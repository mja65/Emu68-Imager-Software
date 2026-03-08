/* $VER: Emu68Updater.rexx 1.1 (10.03.26)                                     */
/* Script to update Emu68 and Videocore files                                 */
/*                                                                            */
/******************************************************************************/
/* REQUIREMENTS:                                                              */
/* - Libraries:           rexxtricks.library                                  */
/* - Tools (in C:):       aget, areweonline, copyreplace, llist, ListDevices, */ 
/*                        unzip                                               */
/* - Scripts (in S:):     progressbar.rexx                                    */ 
/******************************************************************************/

OPTIONS FAILAT 21 
if ~SHOW('L','rexxtricks.library') then addlib('rexxtricks.library',0,-30,0) 

PARSE ARG input 
input = upper(TRANSLATE(input, ' ', '='))
PARSE VAR input . 'PISTORMFOLDER' InputPistormSearchFolder .
PARSE VAR input . 'PROGRAMSFOLDER' InputProgramsSearchFolder .
PARSE VAR input . 'FAT32DEVICE' InputFAT32Device .
PARSE VAR input . 'SCRIPTPATH' InputScriptPath .

DEBUG = "FALSE"
IF POS('DEBUG', input) > 0 THEN DEBUG = "TRUE"

If InputFAT32Device ~= '' then InputFAT32Device = STRIP(InputFAT32Device)||":"

InputPistormSearchFolder = strip(InputPistormSearchFolder)
InputProgramsSearchFolder = strip(InputProgramsSearchFolder)
InputScriptPath = strip(InputScriptPath)

/*
DebugScriptPath = 'Work:'
DebugFat32Device = 'SD0:'
DebugPistormSearchFolder = 'SYS:'
DebugProgramsSearchFolder = 'Work:Applications'
*/

ADDRESS COMMAND

/* Variable Setup - BEGIN */

ScriptPath = ''
Fat32DeviceToMount = ''
PistormSearchFolder = ''
ProgramsSearchFolder = ''

If DebugScriptPath ~= '' then ScriptPath = DebugScriptPath
If DebugFat32Device ~= '' then FAT32DeviceToMount = DebugFat32Device
If DebugPistormSearchFolder ~= '' then PistormSearchFolder = DebugPistormSearchFolder
If DebugProgramsSearchFolder ~= '' then ProgramsSearchFolder = DebugProgramsSearchFolder

If InputScriptPath ~= '' then ScriptPath = InputScriptPath
If InputFat32Device ~= '' then FAT32DeviceToMount = InputFat32Device
If InputPistormSearchFolder ~= '' then PistormSearchFolder = InputPistormSearchFolder
If InputProgramsSearchFolder ~= '' then ProgramsSearchFolder = InputProgramsSearchFolder

DefaultScriptPath = 'SYS:PiStorm'

TempFolder = 'T:Updater'
DownloadFolder = TempFolder||'/DownloadedFiles'
PrerequisiteDownloadFolder = TempFolder||'/PrerequisiteFiles/DownloadedFiles'
PrerequisiteExtractFolder = TempFolder||'/PrerequisiteFiles/ExtractedFiles'
ExtractedFilesFolder = TempFolder||'/ExtractedFiles'
PiStormVariantPath = TempFolder||'/pistormvariant.txt'
ListofEmu68DisksFile = TempFolder||'/DriveInfo.txt'
VersionDataFolder = TempFolder||'/VersionData'
Emu68UpdaterScriptFolder = TempFolder||'/Emu68UpdaterScript'

If DEBUG = 'TRUE' then DO
   Say ScriptPath
   Say FAT32DeviceToMount
   Say PistormSearchFolder
   Say ProgramsSearchFolder 
END

DeviceListPath = 'C:ListDevices'
Drivername1 = 'brcm-emmc.device'
Drivername2 = 'brcm-sdhc.device'
TargetDostype = '0x46415401'
Emu68FilePath = ''

Call CreateFolder(TempFolder)
Call CreateFolder(DownloadFolder)
Call CreateFolder(PrerequisiteDownloadFolder)
Call CreateFolder(PrerequisiteExtractFolder)
Call CreateFolder(VersionDataFolder)
Call CreateFolder(Emu68UpdaterScriptFolder)

UpdateSheetScriptGID = '1689832058'
UpdateSheetGID = '6947660'
UpdateSheetURL = "https://docs.google.com/spreadsheets/d/12UcKD7INDH9y7Tw_w1q3ebQOUS9JtARIs8Z9JWfLUWg/export?format=tsv&gid="

UpdateFilePath = TempFolder||"/Update.txt"
ScriptUpdateFilePath = TempFolder||"/ScriptUpdate.txt"

/* Variable Setup - END */

SAY 'Welcome to Emu68 Updater!'
SAY ''
SAY 'This script will update your current Emu68 version and VideoCore version to the latest official release available on Github.'
SAY 'It will also update other files from your default install where possible'
SAY ''

vCmd = 'c:AreWeOnline'
vCmd
if RC>0 then Call CloseProgram("System is currently offline, please enable your internet connection then try again.",10,3)

if ~IsAmiSSL() then call CloseProgram("AmiSSL not available",10,3)

