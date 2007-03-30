#!/usr/bin/perl
# Created on 30 Dec 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# òµÌ¥ò³ò´

use strict;
use warnings;

package NCVTool;

#use encoding 'euc-jp', STDIN => 'euc-jp', STDOUT => 'euc-jp';

use IPC::Open2;
use Carp;
#use Test::Simple qw( no_plan );

use FindBin qw($Bin);
my %model_dir = ( 'newswire' => $Bin."/../../dict/cooc",
                  'web'      => $Bin."/../../dict/cooc",
);
my $scorer    = 'scorer -u 3 -m Pos -p ';

BEGIN {
    use POSIX qw(uname);
    if ((my $machine = (uname)[4]) !~ m/(x86|i686)/gmx) {
        die "This package won't run on platforms except x86 family.";
    }
}

sub new {
    my $class = shift;
    my %scorer_params = (
        type  => 'newswire',
        prob  => 'MI',
        model => 'n1000',
        pat   => 'ncv',
        @_,
    );
    my $self  = {};
    bless $self, $class;

    opendir 'DIR', $model_dir{$scorer_params{type}};
    my @file = grep /$scorer_params{model}/, readdir DIR;
    closedir DIR;

    my $model_path = $model_dir{$scorer_params{type}}.'/'.$scorer_params{model};
    my $model_prob = $scorer_params{prob};
    if ($model_prob eq 'chi2') {
        chomp (my $N = `tail -n 1 $model_dir{$scorer_params{type}}/Ndic | cut -f4`);
        $model_prob   .= " -t $N";
    }
    die "Cannot find models in $model_path" if ! -e $model_path.'.pz.da';
    my ($pid, $out, $in);
    $scorer = 'scorer -u 2 -m Pos -p ' if ($scorer_params{pat} eq 'cv');

    $pid = open2 $out, $in, "$scorer $model_prob -d $model_path";

    $self->{pid} = $pid;
    $self->{out} = $out;
    $self->{in}  = $in;

    $self;
}

sub get_pid {
    my $self = shift;
    $self->{pid};
}

sub get_out {
    my $self = shift;
    $self->{out};
}

sub get_in {
    my $self = shift;
    $self->{in};
}

sub get_score {
    my $self = shift;
    my $csv  = shift;

    my $in   = $self->get_in;
    my $out  = $self->get_out;
    print $in "$csv\n";
    chomp(my $score = <$out>);

    return ($score eq '4294967295') ? undef : $score;
}

sub DESTROY {
    my $self = shift;

    close $self->get_in;
    close $self->get_out;
    waitpid($self->get_pid, 0);
}

1;
