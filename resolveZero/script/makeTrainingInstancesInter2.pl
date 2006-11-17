#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;
use GDBM_File;

my $usage = <<USG;
./make_ex_svm_inter2.pl -d expr_dir -n #num -T {GA,WO,NI}
-m: mod_dir
-f: fill_zero
USG

my %options;
getopts("d:n:T:m:hf", \%options);
die $usage if ($options{h});
die $usage unless ($options{d});
die $usage unless ($options{n});
die $usage unless ($options{T});
die $usage if ($options{T} !~ m/^(?:GA|WO|NI)$/);
# $options{t} = 0 unless ($options{t});
# die $usage if ($options{t} != 0 and $options{t} != 1);
die $usage unless ($options{m});

$options{b} = 1; ## default

# my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
my $scriptPath = __FILE__; $scriptPath =~ s|//|/|g;
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
unshift @INC, $scriptPath;
require 'common.pl';
require 'openModFile.pl';
require 'centerList.pl';
require 'extractFeatures.pl';
require 'cab.pl';

&main;

sub main {
    my $num2fe = &ext_num2fe;
    &output_fes($num2fe);
#     &output_num;
#     &output_train;
}

sub ext_num2fe {
    my $m = Mod->new($options{m}); my @t = @{$m->txt}; my $t_num = @t;
#     my $m2 = Mod2->new($path); my @t2 = @{$m2->txt}; 
#     push @t, @t2; my $t_num = @t;

    my @m = &open_model_inter_t($options{d}, $options{T});
#     my $f2n_t = &open_f2n_inter_svm_t($options{d});

    my %num2fe = ();
    for (my $tid=0;$tid<$t_num;$tid++) {
	print STDERR 'tid: ', $tid, "\n";
	my $t = $t[$tid]; my @s = @{$t->Sentence}; my $s_num = @s;
	# 文間ゼロ代名詞を持つ述語にmarkする / 文内ゼロ代名詞にもmarkする
	&mark_inter_zero($t); &mark_zero($t);	
	my $num = $tid % $options{n};
	my $cl = Center->new; # Center List
	for (my $sid=0;$sid<$s_num;$sid++) {
	    my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	    for (my $bid=0;$bid<$b_num;$bid++) {
		my $b = $b[$bid];
		
# 		if ($b->PRED_ID and $b->{$options{T}} and
# 		    !$options{'ZERO_'.$options{T}} and 
# 		    &check_dep_case($b, $options{T}) == 0) {
		
		if ($b->PRED) {
# 		    !$options{'ZERO_'.$options{T}} and 
# 		    &check_dep_case($b, $options{T}) == 0) {

		    my $val = ($b->{'ZERO_INTER_'.$options{T}})? '+1' : '-1';

		    # IN_QUOTE
		    if ($options{I} and $b->IN_QUOTE == 0) {
			$cl->add($b) if ($b->NOUN);
			next;
		    }

		    my $S = $s; my $pred = $b;
		    if ($options{f}) {
			# 前文までのゼロを補完する．
			$t = &fill_zero_text($t, $sid, $b); # $s[$i] = $S; 
		    }
		    
# 		    my $fe = &ext_fe_svm_inter2($t, $s, $pred, $options{T}, $cl, $m[$num], $f2n_t);
		    my $fe = &ext_fe_svm_inter2($t, $s, $pred, $options{T}, $cl, $m[$num]);
		    $num2fe{$num}{$val.' '.$fe} = 1 if ($fe);
		}
		$cl->add($b) if ($b->NOUN);
	    }
	}
    }
    return \%num2fe;
}

sub ext_fe_svm_inter2 {
    my ($t, $s, $pred, $case, $cl, $m) = @_; # $case: GA, WO, NI

    my @c = &ext_inter_candidates($t, $pred); # my $c_num = @c;
    return () unless (@c);

#     my %out = (); my $ant; my $looked = 0; my @wrg;

    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	# $c: left, $ant: right
# 	my $fe = &ext_features_svm_inter_t($pred, $ant, $c, $cl, $t, $case, \%options);
	my $fe = &ext_features_comp($pred, $ant, $c, $cl, $s, $case, \%options);
	my $testfile = $options{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `/home/ryu-i/tools/bact-0.13/bact_classify -v 3 $testfile $m`;
	my $score = (split ' ', (split '\n', $r)[1])[1];
	$ant = $c if ($score < 0);

# 	my $num = &fe2num($fe, $f2n);
# 	my $res = $m->classify($num);
# 	$ant = $c if ($res < 0);
    }

#     my $fe = &ext_features_svm_inter($pred, $ant, $cl, $t, $case, \%options);
    my $fe = &ext_features_one($pred, $ant, $cl, $s, $case, \%options);
    return $fe;
}

sub output_fes {
    my $feref = shift;
    for (my $num=0;$num<$options{n};$num++) {
	open 'OUT', '>'.$options{d}.'/fe_inter_'.$num.'_'.$options{T};
 	my %cfe = %{$feref->{$num}};
 	print OUT map $_."\n", keys %cfe;
	close OUT;
    }
    return; 
}

# sub output_num {
#     my %fe2num = (); my $f_num = 1;
#     for (my $num=0;$num<$options{n};$num++) {
# 	open 'FE', $options{d}.'/fe_inter_'.$num.'_t'.$options{t};
# 	open 'OUT', '>'.$options{d}.'/num_inter_'.$num.'_t'.$options{t};
# 	$/ = "\n";
# 	while (<FE>) {
# 	    chomp;
# 	    my ($val, @fe) = split ' ', $_; my %num = ();
# 	    for my $fe (@fe) {
# 		my ($fname, $fval) = split '\:', $fe;
# 		$fe2num{$fname} = $f_num++ unless ($fe2num{$fname});
# 		$num{$fe2num{$fname}.':'.$fval} = 1;
# 	    }
# 	    print OUT $val.' '.join(' ', sort {(split '\:', $a)[0] <=> (split '\:', $b)[0]} keys %num)."\n";
# 	}
# 	close FE; close OUT;
#     }
#     unlink $options{d}.'/f2n_t'.$options{t}.'.gdbm' 
# 	if (-e $options{d}.'/f2n_t'.$options{t}.'.gdbm');
    
#     tie my %FE2NUM, 'GDBM_File', $options{d}.'/f2n_t'.$options{t}.'.gdbm', 
#     GDBM_WRCREAT, 0644 or die $!;
#     %FE2NUM = %fe2num;
#     untie %FE2NUM;

#     unlink $options{d}.'/n2f_t'.$options{t}.'.gdbm'
# 	if (-e $options{d}.'/n2f_t'.$options{t}.'.gdbm');
#     tie my %NUM2FE, 'GDBM_File', $options{d}.'/n2f_t'.$options{t}.'.gdbm', 
#     GDBM_WRCREAT, 0644 or die $!;
#     while (my ($fe, $num) = each %fe2num) { $NUM2FE{$num} = $fe; }
#     untie %NUM2FE;
#     return;
# }

sub output_train {
    for (my $num=0;$num<$options{n};$num++) {
	open 'TRN', '>'.$options{d}.'/train_inter_'.$num; # .'_t';
	for (my $i=0;$i<$options{n};$i++) {
	    next if ($num == $i);
	    open 'NUM', $options{d}.'/fe_inter_'.$i;
	    $/ = "\n";
	    while (<NUM>) { print TRN $_; }
	    close NUM;
	}
	close TRN;
    }
    return;
}
