# Manupulate Extended Cabocha format defined by mamoru-k
# Created on 5 July 2006 Mamoru KOMACHI <mamoru-k@is.naist.jp>

=head1 NAME

MyCabocha - Parse cabocha -f1 output

=head1 SINOPSYS

use MyCabocha;

my $cab = new MyCabocha <>;

=over 4

=cut

use strict;
use warnings;

use Getopt::Std;
my %opt;
getopt('d', \%opt);

my $DEBUG = 0;

package MyCabocha;

use Carp;
use Data::Dumper;

sub new {
    my $self  = {};
    my $class = shift;
    bless $self, $class;

    my $cabocha_fh = shift;

    {
        local $/ = "EOS\n";
        my @texts = <$cabocha_fh>;
        for (my $i = 0; $i < @texts; ++$i) {
            $self->set_text($i, $texts[$i]);
        }
    }

    return $self;
}

=item * puts

=cut

sub puts {
    my $self = shift;

    for my $text (@{ $self->get_text }) {
        $text->puts;
    }
}

=item * set_text

=cut

sub set_text {
    my $self     = shift;
    my $text_id  = shift;
    my $raw_text = shift;

    carp $raw_text if $DEBUG;

    my $text = MyCabocha::Text->new($text_id, $raw_text);

    push @{ $self->{text} }, $text;
}

=item * get_text

=cut

sub get_text {
    my $self = shift;

    return $self->{text};
}

=head2 MyCabocha::Text

=cut

package MyCabocha::Text;

use Carp;
use Data::Dumper;

sub new {
    my $self     = {};
    my $class    = shift;
    bless $self, $class;

    my $id       = shift;
    my $raw_data = shift;

    $self->set_id($id);

    my @raw_chunks = split /\* /, $raw_data;
    shift @raw_chunks; # empty string
    carp Dumper @raw_chunks if $DEBUG;
    for my $raw_chunk (@raw_chunks) {
        carp ">$raw_chunk<\n" if $DEBUG;
        my $chunk = new MyCabocha::Chunk($raw_chunk);
        $self->set_chunk($chunk);
    }

    return $self;
}

=item * puts

=cut

sub puts {
    my $self = shift;

    for my $chunk (@{ $self->get_chunk }) {
        $chunk->puts;
    }

    print "EOS\n";
}

=item * set_chunk

=cut

sub set_chunk {
    my $self  = shift;
    my $chunk = shift;

    carp Dumper $chunk if $DEBUG;

    push @{ $self->{chunk} }, $chunk;
}

=item * get_chunk

=cut

sub get_chunk {
    my $self = shift;
    
    return $self->{chunk};
}

=item * set_id

=cut

sub set_id {
    my $self = shift;

    $self->{id} = $_[0];
}

=item * get_id

=cut

sub get_id {
    my $self = shift;

    return $self->{id};
}

=head2 MyCabocha::Chunk

=cut

package MyCabocha::Chunk;

use Carp;
use Data::Dumper;

sub new {
    my $self      = {};
    my $class     = shift;
    bless $self, $class;

    my $raw_chunk = shift;
    carp ">>$raw_chunk<<\n" if $DEBUG;

    my @raw_morphs = split /\n/, $raw_chunk;

    # 1行目はヘッダ('* %d %d%s %d/%d %f %s\n')
    # 最後の %s は意見かどうかを表すタグ(拡張 )
    my @chunk_labels = split /\s+/, $raw_morphs[0];
    $self->set_id(       $chunk_labels[0]);
    $self->set_link_rel( $chunk_labels[1]);
    $self->set_head_func($chunk_labels[2]);
    $self->set_score(    $chunk_labels[3]);
    $self->set_opinion(  $chunk_labels[4]);
    shift @raw_morphs;

    for (my $i = 0; $i < @raw_morphs; ++$i) {
        last if $raw_morphs[$i] eq 'EOS';
        carp ">>", $raw_morphs[$i], "<<\n" if $DEBUG;
        my $morph = new MyCabocha::Morph($i, $raw_morphs[$i]);
        $self->set_morph($morph);
    }

    return $self;
}

=item * puts_label

=cut

sub puts_label {
    my $self = shift;

    printf "* %s %s %s %s %s\n",
        $self->get_id,
        $self->get_link_rel,
        $self->get_head_func,
        $self->get_score,
        $self->get_opinion;
}

=item * puts

=cut

