<#
.SYNOPSIS
    Extracts or inspects Amiga LZX compressed archives natively in PowerShell 5.1 and PowerShell 7+.

.DESCRIPTION
    Expand-LzxArchive is a high-performance native PowerShell function based on the C unlzx port
    (by nhoudelot & Stuart Caie). It extracts solid/merged and individual files from Amiga .lzx
    archives, calculates and verifies 32-bit CRC checksums, restores Amiga timestamps, and safely
    sanitizes Amiga filenames containing characters that are illegal or problematic on Windows 10/11.

.PARAMETER Path
    Specifies the path to the .lzx archive file. Accepts pipeline input from Get-ChildItem or string paths.

.PARAMETER DestinationPath
    Specifies the path to the directory where the extracted files should be written.
    Defaults to the current working directory.

.PARAMETER InvalidCharReplacement
    Specifies the character or string used to replace Amiga characters that cause issues on Windows 10 or 11
    (e.g., ':', '*', '?', '"', '<', '>', '|', control characters, trailing dots/spaces, and reserved DOS names
    such as CON, PRN, AUX, NUL, COM1-9, LPT1-9).
    The default replacement is '_' (an underscore).

.PARAMETER PreserveTimestamps
    Preserves the original Amiga modification timestamp on extracted files. Enabled by default.

.PARAMETER Force
    Overwrites existing files in DestinationPath without prompting.

.PARAMETER PassThru
    Returns custom objects representing each extracted file, including size, path, CRC verification status,
    and Amiga protection attributes.

.PARAMETER ListOnly
    Displays the contents of the archive without extracting any files to disk.

.EXAMPLE
    Expand-LzxArchive -Path ".\DOpus417pre21.lzx" -DestinationPath ".\Extracted"

    Extracts all files from DOpus417pre21.lzx into the Extracted folder, replacing invalid characters with '_'.

.EXAMPLE
    Expand-LzxArchive -Path ".\DOpus417pre21.lzx" -InvalidCharReplacement "-" -Verbose

    Extracts files using a hyphen as the replacement character for invalid Windows characters, showing detailed extraction progress.

.EXAMPLE
    Get-ChildItem -Filter *.lzx | Expand-LzxArchive -DestinationPath "C:\AmigaArchives" -Force

    Extracts all .lzx files in the current folder via pipeline.

.EXAMPLE
    Get-LzxArchive -Path ".\DOpus417pre21.lzx" | Format-Table -AutoSize

    Lists archive contents with unpacked size, packed size, date, CRC, and Amiga protection bits.

.NOTES
    Compatible with:
    - Windows PowerShell 5.1 (Windows 10, Windows 11, Windows Server 2016-2025)
    - PowerShell 7.0+ (Windows, Linux, macOS)
    No external dependencies or DLLs required.
#>

