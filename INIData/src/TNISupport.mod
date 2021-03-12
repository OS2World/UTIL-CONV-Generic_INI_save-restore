(**************************************************************************)
(*                                                                        *)
(*  Support modules for INIData DLL                                       *)
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

IMPLEMENTATION MODULE TNISupport;

        (************************************************************)
        (*                                                          *)
        (*            Looking after text-based INI data             *)
        (*                                                          *)
        (*    Started:        26 June 2005                          *)
        (*    Last edited:    11 April 2019                         *)
        (*    Status:         Working on DLL implementation         *)
        (*                                                          *)
        (************************************************************)


IMPORT OS2, Strings;

FROM SYSTEM IMPORT
    (* type *)  LOC, ADDRESS,
    (* proc *)  ADDADR, MOVE;

(************************************************************************)
(*                LOCKS FOR CRITICAL SECTION PROTECTION                 *)
(************************************************************************)

PROCEDURE CreateLock (VAR (*OUT*) L: Lock;  label: ARRAY OF CHAR);

    (* Creates a new lock, or obtains access to a lock created by       *)
    (* another process.                                                 *)

    VAR rc: CARDINAL;
        name: ARRAY [0..255] OF CHAR;

    BEGIN
        name := "\SEM32\TNIData_";
        Strings.Append (label, name);
        rc := OS2.DosOpenMutexSem (name, L);
        IF rc = OS2.ERROR_SEM_NOT_FOUND THEN
            rc := OS2.DosCreateMutexSem (name, L, 0, FALSE);
        END (*IF*);
        IF rc <> 0 THEN
            L := MAX(CARDINAL);
        END (*IF*);
    END CreateLock;

(************************************************************************)

PROCEDURE DestroyLock (VAR (*INOUT*) L: Lock);

    (* Closes a lock.  It will be destroyed if the caller is the last   *)
    (* thread to close it.                                              *)

    VAR rc: CARDINAL;

    BEGIN
        rc := OS2.DosCloseMutexSem (L);
    END DestroyLock;

(************************************************************************)

PROCEDURE Obtain (L: Lock);

    (* Obtains lock L, waiting if necessary. *)

    VAR rc: CARDINAL;

    BEGIN
        rc := OS2.DosRequestMutexSem (L, OS2.SEM_INDEFINITE_WAIT);
    END Obtain;

(************************************************************************)

PROCEDURE Release (L: Lock);

    (* Releases lock L - which might unblock some other task. *)

    VAR rc: CARDINAL;

    BEGIN
        IF L <> MAX(CARDINAL) THEN
            rc := OS2.DosReleaseMutexSem (L);
        END (*IF*);
    END Release;

(************************************************************************)
(*                        MISCELLANEOUS UTILITIES                       *)
(************************************************************************)

PROCEDURE EVAL (f: ARRAY OF LOC);

    (* A do-nothing procedure - we use it for evaluating a function and *)
    (* ignoring the result.                                             *)

    BEGIN
    END EVAL;

(************************************************************************)

PROCEDURE AddOffset (A: ADDRESS;  increment: CARDINAL): ADDRESS;

    (* Returns a pointer to the memory location whose physical address  *)
    (* is Physical(A)+increment.  In the present version, it is assumed *)
    (* that the caller will never try to run off the end of a segment.  *)

    BEGIN
        RETURN ADDADR (A, increment);
    END AddOffset;

(************************************************************************)

PROCEDURE Copy (source, destination: ADDRESS;  bytecount: CARDINAL);

    (* Copies an array of bytes from the source address to the          *)
    (* destination address.  In the case where the two arrays overlap,  *)
    (* the destination address should be lower in physical memory than  *)
    (* the source address.                                              *)

    BEGIN
        <* WOFF316 + *>
        MOVE (source, destination, bytecount);
        <* WOFF316 - *>
    END Copy;

(************************************************************************)

END TNISupport.