sub puts {
    my $self = shift;

    $self->puts_label;
    for my $morph (@{ $self->get_morph }) {
        $morph->puts;
    }
}

=item * set_morph

=cut

sub set_morph {
    my $self  = shift;
    my $morph = shift;

    carp Dumper $morph if $DEBUG;

    push @{ $self->{morph} }, $morph;
}

=item * get_morph

=cut

sub get_morph {
    my $self = shift;

    return $self->{morph};
}

=item * set_id

=cut

sub set_id {
    my $self = shift;

    $self->{id} = $_[0];
}

=item * get_id

=cut

sub get_id {
    my $self = shift;

    return $self->{id};
}

=item * set_link_rel

=cut

sub set_link_rel {
    my $self = shift;

    $self->{link_rel} = $_[0];
}

=item * get_link_rel

=cut

sub get_link_rel {
    my $self = shift;

    return $self->{link_rel};
}

=item * set_head_func

=cut

sub set_head_func {
    my $self = shift;

    $self->{head_func} = $_[0];
}

=item * get_head_func

=cut

sub get_head_func {
    my $self = shift;

    return $self->{head_func};
}

=item * set_score

=cut

sub set_score {
    my $self = shift;

    $self->{score} = $_[0];
}

=item * get_score

=cut

sub get_score {
    my $self = shift;

    return $self->{score};
}

sub set_opinion {
    my $self = shift;

    $self->{opinion} = $_[0];
}

sub get_opinion {
    my $self = shift;

    return defined $self->{opinion} ? $self->{opinion} : '';
}

=head2 MyCabocha::Morph

=cut

package MyCabocha::Morph;

sub new {
    my $self      = {};
    my $class     = shift;
    bless $self, $class;

    my $id        = shift;
    my $raw_morph = shift;

    $self->set_id($id);

    my @labels = split /\t/, $raw_morph;

    $self->set_surface( $labels[0]);
    $self->set_base(    $labels[1]);
    $self->set_read(    $labels[2]);
    $self->set_pos(     $labels[3]);
    $self->set_ctype(   $labels[4]);
    $self->set_cform (  $labels[5]);
    $self->set_ne(      $labels[6]);
    $self->set_relation($labels[7]);

    return $self;
}

=item * puts

=cut

sub puts {
    my $self = shift;

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
        $self->get_surface,
        $self->get_base,
        $self->get_read,
        $self->get_pos,
        $self->get_ctype,
        $self->get_cform,
        $self->get_ne,
        $self->get_relation;
}

=item * set_id

=cut

sub set_id {
    my $self = shift;

    $self->{id} = $_[0];
}

=item * get_id

=cut

sub get_id {
    my $self = shift;

    return $self->{id};
}

=item * set_surface

=cut

sub set_surface {
    my $self = shift;
    
    $self->{surface} = $_[0];
}

=item * get_surface

=cut

sub get_surface {
    my $self = shift;

    return $self->{surface};
}

=item * set_base

=cut

sub set_base {
    my $self = shift;
    
    $self->{base} = $_[0];
}

=item * get_base

=cut

sub get_base {
    my $self = shift;

    return $self->{base};
}

=item * set_base

=cut

sub set_read {
    my $self = shift;
    
    $self->{read} = $_[0];
}

sub get_read {
    my $self = shift;

    return $self->{read};
}

=item * set_pos

=cut

sub set_pos {
    my $self = shift;
    
    $self->{pos} = $_[0];
}

=item * get_pos

=cut

sub get_pos {
    my $self = shift;

    return $self->{pos};
}

=item * set_ctype

=cut

sub set_ctype {
    my $self = shift;
    
    $self->{ctype} = $_[0];
}

=item * get_ctype

=cut

sub get_ctype {
    my $self = shift;

    return $self->{ctype};
}

=item * set_cform

=cut

sub set_cform {
    my $self = shift;
    
    $self->{cform} = $_[0];
}

=item * get_cform

=cut

sub get_cform {
    my $self = shift;

    return $self->{cform};
}

=item * set_ne

=cut

sub set_ne {
    my $self = shift;
    
    $self->{ne} = $_[0];
}

=item * get_ne

=cut

sub get_ne {
    my $self = shift;

    return $self->{ne};
}

=item * set_relation

=cut

sub set_relation {
    my $self = shift;
    
    $self->{relation} = $_[0];
}

=item * get_relation

=cut

sub get_relation {
    my $self = shift;

    return defined $self->{relation} ? $self->{relation} : '';
}

1;
