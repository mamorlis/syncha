#!/usr/bin/perl -w

=comment

  ENA -- Event Noun Annotator

  $Id$

  Copyright (C) 2005-2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
=cut

use strict;
use warnings;

package ENA::Event;

use Carp qw(croak carp);
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
#use ENA;

use File::Temp qw(tempfile);

my %score_of;
my %model_of = ( tinysvm   => "$Bin/../dat/mod/train.svmmodel",
                 svm_light => "$Bin/../dat/mod/train.svmlmodel",
);

sub new {
    my $class      = shift;
    my $toolkit    = shift;
    my $cab        = shift;
    my $self       = {};
    bless $self, $class;

    #
    # テストファイルに
    # (1) 名詞-サ変な素性リストを構築
    # (2) それに対してSVM をかける
    # (3) その結果から %score_of を作成
    #
    my $test_file = new File::Temp( UNLINK => 1 );

    # (1)
    my $morph_id = 0;
    my @morph_ids;
    my @noun_list;
    for my $sentence (@{ $cab->get_text }) {
        ENA::make_train_data($sentence, \@noun_list, OUTPUT => 0);
        for my $chunk (@{ $sentence->get_chunk }) {
            for my $morph (@{ $chunk->get_morph }) {
                if ($morph->get_pos =~ m/^名詞-サ変/) {
                    print $test_file ENA::get_feature($morph_id), "\n";
                    push @morph_ids, $morph_id;
                }
                $morph_id++;
            }
        }
    }

    system("$Bin/sort_features.pl $test_file > $test_file.sorted") == 0
        or croak "Cannot sort $test_file";
    rename "$test_file.sorted", "$test_file" or croak "Cannot mv $test_file";

    # Supports either SVM-Light or TinySVM
    # (2)
    my @scores;
    if ($toolkit eq 'tinysvm') {
        my @classify = ("svm_classify", "-V",
                        "$test_file" , "$model_of{tinysvm}");

        my @scores = split /\n/, `@classify | cut -d' ' -f2`
            or croak "@classify failed: $?";
    } elsif ($toolkit eq 'svm_light') {
        my $score_file = new File::Temp ( UNLINK => 1 );
        my @classify = ("svm_light_classify", "-v", "0",
                        "$test_file" , "$model_of{svm_light}", "$score_file");

        system(@classify) == 0 or croak "Failed to exec @classify:$!";
        open my $score_fh, '<', $score_file
            or croak "Cannot open $score_file";
        @scores = split /\n/, <$score_fh>;
        close $score_fh;
    }

    # (3)
    for (my $i = 0; $i < @morph_ids; ++$i) {
        $score_of{$morph_ids[$i]} = $scores[$i];
    }
    $morph_id = 0;
    for my $sentence (@{ $cab->get_text }) {
        # FIXME: not defined
        next if !$sentence->get_chunk;
        for my $chunk (@{ $sentence->get_chunk }) {
            for my $morph (@{ $chunk->get_morph }) {
                if (defined $score_of{$morph_id} and $score_of{$morph_id} > 0) {
                    $morph->set_relation($morph->get_relation.' EVENT');
                }
                $morph_id++;
            }
        }
    }

    close $test_file;

    return $self;
}

sub is_event {
    my $class    = shift;
    my $morph_id = shift;

    return ($score_of{$morph_id} > 0) ? 1 : 0;
}

1;
