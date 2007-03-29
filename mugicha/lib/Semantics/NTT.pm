#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics::NTT - Module to look up selectional preference from Nihongo Goi
                 Taikei

=head1 SYNOPSIS

  use Semantics::NTT;
  my $ntt = new Semantics::NTT;

  $ntt->get_verb_class($morph);
  $ntt->get_selectional_restriction($vframe, $en, $np);
  $ntt->get_sem_class($morph);
  $ntt->ne2sem($morph);

=cut

use strict;
use warnings;

package Semantics::NTT;

use Semantics;
our @ISA = qw(Semantics);
our $VERSION = '0.0.1';

use Data::Dumper;
use Carp qw(carp croak);

=head2 get_verb_class

Get verb class of given morpheme.

=cut

sub get_verb_class {
    my ($self, $morph) = @_;
    my $pred  = $morph->get_surface.'する';
    my $verb_class = $self->get_db('v2c')->{$pred};
    return ($verb_class) ? $verb_class : '';
}

=head2 get_selectional_restriction

Get selectional restriction given a verb frame, an event noun
and a noun phrase.

=cut

sub get_selectional_restriction {
    my ($self, $vframe, $en, $np) = @_;

    my $case = (split /:/, $vframe)[1];
    my $verb = ($case eq 'が') ? $self->get_db('ga')
             : ($case eq 'を') ? $self->get_db('wo')
             : ($case eq 'に') ? $self->get_db('ni')
             : '';

    return '' unless ($en->get_type eq 'EVENT');
    my $vpatterns = $verb->{$en->get_surface.'する'};
    return '' unless ($vpatterns);
    for my $vpattern (split ' ', $vpatterns) {
        return 'SELECT_REST_*' if ($vpattern eq '*');
    }

    my $sems = $self->get_sem_class($np);
    $sems = $self->get_db('N2C')->{$np->get_surface} unless $sems;
    return '' unless $sems;

    my %path_of;
    for my $sem (split ' ', $sems) {
    	for my $path (split ' ', $self->get_db('path')->{$sem}) {
    	    $path_of{$path} = 1;
    	}
    }
    for my $vpattern (split ' ', $vpatterns) {
        return 'SELECT_REST_PATH' if ($path_of{$vpattern});
    }
    return '';
}

=head2 get_sem_class

Get semantic class of given morpheme.

=cut

sub get_sem_class {
    my ($self, $morph) = @_;
    my $noun = $morph->get_surface;
    my $sem = $self->get_db('N2C')->{$noun};
    $sem = $self->ne2sem($morph->get_ne);
    return $sem;
}

=head2 ne2sem

Convert named entity to semantic class.

=cut

sub ne2sem {
    my ($self, $ne) = @_;
    $ne =~ s/[BI]-//;
    return $self->get_sem($ne);
}

1;
