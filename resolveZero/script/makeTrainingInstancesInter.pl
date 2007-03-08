#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
use GDBM_File;

my $usage = <<USG;
文間のゼロ照応をSCMで解析するための訓練事例を作成．
./make_ex_svm_inter.pl -d expr_dir -n #num -T {GA,WO,NI}
-m: mod_dir
-f: fill_zero
USG

# my $host = `hostname`; chomp $host;
# die "run at fir.nait.jp\n" if ($host ne 'fir.naist.jp');

my %options;
getopts("d:n:T:m:hf", \%options);
die $usage if ($options{h});
die $usage unless ($options{d});
die $usage unless ($options{n});
die $usage unless ($options{T});
die $usage if ($options{T} !~ m/^(?:GA|WO|NI)$/);
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

# my $path = __FILE__; $path =~ s|[^/]+$||;
# unshift @INC, $path; require 'common.pl';
# require 'mod.pm'; 
# # require 'mod2.pm'; 
# require 'Center.pm';
# require 'ext_fe.pl'; require 'Cab.pm';

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

    my %num2fe = ();
    for (my $tid=0;$tid<$t_num;$tid++) {
	print STDERR 'tid: ', $tid, "\n";
	my $t = $t[$tid]; my @s = @{$t->Sentence}; my $s_num = @s;
	# 文間ゼロ代名詞を持つ述語にmarkする
	&mark_inter_zero($t);
	my $num = $tid % $options{n};
	my $cl = Center->new; # Center List
	for (my $sid=1;$sid<$s_num;$sid++) { # from $sid = 1 : $sid = 0 は文内ゼロ照応の問題として解く．
	    my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	    for (my $bid=0;$bid<$b_num;$bid++) {
		my $b = $b[$bid];

		if ($b->PRED_ID and $b->{'ZERO_INTER_'.$options{T}} and 
		    &check_dep_case($b, $options{T}) == 0) {
		    
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
		    
		    my @out = &ext_fe_svm_inter($t, $s, $pred, $options{T}, $cl);

# 		    use Data::Dumper;
# 		    print Dumper @out;
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

sub ext_fe_svm_inter {
    my ($t, $s, $pred, $case, $cl) = @_; # $case: GA, WO, NI

#     my @b = @{$s->Bunsetsu}; my $b_num = @b;

    my @c = &ext_inter_candidates($t, $pred); my $c_num = @c;
    return () unless (@c);

#     my @s = @{$t->Sentence}; my $s_num = @s;
#     for (my $sid=0;$sid<$s_num;$sid++) {
# 	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
#     }

#     # debug:
#     print STDERR 'debug: ', "\n";
#     my @s = @{$t->Sentence}; my $s_num = @s;
#     for (my $sid=0;$sid<=$pred->sid;$sid++) {
# 	my $s = $s[$sid]; print STDERR $s->STRING, "\n";
	
#     }
#     # end:
#     print STDERR 'cands: ', "\n";
#     print STDERR join("\t", map $_->bid, reverse @c), "\n\n";

    my %out = (); my $ant; my $looked = 0; my @wrg = ();

    # 最も近い正解のみを利用
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	if ($c[$cid]->ID and $c[$cid]->ID eq $pred->{$case}) {
	    if ($looked == 0) {
		$ant = $c[$cid]; $looked = 1;
		for my $wr (@wrg) {
		    # right; wr, left: ant
		    my $fe = &ext_features_comp($pred, $wr, $ant, $cl, $s, $case, \%options);
# 		    my $fe = &ext_features_svm_inter_t($pred, $wr, $ant, $cl, $t, $case, \%options);
		    $out{'-1 '.$fe} = 1; # ant がleftのときに -1
		}
	    } else { # $look == 1 and 先行詞 のときは何もしない
	    }
	} elsif ($looked == 1) {
	    my $wr = $c;
	    # wr が ant より前に出現．
	    my $fe = &ext_features_comp($pred, $ant, $wr, $cl, $s, $case, \%options);
# 	    my $fe = &ext_features_svm_inter_t($pred, $ant, $wr, $cl, $t, $case, \%options);
	    $out{'+1 '.$fe} = 1; # ant がrightのときに -1
	} else { # $looked == 0
	    push @wrg, $c;
	}
    }
    return keys %out;
}

sub output_fes {
    my $feref = shift;
    for (my $num=0;$num<$options{n};$num++) {
	open 'OUT', '>'.$options{d}.'/fe_inter_t_'.$num.'_'.$options{T};
	my %cfe = %{$feref->{$num}};
	print OUT map $_."\n", keys %cfe;
	close OUT;
    }
    return;
}

# sub output_num {
#     my %fe2num = (); my $f_num = 1;
#     for (my $num=0;$num<$options{n};$num++) {
# 	open 'FE', $options{d}.'/fe_inter_t_'.$num;
# 	open 'OUT', '>'.$options{d}.'/num_inter_t_'.$num;
# 	$/ = "\n";
# 	while (<FE>) {
# 	    chomp;
# 	    my ($val, @fe) = split ' ', $_; my %num = ();
# 	    for my $fe (@fe) {
# 		my ($fname, $fval) = split '\:', $fe;
# 		$fe2num{$fname} = $f_num++ unless ($fe2num{$fname});
# 		unless ($fval) {
# 		    die $fe."\n";
# 		}
# 		$num{$fe2num{$fname}.':'.$fval} = 1;
# 	    }
# 	    print OUT $val.' '.join(' ', sort {(split '\:', $a)[0] <=> (split '\:', $b)[0]} keys %num)."\n";
# 	}
# 	close FE; close OUT;
#     }
#     unlink $options{d}.'/f2n_t.gdbm' if (-e $options{d}.'/f2n_t.gdbm');

#     tie my %FE2NUM, 'GDBM_File', $options{d}.'/f2n_t.gdbm', GDBM_WRCREAT, 0644 or die $!;
#     %FE2NUM = %fe2num;
#     untie %FE2NUM;

#     tie my %NUM2FE, 'GDBM_File', $options{d}.'/n2f_t.gdbm', GDBM_WRCREAT, 0644 or die $!;
#     while (my ($fe, $num) = each %fe2num) { $NUM2FE{$num} = $fe; }
#     untie %NUM2FE;
#     return;
# }

sub output_train {
    for (my $num=0;$num<$options{n};$num++) {
	open 'TRN', '>'.$options{d}.'/train_inter_t_'.$num;
	for (my $i=0;$i<$options{n};$i++) {
	    next if ($options{n} != 1 and $num == $i);
	    open 'NUM', $options{d}.'/fe_inter_t_'.$i;
	    $/ = "\n";
	    while (<NUM>) { print TRN $_; }
	    close NUM;
	}
	close TRN;
    }
    return;
}
