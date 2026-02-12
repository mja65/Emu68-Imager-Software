/* $VER: Network.rexx 1.0 (2026-01-28)                                        */
/* Script to take Amiga online and offline including sync of clock            */
/*                                                                            */

/******************************************************************************
 *                                                                            *
 * REQUIREMENTS:                                                              *
 * - IP Stack:            Miami or Roadshow                                   *
 * - Devices:             genet.device or wifipi.device or                    *
 * - Libraries:           rexxtricks.library                                  *
 *                        uaenet.device(for UAE, built-in)                    *
 * - Tools (in C:):       SetDST, WirelessManager, WaitUntilConnected, sntp,  *
 *                        mecho,KillDev,ListDevices                           *
 * - Script (in S:):      ProgressBar                                         *
 *                                                                            *
 *****************************************************************************/

OPTIONS RESULTS

if ~SHOW('L','rexxtricks.library') then addlib('rexxtricks.library',0,-30,0) 

PARSE ARG input 
input = upper(TRANSLATE(input, ' ', '='))
PARSE VAR input . 'ACTION' action .
PARSE VAR input . 'DEVICE' device .
PARSE VAR input . 'IPSTACK' ipstack .

ipstack = STRIP(ipstack)
device  = STRIP(device)
action  = STRIP(action)

SwitchWaitatEnd = "FALSE"
IF POS('WAITATEND', input) > 0 THEN SwitchWaitatEnd = "TRUE"

IF action = "" | ipstack = "" THEN SIGNAL ShowUsage
IF action = "CONNECT" & device = "" THEN SIGNAL ShowUsage

IF FIND("CONNECT DISCONNECT",action) = 0 THEN DO
   SAY "Error: Invalid ACTION '"action"'. Must be Connect or Disconnect."
   CALL CloseWindowMessage()
   EXIT 10
END

SAY ""
SAY "**********************************************"
SAY ""
SAY "Running Network script for action: "action
SAY ""
SAY "**********************************************"

IF action = "CONNECT" then DO
   TZONE = GETENV(TZONE) 
   if TZONE="" THEN DO
      TimeZoneOverride = GETENV(TZONEOVERRIDE)
      if TimeZoneOverride~="" then DO
         say TimeZoneOverride 
         say "Using Timezone override"
         'C:SetDST ZONE='vTimeZoneOverride' NOASK NOREQ QUIET >NIL:'
      END
      ELSE 'C:SetDST NOASK NOREQ QUIET >NIL:'
   END    

END

/* Check IPStack */
IF action = "CONNECT" then DO
   IF FIND("ROADSHOW MIAMI",ipstack) = 0 THEN DO
      SAY "Error: Invalid IPSTACK '"ipstack"'. Must be Roadshow or Miami."
      CALL CloseWindowMessage()
      EXIT 10
   END
END

If ipstack = "ROADSHOW" then DO
   ADDRESS COMMAND
   say ""
   'roadshowcontrol >NIL:'
   IF RC = 20 then DO
      SAY ""
      SAY "Unable to access bsdsocket.library!"
      SAY "You may be running the demo version of Roadshow after the 15 minute"
      SAY "expiry. You will need to reboot your Amiga"
      CALL CloseWindowMessage()
      EXIT 10
   END
END

SwitchNoCloseWirelessManager = "FALSE"
SwitchNoSyncTime = "FALSE"
SwitchNoCloseMiami = "FALSE"
SwitchNoReStartMiami = "FALSE"
SwitchNoReStartWirelessManager = "FALSE"
SwitchNoShutDownRoadshow = "FALSE"

IF POS('NOCLOSEWIRELESSMANAGER', input) > 0 THEN SwitchNoCloseWirelessManager = "TRUE"
IF POS('NOSYNCTIME', input) > 0 THEN SwitchNoSyncTime = "TRUE"
IF POS('NOCLOSEMIAMI', input) > 0 THEN SwitchNoCloseMiami = "TRUE"
IF POS('NORESTARTMIAMI', input) > 0 THEN SwitchNoReStartMiami = "TRUE"
IF POS('NORESTARTWIRELESSMANAGER', input) > 0 THEN SwitchNoReStartWirelessManager = "TRUE"
IF POS('NOSHUTDOWNROADSHOW', input) > 0 THEN SwitchNoShutDownRoadshow = "TRUE"


IF device ~= "" & ~POS(".", device) > 0 THEN device = device || ".DEVICE"

