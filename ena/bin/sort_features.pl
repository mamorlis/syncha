#!/usr/bin/perl
# Created on 20 Sep 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>

use strict;
use warnings;

while (<>) {
    chomp;
    my ($pn, @features) = split;
    @features = map { "$_:1" }
                sort { $a <=> $b }
                map { (split /:/)[0] }
                @features;
    print $pn, ' ', join(' ', @features), "\n";
}
