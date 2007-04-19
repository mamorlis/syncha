#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";

require 'MyCabocha.pm';

my @ids;
my %id_of;
my $new_id = 0;

my $cab = new MyCabocha(*STDIN);
#$cab->puts;
#my @lines = <>;
#
for my $text (@{ $cab->get_text }) {
    next unless $text->get_chunk;
    for my $chunk (@{ $text->get_chunk }) {
        for my $morph (@{ $chunk->get_morph }) {
            if ($morph->get_relation =~ m/EVENT:(\S+)/) {
                my @cases = split /,/, $1;
                my @case_ids = map { $_ =~ s/(GA|WO|NI)=//g } @cases;
                push @ids, @cases;
            }
        }
    }
}

# WO:0:3:1 から一意の ID のハッシュを作る
# (形式は CASE:TEXT_ID:CHUNK_ID:MORH_ID)
# CASE     => (GA|WO|NI)
# TEXT_ID  => numeric
# CHUNK_ID => numeric
# MORPH_ID => numeric
for my $id (sort @ids) {
    $id_of{$id} = $new_id;
    $new_id++;
}

#carp Dumper %id_of;

for my $id (keys %id_of) {
    my ($tid, $cid, $mid) = split /:/, $id;
    for my $text (@{ $cab->get_text }) {
        if ($tid eq $text->get_id) {
            for my $chunk (@{ $text->get_chunk }) {
                if ($cid eq $chunk->get_id) {
                    for my $morph (@{ $chunk->get_morph }) {
                        if ($mid eq $morph->get_id) {
                            my $relation = $morph->get_relation;
                            if (defined $relation) {
                                $relation .= " ID=$id_of{$id}";
                            } else {
                                $relation = "ID=$id_of{$id}";
                            }
                            $morph->set_relation($relation);
                        }
                    }
                }
            }
        }
    }
}

for my $text (@{ $cab->get_text }) {
    next unless $text->get_chunk;
    for my $chunk (@{ $text->get_chunk }) {
        for my $morph (@{ $chunk->get_morph }) {
            if ($morph->get_relation =~ m/EVENT:(\S+)/) {
                my @cases = split /,/, $1;
                map { $_ =~ s/(GA|WO|NI)=(\S+)/$1=$id_of{$2}/g } @cases;
                my $new_case = join(q{,}, @cases);
                (my $relation = $morph->get_relation) =~ s/$1/$new_case/;
                $morph->set_relation($relation);
            } elsif ($morph->get_relation =~ m/(TYPE:\S+)/) {
                # does nothing?
            }
        }
    }
}

$cab->puts;
