#!/usr/bin/perl -w

=comment

  ENA -- Event Noun Annotator

  $Id$

  Copyright (C) 2005-2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
=cut

use strict;
use warnings;

use Carp qw(croak carp);
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
#use ENA;

sub is_event {
    my $test_file  = shift;
    my $model_file = shift;

    # SVM-Light is not supported -- assumes TinySVM installed
    my @classify = ("/usr/bin/svm_classify", "-V",
                    "$test_file" , "$model_file");

	my $score = `@classify | head -n 1 | cut -d' ' -f2`
        or croak "@classify failed: $?";

    return ($score > 0) ? 1 : 0;
}

1;
