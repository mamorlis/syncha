#!/usr/bin/perl
# Created on 22 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

use strict;
use warnings;

package Syntax::Functional;

use Syntax;
our @ISA = qw(Syntax);

use Carp;
use Data::Dumper;

# FIXME: ¸½¾Ý¤ò»Ø¤·¼¨¤¹Ì¾»ì, p215 ÆüËÜ¸ìÆ°»ì¤Î½ôÁê

sub has_functional {
    my $self      = shift;
    my $chunk_ref = shift;
    my $pattern   = join q[], ${$chunk_ref}->get_surface;
    while (my ($exp, $func) = each %{$self->get_db('functional')}) {
        if ($pattern =~ m/$exp$/gmx) {
            return $exp || '1';
        }
    }
    return undef;
}

sub has_func_verb {
    my $self      = shift;
    my ($en, $np) = @_;
    my $func_morph = ${ $en->get_chunk }->get_func;
    if ($func_morph->get_pos =~ m/³Ê½õ»ì/gmx) {
        if (my $chunk_next = ${ $en->get_chunk }->next) {
            my $func_verb  = ${ $chunk_next }->get_head;
            my $read       = $func_verb->get_read;
            if (exists ${ $self->get_db('func_verbs') }{$read}) {
                return $func_verb;
            }
        }
    }
    return undef;
}

1;
