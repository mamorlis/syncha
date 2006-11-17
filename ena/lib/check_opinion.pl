#!/usr/bin/perl
#
# ���ո����ɤ���Ƚ�ꤹ��⥸�塼��
#

use strict;
use warnings;
use Carp qw(carp croak);

my $WISH       = qr(�ꤤ���ޤ�|˾��|���|��˾);
my $QUESTION   = qr(��|��);
my $PREDICATE  = qr(������|����);
my $ENDING     = qr([����]����|��|����|������|�ɤΤ��餤);
my $HONORIFIC  = qr((?:��|����)����);
my $EOS_SYMBOL = qr(��|��|��|\$);

sub is_opinion {
    # 1ʸ��-1ʸ�����äƤ���
    my $passage = shift;

    if ($passage =~ m/((?:$WISH|$PREDICATE|$ENDING|$QUESTION)$HONORIFIC?$EOS_SYMBOL)/g) {
        return 1;
    } else {
        return 0;
    }
}

1;

# vi:ts=4:
