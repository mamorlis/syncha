#!/usr/bin/perl
# Created on 4 Jan 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# 魑魅魍魎

use strict;
use warnings;

use MyCabocha;
use NCVTool;

use English;
local $LIST_SEPARATOR = '';
use Carp;
use Data::Dumper;
use File::Temp qw(tempfile);
use XML::Simple qw(XMLout);

use Getopt::Std;
use vars qw($opt_b $opt_d $opt_f $opt_t $opt_m $opt_o $opt_r $opt_i $opt_h);
getopts('b:d:f:t:m:o:r:ih');

my $usage =<<"EOM";
$0: -b model [-dfmrtih]
  -b: {bact,svm}_model
  -d: mod dir
  -f: features to unselect
  -m: machine learning method to use (svm/bact)
  -o: order of tournament model (reverse)
  -r: start:end positions of mod files
  -t: type of pred
  -i: toggles inter- and intra-sentential mode
  -h: prints this help
EOM

die $usage if $opt_h;
die $usage unless $opt_b;

use RyuBact;
my $bact = new RyuBact ($opt_f, $opt_b, $opt_m);
use Tournament;

my %marker = ( 'ga' => 'が', 'o' => 'を', 'ni' => 'に', );

my $mod_dir = $opt_d || 'mod_test';
opendir my $mod_dh, $mod_dir or die "Cannot open $mod_dir/:$!\n";
my @mod_files = grep { /\.mod$/ } readdir $mod_dh;

my $mod_max   = scalar @mod_files;
my $pred_type = $opt_t || 'EVENT';
my $from_to   = $opt_r || "0:$mod_max";
my ($mod_start, $mod_end) = (split /:/, $from_to);

for (my $i = $mod_start; $i < $mod_end; ++$i) {
    open my $mod, '<', $mod_dir.'/'.$mod_files[$i]
        or die 'Cannot open a modfile.';
    my $cab = new MyCabocha ($mod);
    close $mod;
    tournament($cab);
}

sub left_branch {
    my $nps_ref = shift;
    if (scalar @$nps_ref == 0) {
        die;
    } elsif (scalar @$nps_ref == 1) {
        return @$nps_ref;
    } elsif (scalar @$nps_ref == 2) {
        return $nps_ref;
    } else {
        my $right = pop @$nps_ref;
        return [ left_branch($nps_ref), $right ]
    }
}

sub right_branch {
    my $nps_ref = shift;
    if (scalar @$nps_ref == 0) {
        die;
    } elsif (scalar @$nps_ref == 1) {
        return @$nps_ref;
    } elsif (scalar @$nps_ref == 2) {
        return $nps_ref;
    } else {
        my $left = shift @$nps_ref;
        return [ $left, right_branch($nps_ref) ];
    }
}

sub chunk_robin {
    my $nps_ref  = shift;
    my %nps_of_chunk;
    for my $np (@$nps_ref) {
        push @{ $nps_of_chunk{$np->get_chunk_id} }, $np;
    }
    my $tree_ref;
    my @tmp_nps;
    for my $chunk_id (sort { $a <=> $b } keys %nps_of_chunk) {
        my @nps = @{$nps_of_chunk{$chunk_id}};

        # construct a pair even if only one child exists
        if (scalar @nps == 1) {
            push @tmp_nps, shift @nps;
            next;
        } else {
            push @nps, @tmp_nps;
            @tmp_nps = ();
        }

        if (!$tree_ref) {
            $tree_ref = left_branch(\@nps);
        } else {
            $tree_ref = [ $tree_ref, left_branch(\@nps) ];
        }
    }
    if (@tmp_nps and !$tree_ref) {
        my $right = pop @tmp_nps;
        $tree_ref = [ left_branch(\@tmp_nps), $right ];
    } elsif (@tmp_nps) {
        $tree_ref = [ $tree_ref, left_branch(\@tmp_nps) ];
    }
    return $tree_ref;
}

