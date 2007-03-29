#!/usr/bin/perl
# Created on 30 Dec 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# 魑魅魍魎

use strict;
use warnings;

use MyCabocha;
use RyuBact;

use English;
local $LIST_SEPARATOR = '';
use Carp;
use Data::Dumper;

use Getopt::Std;
use vars qw($opt_f $opt_t $opt_d $opt_m $opt_r $opt_i $opt_h);
getopts('f:t:d:m:r:ih');

my $usage =<<"EOM";
$0: [-f features to disable] [-d mod dir] [-m # of mod] [-r start:end] [-t type of pred] [-i]
EOM

die $usage if $opt_h;

my $bact = new RyuBact ($opt_f);
my %marker = ( 'ga' => 'が', 'o' => 'を', 'ni' => 'に', );

my $mod_dir = $opt_d || 'mod';
opendir my $mod_dh, $mod_dir or die "Cannot open $mod_dir:$!\n";
my @mod_files = grep { /\.mod$/ } readdir $mod_dh;
close $mod_dh;

my $mod_max   = $opt_m || scalar @mod_files;
my $pred_type = $opt_t || 'EVENT';
my $from_to   = $opt_r || "0:$mod_max";
my ($mod_start, $mod_end) = (split /:/, $from_to);

for (my $i = $mod_start; $i < $mod_end; ++$i) {
    my $mod_file = $mod_dir.'/'.$mod_files[$i];
    open my $mod, '<', $mod_file or die "Cannot open $mod_file:$!";
    my $cab = new MyCabocha ($mod);
    close $mod;
    print STDERR 'Running tournament on features (', $opt_f, ') disabled', "\n" if $opt_f;
    tournament($cab);
}

sub tournament {
    my $cab = shift;
    for my $morph ($cab->get_all_morph) {
        my $text = ${$morph->get_text};
        if ($morph->get_type eq $pred_type) {
            printf STDERR "%s:%s:%s",
                $morph->get_type,
                $morph->get_surface,
                $morph->get_pos;
            for my $case (qw(ga o ni)) {
                if ((my $ln = $morph->get_case($case)) =~ m/^\d+/gmx) {
                    # 項が外界でない場合
                    my $vframe = ':'.$marker{$case}
                                .':'.$morph->get_read;
                    $vframe .= 'する' if $pred_type eq 'EVENT';
                    my $arg = $cab->get_arg($ln);
                    my $arg_text = ${$arg->get_text};
                    if ($arg_text->get_id ne $text->get_id) {
                        # 文間にある
                        next if $opt_i;
                    }
                    for my $np (@{ $text->get_np }) {
                        # skip if not in the same sentence
                        if ($cab->equals($np, $morph)) {
                            next;
                        }

                        my $instance;
                        if ($cab->before($np, $arg)) {
                            $instance = $bact->make_features('+1', $morph, $vframe, $np, $arg);
                        } elsif ($cab->after($np, $arg)) {
                            my @tuple = ( $morph, $vframe, $arg, $np );
                            $instance = $bact->make_features('-1', $morph, $vframe, $arg, $np);
                        }
                        print $instance, "\n" if $instance;
                    }
                }
            }
            print STDERR ':[', $text->get_surface, ']', "\n";
        }
    }
}
