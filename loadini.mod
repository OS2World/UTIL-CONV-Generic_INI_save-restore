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

MODULE LoadINI;

        (********************************************************)
        (*                                                      *)
        (*          Generic load from INI to TNI format         *)
        (*                                                      *)
        (*  Programmer:         P. Moylan                       *)
        (*  Started:            9 November 2008                 *)
        (*  Last edited:        28 February 2009                *)
        (*  Status:             Working                         *)
        (*                                                      *)
        (********************************************************)

IMPORT IOChan, TextIO, Strings;

FROM DumpLoad IMPORT
    (* proc *)  TransferINIData;

FROM ProgramArgs IMPORT
    (* proc *)  ArgChan, IsArgPresent;

FROM FileOps IMPORT
    (* type *)  FilenameString;

(************************************************************************)

CONST Nul = CHR(0);

(************************************************************************)
(*                             MAIN PROGRAM                             *)
(************************************************************************)

PROCEDURE GetParameter (VAR (*OUT*) result: ARRAY OF CHAR);

    (* Picks up the application name from the command line.  *)

    TYPE CharSet = SET OF CHAR;
    CONST Digits = CharSet {'0'..'9'};

    VAR args: IOChan.ChanId;
        L: CARDINAL;

    BEGIN
        args := ArgChan();
        IF IsArgPresent() THEN
            TextIO.ReadString (args, result);
        ELSE
            result[0] := Nul;
        END (*IF*);

        (* Remove leading and trailing spaces. *)

        WHILE result[0] = ' ' DO
            Strings.Delete (result, 0, 1);
        END (*WHILE*);
        L := Strings.Length (result);
        WHILE (L > 0) AND (result[L-1] = ' ') DO
            DEC (L);  result[L] := Nul;
        END (*WHILE*);

    END GetParameter;

(************************************************************************)

VAR AppName: FilenameString;

BEGIN
    GetParameter (AppName);
    (*AppName := "OS2";*)       (* while testing *)
    TransferINIData ("LoadINI", AppName, FALSE);
END LoadINI.

