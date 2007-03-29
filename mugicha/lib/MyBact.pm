#!/usr/bin/perl
# Created on 5 Jan 2007 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

MyBact - Provised common functions to implement tournament model

=head1 SINOPSYS

use MyBact;

=cut

use strict;
use warnings;

package MyBact;

use Exporter qw(import);
our @EXPORT_OK = qw(make_features calc_score classify);

use NCVTool;
my $ncvtool = new NCVTool;

use MySVM;

use File::Temp qw(tempfile);
use Carp;
use Data::Dumper;

sub new {
    my $class      = shift;
    my $bact_model = shift;
    my $self       = {};
    $self->{model} = $bact_model;
    bless $self, ref($class) || $class;
}

=head2 model

Set and get model path.

=cut

sub model {
    my $self = shift;
    if (@_ > 0) {
        $self->{model} = shift;
    } else {
        return $self->{model};
    }
}

=head2 svm

Returns true if using svm.

=cut

sub svm {
    my $self = shift;
    if (@_) {
        $self->{svm} = shift;
    } elsif (ref $self->{svm} ne 'MySVM') {
        # FIXME: ad hoc init
        (my $hash_file = $self->model) =~ s/model/log/;
        my %svm_hash;
        open my $hash_fh, '<', $hash_file or die "Cannot open $hash_file:$!";
        while (<$hash_fh>) {
            chomp;
            my ($feature, $id) = split;
            $svm_hash{$feature} = $id;
        }
        close $hash_fh;
        $self->{hash} = \%svm_hash;
        $self->{svm}  = new MySVM ($self->model);
    }
    $self->{svm};
}

=head2 make_sexp

Makes S-^expression given an array.

=cut

sub make_sexp {
    my ($self, @args) = @_;
    return join '', map { "($_)" } @args;
}

=head2 make_morph_features

Makes pointwise morpheme features for candidates.
Takes $en and $morph as arguments.

=cut

sub make_morph_features {
    my ($self, $en, $vframe, $morph) = @_;

    my @morph_features;
    return @morph_features;
}

=head2 make_pair_features

Makes features defined in terms of pairs of candidates.
Takes $morph, $vframe, $left and $right as arguments.

=cut

sub make_pair_features {
    my ($self, $morph, $vframe, $left, $right) = @_;

    my @pair_features;
    return @pair_features;
}

=head2 make_verb_features

Makes verb features defined by the predicate and context.
Takes predicate $morph, $vframe, morphemes $arg and $np.

=cut

sub make_verb_features {
    my ($self, $morph, $vframe, $arg, $np) = @_;

    my @verb_features;
    return @verb_features;
}

=head2 make_features

Makes features that corresponed to given set of arguments.
Takes pn, $morph, $vframe, $left, $right

=cut

sub make_features {
    my ($self, $pn, $en, $vframe, $left, $right) = @_;
    my @tuple = ( $en, $vframe, $left, $right );
    return sprintf '%s (~ROOT (%s) (%s) (%s) (%s))',
        $pn,
        $self->make_sexp(map { 'L_'.$_ } $self->make_morph_features($en, $vframe, $left)),
        $self->make_sexp(map { 'R_'.$_ } $self->make_morph_features($en, $vframe, $right)),
        $self->make_sexp($self->make_pair_features(@tuple)),
        $self->make_sexp($self->make_verb_features(@tuple));
}

=head2 classify

Determins which candidate wins.

=cut

sub classify {
    my $self = shift;
    my ($morph, $vframe, $winner, $challenger) = @_;

    my $bact_model = $self->model;

    my $res;
    if ($self->svm) {
        my $bact_line = $self->make_features('0', $morph, $vframe, $winner, $challenger);
        $bact_line =~ s/[()]/ /g;
        $bact_line =~ s/^0\s+//;
        my @features;
        for my $feature (split /\s+/, $bact_line) {
            if (exists $self->{hash}->{$feature}) {
                push @features, $self->{hash}->{$feature};
            }
        }
        @features = map { $_ = $_.':1' } sort { $a <=> $b } @features;
        $res = $self->svm->classify_line(join q[ ], @features);
    } else {
        # a temporary file to store tournament
        my $fh = tempfile;
        my $temp_file;
        ($fh, $temp_file) = tempfile;
        print $fh $self->make_features('0', $morph, $vframe, $winner, $challenger), "\n";
        close $fh;
        $res = `bact_classify -v1 $temp_file $bact_model | head -n 1 | cut -d' ' -f2`;
        unlink $temp_file;
    }
    return ($res > 0) ? 1 : -1;
}

=head2 classify_line()

Classify just one line.

=cut

sub classify_line {
    my $self = shift;
    my $line = shift;

    my $bact_model = $self->model;

    my $fh = tempfile;
    my $temp_file;
    ($fh, $temp_file) = tempfile;
    print $fh $line;
    close $fh;
    my $res = `bact_classify -v1 $temp_file $bact_model | head -n 1 | cut -d' ' -f2`;
    unlink $temp_file;
    return ($res > 0) ? 1 : -1;
}

1;
