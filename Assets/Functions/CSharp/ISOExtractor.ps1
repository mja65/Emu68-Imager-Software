$CSharpSource = @"
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

public class ISOItem {
    public string Name { get; set; }
    public string Path { get; set; }            // Relative path, e.g. "C\Copy" or "Libs\mathffp.library"
    public bool IsDirectory { get; set; }
    public long Size { get; set; }              // For files: file size in bytes. For folders: recursive total size of all contained files!
    public long DirectSize { get; set; }        // For folders: sum of immediate files in this folder only
    public int FileCount { get; set; }          // For folders: recursive count of files inside this folder
    public int SubfolderCount { get; set; }     // For folders: recursive count of subfolders inside this folder
    public uint LBA { get; set; }               // Logical Block Address (Sector offset)
    public DateTime DateTime { get; set; }      // Disc record timestamp
    public byte Flags { get; set; }             // ISO 9660 flags (0x02 = Dir, 0x01 = Hidden)
    public string Attributes { get; set; }      // Amiga/ISO protection string, e.g. "d---rwed", "----rwed"
    public string FormattedSize {
        get {
            if (Size < 1024) return Size + " B";
            if (Size < 1024 * 1024) return (Size / 1024.0).ToString("0.0") + " KB";
            if (Size < 1024L * 1024 * 1024) return (Size / (1024.0 * 1024)).ToString("0.0") + " MB";
            return (Size / (1024.0 * 1024 * 1024)).ToString("0.00") + " GB";
        }
    }
}

