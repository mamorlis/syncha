#!/usr/bin/env perl

package ENA::Pronoun;

use strict;
use warnings;
BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use ENA::Conf;
my $pronoun = "$ENV{ENA_DB_DIR}/pronoun.db";
my %pronoun;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %pronoun, 'BerkeleyDB::Hash',
            -Filename => $pronoun,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die "Cannot open $pronoun:$!";
    } elsif (eval "require DB_File; 1") {
        tie %pronoun, 'DB_File', $pronoun, O_RDONLY, 0444, $DB_HASH
            or die "Cannot open $pronoun:$!";
    }

    return $self;
}

sub check_pronoun_type {
    my ($self, $bunsetsu) = @_;

    my $noun = $bunsetsu->HEAD_NOUN;
    my $pos  = $bunsetsu->HEAD_POS;
    my $in   = $noun.':'.$pos;
    return ($pronoun{$in})? $pronoun{$in} : '';
}

# test
if ($0 eq __FILE__) {
    my $noun = '����:̾��-��̾��-����';
    print $pronoun{$noun}, "\n";
}

1;
