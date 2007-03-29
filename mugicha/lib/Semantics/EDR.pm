#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics::EDR - Module to look up whether given np is human in EDR

=head1 SYNOPSIS

  use Semantics::EDR;
  my $edr = new Semantics::EDR;

  $edr->get_edr_type($morph);

=cut

use strict;
use warnings;

package Semantics::EDR;

use Semantics;
our @ISA = qw(Semantics);
our $VERSION = '0.0.1';

use Data::Dumper;
use Carp qw(carp croak);

=head2 get_edr_type()

Get EDR type (human or organization) given a morpheme.

=cut

sub get_edr_type {
    my ($self, $morph) = @_;
    my $edr_type = '';
    if ($self->get_db('hum')->{$morph->get_surface}) {
        $edr_type = 'EDR_PERSON';
    } elsif ($self->get_db('org')->{$morph->get_surface}) {
        $edr_type = 'EDR_ORGANIZATION';
    }
    return $edr_type;
}

1;
