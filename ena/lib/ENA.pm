package ENA;

require Exporter;

=head1 NAME

ENA - Event Noun Annotation

=cut

#use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

our $VERSION = "1.3";

@ISA       = qw(Exporter);
@EXPORT    = qw(annotate get_db_dir get_gdbm_dir get_tools_dir
                get_mod_dir);
@EXPORT_OK = qw();

use vars qw($DEBUG $MEDIUM %options);

# Import environment variables
use ENA::Conf;

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
require 'calc_mi.pl';

my $sem_offset = 50000;
my $syn_offset = 60000;
my $edr_offset = 70000;

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

        carp "FEATURE_KEY: ", $key if $DEBUG;
        my $threshold = 1.0;   # 1.0 以下はそれっぽくない

        if ($key =~ m/^edr_sem_([^_]*)$/xms) {
            $sem_role{$1} ||= scalar keys %sem_role;
            carp "SEM_ROLE: ", $sem_role{$1}, $1 if $DEBUG;

            if ($feature{$key} > $threshold) {
                $feature_list{$sem_role{$1} + $edr_offset}++;
                $feature_name{$sem_role{$1} + $edr_offset}
                    = "SEM_ROLE_".$1;
            }
        }

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

    if ($options{d}) {
        # デバッグ用
        $feature_of{get_morph_id()} .=  '# ';
        $feature_of{get_morph_id()} .=  'MORPH_ID:'. $feature{morph_id}. q{,};
        foreach my $key (keys %feature) {
            if ($key =~ m/^(.*_word_form)$/xms) {
                $feature_of{get_morph_id()} .=  uc "$1:". $feature{$1}. q{,};
            }
            elsif ($key =~ m/^(edr_sem_([^_]*))$/xms) {
                my $sem_feature      = $1;
                my $sem_feature_word = $sem_feature . '_word';
                my $sem_role         = uc $2;
                if ($feature{"$sem_feature"}) {
                    $feature_of{get_morph_id()} .= "SEM_${sem_role}:".
                        $feature{"$sem_feature"}. q{,};
                    $feature_of{get_morph_id()} .=  "SEM_${sem_role}_WORD:".
                        $feature{"$sem_feature_word"}->{WF}. q{,};
                }
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
sub makeTrainData {
    # Sentence が入ってくる
    my $s = shift;
    my $noun_list_ref = shift;
    my %opt = ( OUTPUT => 1, @_, );

    my $sentence = $s->STRING;

    my @bunsetsu = @{ $s->Bunsetsu };

    for (my $i = 0; $i < @bunsetsu; $i++) {
        my $segment = $bunsetsu[$i];
        my @morphs  = @{ $segment->Mor };
        my ($prev_segment, @prev_morphs);
        if ($i > 0) {
            $prev_segment = $bunsetsu[$i-1];
            @prev_morphs  = @{ $prev_segment->Mor };
        }
        my ($next_segment, @next_morphs);
        if ($i < @bunsetsu - 1) {
            $next_segment = $bunsetsu[$i+1];
            @next_morphs  = @{ $next_segment->Mor };
        }
        my $word_form      = $segment->WF;
        my $head_word_form = $segment->HEAD_WF;
        my $head_pos       = $segment->HEAD_POS;

        # 文節に関する素性(BACT で使用)
        my $syn_morphs_pos = '';
        for my $morph (@morphs) {
            $syn_morphs_pos .= "($morph->{POS})";
        }
        
        # FIXME: ad hoc feature
        my $sem_bridge;
        my $syn_prev_morphs_pos = '';
        if ($i > 0) {
            # 最後の形態素
            my $bridge = $prev_morphs[-1];
            my $bridge_cand = $prev_morphs[-2];
            if ($bridge->WF eq 'の') {
                $sem_bridge = $bridge_cand->WF;
            }
            for my $morph (@prev_morphs) {
                $syn_prev_morphs_pos .= "($morph->{POS})";
            }
        }
        my $syn_next_morphs_pos;
        if ($i < @bunsetsu - 1) {
            $syn_next_morphs_pos = join q{},
                                   map { "($_->{POS})" } @next_morphs;
        }

        #if ($segment->PRED) {
        #    # 述語のときは単に無視する
        #    next;
        #}

        for (my $mid = 0; $mid < @morphs; $mid++) {
            my $morph = $morphs[$mid];
            my %feature;
            if ($morph->POS =~ /^名詞-サ変/) {
                # サ変名詞が見つかった
                carp "SAHEN: $morph->{WF}\n" if $DEBUG;

                # 分類語彙表と EDR を見る
                my $bgh_id  = ENA::Bgh::get_class_id_frac($morph->WF);
                my %edr_pat = ENA::EDR::get_pattern($morph->WF);

                carp "BGH: $bgh_id, WF: $morph->{WF}" if $DEBUG;

                # 形態素の素性
                $feature{head_word_form}    = $head_word_form;
                $feature{segment_word_form} = $word_form;
                $feature{morph_word_form}   = $morph->WF;
                $feature{bgh_id}    = $bgh_id;
                $feature{edr_pat}   = \%edr_pat;
                
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
                    if ($before_morph->POS =~ /名詞-サ変/) {
                        $has_sahen_before++;
                        $feature{syn_sahen_before} = 1;
                    }
                }
                for my $after_morph (@after_morphs) {
                    if ($after_morph->POS =~ /名詞-サ変/) {
                        $has_sahen_after++;
                        $feature{syn_sahen_after} = 1;
                    }
                }
                
                # 事態性プラスに働く素性
                # サ変のあとに助詞が来る
                if ($has_sahen_after) {
                    for (my $mid = 0; $mid < @after_morphs - 1; $mid++) {
                        if ($after_morphs[$mid]->POS =~ m/^名詞-サ変/xms) {
                            if ($after_morphs[$mid+1]->POS =~ m/^助詞/xms) {
                                $feature{syn_sahen_particle_after} = 1;
                            }
                            elsif ($after_morphs[$mid+1]->POS =~ m/^名詞-一般/xms) {
                                $feature{syn_sahen_general_after} = 1;
                            }
                        }
                    }
                }
                
                # 前文節に関する素性
                if ($has_sahen_before) {
                    for my $before_morph (@before_morphs) {
                        if ($before_morph->POS =~ m/^名詞-一般/xms) {
                            $feature{syn_sahen_general_before} = 1;
                        }
                    }
                }

                # サ変+名詞接尾となっている
                if ($morphs[$mid+1] and
                    $morphs[$mid+1]->POS =~ m/^名詞-接尾/xms) {
                    $feature{syn_suffix} = 1;
                }

                # サ変が複数入っている
                my $number_of_sahen = 0;
                for my $morph (@morphs) {
                    if ($morph->POS =~ m/^名詞-サ変/xms) {
                        $number_of_sahen++;
                    }
                }
                if ($number_of_sahen >= 2) {
                    $feature{syn_sahen_compound} = 1;
                }

                # 項が当たっているかどうか
                foreach my $case (qw{GA WO NI}) {
                    if ($morph->$case) {
                        my $morph_case_id = $morph->$case;
                        foreach (@morphs) {
                            if ($_->ID and ($_->ID eq $morph_case_id)) {
                                $feature{"case_$case"} = $_->WF;
                            }
                        }
                    }
                }

                # デバッグ用に格が埋まっているかどうか周辺文脈
                $feature{sentence}  = $sentence;

                # 事態タグが付いているかどうか
                if ($morph->EVENT) {
                    $feature{event} = 1; 
                    if ($morph->GA) {
                        $feature{event} += 2;
                    }
                    if ($morph->WO) {
                        $feature{event} += 4;
                    }
                    if ($morph->NI) {
                        $feature{event} += 8;
                    }
                }

                # 名詞としての処理
                foreach my $morph (@morphs) {
                    if ($morph->POS =~ /^名詞/) {
                        push @{ $noun_list_ref }, $morph;
                        $feature{noun_id} = scalar @{ $noun_list_ref };
                    }
                }
            }
            else { # not サ変
                # 名詞が見つかった
                foreach my $morph (@morphs) {
                    if ($morph->POS =~ /^名詞/) {
                        push @{ $noun_list_ref }, $morph;
                    }
                }
            }

            # あらゆる形態素に feature がつく
            $feature{morph_id} = get_morph_id;

            # 名詞の意味素性を追加
            add_noun_feature($noun_list_ref, \%feature);
            set_feature(\%feature);

            # 分類語彙表にあるものだけ対象にする
            if ($feature{bgh_id}) {
                write_feature() if $opt{OUTPUT};
            }

            inc_morph_id();
        }
    }
}

sub add_noun_feature {
    my ($noun_ref, $feature_ref) = @_;
    my $edr_pat = $feature_ref->{edr_pat};
    carp "EDR_PAT: $feature_ref->{head_word_form}\n",
        Dumper(%$edr_pat) if $DEBUG;

    # 格がなければなにもしない
    return if !$edr_pat;

    # 表を作る
    my %concept_id_of;
    my %concept_morph_of;
    my %concept_position_of;
    my @noun_list = @{ $noun_ref };
    for (my $i = 0; $i < scalar @noun_list; $i++) {
        my $noun = $noun_list[$i];
        my $concept_id = ENA::EDR::get_concept_id($noun->WF);
        $concept_id_of{$noun}               = $concept_id;
        $concept_morph_of{"$concept_id"}    = $noun;

        # (1) 最後のもの(一番近い)だけ覚える
        # (2) 番号が一つずつずれている
        $concept_position_of{"$concept_id"} = $i + 1;
    }

    my $case = $edr_pat;
    #foreach my $case (keys %$edr_pat) {
        foreach my $sem_role (keys %{ $case }) {
            print STDERR "CASE: $sem_role = $case->{$sem_role}\n" if $DEBUG;

            # 格要素に関する意味的制約
            my @concepts_id = split /;/, $case->{$sem_role};
            foreach my $concept_id (@concepts_id) {
                my $concept_id = substr $concept_id, 0, 6;
                print STDERR "CONCEPT_ID: $concept_id\n" if $DEBUG;

                # 出現する名詞について意味的制約を満たしているものがある
                # FIXME: 計算をキャッシュして高速化
                foreach my $noun_id (values %concept_id_of) {
                    my $similarity = ENA::EDR::is_under_class($noun_id, $concept_id);
                    my $verb = $feature_ref->{head_word_form};

                    my $sem_feature      = "edr_sem_$sem_role";
                    my $sem_feature_word = $sem_feature . "_word";
                    my $concept          = $concept_morph_of{$noun_id};

                    # スコアは意味的制約が合っていれば高く
                    # 遠くなれば低く出るようになっていてほしい
                    my $distance = abs($feature_ref->{noun_id}
                                       - $concept_position_of{"$noun_id"});
                    my $cooc = ENA::PLSI::calc_mi($concept, $verb."する");

                    print STDERR
                         "DISTANCE:",
                         $feature_ref->{noun_id}, q{,},
                         $concept_position_of{"$noun_id"}, q{,},
                         $distance, qq{\n},
                         "SIMILARITY($sem_role,$concept->{WF}):",
                         $similarity,
                         ", COOCURRENCE($concept->{WF}, $verb):",
                         $cooc, "\n" if $DEBUG;

                    my $score = $distance
                              ? $similarity / log ($distance + 1)
                              : 0;

                    ## それまでに出たもっとも高い類似度のものを記憶
                    #$feature_ref->{"$sem_feature"}       ||= $score;
                    #$feature_ref->{"$sem_feature_word"}  ||= $concept;
                    #if ($score > $feature_ref->{"$sem_feature"}) {
                    #    $feature_ref->{"$sem_feature"}      = $score;
                    #    $feature_ref->{"$sem_feature_word"} = $concept;
                    #}
                }
            }
        }
    #}
}

#
# 分類語彙表を使うモジュール
#
package ENA::Bgh;

use strict;
use warnings;
use Carp qw(carp croak);
use vars qw($VERBOSE);

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

#my $bgh_file = "/cl/nldata/bgh/bgh96/orgdata/sakuin";
my $bgh_file = "$ENV{ENA_DB_DIR}/bgh96-2.db";

my %bgh_dic;
if (eval "require BerkeleyDB; 1") {
    tie %bgh_dic, 'BerkeleyDB::Hash',
        -Filename => $bgh_file,
        -Flags    => DB_RDONLY
        or croak "Cannot open Bunrui Goi Hyou: $!\n";
} elsif (eval "require DB_File; 1") {
    tie %bgh_dic, 'DB_File', $bgh_file, O_RDONLY
        or croak "Cannot open Bunrui Goi Hyou: $!\n";
}

sub get_class_id {
    my $word = shift;
    carp "Looking up $word\n" if $VERBOSE;

    if ($bgh_dic{$word}) {
        carp "Found $word\n" if $VERBOSE;
        return $bgh_dic{$word};
    }
    else {
        return "0.0";
    }
}

sub get_class_id_frac {
    my $word = shift;

    my ($bgh_id_frac) = (ENA::Bgh::get_class_id($word) =~ /\d\.(\d+)/);
    return $bgh_id_frac;
}

#
# EDR を使うモジュール
#
package ENA::EDR;

use strict;
use warnings;
use Carp;

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

#my $jcc_file = "/cl/nldata/EDR/EDR1.5/JCD/JCC.DIC"; # 共起辞書
my $jcp_file = "/cl/nldata/EDR/EDR1.5/JCD/JCP.DIC"; # 共起パターン辞書
my $cpc_file = "/cl/nldata/EDR/EDR1.5/CD/CPC.DIC";  # 概念体系辞書
my $cph_file = "/cl/nldata/EDR/EDR1.5/CD/CPH.DIC";  # 概念辞書
#Readonly::Scalar my $jcc_db => 'bdb/jcc.db';
#tie %jcc_dic, 'DB_File', $jcc_db or die "Cannot open $jcc_db";
my $jcp_db = "$ENV{ENA_DB_DIR}/jcp.db";
my $cpc_db = "$ENV{ENA_DB_DIR}/cpc.db";
my $cph_db = "$ENV{ENA_DB_DIR}/cph.db";
my (%jcp_dic, %cpc_dic, %cph_dic);
if (eval "require BerkeleyDB; 1") {
    tie %jcp_dic, 'BerkeleyDB::Hash',
        -Filename => $jcp_db,
        -Flags    => DB_RDONLY,
        -Mode     => 0444
        or croak "Cannot open $jcp_db:$!";
    tie %cpc_dic, 'BerkeleyDB::Hash',
        -Filename => $cpc_db,
        -Flags    => DB_RDONLY,
        -Mode     => 0444
        or croak "Cannot open $cpc_db:$!";
    tie %cph_dic, 'BerkeleyDB::Hash',
        -Filename => $cph_db,
        -Flags    => DB_RDONLY,
        -Mode     => 0444
        or croak "Cannot open $cph_db:$!";
} elsif (eval "require DB_File; 1") {
    tie %jcp_dic, 'DB_File', $jcp_db, O_RDONLY, 0644
        or croak "Cannot open $jcp_db";
    tie %cpc_dic, 'DB_File', $cpc_db, O_RDONLY, 0644
        or croak "Cannot open $cpc_db";
    tie %cph_dic, 'DB_File', $cph_db, O_RDONLY, 0644
        or croak "Cannot open $cph_db";
}

use vars qw($DEBUG);

# $concept_system->[レベル1項目の番号][レベル2項目の番号]
my @concept_system = [
    # ルートノード
    [
        '3aa966', # 概念
    ],
    # レベル1
    [
        '3aa911', # 人間または人間と似た振る舞いをする主体
        '3d017c', # ものごと
        '30f7e4', # 事象
        '30f751', # 位置
        '30f776', # 時
    ],
    # レベル2
    [
        # 人間または人間と似た振る舞いをする主体
        '30f6b0',
        '30f6bf',
        '3aa912',
        '4444b6',
        # ものごと
        '444d86',
        '444ab5',
        '444daa',
        '0e7faa',
        # 事象
        '30f7e5',
        '30f83e',
        '30f801',
        '3f9856',
        '3aa963',
        # 位置
        '3aa938',
        '30f753',
        '30f767',
        '3f9651',
        '3f9658',
        '444a9d',
        # 時
        '3f9882',
        '444dd2',
        '444dd3',
        '30f77b',
        '444dd4',
        '4449e2',
        '30f7d6',
    ],
];

sub get_concept_id {
    my $concept = shift;

    return $cph_dic{"$concept"} ? $cph_dic{"$concept"} : 0;
}

sub get_parent_id {
    my $concept_id = shift;

    # XXX: aaaaaa-bbbbbb 形式を扱う必要がある
    return $cpc_dic{"$concept_id"} ? $cpc_dic{"$concept_id"}
                                   : $concept_system[0][0]
                                   ;
}

sub get_pattern {
    my $word = shift;

    my %pattern;
    if (defined $jcp_dic{$word}) {
        #carp $jcp_dic{$word};
        for (split q{\|}, $jcp_dic{$word}) {
            #carp $_;
            # FIXME: 複数意味役割がある場合の対応
            my ($sem_role, $concept_id) = split q{:}, $_;
            #$concept_id =~ s/;.*$//g; # とりあえず無視
            $pattern{$sem_role} = $concept_id;
        }
    }

    return %pattern;
}

sub is_same_class {
    my ($concept_a, $concept_b) = @_;
    my (@classes_of_a, @classes_of_b);

    # 祖先を順に入れておく
    while ($concept_a ne $concept_system[0][0]) {
        unshift @classes_of_a, $concept_a;
        $concept_a = get_parent_id("$concept_a");
    }
    while ($concept_b ne $concept_system[0][0]) {
        unshift @classes_of_b, $concept_b;
        $concept_b = get_parent_id("$concept_b");
    }

    #carp join q{,}, @classes_of_a;
    #carp join q{,}, @classes_of_b;

    my $level = 0;  # 最初は必ず 概念('3aa966')
    for (;;) {
        last if (!$classes_of_a[$level] or !$classes_of_b[$level]);
        if ($classes_of_a[$level] eq $classes_of_b[$level]) {
            $level++;
        }
        else {
            last;
        }
    }

    return $level - 1;
}

sub is_under_class {
    my ($word, $class) = @_;
    my @classes_of_word;

    # 祖先を順に入れておく
    while ($word ne $concept_system[0][0]) {
        unshift @classes_of_word, $word;
        $word = get_parent_id("$word");
    }

    #carp join q{,}, @classes_of_word;

    my $under_class = 0;  # 最初は必ず 概念('3aa966')
    foreach my $class_of_word (@classes_of_word) {
        if ($class_of_word eq $class) {
            $under_class = 1;
        }
    }

    return $under_class;
}

#use DB_File;
#my $person_file = $ENV{EXO_PATH} . '/dat/db/edr_person.db';
#my $org_file    = $ENV{EXO_PATH} . '/dat/db/edr_org.db';
#tie my %person, 'DB_File', $person_file, O_RDONLY or croak "$!";
#tie my %org,    'DB_File', $org_file,    O_RDONLY or croak "$!";
#
## [in ] NOUN
## [out] 1:person ; 0:otherwise
#sub check_edr_person {
#    my $bunsetsu = shift;
#    my $noun = $bunsetsu->HEAD_NOUN;
#   return ($person{$noun}) ? 'EDR_PERSON' : '';
#}
#
#sub check_edr_org {
#    my $bunsetsu = shift;
#    my $noun = $bunsetsu->HEAD_NOUN;
#    return ($org{$noun}) ? 'EDR_ORG' : '';
#}

#
# PLSI を使うモジュール
#
package ENA::PLSI;

use strict;
use warnings;

use Carp qw(carp croak);
use Data::Dumper;

# location of results
use FindBin;
my $plsi_dir    = "$FindBin::Script/../dat/plsi";
my $plsi_base   = 'n10/';
my $plsi_prefix = 'n10';
my $Ndic_file   = $plsi_dir.'Ndic';
my $Vdic_file   = $plsi_dir.'Vdic';
my $pdz_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pdz';
my $pzd_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pzd';
my $pd_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pd' ;
my $pwz_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pwz';
my $pzw_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pzw';
my $pw_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pw' ;
my $pz_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pz' ;

my $plsi_file   = "$plsi_dir/${plsi_prefix}.result";

# coocurrence dictionary
my %cooc_dic;
# Set noun andd verb hashes
my (%noun_of, %verb_of);

sub slurp_plsi {
    my (@pwz_of, @pdz_of, @pz_of);

    open my $pz_fh, $pz_file or croak "Cannot open $pz_file";
    while (<$pz_fh>) {
        chomp;
        @pz_of = split;
    }
    close $pz_fh;
    #carp "Reading up $pz_file";

    open my $pdz_fh, $pdz_file or croak "Cannot open $pdz_file";
    my $z = 0;
    while (<$pdz_fh>) {
        chomp;
        my @pdz_i = split;
        push @pdz_of, \@pdz_i;
    }
    close $pdz_fh;
    #carp "Reading up $pdz_file";

    open my $pwz_fh, $pwz_file or croak "Cannot open $pwz_file";
    while (<$pwz_fh>) {
        chomp;
        my @pwz_i = split;
        push @pwz_of, \@pwz_i;
    }
    close $pwz_fh;
    #carp "Reading up $pwz_file";

    my %cooc_of;
    # determine wsize and dsize
    my $word_size = scalar @{ $pwz_of[0] };
    my $doc_size  = scalar @{ $pdz_of[0] };
    #carp $word_size, "\n", $doc_size;
    for (my $j = 0; $j < $word_size; $j++) {
        for (my $k = 0; $k < $doc_size; $k++) {
            $cooc_of{$j}{$k} = 0;
            for (my $i = 0; $i < @pz_of; $i++) {
                $cooc_of{$j}{$k}
                    += $pwz_of[$i][$j] * $pz_of[$i] * $pdz_of[$i][$k];
            }
            if ($cooc_of{$j}{$k} > 0 && log($cooc_of{$j}{$k}) > -10) {
                printf "%d  %d  %0.24f\n", $j, $k, $cooc_of{$j}{$k};
            }
        }
    }
}

sub set_cooc {
    open my $ndic_fh, $Ndic_file or croak "Cannot open $Ndic_file";
    while (<$ndic_fh>) {
        chomp;
        my ($noun_id, $lex_entry) = split;
        $noun_of{$noun_id} = $lex_entry;
    }
    close $ndic_fh;
    open my $vdic_fh, $Vdic_file or croak "Cannot open $Vdic_file";
    while (<$vdic_fh>) {
        chomp;
        my ($verb_id, $case_frame) = split;
        my ($case, $lex_entry) = split /:/, $case_frame;
        $verb_of{$verb_id} = $lex_entry;
    }
    close $vdic_fh;

    open my $cooc_fh, $plsi_file or croak "Cannot open $plsi_file";
    while (<$cooc_fh>) {
        chomp;
        my ($noun_id, $verb_id, $probability) = split;
        if ($probability > 0 && log($probability) > -10) {
            carp "$noun_id, $verb_id, $probability";
            $cooc_dic{$noun_of{$noun_id}}{$verb_of{$verb_id}}
                = $probability;
        }
    }
    close $cooc_fh;
}

sub get_cooc {
    my ($noun, $verb) = @_;
    return 0 unless $cooc_dic{$noun}{$verb};

    printf STDERR "cooc of %s and %s is %s\n",
        $noun, $verb, $cooc_dic{$noun}{$verb};
    return $cooc_dic{$noun}{$verb};
}

# taken from calc_mi.pl
BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

my $Ndic      = "$ENV{ENA_DB_DIR}/n2id.db";
my $Vdic      = "$ENV{ENA_DB_DIR}/v2id.db";
my $ncv2score = "$ENV{ENA_DB_DIR}/ncv2score.db";

my (%Ndic, %Vdic, %ncv2score);
if (eval "require BerkeleyDB; 1") {
    tie %Ndic, 'BerkeleyDB::Hash',
        -Filename => $Ndic,
        -Flags    => DB_RDONLY,
        -Mode     => 0644
        or croak "Cannot open $Ndic:$!";
    tie %Vdic, 'BerkeleyDB::Hash',
        -Filename => $Vdic,
        -Flags    => DB_RDONLY,
        -Mode     => 0644
        or croak "Cannot open $Vdic:$!";
    tie %ncv2score, 'BerkeleyDB::Hash',
        -Filename => $ncv2score,
        -Flags    => DB_RDONLY,
        -Mode     => 0644
        or croak "Cannot open $ncv2score:$!";
} elsif (eval "require DB_File; 1") {
    tie my %Ndic, 'DB_File', $Ndic, O_RDONLY, 0644
        or croak "Cannot open $Ndic:$!";
    tie my %Vdic, 'DB_File', $Vdic, O_RDONLY, 0644
        or croak "Cannot open $Vdic:$!";
    tie my %ncv2score, 'DB_File', $ncv2score, O_RDONLY, 0644
        or croak "Cannot open $ncv2score:$!";
}

sub get_noun_word_form {
    my $morph = shift;
    my $WF = $morph->WF;
    $WF = '＜固有名詞'.$1.'＞' 
        if ($morph->POS =~ /^名詞-固有名詞-(一般|人名|組織|地域)/);
    $WF = '＜固有名詞人名＞' if ($morph->NE =~ /PERSON/);
    $WF = '＜固有名詞地域＞' if ($morph->NE =~ /LOCATION/);
    $WF = '＜固有名詞組織＞' if ($morph->NE =~ /ORGANIZATION/);
    $WF = '＜固有名詞一般＞' if ($morph->NE =~ /ARTIFACT/);
    return $WF;
}

sub calc_mi {
    my ($noun, $verb) = @_; # for each morph
    my $noun_word_form = get_noun_word_form($noun);
    my $noun_id = $Ndic{$noun_word_form};
    my $verb_ga_id = $Vdic{"が:$verb"};
    my $verb_wo_id = $Vdic{"を:$verb"};
    my $verb_ni_id = $Vdic{"に:$verb"};
    #print STDERR "NOUN_WF: $noun_word_form, NOUN_ID: $noun_id\n";
    return '' unless ($noun_id);
    #print STDERR "VERB: $verb, GA_ID: $verb_ga_id, WO_ID: $verb_wo_id, NI_ID: $verb_ni_id\n";
    return '' unless ($verb_ga_id or $verb_wo_id or $verb_ni_id);

    my $GA = $noun_word_form.':が:'.$verb;
    my $WO = $noun_word_form.':を:'.$verb;
    my $NI = $noun_word_form.':に:'.$verb;
    #print STDERR "GA: $GA, WO: $WO, NI: $NI\n";

    my $score = (($ncv2score{$GA}) ? $ncv2score{$GA} : 0)
              + (($ncv2score{$WO}) ? $ncv2score{$WO} : 0)
              + (($ncv2score{$NI}) ? $ncv2score{$NI} : 0);
    if ($score) {
        return ($score eq '4294967295') ? '' : $score;
    } else {
        return 0;
    }
}

1;
# vi:ts=4:expandtab:
