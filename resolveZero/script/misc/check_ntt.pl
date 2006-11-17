#!/usr/local/bin/perl -w

package NTT;

use strict;
use DB_File;

# my $miscPath = $ENV{PWD}.'/'.__FILE__; 
my $miscPath = __FILE__;
 $miscPath =~ s|//|/|g;
$miscPath =~ s|/\./|/|g; $miscPath =~ s|[^/]+$||;
my $rootPath = $miscPath; $rootPath =~ s|[^/]+/$||; $rootPath =~ s|[^/]+/$||;
my $dbPath = $rootPath.'../dict/db/';

# my $ZERO_DAT_PATH = $ENV{ZERO_DAT_PATH};
#my $EXO_PATH = $ENV{'EXO_PATH'} or die $!;


my $N2C  = $dbPath.'/NTT_N2C.db';
# print STDERR $N2C, "\n";
my $path = $dbPath.'/path.db';
my $ga   = $dbPath.'/ga_vframe.db';
my $wo   = $dbPath.'/wo_vframe.db';
my $ni   = $dbPath.'/ni_vframe.db';
tie my %N2C,  'DB_File', $N2C,  O_RDONLY, 0444, $DB_HASH or die $!;
tie my %path, 'DB_File', $path, O_RDONLY, 0444, $DB_HASH or die $!;
tie my %ga,   'DB_File', $ga,   O_RDONLY, 0444, $DB_HASH or die $!;
tie my %wo,   'DB_File', $wo,   O_RDONLY, 0444, $DB_HASH or die $!;
tie my %ni,   'DB_File', $ni,   O_RDONLY, 0444, $DB_HASH or die $!;

my $v2c  = $dbPath.'/NTT_v2c.db';
tie my %v2c,  'DB_File', $v2c,  O_RDONLY, 0444, $DB_HASH or die $!;

sub check_verb_class {
    my $b = shift;
    my $pred = $b->PRED;
    return '' unless ($pred);
    my $class = $v2c{$pred};
    return $class if ($class);
    return '';
}

sub check_select_rest {
    my $ana  = shift;
    my $cand = shift;
    my $case = shift;
#     my $base = shift; # '�ե�'�ʤ�

    # hash��copy�������٤�������Τ�ptr��copy

    my $vfrptr = ($case eq 'GA')? \%ga : ($case eq 'WO')? \%wo : ($case eq 'NI')? \%ni :
	die $!;

#     # �Ȥꤢ�������ʤ��狼��ʤ����ϰ����ʤ�
#     return '' if ($base eq '��');    

#     print STDERR $ana->PRED, "\n";

    return '' unless ($ana->PRED);
    my $vframe = $vfrptr->{$ana->PRED};
    return '' unless ($vframe);
    for my $f (split ' ', $vframe) {
	return 'SELECT_REST' if ($f eq '*');
    }
    my $noun = $cand->HEAD_NOUN;
    my $sem = $N2C{$noun};
    $sem = &ne2sem($cand->HEAD_NE) if ($cand->HEAD_NE ne 'O');
    return '' unless ($sem);

    my %paths = ();
    for (split ' ', $sem) {
	for (split ' ', $path{$_}) {
	    $paths{$_} = 1;
	}
    }
    for (split ' ', $vframe) {
	return 'SELECT_REST' if ($paths{$_});
    }
    return '';
}

sub ext_sem_class {
    my $cand = shift;
    my $noun = $cand->HEAD_NOUN;
    my $sem = $N2C{$noun};
    $sem = &ne2sem($cand->HEAD_NE) if ($cand->HEAD_NE ne 'O');
    return $sem;
}

sub ne2sem {
    my $ne = shift;
    $ne =~ s/[BI]-//;
    return 'g0362_�ȿ�'                       if ($ne eq 'ORGANIZATION');
    return 'g0004_��'                         if ($ne eq 'PERSON');
    return 'g2692_���� g2670_����'            if ($ne eq 'TIME');
    return 'g2692_����'                       if ($ne eq 'DATE');
    return 'g0388_��� g2611_���� g2614_�ϰ�' if ($ne eq 'LOCATION');
    return 'g0533_����ʪ'                     if ($ne eq 'ARTIFACT');
    return 'g2590_�͡���'                     if ($ne eq 'MONEY');
    return 'g2596_�׻���'                     if ($ne eq 'PERCENT');
    return '';
}

1;
