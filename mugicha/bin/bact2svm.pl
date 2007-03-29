#!/usr/bin/perl
# Created on 10 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

bact2svm.pl - Convert BACT training format into SVM.

=head1 SYNOPSIS

  bact2svm.pl [-t hash table] cooc.dat

Bact2svm.pl converts BACT training format file into TinySVM. It emits
TinySVM format lines to stdout, and feature alignment list to stderr.

=cut

use strict;
use warnings;

use Getopt::Std;
use vars qw($opt_h $opt_r $opt_t);
getopts('hrt:');

my $usage =<<__USAGE__;
usage: $0 [-t hash table] [-r] cooc.dat
__USAGE__

die $usage if $opt_h;

my %bact2svm;
my $uniq_id = 1;
my @cooc_score_features = (
    qw(L_COOC_SCORE R_COOC_SCORE COOC_VS_SCORE
    L_WEB_COOC_SCORE R_WEB_COOC_SCORE WEB_COOC_VS_SCORE)
);
if ($opt_r) {
    for (my $i = 0; $i < @cooc_score_features; ++$i) {
        $bact2svm{$cooc_score_features[$i]} = $i + 1;
    }
    $uniq_id += @cooc_score_features;
}

if ($opt_t) {
    open my $table_fh, '<', $opt_t or die "Cannot open $opt_t: $!";
    while (<$table_fh>) {
        chomp;
        my ($bact, $id) = split;
        $bact2svm{$bact} = $id;
        $uniq_id = $id;
    }
    close $table_fh;
    $uniq_id++;
}

while (<>) {
    chomp;
    $_ =~ s/[()]/ /g;
    my ($pn) = (m/^([+-]1)/);
    $_ =~ s/^[+-]1\s+//;
    my @features;
    my %cooc_score_of;
    COOC_FEATURE: for my $feature (split /\s+/, $_) {
        if ($opt_r) {
            for my $cooc_score_feature (@cooc_score_features) {
                if ($feature =~ m/^$cooc_score_feature-(\S+)/gmx) {
                    $cooc_score_of{$cooc_score_feature} = $1;
                }
            }
            next COOC_FEATURE if ($feature =~ m/COOC/);
        }
        if (!exists $bact2svm{$feature}) {
            $bact2svm{$feature} = $uniq_id++;
        }
        push @features, $bact2svm{$feature};
    }
    @features = map { $_ = $_.':1' } sort { $a <=> $b } @features;
    while (my ($cooc_score_feature, $score) = each %cooc_score_of) {
        unshift @features, $bact2svm{$cooc_score_feature}.':'.$score;
    }
    print $pn, q{ }, join(q{ }, @features), "\n";
}

foreach my $bact (sort { $bact2svm{$a} <=> $bact2svm{$b} } keys %bact2svm) {
    print STDERR $bact, "\t", $bact2svm{$bact}, "\n";
}
