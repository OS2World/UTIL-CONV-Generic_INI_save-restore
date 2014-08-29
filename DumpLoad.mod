(**************************************************************************)
(*                                                                        *)
(*  Software to convert between INI and TNI formats.                      *)
(*  Copyright (C) 2014   Peter Moylan                                     *)
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

IMPLEMENTATION MODULE DumpLoad;

        (********************************************************)
        (*                                                      *)
        (*          Generic dump from INI to TNI format         *)
        (*                                                      *)
        (*  Programmer:         P. Moylan                       *)
        (*  Started:            9 November 2008                 *)
        (*  Last edited:        3 July 2012                     *)
        (*  Status:             Working                         *)
        (*                                                      *)
        (********************************************************)

IMPORT GIV, Strings, STextIO;

FROM SYSTEM IMPORT
    (* type *)  ADDRESS,
    (* proc *)  ADR;

FROM OS2 IMPORT
    (* type *)  HAB,
    (* proc *)  WinInitialize;

FROM FileOps IMPORT
    (* type *)  ChanId, FilenameString, DirectoryEntry,
    (* proc *)  FirstDirEntry, OpenOldFile, CloseFile,
                Exists, DeleteFile, MoveFile,
                WriteRaw, FWriteChar, FWriteString, FWriteLn;

FROM INIData IMPORT
    (* type *)  HINI, StringReadState,
    (* proc *)  OpenINIFile, CreateINIFile, INIValid, CloseINIFile,
                GetStringList, NextString, CloseStringList,
                ItemSize, INIGetTrusted, INIPutBinary;

FROM LowLevel IMPORT
    (* proc *)  Copy;

FROM Storage IMPORT ALLOCATE, DEALLOCATE;

(************************************************************************)

CONST Nul = CHR(0);

TYPE
    NameType = ARRAY [0..511] OF CHAR;

(************************************************************************)
(*              OUR GLOBAL STRUCTURE HOLDING THE DATA READ              *)
(************************************************************************)

TYPE
    CharPtr = POINTER TO ARRAY [0..65535] OF CHAR;

    StrPtr = RECORD
                 length: CARDINAL;
                 start: ADDRESS;
             END (*RECORD*);

    KeyPtr = POINTER TO
                  RECORD
                      next: KeyPtr;
                      name: StrPtr;
                      val: StrPtr;
                  END (*RECORD*);

    AppPtr = POINTER TO
                  RECORD
                      next: AppPtr;
                      FirstKey: KeyPtr;
                      name: StrPtr;
                  END (*RECORD*);

(************************************************************************)

VAR MasterList: AppPtr;

(************************************************************************)
(*                      MISCELLANEOUS UTILITIES                         *)
(************************************************************************)

(*
PROCEDURE WriteCard (N: CARDINAL);

    BEGIN
        IF N > 9 THEN
            WriteCard (N DIV 10);
            N := N MOD 10;
        END (*IF*);
        STextIO.WriteChar (CHR(N + ORD('0')));
    END WriteCard;
*)

(************************************************************************)

PROCEDURE StrPtrToString (V: StrPtr;  VAR (*OUT*) result: ARRAY OF CHAR);

    (* Converts V to a conventional string. *)

    VAR N: CARDINAL;

    BEGIN
        N := V.length;
        IF N > HIGH(result) THEN
            N := HIGH(result) + 1;
        END (*IF*);
        Copy (V.start, ADR(result), N);
        IF N <= HIGH(result) THEN
            result[N] := Nul;
        END (*IF*);
    END StrPtrToString;

(************************************************************************)
(*                   LOADING ALL THE DATA INTO MEMORY                   *)
(************************************************************************)

PROCEDURE LoadOneValue (hini: HINI;  VAR (*IN*) app, key: NameType): StrPtr;

    (* Reads one value from the hini file.  *)

    VAR size: CARDINAL;  p: CharPtr;  V: StrPtr;

    BEGIN
        IF ItemSize (hini, app, key, size) AND (size > 0) THEN
            ALLOCATE (p, size);
            IF INIGetTrusted (hini, app, key, p^, size) THEN
                V.length := size;
            ELSE
                V.length := 0;
                DEALLOCATE (p, size);
                p := NIL;
            END (*IF*);
            V.start := p;
        ELSE
            V.length := 0;
            V.start := NIL;
        END (*IF*);

        RETURN V;

    END LoadOneValue;

(************************************************************************)

PROCEDURE TextToStrPtr (VAR (*IN*) text: ARRAY OF CHAR;
                                                 VAR (*OUT*) V: StrPtr);

    (* Converts a text string to StrPtr representation. *)

    VAR size: CARDINAL;

    BEGIN
        size := LENGTH(text);
        ALLOCATE (V.start, size);
        Copy (ADR(text), V.start, size);
        V.length := size;
    END TextToStrPtr;

(************************************************************************)

