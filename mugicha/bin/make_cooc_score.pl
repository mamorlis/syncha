#!/usr/bin/perl
# Created on 30 Dec 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# 魑魅魍魎

use strict;
use warnings;

#use encoding 'euc-jp', STDOUT => 'euc-jp', STDERR => 'euc-jp';

use MyCabocha;
use Semantics::Cooc;
use Carp;
use Data::Dumper;

use Getopt::Std;
use vars qw($opt_d $opt_t $opt_i $opt_c $opt_p $opt_m $opt_h);
getopts('d:t:m:ic:p:h');

my $usage =<<"EOM";
$0: [-d mod dir] [-t type of pred] [-c cooc model] [-p probabilistic model] [-m plsi prefix] [-i]
EOM

die $usage if $opt_h;

my %marker = ( 'ga' => 'が', 'o' => 'を', 'ni' => 'に', );
my %model  = ( type  => $opt_c || 'web',
               model => $opt_m || 'web-n4000',
               prob  => $opt_p || 'MI',
);
my $cooc_mi = new Semantics::Cooc (type => 'newswire', prob => 'MI');
my $web_mi  = new Semantics::Cooc (%model, prob => 'MI');
my $cooc_c2 = new Semantics::Cooc (type => 'newswire', prob => 'chi2');
my $web_c2  = new Semantics::Cooc (%model, prob => 'chi2');
#my $ty_mi   = new Semantics::Cooc (model => 'ty-n1000', prob => 'MI');
#my $ty_c2   = new Semantics::Cooc (model => 'ty-n1000', prob => 'chi2');

my $mod_dir = $opt_d || 'mod';
opendir my $mod_dh, $mod_dir or die "Cannot open $mod_dir:$!\n";
my @mod_files = grep { /\.mod$/ } readdir $mod_dh;
close $mod_dh;

my $mod_max   = scalar @mod_files;
my $pred_type = $opt_t || 'EVENT';

for (my $i = 0; $i < $mod_max; ++$i) {
    my $mod_file = $mod_dir.'/'.$mod_files[$i];
    open my $mod, '<', $mod_file or die "Cannot open a $mod_file:$!\n";
    my $cab = new MyCabocha ($mod);
    close $mod;
    tournament($cab, $mod_file);
}

sub tournament {
    my ($cab, $mod_file) = @_;
    for my $morph ($cab->get_all_morph) {
        my $text = $morph->get_text;
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
                    if (${$arg->get_text}->get_id ne $$text->get_id) {
                        # 文間にある
                        next if $opt_i;
                    }
                    my %arg_score = (
                        NEWS_MI   => $cooc_mi->calc_score($vframe, $arg),
                        WEB_MI    => $web_mi->calc_score($vframe, $arg),
                        #TY_MI     => $ty_mi->calc_score($vframe, $arg),
                        NEWS_CHI2 => $cooc_c2->calc_score($vframe, $arg),
                        WEB_CHI2  => $web_c2->calc_score($vframe, $arg),
                        #TY_CHI2   => $ty_c2->calc_score($vframe, $arg),
                    );
                    my $arg_surface = $arg->get_surface;
                    if ($arg_score{NEWS_MI} eq 'NaN'
                        and $arg_score{WEB_MI} eq 'NaN') {
                        printf STDERR ":%s=x(%s)", $case, $arg_surface;
                    } elsif ($arg_score{NEWS_MI} eq 'NaN') {
                        printf STDERR ":%s=w", $case;
                    } else {
                        printf STDERR ":%s=o", $case;
                    }
                    my $arg_cid = $arg->get_chunk_id;
                    my $arg_id = $arg_cid.':'.$arg->get_id;
                    for my $np (@{ $$text->get_np }) {
                        if ($cab->equals($np, $morph)) {
                            next;
                        }
                        my %np_score = (
                            NEWS_MI   => $cooc_mi->calc_score($vframe, $np),
                            WEB_MI    => $web_mi->calc_score($vframe, $np),
                            #TY_MI     => $ty_mi->calc_score($vframe, $np),
                            NEWS_CHI2 => $cooc_c2->calc_score($vframe, $np),
                            WEB_CHI2  => $web_c2->calc_score($vframe, $np),
                            #TY_CHI2   => $ty_c2->calc_score($vframe, $np),
                        );
                        my $np_surface = $np->get_surface;
                        my $np_cid = $np->get_chunk_id;
                        my $np_id = $np_cid.':'.$np->get_id;
                        my $instance;
                        if ($cab->before($np, $arg)) {
                            $instance = '+1';
                        } elsif ($cab->after($np, $arg)) {
                            $instance = '-1';
                        }
                        if ($instance) {
                            $instance .= q[ ].$mod_file.':'.$$text->get_id
                                        .q[ ].$morph->char.':'.$morph->len
                                        .q[ ].$np->char.':'.$np->len
                                        .q[ ].$arg->char.':'.$arg->len
                                        .q[ ].'vp:'.$vframe
                                        .q[ ].'arg:'.$arg_score{NEWS_MI}.','
                                                    .$arg_score{WEB_MI}.','
                                                    #.$arg_score{TY_MI}.','
                                                    .$arg_score{NEWS_CHI2}.','
                                                    .$arg_score{WEB_CHI2}.','
                                                    #.$arg_score{TY_CHI2}.','
                                        .q[ ].'np:'.$np_score{NEWS_MI}.','
                                                   .$np_score{WEB_MI}.','
                                                   #.$np_score{TY_MI}.','
                                                   .$np_score{NEWS_CHI2}.','
                                                   .$np_score{WEB_CHI2}.','
                                                   #.$np_score{TY_CHI2}.','
                                                   ;
                            if ($np_cid == $arg_cid) {
                                $instance .= ' same_chunk';
                            }
                            if ((my $id = ${$np->get_parent}->get_depend_id) > 0 ) {
                                if ($$text->get_chunk_by_id($id)->get_id == $arg_cid) {
                                    $instance .= ' dep_chunk';
                                }
                            }
                            # flush
                            print $instance, ' [', $$text->get_surface, ']', "\n";
                        }
                    }
                }
            }
            print STDERR ':[', $$text->get_surface, ']', "\n";
        }
    }
}