IF action = "CONNECT" then DO
   DevicebaseName = left(device,(LENGTH(device) - 7))
   IF FIND("WIFIPI GENET UAENET",DevicebaseName) = 0 THEN DO
      SAY "Error: Unsupported DEVICE '"DevicebaseName"'. Supported: wifipi.device, genet.device, uaenet.device"
      CALL CloseWindowMessage()
      EXIT 10
   END
END

DEBUG = "FALSE"
IF POS('DEBUG', input) > 0 THEN DEBUG = "TRUE"

ADDRESS COMMAND

If IPStack = "ROADSHOW" then DO
   IF ~IsRoadshowInstalled() THEN DO
       CALL CloseWindowMessage()
      EXIT 10
   END
END
If IPStack = "MIAMI" then DO
   IF ~IsMiamiInstalled() THEN DO
      CALL CloseWindowMessage()
      EXIT 10
   END
END

WirelessprefsPath = "SYS:Prefs/Env-Archive/sys/wireless.prefs"
WifiPiDevicePath   = "Sys:Devs/Networks/wifipi.device"
WirelesslogFilePath   = "RAM:wirelessmanagerlog.txt"
sntpLog = "RAM:sntplog.txt"
RoadshowParametersFile = "Sys:Pistorm/RoadshowParameters"

IF DEBUG = "TRUE" then DO
   SAY "Debug mode on"
   SAY "IPStack: "ipstack
   SAY "Action: "action
   SAY "Device: "device
   SAY "DevicebaseName: "DevicebaseName
   SAY "SwitchNoRestartMiami: "SwitchNoRestartMiami 
   SAY "SwitchNoReStartWirelessManager: "SwitchNoReStartWirelessManager
   SAY "SwitchNoCloseMiami: "SwitchNoCloseMiami 
   SAY "SwitchNoSyncTime: "SwitchNoSyncTime 
   SAY "SwitchNoCloseWirelessManager: "SwitchNoCloseWirelessManager
   SAY "SwitchWaitatEnd: "SwitchWaitatEnd
   SAY "SwitchNoShutDownRoadshow "SwitchNoShutDownRoadshow
   SAY "WirelessprefsPath: "WirelessprefsPath
   SAY "WifiPiDevicePath: "WifiPiDevicePath
   SAY "WirelesslogFilePath: "WirelesslogFilePath
   SAY "sntpLog: "sntplog
   SAY "RoadshowParametersFile: "RoadshowParametersFile
END


