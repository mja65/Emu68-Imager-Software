/* $VER: SyncTime.rexx 1.1 (2026-08-17)                                    */
/* Wait for any configured TCP/IP stack, then synchronise clock and RTC.    */

OPTIONS RESULTS
ADDRESS COMMAND

sntpLog = 'RAM:NetworkTimeSync.log'

/* Mandatory tools are copied during image creation, but wait rather than
   silently reporting success if an incomplete installation is booted. */
DO WHILE ~EXISTS('C:sntp')
   'Echo "Waiting for C:sntp" >'sntpLog
   'Wait 5'
END

/* SNTP itself is the readiness test. AreWeOnline depends on one unrelated
   HTTP host and can remain false even when the TCP/IP stack and DNS work. */
CALL SynchroniseClock

/* SetDST establishes TZONE and daylight-saving state. Synchronise once more
   afterwards because sntp uses TZONE/locale when setting the Amiga clock. */
IF EXISTS('C:SetDST') THEN DO
   'C:SetDST NOASK NOREQ QUIET >NIL:'
   CALL SynchroniseClock
END

EXIT 0

SynchroniseClock:
DO FOREVER
   'C:sntp pool.ntp.org >'sntpLog
   /* UHCTools sntp can return warnings after changing a very inaccurate
      clock. Its documented success output is the reliable completion test. */
   'Search' sntpLog '"Correction applied to system time" >NIL:'
   IF RC = 0 THEN RETURN 1
   'Wait 10'
END
