#!/bin/bash

f=$(pwd)


mkdir $f/maps
mkdir $f/comm
mkdir $f/tmpl
mkdir $f/meta
mkdir $f/lists
mkdir $f/masks
mkdir $f/temp


echo "vol_ext=.mrc" > $f/tm_settings.txt
echo "fourier_crop=false" >> $f/tm_settings.txt
