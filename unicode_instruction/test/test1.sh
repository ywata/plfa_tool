#!/bin/bash

git checkout .
../generate_unicode.pl test1.chap test1.unicode > test1.org
git diff test1.org


../generate_unicode.pl --update test1.chap test1.unicode
git diff [1-7].org > test1.diff
git diff test1.diff



