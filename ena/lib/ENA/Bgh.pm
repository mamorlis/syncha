#
# 分類語彙表を使うモジュール
#
package ENA::Bgh;

use Exporter;
our @ISA = qw(ENA);
our $VERSION = '0.0.1';

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
sub new {
    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %bgh_dic, 'BerkeleyDB::Hash',
            -Filename => $bgh_file,
            -Flags    => DB_RDONLY
            or croak "Cannot open Bunrui Goi Hyou: $!\n";
    } elsif (eval "require DB_File; 1") {
        tie %bgh_dic, 'DB_File', $bgh_file, O_RDONLY
            or croak "Cannot open Bunrui Goi Hyou: $!\n";
    }
    my $class = shift;
    my $self  = {};
    bless $self, ref($class) || $class;
    return $self;
}

sub DESTROY {
    untie %bgh_dic;
}

sub get_class_id {
    my $self = shift;
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
    my $self = shift;
    my $word = shift;

    my ($bgh_id_frac) = ($self->get_class_id($word) =~ /\d\.(\d+)/);
    return $bgh_id_frac;
}

1;
