#!/bin/sh
targetDir="/Applications/World of Warcraft/Interface/AddOns/Vic/"
files="Vic.lua Vic.toc Vic.xml"

for f in $files 
do
diff "$targetDir"$f $f
cp -v $f "$targetDir"
done

