:userdoc.
:title.GenINI documentation
:docprof toc=12.

.***********************************
.*   INTRODUCTION
.***********************************

:h1.Introduction
:p.
The GenINI package is a pair of programs (DumpINI, LoadINI) that
allow you to save OS/2 INI files in human-readable form, and to
load them from that human-readable form. It also includes some
Rexx scripts (in the TNItools subdirectory) to read and write INI and TNI data. It is
distributed as freeware, and licensed under the GNU General Public
License. You may distribute it with your own applications.
This documentation is for version 1.9.
:p.
:hp2.Disclaimer of Warranty:ehp2.

:sl compact.
:li.
:hp8.
This Product is provided "as-is", without warranty of any
kind, either expressed or implied, including, but not limited to,
the implied warranties of merchantability and fitness for a
particular purpose.  The entire risk as to the quality and
performance of the Product is with you.  Should the Product prove
defective, the full cost of repair, servicing, or correction lies
with you.
:ehp8.
:esl.

:p.
The author of GenINI is Peter Moylan, peter@pmoylan.org

:p.
The latest version of GenINI is normally kept at ftp&colon.&slash.&slash.ftp.pmoylan.org/software
To obtain the source code, look for a file GenINIsrc_N.N.zip, where N.N is the version number.
:p.
Information about other software on this site may be found at
http&colon.&slash.&slash.www.pmoylan.org/pages/os2/software.html.


.***********************************
.*   PREREQUISITES
.***********************************

:h1 id=prerequisites.Prerequisites

:hp2.Prerequisites:ehp2.

:p.This software assumes that both INIDATA.DLL and XDS230M.DLL are in your
LIBPATH. If, when trying to run LoadINI.exe or DumpINI.exe, you get a message like
"The system cannot find the file XDS230M", you must install INIData,
version 1.0 or later. INIData can be found at the same web or FTP site as where
you found the GenINI zip file.

.***********************************
.*   WHAT IS IT FOR?
.***********************************

:h1 id=whatsitfor.What is it for?
:hp2.What is it for?:ehp2.

:p.One of the most common ways for an OS/2 program to store its
configuration data is in an INI file. This means that you can, in
many cases, alter the program options by editing the program's INI
file. There are, in fact, several INI editors available to let you
do just that.

:p.The DumpINI program in this package allows you create a backup
of an INI file, and the LoadINI program allows you to restore the
backup. Of course, you could equally well perform a backup by just
making a copy of the INI file. What we are doing here is a little
more&colon. the backup is not merely a copy of the binary INI file,
it is a copy that has been translated into human-readable form.
(We call the result a TNI file, the T standing for "text version".)
There are some supplementary benefits in having a
human-readable version.

:p.First, it might turn out that an INI file whose contents were
difficult to understand makes a lot more sense once it is readable
as a text document. This can help when you are trying to understand
a program that you've installed.

:p.Second, there are times when it makes sense to edit an INI file,
and it's a whole lot easier to edit the TNI version than to edit
a binary file. You can use DumpINI to create the TNI file, then
use a plain text editor to modify it, and finally use LoadINI to
produce the edited INI file.

:p.I have now introduced the option, in several of my programs,
of having a choice between using an INI or a TNI file. (The
decision as to which one will be used is explained in the
:link reftype=hd refid=selectionrules.selection rules:elink..)
This is because some people are having
problems with the reliability of the INI subsystem within the
operating system code. It used to work well, but increasingly
- depending on the job mix on the computer - we are seeing
situations where INI data becomes inaccessible. This does not
happen to everyone, but when it does happen it is a serious nuisance.

:p.The reason for the problem is that the OS/2 INI-handling system routines were frozen
at a stage where 16MB was considered to be "large main memory". Since
that time the size of main memory has increased enormously - to the
point where 512 MB of main memory is considered "small" - and the
demand for memory has grown to follow the supply. One
consequence of this has been frequent overflows of the space in main
memory where INI data is cached. As a result, operations on INI files
often fail with an "out of memory" error. A system might have plenty
of physical memory, but cached INI data is only allowed to live in
a small shared region in low memory.