/* Stage One - Perform Prerequisite Checks - Start */

Say 'Stage 1 - Perform Prerequisite Checks'

If ~Exists('c:copyreplace') then DO
   Say 'copyreplace does not exist.'
   Call DownloadFile('Downloading copyreplace','http://aminet.net/util/sys/CopyReplace.lha',PrerequisiteDownloadFolder||'/copyreplace.lha',3,1)
   Call Unlha(PrerequisiteDownloadFolder||'/copyreplace.lha',PrerequisiteExtractFolder||'/')
   vCmd = 'copy >NIL: FROM "'PrerequisiteExtractFolder||'/copy" TO c:copyreplace CLONE QUIET'
   If DEBUG = 'TRUE' then say vCmd
   else vCmd
END

If ~Exists('c:llist') then DO
   Say 'llist does not exist.'
   Call DownloadFile('Downloading llist','http://aminet.net/util/shell/LList.lha',PrerequisiteDownloadFolder||'/llist.lha',3,1)
   Call Unlha(PrerequisiteDownloadFolder||'/llist.lha',PrerequisiteExtractFolder||'/')
   vCmd = 'copyreplace >NIL: FROM "'PrerequisiteExtractFolder||'/LList-V39-030" TO c:llist CLONE FOOVR QUIET'
   If DEBUG = 'TRUE' then say vCmd
   else vCmd
END

If ~Exists('c:unzip') then DO
   Say 'unzip does not exist.'
   Call DownloadFile('Downloading llist','http://aminet.net/util/arc/UnZIP552.lha',PrerequisiteDownloadFolder||'/Unzip.lha',3,1)
   Call Unlha(PrerequisiteDownloadFolder||'/unzip.lha',PrerequisiteExtractFolder||'/')
   vCmd = 'copyreplace >NIL: FROM "'PrerequisiteExtractFolder||'/UnZip552/UnZip" TO c: CLONE FOOVR QUIET'
   If DEBUG = 'TRUE' then say vCmd
   else vCmd
END

Call DownloadFile('Getting link to server',UpdateSheetURL||UpdateSheetScriptGID,ScriptUpdateFilePath,3,0)

if ~Exists(ScriptUpdateFilePath) then call CloseProgram("Download Failed",10,3)

If ReadFile(ScriptUpdateFilePath,ScriptURL) then do
   URL = strip(ScriptURL.1)
   Call DownloadFile('Downloading Emu68 Updater',URL,Emu68UpdaterScriptFolder||'/Emu68-Updater.rexx',3,0)
   VersionNewScript = GetVersion(Emu68UpdaterScriptFolder||'/Emu68-Updater.rexx','FILE')
   If EXISTS(DefaultScriptPath||'/Emu68-Updater.rexx') then VersionOldScriptPath = DefaultScriptPath||'/Emu68-Updater.rexx'
   ELSE DO
      If right(ScriptPath,1) = ':' | right(ScriptPath,1) = '/' then VersionOldScriptPath = ScriptPath||'Emu68-Updater.rexx'
      else VersionOldScriptPath = ScriptPath||'/Emu68-Updater.rexx'
   END
   VersionOldScript = GetVersion(VersionOldScriptPath,'FILE')
   If VersionOldScript ~= 'ERROR' then DO   
      UpdateNeeded = CheckUpdateNeeded(VersionOldScript,VersionNewScript)
      say 'Current version of script: 'VersionOldScript'. Version of script on server: 'VersionNewScript'.'
   END
   ELSE DO
      vCmd = 'echo "Current version of Script cannot be found! Do you want to overwrite with server version ('VersionNewScript')? Y/N" NOLINE'
      vCmd
      Pull Response
      if upper(Response)='Y' | upper(Response)='YES' then UpdateNeeded = 'TRUE'
      ELSE UpdateNeeded = 'FALSE'   
   END   
   if UpdateNeeded = 'TRUE' then DO
      say 'Script needs updating! Please restart to complete update'
      vCmd = 'copyreplace >NIL: FROM 'Emu68UpdaterScriptFolder'/Emu68-Updater.rexx TO 'ScriptPath' CLONE FOOVR QUIET'
      If DEBUG = 'TRUE' then say vCmd
      else vCmd
      EXIT
   END
   ELSE SAY 'Script is up-to-date'
end

Say ''

vCmd = 'SYS:C/EMU68INFO variant >'PiStormVariantPath 
VCmd

IF RC>0 then DO 
   Say 'Identifying variant of PiStorm: You are not running PiStorm'
   PistormVariant='None'
   Flag_UpdateEmu68 = "FALSE"
   Flag_UpdateVideoCore = "FALSE"
END
else DO
   If ~READFILE(PiStormVariantPath,PiStormVariantLine) then Call CloseProgram("Error reading PiStorm variant",10,3) 
   'delete 'PiStormVariantPath' QUIET >NIL:' 
   PistormVariant = PiStormVariantLine.1
   Emu68Version = GetEmu68Version()
   say 'Identifying variant of PiStorm: Running 'PistormVariant' Emu68 Version: 'Emu68Version 

   if Pos('1.1',Emu68Version) = 0 & (PistormVariant = 'pistorm' | PistormVariant = 'pistorm32lite') THEN DO 
      Flag_UpdateEmu68 = "TRUE"
      Flag_UpdateVideoCore = "TRUE"
   end
   Else DO
      Say 'Cannot update Emu68 and Videocore with this version of Emu68'
      Flag_UpdateEmu68 = "FALSE"
      Flag_UpdateVideoCore = "FALSE"
   END
