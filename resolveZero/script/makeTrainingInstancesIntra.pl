#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

my $usage = <<USG;
./makeTrainingInstancesIntra.pl -d expr_dir -n #num -T {GA,WO,NI}
-m: mod_dir
-f: fill_zero in advance
-b: baseline (no structure)
-p: depencency structure
-I: extract features from predicates which are in a direct quote

USG

# my $host = `hostname`; chomp $host;
# die "run at fir.naist.jp\n" if ($host ne 'fir.naist.jp');

my %options;
getopts("d:n:T:m:hfbsSIp", \%options);
die $usage if ($options{h});
die $usage unless ($options{d});
die $usage unless ($options{n});
die $usage unless ($options{T});
die $usage if ($options{T} !~ m/^(?:GA|WO|NI)$/);
die $usage unless ($options{m});

# print STDERR 'test2: ', $0, "\n";

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
    &output_opt('make_ex_bact_comp', \%options);
    my $num2fe = &ext_num2fe;
    &output_fes($num2fe);
#     &output_train;
}

sub ext_num2fe {
    my $m = Mod->new($options{m}); my @t = @{$m->txt};
    my $t_num = @t;

    my %num2fe = ();
    for (my $tid=0;$tid<$t_num;$tid++) {
	print STDERR 'tid: ', $tid, "\n";
	my $t = $t[$tid]; my @s = @{$t->Sentence}; my $s_num = @s;
	# 文内に先行詞を持つ述語にmarkする
	&mark_zero($t);
	my $num = $tid % $options{n};
	my $cl = Center->new; # Center List
	for (my $sid=0;$sid<$s_num;$sid++) {
	    my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	    for (my $bid=0;$bid<$b_num;$bid++) {
		my $b = $b[$bid];

# 		if ($b->PRED_ID and $b->{'ZERO_'.$options{T}} and 
# 		    &check_dep_case($b, $options{T}) == 0) {
#  		if ($b->PRED_ID and $b->{'ZERO_'.$options{T}}) {
 		if ($b->PRED_ID and $b->{$options{T}}) {

		    if ($options{I} and $b->IN_QUOTE == 0) {
			$cl->add($b) if ($b->NOUN);
			next;
		    }
#  		    my $S = &fill_zero($s, $b) if ($options{f}); 
		    my $S; my $pred;
		    if ($options{f}) {
# 			$s = ($options{f})? &fill_zero($s, $b) : $s;
			($S, $pred) = &fill_zero($s, $b);
		    } else {
			$S = $s; $pred = $b;
		    }

# 		    $NUM++;
# 		    my @B = @{$s->Bunsetsu}; my $B = $B[$bid];

		    my @out = &ext_fe_bact($S, $pred, $options{T}, $cl);

# 		    for my $o (@out) {
# 			print STDERR 'out: ', $o, "\n";
# 		    }
		    if (@out) {
			for my $o (@out) { $num2fe{$num}{$o} = 1; }
		    }
		}
		# after making training instances, add noun to CenterList
		$cl->add($b) if ($b->NOUN);
	    }
	}
    }
    return \%num2fe;
}

sub ext_fe_bact {
    my $s = shift; my $pred = shift; # Bunsetsu
    my $case = shift; # GA, WO, NI
    my $cl = shift; # Center List
    my @b = @{$s->Bunsetsu}; my $b_num = @b;
    # extract candidates
    my @c = &ext_candidates_including_dep($s, $pred); my $c_num = @c;
    return () unless (@c); # ここ本当にこんなことしてOK?

    my %out = ();

#     for (my $cid=0;$cid<$c_num;$cid++) {
# 	my $c = $c[$cid]; &mark_path($pred, $c, $s); # ???
#     }
    
    # 各先行詞ごとに比較する(複数の先行詞の存在を仮定する)
    for (my $cid=0;$cid<$c_num;$cid++) {
	if ($c[$cid]->ID and $c[$cid]->ID eq $pred->{$case}) {
	    my $ant = $c[$cid];
	    for (my $CID=0;$CID<$c_num;$CID++) {
		next if ($cid == $CID);
		next if ($c[$CID]->ID and $c[$CID]->ID eq $pred->{$options{T}});
		my $wr = $c[$CID];
		if ($cid < $CID) { # つまり cid(ant) よりも CID(wr) が文の前方にある．
		    my $fe = &ext_features_comp($pred, $ant, $wr, $cl, $s, $case, \%options);
		    $out{'+1 '.$fe} = 1;


		} else { # $cid > $CID
		    my $fe = &ext_features_comp($pred, $wr, $ant, $cl, $s, $case, \%options);
		    $out{'-1 '.$fe} = 1;
		}
	    }
	}
    }

#     for (keys %out) {
# 	print STDERR 'fe: ', $_, "\n";
#     }

    return keys %out;
}

sub output_fes {
    my $feref = shift;
    for (my $num=0;$num<$options{n};$num++) {
        open 'OUT', '>'.$options{d}.'/fe_t_'.$num.'_'.$options{T};
        my %cfe = %{$feref->{$num}};
        print OUT join "\n", keys %cfe;
        print OUT "\n";
        close OUT;
    }
    return;
}

sub output_train {
    for (my $num=0;$num<$options{n};$num++) {
        open 'TRN', '>'.$options{d}.'/train_t_'.$num.'_'.$options{T};
        for (my $i=0;$i<$options{n};$i++) {
            next if ($options{n} != 1 and $num == $i);
            open 'NUM', $options{d}.'/fe_t_'.$i.'_'.$options{T};
            $/ = "\n";
            while (<NUM>) { print TRN $_; }
            close NUM;
        }
        close TRN;
    }
    return;
}
