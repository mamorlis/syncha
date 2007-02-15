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
my $DEBUG = 0;

# Import environment variables
use ENA::Conf;
use ENA::PLSI;
use ENA::EDR;
use ENA::Bgh;

my $plsi = new ENA::PLSI;
my $edr  = new ENA::EDR;
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


# ���Ĥ��󤫤���ä�������ץ�
use FindBin qw($Bin);
use lib "$Bin/../lib";
require 'mod.pm';

my $sem_offset = 50000;
my $syn_offset = 60000;
my $edr_offset = 70000;

# �������դˤ��뤿��
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

# morph id ��������������ꥹ��
my %feature_of;
# ��̣���������ֹ�Υޥåԥ��ݻ��ѥϥå���
my %sem_role;
my %syn_rule;

sub set_feature {
    my $feature_ref = shift;
    my %feature = %{$feature_ref};
    my %feature_list;
    my %feature_name;

    # ʬ�����ɽ�Ǥɤ��ˤ��뤫�Ȥ�������
    if ($feature{bgh_id}) {
        my $bgh_id = $feature{bgh_id};
        my $offset = 10000000;
        #my @level_at = qw(1 2 3 4 5 6 7);
        # ������5�Ĥޤǹ�äƤ���Ф褤
        my @level_at = qw(5 6 7);
        for my $level (@level_at) {
            my $feature_id = $offset
                             + substr($bgh_id, 0, $level)
                             * (10 ** ($level_at[-1] - $level));
            $feature_list{$feature_id}++;
            $feature_name{$feature_id} = "BGH_$feature_id";
        }
    }

    # �����Ǥ���ޤäƤ��뤫�ɤ���������
    foreach my $key (keys %feature) {
        last if $options{b};   # -b �ΤȤ��϶����ϸ��ʤ�

        carp "FEATURE_KEY: ", $key if $DEBUG and $key ne 'morph_id';
        my $threshold = 1.0;   # 1.0 �ʲ��Ϥ���äݤ��ʤ�

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

    # SVM ��ʬ��Ǥ���褦��
    $feature_list{$feature{morph_id}} = 1;
    $feature_name{$feature{morph_id}} = "MORPH_ID_".$feature{morph_id};

    # ����
    # ====
    # ư�����ʤ�������ɲá�ư�����Ǥʤ����������ɲ�
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
        # �ǥХå���
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

# ʸ�������ꥹ�Ȥ�ľ����³��
sub make_train_data {
    # Text �����äƤ���
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

        # ʸ��˴ؤ�������(BACT �ǻ���)
        my $syn_morphs_pos = '';
        for my $morph (@morphs) {
            $syn_morphs_pos .= "($morph->get_pos)";
        }
        
        # FIXME: ad hoc feature
        my $sem_bridge;
        my $syn_prev_morphs_pos = '';
        if ($i > 0) {
            # �Ǹ�η�����
            my $bridge = $prev_morphs[-1];
            my $bridge_cand = $prev_morphs[-2];
            if ($bridge->get_surface eq '��') {
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
        #    # �Ҹ�ΤȤ���ñ��̵�뤹��
        #    next;
        #}

        for (my $mid = 0; $mid < @morphs; $mid++) {
            my $morph = $morphs[$mid];
            my %feature;
            if ($morph->get_pos =~ /^̾��-����/) {
                # ����̾�줬���Ĥ��ä�
                carp 'SAHEN: ', $morph->get_surface if $DEBUG;

                # ʬ�����ɽ�� EDR �򸫤�
                my $bgh_id  = $bgh->get_class_id_frac($morph->get_surface);
                my %edr_pat = $edr->get_pattern($morph->get_surface);

                carp "BGH: $bgh_id, WF: ", $morph->get_surface if $DEBUG;

                # �����Ǥ�����
                $feature{head_word_form}    = $head_word_form;
                $feature{segment_word_form} = $word_form;
                $feature{morph_word_form}   = $morph->get_surface;
                $feature{bgh_id}    = $bgh_id;
                $feature{edr_pat}   = \%edr_pat;
                
                # ʸ�������
                $feature{syn_morphs_pos}      = $syn_morphs_pos;
                $feature{syn_prev_morphs_pos} = $syn_prev_morphs_pos;
                $feature{syn_next_morphs_pos} = $syn_next_morphs_pos;
                $feature{sem_bridge}          = $sem_bridge;

                # BACT ����ؽ���������
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

                # ����˥��Ѥ����뤫
                for my $before_morph (@before_morphs) {
                    if ($before_morph->get_pos =~ /̾��-����/) {
                        $has_sahen_before++;
                        $feature{syn_sahen_before} = 1;
                    }
                }
                for my $after_morph (@after_morphs) {
                    if ($after_morph->get_pos =~ /̾��-����/) {
                        $has_sahen_after++;
                        $feature{syn_sahen_after} = 1;
                    }
                }
                
                # �������ץ饹��Ư������
                # ���ѤΤ��Ȥ˽��줬���
                if ($has_sahen_after) {
                    for (my $mid = 0; $mid < @after_morphs - 1; $mid++) {
                        if ($after_morphs[$mid]->get_pos =~ m/^̾��-����/xms) {
                            if ($after_morphs[$mid+1]->get_pos =~ m/^����/xms) {
                                $feature{syn_sahen_particle_after} = 1;
                            }
                            elsif ($after_morphs[$mid+1]->get_pos =~ m/^̾��-����/xms) {
                                $feature{syn_sahen_general_after} = 1;
                            }
                        }
                    }
                }
                
                # ��ʸ��˴ؤ�������
                if ($has_sahen_before) {
                    for my $before_morph (@before_morphs) {
                        if ($before_morph->get_pos =~ m/^̾��-����/xms) {
                            $feature{syn_sahen_general_before} = 1;
                        }
                    }
                }

                # ����+̾�������ȤʤäƤ���
                if ($morphs[$mid+1] and
                    $morphs[$mid+1]->get_pos =~ m/^̾��-����/xms) {
                    $feature{syn_suffix} = 1;
                }

                # ���Ѥ�ʣ�����äƤ���
                my $number_of_sahen = 0;
                for my $morph (@morphs) {
                    if ($morph->get_pos =~ m/^̾��-����/xms) {
                        $number_of_sahen++;
                    }
                }
                if ($number_of_sahen >= 2) {
                    $feature{syn_sahen_compound} = 1;
                }

                # �ब�����äƤ��뤫�ɤ���
                foreach my $case (qw{GA WO NI}) {
                    if (my $morph_case_id = $morph->get_case($case)) {
                        foreach (@morphs) {
                            if ($_->get_id and ($_->get_id eq $morph_case_id)) {
                                $feature{"case_$case"} = $_->get_surface;
                            }
                        }
                    }
                }

                # �ǥХå��Ѥ˳ʤ���ޤäƤ��뤫�ɤ�������ʸ̮
                $feature{sentence}  = $sentence;

                # ���֥������դ��Ƥ��뤫�ɤ���
                if ($morph->get_type eq 'EVENT') {
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

                # ̾��Ȥ��Ƥν���
                foreach my $morph (@morphs) {
                    if ($morph->get_pos =~ /^̾��/) {
                        push @{ $noun_list_ref }, $morph;
                        $feature{noun_id} = scalar @{ $noun_list_ref };
                    }
                }
            }
            else { # not ����
                # ̾�줬���Ĥ��ä�
                foreach my $morph (@morphs) {
                    if ($morph->get_pos =~ /^̾��/) {
                        push @{ $noun_list_ref }, $morph;
                    }
                }
            }

            # ����������Ǥ� feature ���Ĥ�
            $feature{morph_id} = get_morph_id;

            # ̾��ΰ�̣�������ɲ�
            add_noun_feature($noun_list_ref, \%feature);
            set_feature(\%feature);

            # ʬ�����ɽ�ˤ����Τ����оݤˤ���
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
    carp 'EDR_PAT: ', $feature_ref->{head_word_form},
        Dumper(%$edr_pat) if $DEBUG;

    # �ʤ��ʤ���Фʤˤ⤷�ʤ�
    return if !$edr_pat;

    # ɽ����
    my %concept_id_of;
    my %concept_morph_of;
    my %concept_position_of;
    my @noun_list = @{ $noun_ref };
    for (my $i = 0; $i < scalar @noun_list; $i++) {
        my $noun = $noun_list[$i];
        my $concept_id = $edr->get_concept_id($noun->get_surface);
        $concept_id_of{$noun}               = $concept_id;
        $concept_morph_of{"$concept_id"}    = $noun;

        # (1) �Ǹ�Τ��(���ֶᤤ)�����Ф���
        # (2) �ֹ椬��Ĥ��Ĥ���Ƥ���
        $concept_position_of{"$concept_id"} = $i + 1;
    }

    my $case = $edr_pat;
    #foreach my $case (keys %$edr_pat) {
        foreach my $sem_role (keys %{ $case }) {
            print STDERR "CASE: $sem_role = $case->{$sem_role}\n" if $DEBUG;

            # �����Ǥ˴ؤ����̣Ū����
            my @concepts_id = split /;/, $case->{$sem_role};
            foreach my $concept_id (@concepts_id) {
                my $concept_id = substr $concept_id, 0, 6;
                print STDERR "CONCEPT_ID: $concept_id\n" if $DEBUG;

                # �и�����̾��ˤĤ��ư�̣Ū������������Ƥ����Τ�����
                # FIXME: �׻��򥭥�å��夷�ƹ�®��
                foreach my $noun_id (values %concept_id_of) {
                    my $similarity = $edr->is_under_class($noun_id, $concept_id);
                    my $verb = $feature_ref->{head_word_form};

                    my $sem_feature      = "edr_sem_$sem_role";
                    my $sem_feature_word = $sem_feature . "_word";
                    my $concept          = $concept_morph_of{$noun_id};

                    # �������ϰ�̣Ū���󤬹�äƤ���й⤯
                    # �󤯤ʤ���㤯�Ф�褦�ˤʤäƤ��Ƥۤ���
                    my $distance = abs($feature_ref->{noun_id}
                                       - $concept_position_of{"$noun_id"});
                    my $cooc = $plsi->calc_mi($concept, $verb."����");

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

                    ## ����ޤǤ˽Ф���äȤ�⤤����٤Τ�Τ򵭲�
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

1;
# vi:ts=4:expandtab:
