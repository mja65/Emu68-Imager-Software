/* ARexx Script: Semantic Version Comparator (Return Codes) */
/* Compares Arg1 (Installed) vs Arg2 (Candidate) */
/* RETURNS: */
/*   0 = Update Needed (Arg2 > Arg1) */
/*   5 = No Update Needed (Arg2 <= Arg1) */
/*  20 = Error (Bad arguments) */

/* Read all arguments into a single string variable */
parse arg AllArgs

/* 
   CLEANUP INPUT:
   Use COMPRESS to remove ALL double quotes (") from the input string.
   This transforms: "VideoCore 1.2.0" "VideoCore 1.2.1"
   Into:             VideoCore 1.2.0  VideoCore 1.2.1
*/
CleanArgs = COMPRESS(AllArgs, '"')

/* Check if we have enough data (at least 4 words) */
if WORDS(CleanArgs) < 4 then do
    say "Error: Missing arguments or wrong format."
    exit 20
end

/* 
   EXTRACT WORDS BY POSITION:
   Word 2: Old Version (Installed)
   Word 4: New Version (Candidate)
   (Word 1 and 3 are the Names, which we ignore for comparison now)
*/
OldVerStr = WORD(CleanArgs, 2)
NewVerStr = WORD(CleanArgs, 4)

/* 
   PARSE: Split version strings into 4 parts (Major.Minor.Patch.Build). 
*/
parse var OldVerStr OV_Major'.'OV_Minor'.'OV_Patch'.'OV_Build
parse var NewVerStr NV_Major'.'NV_Minor'.'NV_Patch'.'NV_Build

/* 
   NORMALIZATION:
   Convert empty parts to 0 for correct mathematical comparison.
*/
if OV_Major = "" then OV_Major = 0; if NV_Major = "" then NV_Major = 0
if OV_Minor = "" then OV_Minor = 0; if NV_Minor = "" then NV_Minor = 0
if OV_Patch = "" then OV_Patch = 0; if NV_Patch = "" then NV_Patch = 0
if OV_Build = "" then OV_Build = 0; if NV_Build = "" then NV_Build = 0

/* 
   COMPARISON LOGIC
*/

/* 1. CHECK FOR EQUALITY */
if (NV_Major = OV_Major) & (NV_Minor = OV_Minor) & (NV_Patch = OV_Patch) & (NV_Build = OV_Build) then do
    /* Same version -> No update needed */
    exit 5
end

/* 2. CHECK IF NEWER (Arg2 > Arg1) */
Arg2IsNewer = 0

if NV_Major > OV_Major then Arg2IsNewer = 1
else if NV_Major = OV_Major then do
    if NV_Minor > OV_Minor then Arg2IsNewer = 1
    else if NV_Minor = OV_Minor then do
        if NV_Patch > OV_Patch then Arg2IsNewer = 1
        else if NV_Patch = OV_Patch then do
            if NV_Build > OV_Build then Arg2IsNewer = 1
        end
    end
end

/* 3. RETURN RESULTS */
if Arg2IsNewer = 1 then do
    /* Update Needed */
    exit 0
end
else do
    /* Candidate is older than installed -> No update needed */
    exit 5
end