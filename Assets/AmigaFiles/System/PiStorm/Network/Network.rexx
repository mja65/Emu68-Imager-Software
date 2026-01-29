/* $VER: Network.rexx 1.0 (2026-01-28)                                        */
/* Script to take Amiga online and offline including sync of clock            */
/*                                                                            */

/******************************************************************************
 *                                                                            *
 * REQUIREMENTS:                                                              *
 * - IP Stack:       Miami or Roadshow                                        *
 * - Devices:        genet.device or wifipi.device or                         *
 *                   uaenet.device(for UAE, built-in)                         *
 * - Tools (in C:):  SetDST, WirelessManager, WaitUntilConnected, sntp, mecho,* 
 *                    KillDev                                                 *
 * - Script (in S:): ProgressBar                                              *
 *                                                                            *
 ******************************************************************************/

OPTIONS RESULTS

PARSE ARG input 
input = upper(TRANSLATE(input, ' ', '='))
PARSE VAR input . 'ACTION' action .
PARSE VAR input . 'DEVICE' device .
PARSE VAR input . 'IPSTACK' ipstack .

ipstack = STRIP(ipstack)
device  = STRIP(device)
action  = STRIP(action)

IF POS('WAITATEND', input) > 0 THEN DO
   SwitchWaitatEnd = "TRUE"
END
ELSE DO
   SwitchWaitatEnd = "FALSE"
END


IF action = "" | ipstack = "" THEN DO 
   SIGNAL ShowUsage
END
IF action = "CONNECT" & device = "" THEN DO 
   SIGNAL ShowUsage
END

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


IF POS('NOCLOSEWIRELESSMANAGER', input) > 0 THEN DO
   SwitchNoCloseWirelessManager = "TRUE"
END
ELSE DO
   SwitchNoCloseWirelessManager = "FALSE"
END

IF POS('NOSYNCTIME', input) > 0 THEN DO
   SwitchNoSyncTime = "TRUE"
END
ELSE DO
   SwitchNoSyncTime = "FALSE"
END

IF POS('NOCLOSEMIAMI', input) > 0 THEN DO
   SwitchNoCloseMiami = "TRUE"
END
ELSE DO
   SwitchNoCloseMiami = "FALSE"
END

IF POS('NOSTARTMIAMI', input) > 0 THEN DO
   SwitchNoStartMiami = "TRUE"
END
ELSE DO
   SwitchNoStartMiami = "FALSE"
END


IF device ~= "" & ~POS(".", device) > 0 THEN DO
   device = device || ".DEVICE"
END


IF action = "CONNECT" then DO
   DevicebaseName = left(device,(LENGTH(device) - 7))
   IF FIND("WIFIPI GENET UAENET",DevicebaseName) = 0 THEN DO
      SAY "Error: Unsupported DEVICE '"DevicebaseName"'. Supported: wifipi.device, genet.device, uaenet.device"
      CALL CloseWindowMessage()
      EXIT 10
   END
END

IF POS('DEBUG', input) > 0 THEN DO
   DEBUG = "TRUE"
END
ELSE DO
   DEBUG = "FALSE"
END

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
   SAY "SwitchNoStartMiami: "SwitchNoStartMiami 
   SAY "SwitchNoCloseMiami: "SwitchNoCloseMiami 
   SAY "SwitchNoSyncTime: "SwitchNoSyncTime 
   SAY "SwitchNoCloseWirelessManager: "SwitchNoCloseWirelessManager
   SAY "SwitchWaitatEnd: "SwitchWaitatEnd   
   SAY "WirelessprefsPath: "WirelessprefsPath
   SAY "WifiPiDevicePath: "WifiPiDevicePath
   SAY "WirelesslogFilePath: "WirelesslogFilePath
   SAY "sntpLog: "sntplog
   SAY "RoadshowParametersFile: "RoadshowParametersFile
END


IF action = "CONNECT" then DO
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
      If ~KillWirelessManager() then DO
          CALL CloseWindowMessage()
         EXIT 10
      END
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
   IF device = "GENET.DEVICE" THEN DO
      SAY ""
      SAY "Connecting to Ethernet"
      If RPIVersion() ~= "Pi4" then DO
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
   IF device = "USENET.DEVICE" THEN DO
      SAY ""
      SAY "Connecting to Network in UAE (uaenet.device)"
      if ~IsUAE() THEN DO
         CALL CloseWindowMessage()
         EXIT 10
      END
   END

   IF ipstack = "ROADSHOW" THEN DO
      if LoadRoadshowParams(DevicebaseName) THEN DO
         'roadshowcontrol tcp.recvspace='TCPReceive' >NIL:'
         'roadshowcontrol udp.recvspace='UDPReceive' >NIL:'
         'roadshowcontrol tcp.sendspace='TCPSend' >NIL:'
         'roadshowcontrol udp.sendspace='UDPSend' >NIL:'
      END
      ELSE DO
         IF DEBUG="TRUE" then DO
            SAY ""
            SAY "No Roadshow Parameters found"
         END
      END
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
         IF SwitchNoStartMiami="FALSE" then DO   
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
         if RC=0 then DO
            Say "Attempt number "i "to go online failed"
         end
         ELSE DO
            LEAVE
         END
      END
      
      if RC=1 then DO 
         hide
      END
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
      IF EXISTS("SYS:Prefs/ENV-ARCHIVE/TZONEOVERRIDE") THEN DO
         'SYS:Rexxc/rx "push `getenv TZONEOVERRIDE`"'
         pull vTimeZoneOverride
      END
      IF vTimeZoneOverride ~= "VTIMEZONEOVERRIDE" THEN DO
      say vTimeZoneOverride 
      say "should not be here"
         'C:SetDST ZONE='vTimeZoneOverride
      END
      ELSE DO
         'C:SetDST NOASK NOREQ QUIET >NIL:'
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
   IF EXISTS('C:KillDev') THEN DO
      'killdev DOSDEV=SMB0 >NIL:'
   END
   If ipstack = "ROADSHOW" THEN DO
      'c:Netshutdown'
   END
   IF ipstack = "MIAMI" THEN DO
      IF ~IsMiamiInstalled() THEN DO
         SAY ""
         Say "Miami not installed! Cannot take it offline!"
      END
      ELSE DO
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
                     'QUIT'
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
      IF DEBUG ="TRUE" then DO 
         SAY "Roadshow installed"
      END
      RETURN 1
   END
   ELSE DO
      IF DEBUG ="TRUE" then DO
         SAY "Roadshow not installed"
      END
      RETURN 0
   END
   

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
   'VERSION brcm-emmc.device >nil:'
   if RC=0 then DO
      Return "Pi4"
   END
   'version brcm-sdhc.device >NIL:'
   If RC=0 then DO
      Return "Pi3"
   END
   ELSE DO 
      SAY ""
      say "You are not running a PiStorm!"
      Return "Unknown"
   END
LoadRoadshowParams:
   PARSE ARG targetDevice
   IF ~EXISTS(RoadshowParametersFile) THEN RETURN 0
   
   IF OPEN('pf', RoadshowParametersFile, 'READ') THEN DO
      DO UNTIL EOF('pf')
         line = READLN('pf')
         IF line ~= "" THEN DO
            PARSE VAR line vType ';' vName ';' vVal
            /* Match and assign to the caller's scope */
            IF UPPER(vType) = UPPER(targetDevice) THEN DO
               INTERPRET vName '= vVal'
            END
         END
      END
      CALL CLOSE('pf')
      RETURN 1
   END
   RETURN 0

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
   SAY "<Options>: NoSyncTime, NoStartMiami (applicable for connect action type)"
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