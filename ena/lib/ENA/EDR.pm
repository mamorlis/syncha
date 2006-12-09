#!/usr/bin/env perl
# ===================================================================
my $NAME         = 'check_edr.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'EDR辞書の人間，人間の属性以下の語彙かどうかのcheck';
# ===================================================================

package ENA::EDR;

use strict;
use warnings;

use Carp;

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use ENA::Conf;
my $hum = "$ENV{ENA_DB_DIR}/edr_person.db";
my $org = "$ENV{ENA_DB_DIR}/edr_org.db";
my (%hum, %org);

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    # set DB
    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %hum, 'BerkeleyDB::Hash', 
            -Filename => $hum,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die "Cannot open $hum:$!";
        tie %org, 'BerkeleyDB::Hash',
            -Filename => $org,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die "Cannot open $org:$!";
    } elsif (eval "require DB_File; 1") {
        tie %hum, 'DB_File', $hum, O_RDONLY, 0444, $DB_HASH
            or die "Cannot open $hum:$!";
        tie %org, 'DB_File', $org, O_RDONLY, 0444, $DB_HASH
            or die "Cannot open $org:$!";
    }

    return $self;
}

# [in ] NOUN
# [out] 1:person ; 0:otherwise
sub check_edr_person {
    my ($self, $bunsetsu) = @_;
    my $noun = $bunsetsu->HEAD_NOUN;
    return ($hum{$noun})? 'EDR_PERSON' : '';
}

sub check_edr_org {
    my ($self, $bunsetsu) = @_;
    my $noun = $bunsetsu->HEAD_NOUN;
    return ($org{$noun})? 'EDR_ORG' : '';
}

1;
