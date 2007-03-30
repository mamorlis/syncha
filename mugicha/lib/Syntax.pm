#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Syntax.pm - Common module of all Syntax packages

=head1 SYNOPSIS

  use Syntax;

=cut

use strict;
use warnings;

package Syntax;

our $VERSION = '0.0.1';

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use Carp qw(carp croak);
use Data::Dumper;

use FindBin qw($Bin);
our $db_path = $Bin.'../../dict/db/';
our %dict_of = ( functional => 'functional.db',
                 func_verbs => 'func_verbs.db',
                 ealign     => 'ealign.db',
);
our %db_of;
our %syn_of = (); 
our %definite_type_of = (
    'これ' => 'コ系', 'ここ' => 'コ系', 'これら' => 'コ系',
    'ここら' => 'コ系', 'こちら' => 'コ系', 'こっち' => 'コ系',
    'この' => 'コ系', 'こんな' => 'コ系', 'こういう' => 'コ系',
    'こうした' => 'コ系', 'こういった' => 'コ系', 'こう' => 'コ系',
    'こんなに' => 'コ系', 'こんなふうに' => 'コ系',

    'それ' => 'ソ系', 'そこ' => 'ソ系', 'そこら' => 'ソ系',
    'それら' => 'ソ系', 'そちら' => 'ソ系', 'そっち' => 'ソ系',
    'その' => 'ソ系', 'そんな' => 'ソ系', 'そういう' => 'ソ系',
    'そうした' => 'ソ系', 'そういった' => 'ソ系', 'そう' => 'ソ系',
    'そんなに' => 'ソ系', 'そんなふうに' => 'ソ系',

    'あれ' => 'ア系', 'あそこ' => 'ア系', 'あれら' => 'ア系',
    'あっち' => 'ア系', 'あの' => 'ア系', 'あんな' => 'ア系',
    'ああいう' => 'ア系', 'ああした' => 'ア系', 'ああいった' => 'ア系',
    'ああ' => 'ア系', 'あんなに' => 'ア系', 'あんなふうに' => 'ア系',
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

=head2 get_definite()

Get type of definite expressions.

=cut

sub get_definite {
    my ($self, $morph) = @_;
    return (exists $definite_type_of{$morph->get_surface}) ?
        'DEF_'.$definite_type_of{$morph->get_surface} : '';
}

=head2 get_pre_definite()

Get type of definite expressions preceeding given morpheme.

=cut

sub get_pre_definite {
    my ($self, $morph) = @_;
    return '' unless $morph->get_depend;
    for my $dep_morph (@{ $morph->get_depend->get_morph }) {
        if (my $definite = $definite_type_of{$dep_morph->get_surface}) {
            return 'PRE_DEF_'.$definite;
        }
    }
    return '';
}

=head2 get_particle()

Get a particle of given morpheme.

=cut

sub get_particle {
    my ($self, $morph) = @_;
    my $func_morph = ${$morph->get_chunk}->get_func;
    if ($func_morph->get_pos =~ m/^助詞-格助詞/gmx) {
        return 'PARTICLE_'.$func_morph->get_surface;
    }
    return undef;
}

=head2 get_pos()

Get pos sequence of the same chunk.

=cut

sub get_pos {
    my ($self, $morph) = @_;
    my @poses;
    for my $morph (@{ ${$morph->get_chunk}->get_morph }) {
        (my $pos = $morph->get_pos) =~ s/-.*//g;
        push @poses, $pos;
    }
    return 'CHUNK_POS_'. join (q{_}, @poses);
}

=head2 get_db()

Get DB object.

=cut

sub get_db {
    my ($self, $db_name) = @_;
    return $db_of{$db_name};
}

#sub get_sem {
#    my ($self, $ne) = @_;
#    return (exists $sem_of{$ne}) ? $sem_of{$ne} : '';
#}

1;
