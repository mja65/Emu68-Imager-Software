/******************************************************************************
 * ListDevices.c
 *
 * Utility to enumerate and filter DOS devices.
 * Supports physical disks and network handlers (SMB/Network shares).
 *
 * Target: AmigaOS 2.04+ (Kickstart 37+)
 ******************************************************************************/

#include <exec/types.h>
#include <libraries/dos.h>
#include <libraries/dosextens.h>
#include <libraries/filehandler.h>
#include <proto/dos.h>
#include <proto/exec.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

/* Standard Amiga Version String */
static const char __aligned ver[] = "$VER: ListDevices 0.1 (31.01.2026)\r\n";

/* Helper: MatchOr - Handles comma-delimited OR logic for filters */
int MatchOr(char *currentVal, char *filterList) {
    char temp[256];
    char *token;
    if (!filterList) return 1;
    
    strncpy(temp, filterList, 255);
    temp[255] = '\0';
    
    token = strtok(temp, ",");
    while (token) {
        /* Skip leading whitespace if user typed "VAL1, VAL2" */
        while(isspace((unsigned char)*token)) token++;
        
        if (stricmp(currentVal, token) == 0) return 1;
        token = strtok(NULL, ",");
    }
    return 0;
}

int main(int argc, char *argv[])
{
    struct DosLibrary *DOSBase;
    struct RootNode   *rn;
    struct DosInfo    *di;
    struct DeviceNode *dn, *vn;
    char dev[34], volName[34], devName[64], handler[64], unitStr[12];
    char *filterVal = NULL;
    int filterMode = 0; 
    int noFormat = 0;

    /* --- Command Line Argument Parsing --- */
    for (int a = 1; a < argc; a++) {
        if (stricmp(argv[a], "?") == 0 || stricmp(argv[a], "HELP") == 0) {
            printf("Usage: ListDevices [KEYWORD=VAL1,VAL2] [NOFORMATTABLE]\n");
            printf("Keywords: DEVICE, RAW_DOSTYPE, DOSTYPE, DEVICE_NAME, UNIT, VOLUME\n");
            printf("Example: ListDevices DEVICE_NAME=uaehf.device,trackdisk.device\n");
            return 0;
        }
        
        if (stricmp(argv[a], "NOFORMATTABLE") == 0) {
            noFormat = 1;
        } else {
            char *eq = strchr(argv[a], '=');
            if (eq) {
                int keyLen = eq - argv[a];
                char key[32];
                strncpy(key, argv[a], keyLen);
                key[keyLen] = '\0';
                filterVal = eq + 1;

                if (stricmp(key, "DEVICE") == 0) filterMode = 1;
                else if (stricmp(key, "RAW_DOSTYPE") == 0) filterMode = 2;
                else if (stricmp(key, "DOSTYPE") == 0) filterMode = 3;
                else if (stricmp(key, "DEVICE_NAME") == 0) filterMode = 4;
                else if (stricmp(key, "UNIT") == 0) filterMode = 5;
                else if (stricmp(key, "VOLUME") == 0) filterMode = 6;
            } else {
                filterVal = argv[a];
                filterMode = 4; 
            }
        }
    }

    if ((DOSBase = (struct DosLibrary *)OpenLibrary("dos.library", 37)))
    {
        rn = (struct RootNode *)DOSBase->dl_Root;
        di = (struct DosInfo *)BADDR(rn->rn_Info);
        
        if (!noFormat) {
            printf("%-12s %-12s %-12s %-18s %-4s %-12s\n", "DEVICE", "RAW DOSTYPE", "DOSTYPE", "DEVICE NAME", "UNIT", "VOLUME");
            printf("------------ ------------ ------------ ------------------ ---- ------------\n");
        }

        dn = (struct DeviceNode *)BADDR(di->di_DevInfo);
        while (dn)
        {
            struct DeviceList *dl = (struct DeviceList *)dn;
            if (dl->dl_Type == DLT_DEVICE)
            {
                /* 1. Extract Device Logical Name */
                char *bn = (char *)BADDR(dl->dl_Name);
                int len = bn[0];
                int i;
                for(i = 0; i < len && i < 32; i++) dev[i] = bn[i+1];
                dev[i] = '\0';

                /* 2. Extract Handler Path */
                handler[0] = '\0';
                if (dn->dn_Handler) {
                    char *hPtr = (char *)BADDR(dn->dn_Handler);
                    int hLen = hPtr[0];
                    if (hLen > 0 && hLen < 63) {
                        for(int j=0; j<hLen; j++) handler[j] = hPtr[j+1];
                        handler[hLen] = '\0';
                    }
                }

                /* 3. Extract Startup/Physical Details */
                devName[0] = '\0';
                int unitNum = -1;
                unsigned long dt = 0;
                struct FileSysStartupMsg *fssm = (struct FileSysStartupMsg *)BADDR(dn->dn_Startup);
                
                if (fssm && fssm != (struct FileSysStartupMsg *)-1) {
                    char *dPtr = (char *)BADDR(fssm->fssm_Device);
                    if (dPtr && (unsigned long)dPtr > 0x1000) {
                        int dLen = dPtr[0];
                        for(int j=0; j<dLen && j<63; j++) devName[j] = dPtr[j+1];
                        devName[dLen] = '\0';
                    }
                    unitNum = fssm->fssm_Unit;
                    struct DosEnvec *de = (struct DosEnvec *)BADDR(fssm->fssm_Environ);
                    if (de && de->de_TableSize >= 15) dt = de->de_DosType;
                }
                if (dt == 0 || dt > 0x7FFFFFFF) dt = dl->dl_DiskType;

                char cleanDT[12] = "---";
                if ((dt >> 24) >= 0x20 && (dt >> 24) <= 0x7E) {
                    sprintf(cleanDT, "%c%c%c\\%d", (char)(dt>>24), (char)(dt>>16), (char)(dt>>8), (int)(dt&0xFF));
                }

                char rawDTStr[12];
                sprintf(rawDTStr, "0x%08lx", dt);
                char *displayDevName = devName[0] ? devName : (handler[0] ? handler : "---");

                if (unitNum != -1 && unitNum < 1000000) sprintf(unitStr, "%d", unitNum);
                else strcpy(unitStr, "---");

                /* 4. Find Associated Volume Name */
                volName[0] = '\0';
                vn = (struct DeviceNode *)BADDR(di->di_DevInfo);
                while (vn) {
                    struct DeviceList *vl = (struct DeviceList *)vn;
                    if (vl->dl_Type == DLT_VOLUME && vl->dl_Task == dl->dl_Task) {
                        char *vbn = (char *)BADDR(vl->dl_Name);
                        int vlen = vbn[0];
                        int k;
                        for(k = 0; k < vlen && k < 32; k++) volName[k] = vbn[k+1];
                        volName[k] = '\0';
                        break;
                    }
                    vn = (struct DeviceNode *)BADDR(vl->dl_Next);
                }

                /* --- Output Filtering --- */
                int match = 0;
                if (filterMode == 0) match = 1;
                else if (filterMode == 1 && MatchOr(dev, filterVal)) match = 1;
                else if (filterMode == 2 && MatchOr(rawDTStr, filterVal)) match = 1;
                else if (filterMode == 3 && MatchOr(cleanDT, filterVal)) match = 1;
                else if (filterMode == 4 && MatchOr(displayDevName, filterVal)) match = 1;
                else if (filterMode == 5 && MatchOr(unitStr, filterVal)) match = 1;
                else if (filterMode == 6 && MatchOr(volName, filterVal)) match = 1;

                if (match)
                {
                    if (noFormat) {
                        printf("%s;%s;%s;%s;%s;%s\n", dev, rawDTStr, cleanDT, displayDevName, unitStr, volName[0] ? volName : "---");
                    } else {
                        printf("%-12s %-12s %-12s %-18s %-4s %-12s\n", dev, rawDTStr, cleanDT, displayDevName, unitStr, volName[0] ? volName : "---");
                    }
                }
            }
            dn = (struct DeviceNode *)BADDR(dl->dl_Next);
        }
        CloseLibrary((struct Library *)DOSBase);
    }
    return 0;
}