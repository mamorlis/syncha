#!/usr/local/bin/perl -w

# ===================================================================
my $NAME         = 'ext_cab.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = '';
# ===================================================================

use strict;
use Getopt::Std;

my $usage = <<USG;
./ext_cab.pl -i txt_dir -o cab_dir -c chasenrc
USG

my %options;
getopts("i:o:c:h", \%options);
die $usage if ($options{h});
die $usage unless ($options{i});
die $usage unless ($options{o});
die $usage unless ($options{c});

opendir 'DIR', $options{i} or die $!;
my @file = sort grep /\.txt$/, readdir DIR;
closedir DIR;

for my $file (@file) {
    my $in  = $options{i}.'/'.$file;
    my $out = $options{o}.'/'.$file; $out =~ s/txt$/cab/;
    `cabocha -f 1 -c $options{c} < $in > $out`;
}
