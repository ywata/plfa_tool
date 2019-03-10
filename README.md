# plfa_tool
Some scripts for PLFA

## generate_unicode.pl

### Usage of `generate_unicode.pl`

`generate_unicode.pl` provides two main input format.

#### 1. Showing or updating unicode instruction

`generate_unicode.pl [--debug|--update] chapter_file unicode_instruction_file`

With this format, the perl script shows or updates unicode instructions for unicode characters
that are found in a file.
chapter_file contains order of chapter file to be parsed.
Each line should contain an integer and file name. Instruction of a unicode in a file is shown
if the unicode is appeared at most the number. This script assumes the number is in decreasing order.

`generate_unicode.pl chapter_file unicode_instruction_file`

This format shows unicode instructions on screen.

`generate_unicode.pl --update chapter_file unicode_instruction_file`

This format updates unicode instructions in files specified in `f`.

`generate_unicode.pl --debug chapter_file unicode_instruction_file`

This format shows all the unicode instructions that appears in files specified in `f` on screen.
Usig this format, you can check all the unicode characters that appeared have expected unicode instruction.
If unicode instruction is not defined unicode_instruction_file, you will see
`C not found` where `C` is a unicode character.

`generate_unicode.pl --debug --update chapter_file unicode_instruction_file`

This format updates unicode instructions to all the unicode instructions that appears in files specified in `f` on screen.


#### 2. Showing missing unicode codepoint and name.

`generate_unicode.pl unicode_instruction_file`

With this format, the perl script shows unicode code point and unicode character name if
a unicode character is in a line. This helps you when new unicode character is added in a file.

### Expected work flow

- To check all the expected unicode characters are defined in unicode_instruction_file.
  Use ```generate_unicode.pl --debug chapter_file unicode_instruction_file```.
- To add missing unicode instruction to unicode_instruction_file,
  put the character at the end of unicode_instruction_file and run
  ```generate_unicode.pl unicode_instruction_file```
  Please copy the lines printed on scree to unicode_instruction_file.
- To update unicode instruction defined in .lagda flle, use
  ```generate_unicode.pl --update chapter_file unicede_instruction_file```
  Please run `git diff` to see if the changes are OK.

