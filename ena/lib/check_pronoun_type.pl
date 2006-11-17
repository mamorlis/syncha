#!/usr/local/bin/perl -w

package PRONOUN;

use strict;
use DB_File;

use ENA::Conf;
my $pronoun = "$ENV{ENA_DB_DIR}/pronoun.db";
tie my %pronoun, 'DB_File', $pronoun, O_RDONLY, 0444, $DB_HASH
    or die "Cannot open $pronoun:$!";

sub check_pronoun_type {
    my $bunsetsu = shift;
    my $noun = $bunsetsu->HEAD_NOUN;
    my $pos  = $bunsetsu->HEAD_POS;
    my $in   = $noun.':'.$pos;
    return ($pronoun{$in})? $pronoun{$in} : '';
}

# test
if ($0 eq __FILE__) {
    my $noun = 'それ:名詞-代名詞-一般';
    print $pronoun{$noun}, "\n";
}

1;
