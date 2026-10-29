<#
.SYNOPSIS
    Extracts and tests password-protected ZIP files in Windows PowerShell 5.1 using pure .NET.

.DESCRIPTION
    Compiles an in-memory C# decryption engine via Add-Type with zero external dependencies.
    Supports both traditional ZipCrypto (PKWARE) and modern WinZip AES-128 / AES-192 / AES-256.
    Includes automated ZipSlip directory traversal vulnerability protection and -Quiet mode.

.EXAMPLE
    # Test if password is valid silently (returns $true or $false)
    Test-ZipPassword -Path "C:\Backups\Data.zip" -Password "Secret123!" -Quiet

.EXAMPLE
    # Extract files completely silently (returns $true on success, $false on failure, zero console output)
    Expand-PasswordZip -Path "C:\Backups\Data.zip" -DestinationPath "C:\Extracted" -Password "Secret123!" -Force -Quiet
#>

# 1. Compile C# Type if not already loaded into the current PowerShell AppDomain
if (-not ([System.Management.Automation.PSTypeName]'PowerShellZip.ZipDecryptor').Type) {
    $csharpCode = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;

namespace PowerShellZip
{
    public class ZipEntryInfo
    {
        public string Name { get; set; }
        public long CompressedSize { get; set; }
        public long UncompressedSize { get; set; }
        public uint Crc32 { get; set; }
        public bool IsEncrypted { get; set; }
        public string EncryptionType { get; set; }
        public bool IsDirectory { get; set; }
        public DateTime LastModified { get; set; }
        public ushort CompressionMethod { get; set; }
        public long HeaderOffset { get; set; }
        internal AesExtraInfo AesInfo { get; set; }
    }

    public class ZipTestResult
    {
        public bool IsValid { get; set; }
        public bool IsEncrypted { get; set; }
        public int TotalEntries { get; set; }
        public int EncryptedEntries { get; set; }
        public string EncryptionType { get; set; }
        public string ErrorMessage { get; set; }
        public List<ZipEntryInfo> Entries { get; set; }

        public ZipTestResult()
        {
            Entries = new List<ZipEntryInfo>();
        }
    }

    internal class AesExtraInfo
    {
        public ushort VendorVersion { get; set; }
        public byte Strength { get; set; } // 1=128, 2=192, 3=256
        public ushort ActualCompressionMethod { get; set; }

        public int KeyLength
        {
            get
            {
                if (Strength == 1) return 16;
                if (Strength == 2) return 24;
                return 32;
            }
        }

        public int SaltLength
        {
            get
            {
                if (Strength == 1) return 8;
                if (Strength == 2) return 12;
                return 16;
            }
        }
    }

    /// <summary>
    /// Pure .NET Framework 4.5+ / PowerShell 5.1 compatible ZIP extractor.
    /// Supports both standard ZipCrypto (PKWARE traditional) and WinZip AES-128 / 192 / 256.
    /// Zero external DLL dependencies.
    /// </summary>
    public static class ZipDecryptor
    {
        #region Public API

        public static bool TestPassword(string zipPath, string password)
        {
            try
            {
                ZipTestResult result = TestArchive(zipPath, password);
                return result.IsValid;
            }
            catch
            {
                return false;
            }
        }

        public static ZipTestResult TestArchive(string zipPath, string password)
        {
            ZipTestResult result = new ZipTestResult();

            if (string.IsNullOrEmpty(zipPath))
            {
                result.IsValid = false;
                result.ErrorMessage = "ZIP path cannot be null or empty.";
                return result;
            }

            if (!File.Exists(zipPath))
            {
                result.IsValid = false;
                result.ErrorMessage = string.Format("File not found: {0}", zipPath);
                return result;
            }

            try
            {
                using (FileStream fs = new FileStream(zipPath, FileMode.Open, FileAccess.Read, FileShare.Read))
                {
                    List<ZipEntryInfo> entries = ReadCentralDirectory(fs);
                    result.Entries = entries;
                    result.TotalEntries = entries.Count;

                    int encCount = 0;
                    string detectedType = "None";

                    foreach (ZipEntryInfo entry in entries)
                    {
                        if (entry.IsEncrypted)
                        {
                            encCount++;
                            if (detectedType == "None") detectedType = entry.EncryptionType;
                            else if (detectedType != entry.EncryptionType) detectedType = "Mixed";
                        }
                    }

                    result.EncryptedEntries = encCount;
                    result.IsEncrypted = encCount > 0;
                    result.EncryptionType = detectedType;

                    if (!result.IsEncrypted)
                    {
                        result.IsValid = true;
                        return result;
                    }

                    if (string.IsNullOrEmpty(password))
                    {
                        result.IsValid = false;
                        result.ErrorMessage = "Archive contains encrypted entries, but no password was provided.";
                        return result;
                    }

                    foreach (ZipEntryInfo entry in entries)
                    {
                        if (!entry.IsEncrypted || entry.IsDirectory)
                            continue;

                        bool passOk = VerifyEntryPassword(fs, entry, password);
                        if (!passOk)
                        {
                            result.IsValid = false;
                            result.ErrorMessage = string.Format("Incorrect password for entry '{0}' ({1}).", entry.Name, entry.EncryptionType);
                            return result;
                        }
                    }

                    result.IsValid = true;
                    return result;
                }
            }
            catch (Exception ex)
            {
                result.IsValid = false;
                result.ErrorMessage = ex.Message;
                return result;
            }
        }

        public static List<ZipEntryInfo> ListEntries(string zipPath)
        {
            using (FileStream fs = new FileStream(zipPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                return ReadCentralDirectory(fs);
            }
        }

        public static List<string> Extract(string zipPath, string destinationDirectory, string password = null, bool overwrite = true)
        {
            if (string.IsNullOrEmpty(zipPath)) throw new ArgumentNullException("zipPath");
            if (string.IsNullOrEmpty(destinationDirectory)) throw new ArgumentNullException("destinationDirectory");
            if (!File.Exists(zipPath)) throw new FileNotFoundException("ZIP archive not found", zipPath);

            string targetRoot = Path.GetFullPath(destinationDirectory);
            if (!targetRoot.EndsWith(Path.DirectorySeparatorChar.ToString()))
                targetRoot += Path.DirectorySeparatorChar;

            if (!Directory.Exists(targetRoot))
                Directory.CreateDirectory(targetRoot);

            List<string> extractedFiles = new List<string>();

            using (FileStream fs = new FileStream(zipPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                List<ZipEntryInfo> entries = ReadCentralDirectory(fs);

                foreach (ZipEntryInfo entry in entries)
                {
                    string sanitizedName = entry.Name.Replace('/', Path.DirectorySeparatorChar)
                                                     .Replace('\\', Path.DirectorySeparatorChar);
                    
                    // ZipSlip security check
                    string fullPath = Path.GetFullPath(Path.Combine(targetRoot, sanitizedName));
                    if (!fullPath.StartsWith(targetRoot, StringComparison.OrdinalIgnoreCase))
                    {
                        throw new System.Security.SecurityException(
                            string.Format("ZipSlip security violation: entry '{0}' targets outside destination.", entry.Name));
                    }

                    if (entry.IsDirectory)
                    {
                        if (!Directory.Exists(fullPath)) Directory.CreateDirectory(fullPath);
                        continue;
                    }

                    string parentDir = Path.GetDirectoryName(fullPath);
                    if (!Directory.Exists(parentDir)) Directory.CreateDirectory(parentDir);

                    if (File.Exists(fullPath) && !overwrite) continue;

                    ExtractSingleEntry(fs, entry, fullPath, password);

                    try
                    {
                        if (entry.LastModified > DateTime.MinValue && entry.LastModified < DateTime.MaxValue)
                        {
                            File.SetLastWriteTime(fullPath, entry.LastModified);
                        }
                    }
                    catch { }

                    extractedFiles.Add(fullPath);
                }
            }

            return extractedFiles;
        }

        #endregion

        #region Internal Extraction Engine

        private static void ExtractSingleEntry(FileStream fs, ZipEntryInfo entry, string destinationFilePath, string password)
        {
            fs.Seek(entry.HeaderOffset, SeekOrigin.Begin);
            BinaryReader reader = new BinaryReader(fs);

            uint sig = reader.ReadUInt32();
            if (sig != 0x04034b50)
                throw new InvalidDataException(string.Format("Invalid local header signature (0x{0:X8}) for entry: {1}", sig, entry.Name));

            ushort versionNeeded = reader.ReadUInt16();
            ushort flags = reader.ReadUInt16();
            ushort method = reader.ReadUInt16();
            ushort lastModTime = reader.ReadUInt16();
            ushort lastModDate = reader.ReadUInt16();
            uint localCrc = reader.ReadUInt32();
            uint localCompSize = reader.ReadUInt32();
            uint localUncompSize = reader.ReadUInt32();
            ushort nameLen = reader.ReadUInt16();
            ushort extraLen = reader.ReadUInt16();

            fs.Seek(entry.HeaderOffset + 30 + nameLen + extraLen, SeekOrigin.Begin);

            bool isEncrypted = (flags & 1) != 0 || entry.IsEncrypted;
            if (isEncrypted && string.IsNullOrEmpty(password))
            {
                throw new InvalidOperationException(string.Format("Entry '{0}' is password protected.", entry.Name));
            }

            if (entry.CompressedSize <= 0 && localCompSize > 0) entry.CompressedSize = localCompSize;
            if (entry.UncompressedSize <= 0 && localUncompSize > 0) entry.UncompressedSize = localUncompSize;
            if (entry.Crc32 == 0 && localCrc > 0) entry.Crc32 = localCrc;

            using (FileStream outStream = new FileStream(destinationFilePath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                if (entry.EncryptionType.IndexOf("AES", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    ExtractAesEntry(fs, entry, outStream, password);
                }
                else if (isEncrypted)
                {
                    ExtractZipCryptoEntry(fs, entry, outStream, password, flags, lastModTime);
                }
                else
                {
                    ExtractPlainEntry(fs, entry, outStream);
                }
            }
        }

        private static void ExtractPlainEntry(FileStream fs, ZipEntryInfo entry, Stream outStream)
        {
            if (entry.CompressionMethod == 0) // Store
            {
                CopyStreamLimited(fs, outStream, entry.UncompressedSize);
            }
            else if (entry.CompressionMethod == 8) // Deflate
            {
                using (SubStream limitedStream = new SubStream(fs, entry.CompressedSize))
                using (DeflateStream deflater = new DeflateStream(limitedStream, CompressionMode.Decompress))
                {
                    deflater.CopyTo(outStream);
                }
            }
            else
            {
                throw new NotSupportedException(string.Format("Unsupported compression method: {0}", entry.CompressionMethod));
            }
        }

        private static void ExtractZipCryptoEntry(FileStream fs, ZipEntryInfo entry, Stream outStream, string password, ushort flags, ushort lastModTime)
        {
            ZipCrypto crypto = new ZipCrypto();
            crypto.Init(password, flags);

            byte[] encHeader = new byte[12];
            int read = fs.Read(encHeader, 0, 12);
            if (read < 12) throw new InvalidDataException("Unexpected end of stream reading ZipCrypto header.");

            byte[] decHeader = new byte[12];
            for (int i = 0; i < 12; i++) decHeader[i] = crypto.DecryptByte(encHeader[i]);

            byte checkByte1 = (byte)(entry.Crc32 >> 24);
            byte checkByte2 = (byte)(lastModTime >> 8);
            if (decHeader[11] != checkByte1 && decHeader[11] != checkByte2)
            {
                throw new InvalidDataException(string.Format("Incorrect password for '{0}'.", entry.Name));
            }

            long payloadSize = entry.CompressedSize - 12;
            if (payloadSize < 0) throw new InvalidDataException(string.Format("Invalid compressed size for '{0}'.", entry.Name));

            if (entry.CompressionMethod == 0) // Stored
            {
                byte[] buffer = new byte[8192];
                long remaining = payloadSize;
                while (remaining > 0)
                {
                    int toRead = (int)Math.Min(buffer.Length, remaining);
                    int count = fs.Read(buffer, 0, toRead);
                    if (count <= 0) break;

                    for (int i = 0; i < count; i++) buffer[i] = crypto.DecryptByte(buffer[i]);

                    outStream.Write(buffer, 0, count);
                    remaining -= count;
                }
            }
            else if (entry.CompressionMethod == 8) // Deflated
            {
                using (ZipCryptoDecryptStream decryptStream = new ZipCryptoDecryptStream(fs, crypto, payloadSize))
                using (DeflateStream deflater = new DeflateStream(decryptStream, CompressionMode.Decompress))
                {
                    deflater.CopyTo(outStream);
                }
            }
            else
            {
                throw new NotSupportedException(string.Format("Unsupported compression method: {0}", entry.CompressionMethod));
            }
        }

        private static void ExtractAesEntry(FileStream fs, ZipEntryInfo entry, Stream outStream, string password)
        {
            AesExtraInfo aesInfo = entry.AesInfo;
            if (aesInfo == null) throw new InvalidDataException("Missing AES extra field info.");

            int saltLen = aesInfo.SaltLength;
            byte[] salt = new byte[saltLen];
            if (fs.Read(salt, 0, saltLen) < saltLen) throw new InvalidDataException("Truncated AES salt.");

            byte[] storedPv = new byte[2];
            if (fs.Read(storedPv, 0, 2) < 2) throw new InvalidDataException("Truncated AES password verification code.");

            int keyLen = aesInfo.KeyLength;
            byte[] pwdBytes = Encoding.UTF8.GetBytes(password);
            
            using (Rfc2898DeriveBytes pbkdf2 = new Rfc2898DeriveBytes(pwdBytes, salt, 1000))
            {
                byte[] aesKey = pbkdf2.GetBytes(keyLen);
                byte[] macKey = pbkdf2.GetBytes(keyLen);
                byte[] derivedPv = pbkdf2.GetBytes(2);

                if (derivedPv[0] != storedPv[0] || derivedPv[1] != storedPv[1])
                {
                    throw new InvalidDataException(string.Format("Incorrect password for AES encrypted entry '{0}'.", entry.Name));
                }

                long encryptedDataLen = entry.CompressedSize - saltLen - 2 - 10;
                if (encryptedDataLen < 0) throw new InvalidDataException("Invalid AES payload length.");

                using (AesCtrStream ctrStream = new AesCtrStream(fs, aesKey, encryptedDataLen))
                {
                    if (aesInfo.ActualCompressionMethod == 0)
                    {
                        ctrStream.CopyTo(outStream);
                    }
                    else if (aesInfo.ActualCompressionMethod == 8)
                    {
                        using (DeflateStream deflater = new DeflateStream(ctrStream, CompressionMode.Decompress))
                        {
                            deflater.CopyTo(outStream);
                        }
                    }
                }

                fs.Seek(10, SeekOrigin.Current);
            }
        }

        private static bool VerifyEntryPassword(FileStream fs, ZipEntryInfo entry, string password)
        {
            try
            {
                fs.Seek(entry.HeaderOffset, SeekOrigin.Begin);
                BinaryReader reader = new BinaryReader(fs);
                uint sig = reader.ReadUInt32();
                if (sig != 0x04034b50) return false;

                ushort ver = reader.ReadUInt16();
                ushort flags = reader.ReadUInt16();
                ushort method = reader.ReadUInt16();
                ushort lastModTime = reader.ReadUInt16();
                ushort lastModDate = reader.ReadUInt16();
                uint localCrc = reader.ReadUInt32();
                uint localCompSize = reader.ReadUInt32();
                uint localUncompSize = reader.ReadUInt32();
                ushort nameLen = reader.ReadUInt16();
                ushort extraLen = reader.ReadUInt16();

                fs.Seek(entry.HeaderOffset + 30 + nameLen + extraLen, SeekOrigin.Begin);

                if (entry.EncryptionType.IndexOf("AES", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    AesExtraInfo aesInfo = entry.AesInfo;
                    if (aesInfo == null) return false;
                    int saltLen = aesInfo.SaltLength;
                    byte[] salt = new byte[saltLen];
                    if (fs.Read(salt, 0, saltLen) < saltLen) return false;
                    byte[] storedPv = new byte[2];
                    if (fs.Read(storedPv, 0, 2) < 2) return false;

                    byte[] pwdBytes = Encoding.UTF8.GetBytes(password);
                    using (Rfc2898DeriveBytes pbkdf2 = new Rfc2898DeriveBytes(pwdBytes, salt, 1000))
                    {
                        pbkdf2.GetBytes(aesInfo.KeyLength);
                        pbkdf2.GetBytes(aesInfo.KeyLength);
                        byte[] derivedPv = pbkdf2.GetBytes(2);
                        return derivedPv[0] == storedPv[0] && derivedPv[1] == storedPv[1];
                    }
                }
                else
                {
                    ZipCrypto crypto = new ZipCrypto();
                    crypto.Init(password, flags);
                    byte[] encHeader = new byte[12];
                    if (fs.Read(encHeader, 0, 12) < 12) return false;

                    byte[] decHeader = new byte[12];
                    for (int i = 0; i < 12; i++)
                        decHeader[i] = crypto.DecryptByte(encHeader[i]);

                    byte checkByte1 = (byte)(entry.Crc32 >> 24);
                    byte checkByte2 = (byte)(lastModTime >> 8);
                    return (decHeader[11] == checkByte1 || decHeader[11] == checkByte2);
                }
            }
            catch
            {
                return false;
            }
        }

        #endregion

        #region Central Directory Parser

        private static List<ZipEntryInfo> ReadCentralDirectory(FileStream fs)
        {
            long eocdOffset = FindEndOfCentralDirectory(fs);
            if (eocdOffset < 0)
                throw new InvalidDataException("End of Central Directory record not found. Not a valid ZIP file.");

            fs.Seek(eocdOffset, SeekOrigin.Begin);
            BinaryReader reader = new BinaryReader(fs);

            uint sig = reader.ReadUInt32(); // 0x06054b50
            ushort diskNumber = reader.ReadUInt16();
            ushort cdStartDisk = reader.ReadUInt16();
            ushort entriesOnDisk = reader.ReadUInt16();
            ushort totalEntries = reader.ReadUInt16();
            uint cdSize = reader.ReadUInt32();
            uint cdOffset = reader.ReadUInt32();
            ushort commentLen = reader.ReadUInt16();

            long realTotalEntries = totalEntries;
            long realCdOffset = cdOffset;
            long realCdSize = cdSize;

            if (totalEntries == 0xFFFF || cdOffset == 0xFFFFFFFF || cdSize == 0xFFFFFFFF)
            {
                long zip64Eocd = FindZip64EndOfCentralDirectory(fs, eocdOffset);
                if (zip64Eocd >= 0)
                {
                    fs.Seek(zip64Eocd + 4, SeekOrigin.Begin);
                    ulong sizeOfZip64Eocd = reader.ReadUInt64();
                    ushort verMade = reader.ReadUInt16();
                    ushort verNeeded = reader.ReadUInt16();
                    uint diskNum = reader.ReadUInt32();
                    uint diskStart = reader.ReadUInt32();
                    ulong totalEntriesDisk = reader.ReadUInt64();
                    ulong totalEntries64 = reader.ReadUInt64();
                    ulong cdSize64 = reader.ReadUInt64();
                    ulong cdOffset64 = reader.ReadUInt64();

                    realTotalEntries = (long)totalEntries64;
                    realCdOffset = (long)cdOffset64;
                    realCdSize = (long)cdSize64;
                }
            }

            long expectedCdOffset = eocdOffset - realCdSize;
            if (expectedCdOffset >= 0 && expectedCdOffset != realCdOffset)
            {
                fs.Seek(expectedCdOffset, SeekOrigin.Begin);
                if (fs.Position + 4 <= fs.Length && reader.ReadUInt32() == 0x02014b50)
                {
                    realCdOffset = expectedCdOffset;
                }
            }

            fs.Seek(realCdOffset, SeekOrigin.Begin);
            List<ZipEntryInfo> entries = new List<ZipEntryInfo>((int)Math.Min(realTotalEntries, 100000));

            for (long i = 0; i < realTotalEntries; i++)
            {
                if (fs.Position + 46 > fs.Length) break;

                uint cdSig = reader.ReadUInt32();
                if (cdSig != 0x02014b50) break;

                ushort versionMadeBy = reader.ReadUInt16();
                ushort versionNeeded = reader.ReadUInt16();
                ushort flags = reader.ReadUInt16();
                ushort method = reader.ReadUInt16();
                ushort modTime = reader.ReadUInt16();
                ushort modDate = reader.ReadUInt16();
                uint crc32 = reader.ReadUInt32();
                uint compSize = reader.ReadUInt32();
                uint uncompSize = reader.ReadUInt32();
                ushort nameLen = reader.ReadUInt16();
                ushort extraLen = reader.ReadUInt16();
                ushort commentLenEntry = reader.ReadUInt16();
                ushort diskStart = reader.ReadUInt16();
                ushort internalAttrs = reader.ReadUInt16();
                uint externalAttrs = reader.ReadUInt32();
                uint localHeaderOffset = reader.ReadUInt32();

                Encoding enc;
                try { enc = ((flags & (1 << 11)) != 0) ? Encoding.UTF8 : Encoding.GetEncoding(437); }
                catch { enc = Encoding.UTF8; }

                byte[] nameBytes = reader.ReadBytes(nameLen);
                string entryName = enc.GetString(nameBytes);

                byte[] extraBytes = (extraLen > 0) ? reader.ReadBytes(extraLen) : new byte[0];
                if (commentLenEntry > 0) reader.ReadBytes(commentLenEntry);

                bool isEncrypted = (flags & 1) != 0;
                string encType = "None";
                AesExtraInfo aesInfo = null;

                if (method == 99 || HasAesExtraField(extraBytes, out aesInfo))
                {
                    encType = (aesInfo != null && aesInfo.KeyLength == 32) ? "WinZip AES-256" :
                              (aesInfo != null && aesInfo.KeyLength == 16) ? "WinZip AES-128" : "WinZip AES";
                    isEncrypted = true;
                }
                else if (isEncrypted)
                {
                    encType = "ZipCrypto";
                }

                bool isDir = entryName.EndsWith("/") || entryName.EndsWith("\\") || ((externalAttrs & 0x10) != 0);

                DateTime modDateTime = DateTime.MinValue;
                try
                {
                    int year = ((modDate >> 9) & 0x7F) + 1980;
                    int month = (modDate >> 5) & 0x0F;
                    int day = modDate & 0x1F;
                    int hour = (modTime >> 11) & 0x1F;
                    int minute = (modTime >> 5) & 0x3F;
                    int second = (modTime & 0x1F) * 2;
                    if (year >= 1980 && month >= 1 && month <= 12 && day >= 1 && day <= 31)
                    {
                        modDateTime = new DateTime(year, month, day, Math.Min(hour, 23), Math.Min(minute, 59), Math.Min(second, 59));
                    }
                }
                catch { }

                ZipEntryInfo entry = new ZipEntryInfo
                {
                    Name = entryName,
                    CompressedSize = compSize,
                    UncompressedSize = uncompSize,
                    Crc32 = crc32,
                    IsEncrypted = isEncrypted,
                    EncryptionType = encType,
                    IsDirectory = isDir,
                    LastModified = modDateTime,
                    CompressionMethod = method,
                    HeaderOffset = localHeaderOffset,
                    AesInfo = aesInfo
                };

                entries.Add(entry);
            }

            return entries;
        }

        private static long FindEndOfCentralDirectory(FileStream fs)
        {
            long length = fs.Length;
            if (length < 22) return -1;

            int maxSearch = (int)Math.Min(length, 65557L);
            byte[] buffer = new byte[maxSearch];
            long readStart = length - maxSearch;
            fs.Seek(readStart, SeekOrigin.Begin);

            int totalRead = 0;
            while (totalRead < maxSearch)
            {
                int r = fs.Read(buffer, totalRead, maxSearch - totalRead);
                if (r <= 0) break;
                totalRead += r;
            }

            for (int i = totalRead - 22; i >= 0; i--)
            {
                if (buffer[i] == 0x50 && buffer[i + 1] == 0x4b && buffer[i + 2] == 0x05 && buffer[i + 3] == 0x06)
                {
                    return readStart + i;
                }
            }

            return -1;
        }

        private static long FindZip64EndOfCentralDirectory(FileStream fs, long eocdOffset)
        {
            if (eocdOffset < 20) return -1;
            fs.Seek(eocdOffset - 20, SeekOrigin.Begin);
            BinaryReader reader = new BinaryReader(fs);
            uint sig = reader.ReadUInt32();
            if (sig != 0x07064b50) return -1;

            uint diskNum = reader.ReadUInt32();
            ulong zip64EocdOffset = reader.ReadUInt64();
            uint totalDisks = reader.ReadUInt32();

            if ((long)zip64EocdOffset < 0 || (long)zip64EocdOffset > fs.Length - 56) return -1;

            fs.Seek((long)zip64EocdOffset, SeekOrigin.Begin);
            uint zip64Sig = reader.ReadUInt32();
            if (zip64Sig != 0x06064b50) return -1;

            return (long)zip64EocdOffset;
        }

        private static bool HasAesExtraField(byte[] extra, out AesExtraInfo aesInfo)
        {
            aesInfo = null;
            if (extra == null || extra.Length < 4) return false;

            int idx = 0;
            while (idx + 4 <= extra.Length)
            {
                ushort tag = (ushort)(extra[idx] | (extra[idx + 1] << 8));
                ushort len = (ushort)(extra[idx + 2] | (extra[idx + 3] << 8));
                idx += 4;

                if (tag == 0x9901 && idx + len <= extra.Length && len >= 7)
                {
                    ushort vendorVersion = (ushort)(extra[idx] | (extra[idx + 1] << 8));
                    byte strength = extra[idx + 4];
                    ushort actualMethod = (ushort)(extra[idx + 5] | (extra[idx + 6] << 8));

                    aesInfo = new AesExtraInfo
                    {
                        VendorVersion = vendorVersion,
                        Strength = strength,
                        ActualCompressionMethod = actualMethod
                    };
                    return true;
                }

                idx += len;
            }

            return false;
        }

        #endregion

        #region Helper Stream Classes

        private static void CopyStreamLimited(Stream source, Stream target, long length)
        {
            byte[] buf = new byte[8192];
            long rem = length;
            while (rem > 0)
            {
                int toRead = (int)Math.Min(buf.Length, rem);
                int read = source.Read(buf, 0, toRead);
                if (read <= 0) break;
                target.Write(buf, 0, read);
                rem -= read;
            }
        }

        #endregion
    }

    internal class ZipCrypto
    {
        private static readonly uint[] CrcTable = new uint[256];
        private uint key0, key1, key2;

        static ZipCrypto()
        {
            for (uint i = 0; i < 256; i++)
            {
                uint c = i;
                for (int j = 0; j < 8; j++)
                {
                    if ((c & 1) != 0) c = 0xEDB88320 ^ (c >> 1);
                    else c >>= 1;
                }
                CrcTable[i] = c;
            }
        }

        public void Init(string password, ushort flags)
        {
            key0 = 0x12345678;
            key1 = 0x23456789;
            key2 = 0x34567890;

            byte[] pwdBytes = ((flags & (1 << 11)) != 0) 
                ? Encoding.UTF8.GetBytes(password) 
                : Encoding.Default.GetBytes(password);

            for (int i = 0; i < pwdBytes.Length; i++)
            {
                UpdateKeys(pwdBytes[i]);
            }
        }

        public void UpdateKeys(byte b)
        {
            key0 = CrcTable[(key0 ^ b) & 0xFF] ^ (key0 >> 8);
            key1 += (byte)key0;
            key1 = (key1 * 134775813) + 1;
            key2 = CrcTable[(key2 ^ (byte)(key1 >> 24)) & 0xFF] ^ (key2 >> 8);
        }

        public byte DecryptByte(byte cipher)
        {
            ushort temp = (ushort)(key2 | 2);
            byte k = (byte)((temp * (temp ^ 1)) >> 8);
            byte plain = (byte)(cipher ^ k);
            UpdateKeys(plain);
            return plain;
        }
    }

    internal class ZipCryptoDecryptStream : Stream
    {
        private readonly Stream baseStream;
        private readonly ZipCrypto crypto;
        private readonly long length;
        private long position;

        public ZipCryptoDecryptStream(Stream baseStream, ZipCrypto crypto, long length)
        {
            this.baseStream = baseStream;
            this.crypto = crypto;
            this.length = length;
            this.position = 0;
        }

        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return length; } }
        public override long Position
        {
            get { return position; }
            set { throw new NotSupportedException(); }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (position >= length) return 0;
            int toRead = (int)Math.Min(count, length - position);
            int read = baseStream.Read(buffer, offset, toRead);
            if (read <= 0) return 0;

            for (int i = 0; i < read; i++)
            {
                buffer[offset + i] = crypto.DecryptByte(buffer[offset + i]);
            }
            position += read;
            return read;
        }

        public override void Flush() { }
        public override long Seek(long offset, SeekOrigin origin) { throw new NotSupportedException(); }
        public override void SetLength(long value) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) { throw new NotSupportedException(); }
    }

    internal class AesCtrStream : Stream
    {
        private readonly Stream baseStream;
        private readonly ICryptoTransform aesEncryptor;
        private readonly long length;
        private long position;
        private readonly byte[] counterBlock = new byte[16];
        private readonly byte[] keyStream = new byte[16];
        private int keyStreamIndex = 16;
        private ulong counter = 1;

        public AesCtrStream(Stream baseStream, byte[] aesKey, long length)
        {
            this.baseStream = baseStream;
            this.length = length;
            this.position = 0;

            RijndaelManaged rijndael = new RijndaelManaged
            {
                KeySize = aesKey.Length * 8,
                Mode = CipherMode.ECB,
                Padding = PaddingMode.None,
                Key = aesKey
            };
            this.aesEncryptor = rijndael.CreateEncryptor();
        }

        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return length; } }
        public override long Position
        {
            get { return position; }
            set { throw new NotSupportedException(); }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (position >= length) return 0;
            int toRead = (int)Math.Min(count, length - position);
            int read = baseStream.Read(buffer, offset, toRead);
            if (read <= 0) return 0;

            for (int i = 0; i < read; i++)
            {
                if (keyStreamIndex >= 16)
                {
                    Array.Clear(counterBlock, 0, 16);
                    byte[] cBytes = BitConverter.GetBytes(counter);
                    Array.Copy(cBytes, counterBlock, cBytes.Length);
                    counter++;

                    aesEncryptor.TransformBlock(counterBlock, 0, 16, keyStream, 0);
                    keyStreamIndex = 0;
                }

                buffer[offset + i] = (byte)(buffer[offset + i] ^ keyStream[keyStreamIndex++]);
            }

            position += read;
            return read;
        }

        public override void Flush() { }
        public override long Seek(long offset, SeekOrigin origin) { throw new NotSupportedException(); }
        public override void SetLength(long value) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) { throw new NotSupportedException(); }

        protected override void Dispose(bool disposing)
        {
            if (disposing && aesEncryptor != null)
            {
                aesEncryptor.Dispose();
            }
            base.Dispose(disposing);
        }
    }

    internal class SubStream : Stream
    {
        private readonly Stream baseStream;
        private readonly long length;
        private long position;

        public SubStream(Stream baseStream, long length)
        {
            this.baseStream = baseStream;
            this.length = length;
            this.position = 0;
        }

        public override bool CanRead { get { return true; } }
        public override bool CanSeek { get { return false; } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return length; } }
        public override long Position
        {
            get { return position; }
            set { throw new NotSupportedException(); }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            if (position >= length) return 0;
            int toRead = (int)Math.Min(count, length - position);
            int read = baseStream.Read(buffer, offset, toRead);
            if (read > 0) position += read;
            return read;
        }

        public override void Flush() { }
        public override long Seek(long offset, SeekOrigin origin) { throw new NotSupportedException(); }
        public override void SetLength(long value) { throw new NotSupportedException(); }
        public override void Write(byte[] buffer, int offset, int count) { throw new NotSupportedException(); }
    }
}
'@

    Add-Type -TypeDefinition $csharpCode -ReferencedAssemblies "System.IO.Compression", "System.Security" -Language CSharp
}