:p.The TNI format does not share this problem because TNI files are
read and written by normal file system operations, rather than by the
special INI-handling code within OS/2. In addition the data can be
cached, if desired, anywhere in main memory, instead of being restricted
to an especially crowded part of memory. Of course none of this can happen
unless the application programmer specifically allows for TNI files, but
it's not too hard to do that.

.***********************************
.*   WHAT'S IN AN INI FILE?
.***********************************

:h1 id=INIFileDescription.The contents of an INI file
:hp2.The contents of an INI file:ehp2.

:p.An INI file is a place where a program can store just about any
data that it likes. Typically it is used to store information that
the program needs to retain from one invocation to the next: screen
location, fonts, user-configurable options, and the like. You
wouldn't want to use it to store a huge database - that could be
inefficient - but an INI file is the ideal place to store those
little bits of information that aren't big enough to deserve a file
of their own.

:p.Internally, the file is a binary file. You don't need to know
about the precise internal structure, but in case you're interested
the details are given in the
:link reftype=hd refid=INIFormat.appendix:elink.. The
important thing is that OS/2 provides API calls that let a programmer
read and write INI file entries.

:p.Conceptually, each entry is a triple (application,key,value), where
the application and key are character strings that are usually
human-readable. You can think of this as a two-level hierarchy. The
INI file holds data for a number of different applications; each
application can have a number of keys; and associated with each key
there is a value, which is the thing the program actually wants to read.

:p.Historically, there was probably an intention to have all programs
save their INI data in one huge "user INI file", and in that case the
"application" part of the triple would have identified the program
owning that part of the data. These days we've learnt that concentrating
all the important data in a single central registry is bad design - it
leaves the system vulnerable to damage by a single misbehaving
program - so there's more of a tendency to use a separate INI file for
each program. This being the case, it would be logical to rename the
"application" to something like "section label", since it doesn't
identify an application in many cases; but we continue to call it the
"application" in order to be consistent with the existing documentation.

:p.The "value" part of the entry can be anything at all, depending on the
needs of the programmer who is using the INI file. It can be something
as simple as a one-byte binary value; it could also be a character string,
with or without a null terminating byte; or it could be a complex record
whose internal structure is known only to the programmer.

:p.The meaning of INI file data is usually not documented, because
programmers tend to see it as internal implementation detail. Before
modifying anything in an INI file, make sure that you understand what
the modification will do.

.***********************************
.*   INSTALLATION
.***********************************

:h1 id=Installation.Installation
:hp2.Installation:ehp2.

:p.These programs can be in any directory, so in a sense you have already
done the installation. You will probably find, though, that you want to
run them from several different directories. Naturally, you can do this
by giving a full path name on the command line, but this can be inconvenient.
It's probably better to move DumpINI.exe and LoadINI.exe to a directory
on your PATH.

:p.For example, my PATH (in CONFIG.SYS) contains D&colon.\Apps, and that is where
I place programs like top, zip, unzip, etc., that I run from multiple
places. So that is where I keep DumpINI and LoadINI.

:p.The TNItools subdirectory of this package contains some Rexx scripts
that are needed by some utilities that come with FtpServer, Weasel, and Major Major.
So those scripts, too, are best placed in a directory on your PATH.

.***********************************
.*   RUNNING DUMPINI
.***********************************

:h1 id=DumpINI.Running DumpINI
:hp2.Running DumpINI:ehp2.

:p.The DumpINI program takes a single argument, which is the name
of the INI file to be translated. The ".INI" part of the file
name is optional. So, for example, the command
:xmp.
dumpini Admin
:exmp.
takes its information from the file "Admin.INI", and produces an
output file called "Admin.TNI". If the TNI file already existed, the
old version is renamed with a ".TNI.BAK" extension.

:p.If no argument is given, the program looks for the first INI
file in the current directory. If there is no such file, the
program fails without doing anything.

.***********************************
.*   RUNNING LOADINI
.***********************************

:h1 id=LoadINI.Running LoadINI
:hp2.Running LoadINI:ehp2.

:p.The LoadINI program takes a simgle argument, which is the name
of the TNI file to be translated. The ".TNI" part of the file
name is optional. So, for example, the command
:xmp.
loadini Admin
:exmp.
takes its information from the file "Admin.TNI", and produces an
output file called "Admin.INI". If the INI file already existed, the
old version is renamed with a ".INI.BAK" extension.

