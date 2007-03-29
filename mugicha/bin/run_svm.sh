#!/bin/sh
# Created on 5 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

usage() {
    echo "$0 -p prefix [-r]"
    echo "  -r: use real number for SVM classification"
    exit 1
}

rflag=
while getopts rhp: opt ; do
    case $opt in
    r)  rflag='-r';;
    p)  prefix="$OPTARG";;
    ?)  usage;;
    esac
done

[ "$prefix" = "" ] && usage

train_dat=${prefix}_train.dat
train_log=${prefix}_train.log
train_bac=`basename $prefix`_train.bac
train_bin=`basename $prefix`_train.bin
score_dat=${prefix}_score.dat
score_log=${prefix}_score.log
test_dat=${prefix}_test.dat
test_log=${prefix}_test.log

train_svm_dat=${prefix}_train.svm.dat
train_svm_log=${prefix}_train.svm.log
train_svm_mod=${prefix}_train.svm.model
test_svm_dat=${prefix}_test.svm.dat
test_svm_log=${prefix}_test.svm.log
quad_svm_dat=${prefix}_quad.svm.dat
quad_svm_log=${prefix}_quad.svm.log

#bact_learn -L 5 $train_dat $train_bac
#bact_mkmodel -i $train_bac -o $train_bin
#features=`head -n 1 $train_log | sed -e 's/.*(//' -e 's/).*//'`
#./classify_tournament.pl -i -b $train_bin -f $features >$test_dat 2>$test_log

./bact2svm.pl ${rflag} ${train_dat} > ${train_svm_dat} 2> ${train_svm_log}
./bact2svm.pl ${rflag} -t ${train_svm_log} ${test_dat} > ${test_svm_dat} 2> ${test_svm_log}
./add_opt_feature.pl -t ${test_svm_log} ${train_svm_dat}
svm_learn -t 1 -d 2 ${train_svm_dat} ${train_svm_mod}
./calc_quadrant.pl -c ${score_dat} -m svm -b ${train_svm_mod} -s ${test_svm_dat} \
    > ${quad_svm_dat} 2> ${quad_svm_log}