# Ensure high-performance C# engine is loaded (compiled once per session)
if (-not ([System.Management.Automation.PSTypeName]'AmigaLzx.LzxEngine').Type) {
    $cSharpSource = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace AmigaLzx
{
    public class LzxFileInfo
    {
        public string OriginalName { get; set; }
        public string SanitizedPath { get; set; }
        public long UnpackedSize { get; set; }
        public long PackedSize { get; set; }
        public int PackMode { get; set; }
        public string PackModeName { get; set; }
        public uint DataCrc { get; set; }
        public string DataCrcHex { get; set; }
        public DateTime Timestamp { get; set; }
        public byte Attributes { get; set; }
        public string ProtectionString { get; set; }
        public string Comment { get; set; }
        public bool IsMerged { get; set; }
        public bool HadInvalidChars { get; set; }

        public override string ToString()
        {
            return string.Format("{0} ({1:N0} bytes)", SanitizedPath, UnpackedSize);
        }
    }

    public class LzxExtractedResult
    {
        public string OriginalName { get; set; }
        public string DestinationPath { get; set; }
        public long Size { get; set; }
        public uint ExpectedCrc { get; set; }
        public uint CalculatedCrc { get; set; }
        public bool CrcMatches { get; set; }
        public DateTime Timestamp { get; set; }
        public string ProtectionString { get; set; }
        public string Comment { get; set; }
        public bool HadInvalidChars { get; set; }

        public override string ToString()
        {
            return string.Format("{0} [{1}]", DestinationPath, CrcMatches ? "CRC OK" : "CRC MISMATCH");
        }
    }

    public static class LzxEngine
    {
        private static readonly uint[] CrcTable = new uint[256]
        {
            0x00000000,0x77073096,0xEE0E612C,0x990951BA,0x076DC419,0x706AF48F,
            0xE963A535,0x9E6495A3,0x0EDB8832,0x79DCB8A4,0xE0D5E91E,0x97D2D988,
            0x09B64C2B,0x7EB17CBD,0xE7B82D07,0x90BF1D91,0x1DB71064,0x6AB020F2,
            0xF3B97148,0x84BE41DE,0x1ADAD47D,0x6DDDE4EB,0xF4D4B551,0x83D385C7,
            0x136C9856,0x646BA8C0,0xFD62F97A,0x8A65C9EC,0x14015C4F,0x63066CD9,
            0xFA0F3D63,0x8D080DF5,0x3B6E20C8,0x4C69105E,0xD56041E4,0xA2677172,
            0x3C03E4D1,0x4B04D447,0xD20D85FD,0xA50AB56B,0x35B5A8FA,0x42B2986C,
            0xDBBBC9D6,0xACBCF940,0x32D86CE3,0x45DF5C75,0xDCD60DCF,0xABD13D59,
            0x26D930AC,0x51DE003A,0xC8D75180,0xBFD06116,0x21B4F4B5,0x56B3C423,
            0xCFBA9599,0xB8BDA50F,0x2802B89E,0x5F058808,0xC60CD9B2,0xB10BE924,
            0x2F6F7C87,0x58684C11,0xC1611DAB,0xB6662D3D,0x76DC4190,0x01DB7106,
            0x98D220BC,0xEFD5102A,0x71B18589,0x06B6B51F,0x9FBFE4A5,0xE8B8D433,
            0x7807C9A2,0x0F00F934,0x9609A88E,0xE10E9818,0x7F6A0DBB,0x086D3D2D,
            0x91646C97,0xE6635C01,0x6B6B51F4,0x1C6C6162,0x856530D8,0xF262004E,
            0x6C0695ED,0x1B01A57B,0x8208F4C1,0xF50FC457,0x65B0D9C6,0x12B7E950,
            0x8BBEB8EA,0xFCB9887C,0x62DD1DDF,0x15DA2D49,0x8CD37CF3,0xFBD44C65,
            0x4DB26158,0x3AB551CE,0xA3BC0074,0xD4BB30E2,0x4ADFA541,0x3DD895D7,
            0xA4D1C46D,0xD3D6F4FB,0x4369E96A,0x346ED9FC,0xAD678846,0xDA60B8D0,
            0x44042D73,0x33031DE5,0xAA0A4C5F,0xDD0D7CC9,0x5005713C,0x270241AA,
            0xBE0B1010,0xC90C2086,0x5768B525,0x206F85B3,0xB966D409,0xCE61E49F,
            0x5EDEF90E,0x29D9C998,0xB0D09822,0xC7D7A8B4,0x59B33D17,0x2EB40D81,
            0xB7BD5C3B,0xC0BA6CAD,0xEDB88320,0x9ABFB3B6,0x03B6E20C,0x74B1D29A,
            0xEAD54739,0x9DD277AF,0x04DB2615,0x73DC1683,0xE3630B12,0x94643B84,
            0x0D6D6A3E,0x7A6A5AA8,0xE40ECF0B,0x9309FF9D,0x0A00AE27,0x7D079EB1,
            0xF00F9344,0x8708A3D2,0x1E01F268,0x6906C2FE,0xF762575D,0x806567CB,
            0x196C3671,0x6E6B06E7,0xFED41B76,0x89D32BE0,0x10DA7A5A,0x67DD4ACC,
            0xF9B9DF6F,0x8EBEEFF9,0x17B7BE43,0x60B08ED5,0xD6D6A3E8,0xA1D1937E,
            0x38D8C2C4,0x4FDFF252,0xD1BB67F1,0xA6BC5767,0x3FB506DD,0x48B2364B,
            0xD80D2BDA,0xAF0A1B4C,0x36034AF6,0x41047A60,0xDF60EFC3,0xA867DF55,
            0x316E8EEF,0x4669BE79,0xCB61B38C,0xBC66831A,0x256FD2A0,0x5268E236,
            0xCC0C7795,0xBB0B4703,0x220216B9,0x5505262F,0xC5BA3BBE,0xB2BD0B28,
            0x2BB45A92,0x5CB36A04,0xC2D7FFA7,0xB5D0CF31,0x2CD99E8B,0x5BDEAE1D,
            0x9B64C2B0,0xEC63F226,0x756AA39C,0x026D930A,0x9C0906A9,0xEB0E363F,
            0x72076785,0x05005713,0x95BF4A82,0xE2B87A14,0x7BB12BAE,0x0CB61B38,
            0x92D28E9B,0xE5D5BE0D,0x7CDCEFB7,0x0BDBDF21,0x86D3D2D4,0xF1D4E242,
            0x68DDB3F8,0x1FDA836E,0x81BE16CD,0xF6B9265B,0x6FB077E1,0x18B74777,
            0x88085AE6,0xFF0F6A70,0x66063BCA,0x11010B5C,0x8F659EFF,0xF862AE69,
            0x616BFFD3,0x166CCF45,0xA00AE278,0xD70DD2EE,0x4E048354,0x3903B3C2,
            0xA7672661,0xD06016F7,0x4969474D,0x3E6E77DB,0xAED16A4A,0xD9D65ADC,
            0x40DF0B66,0x37D83BF0,0xA9BCAE53,0xDEBB9EC5,0x47B2CF7F,0x30B5FFE9,
            0xBDBDF21C,0xCABAC28A,0x53B39330,0x24B4A3A6,0xBAD03605,0xCDD70693,
            0x54DE5729,0x23D967BF,0xB3667A2E,0xC4614AB8,0x5D681B02,0x2A6F2B94,
            0xB40BBE37,0xC30C8EA1,0x5A05DF1B,0x2D02EF8D
        };

        private static readonly byte[] TableOne = new byte[32]
        {
            0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14
        };

        private static readonly uint[] TableTwo = new uint[32]
        {
            0,1,2,3,4,6,8,12,16,24,32,48,64,96,128,192,256,384,512,768,1024,
            1536,2048,3072,4096,6144,8192,12288,16384,24576,32768,49152
        };

        private static readonly uint[] TableThree = new uint[16]
        {
            0,1,3,7,15,31,63,127,255,511,1023,2047,4095,8191,16383,32767
        };

        private static readonly byte[] TableFour = new byte[34]
        {
            0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,
            0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
        };

        private static readonly HashSet<string> WindowsReserved = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "CON", "PRN", "AUX", "NUL",
            "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
            "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
        };

        public static uint UpdateCrc(byte[] buffer, int offset, int length, uint crc)
        {
            uint temp = ~crc;
            for (int i = 0; i < length; i++)
            {
                temp = CrcTable[(buffer[offset + i] ^ temp) & 0xFF] ^ (temp >> 8);
            }
            return ~temp;
        }

        public static string SanitizeAmigaPath(string amigaPath, string replacement, out bool hadInvalidChars)
        {
            hadInvalidChars = false;
            string rep = string.IsNullOrEmpty(replacement) ? "_" : replacement;

            string[] rawParts = amigaPath.Replace('\\', '/').Split(new char[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
            List<string> safeParts = new List<string>();

            for (int p = 0; p < rawParts.Length; p++)
            {
                string part = rawParts[p];
                if (part == "." || string.IsNullOrEmpty(part))
                {
                    continue;
                }
                if (part == "..")
                {
                    hadInvalidChars = true;
                    safeParts.Add(rep + rep);
                    continue;
                }

                StringBuilder sb = new StringBuilder(part.Length);
                for (int i = 0; i < part.Length; i++)
                {
                    char c = part[i];
                    // Windows illegal filename characters: < > : " / \ | ? * and ASCII control characters < 32 or 127
                    if (c < 32 || c == 127 || c == '<' || c == '>' || c == ':' || c == '"' ||
                        c == '/' || c == '\\' || c == '|' || c == '?' || c == '*')
                    {
                        hadInvalidChars = true;
                        sb.Append(rep);
                    }
                    else
                    {
                        sb.Append(c);
                    }
                }

                string sanitized = sb.ToString();

                // Windows disallows trailing dots and spaces in names
                string trimmed = sanitized.TrimEnd('.', ' ');
                if (trimmed != sanitized)
                {
                    hadInvalidChars = true;
                    sanitized = trimmed.Length > 0 ? trimmed : rep;
                }

                // Check Windows reserved names
                string baseName = sanitized;
                int dotIdx = sanitized.IndexOf('.');
                if (dotIdx >= 0)
                {
                    baseName = sanitized.Substring(0, dotIdx);
                }
                if (WindowsReserved.Contains(baseName))
                {
                    hadInvalidChars = true;
                    sanitized = rep + sanitized;
                }

                if (sanitized.Length > 0)
                {
                    safeParts.Add(sanitized);
                }
            }

            if (safeParts.Count == 0)
            {
                return "unnamed";
            }

            return string.Join(Path.DirectorySeparatorChar.ToString(), safeParts.ToArray());
        }

        public static DateTime ParseAmigaDate(uint dateRaw)
        {
            int year = (int)((dateRaw >> 17) & 63) + 1970;
            int month = (int)((dateRaw >> 23) & 15) + 1;
            int day = (int)((dateRaw >> 27) & 31);
            int hour = (int)((dateRaw >> 12) & 31);
            int minute = (int)((dateRaw >> 6) & 63);
            int second = (int)(dateRaw & 63);

            try
            {
                month = Math.Max(1, Math.Min(12, month));
                day = Math.Max(1, Math.Min(DateTime.DaysInMonth(year, month), day));
                hour = Math.Max(0, Math.Min(23, hour));
                minute = Math.Max(0, Math.Min(59, minute));
                second = Math.Max(0, Math.Min(59, second));
                return new DateTime(year, month, day, hour, minute, second);
            }
            catch
            {
                return DateTime.Now;
            }
        }

        public static string GetProtectionString(byte attr)
        {
            return string.Format("{0}{1}{2}{3}{4}{5}{6}{7}",
                (attr & 32) != 0 ? 'h' : '-',
                (attr & 64) != 0 ? 's' : '-',
                (attr & 128) != 0 ? 'p' : '-',
                (attr & 16) != 0 ? 'a' : '-',
                (attr & 1) != 0 ? 'r' : '-',
                (attr & 2) != 0 ? 'w' : '-',
                (attr & 8) != 0 ? 'e' : '-',
                (attr & 4) != 0 ? 'd' : '-');
        }

        public static List<LzxFileInfo> List(string lzxPath, string invalidReplacement)
        {
            if (!File.Exists(lzxPath))
            {
                throw new FileNotFoundException("LZX archive not found", lzxPath);
            }

            List<LzxFileInfo> list = new List<LzxFileInfo>();
            using (FileStream fs = new FileStream(lzxPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (BinaryReader br = new BinaryReader(fs))
            {
                byte[] magic = br.ReadBytes(10);
                if (magic.Length < 10 || magic[0] != 76 || magic[1] != 90 || magic[2] != 88)
                {
                    throw new InvalidDataException("File is not an Amiga LZX archive (invalid magic signature).");
                }

                while (fs.Position + 31 <= fs.Length)
                {
                    byte[] hdr = br.ReadBytes(31);
                    byte attr = hdr[0];
                    uint unpackSize = (uint)(hdr[2] | (hdr[3] << 8) | (hdr[4] << 16) | (hdr[5] << 24));
                    uint packSize = (uint)(hdr[6] | (hdr[7] << 8) | (hdr[8] << 16) | (hdr[9] << 24));
                    byte packMode = hdr[11];
                    byte flags = hdr[12];
                    byte commLen = hdr[14];

                    uint dateRaw = (uint)((hdr[18] << 24) | (hdr[19] << 16) | (hdr[20] << 8) | hdr[21]);
                    uint dataCrc = (uint)(hdr[22] | (hdr[23] << 8) | (hdr[24] << 16) | (hdr[25] << 24));
                    byte fnLen = hdr[30];

                    byte[] fnBytes = br.ReadBytes(fnLen);
                    string origFn = Encoding.GetEncoding("iso-8859-1").GetString(fnBytes);

                    string comment = "";
                    if (commLen > 0)
                    {
                        byte[] commBytes = br.ReadBytes(commLen);
                        comment = Encoding.GetEncoding("iso-8859-1").GetString(commBytes);
                    }

                    bool hadInvalid;
                    string sanitized = SanitizeAmigaPath(origFn, invalidReplacement, out hadInvalid);

                    LzxFileInfo info = new LzxFileInfo();
                    info.OriginalName = origFn;
                    info.SanitizedPath = sanitized;
                    info.UnpackedSize = unpackSize;
                    info.PackedSize = packSize;
                    info.PackMode = packMode;
                    info.PackModeName = (packMode == 0) ? "Store" : (packMode == 2) ? "Normal" : ("Mode " + packMode);
                    info.DataCrc = dataCrc;
                    info.DataCrcHex = dataCrc.ToString("X8");
                    info.Timestamp = ParseAmigaDate(dateRaw);
                    info.Attributes = attr;
                    info.ProtectionString = GetProtectionString(attr);
                    info.Comment = comment;
                    info.IsMerged = (flags & 1) != 0;
                    info.HadInvalidChars = hadInvalid;
                    list.Add(info);

                    if (packSize > 0)
                    {
                        fs.Seek(packSize, SeekOrigin.Current);
                    }
                }
            }

            return list;
        }

        public static List<LzxExtractedResult> Extract(string lzxPath, string destDir, string invalidReplacement, bool overwrite)
        {
            if (!File.Exists(lzxPath))
            {
                throw new FileNotFoundException("LZX archive not found", lzxPath);
            }

            destDir = Path.GetFullPath(destDir);
            if (!Directory.Exists(destDir))
            {
                Directory.CreateDirectory(destDir);
            }

            List<LzxExtractedResult> results = new List<LzxExtractedResult>();

            using (FileStream fs = new FileStream(lzxPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (BinaryReader br = new BinaryReader(fs))
            {
                byte[] magic = br.ReadBytes(10);
                if (magic.Length < 10 || magic[0] != 76 || magic[1] != 90 || magic[2] != 88)
                {
                    throw new InvalidDataException("File is not an Amiga LZX archive (invalid magic signature).");
                }

                List<LzxFileInfo> mergedGroup = new List<LzxFileInfo>();

                while (fs.Position + 31 <= fs.Length)
                {
                    byte[] hdr = br.ReadBytes(31);
                    byte attr = hdr[0];
                    uint unpackSize = (uint)(hdr[2] | (hdr[3] << 8) | (hdr[4] << 16) | (hdr[5] << 24));
                    uint packSize = (uint)(hdr[6] | (hdr[7] << 8) | (hdr[8] << 16) | (hdr[9] << 24));
                    byte packMode = hdr[11];
                    byte flags = hdr[12];
                    byte commLen = hdr[14];

                    uint dateRaw = (uint)((hdr[18] << 24) | (hdr[19] << 16) | (hdr[20] << 8) | hdr[21]);
                    uint dataCrc = (uint)(hdr[22] | (hdr[23] << 8) | (hdr[24] << 16) | (hdr[25] << 24));
                    byte fnLen = hdr[30];

                    byte[] fnBytes = br.ReadBytes(fnLen);
                    string origFn = Encoding.GetEncoding("iso-8859-1").GetString(fnBytes);

                    string comment = "";
                    if (commLen > 0)
                    {
                        byte[] commBytes = br.ReadBytes(commLen);
                        comment = Encoding.GetEncoding("iso-8859-1").GetString(commBytes);
                    }

                    bool hadInvalid;
                    string sanitized = SanitizeAmigaPath(origFn, invalidReplacement, out hadInvalid);

                    LzxFileInfo item = new LzxFileInfo();
                    item.OriginalName = origFn;
                    item.SanitizedPath = sanitized;
                    item.UnpackedSize = unpackSize;
                    item.PackedSize = packSize;
                    item.PackMode = packMode;
                    item.DataCrc = dataCrc;
                    item.DataCrcHex = dataCrc.ToString("X8");
                    item.Timestamp = ParseAmigaDate(dateRaw);
                    item.Attributes = attr;
                    item.ProtectionString = GetProtectionString(attr);
                    item.Comment = comment;
                    item.IsMerged = (flags & 1) != 0;
                    item.HadInvalidChars = hadInvalid;

                    mergedGroup.Add(item);

                    if (packSize > 0)
                    {
                        if (packMode == 2)
                        {
                            DecoderState state = new DecoderState(fs, (int)packSize);
                            for (int i = 0; i < mergedGroup.Count; i++)
                            {
                                LzxFileInfo fileEntry = mergedGroup[i];
                                string targetPath = Path.Combine(destDir, fileEntry.SanitizedPath);
                                string targetDir = Path.GetDirectoryName(targetPath);
                                if (!Directory.Exists(targetDir))
                                {
                                    Directory.CreateDirectory(targetDir);
                                }

                                if (File.Exists(targetPath) && !overwrite)
                                {
                                    state.SkipBytes((int)fileEntry.UnpackedSize);
                                    continue;
                                }

                                uint runningCrc = 0;
                                using (FileStream outStream = new FileStream(targetPath, FileMode.Create, FileAccess.Write, FileShare.None))
                                {
                                    runningCrc = state.ExtractToFile(outStream, (int)fileEntry.UnpackedSize);
                                }

                                try
                                {
                                    File.SetLastWriteTime(targetPath, fileEntry.Timestamp);
                                }
                                catch { }

                                LzxExtractedResult res = new LzxExtractedResult();
                                res.OriginalName = fileEntry.OriginalName;
                                res.DestinationPath = targetPath;
                                res.Size = fileEntry.UnpackedSize;
                                res.ExpectedCrc = fileEntry.DataCrc;
                                res.CalculatedCrc = runningCrc;
                                res.CrcMatches = (runningCrc == fileEntry.DataCrc);
                                res.Timestamp = fileEntry.Timestamp;
                                res.ProtectionString = fileEntry.ProtectionString;
                                res.Comment = fileEntry.Comment;
                                res.HadInvalidChars = fileEntry.HadInvalidChars;
                                results.Add(res);
                            }
                        }
                        else if (packMode == 0)
                        {
                            for (int i = 0; i < mergedGroup.Count; i++)
                            {
                                LzxFileInfo fileEntry = mergedGroup[i];
                                string targetPath = Path.Combine(destDir, fileEntry.SanitizedPath);
                                string targetDir = Path.GetDirectoryName(targetPath);
                                if (!Directory.Exists(targetDir))
                                {
                                    Directory.CreateDirectory(targetDir);
                                }

                                uint runningCrc = 0;
                                byte[] copyBuf = new byte[8192];
                                int remaining = (int)fileEntry.UnpackedSize;

                                using (FileStream outStream = new FileStream(targetPath, FileMode.Create, FileAccess.Write, FileShare.None))
                                {
                                    while (remaining > 0)
                                    {
                                        int toRead = Math.Min(copyBuf.Length, remaining);
                                        int read = fs.Read(copyBuf, 0, toRead);
                                        if (read <= 0) break;
                                        outStream.Write(copyBuf, 0, read);
                                        runningCrc = UpdateCrc(copyBuf, 0, read, runningCrc);
                                        remaining -= read;
                                    }
                                }

                                try
                                {
                                    File.SetLastWriteTime(targetPath, fileEntry.Timestamp);
                                }
                                catch { }

                                LzxExtractedResult res = new LzxExtractedResult();
                                res.OriginalName = fileEntry.OriginalName;
                                res.DestinationPath = targetPath;
                                res.Size = fileEntry.UnpackedSize;
                                res.ExpectedCrc = fileEntry.DataCrc;
                                res.CalculatedCrc = runningCrc;
                                res.CrcMatches = (runningCrc == fileEntry.DataCrc);
                                res.Timestamp = fileEntry.Timestamp;
                                res.ProtectionString = fileEntry.ProtectionString;
                                res.Comment = fileEntry.Comment;
                                res.HadInvalidChars = fileEntry.HadInvalidChars;
                                results.Add(res);
                            }
                        }
                        else
                        {
                            throw new NotSupportedException("Unsupported LZX compression mode: " + packMode);
                        }

                        mergedGroup.Clear();
                    }
                }
            }

            return results;
        }

        private static bool MakeDecodeTable(int numberSymbols, int tableSize, byte[] length, ushort[] table)
        {
            int bitNum = 1;
            uint pos = 0;
            uint tableMask = (uint)(1 << tableSize);
            uint bitMask = tableMask >> 1;
            bool abort = false;

            while (!abort && bitNum <= tableSize)
            {
                for (int symbol = 0; symbol < numberSymbols; symbol++)
                {
                    if (length[symbol] == bitNum)
                    {
                        uint reverse = pos;
                        uint leaf = 0;
                        int fill = tableSize;
                        do
                        {
                            leaf = (leaf << 1) + (reverse & 1);
                            reverse >>= 1;
                        } while (--fill > 0);

                        pos += bitMask;
                        if (pos > tableMask)
                        {
                            abort = true;
                            break;
                        }

                        fill = (int)bitMask;
                        uint nextSymbol = (uint)(1 << bitNum);
                        do
                        {
                            table[leaf] = (ushort)symbol;
                            leaf += nextSymbol;
                        } while (--fill > 0);
                    }
                }
                bitMask >>= 1;
                bitNum++;
            }

            if (!abort && pos != tableMask)
            {
                for (uint symbol = pos; symbol < tableMask; symbol++)
                {
                    uint reverse = symbol;
                    uint leaf = 0;
                    int fill = tableSize;
                    do
                    {
                        leaf = (leaf << 1) + (reverse & 1);
                        reverse >>= 1;
                    } while (--fill > 0);
                    table[leaf] = 0;
                }

                uint nextSymbol = tableMask >> 1;
                pos <<= 16;
                tableMask <<= 16;
                bitMask = 32768;

                while (!abort && bitNum <= 16)
                {
                    for (int symbol = 0; symbol < numberSymbols; symbol++)
                    {
                        if (length[symbol] == bitNum)
                        {
                            uint reverse = pos >> 16;
                            uint leaf = 0;
                            int fill = tableSize;
                            do
                            {
                                leaf = (leaf << 1) + (reverse & 1);
                                reverse >>= 1;
                            } while (--fill > 0);

                            for (fill = 0; fill < bitNum - tableSize; fill++)
                            {
                                if (table[leaf] == 0)
                                {
                                    table[nextSymbol << 1] = 0;
                                    table[(nextSymbol << 1) + 1] = 0;
                                    table[leaf] = (ushort)nextSymbol++;
                                }
                                leaf = (uint)(table[leaf] << 1);
                                leaf += (uint)((pos >> (15 - fill)) & 1);
                            }
                            table[leaf] = (ushort)symbol;

                            pos += bitMask;
                            if (pos > tableMask)
                            {
                                abort = true;
                                break;
                            }
                        }
                    }
                    bitMask >>= 1;
                    bitNum++;
                }
            }

            if (pos != tableMask) abort = true;
            return abort;
        }

        private class DecoderState
        {
            private Stream _stream;
            private int _packRemaining;

            private uint _control;
            private int _shift;
            private uint _lastOffset;
            private uint _decrunchMethod;
            private int _decrunchLength;

            private byte[] _offsetLen = new byte[8];
            private ushort[] _offsetTable = new ushort[128];
            private byte[] _huffman20Len = new byte[20];
            private ushort[] _huffman20Table = new ushort[96];
            private byte[] _literalLen = new byte[768];
            private ushort[] _literalTable = new ushort[5120];

            private byte[] _readBuf = new byte[16384];
            private int _sourcePtr;
            private int _sourceLen;
            private int _sourceEnd;

            private byte[] _decrunchBuf = new byte[258 + 65536 + 258];
            private int _destPtr;
            private int _destEnd;
            private int _posPtr;

            public DecoderState(Stream stream, int packSize)
            {
                _stream = stream;
                _packRemaining = packSize;
                _control = 0;
                _shift = -16;
                _lastOffset = 1;
                _decrunchMethod = 0;
                _decrunchLength = 0;

                _sourcePtr = 16384;
                _sourceLen = 16384;
                _sourceEnd = 16384 - 1024;

                _destPtr = 258 + 65536;
                _destEnd = 258 + 65536;
                _posPtr = 258 + 65536;
            }

            private void FillReadBuffer()
            {
                int count = _sourceLen - _sourcePtr;
                if (count > 0)
                {
                    Buffer.BlockCopy(_readBuf, _sourcePtr, _readBuf, 0, count);
                }
                int temp = count;
                int toRead = 16384 - temp;
                if (_packRemaining < toRead) toRead = _packRemaining;
                if (toRead > 0)
                {
                    int read = _stream.Read(_readBuf, temp, toRead);
                    _packRemaining -= read;
                    _sourceLen = temp + read;
                }
                else
                {
                    _sourceLen = temp;
                }
                _sourcePtr = 0;
            }

            private void ReadLiteralTable()
            {
                uint control = _control;
                int shift = _shift;

                if (shift < 0)
                {
                    shift += 16;
                    control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                    control += (uint)_readBuf[_sourcePtr++] << shift;
                }

                _decrunchMethod = control & 7;
                control >>= 3;
                if ((shift -= 3) < 0)
                {
                    shift += 16;
                    control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                    control += (uint)_readBuf[_sourcePtr++] << shift;
                }

                if (_decrunchMethod == 3)
                {
                    for (int i = 0; i < 8; i++)
                    {
                        _offsetLen[i] = (byte)(control & 7);
                        control >>= 3;
                        if ((shift -= 3) < 0)
                        {
                            shift += 16;
                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                            control += (uint)_readBuf[_sourcePtr++] << shift;
                        }
                    }
                    if (MakeDecodeTable(8, 7, _offsetLen, _offsetTable))
                        throw new InvalidDataException("Corrupt LZX offset decode table.");
                }

                _decrunchLength = (int)(control & 255) << 16;
                control >>= 8;
                if ((shift -= 8) < 0)
                {
                    shift += 16;
                    control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                    control += (uint)_readBuf[_sourcePtr++] << shift;
                }

                _decrunchLength += (int)(control & 255) << 8;
                control >>= 8;
                if ((shift -= 8) < 0)
                {
                    shift += 16;
                    control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                    control += (uint)_readBuf[_sourcePtr++] << shift;
                }

                _decrunchLength += (int)(control & 255);
                control >>= 8;
                if ((shift -= 8) < 0)
                {
                    shift += 16;
                    control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                    control += (uint)_readBuf[_sourcePtr++] << shift;
                }

                if (_decrunchMethod != 1)
                {
                    int pos = 0;
                    uint fix = 1;
                    int maxSymbol = 256;

                    do
                    {
                        for (int i = 0; i < 20; i++)
                        {
                            _huffman20Len[i] = (byte)(control & 15);
                            control >>= 4;
                            if ((shift -= 4) < 0)
                            {
                                shift += 16;
                                control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                                control += (uint)_readBuf[_sourcePtr++] << shift;
                            }
                        }

                        if (MakeDecodeTable(20, 6, _huffman20Len, _huffman20Table))
                            throw new InvalidDataException("Corrupt LZX huffman20 table.");

                        do
                        {
                            uint symbol = _huffman20Table[control & 63];
                            int temp;
                            if (symbol >= 20)
                            {
                                do
                                {
                                    symbol = _huffman20Table[((control >> 6) & 1) + (symbol << 1)];
                                    if (shift-- == 0)
                                    {
                                        shift += 16;
                                        control += (uint)_readBuf[_sourcePtr++] << 24;
                                        control += (uint)_readBuf[_sourcePtr++] << 16;
                                    }
                                    control >>= 1;
                                } while (symbol >= 20);
                                temp = 6;
                            }
                            else
                            {
                                temp = _huffman20Len[symbol];
                            }

                            control >>= temp;
                            if ((shift -= temp) < 0)
                            {
                                shift += 16;
                                control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                                control += (uint)_readBuf[_sourcePtr++] << shift;
                            }

                            switch (symbol)
                            {
                                case 17:
                                case 18:
                                    {
                                        uint count;
                                        if (symbol == 17)
                                        {
                                            temp = 4;
                                            count = 3;
                                        }
                                        else
                                        {
                                            temp = (int)(6 - fix);
                                            count = 19;
                                        }
                                        count += (control & TableThree[temp]) + fix;
                                        control >>= temp;
                                        if ((shift -= temp) < 0)
                                        {
                                            shift += 16;
                                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                                            control += (uint)_readBuf[_sourcePtr++] << shift;
                                        }
                                        while (pos < maxSymbol && count-- > 0)
                                            _literalLen[pos++] = 0;
                                        break;
                                    }
                                case 19:
                                    {
                                        uint count = (control & 1) + 3 + fix;
                                        if (shift-- == 0)
                                        {
                                            shift += 16;
                                            control += (uint)_readBuf[_sourcePtr++] << 24;
                                            control += (uint)_readBuf[_sourcePtr++] << 16;
                                        }
                                        control >>= 1;

                                        symbol = _huffman20Table[control & 63];
                                        if (symbol >= 20)
                                        {
                                            do
                                            {
                                                symbol = _huffman20Table[((control >> 6) & 1) + (symbol << 1)];
                                                if (shift-- == 0)
                                                {
                                                    shift += 16;
                                                    control += (uint)_readBuf[_sourcePtr++] << 24;
                                                    control += (uint)_readBuf[_sourcePtr++] << 16;
                                                }
                                                control >>= 1;
                                            } while (symbol >= 20);
                                            temp = 6;
                                        }
                                        else
                                        {
                                            temp = _huffman20Len[symbol];
                                        }

                                        control >>= temp;
                                        if ((shift -= temp) < 0)
                                        {
                                            shift += 16;
                                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                                            control += (uint)_readBuf[_sourcePtr++] << shift;
                                        }

                                        symbol = TableFour[_literalLen[pos] + 17 - symbol];
                                        while (pos < maxSymbol && count-- > 0)
                                            _literalLen[pos++] = (byte)symbol;
                                        break;
                                    }
                                default:
                                    {
                                        symbol = TableFour[_literalLen[pos] + 17 - symbol];
                                        _literalLen[pos++] = (byte)symbol;
                                        break;
                                    }
                            }
                        } while (pos < maxSymbol);

                        fix--;
                        maxSymbol += 512;
                    } while (maxSymbol == 768);

                    if (MakeDecodeTable(768, 12, _literalLen, _literalTable))
                        throw new InvalidDataException("Corrupt LZX literal table.");
                }

                _control = control;
                _shift = shift;
            }

            private void Decrunch()
            {
                uint control = _control;
                int shift = _shift;

                while (_destPtr < _destEnd && _sourcePtr < _sourceEnd)
                {
                    uint symbol = _literalTable[control & 4095];
                    int temp;
                    if (symbol >= 768)
                    {
                        control >>= 12;
                        if ((shift -= 12) < 0)
                        {
                            shift += 16;
                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                            control += (uint)_readBuf[_sourcePtr++] << shift;
                        }
                        do
                        {
                            symbol = _literalTable[(control & 1) + (symbol << 1)];
                            if (shift-- == 0)
                            {
                                shift += 16;
                                control += (uint)_readBuf[_sourcePtr++] << 24;
                                control += (uint)_readBuf[_sourcePtr++] << 16;
                            }
                            control >>= 1;
                        } while (symbol >= 768);
                    }
                    else
                    {
                        temp = _literalLen[symbol];
                        control >>= temp;
                        if ((shift -= temp) < 0)
                        {
                            shift += 16;
                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                            control += (uint)_readBuf[_sourcePtr++] << shift;
                        }
                    }

                    if (symbol < 256)
                    {
                        _decrunchBuf[_destPtr++] = (byte)symbol;
                    }
                    else
                    {
                        symbol -= 256;
                        uint count = TableTwo[temp = (int)(symbol & 31)];
                        temp = TableOne[temp];
                        if (temp >= 3 && _decrunchMethod == 3)
                        {
                            temp -= 3;
                            count += (control & TableThree[temp]) << 3;
                            control >>= temp;
                            if ((shift -= temp) < 0)
                            {
                                shift += 16;
                                control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                                control += (uint)_readBuf[_sourcePtr++] << shift;
                            }
                            uint offSym = _offsetTable[control & 127];
                            count += offSym;
                            temp = _offsetLen[offSym];
                        }
                        else
                        {
                            count += control & TableThree[temp];
                            if (count == 0) count = _lastOffset;
                        }
                        control >>= temp;
                        if ((shift -= temp) < 0)
                        {
                            shift += 16;
                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                            control += (uint)_readBuf[_sourcePtr++] << shift;
                        }
                        _lastOffset = count;

                        count = TableTwo[temp = (int)((symbol >> 5) & 15)] + 3;
                        temp = TableOne[temp];
                        count += control & TableThree[temp];
                        control >>= temp;
                        if ((shift -= temp) < 0)
                        {
                            shift += 16;
                            control += (uint)_readBuf[_sourcePtr++] << (8 + shift);
                            control += (uint)_readBuf[_sourcePtr++] << shift;
                        }

                        int stringPtr = ((int)_lastOffset <= _destPtr)
                            ? (_destPtr - (int)_lastOffset)
                            : (_destPtr + 65536 - (int)_lastOffset);

                        while (count-- > 0)
                        {
                            _decrunchBuf[_destPtr++] = _decrunchBuf[stringPtr++];
                        }
                    }
                }

                _control = control;
                _shift = shift;
            }

            public uint ExtractToFile(Stream outStream, int unpackSize)
            {
                uint crc = 0;
                while (unpackSize > 0)
                {
                    if (_posPtr == _destPtr)
                    {
                        if (_sourcePtr >= _sourceEnd)
                        {
                            FillReadBuffer();
                            if (_sourcePtr >= _sourceLen) break;
                        }

                        if (_decrunchLength <= 0)
                        {
                            ReadLiteralTable();
                        }

                        if (_destPtr >= 258 + 65536)
                        {
                            int count = _destPtr - 65536;
                            Buffer.BlockCopy(_decrunchBuf, 65536, _decrunchBuf, 0, count);
                            _destPtr = count;
                            _posPtr = count;
                        }

                        _destEnd = _destPtr + _decrunchLength;
                        if (_destEnd > 258 + 65536)
                            _destEnd = 258 + 65536;

                        int tempDest = _destPtr;
                        Decrunch();
                        _decrunchLength -= (_destPtr - tempDest);
                    }

                    int avail = _destPtr - _posPtr;
                    if (avail > unpackSize) avail = unpackSize;

                    if (outStream != null)
                    {
                        outStream.Write(_decrunchBuf, _posPtr, avail);
                    }
                    crc = UpdateCrc(_decrunchBuf, _posPtr, avail, crc);

                    unpackSize -= avail;
                    _posPtr += avail;
                }

                return crc;
            }

            public void SkipBytes(int count)
            {
                ExtractToFile(null, count);
            }
        }
    }
}
'@
    Add-Type -TypeDefinition $cSharpSource -Language CSharp
}