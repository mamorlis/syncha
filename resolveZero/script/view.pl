#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;

my $usage = <<USG;
cabocha inputText | resolveZero | view.pl > out
USG

my %options;
getopts("h", \%options);
die $usage if ($options{h});

my $scriptPath = $ENV{PWD}.'/'.__FILE__; $scriptPath =~ s|[^/]+$||;
unshift @INC, $scriptPath;
require 'cab.pl';

&main;

sub main {
    my $t = &open_cab_file_from_stdin;
    my $out = &modify_text($t);
    print $out, "\n";
}

sub modify_text {
    my $t = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    my %loc2id = (); my $id = 1;
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
	    for my $type ('GA', 'WO', 'NI') {
		if ($b->{$type}) {
		    my $loc = $b->{$type};
		    $loc2id{$loc} = $id++ unless ($loc2id{$loc});
		    $b->{$type} = $loc2id{$loc};
		}
	    }
	}
    }

    my $out = '';
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
	    if ($b->PRED) {
		my $tag = '<pred';
		my @tag = ();
		for my $type ('GA', 'WO', 'NI') {
		    push @tag, $type.'="'.$b->{$type}.'"' if ($b->{$type});
		}
		$tag .= ' '.join(' ', @tag) if (@tag);
		$tag .= '>';
		my $wf = $tag.$b->WF.'</pred>';
		$wf = '<id ID="'.$loc2id{$b->sb}.'">'.$wf.'</id>' if ($loc2id{$b->sb});
# 		$out .= $tag.$b->WF.'</pred>'.$b->FUNC;
		$out .= $wf.$b->FUNC;
	    } elsif ($loc2id{$b->sb}) {
		my $wf = $b->WF;
		$out .= '<id ID="'.$loc2id{$b->sb}.'">'.$wf.'</id>'.$b->FUNC;
	    } else {
		$out .= $b->STRING;
	    }
	}
	$out .= "\n";
    }
    return $out;
}


