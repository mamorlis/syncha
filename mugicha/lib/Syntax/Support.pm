#!/usr/bin/perl
# òµÌ¥ò³ò´
# Created on 25 Mar 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Syntax/Support.pm - Align predicate to event noun (support verb construction)

=head1 SYNOPSIS

  use Syntax::Support;

=cut

use strict;
use warnings;

package Syntax::Support;

our $VERSION = '0.0.1';
our @ISA = qw(Syntax);

use Syntax;
use Data::Dumper;

=head2 has_support

Returns a triplet of 'pnom:enom,pacc:eacc,pdat:edat' given case and pred.

=cut

sub get_support {
    my $self = shift;
    my $pred = shift;
    my $case = shift;
    my $triplet = $self->get_db('ealign')->{":$case:$pred"};
    return $triplet ? $triplet : '';
}
