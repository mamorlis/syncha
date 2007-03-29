#!/usr/bin/perl
# òµÌ¥ò³ò´
# Created on 18 Feb 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

use strict;
use warnings;

=head1 NAME

Tournament.pm - Implements several wasy of doing tournaments

=cut

package Tournament;

use RyuBact;
use Data::Dumper;
use XML::Simple qw(XMLout);

sub new {
    my $class = shift;
    my %opt = ( @_, );
    my $self  = {};
    $self->{model}  = $opt{model};
    $self->{bact}   = new RyuBact ('', $self->{model}, '');
    $self->{morph}  = $opt{morph};
    $self->{vframe} = $opt{vframe};
    $self->{debug}  = $opt{debug};
    bless $self, ref($class) || $class;

    return $self;
}

=head2 bact

Returns a RyuBact object.

=cut

sub bact {
    my $self = shift;
    $self->{bact};
}

=head2 morph

Returns a morph we're looking at.

=cut

sub morph {
    my $self = shift;
    $self->{morph};
}

=head2 vframe

Returns a vframe we're looking at.

=cut

sub vframe {
    my $self = shift;
    $self->{vframe};
}

=head2 debug

Returns 1 if debug mode.

=cut

sub debug {
    my $self = shift;
    $self->{debug};
}

=head2 xml

Get xml data structure.

=cut

sub xml {
    my $self = shift;
    if (@_ > 0) {
        my $event = shift;
        my $arg   = shift;
        my $text  = shift;
        $self->{xml}->{INPUT}
            = { EVENT => { morph_id => $event->get_id,
                           chunk_id => $event->get_chunk_id,
                           event    => $self->vframe,
                },
                ARGUMENT => { surfarce => $arg->get_surface,
                              morph_id => $arg->get_id,
                              chunk_id => $arg->get_chunk_id,
                },
                TEXT     => [ $text ],
            };
    } else {
        $self->{xml};
    }
}

=head2 traverse(tree structure of candidates)

Traverses a tournament tree.

=cut

sub traverse {
    my $self      = shift;
    my $tree_ref  = shift;
    my $left_ref  = shift @$tree_ref;
    my $right_ref = shift @$tree_ref;
    my ($left, $right);
    if (ref($left_ref) eq 'MyCabocha::Morph') {
        $left  = $left_ref;
    } elsif (ref($left_ref) eq 'ARRAY') {
        $left  = $self->traverse($left_ref);
    }
    if (ref($right_ref) eq 'MyCabocha::Morph') {
        $right = $right_ref;
    } elsif (ref($right_ref) eq 'ARRAY') {
        $right = $self->traverse($right_ref);
    }
    my $winner;
    if ($self->bact->classify($self->morph, $self->vframe, $left, $right) < 0)
    {
        $winner = $left;
    } else {
        $winner = $right;
    }
    if ($self->debug) {
        push @{$self->xml->{PAIR}},
            { LEFT   => { surface  => $left->get_surface,
                          morph_id => $left->get_id,
                          chunk_id => $left->get_chunk_id,
                        },
              RIGHT  => { surface  => $right->get_surface,
                          morph_id => $right->get_id,
                          chunk_id => $right->get_chunk_id,
                        },
              WINNER => { surface  => $winner->get_surface,
                          morph_id => $winner->get_id,
                          chunk_id => $winner->get_chunk_id,
                        },
              VFRAME => $self->vframe,
            };
    }
    return $winner;
}

=head2 round_robin

=cut

sub round_robin {
    my $self    = shift;
    my $nps_ref = shift;
    my %wins_of;
    for (my $i = 0; $i < @$nps_ref - 1; ++$i) {
        for (my $j = $i + 1; $j < @$nps_ref; ++$j) {
            my $winner;
            if ($self->bact->classify($self->morph, $self->vframe,
                $nps_ref->[$i], $nps_ref->[$j]) < 0) {
                $wins_of{$i}++;
                $winner = $nps_ref->[$i];
            } else {
                $wins_of{$j}++;
                $winner = $nps_ref->[$j];
            }
            if ($self->debug) {
                push @{$self->xml->{EVENT}},
                    { LEFT   => $nps_ref->[$i]->get_surface,
                      RIGHT  => $nps_ref->[$j]->get_surface,
                      WINNER => $winner->get_surface,
                      VFRAME => $self->vframe,
                    };
            }
        }
    }
    for my $index (sort { $wins_of{$b} <=> $wins_of{$a} } keys %wins_of) {
        if ($self->debug) {
            push @{$self->xml->{EVENT}},
                    { RESULT => $nps_ref->[$index]->get_surface };
        }
        return $nps_ref->[$index];
    }
}

1;
