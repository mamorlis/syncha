#!/bin/env perl

use strict;
use warnings;
use Getopt::Std;

my $usage = <<USG;
cabocha inputText | ./resolveZero.pl -d modelsPath 
-a intraParam
-e interParam
USG

my %options;
getopts("d:a:e:h", \%options);
die $usage if ($options{h});
die $usage unless ($options{d});

# my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
my $scriptPath = __FILE__; $scriptPath =~ s|//|/|g;
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
unshift @INC, $scriptPath;
require 'common.pl';
require 'openModFile.pl';
require 'centerList.pl';
require 'extractFeatures.pl';
require 'cab.pl';

my $rootPath = $scriptPath; $rootPath =~ s|[^/]+/$||;
my $bactPath = $rootPath.'tools/bact-0.13/';

my $intraParam = 0;
$intraParam = $options{a} if ($options{a});
my $interParam = 0;
$interParam = $options{e} if ($options{e});

&main;

sub main {
    my $t = &resolve_zero();
    &output_text($t);
}

sub resolve_zero {
    my $t = &open_cab_file_from_stdin;
    my @s  = @{$t->Sentence}; my $s_num = @s;
#     &mark_zero($t);
    my $mRef = &open_models($options{d});

    my $cl = Center->new; # Center List
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid];
	my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
            for my $m (@{$b->Mor}) {
                if ($m->EVENT) {
                    # ���Ѥ��������ġ�
                    $b->PRED($m->WF.'����');
                    $m->EVENT('');
                }
            }
	    if ($b->PRED) {
		my $pred = $b;
		for my $type ('GA', 'WO', 'NI') {
# 		    print STDERR 'intra ant', "\t", $type, "\n";
		    my $intra_ant = &identify_antecedent_intra_bact($pred, $s, $type, $cl, $mRef->{intra}->{ant}->{$type});
# 		    print STDERR 'intra ana', "\n";
		    my $intra_score = 0;
		    if ($intra_ant) {
			$intra_score = &detemine_anaphoricity_intra_bact($s, $pred, $intra_ant, $type, $cl, $mRef->{intra}->{ana}->{$type});
		    }
		    if ($intra_score > $intraParam) {
			$pred->{$type} = $intra_ant;
		    } else {
# 			print STDERR 'inter ant', "\n";
			my $inter_ant = &identify_antecedent_inter_bact($pred, $s, $t, $type, $cl, $mRef->{inter}->{ant}->{$type});
# 			print STDERR 'inter ana', "\n";
			my $inter_score = 0;
			if ($inter_ant) {
			    $inter_score = &detemine_anaphoricity_inter_bact($s, $pred, $inter_ant, $type, $cl, $mRef->{inter}->{ana}->{$type});
			}
			$pred->{$type} = $inter_ant if ($inter_score > $interParam);
		    }
		}
	    }
	    $cl->add($b) if ($b->NOUN);
	}
    }
    return $t;
}

sub open_models {
    my $dir = shift;
    my $ref = {};
    for my $type ('GA', 'WO', 'NI') {
	# intra-sentential
	my ($mt) = &open_model_t_bact($dir, $type);
	my ($m)  = &open_model_bact($dir, $type);
	$ref->{intra}->{ant}->{$type} = $mt;
	$ref->{intra}->{ana}->{$type} = $m;

	# inter-sentential
	my ($MT) = &open_model_inter_t($dir, $type);
	my ($M)  = &open_model_inter($dir, $type);
	$ref->{inter}->{ant}->{$type} = $MT;
	$ref->{inter}->{ana}->{$type} = $M;
    }
    return $ref;
}

sub output_text { 
    my $t = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid];
	print $s->puts_mod;
    }
    return;
}

# my $inter_ant = &identify_antecedent_inter_bact($pred, $s, $type, $cl, $mRef->{inter}->{ant}->{$type});
# my $inter_score = &detemine_anaphoricity_inter_bact($s, $pred, $inter_ant, $type, $cl, $mRef->{inter}->{ana}->{$type});

## intra-sentential 
sub identify_antecedent_intra_bact {
    my ($pred, $s, $type, $cl, $m) = @_;
    my @c = &ext_candidates_including_dep($s, $pred);

    return '' unless (@c);
    
    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	my $fe = &ext_features_comp($pred, $ant, $c, $cl, $s, $type, \%options);
	
	my $testfile = $options{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `$bactPath/bact_classify -v 3 $testfile $m`;
# 	print STDERR 'm: ', $m, "\n";
# 	print STDERR 'fe: ', $fe, "\n";
# 	print STDERR 'r: ', "\n";
# 	print STDERR $r, "\n";
	my $score = (split ' ', (split '\n', $r)[1])[1];
	$ant = $c if ($score < 0);	
    }
    return $ant;
}

sub detemine_anaphoricity_intra_bact {
    my ($s, $pred, $ant, $type, $cl, $m) = @_;
    my $fe = &ext_features_one($pred, $ant, $cl, $s, $type, \%options);    

    my $testfile = $options{d}.'/TMP_FE_DUMMY2';
    open 'TMP', '>'.$testfile or die $!;
    print TMP '+1 '.$fe."\n";
    close TMP;
    my $r = `$bactPath/bact_classify -v 3 $testfile $m`;
    my $score = (split ' ', (split '\n', $r)[1])[1];
    return $score;
}

## inter-sentential

sub identify_antecedent_inter_bact {
    my ($pred, $s, $t, $type, $cl, $m) = @_;
    my @c = &ext_inter_candidates($t, $pred);

    return '' unless (@c);
    
    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	$options{b} = 1; # ��¤�����Ѥ��ʤ�
	my $fe = &ext_features_comp($pred, $ant, $c, $cl, $s, $type, \%options);
	
	my $testfile = $options{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `$bactPath/bact_classify -v 3 $testfile $m`;
	my $score = (split ' ', (split '\n', $r)[1])[1];
	$ant = $c if ($score < 0);	
    }
    return $ant;

}

sub detemine_anaphoricity_inter_bact {
#     my ($s, $pred, $inter_ant, $type, $cl, $m) = @_;
    return &detemine_anaphoricity_intra_bact(@_); # Ʊ��
}