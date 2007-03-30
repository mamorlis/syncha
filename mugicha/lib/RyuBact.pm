#!/usr/bin/perl
# Created on 5 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>
# òµÌ¥ò³ò´

=head1 NAME

RyuBact.pm - An implementation of tournament model based on Ryu Iida's

=head1 SYNOPSIS

use RyuBact;

=cut

use strict;
use warnings;

package RyuBact;

use MyBact;
use Semantics::NTT;
use Semantics::EDR;
use Semantics::NE;
use Semantics::Pronoun;
use Semantics::Cooc;
my $ntt     = new Semantics::NTT;
my $edr     = new Semantics::EDR;
my $ne      = new Semantics::NE;
my $pronoun = new Semantics::Pronoun;
my $cooc    = new Semantics::Cooc (type => 'newswire', model => 'n1000');
my $webcooc = new Semantics::Cooc (type => 'web', model => 'web-n4000');
#my $tycooc  = new Semantics::Cooc (type => 'newswire', model => 'ty-n1000');

use Syntax;
use Syntax::Position;
use Syntax::Functional;
use Syntax::Support;
my $syntax   = new Syntax;
my $position = new Syntax::Position;
my $func     = new Syntax::Functional;
my $support  = new Syntax::Support;

#use Toyota::Category;
#my $toyo_cat = new Toyota::Category;

our @ISA=qw(MyBact);

use Data::Dumper;
use Carp;

sub new {
    my $class      = shift;
    my $self       = {};
    my $features   = shift || [];
    my $bact_model = shift;
    my $use_svm    = shift;
    for my $feature (split /,/, $features) {
        ${$self->{features}}->{$feature} = 1;
    }
    $self->{model} = $bact_model;
    $self->{svm}   = $use_svm || 0;
    bless $self, ref($class) || $class;
}

=head2 has_feature()

Check if certain feature turned off or not.

=cut

sub has_feature {
    my ($self, $feature) = @_;

    return (exists ${$self->{features}}->{$feature}) ? 1 : 0;
}

=head2 get_features()

Get a reference to a hash that contains all features as a key.

=cut

sub get_features {
    my $self = shift;

    return $self->{features};
}

=head2 make_semantic_features

Add semantic features taken from Iida et al., 2006

=cut

sub make_semantic_features {
    my ($self, $vframe, $morph) = @_;

    #carp Dumper($morph);

    my @semantic_features;
    if (!$self->has_feature('ntt')
        and (my $ntt_sem = $ntt->get_sem_class($morph))) {
        push @semantic_features, $ntt_sem;
    }
    # EDR seems harmful for our task. 2007/01/28
    #if (!$self->has_feature('edr')
    #    and (my $edr_type = $edr->get_edr_type($morph))) {
    #    push @semantic_features, $edr_type;
    #}
    if (!$self->has_feature('ne')
        and (my $ne_type = $ne->get_ne_type($morph))) {
        push @semantic_features, $ne_type;
    }
    if (!$self->has_feature('pronoun')
        and (my $pronoun_type = $pronoun->get_pronoun_type($morph))) {
        push @semantic_features, $pronoun_type;
    }
    if (!$self->has_feature('cooc')
        and (my @cooc_features = $cooc->get_cooc_features($vframe, $morph))) {
        push @semantic_features, @cooc_features;
    }
    #if (!$self->has_feature('webcooc')
    #    and (my @cooc_features = $webcooc->get_cooc_features($vframe, $morph))) {
    #    push @semantic_features, map { 'WEB_'.$_ } @cooc_features;
    #}
    #if (!$self->has_feature('tycooc')
    #    and (my @cooc_features = $tycooc->get_cooc_features($vframe, $morph))) {
    #    push @semantic_features, map { 'TY_'.$_ } @cooc_features;
    #}
    return @semantic_features;
}

=head2 make_verb_features

Overrides default function with newer one with NTT

=cut