IF action = "CONNECT" then DO
   If IPStack = "MIAMI" then DO
      CALL KillNetworkShares()
      CALL KillMiami()
   END
   If IPStack = "ROADSHOW" then DO  
      IF SwitchNoShutDownRoadshow = "FALSE" then DO 
         CALL KillNetworkShares()
         CALL KillRoadshow()
      END
      ELSE DO
         'areweonline'
         If RC = 0 then DO
            CALL KillNetworkShares()
            CALL KillRoadshow()
         END
      END
   END
   IF device = "WIFIPI.DEVICE" THEN DO
      SAY ""
      SAY "Connecting to Wifi Network"
      
      IF ~EXISTS(WirelessprefsPath) THEN DO
         SAY ""
         SAY "Cannot connect to Wifi! No Wireless.prefs file found!"
         SAY "You need to create a wireless.prefs file at ""SYS:Prefs/Env-Archive/sys"""
         CALL CloseWindowMessage()
         EXIT 10
      END
     
      IF OPEN('f',WirelessprefsPath,'R') then DO
         Do until EOF('f')
            LineRead = Upper(STRIP(READLN('f')))
            IF POS('SSID=',LineRead) > 0 THEN DO
               parse var LineRead v1'SSID="'vSSID'"'
               if vSSID="" then DO
                  SAY "No SSID found in ""SYS:Prefs/Env-Archive/sys/wireless.prefs""! You need to configure!"
                  CALL CloseWindowMessage()
                  EXIT 10
               END
               ELSE DO
                  IF DEBUG="TRUE" then SAY "SSID found was: "vSSID
                  LEAVE
               END        
            END
         END
      END      
      
       
      IF SwitchNoReStartWirelessManager = "FALSE" then DO
         If ~KillWirelessManager() then DO
            CALL CloseWindowMessage()
            EXIT 10
         END      
      END
      ELSE DO
        'Status COM=c:wirelessmanager >T:WirelessManagerStatus'
         IF EXISTS('T:WirelessManagerStatus') THEN DO
            IF OPEN('f','T:WirelessManagerStatus','R') then DO
               IF ~EOF('f') then DO
                  WirelessManagerPID = STRIP(READLN('f'))
                  CALL CLOSE ('f')
                  WirelessManagerActive = "FALSE"
                  IF DATATYPE(WirelessManagerPID,'W') then WirelessManagerActive = "TRUE"
               END
            END
         END
      END
      IF WirelessManagerActive ~="TRUE" | SwitchNoReStartWirelessManager = "FALSE" then DO
         SAY ""
         SAY "Connecting to Wireless. This may take a few moments......."
         SAY ""
         'setenv InProgressBar 1'
         'run >T:Progressbar.txt S:ProgressBar'
         'Run >NIL: C:wirelessmanager device='WifiPiDevicePath' CONFIG='WirelessprefsPath' VERBOSE >'WirelesslogFilePath
         'C:WaitUntilConnected device='WifiPiDevicePath' Unit=0 delay=100'
         If RC = 0 then DO
            SAY ""
            'unsetenv InProgressBar'
            'delete T:Progressbar.txt >NIL: QUIET'
         END
         ELSE DO
            SAY ""
            SAY "Could not connect to Wifi!"
            'unsetenv InProgressBar'
            'delete T:Progressbar.txt >NIL: QUIET'
            If ~KillWirelessManager() then DO
               CALL CloseWindowMessage()
               EXIT 10
            END         
            EXIT 10
         END
      END
   END
   IF device = "GENET.DEVICE" THEN DO
      SAY ""
      SAY "Connecting to Ethernet"
      If RPIVersion() ~= "RPi4" then DO
         SAY ""
         Say "Genet.device only works on Pistorm with Raspberry Pi4 or CM4! Aborting!"
         CALL CloseWindowMessage()
         EXIT 10
      END
      If ~KillWirelessManager() then DO
         CALL CloseWindowMessage()
         EXIT 10
      END   
   END
   IF device = "UAENET.DEVICE" THEN DO
      SAY ""
      SAY "Connecting to Network in UAE (uaenet.device)"
      if ~IsUAE() THEN DO
         CALL CloseWindowMessage()
         EXIT 10
      END
   END

   IF ipstack = "ROADSHOW" THEN DO
      CALL LoadRoadshowParams(DevicebaseName)
      'setenv InProgressBar 1'
      'run >T:Progressbar.txt S:ProgressBar'
      'AddNetInterface 'DevicebaseName' TIMEOUT=50 >T:AddInterface.txt'
      'Search T:AddInterface.txt "Could not add" >NIL:'
      IF RC = 0 THEN DO
         SAY ""
         SAY "Error connecting to Roadshow"
         'unsetenv InProgressBar'
         'delete T:Progressbar.txt >NIL: QUIET'
         If ~KillWirelessManager() then DO
            CALL CloseWindowMessage()
            EXIT 10
         END         
         EXIT 10
      END
      ELSE DO
         SAY ""
         'unsetenv InProgressBar'
         'delete T:Progressbar.txt >NIL: QUIET'
      END
   END

   IF ipstack = "MIAMI" THEN DO
      MiamiConfigFile = "Miami:" || DevicebaseName || ".default"
      IF ~EXISTS(MiamiConfigFile) THEN DO
         SAY ""
         SAY "Configuration file" MiamiConfigFile "does not exist!"
         If ~KillWirelessManager() then DO
            CALL CloseWindowMessage()
            EXIT 10
         END
         CALL CloseWindowMessage()         
         EXIT 10
      END   
      IF ~IsMiamiInstalled() THEN DO
         If ~KillWirelessManager() then DO
            CALL CloseWindowMessage()
            EXIT 10
         END
         CALL CloseWindowMessage()
         EXIT 10
      END
      
      
      IF ~show('p', 'MIAMI.1') then DO
         IF DEBUG="TRUE" then DO
            SAY ""
            SAY "Miami not running"
         END
         'run <>nil: Miami:miamidx 'MiamiConfigFile
      END
      ELSE DO
         IF SwitchNoRestartMiami="FALSE" then DO   
            SAY ""
            Say "Miami already running.Quitting."
            ADDRESS 'MIAMI.1'
            QUIT
            ADDRESS COMMAND
            'wait sec=2'
            'run <>nil: Miami:miamidx 'MiamiConfigFile
         END
         ELSE DO
            ADDRESS 'MIAMI.1'
            LOADSETTINGS MiamiConfigFile
         END
      END
         
      'WaitForPort MIAMI.1'
      ADDRESS 'MIAMI.1'

      DO i=1 to 3
         'Online'
         'ISONLINE'
         if RC=0 then Say "Attempt number "i "to go online failed"
         ELSE LEAVE
      END
      
      if RC=1 then hide
      ELSE DO
         SAY "" 
         Say "All attempts to go online failed!"
         If ~KillWirelessManager() then DO
            CALL CloseWindowMessage()
            EXIT 10
         END
         CALL CloseWindowMessage()
         exit 10
      END
      ADDRESS COMMAND 
   END
   if SwitchNoSyncTime = "FALSE" then DO
      SAY ""
      SAY "Updating system time"
      'c:sntp pool.ntp.org >'sntpLog
      'Search' sntpLog '"Unknown host" >NIL:'
      IF RC = 0 THEN DO
         SAY "Unable to synchronise time"
         'Delete' sntpLog 'QUIET'
         CALL CloseWindowMessage()
         EXIT 5
      END
      ELSE DO
         'Delete' sntpLog 'QUIET'
      END 
      SAY "Time set and DST applied if applicable"
   END
   IF ipstack = "ROADSHOW" THEN DO
      SAY ""
      say "Successfully connected to Network!" 
      SAY ""
      'shownetstatus'
   END