sub tournament {
    my $cab = shift;
    for my $morph ($cab->get_all_morph) {
        my $text = $morph->get_text;
        if ($morph->get_type eq $pred_type) {
            for my $case (qw(ga o ni)) {
                if ((my $ln = $morph->get_case($case)) =~ m/^\d+/gmx) {
                    # 項が外界でない場合
                    my $vframe = ':'.$marker{$case}
                                .':'.$morph->get_read;
                    $vframe .= 'する' if $pred_type eq 'EVENT';
                    my $arg = $cab->get_arg($ln);
                    if (${$arg->get_text}->get_id ne $$text->get_id) {
                        # 文間にある
                        next if $opt_i;
                    }

                    my $tournament = new Tournament (
                        model  => $opt_b,
                        morph  => $morph,
                        vframe => $vframe,
                        debug  => 1,
                    );
                    $tournament->xml($morph, $arg, join(q[], $$text->get_surface));

                    my @nps = grep { !$cab->equals($_,$morph) }
                                @{ $$text->get_np };
                    if (@nps < 1) {
                        print 'Nothing to compare', "\n";
                    } elsif (@nps == 1) {
                        print $nps[0]->get_id, "\n";
                    } else {
                        my $winner;
                        if (defined $opt_o and $opt_o eq 'reverse') {
                            $winner
                                = $tournament->traverse(right_branch(\@nps));
                        } elsif (defined $opt_o and $opt_o eq 'round_robin') {
                            $winner = $tournament->round_robin(\@nps);
                        } elsif (defined $opt_o and $opt_o eq 'chunk_robin') {
                            $winner
                                = $tournament->traverse(chunk_robin(\@nps));
                        } elsif (defined $opt_o and $opt_o eq 'hierarchical') {
                            my @nps_chunk = grep { $_->get_chunk_id
                                                == $morph->get_chunk_id }
                                                @nps;
                            if (@nps_chunk == 0) {
                                $winner
                                    = $tournament->traverse(left_branch(\@nps));
                            } else {
                                my $tmp_winner
                                    = $tournament->traverse(left_branch(\@nps));
                                my $chunk_winner;
                                if (@nps_chunk == 1) {
                                    $chunk_winner = shift @nps_chunk;
                                } else {
                                    $chunk_winner
                                        = $tournament->traverse(left_branch(\@nps_chunk));
                                }
                                my ($l, $r);
                                if ($cab->before($tmp_winner, $chunk_winner)) {
                                    $l = $tmp_winner;
                                    $r = $chunk_winner;
                                } else {
                                    $l = $chunk_winner;
                                    $r = $tmp_winner;
                                }
                                $winner = $tournament->traverse([$l, $r]);
                            }
                        } else {
                            $winner
                                = $tournament->traverse(left_branch(\@nps));
                        }
                        push @{$tournament->xml->{RESULT}},
                            { WINNER   => { surface  => $winner->get_surface,
                                            morph_id => $winner->get_id,
                                            chunk_id => $winner->get_chunk_id,
                                            correct  => ($cab->equals($arg, $winner)) ? 1 : 0,
                                          },
                            };
                        if ($cab->equals($arg, $winner)) {
                            print 'o';
                        } elsif ($winner->get_surface =~
                                m/^(くん|さま|様|チャン|殿|さん|ちゃん|サマ|クン|どの|ちゃーん|君|ら|氏)$/gmx) {
                            if ($cab->equals($arg, ${$winner->prev})) {
                                print 'o';
                            } else {
                                print 'x';
                            }
                        } else {
                            print 'x';
                        }
                        if ($arg->get_chunk_id == $winner->get_chunk_id) {
                            print ' b';
                        } else {
                            print ' q';
                        }
                        print ' system = ', $winner->get_surface, $vframe,
                            ', actual = ', $arg->get_surface, $vframe,
                            ', [', $$text->get_surface, ']',
                            "\n";
                        print STDERR XMLout($tournament->xml, RootName => 'Tournament');
                    }
                }
            }
        }
    }
}

