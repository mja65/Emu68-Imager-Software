if (-not ([System.Management.Automation.PSTypeName]'AmigaAdf.UnAdfEngine').Type) {
    $csharpCode = @'
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

namespace AmigaAdf
{
    /// <summary>
    /// Amiga DOS File System Types based on Boot Block ID (DOS\0 to DOS\7)
    /// </summary>
    public enum AmigaDosType
    {
        OFS = 0,             // DOS\0: Old File System
        FFS = 1,             // DOS\1: Fast File System
        OFS_INTL = 2,        // DOS\2: OFS International mode
        FFS_INTL = 3,        // DOS\3: FFS International mode
        OFS_DIRCACHE = 4,    // DOS\4: OFS Directory Cache
        FFS_DIRCACHE = 5,    // DOS\5: FFS Directory Cache
        OFS_LONGFNAME = 6,   // DOS\6: OFS Long Filenames
        FFS_LONGFNAME = 7,   // DOS\7: FFS Long Filenames
        UNKNOWN = -1
    }

    /// <summary>
    /// Amiga Block Primary & Secondary Types
    /// </summary>
    public static class AmigaBlockType
    {
        public const int T_SHORT = 2;
        public const int T_DATA = 8;
        public const int T_LIST = 16;
        public const int T_DIRCACHE = 33;

        public const int ST_ROOT = 1;
        public const int ST_USERDIR = 2;
        public const int ST_SOFTLINK = 3;
        public const int ST_LINKDIR = 4;
        public const int ST_FILE = -3;
        public const int ST_LINKFILE = -4;
    }

    /// <summary>
    /// Represents an extracted or inspected entry (file or directory) within an Amiga Disk File.
    /// </summary>
    public class AdfEntry
    {
        public string Name { get; set; }
        public string SanitizedName { get; set; }
        public string AmigaPath { get; set; }
        public string RelativeWindowsPath { get; set; }
        public bool IsDirectory { get; set; }
        public bool IsLink { get; set; }
        public long Size { get; set; }
        public int HeaderBlock { get; set; }
        public DateTime Timestamp { get; set; }
        public uint ProtectionBits { get; set; }
        public string ProtectionString { get; set; }
        public string Comment { get; set; }
        public List<int> DataBlocks { get; set; }
        public List<AdfEntry> Children { get; set; }

        public AdfEntry()
        {
            DataBlocks = new List<int>();
            Children = new List<AdfEntry>();
            Name = string.Empty;
            SanitizedName = string.Empty;
            AmigaPath = string.Empty;
            RelativeWindowsPath = string.Empty;
            Comment = string.Empty;
            ProtectionString = "----rwed";
        }
    }

    /// <summary>
    /// High-level disk image information
    /// </summary>
    public class AdfDiskInfo
    {
        public string DiskName { get; set; }
        public string SanitizedDiskName { get; set; }
        public AmigaDosType DosType { get; set; }
        public string DosTypeString { get; set; }
        public bool IsFFS { get; set; }
        public bool IsInternational { get; set; }
        public bool IsDirCache { get; set; }
        public int BlockSize { get; set; }
        public int TotalBlocks { get; set; }
        public long TotalSizeBytes { get; set; }
        public int RootBlockNumber { get; set; }
        public DateTime CreationDate { get; set; }
        public DateTime AlterationDate { get; set; }
        public int TotalFiles { get; set; }
        public int TotalDirectories { get; set; }
        public long TotalDataBytes { get; set; }

        public AdfDiskInfo()
        {
            BlockSize = 512;
            DiskName = "Workbench";
            SanitizedDiskName = "Workbench";
            DosTypeString = "DOS/0 (OFS)";
        }
    }

    /// <summary>
    /// Options controlling extraction and listing, mirroring the 'unadf' command line tool.
    /// </summary>
    public class UnAdfOptions
    {
        public bool ListOnly { get; set; }
        public bool Recursive { get; set; }
        public bool Extract { get; set; }
        public bool PrintSizes { get; set; }
        public int Verbosity { get; set; }             // 0 = quiet, 1 = normal, 2 = verbose
        public char WildcardReplaceChar { get; set; }   // -w argument character
        public string DestinationDir { get; set; }
        public string Filter { get; set; }
        public bool PipeToConsole { get; set; }

        public UnAdfOptions()
        {
            ListOnly = false;
            Recursive = true;
            Extract = false;
            PrintSizes = false;
            Verbosity = 1;
            WildcardReplaceChar = '_';
            DestinationDir = ".";
            Filter = string.Empty;
            PipeToConsole = false;
        }
    }

    /// <summary>
    /// Replicates the ADFlib unadf utility for PowerShell 5.1 and .NET.
    /// Handles OFS/FFS Amiga Disk File archives, Latin-1 encoding,
    /// Amiga special characters, and Windows 10/11 filesystem constraints.
    /// </summary>
    public class UnAdfEngine
    {
        private byte[] diskData;
        private int blockSize;
        private int totalBlocks;
        private Encoding amigaEncoding;
        private char replaceChar;

        public AdfDiskInfo DiskInfo { get; private set; }
        public AdfEntry RootDirectory { get; private set; }

        public UnAdfEngine()
        {
            blockSize = 512;
            replaceChar = '_';
            try
            {
                amigaEncoding = Encoding.GetEncoding("iso-8859-1");
            }
            catch
            {
                // Fallback to Latin-1 compatible code page if not registered
                amigaEncoding = Encoding.GetEncoding(28591);
            }
        }

        /// <summary>
        /// Loads an ADF image from disk file path.
        /// </summary>
        public void Load(string adfPath, char wildcardReplaceChar)
        {
            if (string.IsNullOrEmpty(adfPath))
                throw new ArgumentNullException("adfPath");
            if (!File.Exists(adfPath))
                throw new FileNotFoundException("ADF image not found: " + adfPath);

            byte[] bytes = File.ReadAllBytes(adfPath);
            Load(bytes, wildcardReplaceChar);
        }

        /// <summary>
        /// Loads an ADF image directly from a byte array.
        /// </summary>
        public void Load(byte[] rawData, char wildcardReplaceChar)
        {
            if (rawData == null || rawData.Length < 1024)
                throw new ArgumentException("ADF image data is invalid or too small.");

            diskData = rawData;
            blockSize = 512;
            totalBlocks = diskData.Length / blockSize;
            replaceChar = wildcardReplaceChar != '\0' ? wildcardReplaceChar : '_';

            ParseDisk();
        }

        private void ParseDisk()
        {
            DiskInfo = new AdfDiskInfo();
            DiskInfo.BlockSize = blockSize;
            DiskInfo.TotalBlocks = totalBlocks;
            DiskInfo.TotalSizeBytes = diskData.Length;

            // 1. Inspect Boot Block (Blocks 0 & 1)
            byte[] bootBlock = ReadBlock(0);
            if (bootBlock.Length >= 4 && bootBlock[0] == 'D' && bootBlock[1] == 'O' && bootBlock[2] == 'S')
            {
                byte flag = bootBlock[3];
                int dosNum = (int)flag;
                if (dosNum >= 0 && dosNum <= 7)
                {
                    DiskInfo.DosType = (AmigaDosType)dosNum;
                }
                else
                {
                    DiskInfo.DosType = AmigaDosType.UNKNOWN;
                }
            }
            else
            {
                DiskInfo.DosType = AmigaDosType.OFS;
            }

            int dosVal = (int)DiskInfo.DosType;
            DiskInfo.IsFFS = (dosVal & 1) == 1;
            DiskInfo.IsInternational = (dosVal & 2) == 2;
            DiskInfo.IsDirCache = (dosVal & 4) == 4;

            string dosTypeName = "Unknown";
            switch (DiskInfo.DosType)
            {
                case AmigaDosType.OFS: dosTypeName = "OFS - Old File System"; break;
                case AmigaDosType.FFS: dosTypeName = "FFS - Fast File System"; break;
                case AmigaDosType.OFS_INTL: dosTypeName = "OFS-INTL - International"; break;
                case AmigaDosType.FFS_INTL: dosTypeName = "FFS-INTL - International"; break;
                case AmigaDosType.OFS_DIRCACHE: dosTypeName = "OFS-DIRCACHE - Directory Cache"; break;
                case AmigaDosType.FFS_DIRCACHE: dosTypeName = "FFS-DIRCACHE - Directory Cache"; break;
                case AmigaDosType.OFS_LONGFNAME: dosTypeName = "OFS-LONG - Long Names"; break;
                case AmigaDosType.FFS_LONGFNAME: dosTypeName = "FFS-LONG - Long Names"; break;
                default: dosTypeName = "Unknown Amiga DOS Type"; break;
            }
            DiskInfo.DosTypeString = string.Format("DOS/{0} ({1})", dosVal, dosTypeName);

            // 2. Locate Root Block: standard location is totalBlocks / 2
            int rootBlock = totalBlocks / 2;
            if (rootBlock < 0 || rootBlock >= totalBlocks)
                rootBlock = 880;

            byte[] rootData = ReadBlock(rootBlock);
            int rootType = ReadBigEndianInt32(rootData, 0);
            int rootSecType = ReadBigEndianInt32(rootData, 508);

            // Fallback probe around standard floppy (880)
            if (rootType != AmigaBlockType.T_SHORT || rootSecType != AmigaBlockType.ST_ROOT)
            {
                if (totalBlocks >= 881)
                {
                    byte[] probe880 = ReadBlock(880);
                    if (ReadBigEndianInt32(probe880, 0) == AmigaBlockType.T_SHORT &&
                        ReadBigEndianInt32(probe880, 508) == AmigaBlockType.ST_ROOT)
                    {
                        rootBlock = 880;
                        rootData = probe880;
                    }
                }
            }

            DiskInfo.RootBlockNumber = rootBlock;

            // Extract Volume Name (Byte 432: BSTR format = length byte, then chars)
            int nameLen = (int)rootData[432];
            if (nameLen > 30) nameLen = 30;
            if (nameLen > 0)
            {
                DiskInfo.DiskName = amigaEncoding.GetString(rootData, 433, nameLen);
            }
            else
            {
                DiskInfo.DiskName = "Workbench";
            }
            DiskInfo.SanitizedDiskName = SanitizeFilename(DiskInfo.DiskName, replaceChar);

            // Read Alteration Date (bytes 420..431: c_days, c_mins, c_ticks)
            int cDays = ReadBigEndianInt32(rootData, 420);
            int cMins = ReadBigEndianInt32(rootData, 424);
            int cTicks = ReadBigEndianInt32(rootData, 428);
            DiskInfo.AlterationDate = ConvertAmigaDate(cDays, cMins, cTicks);

            // Read Creation Date (bytes 476..487: c2_days, c2_mins, c2_ticks)
            int c2Days = ReadBigEndianInt32(rootData, 476);
            int c2Mins = ReadBigEndianInt32(rootData, 480);
            int c2Ticks = ReadBigEndianInt32(rootData, 484);
            DiskInfo.CreationDate = ConvertAmigaDate(c2Days, c2Mins, c2Ticks);

            // 3. Parse Directory Tree starting from Root Block
            RootDirectory = new AdfEntry();
            RootDirectory.Name = DiskInfo.DiskName;
            RootDirectory.SanitizedName = DiskInfo.SanitizedDiskName;
            RootDirectory.AmigaPath = DiskInfo.DiskName + ":";
            RootDirectory.RelativeWindowsPath = "";
            RootDirectory.IsDirectory = true;
            RootDirectory.HeaderBlock = rootBlock;
            RootDirectory.Timestamp = DiskInfo.AlterationDate;

            HashSet<int> visitedBlocks = new HashSet<int>();
            visitedBlocks.Add(rootBlock);

            int fileCount = 0;
            int dirCount = 0;
            long totalBytes = 0;

            ParseDirectoryHashTable(rootData, RootDirectory, visitedBlocks, ref fileCount, ref dirCount, ref totalBytes);

            DiskInfo.TotalFiles = fileCount;
            DiskInfo.TotalDirectories = dirCount;
            DiskInfo.TotalDataBytes = totalBytes;
        }

        private void ParseDirectoryHashTable(byte[] dirBlockData, AdfEntry parentEntry, HashSet<int> visited,
                                             ref int fileCount, ref int dirCount, ref long totalBytes)
        {
            // Hash table has 72 entries: words 6..77 (byte offset 24 to 311)
            for (int i = 0; i < 72; i++)
            {
                int entryBlock = ReadBigEndianInt32(dirBlockData, 24 + (i * 4));
                while (entryBlock > 0 && entryBlock < totalBlocks && !visited.Contains(entryBlock))
                {
                    visited.Add(entryBlock);

                    byte[] entryData = ReadBlock(entryBlock);
                    int primaryType = ReadBigEndianInt32(entryData, 0);
                    int secType = ReadBigEndianInt32(entryData, 508);

                    if (primaryType == AmigaBlockType.T_SHORT)
                    {
                        AdfEntry entry = ParseEntryBlock(entryData, entryBlock, parentEntry);

                        if (entry != null)
                        {
                            parentEntry.Children.Add(entry);

                            if (entry.IsDirectory)
                            {
                                dirCount++;
                                ParseDirectoryHashTable(entryData, entry, visited, ref fileCount, ref dirCount, ref totalBytes);
                            }
                            else
                            {
                                fileCount++;
                                totalBytes += entry.Size;
                            }
                        }
                    }

                    // Move to next collision in this hash bucket (word 124, offset 496: nextSameHash)
                    entryBlock = ReadBigEndianInt32(entryData, 496);
                }
            }
        }

        private AdfEntry ParseEntryBlock(byte[] blockData, int blockNum, AdfEntry parent)
        {
            int secType = ReadBigEndianInt32(blockData, 508);

            bool isDir = (secType == AmigaBlockType.ST_USERDIR || secType == AmigaBlockType.ST_LINKDIR);
            bool isFile = (secType == AmigaBlockType.ST_FILE || secType == AmigaBlockType.ST_LINKFILE);

            if (!isDir && !isFile)
                return null;

            AdfEntry entry = new AdfEntry();
            entry.HeaderBlock = blockNum;
            entry.IsDirectory = isDir;
            entry.IsLink = (secType == AmigaBlockType.ST_LINKDIR || secType == AmigaBlockType.ST_LINKFILE || secType == AmigaBlockType.ST_SOFTLINK);

            // Filename: byte 432 is length, followed by ISO-8859-1 characters
            int nameLen = (int)blockData[432];
            if (nameLen > 30) nameLen = 30;
            if (nameLen > 0)
            {
                entry.Name = amigaEncoding.GetString(blockData, 433, nameLen);
            }
            else
            {
                entry.Name = "unnamed_" + blockNum.ToString();
            }

            // Sanitize name for Windows 10/11 using replacement character
            entry.SanitizedName = SanitizeFilename(entry.Name, replaceChar);

            // Construct paths - both Amiga path and sanitized Windows path
            if (string.IsNullOrEmpty(parent.AmigaPath) || parent.AmigaPath.EndsWith(":"))
            {
                entry.AmigaPath = parent.AmigaPath + entry.Name;
                entry.RelativeWindowsPath = entry.SanitizedName;
            }
            else
            {
                entry.AmigaPath = parent.AmigaPath + "/" + entry.Name;
                if (string.IsNullOrEmpty(parent.RelativeWindowsPath))
                {
                    entry.RelativeWindowsPath = entry.SanitizedName;
                }
                else
                {
                    entry.RelativeWindowsPath = Path.Combine(parent.RelativeWindowsPath, entry.SanitizedName);
                }
            }

            // Protection bits (word 80, offset 320)
            entry.ProtectionBits = (uint)ReadBigEndianInt32(blockData, 320);
            entry.ProtectionString = FormatProtectionBits(entry.ProtectionBits);

            // File Size (word 81, offset 324)
            if (isFile)
            {
                entry.Size = (long)(uint)ReadBigEndianInt32(blockData, 324);
            }
            else
            {
                entry.Size = 0;
            }

            // Comment (byte 328: length, followed by comment text)
            int commLen = (int)blockData[328];
            if (commLen > 79) commLen = 79;
            if (commLen > 0)
            {
                entry.Comment = amigaEncoding.GetString(blockData, 329, commLen);
            }

            // Timestamp (words 105..107, offsets 420..431: days, mins, ticks)
            int days = ReadBigEndianInt32(blockData, 420);
            int mins = ReadBigEndianInt32(blockData, 424);
            int ticks = ReadBigEndianInt32(blockData, 428);
            entry.Timestamp = ConvertAmigaDate(days, mins, ticks);

            // If it's a file, collect data blocks
            if (isFile)
            {
                CollectFileDataBlocks(blockData, entry);
            }

            return entry;
        }

        private void CollectFileDataBlocks(byte[] headerBlock, AdfEntry entry)
        {
            int highSeq = ReadBigEndianInt32(headerBlock, 8);
            if (highSeq > 72) highSeq = 72;

            for (int k = 0; k < highSeq; k++)
            {
                int ptr = ReadBigEndianInt32(headerBlock, 24 + ((71 - k) * 4));
                if (ptr > 0 && ptr < totalBlocks)
                {
                    entry.DataBlocks.Add(ptr);
                }
            }

            // Extension blocks (word 126, offset 504: extension)
            int extBlock = ReadBigEndianInt32(headerBlock, 504);
            HashSet<int> visitedExt = new HashSet<int>();

            while (extBlock > 0 && extBlock < totalBlocks && !visitedExt.Contains(extBlock))
            {
                visitedExt.Add(extBlock);
                byte[] extData = ReadBlock(extBlock);
                int extType = ReadBigEndianInt32(extData, 0);
                int extSecType = ReadBigEndianInt32(extData, 508);

                if (extType == AmigaBlockType.T_LIST && extSecType == AmigaBlockType.ST_FILE)
                {
                    int extHighSeq = ReadBigEndianInt32(extData, 8);
                    if (extHighSeq > 72) extHighSeq = 72;

                    for (int k = 0; k < extHighSeq; k++)
                    {
                        int ptr = ReadBigEndianInt32(extData, 24 + ((71 - k) * 4));
                        if (ptr > 0 && ptr < totalBlocks)
                        {
                            entry.DataBlocks.Add(ptr);
                        }
                    }

                    extBlock = ReadBigEndianInt32(extData, 504);
                }
                else
                {
                    break;
                }
            }
        }

        /// <summary>
        /// Reads and extracts the complete binary content of a file entry.
        /// </summary>
        public byte[] ReadFileContent(AdfEntry entry)
        {
            if (entry == null || entry.IsDirectory)
                return new byte[0];

            long expectedSize = entry.Size;
            byte[] fileBytes = new byte[expectedSize];
            long bytesWritten = 0;

            bool isFFS = DiskInfo != null && DiskInfo.IsFFS;

            for (int i = 0; i < entry.DataBlocks.Count; i++)
            {
                if (bytesWritten >= expectedSize)
                    break;

                int blockNum = entry.DataBlocks[i];
                if (blockNum <= 0 || blockNum >= totalBlocks)
                    continue;

                byte[] blk = ReadBlock(blockNum);
                long bytesRemaining = expectedSize - bytesWritten;

                if (isFFS)
                {
                    int copyLen = (int)Math.Min((long)blockSize, bytesRemaining);
                    Array.Copy(blk, 0, fileBytes, bytesWritten, copyLen);
                    bytesWritten += copyLen;
                }
                else
                {
                    int dataSize = ReadBigEndianInt32(blk, 12);
                    if (dataSize <= 0 || dataSize > 488) dataSize = 488;

                    int copyLen = (int)Math.Min((long)dataSize, bytesRemaining);
                    if (copyLen > 0 && (24 + copyLen) <= blk.Length)
                    {
                        Array.Copy(blk, 24, fileBytes, bytesWritten, copyLen);
                        bytesWritten += copyLen;
                    }
                }
            }

            return fileBytes;
        }

        /// <summary>
        /// Flattens the directory tree into a simple list of all entries.
        /// </summary>
        public List<AdfEntry> GetAllEntries(bool includeDirectories)
        {
            List<AdfEntry> results = new List<AdfEntry>();
            if (RootDirectory != null)
            {
                CollectEntriesRecursive(RootDirectory, results, includeDirectories);
            }
            return results;
        }

        private void CollectEntriesRecursive(AdfEntry current, List<AdfEntry> list, bool includeDirs)
        {
            for (int i = 0; i < current.Children.Count; i++)
            {
                AdfEntry child = current.Children[i];
                if (child.IsDirectory)
                {
                    if (includeDirs) list.Add(child);
                    CollectEntriesRecursive(child, list, includeDirs);
                }
                else
                {
                    list.Add(child);
                }
            }
        }

        /// <summary>
        /// Executes extraction according to the provided UnAdfOptions.
        /// </summary>
        public int ExtractAll(UnAdfOptions options, Action<string> logCallback)
        {
            if (options == null)
                options = new UnAdfOptions();

            string baseDest = string.IsNullOrEmpty(options.DestinationDir) ? "." : options.DestinationDir;
            if (!Directory.Exists(baseDest))
            {
                Directory.CreateDirectory(baseDest);
            }

            List<AdfEntry> all = GetAllEntries(true);
            int extractedCount = 0;

            for (int i = 0; i < all.Count; i++)
            {
                AdfEntry item = all[i];

                if (!string.IsNullOrEmpty(options.Filter))
                {
                    if (item.Name.IndexOf(options.Filter, StringComparison.OrdinalIgnoreCase).Equals(-1) &&
                        item.AmigaPath.IndexOf(options.Filter, StringComparison.OrdinalIgnoreCase).Equals(-1))
                    {
                        continue;
                    }
                }

                string targetPath = Path.Combine(baseDest, item.RelativeWindowsPath);

                if (item.IsDirectory)
                {
                    if (!Directory.Exists(targetPath))
                    {
                        Directory.CreateDirectory(targetPath);
                        if (logCallback != null && options.Verbosity > 0)
                            logCallback("Created dir: " + targetPath);
                    }
                }
                else
                {
                    string dir = Path.GetDirectoryName(targetPath);
                    if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                    {
                        Directory.CreateDirectory(dir);
                    }

                    byte[] content = ReadFileContent(item);
                    File.WriteAllBytes(targetPath, content);

                    try
                    {
                        File.SetLastWriteTime(targetPath, item.Timestamp);
                    }
                    catch { }

                    extractedCount++;

                    if (logCallback != null && options.Verbosity > 0)
                    {
                        if (options.PrintSizes)
                        {
                            logCallback(string.Format("Extracted: {0} ({1} bytes) -> {2}", item.AmigaPath, item.Size, targetPath));
                        }
                        else
                        {
                            logCallback("Extracted: " + targetPath);
                        }
                    }
                }
            }

            return extractedCount;
        }

        /// <summary>
        /// Extracts a specific single entry to the target directory.
        /// Returns the full path of the extracted file, or null if directory or error.
        /// </summary>
        public string ExtractEntry(AdfEntry item, string baseDest)
        {
            if (item == null) return null;
            if (string.IsNullOrEmpty(baseDest)) baseDest = ".";
            if (!Directory.Exists(baseDest)) Directory.CreateDirectory(baseDest);

            string targetPath = Path.Combine(baseDest, item.RelativeWindowsPath);
            if (item.IsDirectory)
            {
                if (!Directory.Exists(targetPath)) Directory.CreateDirectory(targetPath);
                return targetPath;
            }
            else
            {
                string dir = Path.GetDirectoryName(targetPath);
                if (!string.IsNullOrEmpty(dir) && !Directory.Exists(dir))
                {
                    Directory.CreateDirectory(dir);
                }
                byte[] content = ReadFileContent(item);
                File.WriteAllBytes(targetPath, content);
                try { File.SetLastWriteTime(targetPath, item.Timestamp); } catch { }
                return targetPath;
            }
        }

        /// <summary>
        /// Reads the content of an Amiga file specified by its Amiga path or filename.
        /// </summary>
        public byte[] ReadFileContentByPath(string pathOrName)
        {
            if (string.IsNullOrEmpty(pathOrName)) return new byte[0];
            List<AdfEntry> all = GetAllEntries(false);
            for (int i = 0; i < all.Count; i++)
            {
                AdfEntry item = all[i];
                if (string.Equals(item.Name, pathOrName, StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(item.AmigaPath, pathOrName, StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(item.RelativeWindowsPath, pathOrName, StringComparison.OrdinalIgnoreCase) ||
                    item.AmigaPath.EndsWith("/" + pathOrName, StringComparison.OrdinalIgnoreCase) ||
                    item.RelativeWindowsPath.EndsWith("\\" + pathOrName, StringComparison.OrdinalIgnoreCase))
                {
                    return ReadFileContent(item);
                }
            }
            return new byte[0];
        }

        /// <summary>
        /// Finds entries matching a wildcard or substring.
        /// </summary>
        public List<AdfEntry> FindEntries(string pattern, bool includeDirectories)
        {
            List<AdfEntry> results = new List<AdfEntry>();
            List<AdfEntry> all = GetAllEntries(includeDirectories);
            if (string.IsNullOrEmpty(pattern) || pattern == "*")
            {
                return all;
            }
            for (int i = 0; i < all.Count; i++)
            {
                AdfEntry item = all[i];
                if (item.Name.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0 ||
                    item.AmigaPath.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0 ||
                    item.RelativeWindowsPath.IndexOf(pattern, StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    results.Add(item);
                }
            }
            return results;
        }

        #region Helper Methods

        private byte[] ReadBlock(int blockNum)
        {
            byte[] block = new byte[blockSize];
            int offset = blockNum * blockSize;
            if (offset >= 0 && offset + blockSize <= diskData.Length)
            {
                Array.Copy(diskData, offset, block, 0, blockSize);
            }
            return block;
        }

        public static int ReadBigEndianInt32(byte[] data, int offset)
        {
            if (offset + 4 > data.Length) return 0;
            return (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3];
        }

        /// <summary>
        /// Converts AmigaDOS days/mins/ticks timestamp to .NET DateTime.
        /// Amiga epoch is Jan 1, 1978. Ticks are 1/50th of a second.
        /// </summary>
        public static DateTime ConvertAmigaDate(int days, int mins, int ticks)
        {
            try
            {
                DateTime baseDate = new DateTime(1978, 1, 1, 0, 0, 0, DateTimeKind.Utc);
                if (days < 0 || days > 50000) return baseDate;
                DateTime result = baseDate.AddDays(days).AddMinutes(mins).AddSeconds(ticks / 50.0);
                return result.ToLocalTime();
            }
            catch
            {
                return new DateTime(1978, 1, 1);
            }
        }

        /// <summary>
        /// Formats Amiga protection bits as HSPARWED string.
        /// </summary>
        public static string FormatProtectionBits(uint mask)
        {
            char h = (mask & 128) != 0 ? 'h' : '-'; // Hold
            char s = (mask & 64) != 0 ? 's' : '-';  // Script
            char p = (mask & 32) != 0 ? 'p' : '-';  // Pure
            char a = (mask & 16) != 0 ? 'a' : '-';  // Archive
            char r = (mask & 8) == 0 ? 'r' : '-';   // Read (0 = allowed)
            char w = (mask & 4) == 0 ? 'w' : '-';   // Write (0 = allowed)
            char e = (mask & 2) == 0 ? 'e' : '-';   // Execute (0 = allowed)
            char d = (mask & 1) == 0 ? 'd' : '-';   // Delete (0 = allowed)

            return new string(new char[] { h, s, p, a, r, w, e, d });
        }

        /// <summary>
        /// Sanitizes an Amiga filename into a valid Windows 10/11 NTFS/FAT filename,
        /// replacing illegal characters and Amiga special / extended characters (codes >= 127
        /// such as ñ, é, ä, ö, ü, etc.) with the -w replacement character, handling
        /// trailing periods/spaces and Windows reserved device names (CON, PRN, AUX, etc.).
        /// </summary>
        public static string SanitizeFilename(string amigaName, char replaceChar)
        {
            if (string.IsNullOrEmpty(amigaName))
                return "unnamed";

            StringBuilder sb = new StringBuilder();

            // Characters forbidden on Windows or Amiga special / non-ASCII characters:
            // \ / : * ? " < > | and control characters < 32 and non-ASCII >= 127 (including ñ, é, etc.)
            for (int i = 0; i < amigaName.Length; i++)
            {
                char c = amigaName[i];
                if (c == '\\' || c == '/' || c == ':' || c == '*' || c == '?' ||
                    c == '"' || c == '<' || c == '>' || c == '|' || (int)c < 32 || (int)c >= 127)
                {
                    sb.Append(replaceChar);
                }
                else
                {
                    sb.Append(c);
                }
            }

            string result = sb.ToString();

            // Windows cannot have names ending with space or dot
            while (result.Length > 0 && (result[result.Length - 1] == '.' || result[result.Length - 1] == ' '))
            {
                result = result.Substring(0, result.Length - 1) + replaceChar;
            }

            if (result.Length == 0)
                result = replaceChar.ToString();

            // Check Windows Reserved Device Names: CON, PRN, AUX, NUL, COM1-9, LPT1-9
            string nameWithoutExt = result;
            int dotIdx = result.IndexOf('.');
            if (dotIdx > 0)
            {
                nameWithoutExt = result.Substring(0, dotIdx);
            }

            string upper = nameWithoutExt.ToUpperInvariant();
            if (upper == "CON" || upper == "PRN" || upper == "AUX" || upper == "NUL" ||
                upper == "COM1" || upper == "COM2" || upper == "COM3" || upper == "COM4" ||
                upper == "COM5" || upper == "COM6" || upper == "COM7" || upper == "COM8" || upper == "COM9" ||
                upper == "LPT1" || upper == "LPT2" || upper == "LPT3" || upper == "LPT4" ||
                upper == "LPT5" || upper == "LPT6" || upper == "LPT7" || upper == "LPT8" || upper == "LPT9")
            {
                if (dotIdx > 0)
                {
                    result = nameWithoutExt + replaceChar + result.Substring(dotIdx);
                }
                else
                {
                    result = result + replaceChar;
                }
            }

            return result;
        }

        #endregion
    }
}

'@
    Add-Type -TypeDefinition $csharpCode -Language CSharp
}