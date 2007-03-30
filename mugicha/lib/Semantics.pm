#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics.pm - Common module of all Semantics packages

=head1 SYNOPSIS

  use Semantics;

=cut

use strict;
use warnings;

package Semantics;

our $VERSION = '0.1';

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use FindBin qw($Bin);
our $db_path = $Bin.'/../../dict/db/';
our %dict_of = ( #N2C  => 'NTT_N2C.db',
                 #v2c  => 'NTT_v2c.db',
                 #path => 'path.db',
                 #ga   => 'ga_vframe.db',
                 #wo   => 'wo_vframe.db',
                 #ni   => 'ni_vframe.db',
                 pron => 'pronoun.db',
                 #hum  => 'edr_person.db',
                 #org  => 'edr_org.db',
);
our %db_of;
our %sem_of = ( ORGANIZATION => 'g0362_�ȿ�',
                PERSON       => 'g0004_��',
                TIME         => 'g2692_���� g2670_����',
                DATE         => 'g2692_����',
                LOCATION     => 'g0388_��� g2611_���� g2614_�ϰ�',
                ARTIFACT     => 'g0533_����ʪ',
                MONEY        => 'g2590_�͡���',
                PERCENT      => 'g2596_�׻���',
);

sub new {
    my $class = shift;
    my $self  = {};

    for my $dict (keys %dict_of) {
        no strict 'subs';
        if (eval 'require BerkeleyDB; 1') {
            tie %{ $db_of{$dict} }, 'BerkeleyDB::Hash',
                -Filename => $db_path.$dict_of{$dict},
                -Flags    => DB_RDONLY,
                -Mode     => 0444
                or die "Cannot open $db_path$dict_of{$dict}:$!";
        } elsif (eval 'require DB_File; 1') {
            tie %{ $db_of{$dict} }, 'DB_File',
                $db_path.$dict_of{$dict}, O_RDONLY, 0644
                or die "Cannot open $db_path$dict_of{$dict}:$!";
        }
    }

    bless $self, ref($class) || $class;
}

sub DESTROY {
    my $self = shift;
    for my $dict (keys %dict_of) {
        untie %{ $db_of{$dict} };
    }
}

sub get_db {
    my ($self, $db_name) = @_;
    return $db_of{$db_name};
}

sub get_sem {
    my ($self, $ne) = @_;
    return (exists $sem_of{$ne}) ? $sem_of{$ne} : '';
}

1;
