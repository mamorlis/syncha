#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics::NE - Check if given expression contains named entities

=head1 SYNOPSIS

  use Semantics::NE;

  my $ne = new Semantics::NE;

  my $ne_type = $ne->get_ne_type;

=cut

use strict;
use warnings;

package Semantics::NE;

use Semantics;
our @ISA = qw(Semantics);
our $VERSION = '0.0.1';

=head2 get_ne_type()

Return named entity type of given morpheme.

=cut

sub get_ne_type {
    my ($self, $morph) = @_;
    my $ne_type = ($morph->get_ne =~ m/[BI]-(.*)/gmx)[0];
    return $ne_type;
}

1;