sub make_verb_features {
    my ($self, $en, $vframe, $arg, $np) = @_;

    my @verb_features
        = $self->SUPER::make_verb_features($en, $vframe, $arg, $np);

    # Lexical information
    unless ($self->has_feature('lex')) {
        push @verb_features, (split /:/, $vframe)[1,2];
    }
    # Syntactic information
    unless ($self->has_feature('distance')) {
        for my $distance ($position->get_distance($en, $arg)) {
            push @verb_features, 'L_'.$distance;
        }
        for my $distance ($position->get_distance($en, $np)) {
            push @verb_features, 'R_'.$distance;
        }
    }
    unless ($self->has_feature('chunk')) {
        push @verb_features, 'SAME_CHUNK'
            if $np->get_chunk_id == $arg->get_chunk_id;
        if ((my $id = ${$np->get_parent}->get_depend_id) > 0) {
            if (${$en->get_text}->get_chunk_by_id($id)->get_id
                == $arg->get_chunk_id) {
                push @verb_features, 'DEP_CHUNK';
            }
        }
        unless ($self->has_feature('depend')) {
            for my $depend ($position->get_depend($en, $arg)) {
                push @verb_features, 'L_'.$depend;
            }
            for my $depend ($position->get_depend($en, $np)) {
                push @verb_features, 'R_'.$depend;
            }
            unless ($self->has_feature('depend_path')) {
                for my $depend ($position->get_depend_path($en, $arg)) {
                    push @verb_features, 'L_'.$depend;
                }
                for my $depend ($position->get_depend_path($en, $np)) {
                    push @verb_features, 'R_'.$depend;
                }
            }
        }
    }

    # quote seems to work for event noun
    unless ($self->has_feature('quote')) {
        push @verb_features, 'PRED_QUOTE' if $en->in_quote;
    }

    # functional expressions
    unless ($self->has_feature('func')) {
        my $func_exp = $func->has_functional($en->get_chunk);
        push @verb_features, 'PRED_FUNC_EXP_'.$func_exp if $func_exp;
    }

    # Verb seems harmful. 2007/01/29
    #unless ($self->has_feature('verb')) {
    #    if (my $chunk_next = ${$en->get_chunk}->next) {
    #        my @next_chunk_features;
    #        for my $verb_morph (@{ $$chunk_next->get_morph }) {
    #            push @next_chunk_features,
    #                'PRED_NEXT_SURFACE_'.$verb_morph->get_surface,
    #                'PRED_NEXT_BASE_'.$verb_morph->get_base,
    #                'PRED_NEXT_POS_'.$verb_morph->get_pos;
    #        }
    #        for my $chunk_feature (@next_chunk_features) {
    #            if ($chunk_feature =~ m/^PRED_NEXT_POS_Æ°»ì/gmx) {
    #                push @verb_features, @next_chunk_features;
    #                last;
    #            }
    #        }
    #    }
    #}

    # Semantic information
    unless ($self->has_feature('ntt')) {
        if (my $sem_class = $ntt->get_verb_class($en)) {
            push @verb_features, $sem_class;
        }
        if (my $sel_res = $ntt->get_selectional_restriction($vframe, $en, $arg)) {
            push @verb_features, 'L_'.$sel_res;
        }
        if (my $sel_res = $ntt->get_selectional_restriction($vframe, $en, $np)) {
            push @verb_features, 'R_'.$sel_res;
        }
    }

    return @verb_features;
}

=head2 make_morph_features

Make features of morphemes encompassing semantic features.

=cut

sub make_morph_features {
    my ($self, $en, $vframe, $morph) = @_;
    my @morph_features = $self->SUPER::make_morph_features($en, $vframe, $morph);
    my $cab = $morph->get_cab;

    # Lexical information
    unless ($self->has_feature('lex')) {
        push @morph_features, $morph->get_surface;
    }

    ## toyota
    #unless ($self->has_feature('toyota')) {
    #    push @morph_features, 'TY_TYPE_'.$toyo_cat->cat($morph);
    #}

    # Syntactic information
    unless ($self->has_feature('syntax')) {
        unless ($self->has_feature('pos')) {
            push @morph_features, $morph->get_pos;
            push @morph_features, $syntax->get_pos($morph);
        }
        unless ($self->has_feature('head')) {
            if ($morph->is_head) {
                push @morph_features, 'HEAD';
            }
            if ($morph->is_func) {
                push @morph_features, 'FUNC';
            }
        }
        unless ($self->has_feature('definite')) {
            if (my $definite_expression = $syntax->get_definite($morph)) {
                push @morph_features, $definite_expression;
            }
            if (my $definite_expression = $syntax->get_pre_definite($morph)) {
                push @morph_features, $definite_expression;
            }
        }
        # Particle seems harmful. 2007/01/29
        #if (!$self->has_feature('particle')
        #    and (my $particle_expression = $syntax->get_particle($morph))) {
        #    push @morph_features, $particle_expression;
        #}
        unless ($self->has_feature('position')) {
            for my $pos ($position->get_position($morph)) {
                push @morph_features, $pos;
            }
        }
        unless ($self->has_feature('quote')) {
            push @morph_features, 'QUOTE' if $morph->in_quote;
        }
        # Adding functional expression information to arguments
        # didn't improve clasiffication performance (2007/01/22)
        #unless ($self->has_feature('func')) {
        #    my $func_exp = $func->has_functional($morph->get_chunk);
        #    push @morph_features, 'FUNC_EXP_'.$func_exp if $func_exp;
        #}
        unless ($self->has_feature('func_verb')) {
            if (my $func_verb = $func->has_func_verb($en, $morph)) {
                push @morph_features, 'FUNC_VERB_'.$func_verb->get_read;
                for my $depend ($position->get_depend($func_verb, $morph)) {
                    push @morph_features, 'FUNC_VERB_'.$depend;
                }
                for my $depend ($position->get_depend_path($func_verb, $morph)) {
                    push @morph_features, 'FUNC_VERB_'.$depend;
                }
            }
        }
    }

    # Semantic information
    my @semantic_features = $self->make_semantic_features($vframe, $morph);
    if (!$self->has_feature('semantics') and @semantic_features) {
        push @morph_features, @semantic_features;
    }

    return @morph_features;
}

=head2 make_pair_features()

Override default pairwise features.

=cut

sub make_pair_features {
    my ($self, $morph, $vframe, $left, $right) = @_;

    my @pair_features = $self->SUPER::make_pair_features;
    if (!$self->has_feature('cooc')
        and (my @cooc_features = $cooc->cmp_cooc_features($vframe, $left, $right))) {
        push @pair_features, @cooc_features;
    }
    #if (!$self->has_feature('webcooc')
    #    and (my @cooc_features = $webcooc->cmp_cooc_features($vframe, $left, $right))) {
    #    push @pair_features, map { 'WEB_'.$_ } @cooc_features;
    #}
    #if (!$self->has_feature('tycooc')
    #    and (my @cooc_features = $tycooc->cmp_cooc_features($vframe, $left, $right))) {
    #    push @pair_features, map { 'TY_'.$_ } @cooc_features;
    #}
    return @pair_features;
}

1;
