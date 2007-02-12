#!/usr/bin/env perl
# ===================================================================
my $NAME         = 'check_edr.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'EDR辞書の人間，人間の属性以下の語彙かどうかのcheck';
# ===================================================================

package ENA::EDR;

use Exporter;
our @ISA = qw(ENA);
our $VERSION = '0.0.1';

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

#my $jcc_file = "/cl/nldata/EDR/EDR1.5/JCD/JCC.DIC"; # 共起辞書
my $jcp_file = "/cl/nldata/EDR/EDR1.5/JCD/JCP.DIC"; # 共起パターン辞書
my $cpc_file = "/cl/nldata/EDR/EDR1.5/CD/CPC.DIC";  # 概念体系辞書
my $cph_file = "/cl/nldata/EDR/EDR1.5/CD/CPH.DIC";  # 概念辞書
#Readonly::Scalar my $jcc_db => 'bdb/jcc.db';
#tie %jcc_dic, 'DB_File', $jcc_db or die "Cannot open $jcc_db";
my $jcp_db = "$ENV{ENA_DB_DIR}/jcp.db";
my $cpc_db = "$ENV{ENA_DB_DIR}/cpc.db";
my $cph_db = "$ENV{ENA_DB_DIR}/cph.db";
my (%jcp_dic, %cpc_dic, %cph_dic);
use vars qw($DEBUG);

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
        tie %jcp_dic, 'BerkeleyDB::Hash',
            -Filename => $jcp_db,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or croak "Cannot open $jcp_db:$!";
        tie %cpc_dic, 'BerkeleyDB::Hash',
            -Filename => $cpc_db,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or croak "Cannot open $cpc_db:$!";
        tie %cph_dic, 'BerkeleyDB::Hash',
            -Filename => $cph_db,
            -Flags    => DB_RDONLY,
            -Mode     => 0444
            or croak "Cannot open $cph_db:$!";
    } elsif (eval "require DB_File; 1") {
        tie %hum, 'DB_File', $hum, O_RDONLY, 0444, $DB_HASH
            or die "Cannot open $hum:$!";
        tie %org, 'DB_File', $org, O_RDONLY, 0444, $DB_HASH
            or die "Cannot open $org:$!";
        tie %jcp_dic, 'DB_File', $jcp_db, O_RDONLY, 0644
            or croak "Cannot open $jcp_db";
        tie %cpc_dic, 'DB_File', $cpc_db, O_RDONLY, 0644
            or croak "Cannot open $cpc_db";
        tie %cph_dic, 'DB_File', $cph_db, O_RDONLY, 0644
            or croak "Cannot open $cph_db";
    }

    return $self;
}

# $concept_system->[レベル1項目の番号][レベル2項目の番号]
my @concept_system = [
    # ルートノード
    [
        '3aa966', # 概念
    ],
    # レベル1
    [
        '3aa911', # 人間または人間と似た振る舞いをする主体
        '3d017c', # ものごと
        '30f7e4', # 事象
        '30f751', # 位置
        '30f776', # 時
    ],
    # レベル2
    [
        # 人間または人間と似た振る舞いをする主体
        '30f6b0',
        '30f6bf',
        '3aa912',
        '4444b6',
        # ものごと
        '444d86',
        '444ab5',
        '444daa',
        '0e7faa',
        # 事象
        '30f7e5',
        '30f83e',
        '30f801',
        '3f9856',
        '3aa963',
        # 位置
        '3aa938',
        '30f753',
        '30f767',
        '3f9651',
        '3f9658',
        '444a9d',
        # 時
        '3f9882',
        '444dd2',
        '444dd3',
        '30f77b',
        '444dd4',
        '4449e2',
        '30f7d6',
    ],
];

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

sub get_concept_id {
    my $concept = shift;

    return $cph_dic{"$concept"} ? $cph_dic{"$concept"} : 0;
}

sub get_parent_id {
    my $concept_id = shift;

    # XXX: aaaaaa-bbbbbb 形式を扱う必要がある
    return $cpc_dic{"$concept_id"} ? $cpc_dic{"$concept_id"}
                                   : $concept_system[0][0]
                                   ;
}

sub get_pattern {
    my $word = shift;

    my %pattern;
    if (defined $jcp_dic{$word}) {
        #carp $jcp_dic{$word};
        for (split q{\|}, $jcp_dic{$word}) {
            #carp $_;
            # FIXME: 複数意味役割がある場合の対応
            my ($sem_role, $concept_id) = split q{:}, $_;
            #$concept_id =~ s/;.*$//g; # とりあえず無視
            $pattern{$sem_role} = $concept_id;
        }
    }

    return %pattern;
}

sub is_same_class {
    my ($concept_a, $concept_b) = @_;
    my (@classes_of_a, @classes_of_b);

    # 祖先を順に入れておく
    while ($concept_a ne $concept_system[0][0]) {
        unshift @classes_of_a, $concept_a;
        $concept_a = get_parent_id("$concept_a");
    }
    while ($concept_b ne $concept_system[0][0]) {
        unshift @classes_of_b, $concept_b;
        $concept_b = get_parent_id("$concept_b");
    }

    #carp join q{,}, @classes_of_a;
    #carp join q{,}, @classes_of_b;

    my $level = 0;  # 最初は必ず 概念('3aa966')
    for (;;) {
        last if (!$classes_of_a[$level] or !$classes_of_b[$level]);
        if ($classes_of_a[$level] eq $classes_of_b[$level]) {
            $level++;
        }
        else {
            last;
        }
    }

    return $level - 1;
}

sub is_under_class {
    my ($word, $class) = @_;
    my @classes_of_word;

    # 祖先を順に入れておく
    while ($word ne $concept_system[0][0]) {
        unshift @classes_of_word, $word;
        $word = get_parent_id("$word");
    }

    #carp join q{,}, @classes_of_word;

    my $under_class = 0;  # 最初は必ず 概念('3aa966')
    foreach my $class_of_word (@classes_of_word) {
        if ($class_of_word eq $class) {
            $under_class = 1;
        }
    }

    return $under_class;
}

#use DB_File;
#my $person_file = $ENV{EXO_PATH} . '/dat/db/edr_person.db';
#my $org_file    = $ENV{EXO_PATH} . '/dat/db/edr_org.db';
#tie my %person, 'DB_File', $person_file, O_RDONLY or croak "$!";
#tie my %org,    'DB_File', $org_file,    O_RDONLY or croak "$!";
#
## [in ] NOUN
## [out] 1:person ; 0:otherwise
#sub check_edr_person {
#    my $bunsetsu = shift;
#    my $noun = $bunsetsu->HEAD_NOUN;
#   return ($person{$noun}) ? 'EDR_PERSON' : '';
#}
#
#sub check_edr_org {
#    my $bunsetsu = shift;
#    my $noun = $bunsetsu->HEAD_NOUN;
#    return ($org{$noun}) ? 'EDR_ORG' : '';
#}

1;
