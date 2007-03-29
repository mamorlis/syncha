#!/usr/bin/perl
# Created on 7 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

Semantics::Cooc - Calculate coocurrence and convert into features

=head1 SYNOPSIS

  use Semantics::Cooc;

  my $cooc = new Semantics::Cooc;

=cut

use strict;
use warnings;

package Semantics::Cooc;

use Semantics;
our @ISA = qw(Semantics);

use NCVTool;

my %cooc_window = ( 'newswire' => 1, 'web' => 0.025 );
my %cooc_max    = ( 'newswire' => 5, 'web' => 0.2 );

sub new {
    my $class = shift;
    my $self  = {};
    my %args  = ( @_, );
    $self->{ncvtool} = new NCVTool (%args);
    $self->{type}    = $args{type} || 'newswire';
    bless $self, ref($class) || $class;
}

=head2 get_type

Returns type of cooc obj.

=cut

sub get_type {
    my $self = shift;
    $self->{type};
}

=head2 get_ncvtool()

Returns ncvtool object.

=cut

sub get_ncvtool {
    my $self = shift;
    $self->{ncvtool};
}

=head2 get_cooc_features()

Get cooc feature.

=cut

sub get_cooc_features {
    my ($self, $vframe, $morph) = @_;

    my $morph_score = $self->calc_score($vframe, $morph);
    my @cooc_features;
    push @cooc_features, "COOC_SCORE-$morph_score" if $morph_score ne 'NaN';
    if ($morph_score > 0) {
        for (my $i = 0;
             $i <= $cooc_max{$self->get_type};
             $i += $cooc_window{$self->get_type}) {
            if ($morph_score > $i) {
                push @cooc_features, "COOC_PLUS-$i";
            }
        }
    } else {
        for (my $i = 0;
             $i <= $cooc_max{$self->get_type};
             $i += $cooc_window{$self->get_type}) {
            if ($morph_score < (-1 * $i)) {
                push @cooc_features, "COOC_MINUS-$i";
            }
        }
    }
    return @cooc_features;
}

=head2 cmp_cooc_features()

Compare coocurrence and convert into features.

=cut

sub cmp_cooc_features {
    my ($self, $vframe, $left, $right) = @_;

    my $left_score  = $self->calc_score($vframe, $left);
    my $right_score = $self->calc_score($vframe, $right);

    # construct cooc features
    my @cooc_features;
    if ($left_score <=> $right_score) {
        push @cooc_features,
            ($left_score > $right_score) ? 'COOC_LEFT_GT_RIGHT'
                                         : 'COOC_LEFT_LE_RIGHT';
        my $score_diff = $left_score - $right_score;
        push @cooc_features, 'COOC_VS_SCORE-'.$score_diff;
        for (my $i = 0;
            $i <= $cooc_max{$self->get_type} * 2;
            $i += $cooc_window{$self->get_type}) {
            if ($score_diff > $i) {
                push @cooc_features, "COOC_VS_BY-$i";
            }
        }
    }
    return @cooc_features;
}

=head2 calc_score

Calculate coocurence score given a query.

=cut

sub calc_score {
    my $self   = shift;
    my $vframe = shift;
    my $morph  = shift;
    my %params = ( smooth => 1,
                   @_,
    );

    my $ncvtool = $self->get_ncvtool;

    my $q   = $morph->get_surface.$vframe;
    my $morph_score = $ncvtool->get_score($q);
    if ($params{smooth} and (!defined $morph_score or $morph_score < 0)) {
        my $ne;
        if ($morph->get_pos =~ /^Ì¾»ì-¸ÇÍ­Ì¾»ì-(°ìÈÌ|¿ÍÌ¾|ÁÈ¿¥|ÃÏ°è)/) {
            $ne = '¡ã¸ÇÍ­Ì¾»ì'.$1.'¡ä'
        } else {
            $ne = ($morph->get_ne =~ /PERSON/)       ? '¡ã¸ÇÍ­Ì¾»ì¿ÍÌ¾¡ä'
                : ($morph->get_ne =~ /LOCATION/)     ? '¡ã¸ÇÍ­Ì¾»ìÃÏ°è¡ä'
                : ($morph->get_ne =~ /ORGANIZATION/) ? '¡ã¸ÇÍ­Ì¾»ìÁÈ¿¥¡ä'
                : ($morph->get_ne =~ /ARTIFACT/)     ? '¡ã¸ÇÍ­Ì¾»ì°ìÈÌ¡ä'
                : '';
        }
        $morph_score = $ncvtool->get_score($ne.$vframe) if $ne;
    }
    $morph_score = 'NaN' unless defined $morph_score;

    return $morph_score;
}

1;
