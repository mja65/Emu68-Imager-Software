<#
.SYNOPSIS
    AmigaIconKit - Robust PowerShell Module with C# Add-Type for Amiga Icon (.info) manipulation.
.DESCRIPTION
    Works across all Amiga icon formats:
    - Classic Workbench 1.x - 3.x planar DiskObject icons (Magic 0xE310)
    - NewIcons (embedded ASCII palette & pixel data in ToolTypes)
    - ColorIcons / GlowIcons (OS 3.5/3.9 with IFF FORM ICON)
    - AmigaOS 4.x / DualPNG / PowerIcons PNG icons (amiG chunk & tEXt chunks)
    - Standalone IFF FORM ICON files

    Supports reading and setting:
    - Icon position: CurrentX, CurrentY (or -NoPosition)
    - Icon type: Disk, Drawer, Tool, Project, Garbage, Device, Kick, AppIcon
    - Drawer window position & dimensions: DrawerX, DrawerY, DWidth, DHeight
    - ToolTypes: Get, Set, Add, Remove, Toggle
    - DefaultTool, StackSize

    Compatible with Windows PowerShell 5.1 (C# 4/5 compiler) and PowerShell 7+ (Core).
#>

$csharpSource = @'
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

namespace AmigaIconKit {
    public enum AmigaIconType : byte {
        Disk = 1,
        Drawer = 2,
        Tool = 3,
        Project = 4,
        Garbage = 5,
        Device = 6,
        Kick = 7,
        AppIcon = 8
    }

    public class AmigaIconData {
        public string FilePath { get; set; }
        public string Format { get; set; }
        public AmigaIconType IconType { get; set; }
        public int CurrentX { get; set; }
        public int CurrentY { get; set; }
        public string DefaultTool { get; set; }
        public string ToolWindow { get; set; }
        public int StackSize { get; set; }
        public List<string> ToolTypes { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public bool HasSecondImage { get; set; }
        public bool HasNewIconData { get; set; }
        public bool HasDrawerData { get; set; }

        // Drawer window properties
        public int? DrawerX { get; set; }
        public int? DrawerY { get; set; }
        public int? DWidth { get; set; }
        public int? DHeight { get; set; }

        // OS 2.0+ DrawerData2 extended flags (ViewIcons=1, AllFiles=2) & ViewModes (0=ShowIconsOs1X, 1=ShowIcons, etc.)
        public uint? DrawerFlags { get; set; }
        public ushort? DrawerViewModes { get; set; }
        public uint UserData { get; set; }

        public bool HasNoPosition {
            get {
                return CurrentX == unchecked((int)0x80000000) || CurrentY == unchecked((int)0x80000000);
            }
        }

        internal byte[] OriginalBytes;
        internal byte[] DrawerDataBytes;
        internal byte[] Image1Bytes;
        internal byte[] Image2Bytes;
        internal byte[] TrailingExtraBytes;
        internal bool IsPngFormat;

        public AmigaIconData() {
            FilePath = "";
            Format = "Classic";
            IconType = AmigaIconType.Tool;
            CurrentX = unchecked((int)0x80000000);
            CurrentY = unchecked((int)0x80000000);
            DefaultTool = "";
            ToolWindow = "";
            StackSize = 4096;
            ToolTypes = new List<string>();
            Width = 0;
            Height = 0;
            HasSecondImage = false;
            HasNewIconData = false;
            HasDrawerData = false;
            IsPngFormat = false;

            DrawerX = null;
            DrawerY = null;
            DWidth = null;
            DHeight = null;
            DrawerFlags = null;
            DrawerViewModes = null;
            UserData = 0;
        }
    }

    public static class AmigaIconEngine {
        public const int NO_ICON_POSITION = unchecked((int)0x80000000);
        public const ushort AMIGA_MAGIC = 0xE310;
        private static uint[] CrcTable = null;

        static AmigaIconEngine() {
            InitCrc32();
        }

        private static void InitCrc32() {
            CrcTable = new uint[256];
            for (uint i = 0; i < 256; i++) {
                uint c = i;
                for (int j = 0; j < 8; j++) {
                    if ((c & 1) != 0) c = 0xEDB88320U ^ (c >> 1);
                    else c >>= 1;
                }
                CrcTable[i] = c;
            }
        }

        public static uint CalculateCrc32(byte[] data, int offset, int length) {
            if (data == null || offset < 0 || length < 0 || offset + length > data.Length) return 0;
            uint crc = 0xFFFFFFFFU;
            for (int i = 0; i < length; i++) {
                byte b = data[offset + i];
                crc = CrcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
            }
            return crc ^ 0xFFFFFFFFU;
        }

        public static short ReadInt16BE(byte[] b, int offset) {
            if (b == null || offset < 0 || offset + 2 > b.Length) return 0;
            return (short)((b[offset] << 8) | b[offset + 1]);
        }

        public static ushort ReadUInt16BE(byte[] b, int offset) {
            if (b == null || offset < 0 || offset + 2 > b.Length) return 0;
            return (ushort)((b[offset] << 8) | b[offset + 1]);
        }

        public static int ReadInt32BE(byte[] b, int offset) {
            if (b == null || offset < 0 || offset + 4 > b.Length) return 0;
            return (b[offset] << 24) | (b[offset + 1] << 16) | (b[offset + 2] << 8) | b[offset + 3];
        }

        public static void WriteInt16BE(byte[] b, int offset, short val) {
            if (b == null || offset < 0 || offset + 2 > b.Length) return;
            b[offset] = (byte)((val >> 8) & 0xFF);
            b[offset + 1] = (byte)(val & 0xFF);
        }

        public static void WriteUInt16BE(byte[] b, int offset, ushort val) {
            if (b == null || offset < 0 || offset + 2 > b.Length) return;
            b[offset] = (byte)((val >> 8) & 0xFF);
            b[offset + 1] = (byte)(val & 0xFF);
        }

        public static void WriteInt32BE(byte[] b, int offset, int val) {
            if (b == null || offset < 0 || offset + 4 > b.Length) return;
            b[offset] = (byte)((val >> 24) & 0xFF);
            b[offset + 1] = (byte)((val >> 16) & 0xFF);
            b[offset + 2] = (byte)((val >> 8) & 0xFF);
            b[offset + 3] = (byte)(val & 0xFF);
        }

        public static AmigaIconData ReadIcon(string filePath) {
            if (!File.Exists(filePath)) {
                throw new FileNotFoundException("Amiga icon file not found", filePath);
            }
            byte[] bytes = File.ReadAllBytes(filePath);
            AmigaIconData icon = ReadIconFromBytes(bytes);
            icon.FilePath = filePath;
            return icon;
        }

        public static AmigaIconData ReadIconFromBytes(byte[] bytes) {
            if (bytes == null || bytes.Length < 8) {
                throw new InvalidDataException("File is too small to be an Amiga icon.");
            }

            // 1. AmigaOS 4 PNG / DualPNG Icon
            if (bytes.Length >= 8 &&
                bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
                bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
                return ReadPngIcon(bytes);
            }

            // 2. Standalone IFF FORM ICON
            if (bytes.Length >= 12 &&
                bytes[0] == 'F' && bytes[1] == 'O' && bytes[2] == 'R' && bytes[3] == 'M' &&
                bytes[8] == 'I' && bytes[9] == 'C' && bytes[10] == 'O' && bytes[11] == 'N') {
                return ReadIffFormIcon(bytes);
            }

            // 3. Classic DiskObject
            ushort magic = ReadUInt16BE(bytes, 0);
            if (magic != AMIGA_MAGIC) {
                throw new InvalidDataException(string.Format("Invalid Amiga icon magic 0x{0:X4}. Expected 0xE310.", magic));
            }

            return ReadClassicIcon(bytes);
        }

        private static AmigaIconData ReadIffFormIcon(byte[] bytes) {
            AmigaIconData icon = new AmigaIconData();
            icon.OriginalBytes = bytes;
            icon.IsPngFormat = false;
            icon.Format = "ColorIcon (OS 3.5/3.9 Standalone)";
            icon.TrailingExtraBytes = bytes;
            ExtractWindowToolType(icon);
            return icon;
        }

        private static AmigaIconData ReadClassicIcon(byte[] bytes) {
            AmigaIconData icon = new AmigaIconData();
            icon.OriginalBytes = bytes;
            icon.IsPngFormat = false;
            icon.Format = "Classic";

            if (bytes.Length < 78) {
                throw new InvalidDataException("Classic Amiga icon header is truncated.");
            }

            // Gadget Dimensions & Pointers
            icon.Width = ReadInt16BE(bytes, 12);
            icon.Height = ReadInt16BE(bytes, 14);
            int gadgetRender = ReadInt32BE(bytes, 22);
            int selectRender = ReadInt32BE(bytes, 26);
            icon.HasSecondImage = (selectRender != 0);

            icon.UserData = (uint)ReadInt32BE(bytes, 44);

            // DiskObject fields
            byte typeByte = bytes[48];
            if (Enum.IsDefined(typeof(AmigaIconType), typeByte)) {
                icon.IconType = (AmigaIconType)typeByte;
            } else {
                icon.IconType = AmigaIconType.Tool;
            }

            int defaultToolPtr = ReadInt32BE(bytes, 50);
            int toolTypesPtr = ReadInt32BE(bytes, 54);
            icon.CurrentX = ReadInt32BE(bytes, 58);
            icon.CurrentY = ReadInt32BE(bytes, 62);
            int drawerDataPtr = ReadInt32BE(bytes, 66);
            int toolWindowPtr = ReadInt32BE(bytes, 70);
            icon.StackSize = ReadInt32BE(bytes, 74);
            icon.HasDrawerData = (drawerDataPtr != 0);

            int pos = 78;

            // 1. DrawerData (NewWindow struct [48 bytes] + CurrentX [4] + CurrentY [4] = 56 bytes)
            if (drawerDataPtr != 0 && pos + 56 <= bytes.Length) {
                icon.DrawerDataBytes = new byte[56];
                Array.Copy(bytes, pos, icon.DrawerDataBytes, 0, 56);

                // Read DrawerX, DrawerY, DWidth, DHeight from NewWindow struct
                icon.DrawerX = ReadInt16BE(icon.DrawerDataBytes, 0);
                icon.DrawerY = ReadInt16BE(icon.DrawerDataBytes, 2);
                icon.DWidth = ReadInt16BE(icon.DrawerDataBytes, 4);
                icon.DHeight = ReadInt16BE(icon.DrawerDataBytes, 6);

                pos += 56;
            }

            // 2. Image 1
            if (gadgetRender != 0 && pos + 20 <= bytes.Length) {
                int imgW = ReadInt16BE(bytes, pos + 4);
                int imgH = ReadInt16BE(bytes, pos + 6);
                int imgDepth = ReadInt16BE(bytes, pos + 8);
                int imgDataPtr = ReadInt32BE(bytes, pos + 10);

                int imgDataLen = 0;
                if (imgDataPtr != 0 && imgDepth > 0 && imgDepth <= 8 && imgW > 0 && imgH > 0 && imgW <= 2048 && imgH <= 2048) {
                    int planeWords = ((imgW + 15) / 16) * 2;
                    imgDataLen = planeWords * imgH * imgDepth;
                }
                int totalLen = 20 + imgDataLen;
                if (pos + totalLen <= bytes.Length) {
                    icon.Image1Bytes = new byte[totalLen];
                    Array.Copy(bytes, pos, icon.Image1Bytes, 0, totalLen);
                    pos += totalLen;
                }
            }

            // 3. Image 2
            if (selectRender != 0 && pos + 20 <= bytes.Length) {
                int imgW = ReadInt16BE(bytes, pos + 4);
                int imgH = ReadInt16BE(bytes, pos + 6);
                int imgDepth = ReadInt16BE(bytes, pos + 8);
                int imgDataPtr = ReadInt32BE(bytes, pos + 10);

                int imgDataLen = 0;
                if (imgDataPtr != 0 && imgDepth > 0 && imgDepth <= 8 && imgW > 0 && imgH > 0 && imgW <= 2048 && imgH <= 2048) {
                    int planeWords = ((imgW + 15) / 16) * 2;
                    imgDataLen = planeWords * imgH * imgDepth;
                }
                int totalLen = 20 + imgDataLen;
                if (pos + totalLen <= bytes.Length) {
                    icon.Image2Bytes = new byte[totalLen];
                    Array.Copy(bytes, pos, icon.Image2Bytes, 0, totalLen);
                    pos += totalLen;
                }
            }

            // 4. DefaultTool string
            if (defaultToolPtr != 0 && pos + 4 <= bytes.Length) {
                int len = ReadInt32BE(bytes, pos);
                pos += 4;
                if (len > 0 && len <= 4096 && pos + len <= bytes.Length) {
                    int strLen = 0;
                    while (strLen < len && pos + strLen < bytes.Length && bytes[pos + strLen] != 0) {
                        strLen++;
                    }
                    icon.DefaultTool = Encoding.GetEncoding("ISO-8859-1").GetString(bytes, pos, strLen);
                    pos += len;
                }
            }

            // 5. ToolTypes array
            if (toolTypesPtr != 0 && pos + 4 <= bytes.Length) {
                int arraySizeBytes = ReadInt32BE(bytes, pos);
                pos += 4;
                if (arraySizeBytes > 0 && arraySizeBytes <= 500000) {
                    int count = Math.Max(0, (arraySizeBytes / 4) - 1);
                    if (count > 2000) count = 2000;

                    for (int i = 0; i < count && pos + 4 <= bytes.Length; i++) {
                        int sLen = ReadInt32BE(bytes, pos);
                        pos += 4;
                        if (sLen <= 0 || sLen > 8192 || pos + sLen > bytes.Length) {
                            break;
                        }
                        int strLen = 0;
                        while (strLen < sLen && pos + strLen < bytes.Length && bytes[pos + strLen] != 0) {
                            strLen++;
                        }
                        string tt = Encoding.GetEncoding("ISO-8859-1").GetString(bytes, pos, strLen);
                        icon.ToolTypes.Add(tt);
                        pos += sLen;

                        if (tt.StartsWith("***") || tt.StartsWith("/*")) {
                            icon.HasNewIconData = true;
                        }
                    }
                }
            }

            // 6. ToolWindow string
            if (toolWindowPtr != 0 && pos + 4 <= bytes.Length) {
                int len = ReadInt32BE(bytes, pos);
                pos += 4;
                if (len > 0 && len <= 4096 && pos + len <= bytes.Length) {
                    int strLen = 0;
                    while (strLen < len && pos + strLen < bytes.Length && bytes[pos + strLen] != 0) {
                        strLen++;
                    }
                    icon.ToolWindow = Encoding.GetEncoding("ISO-8859-1").GetString(bytes, pos, strLen);
                    pos += len;
                }
            }

            // 7. Extended DrawerData2 (dd_Flags [4 bytes] + dd_ViewModes [2 bytes])
            // In AmigaOS 2.0+ and HstAmiga, if HasDrawerData and UserData == 1:
            // 6 bytes are located directly after ToolTypes / ToolWindow.
            if (icon.HasDrawerData && pos + 6 <= bytes.Length) {
                bool isForm = (pos + 4 <= bytes.Length && bytes[pos] == 'F' && bytes[pos + 1] == 'O' && bytes[pos + 2] == 'R' && bytes[pos + 3] == 'M');
                if (!isForm && icon.UserData == 1) {
                    icon.DrawerFlags = (uint)ReadInt32BE(bytes, pos);
                    icon.DrawerViewModes = (ushort)ReadUInt16BE(bytes, pos + 4);
                    pos += 6;
                }
            }

            // Standard OS2.0+ defaults for drawer icons if not already read
            if (icon.HasDrawerData) {
                if (!icon.DrawerFlags.HasValue) {
                    icon.DrawerFlags = 0; // ViewIconsOs1X (0 = OS1.x compatibility)
                }
                if (!icon.DrawerViewModes.HasValue) {
                    icon.DrawerViewModes = 0; // ShowIconsOs1X
                }
                icon.UserData = 1;
            }

            // 8. Trailing Extra (ColorIcon IFF FORM ICON chunks)
            if (pos < bytes.Length) {
                int rem = bytes.Length - pos;
                icon.TrailingExtraBytes = new byte[rem];
                Array.Copy(bytes, pos, icon.TrailingExtraBytes, 0, rem);
                if (rem >= 12 && icon.TrailingExtraBytes[0] == 'F' && icon.TrailingExtraBytes[1] == 'O' && icon.TrailingExtraBytes[2] == 'R' && icon.TrailingExtraBytes[3] == 'M') {
                    icon.Format = "ColorIcon (OS 3.5/3.9)";
                }
            }

            if (icon.HasNewIconData) {
                icon.Format = "NewIcon (OS 3.x)";
            }

            // Fallback to WINDOW= tooltype if DrawerX not yet set
            if (!icon.DrawerX.HasValue) {
                ExtractWindowToolType(icon);
            }

            return icon;
        }

        private static AmigaIconData ReadPngIcon(byte[] bytes) {
            AmigaIconData icon = new AmigaIconData();
            icon.OriginalBytes = bytes;
            icon.IsPngFormat = true;
            icon.Format = "PNG (OS 4.x / DualPNG)";

            int pos = 8;
            while (pos + 8 <= bytes.Length) {
                long ulen = ((long)bytes[pos] << 24) | ((long)bytes[pos + 1] << 16) | ((long)bytes[pos + 2] << 8) | (long)bytes[pos + 3];
                if (ulen < 0 || ulen > 50000000) break;
                int len = (int)ulen;
                string chunk = Encoding.ASCII.GetString(bytes, pos + 4, 4);
                pos += 8;

                if (pos + len > bytes.Length) break;

                if (chunk == "IHDR" && len >= 8) {
                    icon.Width = ReadInt32BE(bytes, pos);
                    icon.Height = ReadInt32BE(bytes, pos + 4);
                } else if (chunk == "amiG" && len >= 16) {
                    ParseAmiGChunk(bytes, pos, len, icon);
                } else if (chunk == "tEXt") {
                    ParseTextChunk(bytes, pos, len, icon);
                } else if (chunk == "IEND") {
                    int nextPos = pos + len + 4;
                    if (nextPos + 8 <= bytes.Length &&
                        bytes[nextPos] == 0x89 && bytes[nextPos + 1] == 0x50 && bytes[nextPos + 2] == 0x4E && bytes[nextPos + 3] == 0x47) {
                        icon.HasSecondImage = true;
                    }
                    break;
                }

                pos += len + 4;
            }

            ExtractWindowToolType(icon);
            return icon;
        }

        private static void ParseAmiGChunk(byte[] bytes, int offset, int length, AmigaIconData icon) {
            if (length < 18 || offset + length > bytes.Length) return;
            int p = offset;
            ushort version = ReadUInt16BE(bytes, p); p += 2;
            byte type = bytes[p++];
            if (Enum.IsDefined(typeof(AmigaIconType), type)) {
                icon.IconType = (AmigaIconType)type;
            }
            p++; // pad
            icon.CurrentX = ReadInt32BE(bytes, p); p += 4;
            icon.CurrentY = ReadInt32BE(bytes, p); p += 4;
            icon.StackSize = ReadInt32BE(bytes, p); p += 4;

            if (p + 2 <= offset + length) {
                ushort dtLen = ReadUInt16BE(bytes, p); p += 2;
                if (dtLen > 0 && p + dtLen <= offset + length && p + dtLen <= bytes.Length) {
                    icon.DefaultTool = Encoding.UTF8.GetString(bytes, p, dtLen);
                    p += dtLen;
                }
            }

            if (p + 2 <= offset + length) {
                ushort ttCount = ReadUInt16BE(bytes, p); p += 2;
                for (int i = 0; i < ttCount && p + 2 <= offset + length; i++) {
                    ushort ttLen = ReadUInt16BE(bytes, p); p += 2;
                    if (ttLen > 0 && p + ttLen <= offset + length && p + ttLen <= bytes.Length) {
                        icon.ToolTypes.Add(Encoding.UTF8.GetString(bytes, p, ttLen));
                        p += ttLen;
                    }
                }
            }
        }

        private static void ParseTextChunk(byte[] bytes, int offset, int length, AmigaIconData icon) {
            if (length <= 1 || offset + length > bytes.Length) return;
            int nullPos = -1;
            for (int i = 0; i < length; i++) {
                if (bytes[offset + i] == 0) { nullPos = i; break; }
            }
            if (nullPos <= 0 || nullPos >= length) return;

            string key = Encoding.ASCII.GetString(bytes, offset, nullPos);
            int valLen = length - nullPos - 1;
            string val = valLen > 0 ? Encoding.UTF8.GetString(bytes, offset + nullPos + 1, valLen) : "";

            if (key.StartsWith("ToolType", StringComparison.OrdinalIgnoreCase)) {
                icon.ToolTypes.Add(val);
            } else if (key.Equals("DefaultTool", StringComparison.OrdinalIgnoreCase)) {
                icon.DefaultTool = val;
            } else if (key.Equals("Position", StringComparison.OrdinalIgnoreCase)) {
                string[] pts = val.Split(new char[] { ',', ' ', 'x' }, StringSplitOptions.RemoveEmptyEntries);
                if (pts.Length >= 2) {
                    int x, y;
                    if (int.TryParse(pts[0], out x)) icon.CurrentX = x;
                    if (int.TryParse(pts[1], out y)) icon.CurrentY = y;
                }
            } else if (key.Equals("Type", StringComparison.OrdinalIgnoreCase) || key.Equals("IconType", StringComparison.OrdinalIgnoreCase)) {
                byte t;
                if (byte.TryParse(val, out t) && Enum.IsDefined(typeof(AmigaIconType), t)) {
                    icon.IconType = (AmigaIconType)t;
                }
            } else if (key.Equals("StackSize", StringComparison.OrdinalIgnoreCase)) {
                int s;
                if (int.TryParse(val, out s)) icon.StackSize = s;
            }
        }

        private static void ExtractWindowToolType(AmigaIconData icon) {
            if (icon.ToolTypes == null) return;
            foreach (string tt in icon.ToolTypes) {
                string raw = tt.Trim();
                bool isCommented = raw.StartsWith("(") && raw.EndsWith(")");
                string clean = isCommented ? raw.Substring(1, raw.Length - 2).Trim() : raw;
                if (clean.StartsWith("WINDOW=", StringComparison.OrdinalIgnoreCase)) {
                    string val = clean.Substring(7);
                    string[] parts = val.Split(new char[] { ',', ' ' }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length >= 4) {
                        int dx, dy, dw, dh;
                        if (int.TryParse(parts[0], out dx)) icon.DrawerX = dx;
                        if (int.TryParse(parts[1], out dy)) icon.DrawerY = dy;
                        if (int.TryParse(parts[2], out dw)) icon.DWidth = dw;
                        if (int.TryParse(parts[3], out dh)) icon.DHeight = dh;
                        break;
                    }
                }
            }
        }

        public static void SyncDrawerData(AmigaIconData icon) {
            bool isDrawerType = (icon.IconType == AmigaIconType.Disk || icon.IconType == AmigaIconType.Drawer || icon.IconType == AmigaIconType.Garbage);
            if (!icon.DrawerX.HasValue && !icon.DrawerY.HasValue && !icon.DWidth.HasValue && !icon.DHeight.HasValue && !isDrawerType && !icon.HasDrawerData) {
                return;
            }

            int targetX = icon.DrawerX.HasValue ? icon.DrawerX.Value : 50;
            int targetY = icon.DrawerY.HasValue ? icon.DrawerY.Value : 40;
            int targetW = icon.DWidth.HasValue ? icon.DWidth.Value : 320;
            int targetH = icon.DHeight.HasValue ? icon.DHeight.Value : 200;

            icon.DrawerX = targetX;
            icon.DrawerY = targetY;
            icon.DWidth = targetW;
            icon.DHeight = targetH;
            icon.HasDrawerData = true;

            // Ensure DrawerData2 properties have valid defaults for OS 2.0+
            if (!icon.DrawerFlags.HasValue) {
                icon.DrawerFlags = 0; // ViewIconsOs1X = 0
            }
            if (!icon.DrawerViewModes.HasValue) {
                icon.DrawerViewModes = 0; // ShowIconsOs1X = 0
            }
            icon.UserData = 1;

            // 1. Update DrawerDataBytes (strictly 56 bytes)
            if (icon.DrawerDataBytes == null || icon.DrawerDataBytes.Length < 56) {
                byte[] defaultDrawer = new byte[56];
                WriteInt16BE(defaultDrawer, 0, (short)targetX);
                WriteInt16BE(defaultDrawer, 2, (short)targetY);
                WriteInt16BE(defaultDrawer, 4, (short)targetW);
                WriteInt16BE(defaultDrawer, 6, (short)targetH);
                defaultDrawer[8] = 0; // DetailPen
                defaultDrawer[9] = 1; // BlockPen
                WriteInt32BE(defaultDrawer, 14, 0x00000E0F); // Window Flags
                WriteInt16BE(defaultDrawer, 38, 64);  // MinWidth
                WriteInt16BE(defaultDrawer, 40, 40);  // MinHeight
                WriteInt16BE(defaultDrawer, 42, -1);  // MaxWidth
                WriteInt16BE(defaultDrawer, 44, -1);  // MaxHeight
                WriteUInt16BE(defaultDrawer, 46, 1);  // Type = 1 (WBSCREEN)
                icon.DrawerDataBytes = defaultDrawer;
            } else {
                WriteInt16BE(icon.DrawerDataBytes, 0, (short)targetX);
                WriteInt16BE(icon.DrawerDataBytes, 2, (short)targetY);
                WriteInt16BE(icon.DrawerDataBytes, 4, (short)targetW);
                WriteInt16BE(icon.DrawerDataBytes, 6, (short)targetH);
            }

            // Only update an existing WINDOW= tooltype if one was already present in ToolTypes
            string winString = string.Format("WINDOW={0},{1},{2},{3}", targetX, targetY, targetW, targetH);
            for (int i = 0; i < icon.ToolTypes.Count; i++) {
                string raw = icon.ToolTypes[i].Trim();
                bool isCommented = raw.StartsWith("(") && raw.EndsWith(")");
                string clean = isCommented ? raw.Substring(1, raw.Length - 2).Trim() : raw;
                if (clean.StartsWith("WINDOW=", StringComparison.OrdinalIgnoreCase)) {
                    icon.ToolTypes[i] = isCommented ? string.Format("({0})", winString) : winString;
                    break;
                }
            }
        }

        public static void SetDrawerDimensions(AmigaIconData icon, int? dx, int? dy, int? dw, int? dh) {
            if (dx.HasValue) icon.DrawerX = dx.Value;
            if (dy.HasValue) icon.DrawerY = dy.Value;
            if (dw.HasValue) icon.DWidth = dw.Value;
            if (dh.HasValue) icon.DHeight = dh.Value;
            SyncDrawerData(icon);
        }

        public static byte[] SerializeIcon(AmigaIconData icon) {
            SyncDrawerData(icon);
            if (icon.IsPngFormat) {
                return SerializePngIcon(icon);
            }
            return SerializeClassicIcon(icon);
        }

        private static byte[] SerializeClassicIcon(AmigaIconData icon) {
            using (MemoryStream ms = new MemoryStream()) {
                byte[] header = new byte[78];
                if (icon.OriginalBytes != null && icon.OriginalBytes.Length >= 78) {
                    Array.Copy(icon.OriginalBytes, 0, header, 0, 78);
                } else {
                    WriteUInt16BE(header, 0, AMIGA_MAGIC);
                    WriteUInt16BE(header, 2, 1);
                }

                header[48] = (byte)icon.IconType;
                header[49] = 0;

                bool hasDefTool = !string.IsNullOrEmpty(icon.DefaultTool);
                bool hasToolTypes = (icon.ToolTypes != null && icon.ToolTypes.Count > 0);
                bool hasDrawer = (icon.DrawerDataBytes != null && icon.DrawerDataBytes.Length > 0);
                bool hasToolWin = !string.IsNullOrEmpty(icon.ToolWindow);

                if (hasDrawer) {
                    // For drawers, Gadget.UserData (byte 44) must be 1 to signal DrawerData2 to Workbench/HstAmiga
                    WriteInt32BE(header, 44, 1);
                }

                WriteInt32BE(header, 50, hasDefTool ? 1 : 0);
                WriteInt32BE(header, 54, hasToolTypes ? 1 : 0);
                WriteInt32BE(header, 58, icon.CurrentX);
                WriteInt32BE(header, 62, icon.CurrentY);
                WriteInt32BE(header, 66, hasDrawer ? 1 : 0);
                WriteInt32BE(header, 70, hasToolWin ? 1 : 0);
                WriteInt32BE(header, 74, icon.StackSize);

                ms.Write(header, 0, 78);

                if (hasDrawer) {
                    // DrawerData is ALWAYS strictly 56 bytes
                    ms.Write(icon.DrawerDataBytes, 0, Math.Min(56, icon.DrawerDataBytes.Length));
                }
                if (icon.Image1Bytes != null) {
                    ms.Write(icon.Image1Bytes, 0, icon.Image1Bytes.Length);
                }
                if (icon.Image2Bytes != null) {
                    ms.Write(icon.Image2Bytes, 0, icon.Image2Bytes.Length);
                }

                if (hasDefTool) {
                    byte[] sBytes = Encoding.GetEncoding("ISO-8859-1").GetBytes(icon.DefaultTool);
                    byte[] lBuf = new byte[4];
                    WriteInt32BE(lBuf, 0, sBytes.Length + 1);
                    ms.Write(lBuf, 0, 4);
                    ms.Write(sBytes, 0, sBytes.Length);
                    ms.WriteByte(0);
                }

                if (hasToolTypes) {
                    byte[] aBuf = new byte[4];
                    WriteInt32BE(aBuf, 0, (icon.ToolTypes.Count + 1) * 4);
                    ms.Write(aBuf, 0, 4);

                    byte[] sBuf = new byte[4];
                    foreach (string tt in icon.ToolTypes) {
                        byte[] ttBytes = Encoding.GetEncoding("ISO-8859-1").GetBytes(tt);
                        WriteInt32BE(sBuf, 0, ttBytes.Length + 1);
                        ms.Write(sBuf, 0, 4);
                        ms.Write(ttBytes, 0, ttBytes.Length);
                        ms.WriteByte(0);
                    }
                }

                if (hasToolWin) {
                    byte[] sBytes = Encoding.GetEncoding("ISO-8859-1").GetBytes(icon.ToolWindow);
                    byte[] lBuf = new byte[4];
                    WriteInt32BE(lBuf, 0, sBytes.Length + 1);
                    ms.Write(lBuf, 0, 4);
                    ms.Write(sBytes, 0, sBytes.Length);
                    ms.WriteByte(0);
                }

                // 7. Extended DrawerData2 (dd_Flags [4 bytes] + dd_ViewModes [2 bytes])
                // In AmigaOS 2.0+ and HstAmiga, if hasDrawer and Gadget.UserData == 1:
                // Write 6 bytes between ToolTypes/ToolWindow and TrailingExtraBytes (ColorIcon)
                if (hasDrawer) {
                    byte[] dd2Buf = new byte[6];
                    uint flags = icon.DrawerFlags.HasValue ? icon.DrawerFlags.Value : 0;
                    ushort viewModes = icon.DrawerViewModes.HasValue ? icon.DrawerViewModes.Value : (ushort)0;
                    WriteInt32BE(dd2Buf, 0, (int)flags);
                    WriteUInt16BE(dd2Buf, 4, viewModes);
                    ms.Write(dd2Buf, 0, 6);
                }

                if (icon.TrailingExtraBytes != null) {
                    ms.Write(icon.TrailingExtraBytes, 0, icon.TrailingExtraBytes.Length);
                }
                return ms.ToArray();
            }
        }

        private static byte[] SerializePngIcon(AmigaIconData icon) {
            byte[] orig = icon.OriginalBytes;
            byte[] amiGData;
            using (MemoryStream ms = new MemoryStream()) {
                byte[] u16 = new byte[2];
                byte[] s32 = new byte[4];
                WriteUInt16BE(u16, 0, 1); ms.Write(u16, 0, 2);
                ms.WriteByte((byte)icon.IconType); ms.WriteByte(0);
                WriteInt32BE(s32, 0, icon.CurrentX); ms.Write(s32, 0, 4);
                WriteInt32BE(s32, 0, icon.CurrentY); ms.Write(s32, 0, 4);
                WriteInt32BE(s32, 0, icon.StackSize); ms.Write(s32, 0, 4);

                byte[] dtBytes = string.IsNullOrEmpty(icon.DefaultTool) ? new byte[0] : Encoding.UTF8.GetBytes(icon.DefaultTool);
                WriteUInt16BE(u16, 0, (ushort)dtBytes.Length); ms.Write(u16, 0, 2);
                if (dtBytes.Length > 0) ms.Write(dtBytes, 0, dtBytes.Length);

                ushort ttCount = (ushort)(icon.ToolTypes != null ? icon.ToolTypes.Count : 0);
                WriteUInt16BE(u16, 0, ttCount); ms.Write(u16, 0, 2);
                if (icon.ToolTypes != null) {
                    foreach (string tt in icon.ToolTypes) {
                        byte[] ttBytes = Encoding.UTF8.GetBytes(tt);
                        WriteUInt16BE(u16, 0, (ushort)ttBytes.Length); ms.Write(u16, 0, 2);
                        ms.Write(ttBytes, 0, ttBytes.Length);
                    }
                }
                amiGData = ms.ToArray();
            }

            using (MemoryStream outMs = new MemoryStream()) {
                outMs.Write(orig, 0, 8);
                int pos = 8;
                bool amiGWritten = false;
                while (pos + 8 <= orig.Length) {
                    long ulen = ((long)orig[pos] << 24) | ((long)orig[pos + 1] << 16) | ((long)orig[pos + 2] << 8) | (long)orig[pos + 3];
                    if (ulen < 0 || ulen > 50000000) break;
                    int len = (int)ulen;
                    string chunk = Encoding.ASCII.GetString(orig, pos + 4, 4);
                    int tot = 12 + len;

                    if (chunk == "amiG") { pos += tot; continue; }
                    if (chunk == "IEND" && !amiGWritten) {
                        WriteChunk(outMs, "amiG", amiGData);
                        amiGWritten = true;
                    }
                    if (pos + tot <= orig.Length) {
                        outMs.Write(orig, pos, tot);
                    }
                    pos += tot;
                    if (chunk == "IEND") break;
                }
                if (!amiGWritten) WriteChunk(outMs, "amiG", amiGData);

                if (pos < orig.Length) {
                    outMs.Write(orig, pos, orig.Length - pos);
                }
                return outMs.ToArray();
            }
        }

        private static void WriteChunk(MemoryStream ms, string type, byte[] data) {
            byte[] lenBuf = new byte[4];
            WriteInt32BE(lenBuf, 0, data.Length);
            ms.Write(lenBuf, 0, 4);
            byte[] typeBytes = Encoding.ASCII.GetBytes(type);
            ms.Write(typeBytes, 0, 4);
            ms.Write(data, 0, data.Length);
            byte[] payload = new byte[4 + data.Length];
            Array.Copy(typeBytes, 0, payload, 0, 4);
            Array.Copy(data, 0, payload, 4, data.Length);
            uint crc = CalculateCrc32(payload, 0, payload.Length);
            byte[] crcBuf = new byte[4];
            WriteInt32BE(crcBuf, 0, unchecked((int)crc));
            ms.Write(crcBuf, 0, 4);
        }

        public static void SaveIcon(AmigaIconData icon, string outputPath) {
            byte[] bytes = SerializeIcon(icon);
            File.WriteAllBytes(outputPath, bytes);
        }
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'AmigaIconKit.AmigaIconEngine').Type) {
    Add-Type -TypeDefinition $csharpSource -ErrorAction Stop
}
