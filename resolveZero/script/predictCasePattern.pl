#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
unshift @INC, $Bin;
use NCVTool;
my $ncvtool = new NCVTool(model=>'n50', pat=>'cv');

sub predicat_case_pattern {
    my $pred = shift; # Bunsetsu
    my @type = ('GA');
    if ($pred->PRED) {
	my %case = ( '¤ò'=>'WO', '¤Ë'=>'NI' );
	for my $case (keys %case) {
 	    my $q = $case.':'.$pred->PRED;
	    my $score = $ncvtool->get_score($q);
	    push @type, $case{$case} if ($score and $score > 0) ;
	}
    } else {
	@type = ('GA', 'WO', 'NI') if ($pred->HEAD_POS =~ /^Æ°»ì/);
    }
    return @type;
}

1;