END

If Flag_UpdateEmu68 = "TRUE" then DO
   DeviceListPath 'raw_dostype='TargetDostype' NOFORMATTABLE >'ListofEmu68DisksFile 
   FAT32Device = ''
   if READFILE(ListofEmu68DisksFile,ListofDisks) then DO
      found_count = 0
      DO i=1 to ListofDisks.0
         parse var ListofDisks.i vDevice';'vRawDosType';'vDosType';'vDeviceName';'vUnit';'vVolume
         found_count = found_count + 1
         if found_count = 1 then FAT32Device = vDevice':'
      END
      SELECT
         WHEN found_count = 1 then DO
            Say 'Found FAT32 partition at device: 'FAT32Device 
         END
         WHEN found_count > 1 then DO
            Say 'Error finding FAT32 partition. Not updating Emu68 or Videocore.card'
            FAT32Device = 'ERROR'
         END
         OTHERWISE DO
            Say "FAT32 device not mounted!"
            If FAT32DevicetoMount=":" then DO 
               Say 'No FAT32 Device defined in tooltype. Not updating Emu68 or Videocore.card'
               FAT32Device = 'ERROR'
            END
            ELSE Do
               Say "Attempting mount of "FAT32DevicetoMount
               'mount 'FAT32DevicetoMount
               IF RC>0 THEN DO 
                  Say 'Unable to mount FAT32 Device as device not defined in tooltype. Not updating Emu68 or Videocore.card'
                  FAT32Device = 'ERROR'
               END
               Else DO
                  Say 'Mount successful'
                  FAT32Device = FAT32DevicetoMount
               END
            END
         END
      END   
   END
   IF FAT32Device = 'ERROR' | FAT32Device = '' then DO
      Flag_UpdateEmu68 = "FALSE"
      Flag_UpdateVideoCore = "FALSE"
      Emu68FileName = ''
   END
   ELSE DO
      Flag_UpdateVideoCore = "TRUE"
      Emu68FileName = 'Emu68-'||PistormVariant
      Emu68FileNameLength = Length(Emu68FileName)
   END   
END
      

If Flag_UpdateEmu68 = "TRUE" then DO
   if Readfile(FAT32Device||'Config.txt',ConfigtxtLines) then Do 
      PathsFound = 0
      Emu68FilePath = ''
      do i=1 to ConfigtxtLines.0
         line = strip(ConfigtxtLines.i)
         if left(upper(line),7)='KERNEL=' & right(upper(line),Emu68FileNameLength) = upper(Emu68FileName) then DO
            If Emu68FilePath ~= substr(line,8) then DO
               PathsFound = PathsFound + 1
               If PathsFound > 1 then leave
               Emu68FilePath = substr(line,8) 
            END            
         end
      end      
   end
   Select
     WHEN PathsFound = 0 then DO
        Say 'No references to Emu68 found! Cannot update Emu68 or Videocore.'
        Flag_UpdateEmu68 = "FALSE"
        Flag_UpdateVideoCore = "FALSE"
        Emu68FilePath = ''
     END
     WHEN PathsFound > 1 then DO
        Say 'Multiple references to Emu68 found! Cannot update Emu68 or Videocore.'
        Flag_UpdateEmu68 = "FALSE"
        Flag_UpdateVideoCore = "FALSE"
        Emu68FilePath = ''
     END
     Otherwise DO
        if left(Emu68FilePath,1) = '/' then Emu68FilePath = substr(EMU68FilePath,2)
        Say 'Found Emu68 files at:'FAT32Device||Emu68FilePath                     
     END
   END  
end            

/* Stage One - Perform Prerequisite Checks - Finish */

/* Stage One - Retrieve List of Files for Update - Start */

Call DownloadFile('Stage 1 - Retrieve List of Files for Update',UpdateSheetURL||UpdateSheetGID,UpdateFilePath,3,0)

if ~Exists(UpdateFilePath) then call CloseProgram("Download Failed",10,3)

KickstartVersionFound = GetVersion("","")
Select 
   When KickstartVersionFound = '47.115' then KickstartVersionFound = '3.2.3'
   WHEN KickstartVersionFound = '47.111' then KickstartVersionFound = '3.2.2.1'
   WHEN KickstartVersionFound = '47.96' then KickstartVersionFound = '3.2'
   WHEN KickstartVersionFound = '40.68' then KickstartVersionFound = '3.1'
   WHEN KickstartVersionFound > 40.99 & KickstartVersionFound < 47 then KickstartVersionFound = '3.9'
   Otherwise KickstartVersionFound = "Unknown"
END

delimiter = d2c(9)
ListofUpdateLinesCleansed.0 = "Unknown"
Counter = 0

If ReadFile(UpdateFilePath,UpdateLines) then Do
   do i=2 to UpdateLines.0
      If POS(';',UpdateLines.i) > 0 then do    
         Parse var UpdateLines.i Keep(delimiter)Trash
         Keep = strip(Keep)
         Parse var Keep Trash1';'Trash2';'KickstartVersion';'
         If Keep ~= '' & POS(KickstartVersionFound,KickstartVersion) > 0 then DO
             Counter = Counter + 1
             ListofUpdateLinesCleansed.Counter = Keep 
         END
      END  
   END
END

ListofUpdateLinesCleansed.0 = Counter

/* Say 'Found 'ListofUpdateLinesCleansed.0' lines to process' */


/* Stage One - Retrieve List of Files for Update - Finish */

/* Stage Two  - Download Files -START */


Say 'Stage 2 - Downloading Files for Update and Uncompresssing'
Say ''

PackageNametoReport = ''

Do i = 1 to ListofUpdateLinesCleansed.0
   VersionFound = ''
   Line = strip(ListofUpdateLinesCleansed.i) 
   parse var line Sequence';'AmigaVersionCheck';'KickstartVersion';'PackageName';'AminetSearch';'Source';'GithubPage';'GithubName';'GithubRelease';'SourceLocation';'FileDownloadName';'FilestoInstall';'DrivetoInstall';'LocationtoInstall';'FilesToDelete';'BackupFolder';'SearchPathType';'SearchPathFile';'NewFileName
   if AmigaVersionCheck ~= 'TRUE' then iterate
   If PackageName ~= PackageNametoReport then DO
      RevisedPath = ''
      Say 'Processing Package: 'PackageName
   end
   PackageNametoReport = PackageName
   if POS('EMU68 PISTORM',upper(PackageName)) > 0 then DO
      If Flag_UpdateEmu68 = "TRUE" then DO
        If upper(PackageName) = 'EMU68 PISTORM32LITE' & upper(PistormVariant) ~= 'PISTORM32LITE' then DO
           say ''
           iterate
        end
        If upper(PackageName) = 'EMU68 PISTORM' & upper(PistormVariant) ~= 'PISTORM' then DO
           say ''
           iterate
           END
      END
      ELSE DO
         Say 'Cannot update Emu68 as either you are not using PiStorm, the version is too recent (1.1), or the files could not be found'
         Say ''
         iterate
      END
   END
   if POS('VIDEOCORE',upper(PackageName)) > 0 & Flag_UpdateVideocore = "FALSE"  then do
      say 'Cannot update Videocore as either you are not using PiStorm or the version is too recent (1.1)'
      say ''
      iterate
   end
   FilesToInstall = Translate(FilestoInstall,'/','\')
   LocationtoInstall = Translate(LocationtoInstall,'/','\')     
   Select 
      WHEN upper(DrivetoInstall) = 'EMU68BOOT' then DO
         DrivetoInstall = FAT32Device
         If LastPos('/',Emu68FilePath) > 0 then LocationtoInstall = left(Emu68FilePath,(LastPos('/',Emu68FilePath)-1))
         Else LocationtoInstall = ''
      END
      WHEN upper(DrivetoInstall) = 'SYSTEM' then DrivetoInstall = 'SYS:'
      Otherwise DrivetoInstall = DrivetoInstall||':'
   END
   if NewFileName~='' then FileName = NewFileName   
   ELSE DO    
      FileNameStartPoint = LastPos('/',FilestoInstall)
      If FileNameStartPoint > 1 then FileName = substr(FilestoInstall,FileNameStartPoint+1)
      Else FileName = FilestoInstall          
   END
   If LocationtoInstall ~='' then ExistingFiletoCheckPath = DrivetoInstall||LocationtoInstall||'/'||FileName
   Else ExistingFiletoCheckPath = DrivetoInstall||FileName
   If ~Exists(ExistingFiletoCheckPath) then do
      If SearchPathFile ~='' then do 
         SELECT
            WHEN upper(SearchPathType)='PROGRAMS' & ProgramsSearchFolder ~= '' then RevisedPath = FindFile(ProgramsSearchFolder,SearchPathFile)
            WHEN upper(SearchPathType)='PISTORM' & PistormSearchFolder ~= '' then RevisedPath = FindFile(PistormSearchFolder,SearchPathFile)
            Otherwise RevisedPath = 'ERROR'
         END
         If RevisedPath ~= 'ERROR' then DO
            SAY 'Could not find default install location. Default path: "'ExistingFiletoCheckPath'" replaced with "'RevisedPath||'/'||FileName'"' 
            ExistingFiletoCheckPath = RevisedPath||'/'||FileName             
         END      
      end
   END   
   ListofUpdateLinesCleansed.i = ListofUpdateLinesCleansed.i||';'||RevisedPath
   /* Say 'DEBUG - Line Number: 'Sequence' ExistingFilePath: 'ExistingFiletoCheckPath */
   If ~Exists(ExistingFiletoCheckPath) then DO
      say 'Cannot update "'PackageName'" as not installed (or not installed in expected location)!'
      say ''
      iterate
   END
   VersionFound = GetVersion(ExistingFiletoCheckPath,'FILE')
   vCmd = 'echo "'FilestoInstall||';'||VersionFound'" >"'VersionDataFolder'/'PackageName'"'
   vCmd       
   DownloadLocation = DownloadFolder"/"FileDownloadName
   Say 'Found 'Filename' version 'VersionFound
   if Exists(DownloadLocation) then DO
      say FileDownloadName' already downloaded'
      say ''
   end
   ELSE DO
      Select
         WHEN Source="Web" then DO        
            Message = 'DLing 'FileDownloadName
            Call DownloadFile(Message,SourceLocation,DownloadLocation,3,1)
         END
         When Source="Web - SearchforPackageAminet" then DO
            AminetDLLocation = GetLatestAminetURL(AminetSearch)
            if AminetDLLocation ~="ERROR" then do
               Message = 'DLing 'FileDownloadName
               Call DownloadFile(Message,AminetDLLocation,DownloadLocation,3,1) 
            end
         end   
         When Source="Github" then DO
            GithubFilesDownloadURL =''
            GithubPathJSONURL = SourceLocation
            GithubPathURL = GitHubPage
            JsonDownloadPath = TempFolder||'/'||PackageName||'.json'
            Call DownloadFile('Looking for release information from Github for '||PackageName,SourceLocation,JsonDownloadPath,3,0)
            TagValue = ProcessJSONFile(JsonDownloadPath)
            if right(GithubName,1)='.' then GithubName = left(GithubName,(length(GithubName)-1))
            GithubFilesDownloadURL = GitHubPage||'/download/'||TagValue||'/'||GithubName||'.zip'
            Message = 'DLing 'FileDownloadName
            Call DownloadFile(Message,GithubFilesDownloadURL,DownloadLocation,3,1) 
         END
         Otherwise nop                        
      END
   END
END

say ''
say "Completed Downloads!"
say ''
Say 'Uncompressing Downloaded Files'
say ''
if Getdir(DownloadFolder||'/','(#?.lha|#?.zip)','ListofFiles','FILES','PATH','SUBDIRS') then DO
   do i = 1 to ListofFiles.0
      Parse Var ListofFiles.i SubFolder'.'
      SubFolder = substr(SubFolder,(lastpos('/',SubFolder)+1))
      if ~IsFolder(ExtractedFilesFolder||'/'||SubFolder) then do 
         say 'Extracting file 'ListofFiles.i
         If upper(Right(ListofFiles.i,4))=".LHA" then call Unlha(ListofFiles.i,ExtractedFilesFolder||'/'||SubFolder||'/')
         If upper(Right(ListofFiles.i,4))=".ZIP" then call Unzip(ListofFiles.i,ExtractedFilesFolder||'/'||SubFolder)
      END
      Else Say ListofFiles.i' already extracted'
   end
END

/* Stage Two  - Download Files - Finish */

/* Stage Three - Perform Updates - Start */

Say ''
Say 'Stage 3 - Peforming Updates where needed'
Say ''

PackageNametoReport = ''
PackageNeedsUpdating = ''

Do i = 1 to ListofUpdateLinesCleansed.0
   PathtoCurrentVersion = ''
   Line = strip(ListofUpdateLinesCleansed.i) 
   parse var line Sequence';'AmigaVersionCheck';'KickstartVersion';'PackageName';'AminetSearch';'Source';'GithubPage';'GithubName';'GithubRelease';'SourceLocation';'FileDownloadName';'FilestoInstall';'DrivetoInstall';'LocationtoInstall';'FilesToDelete';'BackupFolder';'SearchPathType';'SearchPathFile';'NewFileName';'RevisedPath
   if PackageName = '' then iterate
   PathtoCurrentVersion = VersionDataFolder'/'PackageName 
   If PackageName ~= PackageNametoReport then DO
      PathtoFutureVersion = ''
      PackageNeedsUpdating = ''      
      Say ''
      If Exists(PathtoCurrentVersion) then Do
         Say 'Processing Package: 'PackageName
         if READFILE(PathtoCurrentVersion,'FilePathandVersion') then do
            parse Var FilePathandVersion.1 FilePathtoExtractedFile';'CurrentVersion
            If Pos('#?',FilePathtoExtractedFile) > 0 then do
               parse Var FileDownloadName NameofFile'.'                 
               ExtensiontoUse = upper(substr(FilePathtoExtractedFile,(LastPos('.',FilePathtoExtractedFile)+1)))
               PathtoFutureVersion = FindFilewithWildCard(FilePathtoExtractedFile,(ExtractedFilesFolder||'/'NameofFile),ExtensiontoUse)
               say PathtoFutureVersion
            end
            else Do
               If upper(right(FileDownloadName,4)) ~= ".LHA" & upper(right(FileDownloadName,4)) ~= ".ZIP" then PathtoFutureVersion = DownloadFolder||'/'FilePathtoExtractedFile
               ELSE DO            
                  parse Var FileDownloadName NameofFile'.'                        
                  PathtoFutureVersion =  ExtractedFilesFolder||'/'NameofFile||'/'||FilePathtoExtractedFile
               END            
            END
            DownloadedFileVersion = GetVersion(PathtoFutureVersion,'FILE')
            If DownloadedFileVersion = 'ERROR' then DO
               say 'Error identifying version of downloaded file! Skipping!' 
               iterate
            END        
            If CurrentVersion = 'ERROR' & DownloadedFileVersion ~= 'ERROR' then DO          
               vCmd = 'echo "Current version cannot be found! Do you want to overwrite with server version ('DownloadedFileVersion')? Y/N" NOLINE'
               vCmd
               Pull Response
               if upper(Response)='Y' | upper(Response)='YES' then PackageNeedsUpdating = 'TRUE'
               ELSE PackageNeedsUpdating  = 'FALSE'   
            END
            If PackageNeedsUpdating = '' & DownloadedFileVersion ~= 'ERROR' then DO
               PackageNeedsUpdating = CheckUpdateNeeded(CurrentVersion,DownloadedFileVersion,'FILE')
               If PackageNeedsUpdating = "FALSE" then say 'Current version is: 'CurrentVersion'. New version is: 'DownloadedFileVersion'. Nothing to do!'
               Else DO
                  say 'Current version is: 'CurrentVersion'. New version is: 'DownloadedFileVersion'. Current installed package is out-of-date.' 
                  If AskResponse() then say 'Performing update of 'PackageName
                  ELSE DO
                     say 'Not updating 'PackageName
                     PackageNeedsUpdating = 'FALSE'
                  END
               END
            END
         END
      End
      Else say 'Not updating 'PackageName
   end
   /* Say Sequence */
   PackageNametoReport = PackageName
   /* Comment out below line for testing */
   If PackageNeedsUpdating = '' | PackageNeedsUpdating = "FALSE" then iterate
   FilesToInstall = Translate(FilestoInstall,'/','\')
   LocationtoInstall = Translate(LocationtoInstall,'/','\')  
   Select 
      WHEN upper(DrivetoInstall) = 'SYSTEM' then DrivetoInstall = 'SYS:'
      WHEN upper(DrivetoInstall) = 'EMU68BOOT' then DrivetoInstall = FAT32Device
      OTHERWISE DrivetoInstall = DrivetoInstall||':'
   END
   if NewFileName ~= '' then FileName = NewFileName 
   ELSE FileName = '' 
   DO
      FileNameStartPoint = LastPos('/',FilestoInstall)
      If FileNameStartPoint > 1 then FileName = substr(FilestoInstall,FileNameStartPoint+1)
      Else FileName = FilestoInstall
   END
   If RevisedPath ~= '' then DO
      Say 'Not installed in default location. Revising path to:' RevisedPath
      Select
         WHEN upper(SearchPathType)='PISTORM' then LocationtoInstall = RevisedPath
         WHEN upper(SearchPathType)='PROGRAMS' then LocationtoInstall = RevisedPath
         Otherwise nop
      END 
   END  
   If DrivetoInstall = FAT32Device then InstallPath = FAT32Device||Emu68FilePath                     
   ELSE DO             
      If LocationtoInstall ~='' then InstallPath = DrivetoInstall||LocationtoInstall||'/'
      Else InstallPath = DrivetoInstall
      If NewFileName ~= '' then InstallPath = InstallPath||NewFileName
   END
   If upper(right(FileDownloadName,4)) ~= ".LHA" & upper(right(FileDownloadName,4)) ~= ".ZIP" then FullPathFilestoInstall = DownloadFolder||'/'FilestoInstall
   ELSE FullPathFilestoInstall = ExtractedFilesFolder||'/'NameofFile||'/'FilestoInstall
   If BackupFolder ~= '' then DO
      If LocationtoInstall = '' then BackupFolderPath = DrivetoInstall||BackupFolder
      ELSE BackupFolderPath = DrivetoInstall||LocationtoInstall||'/'||BackupFolder
      If DrivetoInstall = FAT32Device then FiletoBackup = InstallPath
      ELSE FiletoBackup = InstallPath||FileName 
      Say 'Backing up file: "'FiletoBackup'" to Backup folder: "'BackupFolderPath'"'
      vCmd = 'c:copyreplace >NIL: FROM "'FiletoBackup'" TO "'BackupFolderPath'/'FileName||CurrentVersion'" CLONE FOOVR QUIET'
      If DEBUG = 'TRUE' then say vCmd
      else vCmd
   END
   If FilesToDelete ~= '' then DO
      vCmd = 'c:delete >NIL: 'InstallPath||FilesToDelete' FORCE QUIET'
      If DEBUG = 'TRUE' then say vCmd
      else vCmd
   END
   vCmd = 'c:copyreplace >NIL: FROM "'FullPathFilestoInstall'" TO "'InstallPath'" CLONE FOOVR QUIET'
   If DEBUG = 'TRUE' then say vCmd
   else vCmd 
end

/* Stage Three - Perform Updates - Finish */

Say 'Updates Completed! Deleting Temporary Files'
vCmd = 'c:delete >NIL: "'TempFolder'" ALL QUIET' 
If DEBUG = 'TRUE' then say vCmd
else vCmd
Say 'This window will close in 3 seconds'
'wait 3'

EXIT

/* ================= FUNCTIONS ================= */
CreateFolder:
   parse arg FoldertoCreatePath
   FullPathtoCreate = ''
   DO WHILE FoldertoCreatePath ~= ''
      PARSE VAR FoldertoCreatePath segment '/' FoldertoCreatePath
      IF FullPathtoCreate = '' then FullPathtoCreate = segment
      ELSE FullPathtoCreate = FullPathtoCreate||'/'||segment
      If ~EXISTS(FullPathtoCreate) then DO      
         vCmd = 'c:makedir "'FullPathtoCreate'"'
         vCmd
      END  
   END
   return
AskResponse:
   vCmd = 'echo "New version found! Do you want to update your current version? Y/N " NOLINE'
   vCmd
   Pull Response
   if upper(Response)='Y' | upper(Response)='YES' then Return 1
   ELSE Return 0
FindFilewithWildCard:
   Parse Arg SearchTerm,PathtoSearch,FileExtensiontoSearch
   FoundPath = 'Not Found'
   Wildcard = '#?'
   TempFile = TempFolder||'/SearchFile.txt' 
   PositionofWildCard = POS(Wildcard,SearchTerm)
   FirstPart = left(SearchTerm,(PositionofWildCard-1))
   SecondPart = substr(SearchTerm,(PositionofWildCard+Length(Wildcard)))
   vCmd = 'llist DIR='PathtoSearch'  pat="#?.'FileExtensiontoSearch'" ALL FILES LFORMAT="%p%m" >'TempFile
   VCmd
   If ReadFile(TempFile,ListofFiles) then Do
      do tempi=1 to ListofFiles.0
      if POS(FirstPart,ListofFiles.tempi) > 0 & POS(SecondPart,ListofFiles.tempi) > 0 then DO
         FoundPath = ListofFiles.tempi
         leave
      END
   end
   Return FoundPath
IsFolder:
   Parse ARG TempPath
   TempFile = TempFolder||'/SearchFolder.txt'
   vCmd = 'c:llist "'TempPath'" LFORMAT="" >'TempFile
   vCmd
   If ReadFile(TempFile,FoundFolders) then Do
      if POS('object not found',FoundFolders.1)>0 then RETURN 0
      Else Return 1 
   END 
FindFile:
   Parse ARG TempPath,SearchTerm 
   TempFile = TempFolder||'/SearchFile.txt' 
   vCmd = 'c:llist "'TempPath'" p=#?'SearchTerm' ALL FILES LFORMAT="%p;%n" >'TempFile
   vCmd
   If ReadFile(TempFile,FoundFiles) then Do
      Counter = 0
      do tempi=1 to FoundFiles.0
         if POS(';',FoundFiles.tempi) = 0 then iterate
         Divider = pos(";",FoundFiles.tempi)
         FileNameFound = Substr(FoundFiles.tempi,Divider+1)
         If upper(FileNameFound) = upper(SearchTerm) then do
            Counter = Counter + 1
            If Counter > 1 then Do
               Say "Multiple copies of program found!"
               leave 
            END
            PathtoReturn = left(FoundFiles.tempi,Divider-1)
            if right(PathtoReturn,1) = '/' then PathtoReturn = left(PathtoReturn,(length(PathtoReturn)-1))
         end
      End
   End
   If Counter = 1 then Return PathtoReturn
   ELSE Return 'ERROR'
GetLatestAminetURL:
   Parse ARG AminetURL
   TempFile = TempFolder'/AminetReleaseData.txt'
   call DownloadFile('DLing latest Release from Aminet',AminetURL,TempFile,3,0)
   download_url = ""
   if READFILE(TempFile,SearchResultData) then do
      tempj = 0
      tempi = 0
      do tempi=1 to SearchResultData.0   
         IF POS('pkg_row',SearchResultData.tempi) > 0 THEN DO
            tempj = tempi+2
            IF POS('<a href="', SearchResultData.tempj) > 0 THEN DO
               PARSE VAR SearchResultData.tempj '<a href="' download_url '"' .
               LEAVE
            END    
         END 
      END
   END
   IF download_url ~= "" THEN Return "https://aminet.net"download_url
   ELSE RETURN "ERROR"
GetEmu68Version:
   TempFile = TempFolder||'/VersionCheck.txt'
   vCmd = 'c:emu68info idstring >'TempFile
   VCmd
   Version = ''
   if ~READFILE(Tempfile,VersionData) then call CloseProgram("Error Reading version information",10,3)
   parse VAR VersionData.1 'Emu68 'Version' '
   return Version
GetVersion:
   Vcmd = ''
   parse ARG path,FileSwitch
   TempFile = TempFolder||'/VersionCheck.txt'
   Version = ''
   SELECT
      WHEN FileSwitch = "FILE" & path ~="" then vCmd = 'version >'TempFile' "'path'" FILE'
      WHEN path ="" & FileSwitch = "" then vCmd = 'version >'TempFile
      OTHERWISE vCmd = 'version >'TempFile' "'path'"'
   end   
   vCmd
   If RC > 0 then DO
      Version = 'ERROR'
      return Version
   END
   if ~READFILE(Tempfile,VersionData) then call CloseProgram("Error Reading version information",10,3)
   If path = '' then do
      parse VAR VersionData.1 LibraryName Version
      Parse Var Version VersionToReturn","
      Version = Strip(VersionToReturn)
   end
   else do
      if left(VersionData.1,6) = '$VER: ' then VersionData.1 = substr(VersionData.1,7)
      Parse Var VersionData.1 ProgramName' 'VersiontoCleanse
      Parse Var VersiontoCleanse Version' '
      Version = Strip(Version)
    end
   return Version
IsAmiSSL:
   if (GetVersion('amisslmaster.library','') > 4) THEN RETURN 1 
   ELSE RETURN 0
   Return  
CloseProgram:
   Parse ARG CloseProgramMessage, ExitNumber, TimetoClose
   Say ""
   Say CloseProgramMessage
   'delete >NIL: t:Emu68Updater ALL QUIET'
   Say 'This window will close in 'TimetoClose' seconds'
   'wait sec='TimetoClose 
   Exit
   Return   
DownloadFile:
   Parse ARG TempMessage,URL,DLLocation,NumberAttempts,EnableProgressBar
   Attempt = 1
   If TempMessage = '' then TempMessage = 'Downloading'
   if EnableProgressBar = 1 then DO  
      'setenv InProgressBar 'TempMessage
      'run >T:Progressbar.txt rx S:ProgressBar.rexx'
   END
   ELSE Say TempMessage
   Do until IsDLed="TRUE"
      If Attempt > 1 then Say 'Download Failed! Trying Again. Attempt number: 'Attempt 
      vCmd = 'c:aget "'URL'" TO "'DLLocation'" >NIL:'
      VCmd
      if RC = 0 then IsDLed="TRUE"
      ELSE Attempt = Attempt +1
      IF Attempt > NumberAttempts then DO
         if EnableProgressBar = 1 then DO
            'setenv InProgressBar ERROR'
            'delete T:Progressbar.txt >NIL: QUIET'
         END
         ELSE DO
            say "Unable to download file!"
            Say ""
         END
      END
   END
   IF EnableProgressBar = 1 then DO
      'setenv InProgressBar COMPLETE'
      'delete T:Progressbar.txt >NIL: QUIET'
      'wait 1'
   END
   ELSE DO
      Say "Download Successful!"
      Say ""
   END
   Return
Unzip:
    Parse ARG SourcePath, DestinationPath
    vCmd = 'c:unzip -o "'SourcePath'" -d "'DestinationPath'" >NIL:'
    vCmd
    RETURN   
Unlha:
   Parse ARG SourcePath, DestinationPath
   vCmd = 'c:lha -aexrm x "'SourcePath'" "'DestinationPath'" >NIL:' 
   VCmd
   Return  
ProcessJsonFile:
   Parse arg  PathtoJsonFile
   IF ~OPEN(inputfile, PathtoJsonFile, 'R') THEN Call CloseProgram('Could not open Emu68 file details',10,3)

   tag_value = ""
   target_key = '"tag_name":'

   required_draft_status = '"draft":false'
   required_prerelease_status = '"prerelease":false'

   DO WHILE ~EOF(inputfile)
      line = READLN(inputfile) 
      IF POS(target_key, line) > 0 & POS(required_draft_status, line) > 0 & POS(required_prerelease_status, line) > 0 THEN DO
         key_pos = POS(target_key, line)
         value_part = SUBSTR(line, key_pos + LENGTH(target_key))
         value_part = STRIP(value_part, 'L')
         IF LEFT(value_part, 1) = '"' THEN DO
            end_quote_pos = POS('"', SUBSTR(value_part, 2))
            IF end_quote_pos > 0 THEN DO
                tag_value = SUBSTR(value_part, 2, end_quote_pos - 1)
                LEAVE
            END
         END
      END
   END
   CALL CLOSE(inputfile)
   IF tag_value = "" THEN CALL CloseProgram('Could not find a valid release (draft:false, prerelease:false) in the file.',3,3)
   ELSE Return tag_value  
CheckUpdateNeeded:
   parse arg OldVersion,NewVersion
  
   parse var OldVersion vFieldThowAway OV_Major'.'OV_Minor'.'OV_Patch'.'OV_Build
   parse var NewVersion vFieldThrowAway NV_Major'.'NV_Minor'.'NV_Patch'.'NV_Build

   if OV_Major = "" then OV_Major = 0; if NV_Major = "" then NV_Major = 0
   if OV_Minor = "" then OV_Minor = 0; if NV_Minor = "" then NV_Minor = 0
   if OV_Patch = "" then OV_Patch = 0; if NV_Patch = "" then NV_Patch = 0
   if OV_Build = "" then OV_Build = 0; if NV_Build = "" then NV_Build = 0

   If upper(left(OV_Major,1)) = 'V' then OV_Major = substr(OV_Major,2)

   UpdateNeeded="FALSE"

   if (NV_Major = OV_Major) & (NV_Minor = OV_Minor) & (NV_Patch = OV_Patch) & (NV_Build = OV_Build) then UpdateNeeded="FALSE"
   ELSE DO
      if NV_Major > OV_Major then UpdateNeeded="TRUE"
      else if NV_Major = OV_Major then do
         if NV_Minor > OV_Minor then UpdateNeeded="TRUE"
         else if NV_Minor = OV_Minor then do
            if NV_Patch > OV_Patch then UpdateNeeded="TRUE"
            else if NV_Patch = OV_Patch then do
               if NV_Build > OV_Build then UpdateNeeded="TRUE"
            end
         end
      end
   END
   RETURN UpdateNeeded      