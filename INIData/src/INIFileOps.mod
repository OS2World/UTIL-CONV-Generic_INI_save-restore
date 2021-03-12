(**************************************************************************)
(*                                                                        *)
(*  INIData DLL support                                                   *)
(*  Copyright (C) 2019   Peter Moylan                                     *)
(*                                                                        *)
(*  This program is free software: you can redistribute it and/or modify  *)
(*  it under the terms of the GNU General Public License as published by  *)
(*  the Free Software Foundation, either version 3 of the License, or     *)
(*  (at your option) any later version.                                   *)
(*                                                                        *)
(*  This program is distributed in the hope that it will be useful,       *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of        *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *)
(*  GNU General Public License for more details.                          *)
(*                                                                        *)
(*  You should have received a copy of the GNU General Public License     *)
(*  along with this program.  If not, see <http://www.gnu.org/licenses/>. *)
(*                                                                        *)
(*  To contact author:   http://www.pmoylan.org   peter@pmoylan.org       *)
(*                                                                        *)
(**************************************************************************)

IMPLEMENTATION MODULE INIFileOps;

        (********************************************************)
        (*                                                      *)
        (*                 File utilities                       *)
        (*                                                      *)
        (*       This is a specialised version of the FileOps   *)
        (*       module that only includes those procedures     *)
        (*       that are needed for INIData operations.        *)
        (*                                                      *)
        (*  Programmer:         P. Moylan                       *)
        (*  Started:            10 April 2019                   *)
        (*  Last edited:        11 April 2019                   *)
        (*  Status:             Working                         *)
        (*                                                      *)
        (********************************************************)


IMPORT OS2;

FROM SYSTEM IMPORT
    (* type *)  LOC,
    (* proc *)  ADR, CAST;

IMPORT FileSys;

(************************************************************************)

CONST Nul = CHR(0);

VAR
    (* LongSupport is TRUE if the OS version is high enough to support  *)
    (* 64-bit file pointers.                                            *)

    LongSupport: BOOLEAN;

(************************************************************************)
(* Entry points of dynamically loaded procedures.                       *)
(************************************************************************)

TYPE
    OpenLProc = PROCEDURE [OS2.APIENTRY] (ARRAY OF CHAR, VAR OS2.HFILE,
                                     VAR OS2.ULONG, OS2.ULONG, OS2.ULONG,
                                     OS2.ULONG, OS2.ULONG, OS2.ULONG,
                                     VAR [NIL] OS2.EAOP2): OS2.APIRET;
    SetFilePtrLProc = PROCEDURE [OS2.APIENTRY] (OS2.HFILE, OS2.ULONG,
                                 OS2.LONG, OS2.ULONG,
                                 OS2.PULONG): OS2.APIRET;
    SetFileSizeLProc = PROCEDURE [OS2.APIENTRY] (OS2.HFILE,
                                 OS2.ULONG, OS2.ULONG): OS2.APIRET;

VAR
    OpenL: OpenLProc;
    SetFilePtrL: SetFilePtrLProc;
    SetFileSizeL: SetFileSizeLProc;

(************************************************************************)
(*                      GENERAL FILE OPERATIONS                         *)
(************************************************************************)

PROCEDURE IncreaseFileHandles;

    (* Adds some more file handles to the process. *)

    VAR cbReqCount: OS2.LONG;  cbCurMaxFH: OS2.ULONG;

    BEGIN
        cbReqCount := 32;
        OS2.DosSetRelMaxFH (cbReqCount, cbCurMaxFH);
    END IncreaseFileHandles;

(************************************************************************)

PROCEDURE OpenOldFile (name: ARRAY OF CHAR;  WillWrite: BOOLEAN;
                                             binary: BOOLEAN): ChanId;

    (* Opens an existing file and returns its channel ID.  If the       *)
    (* second parameter is TRUE we are requesting write as well as read *)
    (* access; if it's FALSE, we want read-only access.                 *)
    (* The 'binary' parameter is ignored in the OS/2 version, but is    *)
    (* needed in the Windows version.                                   *)

    CONST
        OpenFlags = OS2.OPEN_ACTION_FAIL_IF_NEW
                    + OS2.OPEN_ACTION_OPEN_IF_EXISTS;
        Mode1 = OS2.OPEN_FLAGS_FAIL_ON_ERROR + OS2.OPEN_SHARE_DENYNONE
                + OS2.OPEN_FLAGS_NOINHERIT
                + OS2.OPEN_ACCESS_READONLY;
        Mode2 = OS2.OPEN_FLAGS_FAIL_ON_ERROR + OS2.OPEN_SHARE_DENYWRITE
                + OS2.OPEN_FLAGS_NOINHERIT
                + OS2.OPEN_ACCESS_READWRITE;

    VAR cid: ChanId;  rc: OS2.APIRET;  Mode, Action: CARDINAL;

    BEGIN
        IF WillWrite THEN
            Mode := Mode2;
        ELSE
            Mode := Mode1;
        END (*IF*);
        IF LongSupport THEN
            rc := OpenL (name, cid, Action, 0, 0, 0, OpenFlags, Mode, NIL);
        ELSE
            rc := OS2.DosOpen (name, cid, Action, 0, 0, OpenFlags, Mode, NIL);
        END (*IF*);
        IF rc = OS2.ERROR_TOO_MANY_OPEN_FILES THEN
            IncreaseFileHandles;
            RETURN OpenOldFile (name, WillWrite, binary);
        ELSIF rc <> 0 THEN
            cid := NoSuchChannel;
        END (*IF*);
        RETURN cid;
    END OpenOldFile;

(************************************************************************)

PROCEDURE OpenNewFile (name: ARRAY OF CHAR;  binary: BOOLEAN): ChanId;

    (* Opens a new file and returns its channel ID.                     *)
    (* The 'binary' parameter is ignored in the OS/2 version, but is    *)
    (* needed in the Windows version.                                   *)

    CONST
        OpenFlags = OS2.OPEN_ACTION_CREATE_IF_NEW
                    + OS2.OPEN_ACTION_FAIL_IF_EXISTS;
        Mode = OS2.OPEN_FLAGS_FAIL_ON_ERROR + OS2.OPEN_SHARE_DENYWRITE
                + OS2.OPEN_FLAGS_NOINHERIT
                + OS2.OPEN_ACCESS_READWRITE;

    VAR cid: ChanId;  rc: OS2.APIRET;  Action: CARDINAL;

    BEGIN
        IF LongSupport THEN
            rc := OpenL (name, cid, Action, 0, 0, 0, OpenFlags, Mode, NIL);
        ELSE
            rc := OS2.DosOpen (name, cid, Action, 0, 0, OpenFlags, Mode, NIL);
        END (*IF*);
        IF rc = OS2.ERROR_TOO_MANY_OPEN_FILES THEN
            IncreaseFileHandles;
            RETURN OpenNewFile (name, binary);
        ELSIF rc <> 0 THEN
            cid := NoSuchChannel;
        END (*IF*);
        RETURN cid;
    END OpenNewFile;

(************************************************************************)

PROCEDURE OpenNewFile0 (name: ARRAY OF CHAR;  Attributes: CARDINAL;
                         VAR (*OUT*) duplicate: BOOLEAN): ChanId;

    (* Like OpenNewFile, but returns an indication of whether the       *)
    (* file couldn't be created because of a name duplication.  Also    *)
    (* allows attributes to be specified.                               *)

    CONST
        OpenFlags = OS2.OPEN_ACTION_CREATE_IF_NEW
                    + OS2.OPEN_ACTION_FAIL_IF_EXISTS;
        Mode = OS2.OPEN_FLAGS_FAIL_ON_ERROR + OS2.OPEN_SHARE_DENYWRITE
                + OS2.OPEN_FLAGS_NOINHERIT
                + OS2.OPEN_ACCESS_READWRITE;

    VAR cid: ChanId;  rc: OS2.APIRET;  Action: CARDINAL;

    BEGIN
        IF LongSupport THEN
            rc := OpenL (name, cid, Action, 0, 0,
                                       Attributes, OpenFlags, Mode, NIL);
        ELSE
            rc := OS2.DosOpen (name, cid, Action, 0, Attributes, OpenFlags,
                                       Mode, NIL);
        END (*IF*);
        duplicate := (rc = OS2.ERROR_FILE_EXISTS)
                       OR (rc = OS2.ERROR_OPEN_FAILED);
        IF rc <> 0 THEN
            cid := NoSuchChannel;
        END (*IF*);
        RETURN cid;
    END OpenNewFile0;

(************************************************************************)

PROCEDURE OpenNewFile1 (name: ARRAY OF CHAR;
                         VAR (*OUT*) duplicate: BOOLEAN): ChanId;

    (* Like OpenNewFile, but returns an indication of whether the       *)
    (* file couldn't be created because of a name duplication.          *)

    BEGIN
        RETURN OpenNewFile0 (name, 0, duplicate);
    END OpenNewFile1;

(************************************************************************)

PROCEDURE CloseFile (cid: ChanId);

    (* Closes a file. *)

    BEGIN
        OS2.DosClose (cid);
    END CloseFile;

(************************************************************************)

PROCEDURE Exists (name: ARRAY OF CHAR): BOOLEAN;

    (* Returns TRUE iff 'name' already exists. *)

    VAR L: CARDINAL;

    BEGIN
        L := LENGTH(name);
        IF L > 0 THEN
            DEC (L);
            IF (name[L] = '\') OR (name[L] = '/') THEN
                name[L] := Nul;
            END (*IF*);
        END (*IF*);
        RETURN FileSys.Exists (name);
    END Exists;

(************************************************************************)

PROCEDURE DeleteFile (name: ARRAY OF CHAR);

    (* Deletes a named file. *)

    VAR dummy: BOOLEAN;

    BEGIN
        FileSys.Remove (name, dummy);
    END DeleteFile;

(************************************************************************)

PROCEDURE CreateFile (name: ARRAY OF CHAR);

    (* Creates an empty file.  Deletes any existing file with the same name. *)

    VAR cid: ChanId;

    BEGIN
        IF Exists (name) THEN
            DeleteFile (name);
        END (*IF*);
        cid := OpenNewFile (name, TRUE);
        CloseFile (cid);
    END CreateFile;

(************************************************************************)

PROCEDURE MoveFile (oldname, newname: ARRAY OF CHAR): BOOLEAN;

    (* Renames a file, returns TRUE iff successful.  The source and     *)
    (* destination files must be on the same drive.  This procedure is  *)
    (* also a mechanism for renaming a file.                            *)

    VAR code: CARDINAL;

    BEGIN
        code := OS2.DosMove (oldname, newname);
        RETURN code = 0;
    END MoveFile;

(************************************************************************)
(*                              READ                                    *)
(************************************************************************)

PROCEDURE ReadLine (cid: ChanId;  VAR (*OUT*) data: ARRAY OF CHAR);

    (* Reads a line of text from a file.  Assumption: a line ends with  *)
    (* CRLF.  To avoid having to keep a lookahead character, I take     *)
    (* the LF as end of line and skip the CR.                           *)

    CONST CR = CHR(13);  LF = CHR(10);  CtrlZ = CHR(26);

    VAR j, NumberRead: CARDINAL;
        ch: CHAR;

    BEGIN
        j := 0;  ch := Nul;
        LOOP
            OS2.DosRead (cid, ADR(ch), 1, NumberRead);
            IF NumberRead = 0 THEN
                IF j = 0 THEN
                    data[0] := CtrlZ;  j := 1;
                END (*IF*);
                EXIT (*LOOP*);
            ELSIF ch = CR THEN
                (* ignore carriage return. *)
            ELSIF ch = LF THEN
                EXIT (*LOOP*);
            ELSIF j <= HIGH(data) THEN
                data[j] := ch;  INC(j);
            END (*IF*);
        END (*LOOP*);

        IF j <= HIGH(data) THEN
            data[j] := Nul;
        END (*IF*);

    END ReadLine;

(************************************************************************)
(*                               WRITE                                  *)
(************************************************************************)

PROCEDURE WriteRaw (cid: ChanId;  VAR (*IN*) data: ARRAY OF LOC;
                                            amount: CARDINAL);

    (* Writes a binary string to a file. *)

    VAR actual: CARDINAL;

    BEGIN
        OS2.DosWrite (cid, ADR(data), amount, actual);
    END WriteRaw;

(************************************************************************)

PROCEDURE WriteRawV (cid: ChanId;  data: ARRAY OF LOC;  amount: CARDINAL);

    (* Like WriteRaw, but data passed by value. *)

    VAR actual: CARDINAL;

    BEGIN
        OS2.DosWrite (cid, ADR(data), amount, actual);
    END WriteRawV;

(************************************************************************)

PROCEDURE FWriteChar (cid: ChanId;  character: CHAR);

    (* Writes a single character to a file. *)

    VAR actual: CARDINAL;

    BEGIN
        OS2.DosWrite (cid, ADR(character), 1, actual);
    END FWriteChar;

(************************************************************************)

PROCEDURE FWriteString (cid: ChanId;  string: ARRAY OF CHAR);

    (* Writes a string to a file. *)

    VAR actual: CARDINAL;

    BEGIN
        OS2.DosWrite (cid, ADR(string), LENGTH(string), actual);
    END FWriteString;

(************************************************************************)

PROCEDURE FWriteLn (cid: ChanId);

    (* Writes end-of-line to the file. *)

    TYPE TwoChar = ARRAY [0..1] OF CHAR;
    CONST CRLF = TwoChar {CHR(13), CHR(10)};

    BEGIN
        WriteRawV (cid, CRLF, 2);
    END FWriteLn;

(************************************************************************)
(*                      QUERYING THE SYSTEM VERSION                     *)
(************************************************************************)

PROCEDURE CheckSystemVersion;

    (* Checks whether the system version is high enough to support      *)
    (* files of size > 2GB.                                             *)

    VAR pfn: OS2.PFN;
        hmod: OS2.HMODULE;
        rc: OS2.APIRET;
        FailureObject: ARRAY [0..511] OF CHAR;

    BEGIN
        rc := OS2.DosLoadModule (FailureObject, SIZE(FailureObject),
                             'DOSCALLS', hmod);
        LongSupport := rc = 0;

        IF LongSupport THEN

            (* 981 is the ordinal number of DosOpenL. *)

            rc := OS2.DosQueryProcAddr(hmod, 981, NIL, pfn);
            OpenL := CAST (OpenLProc, pfn);
            LongSupport := rc = 0;
        END (*IF*);

        IF LongSupport THEN

            (* 988 is the ordinal number of DosSetFilePtrL. *)

            rc := OS2.DosQueryProcAddr(hmod, 988, NIL, pfn);
            SetFilePtrL := CAST (SetFilePtrLProc, pfn);
            LongSupport := rc = 0;
        END (*IF*);

        IF LongSupport THEN

            (* 989 is the ordinal number of DosSetFileSizeL. *)

            rc := OS2.DosQueryProcAddr(hmod, 989, NIL, pfn);
            SetFileSizeL := CAST (SetFileSizeLProc, pfn);
            LongSupport := rc = 0;
        END (*IF*);

    END CheckSystemVersion;

(************************************************************************)

BEGIN
    OS2.DosError (OS2.FERR_DISABLEHARDERR); (* disable hard error popups *)
    CheckSystemVersion;
END INIFileOps.

