#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Syntax::Position - Get features for positional parameters.

=head1 SYNOPSIS

  use Syntax::Position;

  my $position = new Syntax::Position;

=cut

use strict;
use warnings;

package Syntax::Position;

use Syntax;
our @ISA = qw(Syntax);
our $VERSION = '0.0.1';

use Carp qw(carp croak);
use Data::Dumper;

=head2 get_distance()

Get distance between event noun and noun phrase.

=cut

sub get_distance {
    my ($self, $en, $np) = @_;

    my @distance;
    if (${$en->get_cab}->before($en, $np)) {
        push @distance, 'PRED_NP';
        my $dist = $np->get_num - $en->get_num;
        push @distance, "PRED_NP_$dist";
    } else {
        push @distance, 'NP_PRED';
        my $dist = $en->get_num - $np->get_num;
        push @distance, "NP_PRED_$dist";
    }
    return @distance;
}

=head2 get_depend

Get dependency between event noun and noun phrase.

=cut

sub get_depend {
    my ($self, $en, $np) = @_;

    my @depend_paths;
    if ($en->get_depend_id == $np->get_chunk_id) {
        push @depend_paths, 'DEP_PRED_NP';
    }
    if ($np->get_depend_id == $en->get_chunk_id) {
        push @depend_paths, 'DEP_NP_PRED';
    }
    return @depend_paths;
}

=head2 get_depend_path

Get dependency path between event noun and noun phrase.

=cut

sub get_depend_path {
    my ($self, $en, $np) = @_;

    my @depend_paths;
    for my $path (@{ ${$en->get_chunk}->get_depend_path([]) }) {
        if ($path == $np->get_chunk_id) {
            push @depend_paths, 'DEP_PRED_PATH2NP';
        }
    }
    for my $path (@{ ${$np->get_chunk}->get_depend_path([]) }) {
        if ($path == $en->get_chunk_id) {
            push @depend_paths, 'DEP_NP_PATH2PRED';
        }
    }
    return @depend_paths;
}

=head2 get_position()

Get postion in a sentence.

=cut

sub get_position {
    my ($self, $morph) = @_;

    my @position;
    if ($morph->get_chunk_id == 0) {
        push @position, 'SENT_BEGIN';
    } elsif ($morph->get_chunk_id == scalar @{ ${$morph->get_text}->get_chunk } - 1) {
        push @position, 'SENT_END';
    }
    
    if ($morph->get_id == 0) {
        push @position, 'NP_BEGIN';
    } elsif ($morph->get_id == scalar @{ ${$morph->get_chunk}->get_morph } - 1) {
        push @position, 'NP_END';
    }

    return @position;
}

1;
