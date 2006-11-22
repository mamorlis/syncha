#!/usr/bin/perl -w

=comment

  ENA -- Event Noun Annotator

  $Id$

  Copyright (C) 2005-2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>
=cut

use strict;
use warnings;

package Check::Event;

use Carp qw(croak carp);
use Data::Dumper;

use FindBin qw($Bin);
use lib "$Bin/../lib";
#use ENA;

use File::Temp qw(tempfile);

my %score_of;

sub new {
    my $class      = shift;
    my $model_file = shift;
    my $mod        = shift;
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
    for my $text (@{ $mod->txt }) {
        my @noun_list;
        for my $sentence (@{ $text->Sentence }) {
            ENA::makeTrainData($sentence, \@noun_list, OUTPUT => 0);
            for my $segment (@{ $sentence->Bunsetsu }) {
                for my $morph (@{ $segment->Mor }) {
                    if ($morph->POS =~ m/^名詞-サ変/) {
                        print $test_file ENA::get_feature($morph_id), "\n";
                        push @morph_ids, $morph_id;
                    }
                    $morph_id++;
                }
            }
        }
    }

    # SVM-Light is not supported -- assumes TinySVM installed
    my @classify = ("/usr/bin/svm_classify", "-V",
                    "$test_file" , "$model_file");

    # (2)
    my @scores = split /\n/, `@classify | cut -d' ' -f2`
        or croak "@classify failed: $?";

    # (3)
    for (my $i = 0; $i < @morph_ids; ++$i) {
        $score_of{$morph_ids[$i]} = $scores[$i];
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
