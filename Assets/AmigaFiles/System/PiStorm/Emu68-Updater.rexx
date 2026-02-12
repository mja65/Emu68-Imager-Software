/* $VER: Emu68Updater.rexx 1.1 (24.02.26)                                     */
/* Script to update Emu68 and Videocore files                                 */
/*                                                                            */

/******************************************************************************
 *                                                                            *
 * REQUIREMENTS:                                                              *
 *                                                                            *
 * - Libraries:           rexxtricks.library                                  *
 *                                                                            *
 * - Tools (in C:):       aget, areweonline, ListDevices, unzip               *
 *                                                                            *
 ******************************************************************************/


if ~SHOW('L','rexxtricks.library') then addlib('rexxtricks.library',0,-30,0) 

PARSE ARG input 
input = upper(TRANSLATE(input,' ','='))
PARSE VAR input . 'FAT32DEVICE' InputFAT32Device

InputFAT32Device = STRIP(InputFAT32Device)||":"


ADDRESS COMMAND

DeviceListPath = 'C:ListDevices'
Drivername1 = 'brcm-emmc.device'
Drivername2 = 'brcm-sdhc.device'
TargetDostype = '0x46415401'
Emu68BackupFolderName = 'Backup_Emu68'
VideoCoreBackupFolderName = 'Backup_Videocore'

PiStormVariantPath = 'T:Emu68Updater/PistormVariant'
 
Emu68GithubPathJSONURL =  'https://api.github.com/repos/michalsc/Emu68/releases'
Emu68ToolsGithubPathJSONURL =  'https://api.github.com/repos/michalsc/Emu68-tools/releases'

Emu68GithubPathURL = 'https://github.com/michalsc/Emu68/releases'
Emu68ToolsGithubPathURL = 'https://github.com/michalsc/Emu68-tools/releases'

Emu68json_path = 'T:Emu68Updater/ReleasesEmu68.json'
Emu68Toolsjson_path = 'T:ReleasesTools.json'

ListofEmu68DisksFile = "T:Emu68Updater/DriveInfo.txt"
Emu68FilesLocation = "T:Emu68Updater/Emu68FilesLocation.txt"

Emu68TempFilesFolder = 'T:Emu68Updater/Emu68TempFiles'
Emu68ToolsTempFilesFolder = 'T:Emu68Updater/Emu68ToolsTempFiles'

SAY "Welcome to Emu68 & VideoCore Updater!"
SAY ""
SAY "This script will update your current Emu68 version and VideoCore"
Say "version to the latest official release available on Github."

SAY ""
Say "Section 1: Emu68 - Starting update processs for Emu68"
Say ""

if Exists('t:Emu68Updater') then do
   'delete >NIL: t:Emu68Updater ALL QUIET'   
end

'makedir t:Emu68Updater'

'SYS:C/EMU68INFO variant >'PiStormVariantPath 
IF RC>0 then Call CloseProgram("It seems you're not running Emu68",10,3) 
  
If ~READFILE(PiStormVariantPath,PiStormVariantLine) then Call CloseProgram("Error reading PiStorm variant",10,3) 

PistormVariant = PiStormVariantLine.1
say 'Identified Pistorm as: 'PistormVariant

Emu68FileName = 'Emu68-'||PistormVariant
Emu68FileNameLength = Length(Emu68FileName)

'c:AreWeOnline'
if RC>0 then Call CloseProgram("System is currently offline, please enable your internet connection then try again.",10,3)

'ASSIGN >NIL: AmiSSL: EXISTS'
if RC>0 then Call CloseProgram("AmiSSL not found!",10,3)

DeviceListPath 'raw_dostype='TargetDostype' NOFORMATTABLE >'ListofEmu68DisksFile 

if ~READFILE(ListofEmu68DisksFile,ListofDisks) then Call CloseProgram("Error accessing list of drives!",10,3)

found_count = 0
FAT32Device = ""

DO i=1 to ListofDisks.0
    parse var ListofDisks.i vDevice';'vRawDosType';'vDosType';'vDeviceName';'vUnit';'vVolume
    found_count = found_count + 1
    if found_count = 1 then FAT32Device = vDevice':'
END

If found_count = 0 then DO
   Say "FAT32 device not mounted!"
   If InputFAT32Device=":" then DO 
      Say 'No FAT32 Device defined in tooltype'
      Call CloseProgram("Error finding FAT32 drive!",10,3)
   END
   ELSE DO
      Say "Attempting mount of "InputFAT32Device
      'mount 'InputFAT32Device
      IF RC>0 THEN Call CloseProgram("Error finding FAT32 drive!",10,3)
      FAT32Device = InputFAT32Device
   END