:p.If no argument is given, the program looks for the first TNI
file in the current directory. If there is no such file, the
program fails without doing anything.

:note.LoadINI will fail if it cannot delete the old INI file. This
means, for example, that it will not replace either of the system
files OS2.INI or OS2SYS.INI, because those files normally have
the file attributes "read-only" and "system". If you really want to
replace one of those files, you must first rename it, or
turn off the attributes that prevent it from being deleted.

:p.Even if it were possible for LoadINI to do this automatically,
it is probably safer to leave the standard safeguards in place.

.***********************************
.*   TNItools
.***********************************

:h1 id=TNItools.TNItools
:hp2.TNItools:ehp2.

:p.It is common enough for an application program to come with some
Rexx scripts that perform simple utility functions. Sometimes those
scripts need to access INI data. (For example, some of the Weasel
tools need to look up the location of the mail root directory.)
There are Rexx utility functions that allow working with INI files,
but of course they can't handle TNI files. The TNItools directory
of the GenINI package fills that gap.

It is, by the way, desirable to move those TNItools scripts to a
directory on your PATH. That ensures that they can be found by
any Rexx code that calls them.

:p.These tools are described below.

:dl break=all.

:dt.SelectTNI.cmd
:dd.This decides whether to use an INI or a TNI file, using the
rules described in
:link reftype=hd refid=selectionrules.the following section:elink..

:dt.INI_val.cmd
:dd.This fetches a value from an INI or TNI file. It also has options
to fetch a list of all applications, or all keys for a given application.

:dt.INIput.cmd
:dd.This stores a value into an INI or TNI file.

:dt.INIdel.cmd
:dd.This deletes an item from an INI or TNI file. It also has options
to delete all keys or all applications.

:edl.

:note.In an earlier version of this software, INI_val.cmd was called INIget.cmd.
It had to be renamed because of a name conflict with other software. If you
have existing scripts that call INIget, you will have to update them to call
INI_val instead.

.***********************************
.*   CHECKING THE VERSION
.***********************************

:h1 id=selectionrules.The selection rules
:hp2.The selection rules:ehp2.

:p.If a program is designed to accept configuration data in either
INI or TNI format, how does it decide which one to use? Of course
one could always decide that the choice should be specified with a
command-line parameter, but it is simpler to have a set of rules
that do not require a parameter to be supplied.

:p.The rules that I prefer, and are built into SelectTNI.cmd, work
as follows. Suppose that an application myprog.exe can get its data
from either myprog.ini or myprog.tni. The SelectTNI rules
work as follows.

:ol.
:li.If only one of myprog.ini and myprog.tni exists, then that is the
one that will be used.
:li.If neither file exists, we default to choosing INI format.
:li.If both exist, then we consult the entry ($SYS, UseTNI) in
each file. This entry, if present, will use 0 to mean INI and
a nonzero value (usually 1) to mean that TNI format should be used.
If only one of the files has such an entry, or if both entries
exist and agree with each other, then that gives us a decision.
:li.If this still does not give a decision, then we default to
using INI format.
:eol.

:p.Ideally, the myprog software should provide a way to insert a
value for ($SYS, UseTNI) into either or both of myprog.ini and
myprog.tni (especially if both exist), so that the user has a
clear idea of which way the Rule 3 decision is going to go.

.***********************************
.*   CHECKING THE VERSION
.***********************************

:h1 id=CheckVersion.Checking the version
:hp2.Checking the version:ehp2.

:p.You can discover which version of GenINI you have installed with
the bldlevel command. At a command prompt, type one of the following
commands:
:xmp.
    bldlevel LoadINI.exe
    bldlevel DumpINI.exe
:exmp.


.***********************************
.*   FORMAT OF A TNI FILE
.***********************************

:h1 id=TNIFormatDescription.The format of a TNI file
:hp2.The format of a TNI file:ehp2.

:p.A TNI file continues to divide the information into "applications",
in the same way that the INI file does. If there are two applications
called App1 and App2, then the TNI file has the form
:xmp.
[App1]
    <key values for App1>