PROCEDURE LoadOneApp (hini: HINI;  VAR (*IN*) app: NameType): KeyPtr;

    (* Reads one application from the hini file.  *)

    VAR state: StringReadState;
        key: NameType;
        result, tail, current: KeyPtr;

    BEGIN
        result := NIL;  tail := NIL;
        key := "";
        GetStringList (hini, app, key, state);
        LOOP
            NextString (state, key);
            IF key[0] = Nul THEN
                EXIT (*LOOP*);
            END (*IF*);
            NEW (current);
            IF tail = NIL THEN
                result := current;
            ELSE
                tail^.next := current;
            END (*IF*);
            current^.next := NIL;
            tail := current;
            TextToStrPtr (key, current^.name);
            current^.val := LoadOneValue (hini, app, key);
        END (*LOOP*);
        CloseStringList (state);
        RETURN result;
    END LoadOneApp;

(************************************************************************)

PROCEDURE LoadAllApps (hini: HINI);

    (* Reads all application/key information from the hini file.  *)

    VAR state: StringReadState;
        app: NameType;
        tail, current: AppPtr;
        count: CARDINAL;

    BEGIN
        count := 0;
        MasterList := NIL;  tail := NIL;
        app := "";
        GetStringList (hini, app, app, state);
        LOOP
            NextString (state, app);
            IF app[0] = Nul THEN
                EXIT (*LOOP*);
            END (*IF*);
            NEW (current);
            IF tail = NIL THEN
                MasterList := current;
            ELSE
                tail^.next := current;
            END (*IF*);
            current^.next := NIL;
            tail := current;
            TextToStrPtr (app, current^.name);
            current^.FirstKey := LoadOneApp (hini, app);
            INC (count);
        END (*LOOP*);
        (*
        CloseStringList (state);
        STextIO.WriteString ("Loaded ");
        WriteCard (count);
        STextIO.WriteString (" applications.");
        STextIO.WriteLn;
        *)
    END LoadAllApps;

(************************************************************************)

PROCEDURE LoadAllData (name: FilenameString;  FromINI: BOOLEAN): BOOLEAN;

    (* Reads all information from the name.INI or name.TNI file.  *)

    VAR hini: HINI;
        success: BOOLEAN;
        INIFileName: FilenameString;

    BEGIN
        Strings.Assign (name, INIFileName);
        IF FromINI THEN
            Strings.Append (".INI", INIFileName);
        ELSE
            Strings.Append (".TNI", INIFileName);
        END (*IF*);

        STextIO.WriteString ("Reading data from ");
        STextIO.WriteString (INIFileName);
        STextIO.WriteLn;

        hini := OpenINIFile (INIFileName, NOT FromINI);
        success := INIValid (hini);
        IF success THEN
            LoadAllApps (hini);
            CloseINIFile (hini);
        ELSE
            STextIO.WriteString ("Failed to open ");
            STextIO.WriteString (INIFileName);
            STextIO.WriteLn;
        END (*IF*);

        RETURN success;

    END LoadAllData;

(************************************************************************)
(*                         DISCARDING TNI DATA                          *)
(************************************************************************)

PROCEDURE DiscardName (VAR (*INOUT*) name: StrPtr);

    (* Discards a variable-length string.                               *)
    (* We assume that the caller has exclusive access to the string.    *)

    BEGIN
        IF name.length > 0 THEN
            DEALLOCATE (name.start, name.length);
            name.length := 0;
            name.start := NIL;
        END (*IF*);
    END DiscardName;

(************************************************************************)

PROCEDURE DiscardKey (VAR (*INOUT*) k: KeyPtr);

    (* Discards one key.                                        *)
    (* We assume that the caller has exclusive access to it.    *)

    BEGIN
        DiscardName (k^.name);
        DiscardName (k^.val);
        DISPOSE (k);
    END DiscardKey;

(************************************************************************)

PROCEDURE DiscardApp (VAR (*INOUT*) p: AppPtr);

    (* Discards all keys for the given application.             *)
    (* We assume that the caller has exclusive access to p.     *)

    VAR k: KeyPtr;

    BEGIN
        k := p^.FirstKey;
        WHILE k <> NIL DO
            p^.FirstKey := k^.next;
            DiscardKey (k);
            k := p^.FirstKey;
        END (*WHILE*);
        DiscardName (p^.name);
        DISPOSE (p);
    END DiscardApp;

(************************************************************************)
(*                       PUTTING OUT THE RESULT                         *)
(************************************************************************)

PROCEDURE DumpValue (hini: HINI;
                     VAR (*IN*) appname, keyname: ARRAY OF CHAR;
                                                           V: StrPtr);

    (* Dumps a value to hini. *)

    BEGIN
        IF V.length = 0 THEN
            INIPutBinary (hini, appname, keyname, keyname, 0);
        ELSE
            INIPutBinary (hini, appname, keyname, V.start^, V.length);
        END (*IF*);
    END DumpValue;

(************************************************************************)

PROCEDURE DumpKeyList (hini: HINI;  VAR (*IN*) appname: ARRAY OF CHAR;
                                     VAR (*INOUT*) list: KeyPtr);

    (* Dumps list to hini, and disposes of it. *)

    VAR p: KeyPtr;
        keyname: NameType;

    BEGIN
        WHILE list <> NIL DO
            StrPtrToString (list^.name, keyname);
            DumpValue (hini, appname, keyname, list^.val);
            p := list^.next;
            DiscardKey (list);
            list := p;
        END (*WHILE*);
    END DumpKeyList;

