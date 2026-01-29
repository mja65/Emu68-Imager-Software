/* ExtractTag.rexx */
/* Robust ARexx script to extract the first 'tag_name' value */
/* from a non-draft, non-prerelease entry in RAM:releases.json */

/* Define the path to the JSON file */
json_path = 'RAM:releases.json'

/* Open the file */
IF ~OPEN(inputfile, json_path, 'R') THEN DO
    SAY 'Could not open' json_path
    EXIT 10
END

/* Initialize variable to hold the result */
tag_value = ""
target_key = '"tag_name":'

/* Define the required conditions for a valid release */
required_draft_status = '"draft":false'
required_prerelease_status = '"prerelease":false'

/* Read through file line by line */
DO WHILE ~EOF(inputfile)
    line = READLN(inputfile)
    
    /* 
     * Look for a line that represents a valid, final release.
     * It must contain the tag_name, and also have 'draft' and 'prerelease' set to false.
     */
    IF POS(target_key, line) > 0 & ,
       POS(required_draft_status, line) > 0 & ,
       POS(required_prerelease_status, line) > 0 THEN DO
        
        /* Found a line with a valid release. Now, extract the tag_name value. */
        key_pos = POS(target_key, line)
        
        /* 1. Get the substring starting after the key */
        value_part = SUBSTR(line, key_pos + LENGTH(target_key))
        
        /* 2. Strip leading spaces */
        value_part = STRIP(value_part, 'L')
        
        /* 3. The value should be enclosed in quotes. We find the first and second quote. */
        IF LEFT(value_part, 1) = '"' THEN DO
            /* Find the position of the closing quote */
            end_quote_pos = POS('"', SUBSTR(value_part, 2))
            
            IF end_quote_pos > 0 THEN DO
                /* Extract the string between the quotes */
                tag_value = SUBSTR(value_part, 2, end_quote_pos - 1)
                LEAVE /* We found the first valid one, so we can exit the loop */
            END
        END
    END
END

CALL CLOSE(inputfile)

/* Check if we found the value */
IF tag_value = "" THEN DO
    SAY 'Could not find a valid release (draft:false, prerelease:false) in the file.'
    EXIT 20
END

/* Set the environment variable called TagENV */
ADDRESS COMMAND 'SETENV TagENV 'tag_value

/* Verify by displaying the result */
SAY 'Set TagENV to: 'tag_value

EXIT 0