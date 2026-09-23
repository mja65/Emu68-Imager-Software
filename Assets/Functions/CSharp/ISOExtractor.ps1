$CSharpSource = @"
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

public class ISOExtractor {
    public static void ExtractExplicitFiles(string isoPath, string[] sourcePaths, string[] destPaths) {
        if (sourcePaths == null || destPaths == null || sourcePaths.Length != destPaths.Length) return;

        // Map a single source path to multiple destination targets
        Dictionary<string, List<string>> lookupMap = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < sourcePaths.Length; i++) {
            if (string.IsNullOrEmpty(sourcePaths[i])) continue;
            
            if (!lookupMap.ContainsKey(sourcePaths[i])) {
                lookupMap[sourcePaths[i]] = new List<string>();
            }
            lookupMap[sourcePaths[i]].Add(destPaths[i]);
        }

        if (lookupMap.Count == 0) return;

        using (FileStream fs = File.OpenRead(isoPath))
        using (BinaryReader br = new BinaryReader(fs)) {
            int sectorSize = 2048;
            Encoding latin1 = Encoding.GetEncoding("ISO-8859-1");
            
            fs.Position = 16 * sectorSize;
            byte[] pvd = br.ReadBytes(sectorSize);
            if (latin1.GetString(pvd, 1, 5) != "CD001") return;
            
            uint rootLBA = BitConverter.ToUInt32(pvd, 156 + 2);
            uint rootSize = BitConverter.ToUInt32(pvd, 156 + 10);
            
            Queue<Tuple<uint, uint, string>> dirQueue = new Queue<Tuple<uint, uint, string>>();
            dirQueue.Enqueue(new Tuple<uint, uint, string>(rootLBA, rootSize, ""));
            
            while (dirQueue.Count > 0) {
                var currentDir = dirQueue.Dequeue();
                fs.Position = currentDir.Item1 * sectorSize;
                byte[] dirData = br.ReadBytes((int)currentDir.Item2);
                
                int offset = 0;
                while (offset < dirData.Length) {
                    int recLen = dirData[offset];
                    if (recLen == 0) {
                        offset += sectorSize - (offset % sectorSize);
                        continue;
                    }
                    
                    byte flags = dirData[offset + 25];
                    int nameLen = dirData[offset + 32];
                    
                    if (nameLen > 0 && (offset + 33 + nameLen) <= dirData.Length) {
                        string name = latin1.GetString(dirData, offset + 33, nameLen).Split(';')[0];
                        uint fileLBA = BitConverter.ToUInt32(dirData, offset + 2);
                        uint fileSize = BitConverter.ToUInt32(dirData, offset + 10);
                        
                        int suaOffset = offset + 33 + nameLen;
                        if (nameLen % 2 == 0) suaOffset++;
                        int suaLen = recLen - (suaOffset - offset);
                        
                        if (suaLen > 4 && suaOffset + suaLen <= dirData.Length) {
                            int scan = suaOffset;
                            while (scan < (suaOffset + suaLen - 4)) {
                                string sig = latin1.GetString(dirData, scan, 2);
                                int len = dirData[scan + 2];
                                if (len <= 0) break;
                                
                                if (sig == "NM" && scan + 5 + (len - 5) <= dirData.Length) {
                                    name = latin1.GetString(dirData, scan + 5, len - 5);
                                } else if (sig == "CL") {
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
                                if (lookupMap.ContainsKey(relPath)) {
                                    // Read file bytes once from the sector
                                    long savedPos = fs.Position;
                                    fs.Position = fileLBA * sectorSize;
                                    byte[] fileData = br.ReadBytes((int)fileSize);
                                    fs.Position = savedPos;

                                    // Loop through and write to all registered rename targets
                                    foreach (string outPath in lookupMap[relPath]) {
                                        string dir = Path.GetDirectoryName(outPath);
                                        if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
                                        File.WriteAllBytes(outPath, fileData);
                                    }
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

# $CSharpSource = @"
# using System;
# using System.IO;
# using System.Text;
# using System.Collections.Generic;

# public class ISOExtractorv2 {
#     public static void ExtractExplicitFiles(string isoPath, string[] sourcePaths, string[] destPaths) {
#         if (sourcePaths == null || destPaths == null || sourcePaths.Length != destPaths.Length) return;

#         // Simple case-insensitive lookup map for the flat strings
#         Dictionary<string, string> lookupMap = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
#         for (int i = 0; i < sourcePaths.Length; i++) {
#             if (!string.IsNullOrEmpty(sourcePaths[i])) {
#                 lookupMap[sourcePaths[i]] = destPaths[i];
#             }
#         }

#         if (lookupMap.Count == 0) return;

#         using (FileStream fs = File.OpenRead(isoPath))
#         using (BinaryReader br = new BinaryReader(fs)) {
#             int sectorSize = 2048;
#             Encoding latin1 = Encoding.GetEncoding("ISO-8859-1");
            
#             fs.Position = 16 * sectorSize;
#             byte[] pvd = br.ReadBytes(sectorSize);
#             if (latin1.GetString(pvd, 1, 5) != "CD001") return;
            
#             uint rootLBA = BitConverter.ToUInt32(pvd, 156 + 2);
#             uint rootSize = BitConverter.ToUInt32(pvd, 156 + 10);
            
#             Queue<Tuple<uint, uint, string>> dirQueue = new Queue<Tuple<uint, uint, string>>();
#             dirQueue.Enqueue(new Tuple<uint, uint, string>(rootLBA, rootSize, ""));
            
#             while (dirQueue.Count > 0) {
#                 var currentDir = dirQueue.Dequeue();
#                 fs.Position = currentDir.Item1 * sectorSize;
#                 byte[] dirData = br.ReadBytes((int)currentDir.Item2);
                
#                 int offset = 0;
#                 while (offset < dirData.Length) {
#                     int recLen = dirData[offset];
#                     if (recLen == 0) {
#                         offset += sectorSize - (offset % sectorSize);
#                         continue;
#                     }
                    
#                     byte flags = dirData[offset + 25];
#                     int nameLen = dirData[offset + 32];
                    
#                     if (nameLen > 0 && (offset + 33 + nameLen) <= dirData.Length) {
#                         string name = latin1.GetString(dirData, offset + 33, nameLen).Split(';')[0];
#                         uint fileLBA = BitConverter.ToUInt32(dirData, offset + 2);
#                         uint fileSize = BitConverter.ToUInt32(dirData, offset + 10);
                        
#                         int suaOffset = offset + 33 + nameLen;
#                         if (nameLen % 2 == 0) suaOffset++;
#                         int suaLen = recLen - (suaOffset - offset);
                        
#                         if (suaLen > 4 && suaOffset + suaLen <= dirData.Length) {
#                             int scan = suaOffset;
#                             while (scan < (suaOffset + suaLen - 4)) {
#                                 string sig = latin1.GetString(dirData, scan, 2);
#                                 int len = dirData[scan + 2];
#                                 if (len <= 0) break;
                                
#                                 if (sig == "NM" && scan + 5 + (len - 5) <= dirData.Length) {
#                                     name = latin1.GetString(dirData, scan + 5, len - 5);
#                                 } else if (sig == "CL") {
#                                     fileLBA = BitConverter.ToUInt32(dirData, scan + 4);
#                                 }
#                                 scan += len;
#                             }
#                         }
                        
#                         if (dirData[offset + 33] != 0 && dirData[offset + 33] != 1) {
#                             if (name == "rr_moved" || name == ".rr_moved") {
#                                 offset += recLen;
#                                 continue;
#                             }
                            
#                             string relPath = string.IsNullOrEmpty(currentDir.Item3) ? name : currentDir.Item3 + "\\" + name;
                            
#                             if ((flags & 0x02) == 0x02) {
#                                 if (fileSize > 0) dirQueue.Enqueue(new Tuple<uint, uint, string>(fileLBA, fileSize, relPath));
#                             } else {
#                                 if (lookupMap.ContainsKey(relPath)) {
#                                     string outPath = lookupMap[relPath];
#                                     string dir = Path.GetDirectoryName(outPath);
#                                     if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
                                    
#                                     long savedPos = fs.Position;
#                                     fs.Position = fileLBA * sectorSize;
#                                     File.WriteAllBytes(outPath, br.ReadBytes((int)fileSize));
#                                     fs.Position = savedPos;
#                                 }
#                             }
#                         }
#                     }
#                     offset += recLen;
#                 }
#             }
#         }
#     }
# }
# "@

Add-Type -TypeDefinition $CSharpSource -Language CSharp