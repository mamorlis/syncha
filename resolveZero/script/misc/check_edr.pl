#!/usr/local/bin/perl -w
# ===================================================================
my $NAME         = 'check_edr.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'EDR����οʹ֡��ʹ֤�°���ʲ��θ��ä��ɤ�����check';
# ===================================================================

package EDR;

use strict;
use DB_File;

# my $miscPath = $ENV{PWD}.'/'.__FILE__; 
my $miscPath = __FILE__; $miscPath =~ s|//|/|g;
$miscPath =~ s|/\./|/|g; $miscPath =~ s|[^/]+$||;
my $rootPath = $miscPath; $rootPath =~ s|[^/]+/$||; $rootPath =~ s|[^/]+/$||;
my $dbPath = $rootPath.'../dict/db/';

# my $ZERO_DAT_PATH = $ENV{ZERO_DAT_PATH} or die $!;

my $hum = $dbPath.'/edr_person.db';
my $org = $dbPath.'/edr_org.db';

tie my %hum, 'DB_File', $hum, O_RDONLY, 0444, $DB_HASH or die $!;
tie my %org, 'DB_File', $org, O_RDONLY, 0444, $DB_HASH or die $!;

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