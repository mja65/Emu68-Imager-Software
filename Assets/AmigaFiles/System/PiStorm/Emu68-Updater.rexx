/* $VER: Emu68Updater.rexx 1.1 (02.02.26)                                     */
/* Script to update Emu68 and Videocore files                                 */
/*                                                                            */

/******************************************************************************
 *                                                                            *
 * REQUIREMENTS:                                                              *
 *                                                                            *
 * - Libraries:           rexxtricks.library                                  *
 *                                                                            *
 * - Tools (in C:):       aget, ListDevices, unzip                            *
 *                                                                            *
 ******************************************************************************/


if ~SHOW('L','rexxtricks.library') then addlib('rexxtricks.library',0,-30,0) 

ADDRESS COMMAND
 
DeviceListPath = 'C:ListDevices'
Drivername1 = 'brcm-emmc.device'
Drivername2 = 'brcm-sdhc.device'
TargetDostype = '0x46415401'
Emu68BackupFolderName = 'Backup_Emu68'
VideoCoreBackupFolderName = 'Backup_Videocore'

PiStormVariantPath = 'T:PistormVariant'
 
Emu68GithubPathJSONURL =  'https://api.github.com/repos/michalsc/Emu68/releases'
Emu68ToolsGithubPathJSONURL =  'https://api.github.com/repos/michalsc/Emu68-tools/releases'

Emu68GithubPathURL = 'https://github.com/michalsc/Emu68/releases'
Emu68ToolsGithubPathURL = 'https://github.com/michalsc/Emu68-tools/releases'

Emu68json_path = 'T:ReleasesEmu68.json'
Emu68Toolsjson_path = 'T:ReleasesTools.json'

ListofEmu68DisksFile = "T:DriveInfo.txt"
Emu68FilesLocation = "T:Emu68FilesLocation.txt"

Emu68TempFilesFolder = 'T:Emu68TempFiles'
Emu68ToolsTempFilesFolder = 'T:Emu68ToolsTempFiles'

SAY "Welcome to Emu68 & VideoCore Updater!"
SAY ""
SAY "This script will update your current Emu68 version and VideoCore version to the latest official release available on Github."
SAY ""

'SYS:C/EMU68INFO variant >'PiStormVariantPath 
IF RC>0 then Call CloseProgram("It seems you're not running Emu68",10,3) 
  
If ~READFILE(PiStormVariantPath,PiStormVariantLine) then Call CloseProgram("Error reading PiStorm variant",10,3) 

'delete 'PiStormVariantPath' QUIET >NIL:' 
PistormVariant = PiStormVariantLine.1
say 'Running 'PistormVariant

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

'delete 'ListofEmu68DisksFile' QUIET >NIL:' 

If found_count = 0 then Call CloseProgram("Error finding FAT32 drive!",10,3)
SAY ''
Say 'Found FAT32 partition at device: 'FAT32Device 

if ~Readfile(FAT32Device||'config.txt',ConfigtxtLines) then Call CloseProgram("Error accessing Config.txt!",10,3)

PathsFound=0
Emu68FilePath=""

do i=1 to ConfigtxtLines.0
   line = strip(ConfigtxtLines.i)
   if left(upper(line),7)='KERNEL=' & right(upper(line),Emu68FileNameLength) = upper(Emu68FileName) then DO
      /*Emu68FilePath = substr(line,8,(length(line)-7-Emu68FileNameLength))*/
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

BackupFolderPath = Emu68FolderLocation||Emu68BackupFolderName


Call DownloadFile('Trying download from Github for Emu68 file details.',Emu68GithubPathJSONURL,Emu68json_path,3)

Emu68TagValue = ProcessJSONFile(Emu68json_path)

SAY  'Downloading latest Emu68-'PistormVariant' release...'
SAY ''

Emu68FilesDownloadURL = Emu68GithubPathURL||'/download/'||Emu68TagValue||'/Emu68-'||PistormVariant||'.zip'
Destination = 'T:Emu68-'||PistormVariant'.zip'

Call DownloadFile('Trying download from Github for Emu68 files',Emu68FilesDownloadURL,Destination,3)

SAY "Download Complete"

call Unzip(Destination,Emu68TempFilesFolder) 

SAY "Files unzipped"

SAY "Starting Emu68 update process..."
SAY ""

FilePathNewversion = Emu68TempFilesFolder||'/Emu68-'PistormVariant

'version 'Emu68FilePath' >T:Emu68OldVersion.txt'
'version 'FilePathNewversion' >T:Emu68NewVersion.txt'

if ~READFILE('T:Emu68OldVersion.txt',OldVersionEmu68Line) then Call CloseProgram("Error accessing version of Emu68!",10)
if ~READFILE('T:Emu68NewVersion.txt',NewVersionEmu68Line) then Call CloseProgram("Error accessing version of Emu68!",10)

OldEmu68Version = OldVersionEmu68Line.1
NewEmu68Version = NewVersionEmu68Line.1

'delete T:Emu68OldVersion.txt QUIET >NIL:'
'delete T:Emu68NewVersion.txt QUIET >NIL:'

SAY 'Version on your Amiga: 'OldEmu68Version
SAY 'Version found online: 'NewEmu68Version

Emu68UpdateNeeded = CheckUpdateNeeded(OldEmu68Version,NewVersion)

if Emu68UpdateNeeded="FALSE" then SAY "Your version of Emu68 is already up to date."
ELSE DO
   'echo "New 'NewEmu68Version' version found, do you want to update your current 'OldEmu68Version' version? Y/N" NOLINE'
   Pull Response
   if upper(Response)='Y' | upper(Response)='YES' then do
      if ~EXISTS(Emu68FolderLocation||Emu68BackupFolderName) then DO
         SAY 'Creating backup folder at 'BackupFolderPath
         'MAKEDIR 'BackupFolderPath' >NIL:'
      END
      
      BackupFilePath = BackupFolderPath'/Emu68-'PistormVariant'_old'
    
      If Exists (BackupFilePath) then DO
         SAY "Deleting previous backup file"
         'delete 'BackupFilePath' FORCE QUIET >NIL:'
      end  
      say 'Copying file from: 'Emu68FilePath' to: 'BackupFilePath  
      'copy "'Emu68FilePath'" TO "'BackupFilePath'" FORCE CLONE QUIET >NIL:'
      say 'Copying file from: 'FilePathNewversion' to: 'Emu68FilePath
      'copy "'FilePathNewversion'" TO "'Emu68FilePath'" FORCE CLONE QUIET >NIL:'  
   end
END

'delete 'Emu68json_path' QUIET >NIL:'
'delete 'destination' QUIET >NIL:'
'delete 'Emu68TempFilesFolder' ALL QUIET >NIL:'

Say "Starting update processs for Videocore"

Call DownloadFile('Trying download from Github for Emu68-Tools file details.',Emu68ToolsGithubPathJSONURL,Emu68Toolsjson_path,3)

Emu68ToolsTagValue = ProcessJSONFile(Emu68Toolsjson_path)

SAY  'Downloading latest Emu68-Tools'PistormVariant' release...'
SAY ''

Emu68ToolsDownloadURL = Emu68ToolsGithubPathURL||'/download/'||Emu68ToolsTagValue||'/Emu68-Tools.zip'

Destination = 'T:Emu68-Tools.zip'

Call DownloadFile('Trying download from Github for Emu68 files',Emu68ToolsDownloadURL,Destination,3)

SAY "Download Complete"

call Unzip(Destination,Emu68ToolsTempFilesFolder) 

SAY "Files unzipped"

SAY "Starting VideoCore update process..."
SAY ""

FilePathVideocoreOldversion = 'LIBS:Picasso96/VideoCore.card' 
FilePathVideocoreNewversion = Emu68ToolsTempFilesFolder||'/VideoCore/VideoCore.card'

'version 'FilePathVideocoreOldversion' >T:VideocoreOldVersion.txt'
'version 'FilePathVideocoreNewversion' >T:VideoCoreNewVersion.txt'

if ~READFILE('T:VideocoreOldVersion.txt',OldVersionVideocoreLine) then Call CloseProgram("Error accessing version of Videocore!",10)
if ~READFILE('T:VideoCoreNewVersion.txt',NewVersionVideocoreLine) then Call CloseProgram("Error accessing version of Videcore!",10)

OldVideocoreVersion = OldVersionVideocoreLine.1
NewVideocoreVersion = NewVersionVideocoreLine.1

'delete T:VideocoreOldVersion.txt QUIET >NIL:'
'delete T:VideocoreNewVersion.txt QUIET >NIL:'

SAY 'Version on your Amiga: 'OldVideocoreVersion
SAY 'Version found online: 'NewVideocoreVersion

VideocoreUpdateNeeded = CheckUpdateNeeded(OldVideocoreVersion,NewVideocoreVersion) 
If VideocoreUpdateNeeded ="FALSE" then say "Your version of Videocore is up to date"

