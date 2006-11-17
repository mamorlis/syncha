#!/usr/local/bin/perl -w

# ===================================================================
my $NAME         = 'ext_txt.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = '';
# ===================================================================

use strict;
use Getopt::Std;

my $usage = <<USG;
./ext_txt.pl -i tgr_dir -o txt_dir
USG

my %options;
getopts("i:o:h", \%options);
die $usage if ($options{h});
die $usage unless ($options{i});
die $usage unless ($options{o});

opendir 'DIR', $options{i} or die $!;
my @file = sort grep /\.tgr$/, readdir DIR;
closedir DIR;

for my $file (@file) {
    $/ = "</text>\n";
    open 'FL', $options{i}.'/'.$file or die $!;
    while (<FL>) {
	chomp; my @IN = split '\n', $_;
	my $tid = shift @IN;
	$tid =~ /text id=(\d+)/;  $tid = $1;
	my $cflg = 0; my @s = ();
	for my $in (@IN) {
	    if ($in =~ m|</contents>|) {
		$cflg = 0;
	    } elsif ($in =~ m|<contents>|) {
		$cflg = 1;
	    } elsif ($cflg) {
# 		next unless ($in);
		my $tmp = (split ' ', $in)[1];

		# 【　外界(一人称)　】/ ――――――――――――
		next unless ($tmp);

		$tmp =~ s/<\[(..)+?\]>//g;
		push @s, $tmp;
	    }
	}
	open 'OUT', '>'.$options{o}.'/'.$tid.'.txt' or die $!;
 	print OUT map "$_\n", @s;
# 	for (@s) {
# 	    print OUT $_, "\n"; # if ($_);
# 	}
	close OUT;
    }
    close FL;
}
