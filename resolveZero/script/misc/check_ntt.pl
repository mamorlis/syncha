#!/usr/bin/env perl

package NTT;

use strict;
use warnings;

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

# my $miscPath = $ENV{PWD}.'/'.__FILE__; 
my $miscPath = __FILE__;
$miscPath =~ s|//|/|g;
$miscPath =~ s|/\./|/|g; $miscPath =~ s|[^/]+$||;
my $rootPath = $miscPath; $rootPath =~ s|[^/]+/$||; $rootPath =~ s|[^/]+/$||;
my $dbPath = $rootPath.'../dict/db/';

# my $ZERO_DAT_PATH = $ENV{ZERO_DAT_PATH};
#my $EXO_PATH = $ENV{'EXO_PATH'} or die $!;

my $N2C  = $dbPath.'/NTT_N2C.db';
my $path = $dbPath.'/path.db';
my $ga   = $dbPath.'/ga_vframe.db';
my $wo   = $dbPath.'/wo_vframe.db';
my $ni   = $dbPath.'/ni_vframe.db';
my $v2c  = $dbPath.'/NTT_v2c.db';

my (%N2C, %path, %ga, %wo, %ni, %v2c);

{
    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %N2C, 'BerkeleyDB::Hash',
            -Filename => $N2C,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
        tie %path, 'BerkeleyDB::Hash',
            -Filename => $path,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
        tie %ga, 'BerkeleyDB::Hash',
            -Filename => $ga,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
        tie %wo, 'BerkeleyDB::Hash',
            -Filename => $wo,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
        tie %ni, 'BerkeleyDB::Hash',
            -Filename => $ni,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
        tie %v2c, 'BerkeleyDB::Hash',
            -Filename => $v2c,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or die $!;
    } elsif (eval "require DB_File; 1") {
        tie %N2C,  'DB_File', $N2C,  O_RDONLY, 0444, $DB_HASH or die $!;
        tie %path, 'DB_File', $path, O_RDONLY, 0444, $DB_HASH or die $!;
        tie %ga,   'DB_File', $ga,   O_RDONLY, 0444, $DB_HASH or die $!;
        tie %wo,   'DB_File', $wo,   O_RDONLY, 0444, $DB_HASH or die $!;
        tie %ni,   'DB_File', $ni,   O_RDONLY, 0444, $DB_HASH or die $!;
        tie %v2c,  'DB_File', $v2c,  O_RDONLY, 0444, $DB_HASH or die $!;
    }
}

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
#     my $base = shift; # 'φガ'など

    # hashをcopyすると負荷がかかるのでptrをcopy

    my $vfrptr = ($case eq 'GA')? \%ga : ($case eq 'WO')? \%wo : ($case eq 'NI')? \%ni :
	die $!;

#     # とりあえず，格がわからない場合は引かない
#     return '' if ($base eq 'φ');    

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
    return 'g0362_組織'                       if ($ne eq 'ORGANIZATION');
    return 'g0004_人'                         if ($ne eq 'PERSON');
    return 'g2692_時刻 g2670_時間'            if ($ne eq 'TIME');
    return 'g2692_時刻'                       if ($ne eq 'DATE');
    return 'g0388_場所 g2611_位置 g2614_範囲' if ($ne eq 'LOCATION');
    return 'g0533_具体物'                     if ($ne eq 'ARTIFACT');
    return 'g2590_値・額'                     if ($ne eq 'MONEY');
    return 'g2596_計算値'                     if ($ne eq 'PERCENT');
    return '';
}

1;
