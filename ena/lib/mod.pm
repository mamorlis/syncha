#!/usr/bin/perl -w

use strict;

require 'Cab2.pm';

package Mod;

sub new {
    my $type = shift;
    my $self = {}; bless $self;
 
    my $mod_dir = $ENV{ENA_MOD_DIR}.'/';

    opendir 'DIR', $mod_dir or die "$!\n";
    my @file = sort grep /mod$/, readdir DIR; my $f_num = @file;
    closedir DIR;
    for (my $i=0;$i<$f_num;$i++) { $file[$i] = $mod_dir.$file[$i]; }

    my @t = ();
    for my $file (@file) {
        print STDERR 'mod: ', $file, "\n";
        my $tid = $file; $tid =~ s/\.mod//; 
        my $t = Cab::open_cab_file($file, $tid);
        $t->id($tid);
        push @t, $t;
    }

    $self->txt(\@t);
    return $self;
}

# test用．1事例だけ．
sub new_one {
    my $type = shift; my $fileno = shift;
    my $self = {}; bless $self;
    $fileno = 0 unless ($fileno);

    my $mod_dir = $ENV{ENA_MOD_DIR}."/";
    opendir 'DIR', $mod_dir or die "Cannot open directory $mod_dir:$!\n";
    my @file = sort grep /mod$/, readdir DIR; my $f_num = @file;
    closedir DIR;
    for (my $i=0;$i<$f_num;$i++) { $file[$i] = $mod_dir.$file[$i]; }

    my @t = ();
#     for my $file (@file) {
    my $file = $file[$fileno];
    print STDERR 'mod: ', $file, "\n";
    my $tid = $file; $tid =~ s/\.mod//; 
    my $t = Cab::open_cab_file($file, $tid);
    $t->id($tid);
    push @t, $t;
#       last;
#     }

    $self->txt(\@t);
    return $self;
}

sub new_file {
    my $type = shift; my $file = shift;
    my $self = {}; bless $self;

    my @t = ();

    # something must be defined
    my $tid = int(rand(8));
    my $t = Cab::open_cab_file($file, $tid);
    $t->id($tid);
    push @t, $t;

    $self->txt(\@t);
    return $self;
}

sub txt {
    my $self = shift;
    if (@_) {
        $self->{txt} = $_[0];
    } else {
        return $self->{txt};
    }
}

1;
