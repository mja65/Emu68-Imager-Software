/*****************************************************************
**                                                              **
**  CheckScreenModeandChipset.Rexx                              **
**                                                              **
******************************************************************/

  /* Add the library functions */
CALL AddLib("/libs/rexxidentify.library",0,-30,0)
IF Word(ID_Release(),1)<5 THEN DO
  SAY "This script requires at least rexxidentify.library release 5!"
  EXIT
END

vChipset=ID_Hardware("CHIPSET",NOLOCALE)
vDefaultScreenMode = 0

address command 'SYS:Rexxc/rx "push `getenv ScreenModeChipset`"'
pull vScreenModeChipset

say vChipset "Amiga detected"
say "Chipset of required screenmode is:" vScreenModeChipset


Select
    when vChipset = "OCS" then do
        if vScreenModeChipset~="OCS" & vScreenModeChipset~="RTG" then do
            say "You are running on an OCS machine and selected a non-OCS screenmode! Reverting to default screenmode!"
            vDefaultScreenMode = 1
        end
    end
    when vChipset = "ECS" then do
        if vScreenModeChipset~="OCS" & vScreenModeChipset~="ECS" & vScreenModeChipset~="RTG" then do
            say "You are running on an ECS machine and selected a non-ECS screenmode! Reverting to default screenmode!"
            vDefaultScreenMode = 1        
        end
    end
    otherwise nop
end   


IF vDefaultScreenMode = 1 THEN DO
    SAY "Reverting Screenmode Preferences to default"
end
else do    
    SAY "Setting up user defined screenmode"

    ADDRESS COMMAND

    'Sys:Prefs/ScreenMode FROM Sys:Prefs/Env-Archive/sys/screenmode.prefs.User USE >NIL:'
    'DELETE >NIL: SYS:PREFS/Env-Archive/Sys/Screenmode.prefs'
    'RENAME from SYS:PREFS/Env-Archive/Sys/Screenmode.prefs.user to SYS:PREFS/Env-Archive/Sys/Screenmode.prefs'

END

EXIT 0