public class ISOExtractor {
    // -----------------------------------------------------------------------------------------
    // NEW METHOD: Get complete file and folder listing with recursive folder sizes & attributes
    // -----------------------------------------------------------------------------------------
    public static List<ISOItem> GetEntries(string isoPath) {
        var results = new List<ISOItem>();
        if (!File.Exists(isoPath)) return results;

        using (FileStream fs = File.OpenRead(isoPath))
        using (BinaryReader br = new BinaryReader(fs)) {
            int sectorSize = 2048;
            Encoding latin1 = Encoding.GetEncoding("ISO-8859-1");

            // Locate Primary Volume Descriptor (scan sectors 16..31 to handle CDTV/CD32 boot sectors safely)
            uint rootLBA = 0;
            uint rootSize = 0;
            for (int s = 16; s < 32; s++) {
                fs.Position = (long)s * sectorSize;
                byte[] vd = br.ReadBytes(sectorSize);
                if (vd.Length < sectorSize) break;
                if (latin1.GetString(vd, 1, 5) != "CD001") break;

                byte descType = vd[0];
                if (descType == 1) { // Primary Volume Descriptor
                    rootLBA = BitConverter.ToUInt32(vd, 156 + 2);
                    rootSize = BitConverter.ToUInt32(vd, 156 + 10);
                    break;
                }
                if (descType == 255) break; // Volume Descriptor Set Terminator
            }

            if (rootLBA == 0 || rootSize == 0) return results;

            // Breadth-First directory traversal
            var dirQueue = new Queue<Tuple<uint, uint, string>>();
            dirQueue.Enqueue(new Tuple<uint, uint, string>(rootLBA, rootSize, ""));

            var folderDict = new Dictionary<string, ISOItem>(StringComparer.OrdinalIgnoreCase);

            while (dirQueue.Count > 0) {
                var currentDir = dirQueue.Dequeue();
                fs.Position = (long)currentDir.Item1 * sectorSize;
                byte[] dirData = br.ReadBytes((int)currentDir.Item2);

                int offset = 0;
                while (offset < dirData.Length) {
                    int recLen = dirData[offset];
                    if (recLen == 0) {
                        int rem = offset % sectorSize;
                        offset += (rem == 0 ? sectorSize : sectorSize - rem);
                        continue;
                    }

                    if (offset + recLen > dirData.Length) break;

                    byte flags = dirData[offset + 25];
                    int nameLen = dirData[offset + 32];

                    if (nameLen > 0 && (offset + 33 + nameLen) <= dirData.Length) {
                        string name = latin1.GetString(dirData, offset + 33, nameLen).Split(';')[0];
                        if (name.EndsWith(".")) name = name.Substring(0, name.Length - 1);

                        uint fileLBA = BitConverter.ToUInt32(dirData, offset + 2);
                        uint fileSize = BitConverter.ToUInt32(dirData, offset + 10);

                        // Parse Rock Ridge SUSP extensions (NM, CL, AS, PX, TF)
                        int suaOffset = offset + 33 + nameLen;
                        if (nameLen % 2 == 0) suaOffset++;
                        int suaLen = recLen - (suaOffset - offset);

                        string amigaProt = ((flags & 0x02) == 0x02) ? "d---rwed" : "----rwed";

                        if (suaLen >= 4 && suaOffset + suaLen <= dirData.Length) {
                            int scan = suaOffset;
                            while (scan <= (suaOffset + suaLen - 4)) {
                                string sig = latin1.GetString(dirData, scan, 2);
                                int len = dirData[scan + 2];
                                if (len < 4) break;

                                if (sig == "NM" && scan + 5 <= dirData.Length) {
                                    int nmlen = len - 5;
                                    if (nmlen > 0 && scan + 5 + nmlen <= dirData.Length) {
                                        name = latin1.GetString(dirData, scan + 5, nmlen);
                                    }
                                } else if (sig == "CL" && scan + 8 <= dirData.Length) {
                                    fileLBA = BitConverter.ToUInt32(dirData, scan + 4);
                                } else if (sig == "AS" && scan + 8 <= dirData.Length) {
                                    uint protBits = BitConverter.ToUInt32(dirData, scan + 4);
                                    char h = (protBits & 0x80) != 0 ? 'h' : '-';
                                    char s = (protBits & 0x40) != 0 ? 's' : '-';
                                    char p = (protBits & 0x20) != 0 ? 'p' : '-';
                                    char a = (protBits & 0x10) != 0 ? 'a' : '-';
                                    char r = (protBits & 0x08) == 0 ? 'r' : '-';
                                    char w = (protBits & 0x04) == 0 ? 'w' : '-';
                                    char e = (protBits & 0x02) == 0 ? 'e' : '-';
                                    char d = (protBits & 0x01) == 0 ? 'd' : '-';
                                    amigaProt = new string(new char[] { h, s, p, a, r, w, e, d });
                                }
                                scan += len;
                            }
                        }

                        // Skip '.' (current dir) and '..' (parent dir)
                        if (dirData[offset + 33] != 0 && dirData[offset + 33] != 1) {
                            if (name == "rr_moved" || name == ".rr_moved") {
                                offset += recLen;
                                continue;
                            }

                            string relPath = string.IsNullOrEmpty(currentDir.Item3) ? name : currentDir.Item3 + "\\" + name;

                            // Parse ISO timestamp
                            DateTime itemDate = DateTime.MinValue;
                            try {
                                int yr = 1900 + dirData[offset + 18];
                                int mo = Math.Max(1, Math.Min(12, (int)dirData[offset + 19]));
                                int dy = Math.Max(1, Math.Min(31, (int)dirData[offset + 20]));
                                int hr = Math.Max(0, Math.Min(23, (int)dirData[offset + 21]));
                                int mn = Math.Max(0, Math.Min(59, (int)dirData[offset + 22]));
                                int sc = Math.Max(0, Math.Min(59, (int)dirData[offset + 23]));
                                itemDate = new DateTime(yr, mo, dy, hr, mn, sc);
                            } catch { }

                            bool isDir = (flags & 0x02) == 0x02;
                            var item = new ISOItem {
                                Name = name,
                                Path = relPath,
                                IsDirectory = isDir,
                                Size = isDir ? 0 : fileSize,
                                DirectSize = 0,
                                FileCount = 0,
                                SubfolderCount = 0,
                                LBA = fileLBA,
                                DateTime = itemDate,
                                Flags = flags,
                                Attributes = amigaProt
                            };

                            results.Add(item);

                            if (isDir) {
                                folderDict[relPath] = item;
                                if (fileSize > 0) {
                                    dirQueue.Enqueue(new Tuple<uint, uint, string>(fileLBA, fileSize, relPath));
                                }
                            }
                        }
                    }
                    offset += recLen;
                }
            }

            // -------------------------------------------------------------------------
            // Compute recursive folder sizes, direct sizes, file counts, and folder counts
            // -------------------------------------------------------------------------
            foreach (var item in results) {
                if (item.IsDirectory) continue;

                // For every file, bubble up its size to all its ancestor folders
                string currentPath = item.Path;
                int slashIdx = currentPath.LastIndexOf('\\');
                bool isImmediate = true;

                while (slashIdx >= 0) {
                    string parentPath = currentPath.Substring(0, slashIdx);
                    if (folderDict.ContainsKey(parentPath)) {
                        folderDict[parentPath].Size += item.Size;
                        folderDict[parentPath].FileCount += 1;
                        if (isImmediate) {
                            folderDict[parentPath].DirectSize += item.Size;
                            isImmediate = false;
                        }
                    }
                    slashIdx = parentPath.LastIndexOf('\\');
                }
            }

            // Compute subfolder counts for each folder
            foreach (var item in results) {
                if (!item.IsDirectory) continue;
                string currentPath = item.Path;
                int slashIdx = currentPath.LastIndexOf('\\');
                while (slashIdx >= 0) {
                    string parentPath = currentPath.Substring(0, slashIdx);
                    if (folderDict.ContainsKey(parentPath)) {
                        folderDict[parentPath].SubfolderCount += 1;
                    }
                    slashIdx = parentPath.LastIndexOf('\\');
                }
            }
        }

        return results;
    }

