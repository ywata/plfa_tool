# plfa_tool
Some scripts for PLFA

## generate_unicode.pl

`generate_unicode.pl` provides two main input format.

1.

`generate_unicode.pl [--debug|--update] chapter_file unicode_instruction_file`
With this format, the perl script shows or updates unicode instructions for unicode characters
that are found in a file.
chapter_file contains order of chapter file to be parsed.
Each line should contain an integer and file name. Instruction of a unicode in a file is shown
if the unicode is appeared at most the number. This script assumes the number is in decreasing order.

`generate_unicode.pl f u` :
This format shows unicode instructions on screen.

`generate_unicode.pl --update f u` :
This format updates unicode instructions in files specified in `f`.

`generate_unicode.pl --debug f u` :
This format shows all the unicode instructions that appears in files specified in `f` on screen.

`generate_unicode.pl --debug --update f u` :
This format updates unicode instructions to all the unicode instructions that appears in files specified in `f` on screen.


2.
`generate_unicode.pl unicode_instruction_file`
With this format, the perl script shows unicode code point and unicode character name if
a unicode character is in a line. This helps you when new unicode character is added in a file.
