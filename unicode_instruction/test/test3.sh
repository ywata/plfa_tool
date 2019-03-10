#!/bin/bash

git checkout .
../generate_unicode.pl test1.chap test1.unicode
echo $?

../generate_unicode.pl test3.chap test3.unicode
echo $?
