#!/usr/local/bin/perl -w
# ===================================================================
my $NAME         = 'check_edr.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'EDR辞書の人間，人間の属性以下の語彙かどうかのcheck';
# ===================================================================

package EDR;

use strict;
use DB_File;

use ENA::Conf;
my $hum = "$ENV{ENA_DB_DIR}/edr_person.db";
my $org = "$ENV{ENA_DB_DIR}/edr_org.db";
tie my %hum, 'DB_File', $hum, O_RDONLY, 0444, $DB_HASH
    or die "Cannot open $hum:$!";
tie my %org, 'DB_File', $org, O_RDONLY, 0444, $DB_HASH
    or die "Cannot open $org:$!";

# [in ] NOUN
# [out] 1:person ; 0:otherwise
sub check_edr_person {
    my $bunsetsu = shift;
    my $noun = $bunsetsu->HEAD_NOUN;
    return ($hum{$noun})? 'EDR_PERSON' : '';
}

sub check_edr_org {
    my $bunsetsu = shift;
    my $noun = $bunsetsu->HEAD_NOUN;
    return ($org{$noun})? 'EDR_ORG' : '';
}

1;
