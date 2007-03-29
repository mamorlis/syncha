#!/bin/sh
# Created on 5 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

[ "$#" -ne 1 -o "$1" == '-h' ] && echo "usage: $0 prefix" && exit 1

prefix=$1

train_dat=${prefix}_train.dat
train_log=${prefix}_train.log
train_bac=`basename $prefix`_train.bac
train_bin=`basename $prefix`_train.bin
test_dat=${prefix}_test.bact.dat
test_log=${prefix}_test.bact.log

bact_learn -T 3000 -m 5 -L 4 $train_dat $train_bac
bact_mkmodel -i $train_bac -o $train_bin -O ${train_bin}.O
features=`head -n 1 $train_log | sed -e 's/.*(//' -e 's/).*//'`
./classify_tournament.pl -i -b $train_bin -f $features >$test_dat 2>$test_log
