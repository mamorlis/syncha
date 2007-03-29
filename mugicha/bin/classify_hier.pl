#!/usr/bin/perl
# Created on 4 Jan 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# 魑魅魍魎

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../bin";

use MyCabocha;
use NCVTool;

use English;
local $LIST_SEPARATOR = '';
use Carp;
use Data::Dumper;
use File::Temp qw(tempfile);
use XML::Simple qw(XMLout);

use Getopt::Std;
use vars qw($opt_b $opt_f $opt_t $opt_m $opt_o $opt_i $opt_h);
getopts('b:f:t:m:o:ih');

my $usage =<<"EOM";
$0: -b model [-dfmrtih]
  -b: {bact,svm}_model
  -f: features to unselect
  -m: machine learning method to use (svm/bact)
  -o: order of tournament model (reverse)
  -t: type of pred
  -i: toggles inter- and intra-sentential mode
  -h: prints this help
EOM

die $usage if $opt_h;
die $usage unless $opt_b;

use RyuBact;
my $bact = new RyuBact ($opt_f, $opt_b, $opt_m);
use Tournament;
require 'predict_case.pl';

# check if support verb is effective or not
use Syntax::Support;
my $support = new Syntax::Support;

my %marker = ( 'ga' => 'が', 'o' => 'を', 'ni' => 'に',
               'が' => 'ga', 'を' => 'o', 'に' => 'ni',
               'GA' => 'が', 'WO' => 'を', 'NI' => 'に', );

my $pred_type = $opt_t || 'EVENT';

sub main {
    my $cab = new MyCabocha (*STDIN);
    classify_hier($cab);
    $cab->puts;
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

sub classify_hier {
    my $cab = shift;
    for my $morph ($cab->get_all_morph) {
        my $text = ${$morph->get_text};
        if ($morph->get_type eq $pred_type) {
            for my $case (predict_case($morph)) {
                $case = ($case eq 'GA') ? 'ga'
                      : ($case eq 'WO') ? 'o'
                      : ($case eq 'NI') ? 'ni'
                      : '';
                    my $vframe = ':'.$marker{$case}
                                .':'.$morph->get_read;
                    $vframe .= 'する' if $pred_type eq 'EVENT';

                    if (my $pred = $morph->get_depend) {
                        my $verb_head = $pred->get_head;
                        my $verb;
                        if ($verb_head->get_read eq 'する') {
                            if (defined $verb_head->prev) {
                                $verb = ${$verb_head->prev}->get_read.'する';
                            } else {
                                $verb = $verb_head->get_read;
                            }
                        } else {
                            $verb = $verb_head->get_read;
                        }
                        my $func = ${$morph->get_chunk}->get_func->get_read;
                        if ($morph->is_head
                            and my $case_align = $support->get_support($verb, $func)) {
                            my ($nom, $acc, $dat) = split q[,], $case_align;
                            my ($pnom, $enom) = split q[:], $nom;
                            my ($pacc, $eacc) = split q[:], $acc;
                            my ($pdat, $edat) = split q[:], $dat;
                            my $pcase =
                                ($marker{$case} eq $enom) ? $marker{$pnom} :
                                ($marker{$case} eq $eacc) ? $marker{$pacc} :
                                ($marker{$case} eq $edat) ? $marker{$pdat} :
                                undef;
                            if (!$pcase) {
                                tournament($morph, $vframe);
                                next;
                            }
                            my $earg = $morph->get_arg_by_case($case);
                            my $parg = $verb_head->get_arg_by_case($pcase);

                            my $result =
                                ($cab->equals($parg, $morph)) ? '?' :
                                ($cab->equals($earg, $parg))  ? 'o' :
                                (ref($earg) eq 'MyCabocha::Morph'
                                     and ref($parg) eq 'MyCabocha::Morph')
                                                              ? 'x' :
                                                                '';

                            if ($result eq 'o') {
                                set_event_arg($morph, $vframe, $earg);
                            } elsif (!$result or $result eq '?') {
                                tournament($morph, $vframe);
                                next;
                            } else {
                                # argument not found
                            }
                        } else {
                            tournament($morph, $vframe);
                        }
                }
            }
        }
    }
}

sub tournament {
    my ($morph, $vframe) = @_;
    my $text = ${$morph->get_text};
    my $cab  = ${$morph->get_cab};

    my $tournament = new Tournament (
        model  => $opt_b,
        morph  => $morph,
        vframe => $vframe,
        debug  => 1,
    );
    $tournament->xml($morph, $morph, join(q[], $text->get_surface));

    my @nps = grep { !$cab->equals($_,$morph) }
                @{ $text->get_np };
    if (@nps <= 1) {
        warn 'Nothing to compare';
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
                          },
            };
        if ($winner->get_surface =~
            m/^(くん|さま|様|チャン|殿|さん|ちゃん|サマ|クン|どの|ちゃーん|君|ら|氏)$/gmx) {
            set_event_arg($morph, $vframe, ${$winner->prev});
        } else {
            set_event_arg($morph, $vframe, $winner);
        }
        #print STDERR XMLout($tournament->xml, RootName => 'Tournament');
    }
}

sub set_event_arg {
    my ($event, $vframe, $arg) = @_;
    my $case = (split q[:], $vframe)[1];
    my $event_str;
    my $arg_id = $arg->get_text_id.':'.$arg->get_chunk_id.':'.$arg->get_id;
    my %marker = ( 'が' => 'GA', 'を' => 'WO', 'に' => 'NI' );
    if ($event->get_relation !~ 'EVENT:') {
        $event_str = 'TYPE:event EVENT:'.$marker{$case}.'='.$arg_id;
    } else {
        $event_str = $event->get_relation.','.$marker{$case}.'='.$arg_id;
    }
    $event->set_relation($event_str);
}

main;
