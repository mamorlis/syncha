package ENA;

require Exporter;

=head1 NAME

ENA - Event Noun Annotation

=cut

#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

our $VERSION = "1.4";

@ISA       = qw(Exporter);
@EXPORT    = qw(annotate get_db_dir get_gdbm_dir get_tools_dir
                get_mod_dir);
@EXPORT_OK = qw();

use vars qw($DEBUG $MEDIUM %options);
my $DEBUG = 0;

# Import environment variables
use ENA::Conf;
use ENA::PLSI;
use ENA::Bgh;

my $plsi = new ENA::PLSI;
my $bgh  = new ENA::Bgh;

use strict;
use Carp qw(croak carp);
use Data::Dumper;
use Encode qw(encode_utf8 decode_utf8);

=head1 SYNOPSIS

  use ENA;

=head1 DESCRIPTION

Event Noun Annotator decides whether a noun refers to an event or not.
It also identifies argument structure of an event if it refers to a
specific event.

=cut


# 飯田さんからもらったスクリプト
use FindBin qw($Bin);
use lib "$Bin/../lib";
require 'mod.pm';

my $sem_offset = 50000;
my $syn_offset = 60000;

# 素性を一意にするため
my $morph_id = 0;
sub set_morph_id {
    $morph_id = shift;
}

sub get_morph_id {
    return $morph_id;
}

sub inc_morph_id {
    $morph_id++;
}

# morph id から引ける素性リスト
my %feature_of;
# 意味役割と素性番号のマッピング保持用ハッシュ
my %sem_role;
my %syn_rule;

sub set_feature {
    my $feature_ref = shift;
    my %feature = %{$feature_ref};
    my %feature_list;
    my %feature_name;

    # 分類語彙表でどこにいるかという素性
    if ($feature{bgh_id}) {
        my $bgh_id = $feature{bgh_id};
        my $offset = 10000000;
        #my @level_at = qw(1 2 3 4 5 6 7);
        # 素性は5つまで合っていればよい
        my @level_at = qw(5 6 7);
        for my $level (@level_at) {
            my $feature_id = $offset
                             + substr($bgh_id, 0, $level)
                             * (10 ** ($level_at[-1] - $level));
            $feature_list{$feature_id}++;
            $feature_name{$feature_id} = "BGH_$feature_id";
        }
    }

    # 格要素が埋まっているかどうかの素性
    foreach my $key (keys %feature) {
        last if $options{b};   # -b のときは共起は見ない

        carp "FEATURE_KEY: ", $key if $DEBUG and $key ne 'morph_id';
        my $threshold = 1.0;   # 1.0 以下はそれっぽくない

        if ($key =~ m/^sem_(.*)$/xms) {
            my $attribute = $1;
            if ($attribute eq 'bridge') {
                $feature_list{$sem_offset} = 1;
                $feature_name{$sem_offset} = "SEM_BRIDGE";
            }
            else {
                if ($attribute =~ m/(.*)_(.*)$/xms) {
                    my $attr_name = $1;
                    my $index = $2;
                    $index += $sem_offset + 1;
                    $feature_list{"$index"} = 1;
                    $feature_name{"$index"} = "SEM_$attr_name";
                }
            }
        }

        if ($key =~ m/^syn_(.*)$/xms) {
            my $rule = $1;
            if (!$syn_rule{$rule}) {
                $syn_rule{$rule} = scalar(keys %syn_rule) + 1;
            }
            $feature_list{$syn_rule{$rule} + $syn_offset} = 1;
            $feature_name{$syn_rule{$rule} + $syn_offset} = "SYN_$rule";
        }
    }

    # SVM で分類できるように
    $feature_list{$feature{morph_id}} = 1;
    $feature_name{$feature{morph_id}} = "MORPH_ID_".$feature{morph_id};

    # 出力
    # ====
    # 動作性なら正例に追加、動作性でなければ負例に追加
    $feature_of{get_morph_id()} = $feature{event} ? "$feature{event} " : "-1 ";
    if ($options{t}) {
        # BACT
        $feature_of{get_morph_id()} .= '(ROOT ';
        foreach my $feature_name (values %feature_name) {
            $feature_of{get_morph_id()} .= "($feature_name)";
        }
        $feature_of{get_morph_id()} .= ')';
    }
    else {
        foreach my $feature (keys %feature_list) {
            #print "$feature:$feature_list{$feature} ";
            $feature_of{get_morph_id()} .= "$feature:1 ";
        }
    }

    if ($DEBUG) {
        # デバッグ用
        $feature_of{get_morph_id()} .=  '# ';
        $feature_of{get_morph_id()} .=  'MORPH_ID:'. $feature{morph_id}. q{,};
        foreach my $key (keys %feature) {
            if ($key =~ m/^(.*_word_form)$/xms) {
                $feature_of{get_morph_id()} .=  uc "$1:". $feature{$1}. q{,};
            }
            elsif ($key =~ m/^(case_(.*))$/xms) {
                my $case_feature = $1;
                my $case_marker  = uc $2;
                $feature_of{get_morph_id()} .=  "$case_marker:". $feature{"$case_feature"}. q{,};
            }
            elsif ($key =~ m/^((sem|syn|bgh)_.*)$/xms) {
                $feature_of{get_morph_id()} .=  uc "$1:". $feature{$1}. q{,};
            }
        }
        $feature_of{get_morph_id()} .=  'SENTENCE:'. $feature{sentence};
    }
}