END

SAY ''
Say 'Found FAT32 partition at device: 'FAT32Device 

if ~Readfile(FAT32Device||'config.txt',ConfigtxtLines) then Call CloseProgram("Error accessing Config.txt!",10,3)

PathsFound=0
Emu68FilePath=""

do i=1 to ConfigtxtLines.0
   line = strip(ConfigtxtLines.i)
   if left(upper(line),7)='KERNEL=' & right(upper(line),Emu68FileNameLength) = upper(Emu68FileName) then DO
      PathsFound = PathsFound + 1
      If Emu68FilePath ~= "" & upper(Emu68FilePath) ~= upper(substr(line,8)) then Call CloseProgram("Multiple different entries for 'Kernel=' lline in config.txt file!",10,3)
      else do
         if Emu68FilePath = "" then do
            Emu68FilePath = substr(line,8)
            if left(Emu68FilePath,1)='/' then Emu68FilePath =  substr(EMU68FilePath,2)
         end
      end
   END
end

if Emu68FilePath="" then exit
Emu68FilePath = FAT32Device||Emu68FilePath

Emu68FolderLocation = left(Emu68FilePath,(Length(Emu68FilePath)-Emu68FileNameLength))

if right(Emu68FolderLocation,1)~=':' & right(Emu68FolderLocation,1)~='/' then Emu68FolderLocation = Emu68FolderLocation||'/' 

Say 'Found Emu68 files at:'Emu68FilePath

BackupFolderPathEmu68 = Emu68FolderLocation||Emu68BackupFolderName

Say ""
Say "Obtaining list of Emu68 releases"

Call DownloadFile('Trying download from Github for available Emu68 releases.',Emu68GithubPathJSONURL,Emu68json_path,3)

Emu68TagValue = ProcessJSONFile(Emu68json_path)

SAY  'Downloading latest Emu68-'PistormVariant' release...'

Emu68FilesDownloadURL = Emu68GithubPathURL||'/download/'||Emu68TagValue||'/Emu68-'||PistormVariant||'.zip'
DestinationEmu68Zip = 'T:Emu68Updater/Emu68-'||PistormVariant'.zip'

Call DownloadFile('Trying download from Github for Emu68 files',Emu68FilesDownloadURL,DestinationEmu68Zip,3)

call Unzip(DestinationEmu68Zip,Emu68TempFilesFolder) 

SAY "Files unzipped"

Say ""
SAY "Starting Emu68 update process..."
SAY ""

FilePathNewversion = Emu68TempFilesFolder||'/Emu68-'PistormVariant

'version 'Emu68FilePath' FILE >T:Emu68Updater/Emu68OldVersion.txt'
'version 'FilePathNewversion' FILE >T:Emu68Updater/Emu68NewVersion.txt'

if ~READFILE('T:Emu68Updater/Emu68OldVersion.txt',OldVersionEmu68Line) then Call CloseProgram("Error accessing version of Emu68!",10)
if ~READFILE('T:Emu68Updater/Emu68NewVersion.txt',NewVersionEmu68Line) then Call CloseProgram("Error accessing version of Emu68!",10)

OldEmu68Version = OldVersionEmu68Line.1
NewEmu68Version = NewVersionEmu68Line.1

SAY 'Version on your Amiga: 'OldEmu68Version
SAY 'Version found online: 'NewEmu68Version

if POS("EMU68 ",upper(OldEmu68Version)) >0 then Emu68BackupSuffix = SUBSTR(OldEmu68Version,7)
else Emu68BackupSuffix = ""

Emu68BackupFileName = Emu68FileName||Emu68BackupSuffix
 
Emu68UpdateNeeded = CheckUpdateNeeded(OldEmu68Version,NewEmu68Version)


if Emu68UpdateNeeded="FALSE" then DO
   SAY "Your version of Emu68 is already up to date. Nothing to do!"
   SAY ""
END   
ELSE DO
   say""
   'echo "New 'NewEmu68Version' version found, do you want to update your"'
   'echo "current 'OldEmu68Version' version? Y/N? " NOLINE'
   Pull Response
   if upper(Response)='Y' | upper(Response)='YES' then do
      say ""
      say 'Copying file from: 'Emu68FilePath' to: 'BackupFolderPathEmu68
      if ~EXISTS(BackupFolderPathEmu68) then DO
         vCmd = 'makedir "'BackupFolderPathEmu68'"'
         /* say vCmd */ 
         vCmd
      END
      Emu68BackupFullPath = BackupFolderPathEmu68||"/"||Emu68BackupFileName
      vCmd = 'copyreplace "'Emu68FilePath'" TO "'Emu68BackupFullPath'" FORCE QUIET >NIL:'
      /* say vCmd */
      vCmd 
      say 'Copying file from: 'FilePathNewversion' to: 'Emu68FilePath
      vCmd = 'copyreplace "'FilePathNewversion'" TO "'Emu68FilePath'" FORCE QUIET >NIL:'
      /* say vCmd */
      vCmd
   end
   else do
      say "No update to Emu68 made!"
      say ""
   end
END

Say "Section 1: Emu68 - Starting update processs for Emu68 - COMPLETE"
Say ""

Say "Section 2: Videocore - Starting update processs for Videocore"
Say ""
Say "Obtaining list of Emu68-tools releases"
Call DownloadFile('Trying download from Github for available Emu68-Tools releases.',Emu68ToolsGithubPathJSONURL,Emu68Toolsjson_path,3)

Emu68ToolsTagValue = ProcessJSONFile(Emu68Toolsjson_path)

SAY  'Downloading latest Emu68-Tools release...'

Emu68ToolsDownloadURL = Emu68ToolsGithubPathURL||'/download/'||Emu68ToolsTagValue||'/Emu68-Tools.zip'

DestinationEmu68ToolsZip = 'T:Emu68Updater/Emu68-Tools.zip'

Call DownloadFile('Trying download from Github for Emu68 files',Emu68ToolsDownloadURL,DestinationEmu68ToolsZip,3)

call Unzip(DestinationEmu68ToolsZip,Emu68ToolsTempFilesFolder) 

SAY "Files unzipped"
Say ""
SAY "Starting VideoCore update process..."
SAY ""

FilePathVideocoreOldversion = 'LIBS:Picasso96/VideoCore.card' 
FilePathVideocoreNewversion = Emu68ToolsTempFilesFolder||'/VideoCore/VideoCore.card'

'version 'FilePathVideocoreOldversion' FILE >T:Emu68Updater/VideocoreOldVersion.txt'
'version 'FilePathVideocoreNewversion' FILE >T:Emu68Updater/VideoCoreNewVersion.txt'

if ~READFILE('T:Emu68Updater/VideocoreOldVersion.txt',OldVersionVideocoreLine) then Call CloseProgram("Error accessing version of Videocore!",10)
if ~READFILE('T:Emu68Updater/VideoCoreNewVersion.txt',NewVersionVideocoreLine) then Call CloseProgram("Error accessing version of Videcore!",10)

OldVideocoreVersion = OldVersionVideocoreLine.1
NewVideocoreVersion = NewVersionVideocoreLine.1

SAY 'Version on your Amiga: 'OldVideocoreVersion
SAY 'Version found online: 'NewVideocoreVersion
Say ""
VideocoreUpdateNeeded = CheckUpdateNeeded(OldVideocoreVersion,NewVideocoreVersion) 

If VideocoreUpdateNeeded ="FALSE" then Do 
   say "Your version of Videocore is up to date. Nothing to do!"
   Call CloseProgram('Update process complete!',0,3)
end

BackupFolderPathVideocore = "Sys:Libs/Picasso96/"||VideoCoreBackupFolderName

if POS("VIDEOCORE ",upper(OldVideocoreVersion)) >0 then VideocoreBackupSuffix = SUBSTR(OldVideocoreVersion,11)
else VideocoreBackupSuffix = ""



VideocoreBackupFileName = 'Videocore.card'||VideocoreBackupSuffix


'echo "New 'NewVideocoreVersion' version found, do you want to update your"' 
'echo "current 'OldVideocoreVersion' version? Y/N? " NOLINE'
Pull Response
if upper(Response)='Y' | upper(Response)='YES' then do
   say ""
   if ~EXISTS(BackupFolderPathVideocore) then DO
      vCmd = 'makedir 'BackupFolderPathVideocore
      vCmd 
   END
   say 'Copying file from: 'FilePathVideocoreOldversion' to: 'BackupFolderPathVideocore  
   vCmd = 'copyreplace >NIL: "'FilePathVideocoreOldversion'" TO "'BackupFolderPathVideocore'/'VideocoreBackupFileName'" FORCE QUIET'
   /* say vCmd */
   vCmd
   say 'Copying file from: 'FilePathVideocoreNewversion' to: 'FilePathVideocoreOldversion 
   vCmd = 'copyreplace >NIL: "'FilePathVideocoreNewversion'" TO "'FilePathVideocoreOldversion'" FORCE QUIET'
   /* say vCmd */
   vCmd
   say ""  
end

SAY "Identifying Monitor .info file for Videocore"
   
if ~GETDIR('SYS:Devs/Monitors','~(#?.info)',ListofFiles,'FILES','PATH',) then Call CloseProgram("Error identifying monitor files",10)
   
VideocoreFilePath = ""

FoundCount = 0
do i = 1 to ListofFiles.0
   If GetToolTypes(ListofFiles.i,VideocoreToolTypeLines) then DO
      Do j =1 to VideocoreToolTypeLines.0
         TooltipLine = upper(strip(VideocoreToolTypeLines.j))
         if TooltipLine="BOARDTYPE=VIDEOCORE" then DO
            FoundCount = FoundCount + 1
            VideocoreFilePath = ListofFiles.i
            say "Videocore found in: "ListofFiles.i".info"
         END   
      END
   END
end 
         
Select
   WHEN FoundCount = 0 THEN DO
      SAY "Could not find monitor file for Videocore! Cannot check tooltypes!"
      UpdateToolType = "FALSE"
   END
   WHEN FoundCount = 1 THEN DO
      UpdateToolType = "TRUE"        
   END
   WHEN FoundCount > 1 THEN DO
      Say "More than one monitor file found for Videocore! Cannot check tooltypes!"
      UpdateToolType = "FALSE"
   END
   Otherwise NOP
END

say ""

If UpdateToolType = "TRUE" then DO
   SAY "Checking .info file to determine if Tooltype set"
   If ~GetToolTypes(VideocoreFilePath,VideocoreToolTypeLines) then Call CloseProgram('Could not open Videocore.card',10,3)
   LegacyIDFound="FALSE" 
   do i=1 to VideocoreToolTypeLines.0
      if POS('VC4_LEGACY_ID',VideocoreToolTypeLines.i)>0 then Do
         LegacyIDFound="TRUE"
         Leave
      end
   end
   if LegacyIDFound="TRUE" then SAY "VC4_LEGACY_ID tooltype already set"
   else do
      say ""
      'echo "VC4_LEGACY_ID tooltype not found! If you are using the shareware version"'
      'echo "of P96 (version 2.x) you will need to add this."'
      'echo "Do you want to update the Tooltype Y/N? " NOLINE'
      PULL Response
      if upper(Response)='Y' | upper(Response)='YES' then do
         say ""
         SAY "Adding VC4_LEGACY_ID tooltype to Videocore.card"
         If ~SETTOOLTYPEVALUE(VideocoreFilePath,'VC4_LEGACY_ID','') then Call CloseProgram('Could not open Videocore.card',10,3)
      END
   end
END   


Call CloseProgram('Update process complete!',0,3)
   

EXIT
/* ================= FUNCTIONS ================= */

CloseProgram:
   Parse ARG Message, ExitNumber, TimetoClose
   Say ""
   Say Message
   'delete >NIL: t:Emu68Updater ALL QUIET'
   Say 'This window will close in 'TimetoClose' seconds'
   'wait sec='TimetoClose 
   Exit ExitNumber
   Return
DownloadFile:
   Parse ARG Message,URL,DLLocation,NumberAttempts
   Attempt = 1
   Say Message
   /*
   Do until IsDLed="TRUE"
      Say 'Attempt number: 'Attempt 
      'c:aget 'URL'  TO 'DLLocation' >NIL:'
      if RC = 0 then IsDLed="TRUE"
      ELSE Attempt = Attempt +1
      IF Attempt > NumberAttempts then DO
         SAY "It seems the system is currently unable to connect to Github, please try again later."
         SAY "This window will close in 3 seconds."
         'Wait sec=3'
         EXIT 10
      END
   END
   */
   Say "Download Successful!"
   Say ""
   RETURN
Unzip:
    Parse ARG SourcePath, DestinationPath
    'c:unzip -o 'SourcePath' -d 'DestinationPath' >NIL:'
    RETURN   
    
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
   IF tag_value = "" THEN CALL CloseProgram('Could not find a valid release (draft:false, prerelease:false) in the file.',3,10)
   ELSE Return tag_value  
CheckUpdateNeeded:
   parse ARG OldVersion,NewVersion
   parse var OldVersion vFieldThowAwayOLD OV_Major'.'OV_Minor'.'OV_Patch'.'OV_Build
   parse var NewVersion vFieldThrowAwayNEW NV_Major'.'NV_Minor'.'NV_Patch'.'NV_Build

   if OV_Major = "" then OV_Major = 0; if NV_Major = "" then NV_Major = 0
   if OV_Minor = "" then OV_Minor = 0; if NV_Minor = "" then NV_Minor = 0
   if OV_Patch = "" then OV_Patch = 0; if NV_Patch = "" then NV_Patch = 0
   if OV_Build = "" then OV_Build = 0; if NV_Build = "" then NV_Build = 0

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