(************************************************************************)

PROCEDURE DumpAppList (hini: HINI;  VAR (*INOUT*) list: AppPtr);

    (* Dumps list to hini, and disposes of it. *)

    VAR p: AppPtr;  count: CARDINAL;
        appname: NameType;

    BEGIN
        count := 0;
        WHILE list <> NIL DO
            INC (count);
            StrPtrToString (list^.name, appname);
            DumpKeyList (hini, appname, list^.FirstKey);
            p := list^.next;
            DiscardApp (list);
            list := p;
        END (*WHILE*);
        (*
        STextIO.WriteString ("Stored ");
        WriteCard (count);
        STextIO.WriteString (" applications.");
        STextIO.WriteLn;
        *)
    END DumpAppList;

(************************************************************************)

PROCEDURE OpenOutputFile (VAR (*INOUT*) outname: ARRAY OF CHAR;
                                             UseTNI: BOOLEAN): HINI;

    (* Opens the file outname.INI or outname.TNI for output.  If a file *)
    (* of this name already exists, we create a backup file.            *)

    VAR filename, BAKname: FilenameString;
        hini: HINI;

    BEGIN
        Strings.Assign (outname, filename);
        IF UseTNI THEN
            Strings.Append (".TNI", filename);
        ELSE
            Strings.Append (".INI", filename);
        END (*IF*);
        STextIO.WriteString ("Writing the result to ");
        STextIO.WriteString (filename);
        STextIO.WriteLn;
        IF Exists (filename) THEN
            Strings.Assign (filename, BAKname);
            Strings.Append (".BAK", BAKname);
            DeleteFile (BAKname);
            IF MoveFile (filename, BAKname) THEN
                hini := CreateINIFile (filename, UseTNI);
            ELSE
                hini := NIL;
            END (*IF*);
        ELSE
            hini := CreateINIFile (filename, UseTNI);
        END (*IF*);
        RETURN hini;
    END OpenOutputFile;

(************************************************************************)

PROCEDURE DumpAllData (name: FilenameString;  UseTNI: BOOLEAN): BOOLEAN;

    (* Writes all information to the name.INI or name.TNI file.  *)

    VAR hini: HINI;
        success: BOOLEAN;

    BEGIN
        hini := OpenOutputFile (name, UseTNI);
        success := INIValid(hini);
        IF success THEN
            DumpAppList (hini, MasterList);
            CloseINIFile (hini);
        ELSE
            STextIO.WriteString ("Failed to open output file ");
            STextIO.WriteString (name);
            STextIO.WriteLn;
        END (*IF*);

        RETURN success;

    END DumpAllData;

(************************************************************************)
(*                            MAIN PROCEDURE                            *)
(************************************************************************)

PROCEDURE TransferINIData (ProgramName: ARRAY OF CHAR;
                          VAR (*IN*) file: ARRAY OF CHAR;  dump: BOOLEAN);

    (* Dumps file.INI to AppName.TNI if dump=TRUE, or conversely  *)
    (* if dump=FALSE.                                             *)

    VAR AppName, LookFor: FilenameString;
        D: DirectoryEntry;
        pos: CARDINAL;
        success, found: BOOLEAN;

    BEGIN
        (* Identify the program name and GenINI version.  *)

        STextIO.WriteString (ProgramName);
        STextIO.WriteString (" version ");
        STextIO.WriteString (GIV.version);
        STextIO.WriteLn;

        (* The application name should be supplied as a parameter.      *)
        (* If it's missing, search for an INI file in the current       *)
        (* directory.  If both of these approaches fail, we have to     *)
        (* give up with an error message.                               *)

        Strings.Assign (file, AppName);
        IF AppName[0] = Nul THEN

            (* Find the first INI/TNI file in the current directory. *)

            IF dump THEN
                LookFor := "*.ini";
            ELSE
                LookFor := "*.tni";
            END (*IF*);
            IF FirstDirEntry (LookFor, FALSE, TRUE, D) THEN
                AppName := D.name;
            END (*IF*);

        END (*IF*);

        success := AppName[0] <> Nul;
        IF success THEN
            Strings.FindPrev (".", AppName, LENGTH(AppName), found, pos);
            IF found THEN
                AppName[pos] := Nul;
            END (*IF*);
        ELSE
            STextIO.WriteString ("Error: you have to supply an application name.");
            STextIO.WriteLn;
        END (*IF*);

        (* Load the data from the INI file, then write it out to *)
        (* the TNI file.  (Or vice versa if dump=FALSE.)         *)

        success := success AND LoadAllData (AppName, dump)
                           AND DumpAllData (AppName, dump);

        IF success THEN
            STextIO.WriteString ("Finished");
            STextIO.WriteLn;
        ELSE
            STextIO.WriteString ("Operation failed");
            STextIO.WriteLn;
        END (*IF*);

    END TransferINIData;

(************************************************************************)

END DumpLoad.