END

IF action = "DISCONNECT" then DO
   SAY ""
   Say "Disconnecting Network"
   SAY ""
   SAY "Killing network shares"
   CALL KillNetworkShares()
   If ipstack = "ROADSHOW" THEN CALL KillRoadshow()
   IF ipstack = "MIAMI" THEN DO
      IF ~SHOW('P', 'MIAMI.1') THEN DO
         SAY ""
         SAY "Miami is already closed and offline!"
      END
      ELSE DO
         ADDRESS 'MIAMI.1'
         'ISONLINE'
         IF RC = 0 THEN DO
            ADDRESS COMMAND
            SAY ""
            SAY "Miami is already offline!"
         END
         ELSE DO
            'OFFLINE'
            'ISONLINE'
            IF RC = 1 THEN DO
               ADDRESS COMMAND
               SAY ""
               SAY "Couldn't get Miami offline!"
            END
            ELSE DO
               If DEBUG = "TRUE" then DO
                  SAY ""
                  SAY "Miami is now offline"
               END
               If SwitchNoCloseMiami = "FALSE" then DO                  
                  CALL KillMiami()
                  If DEBUG = "TRUE" then DO
                     SAY ""
                     SAY "Miami is now closed"
                  END
               END
               ADDRESS COMMAND               
            END
         END
      END
   END
   IF device = "WIFIPI.DEVICE" & SwitchNoCloseWirelessManager = "FALSE" THEN DO
      If ~KillWirelessManager() then DO
         CALL CloseWindowMessage()
         EXIT 10
      END
   END

END

Call CloseWindowMessage()

EXIT 0

/* ================= FUNCTIONS ================= */

IsMiamiInstalled:
   'assign exists Miami: >NIL:'
   IF RC >= 5 then DO
      SAY "Miami not installed!"
      RETURN 0
   END
   ELSE DO
      IF EXISTS('Libs:bsdsocket.library') THEN DO
         SAY ""
         Say "Miami installed but existing bsdsocket.library!"
         CALL CloseWindowMessage()
         EXIT 10
      END
      RETURN 1
   END
IsUAE:
   'VERSION uaehf.device'
   If RC >0 THEN DO
      If debug = "TRUE" THEN DO
         SAY "UAE not detected"
      END   
      RETURN 1
   END
   ELSE DO
      If debug = "TRUE" THEN DO
         SAY "UAE detected"
      END
      RETURN 0
   END
IsRoadshowInstalled:
   IF EXISTS('Libs:bsdsocket.library') THEN DO
      IF DEBUG ="TRUE" then SAY "Roadshow installed"
      RETURN 1
   END
   ELSE DO
      IF DEBUG ="TRUE" then DO
         SAY "Roadshow not installed"
      END
      RETURN 0
   END
   

KillRoadshow:
   'c:Netshutdown >NIL:'
   Return
KillMiami:
   IF SHOW('P', 'MIAMI.1') THEN DO
      ADDRESS 'MIAMI.1'
      QUIT
      ADDRESS COMMAND
   END
   Return
   