else do
   'echo "New 'NewVideocoreVersion' version found, do you want to update your current 'OldVideocoreVersion' version? Y/N " NOLINE'
   Pull Response
   if upper(Response)='Y' | upper(Response)='YES' then do
      If ~EXISTS('LIBS:Picasso96/'VideoCoreBackupFolderName) THEN DO
         say 'Creating backup folder at 'VideoCoreBackupFolderName
         'MAKEDIR LIBS:Picasso96/'VideoCoreBackupFolderName' >NIL:'
      END
      BackupFilePath = 'LIBS:Picasso96/'||VideoCoreBackupFolderName'/Videocore.card_old'
      If Exists (BackupFilePath) then do
         say "Deleting previous backup file"
         'delete 'BackupFilePath' FORCE QUIET >NIL:'
      end
      say 'Copying file from: 'FilePathVideocoreOldversion' to: 'BackupFilePath  
      'copy "'FilePathVideocoreOldversion'" TO "'BackupFilePath'" FORCE CLONE QUIET >NIL:'
      say 'Copying file from: 'FilePathVideocoreNewversion' to: 'FilePathVideocoreOldversion 
      'copy "'FilePathVideocoreNewversion'" TO "'FilePathVideocoreOldversion'" FORCE CLONE QUIET >NIL:'  
   end
   

   SAY "Identifying Monitor file for Videcore"
   
   if ~GETDIR('SYS:Devs/Monitors','~(#?.info)',ListofFiles,'FILES','PATH',) then Call CloseProgram("Error identifying monitor files",10)

   FoundCount = 0
   do i = 1 to ListofFiles.0
      If GetToolTypes(ListofFiles.i,VideocoreToolTypeLines) then DO
         Do j =1 to VideocoreToolTypeLines.0
            TooltipLine = upper(strip(VideocoreToolTypeLines.j))
            if TooltipLine="BOARDTYPE=VIDEOCORE" then DO
               FoundCount = FoundCount + 1
               say "Videocore found in: "ListofFiles.i
            END   
         END
      END
   end 

   Select
      WHEN FoundCount = 0 then exit
      WHEN FoundCount >1 THEN DO
         Say "More than one monitor file found for Videocore! Cannot check tooltypes!"
         UpdateToolType = "FALSE"
      END
      WHEN FoudCount = 1 then DO
         UpdateToolType = "TRUE"
         VideocoreFilePath = ListofFiles.i
      END
      OTHERWISE nop
   END

   If UpdateToolType = "TRUE" then do
      If ~GetToolTypes(VideocoreFilePath,VideocoreToolTypeLines) then Call CloseProgram('Could not open Videocore.card',10,3)
      LegacyIDFound="FALSE"
      do i=1 to VideocoreToolTypeLines.0
         if POS('VC4_LEGACY_ID',VideocoreToolTypeLines.i)>0 then Do
            LegacyIDFound="TRUE"
            Leave
         end
      end
      if LegacyIDFound="FALSE" then do
         'echo "VC4_LEGACY_ID tooltype not found! If you are using the sharware version of P96 (version 2.x) you will need to add this. Do you want to update the Tooltype Y/N " NOLINE'
         Pull Response
         if upper(Response)='Y' | upper(Response)='YES' then do
            SAY "Adding VC4_LEGACY_ID tooltype to Videocore.card"
            If ~SETTOOLTYPEVALUE(VideocoreFilePath,'VC4_LEGACY_ID','') then Call CloseProgram('Could not open Videocore.card',10,3)
         END
      END
   END

END

'delete 'Emu68Toolsjson_path' QUIET >NIL:'
'delete 'destination' QUIET >NIL:'
'delete 'Emu68ToolsTempFilesFolder' ALL QUIET >NIL:'

Call CloseProgram('Update process complete!',0,3)


EXIT
/* ================= FUNCTIONS ================= */

CloseProgram:
   Parse ARG Message, ExitNumber, TimetoClose
   Say Message
   Say 'This window will close in 'TimetoClose' seconds'
   'wait sec='TimetoClose 
   Exit ExitNumber
   Return
DownloadFile:
   Parse ARG Message,URL,DLLocation,NumberAttempts
   SAY ""
   Attempt = 1
   Do until IsDLed="TRUE"
      Say Message' Attempt number: 'Attempt 
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
   parse arg OldVersion,NewVersion

   parse var OldVersion vFieldThowAway OV_Major'.'OV_Minor'.'OV_Patch'.'OV_Build
   parse var NewVersion vFieldThrowAway NV_Major'.'NV_Minor'.'NV_Patch'.'NV_Build

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