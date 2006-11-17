#!/usr/local/bin/perl -w

use strict;

my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
unshift @INC, $scriptPath;
 require 'cab.pl';

package Mod;

sub new {
    my $type = shift;
    my $self = {}; bless $self;
    my $mod_dirs = shift; my @mod_dir = split '\:', $mod_dirs;
#     print STDERR 'mod_dirs: ', $mod_dirs, "\n";
#     @mod_dir = ('/work/ryu-i/zstruct/mod/') unless ($mod_dirs); ## default
    my @file = ();
    for my $mod_dir (@mod_dir) {
	opendir 'DIR', $mod_dir or die "Error: not exists mod_dir\n";
	my @tmpfile = sort grep /mod$/, readdir DIR; my $f_num = @tmpfile;
	closedir DIR;
 	for (my $i=0;$i<$f_num;$i++) { push @file, $mod_dir.$tmpfile[$i]; }
    }
    print STDERR 'file_num: ', scalar(@file), "\n";
    my @t = ();
    for my $file (@file) {
	print STDERR 'mod: ', $file, "\n";
	my $tid = $file; $tid =~ s/\.mod//; 
	my $t = &main::open_cab_file($file, $tid);
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

    my $mod_dir = '/work/ryu-i/zstruct/mod/';

    my $host = `hostname`; chomp $host;
    $mod_dir = '/work2/ryu-i/zstruct/mod/' if ($host =~ /^elm/);

    opendir 'DIR', $mod_dir or die "fir.naist.jpで実行してください\n";
    my @file = sort grep /mod$/, readdir DIR; my $f_num = @file;
    closedir DIR;
    for (my $i=0;$i<$f_num;$i++) { $file[$i] = $mod_dir.$file[$i]; }

    my @t = ();
#     for my $file (@file) {
    my $file = $file[$fileno];
    print STDERR 'mod: ', $file, "\n";
    my $tid = $file; $tid =~ s/\.mod//; 
    my $t = &main::open_cab_file($file, $tid);
    $t->id($tid);
    push @t, $t;
#     	last;
#     }

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
