#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

my $usage = <<USG;
./make_ex_bact_comp2.pl -d expr_dir -n #num -T {GA,WO,NI}
-m: mod_dir
-f: fill_zero in advance
-b: baseline (no structure)
-l: league game
-p: depencency structure
-I: extract features from predicates which are in a direct quote
USG

# my $host = `hostname`; chomp $host;
# die "run at fir.naist.jp\n" if ($host ne 'fir.naist.jp');

my %options;
getopts("d:n:T:m:hfbslSIp", \%options);
die $usage if ($options{h});
die $usage unless ($options{d});
die $usage unless ($options{n});
die $usage unless ($options{T});
die $usage if ($options{T} !~ m/^(?:GA|WO|NI)$/);
die $usage unless ($options{m});

# my $path = __FILE__; $path =~ s|[^/]+$||;
# unshift @INC, $path; require 'common.pl';
# require 'mod.pm'; require 'mod2.pm'; require 'Center.pm';
# require 'ext_fe.pl'; require 'Cab.pm';

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
    &output_opt('make_ex_bact_comp2', \%options);
    my $num2fe = &ext_num2fe;
    &output_fes($num2fe);
#     &output_train;
}

sub ext_num2fe {
    my $m = Mod->new($options{m}); my @t = @{$m->txt}; # my $t_num = @t;
    my @m = &open_model_t_bact($options{d}, $options{T});
#     my $m2 = Mod2->new($path); my @t2 = @{$m2->txt}; 
#     push @t, @t2; 
    my $t_num = @t;

    my %num2fe = ();
    for (my $tid=0;$tid<$t_num;$tid++) {
	print STDERR 'tid: ', $tid, "\n";
	my $t = $t[$tid]; my @s = @{$t->Sentence}; my $s_num = @s;
	&mark_zero($t);
	my $num = $tid % $options{n};
	my $cl = Center->new; # Center List
	for (my $sid=0;$sid<$s_num;$sid++) {
	    my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	    for (my $bid=0;$bid<$b_num;$bid++) {
		my $b = $b[$bid];

# 		if ($b->PRED_ID and $b->{$options{T}} and 
# 		    &check_dep_case($b, $options{T}) == 0) {
		if ($b->PRED_ID) {
# 		    and $b->{$options{T}} and 
# 		    &check_dep_case($b, $options{T}) == 0) {

		    if ($options{I} and $b->IN_QUOTE == 0) {
			$cl->add($b) if ($b->NOUN);
			next;
		    }
# 		    my $S = &fill_zero($s, $b) if ($options{f}); 
		    my $S; my $pred;
		    if ($options{f}) {
# 			$s = ($options{f})? &fill_zero($s, $b) : $s;
			($S, $pred) = &fill_zero($s, $b);
		    } else {
			$S = $s; $pred = $b;
		    }
		    
		    my @c = &ext_candidates_including_dep($S, $pred);
		    if (@c) {
			my $case = $options{T};
			my $ant;
			if ($options{l}) { # league tournament
			    my $c_num = @c;
			    my @score = ();
			    for (my $i=0;$i<$c_num;$i++) { $score[$i] = 0; }
			    for (my $i=0;$i<$c_num-1;$i++) {
				for (my $j=$i+1;$j<$c_num;$j++) {
				    my $fe = &ext_features_comp($pred, $c[$i], $c[$j], $cl,
								$S, $case, \%options);
				    my $testfile = $options{d}.'/TMP_FE_DUMMY';
				    open 'TMP', '>'.$testfile or die $!;
				    print TMP '+1 '.$fe."\n";
				    close TMP;
				    my $r = `/home/ryu-i/tools/bact-0.13/bact_classify -v 3 $testfile $m[$num]`;
				    my $score = (split ' ', (split '\n', $r)[1])[1];
				    if ($score > 0) {
					$score[$i]++; $score[$j]--;
				    } else {
					$score[$i]--; $score[$j]++;
				    }
				}
			    }
			    my $max_score = -10000;
			    for (my $i=0;$i<$c_num;$i++) {
				if ($max_score < $score[$i]) {
				    $max_score = $score[$i]; $ant = $c[$i];
				}
			    }

			} else { # single elimination tournament
			    $ant = shift @c; my $c_num = @c;
			    for (my $cid=0;$cid<$c_num;$cid++) {
				my $c = $c[$cid]; 
				my $fe = &ext_features_comp($pred, $ant, $c, $cl,
							    $S, $case, \%options);
				my $testfile = $options{d}.'/TMP_FE_DUMMY';
				open 'TMP', '>'.$testfile or die $!;
				print TMP '+1 '.$fe."\n";
				close TMP;
				my $r = `/home/ryu-i/tools/bact-0.13/bact_classify -v 3 $testfile $m[$num]`;
				my $score = (split ' ', (split '\n', $r)[1])[1];
				if ($score =~ /nan/) {
				    print STDERR $fe, "\n";
				    print STDERR $r, "\n";
				}
				$ant = $c if ($score < 0);
			    }
			}
			my $fe = &ext_features_one($pred, $ant, $cl, $S, $case, \%options);
			my $val = (&check_dep_case($b, $options{T}) == 1 or 
				   $pred->{'ZERO_'.$options{T}})? '+1' : '-1';
			$num2fe{$num}{$val.' '.$fe} = 1;
		    }
		}	
		$cl->add($b) if ($b->NOUN);		
	    }
	}
    }
    return \%num2fe;
}

sub output_fes {
    my $feref = shift;
    for (my $num=0;$num<$options{n};$num++) {
        open 'OUT', '>'.$options{d}.'/fe_'.$num.'_'.$options{T};
        my %cfe = %{$feref->{$num}};
        print OUT join "\n", keys %cfe;
        print OUT "\n";
        close OUT;
    }
    return;
}

# sub output_train {
#     for (my $num=0;$num<$options{n};$num++) {
#         open 'TRN', '>'.$options{d}.'/train_'.$num;
#         for (my $i=0;$i<$options{n};$i++) {
#             next if ($num == $i);
#             open 'NUM', $options{d}.'/fe_'.$i;
#             $/ = "\n";
#             while (<NUM>) { print TRN $_; }
#             close NUM;
#         }
#         close TRN;
#     }
#     return;
# }

