/* ParseEmu68Boot.rexx                *
*                                     *
* ARexx Parser for Emu68BOOT Device   *
*                                     */

DosListPath = 'sys:Pistorm/Emu68UpdaterFiles/Doslist'
Drivername1 = 'brcm-emmc.device'
Drivername2 = 'brcm-sdhc.device'
TargetDostype = '46415401'

filename = "T:DriveInfo.txt"
filename2 = "T:Emu68FilesLocation.txt"

address command DosListPath' devs >' filename

if ~open(inf, filename, 'R') then DO
   SAY "Error accessing list of drives!"
   exit 10
end

active = 0
found_count = 0
first_device = ""

do while ~eof(inf)
    line = readln(inf)
    
    select
        when pos('Device: "', line) > 0 then do
           parse var line 'Device: "' device '"' .
            dname = ""
            unit = ""
            active = 1 
        end

        when pos('No environment vector', line) > 0 then active = 0

        when active & pos('Device name is "', line) > 0 then do
            parse var line 'is "' dname '", unit is ' unit ', flags' .
            unit = strip(strip(unit), 'T', ',')
        end

        when active & pos('DosType is', line) > 0 then do
            parse var line 'is ' dtype
            /* Clean the parsed DosType: remove $ and spaces */
            dtype = strip(dtype)
            if LEFT(dtype, 1) = "$" then dtype = SUBSTR(dtype, 2)

            /* Match against Driver, Unit 0, and DosType */
            if (upper(dname) = upper(Drivername1) | upper(dname) = upper(Drivername2)) & unit = "0" & dtype = TargetDostype then do
                found_count = found_count + 1
                if found_count = 1 then first_device = device':'
            end
            active = 0
        end
        otherwise nop
    end
end

close(inf)


ADDRESS COMMAND 'delete 'filename' QUIET >NIL:' 

If found_count = 0 then DO
   SAY "No device found!"
   EXIT 10
end

ADDRESS COMMAND 'list all files 'first_device' Pat=(Emu68-pistorm#?) Lformat="%p" >'filename2


if ~open(inf, filename2, 'R') then DO
   SAY "Cannot open list of files!"
   exit 10
END

unique_count = 0
count. = 0
captured_line = ""

do while ~eof(inf)
    line = readln(inf)
    if line = "" & eof(inf) then iterate
    if count.line = 0 then do
       captured_line = line
       unique_count = unique_count + 1
    end
    
    /* Increment the count for this specific group */
    count.line = count.line + 1
end

close(inf)

ADDRESS COMMAND 'delete 'filename' QUIET >NIL:' 

if unique_count > 1 then DO
   SAY "Multiple locations for Emu68 files!"
   EXIT 10
END
if unique_count = 0 then DO
  say "File was empty."
  EXIT 10
end

Emu68FilePath = captured_line

ADDRESS COMMAND 'SETENV EMU68FilePath 'Emu68FilePath

If found_count~=1 then DO
   Say "Multiple FAT32 partitions found. Using first one"
   EXIT 5
END 


EXIT 0