[/App1]
[App2]
    <key values for App2>
[/App2]
:exmp.
where the parts listed as <key values for App1> and <key values for App2>
will be further described below. That is, each application section
starts with the application name in square brackets, and ends with a
similar label where the character '/' comes ahead of the application
name.

:p.Except for one special case, to be described below, the value for
each key within an application is specified by a line of the form
:xmp.
    key=value
:exmp.
where the "key" part is the name of the key, and the "value" part can
be one of the following:
:ul.
:li.A decimal number, or a space-separated list of decimal numbers.
In this case, it is implied that each number takes four bytes, and is
stored in the INI file with the least significant byte first.
:li.The characters (N), where N is a small decimal number, followed
by one or more decimal numbers separated by spaces. This is the same
as the previous case, except that N specifies the number of bytes to
be used to hold each number. So, for example, a one-byte number with value 25, stored
with the key name "option", would appear in the TNI file as
:xmp.
    option=(1)25
:exmp.
:li.The characters (X), where this time the X is to be taken
literally, followed by one or more one-byte numbers in hexadecimal
notation.
:li.A character string, which might or might not be delimited with
quote characters (either ' or "). The quote characters are needed only
if there is a potential ambiguity (e.g. a string consisting of numeric
digits), or if the string itself contains space characters or one or both of the quote
characters. If necessary, the string is broken up into substrings
connected by the concatenation operator "+". (Very long strings are
broken up, as are strings containing both kinds of quotation mark.
Quotation marks are also used when needed to resolve an ambiguity, for
example when a string starts with a digit or contains a space character.)
:eul.

:p.If the "+" is the last non-space character then the string is
continued on the next line.

:p.:hp2.Remark:ehp2. A nul-terminated string is recorded as a
quoted string, with the digit 0 after the closing quotation mark.

:p.It was mentioned above that there is one special case that does
not fit into any of the above patterns. This is a data item that can
be thought of as a "string of strings". (Or, if you prefer, a
one-dimensional array of text strings.) Each individual string is
terminated in the INI file with a Nul character (a single byte whose
value is zero). The overall concatenation is terminated with an
extra Nul character, so that the sequence normally finishes with two Nul
characters. Empty strings are not permitted in this format; but an
empty "string of strings" is possible, in which case the value is a
single Nul.

:p.(If you do need an empty string with this format, a good compromise is
to make it a nul-terminated empty string, written as ''0.)

:p.In the TNI file, a string of strings is written as an extra level
of nesting, as shown in the following example.
:xmp.
    [key]
       first string
       second string
       third string
    [/key]
:exmp.

:p.For ease of readability, information in a TNI file is indented with
the aid of leading space characters. The leading space is not
compulsory, however, and those space characters are ignored by LoadINI.

.***********************************
.*   THE FORMAT FILE
.***********************************

:h1 id=FormatFiles.Format files
:hp2.Format files:ehp2.

:p.As noted in the preceding section, the data in a TNI file can have
several different formats, depending on whether the values represent
a text string, a sequence of bytes, a sequence of multibyte values,
and so on. There is, however, no corresponding format information in
an INI file. That means that the DumpINI program must make its best
guess about what format to use.

:p.If DumpINI makes a wrong guess, no harm is done, because whatever
it writes can still be read back by LoadINI. Nevertheless, the TNI file
is more readable by humans if the "right" format is chosen. For this
reason, DumpINI will read a format file if it is available, for information
about what format to use. The format file has the same name as the INI
file, except that the name ends in ".FMT" instead of ".INI".

:p.A format file looks just like a TNI file, except that
:ul.
:li.It does not have to have an entry for each application and key, only
for those where you want to override the default assumptions. Usually
this means that only a small number of applications and keys are listed.
:li.Where the TNI file has lines of the form "key=value", the corresponding
FMT file has lines of the form "key=format code", where there is only a
small number of possible format codes.
:eul.

:p.The available format codes are
:ul.
:li.The single quote character ' to indicate that the value is a string.
:li.The pair '0 to indicate that the value is a nul-terminated string.
:li.The double quote character " to indicate that the value is a string of strings.
:li.The code (X) to indicate that the value is a sequence of bytes, to be listed
in hexadecimal in the TNI file.
:li.The code (N), where N is a small decimal number, to indicate that the value
should be broken up into a sequence of N-byte numbers, to be listed in decimal
in the TNI file.
:li.The code (), which is the same as (N) but for the special case N=4.
That is, (4) and () mean the same thing.
:eul.

.***********************************
.*   THE FORMAT FILE
.***********************************

:h1 id=INIFormat.Appendix: The format of an INI file
:hp2.Appendix: The format of an INI file:ehp2.

:p.To the best of my knowledge, there is no official specification
of the format of a binary OS/2 INI file. The information we have
is based on "reverse engineering" based on examining binary dumps of
INI files.

:p.The following description is based mostly on information
supplied by James J. Weinkam <jjw@cs.sfu.ca>. That information was
published in the VOICE newsletter of September 2004
(http&colon.//www.os2voice.org//vnl/past_issues/VNL0904H/vnewsf4.htm).
The "I" in the following description refers to his description.

:p.OS/2 INI files consist of groups of key=value pairs grouped by
application.  The application names and keys are null terminated
strings.  The values may be arbitrary binary data.

:p.:hp2.File format&colon.:ehp2.

:p.The following format information was derived by examining and
experimenting with copies of several actual ini files in the OS/2
system and several other ini files constructed for the purpose.
There are a number of apparently unused fields.  It is possible
that some of these fields are used for purposes which did not
come up in the various ini files that I examined.

:p.:hp2.File descriptor section&colon.:ehp2.

:xmp.
32 bit integer   Signature?            FFFFFFFF
32 bit integer   Offset of first app   00000014
32 bit integer   File size
32 bit integer   Unused?               00000000
32 bit integer   Unused?               00000000
:exmp.

:p.:hp2.Application descriptor:ehp2.

:xmp.
32 bit integer   Next app
32 bit integer   First pair
32 bit integer   Unused?               00000000
16 bit integer   Name length           nnnn
16 bit integer   Name length           nnnn
32 bit integer   Offset of name
nnnn bytes       App name              Name followed by nul
:exmp.

:p.:hp2.Pair descriptor:ehp2.

:xmp.
32 bit integer   Next pair
32 bit integer   Unused?               00000000
16 bit integer   Key length            kkkk
16 bit integer   Key length            kkkk
32 bit integer   Offset of key
16 bit integer   Value length          vvvv
16 bit integer   Value length          vvvv
32 bit integer   Offset of value
kkkk bytes       Key                   Key followed by nul
vvvv bytes       Value                 Value
:exmp.

:p.:hp2.Notes&colon.:ehp2.

:p.The value may but need not be terminated with a nul.  The name
and key fields must have a terminating nul.  In all cases the
length includes the terminating nul if there is one.

:p.The value 00000000 is used to terminate the application list and
each application's pair list.

:p.There is considerable redundancy in this design.  In all the
examples I have looked at the first application descriptor
immediately follows the file descriptor and the application name
immediately follows the application descriptor, each
application's pair list immediately follows the application
name and each pair's key and value immediately follow its
descriptor.  Thus the offset fields are not really needed.  Also
the length of the name, key, and value fields are recorded twice
for no apparent reason.

:p.The value field is always vvvv bytes in length.  On the other
hand, if a hex editor is used to introduce a nul prior to the
nnnn-th byte of a name field or the kkkk-th byte of a key field,
that null will terminate the name or key, the length fields will
be adjusted accordingly and the extra bytes eliminated the next
time the file is written out.  The API calls do not enforce any
other restrictions on the content of the name and key fields
although the use of ascii values between 1 and 31 inclusive or
greater than 127 in these fields may present challenges in some
situations.

:p.No information about the "type" of the value field is stored.
The API calls allow values to be stored as strings or binary
values and retrieved as string, binary, or 32 bit integer.
However, any value can be retrieved as binary no matter how it
was stored and an attempt to retrieve a value as a string or
integer will fail unless the actual data can be validly
interpreted as such.  In the case of string this means that the
last byte must nul and no other bytes may be.  In the case of
integer it means that the length must be 4.

:euserdoc.

