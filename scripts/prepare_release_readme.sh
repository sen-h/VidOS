#!/bin/bash

INSTRUCTIONS_START=$(( $(grep -n "# Getting Started" README.md | cut -d ":" -f1)+1 ))
INSTRUCTIONS_END=$(( $(grep -n "# Bootloader" README.md | cut -d ":" -f1)-1 ))

tail -n +$INSTRUCTIONS_START README.md | head -n $(($INSTRUCTIONS_END-$INSTRUCTIONS_START)) > instructions

sed -e '/# Getting Started/r instructions' release_paperwork/readme_template > release_paperwork/README.md

rm instructions