sub get_feature {
    my $id = shift;
    return $feature_of{$id};
}

sub get_all_feature {
    return %feature_of;
}

sub write_feature {
    print $feature_of{get_morph_id()}, "\n";
}

sub get_current_feature {
    return $feature_of{get_morph_id()};
}

# 文を素性リストに直す手続き
sub make_train_data {
    # Text が入ってくる
    my $text = shift;
    my $noun_list_ref = shift;
    my %opt = ( OUTPUT => 1, @_, );

    my $sentence = $text->get_surface;

    # FIXME: not defined
    last if !$text->get_chunk;
    my @chunks = @{ $text->get_chunk };

    for (my $i = 0; $i < @chunks; $i++) {
        my $chunk = $chunks[$i];
        my @morphs  = @{ $chunk->get_morph };
        my ($prev_chunk, @prev_morphs);
        if ($i > 0) {
            $prev_chunk  = $chunks[$i-1];
            @prev_morphs = @{ $prev_chunk->get_morph };
        }
        my ($next_chunk, @next_morphs);
        if ($i < @chunks - 1) {
            $next_chunk  = $chunks[$i+1];
            @next_morphs = @{ $next_chunk->get_morph };
        }
        my $word_form      = $chunk->get_surface;
        my $head_word_form = $chunk->get_head->get_surface;
        my $head_pos       = $chunk->get_head->get_pos;

        # 文節に関する素性(BACT で使用)
        my $syn_morphs_pos = '';
        for my $morph (@morphs) {
            $syn_morphs_pos .= "($morph->get_pos)";
        }
        
        # FIXME: ad hoc feature
        my $sem_bridge;
        my $syn_prev_morphs_pos = '';
        if ($i > 0) {
            # 最後の形態素
            my $bridge = $prev_morphs[-1];
            my $bridge_cand = $prev_morphs[-2];
            if ($bridge->get_surface eq 'の') {
                $sem_bridge = $bridge_cand->get_surface;
            }
            for my $morph (@prev_morphs) {
                $syn_prev_morphs_pos .= "($morph->get_pos)";
            }
        }
        my $syn_next_morphs_pos;
        if ($i < @chunks - 1) {
            $syn_next_morphs_pos = join q{},
                                   map { "($_->get_pos)" } @next_morphs;
        }

        #if ($segment->PRED) {
        #    # 述語のときは単に無視する
        #    next;
        #}

        for (my $mid = 0; $mid < @morphs; $mid++) {
            my $morph = $morphs[$mid];
            my %feature;
            if ($morph->get_pos =~ /^名詞-サ変/) {
                # サ変名詞が見つかった
                carp 'SAHEN: ', $morph->get_surface if $DEBUG;

                # 分類語彙表を見る
                my $bgh_id  = $bgh->get_class_id_frac($morph->get_surface);

                carp "BGH: $bgh_id, WF: ", $morph->get_surface if $DEBUG;

                # 形態素の素性
                $feature{head_word_form}    = $head_word_form;
                $feature{segment_word_form} = $word_form;
                $feature{morph_word_form}   = $morph->get_surface;
                $feature{bgh_id}    = $bgh_id;
                
                # 文節の素性
                $feature{syn_morphs_pos}      = $syn_morphs_pos;
                $feature{syn_prev_morphs_pos} = $syn_prev_morphs_pos;
                $feature{syn_next_morphs_pos} = $syn_next_morphs_pos;
                $feature{sem_bridge}          = $sem_bridge;

                # BACT から学習した素性
                my ($has_sahen_after, $has_sahen_before) = 0 x 2;
                my @before_morphs = @prev_morphs;
                if ($mid > 1) {
                    push @before_morphs, @morphs[0..($mid-1)];
                }
                my @after_morphs;
                if ($mid < @morphs) {
                    push @after_morphs,  @morphs[($mid+1)..$#morphs];
                }
                push @after_morphs, @next_morphs;

                # 前後にサ変があるか
                for my $before_morph (@before_morphs) {
                    if ($before_morph->get_pos =~ /名詞-サ変/) {
                        $has_sahen_before++;
                        $feature{syn_sahen_before} = 1;
                    }
                }
                for my $after_morph (@after_morphs) {
                    if ($after_morph->get_pos =~ /名詞-サ変/) {
                        $has_sahen_after++;
                        $feature{syn_sahen_after} = 1;
                    }
                }
                
                # 事態性プラスに働く素性
                # サ変のあとに助詞が来る
                if ($has_sahen_after) {
                    for (my $mid = 0; $mid < @after_morphs - 1; $mid++) {
                        if ($after_morphs[$mid]->get_pos =~ m/^名詞-サ変/xms) {
                            if ($after_morphs[$mid+1]->get_pos =~ m/^助詞/xms) {
                                $feature{syn_sahen_particle_after} = 1;
                            }
                            elsif ($after_morphs[$mid+1]->get_pos =~ m/^名詞-一般/xms) {
                                $feature{syn_sahen_general_after} = 1;
                            }
                        }
                    }
                }
                
                # 前文節に関する素性
                if ($has_sahen_before) {
                    for my $before_morph (@before_morphs) {
                        if ($before_morph->get_pos =~ m/^名詞-一般/xms) {
                            $feature{syn_sahen_general_before} = 1;
                        }
                    }
                }

                # サ変+名詞接尾となっている
                if ($morphs[$mid+1] and
                    $morphs[$mid+1]->get_pos =~ m/^名詞-接尾/xms) {
                    $feature{syn_suffix} = 1;
                }

                # サ変が複数入っている
                my $number_of_sahen = 0;
                for my $morph (@morphs) {
                    if ($morph->get_pos =~ m/^名詞-サ変/xms) {
                        $number_of_sahen++;
                    }
                }
                if ($number_of_sahen >= 2) {
                    $feature{syn_sahen_compound} = 1;
                }

                # 項が当たっているかどうか
                foreach my $case (qw{GA WO NI}) {
                    if (my $morph_case_id = $morph->get_case($case)) {
                        foreach (@morphs) {
                            if ($_->get_id and ($_->get_id eq $morph_case_id)) {
                                $feature{"case_$case"} = $_->get_surface;
                            }
                        }
                    }
                }

                # デバッグ用に格が埋まっているかどうか周辺文脈
                $feature{sentence}  = $sentence;

                # 事態タグが付いているかどうか
                if ($morph->get_type =~ /event/i) {
                    $feature{event} = 1; 
                    #if ($morph->get_case('GA')) {
                    #    $feature{event} += 2;
                    #}
                    #if ($morph->get_case('WO')) {
                    #    $feature{event} += 4;
                    #}
                    #if ($morph->get_case('NI')) {
                    #    $feature{event} += 8;
                    #}
                }

                # 名詞としての処理
                foreach my $morph (@morphs) {
                    if ($morph->get_pos =~ /^名詞/) {
                        push @{ $noun_list_ref }, $morph;
                        $feature{noun_id} = scalar @{ $noun_list_ref };
                    }
                }
            }
            else { # not サ変
                # 名詞が見つかった
                foreach my $morph (@morphs) {
                    if ($morph->get_pos =~ /^名詞/) {
                        push @{ $noun_list_ref }, $morph;
                    }
                }
            }

            # あらゆる形態素に feature がつく
            $feature{morph_id} = get_morph_id;

            # 名詞の意味素性を追加
            set_feature(\%feature);

            # 分類語彙表にあるものだけ対象にする
            if ($feature{bgh_id}) {
                write_feature() if $opt{OUTPUT};
            }

            inc_morph_id();
        }
    }
}

1;
# vi:ts=4:expandtab:
