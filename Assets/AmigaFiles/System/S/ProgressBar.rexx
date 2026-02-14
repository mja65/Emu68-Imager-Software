/* */


if ~SHOW('L','rexxtricks.library') then addlib('rexxtricks.library',0,-30,0) 

InProgressStatus = GETENV(InProgressBar)
Task = InProgressStatus
if InProgressStatus = "" then exit

address command

Do until InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR"
   InProgressStatus = upper(GETENV(InProgressBar))
   'mecho -e  "Performing task: 'Task' [ ...           ]" \r'
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
   'mecho -e  "Performing task: 'Task' [   ...         ]" \r'
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
   'mecho -e  "Performing task: 'Task' [     ...       ]" \r'
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
   'mecho -e  "Performing task: 'Task' [       ...     ]" \r'
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
   'mecho -e  "Performing task: 'Task' [         ...   ]" \r'  
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
   'mecho -e  "Performing task: 'Task' [           ... ]" \r'  
   'wait 1'
   InProgressStatus = upper(GETENV(InProgressBar))
   if InProgressStatus = "COMPLETE" | InProgressStatus = "ERROR" then leave
END
if InProgressStatus="ERROR" then 'mecho -e  " 'Task' -   ERROR!                                                      " \r\n' 
if InProgressStatus="COMPLETE" then 'mecho -e  " 'Task' -   Completed!                                                   " \r\n'
'unsetenv InprogressBar'
say ""
EXIT

