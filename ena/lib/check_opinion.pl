#!/usr/bin/perl
#
# ご意見かどうか判定するモジュール
#

use strict;
use warnings;
use Carp qw(carp croak);

my $WISH       = qr(願いします|望む|提案|切望);
my $QUESTION   = qr(か|の);
my $PREDICATE  = qr(教えて|して);
my $ENDING     = qr([ほ欲]しい|は|たい|いくら|どのくらい);
my $HONORIFIC  = qr((?:下|くだ)さい);
my $EOS_SYMBOL = qr(。|？|！|\$);

sub is_opinion {
    # 1文節-1文が入ってくる
    my $passage = shift;

    if ($passage =~ m/((?:$WISH|$PREDICATE|$ENDING|$QUESTION)$HONORIFIC?$EOS_SYMBOL)/g) {
        return 1;
    } else {
        return 0;
    }
}

1;

# vi:ts=4:
