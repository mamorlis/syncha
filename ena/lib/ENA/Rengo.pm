#!/usr/bin/env perl
# ===================================================================
my $NAME         = 'check_edr.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'EDR辞書の人間，人間の属性以下の語彙かどうかのcheck';
# ===================================================================

package ENA::Rengo;

use strict;
use warnings;

use Carp;

BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use ENA::Conf;
my $rengo = "$ENV{ENA_DB_DIR}/rengo.db";
my %rengo;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    # set DB
    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %rengo, 'BerkeleyDB::Hash',
                -Filename => $rengo,
                -Flags    => DB_RDONLY,
                -Mode     => 0644
                or die $!;
    } elsif (eval "require DB_File; 1") {
        tie %rengo, 'DB_File', $rengo, O_RDONLY, 0644 or die $!;
    }

    return $self;
}

sub get_rengo {
    my ($self, $word_form) = @_;

    return $rengo{$word_form};
}

1;
