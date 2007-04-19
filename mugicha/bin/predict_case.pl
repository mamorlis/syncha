#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
unshift @INC, $Bin;
use NCVTool;
my $ncvtool = new NCVTool(model=>'n50', pat=>'cv');

sub predict_case {
    my $morph = shift; # Morph
    my @type;
    if ($morph->get_type eq 'event') {
        my %case = ( 'が' => 'GA', 'を'=>'WO', 'に'=>'NI' );
        for my $case (keys %case) {
            my $q = $case.':'.$morph->get_surface.'する';
            my $score = $ncvtool->get_score($q);
            push @type, $case{$case} if ($score and $score > 0) ;
        }
    }
    return @type;
}

1;