KillNetworkShares:
   'c:ListDevices device_name=L:smb-handler,L:smb2-handler NOFORMATTABLE >T:NetworkShares.txt'
   IF OPEN('f','T:NetworkShares.txt','R') then DO
      DO while ~EOF('f')  
      Line = STRIP(READLN('f'))
      If line = "" then iterate
      parse var Line vDevice';'vRawDosType';'vDosType';'vDeviceName';'vUnit';'vVolume
      vCmd = 'c:killdev 'vDevice
      IF DEBUG="TRUE" then DO
         say "Running command: "vCmd
      END 
      vCmd
      END
   END
   call close('f')
   'delete T:NetworkShares.txt QUIET >NIL:'
   RETURN   
KillWirelessManager:
   'Status COM=c:wirelessmanager >T:WirelessManagerStatus'
   IF EXISTS('T:WirelessManagerStatus') THEN DO
      IF OPEN('f','T:WirelessManagerStatus','R') then DO
         IF ~EOF('f') then DO
            WirelessManagerPID = STRIP(READLN('f'))
            CALL CLOSE ('f')
            IF DATATYPE(WirelessManagerPID,'W') then DO
               SAY ""
               Say "Quitting Wireless Manager"
               'break' WirelessManagerPID
               'wait sec=2'
            END
            ELSE DO
               IF DEBUG="TRUE" then DO
                  SAY ""
                  SAY "Wireless Manager not already running"
               END
            END
         END
         ELSE DO
            IF DEBUG="TRUE" then DO
               SAY ""
               SAY "Wireless Manager not already running"
            END
         END
      END
      'Delete T:WirelessManagerStatus >NIL: QUIET'
      RETURN 1
   END
   ELSE DO
      SAY ""
      SAY "Error running check of WirelessManager!"
      RETURN 0
   END

RpiVersion:
   RpiType = GETENV(rpitype)
   if RpiType~="" THEN RETURN RpiType
   'VERSION brcm-emmc.device >nil:'
   if RC=0 then RETURN 'RPi4'
   'version brcm-sdhc.device >NIL:'
   if RC=0 then RETURN 'RPi3'
   Return "Unknown"
LoadRoadshowParams:
   PARSE ARG targetDevice
   if ~READFILE(RoadshowParametersFile,ReadLines) then RETURN
   do i=1 to Readlines.0
   IF Readlines.i = "" | LEFT(Readlines.i, 1) = ";" THEN iterate
     parse var Readlines.i vType';'vParameter';'vValue
     if upper(vType) ~= targetDevice then iterate
     SELECT
        WHEN upper(vParameter) = "TCPRECEIVE" THEN vCmd = 'roadshowcontrol tcp.recvspace='vValue' >NIL:'
        WHEN upper(vParameter)= "UDPRECEIVE" THEN vCmd = 'roadshowcontrol udp.recvspace='vValue' >NIL:'
        WHEN upper(vParameter) = "TCPSEND" THEN vCmd = 'roadshowcontrol tcp.sendspace='vValue' >NIL:'
        WHEN upper(vParameter) = "UDPSEND" THEN vCmd = 'roadshowcontrol udp.sendspace='vValue' >NIL:'
        OTHERWISE nop
     end
     if DEBUG="TRUE" then SAY vCmd
     vCmd
   end
   RETURN
CloseWindowMessage:
   If SwitchWaitatEnd="TRUE" then DO
      SAY ""
      say "Window will close in 3 seconds"
      ADDRESS COMMAND
      'wait sec=3'
      EXIT
   END
   Return

ShowUsage:
   SAY ""
   SAY "Arexx program to connect to network using via Miami or Roadshow and to synchronise time"
   SAY ""
   SAY "Usage: Rx Network.rexx ACTION=<Action Type> DEVICE=<Selected Device> IPSTACK=<IP Stack> <Options>"
   SAY "<Action Type>: Connect, Disconnect"
   SAY "<Selected Device>: WifiPi, Genet, Uaenet (applicable for Connect action type)"
   SAY "<IP Stack>: Miami, Roadshow"
   SAY "<Options>: NoSyncTime, NoRestartMiami, NoRestartWirelessManager, NoShutdownRoadshow (applicable for connect action type)"
   SAY "<Options>: NoCloseWirelessManager, NoCloseMiami (applicable for disconnect action type)"
   SAY "<Options>: Debug, WaitatEnd"
   SAY ""
   SAY "Example Usage: "
   SAY "Connect to wifipi.device using MiamiDX"
   SAY "Rx Network.rexx ACTION=Connect DEVICE=wifipi IPSTACK=Miami"
   SAY ""
   SAY "Disconnect from network running via Miami"
   SAY "Rx Network.rexx ACTION=Disconnect IPSTACK=Miami" 
   SAY ""
   
   CALL CloseWindowMessage()
   EXIT 10
