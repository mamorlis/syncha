#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics::Pronoun - Check if given expression contains pronoun

=head1 SYNOPSIS

  use Semantics::Pronoun;

  my $pronoun = new Semantics::Pronoun;

  my $pronoun_type = $pronoun->get_pronoun_type;

=cut

use strict;
use warnings;

package Semantics::Pronoun;

use Semantics;
our @ISA = qw(Semantics);
our $VERSION = '0.0.1';

=head2 get_pronoun_type()

Return pronoun type of given morpheme.

=cut

sub get_pronoun_type {
    my ($self, $morph) = @_;
    my $pronoun = $morph->get_surface.':'.$morph->get_pos;
    return (exists $self->get_db('pron')->{$pronoun}) ?
        $self->get_db('pron')->{$pronoun} : '';
}

1;
