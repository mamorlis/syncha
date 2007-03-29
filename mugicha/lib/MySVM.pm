#!/usr/bin/perl
# Created on 10 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

MySVM - Provised common functions to implement tournament model

=head1 SINOPSYS

  use MySVM;

=cut

use strict;
use warnings;

package MySVM;

use TinySVM;
use File::Temp qw(tempfile);

use Carp;
use Data::Dumper;

sub new {
    my $class      = shift;
    my $svm_model  = shift;
    my $self       = {};
    $self->{model} = new TinySVM::Model;
    $self->{model}->read($svm_model);
    bless $self, ref($class) || $class;
}

=head2 model

Set and get model path.

=cut

sub model {
    my $self = shift;
    if (@_ > 0) {
        my $svm_model = shift;
        $self->{model}->read($svm_model);
    } else {
        return $self->{model};
    }
}

=head2 classify_line()

Classify just one line.

=cut

sub classify_line {
    my $self = shift;
    my $line = shift;

    my $svm_model = $self->model;

    $line = substr $line, 3;
    my $res = $svm_model->classify($line);
    return $res;
}

1;