    // -----------------------------------------------------------------------------------------
    // EXISTING METHOD: Kept 100% backwards-compatible, with memory & sector improvements
    // -----------------------------------------------------------------------------------------
    public static void ExtractExplicitFiles(string isoPath, string[] sourcePaths, string[] destPaths) {
        if (sourcePaths == null || destPaths == null || sourcePaths.Length != destPaths.Length) return;

        // Map a single source path to multiple destination targets (normalizing path separators)
        Dictionary<string, List<string>> lookupMap = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < sourcePaths.Length; i++) {
            if (string.IsNullOrEmpty(sourcePaths[i])) continue;
            string normKey = sourcePaths[i].Replace('/', '\\').Trim('\\');
            if (!lookupMap.ContainsKey(normKey)) {
                lookupMap[normKey] = new List<string>();
            }
            lookupMap[normKey].Add(destPaths[i]);
        }

        if (lookupMap.Count == 0) return;

        using (FileStream fs = File.OpenRead(isoPath))
        using (BinaryReader br = new BinaryReader(fs)) {
            int sectorSize = 2048;
            Encoding latin1 = Encoding.GetEncoding("ISO-8859-1");

            // Locate Primary Volume Descriptor (safely scanning past any boot sectors)
            uint rootLBA = 0;
            uint rootSize = 0;
            for (int s = 16; s < 32; s++) {
                fs.Position = (long)s * sectorSize;
                byte[] vd = br.ReadBytes(sectorSize);
                if (vd.Length < sectorSize) break;
                if (latin1.GetString(vd, 1, 5) != "CD001") break;

                if (vd[0] == 1) { // Primary Volume Descriptor
                    rootLBA = BitConverter.ToUInt32(vd, 156 + 2);
                    rootSize = BitConverter.ToUInt32(vd, 156 + 10);
                    break;
                }
                if (vd[0] == 255) break;
            }

            if (rootLBA == 0 || rootSize == 0) return;

            Queue<Tuple<uint, uint, string>> dirQueue = new Queue<Tuple<uint, uint, string>>();
            dirQueue.Enqueue(new Tuple<uint, uint, string>(rootLBA, rootSize, ""));

            while (dirQueue.Count > 0) {
                var currentDir = dirQueue.Dequeue();
                fs.Position = (long)currentDir.Item1 * sectorSize;
                byte[] dirData = br.ReadBytes((int)currentDir.Item2);

                int offset = 0;
                while (offset < dirData.Length) {
                    int recLen = dirData[offset];
                    if (recLen == 0) {
                        int rem = offset % sectorSize;
                        offset += (rem == 0 ? sectorSize : sectorSize - rem);
                        continue;
                    }

                    if (offset + recLen > dirData.Length) break;

                    byte flags = dirData[offset + 25];
                    int nameLen = dirData[offset + 32];

                    if (nameLen > 0 && (offset + 33 + nameLen) <= dirData.Length) {
                        string name = latin1.GetString(dirData, offset + 33, nameLen).Split(';')[0];
                        if (name.EndsWith(".")) name = name.Substring(0, name.Length - 1);

                        uint fileLBA = BitConverter.ToUInt32(dirData, offset + 2);
                        uint fileSize = BitConverter.ToUInt32(dirData, offset + 10);

                        int suaOffset = offset + 33 + nameLen;
                        if (nameLen % 2 == 0) suaOffset++;
                        int suaLen = recLen - (suaOffset - offset);

                        if (suaLen >= 4 && suaOffset + suaLen <= dirData.Length) {
                            int scan = suaOffset;
                            while (scan <= (suaOffset + suaLen - 4)) {
                                string sig = latin1.GetString(dirData, scan, 2);
                                int len = dirData[scan + 2];
                                if (len < 4) break;

                                if (sig == "NM" && scan + 5 <= dirData.Length) {
                                    int nmlen = len - 5;
                                    if (nmlen > 0 && scan + 5 + nmlen <= dirData.Length) {
                                        name = latin1.GetString(dirData, scan + 5, nmlen);
                                    }
                                } else if (sig == "CL" && scan + 8 <= dirData.Length) {
                                    fileLBA = BitConverter.ToUInt32(dirData, scan + 4);
                                }
                                scan += len;
                            }
                        }

                        if (dirData[offset + 33] != 0 && dirData[offset + 33] != 1) {
                            if (name == "rr_moved" || name == ".rr_moved") {
                                offset += recLen;
                                continue;
                            }

                            string relPath = string.IsNullOrEmpty(currentDir.Item3) ? name : currentDir.Item3 + "\\" + name;

                            if ((flags & 0x02) == 0x02) {
                                if (fileSize > 0) dirQueue.Enqueue(new Tuple<uint, uint, string>(fileLBA, fileSize, relPath));
                            } else {
                                string lookupKey = relPath.Replace('/', '\\').Trim('\\');
                                if (lookupMap.ContainsKey(lookupKey)) {
                                    long savedPos = fs.Position;
                                    fs.Position = (long)fileLBA * sectorSize;

                                    // Stream in 64KB buffer chunks directly to output files (zero RAM spikes on large files)
                                    foreach (string outPath in lookupMap[lookupKey]) {
                                        string dir = Path.GetDirectoryName(outPath);
                                        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

                                        fs.Position = (long)fileLBA * sectorSize;
                                        long remaining = fileSize;
                                        byte[] buffer = new byte[65536];

                                        using (FileStream outFile = File.Create(outPath)) {
                                            while (remaining > 0) {
                                                int toRead = (int)Math.Min((long)buffer.Length, remaining);
                                                int read = fs.Read(buffer, 0, toRead);
                                                if (read <= 0) break;
                                                outFile.Write(buffer, 0, read);
                                                remaining -= read;
                                            }
                                        }
                                    }

                                    fs.Position = savedPos;
                                }
                            }
                        }
                    }
                    offset += recLen;
                }
            }
        }
    }
}
"@

Add-Type -TypeDefinition $CSharpSource -Language CSharp