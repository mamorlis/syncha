# Manupulate Extended Cabocha format defined by mamoru-k
# 魑魅魍魎
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

#use encoding 'euc-jp';

my $DEBUG = 0;

package MyCabocha;

use Carp;
use Data::Dumper;

sub new {
    my $self  = {};
    my $class = shift;
    bless $self, $class;

    # uniq morph id
    $self->{morph_num} = 0;

    my $cabocha_fh = shift;

    {
        local $/ = "EOS\n";
        my @texts = <$cabocha_fh>;
        for (my $i = 0; $i < @texts; ++$i) {
            $self->set_text($i, $texts[$i]);
        }
    }

    $self->parse_arg;

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

    my $text = MyCabocha::Text->new(\$self, $text_id, $raw_text);

    push @{ $self->{text} }, $text;
}

=item * get_text

=cut

sub get_text {
    my $self = shift;

    return $self->{text};
}

=item * parse_argstr

=cut

sub parse_arg {
    my $self = shift;

    my %arg_of;

    for my $text (@{ $self->get_text }) {
        # FIXME: not defined
        last if !$text->get_chunk;
        for my $chunk (@{ $text->get_chunk }) {
            for my $morph (@{ $chunk->get_morph }) {
                if (my $id = ($morph->get_argstr =~ m/ID=(\d*)/gmx)[0]) {
                    $arg_of{$id} = $morph;
                }
            }
        }
    }

    %{ $self->{arg} } = %arg_of;
}

=item * get_arg

=cut

sub get_arg {
    my $self = shift;
    my $id   = shift;

    $self->{arg}{$id};
}

=item * get_all_morph

Get all morphs under control.

=cut

sub get_all_morph {
    my $self = shift;
 
    return map { @{ $_->get_morph } }
           map { @{ $_->get_chunk } } @{ $self->get_text };
}

=item * equals

Check if the two objects are the same

=cut

sub equals {
    my ($self, $obj1, $obj2) = @_;

    if (ref $obj1 eq 'MyCabocha::Morph' and ref $obj2 eq 'MyCabocha::Morph') {
        if ($obj1->get_id eq $obj2->get_id
            and $obj1->get_chunk_id eq $obj2->get_chunk_id
            and $obj1->get_text_id  eq $obj2->get_text_id) {
            return 1;
        }
    } elsif (ref $obj1 eq 'MyCabocha::Chunk' and ref $obj2 eq 'MyCabocha::Chunk') {
        if ($obj1->get_id eq $obj2->get_id
            and $obj1->get_text_id eq $obj2->get_text_id) {
            return 1;
        }
    }
    return 0;
}

=item * before

Check if given object occurs before given object or not.

=cut

sub before {
    my ($self, $obj1, $obj2) = @_;

    if ($obj1->get_text_id ne $obj2->get_text_id) {
        warn "Text id is not the same.\n";
    }

    if (ref $obj1 eq 'MyCabocha::Morph' and ref $obj2 eq 'MyCabocha::Morph') {
        if ($obj1->get_chunk_id < $obj2->get_chunk_id
            or $obj1->get_chunk_id == $obj2->get_chunk_id
            and $obj1->get_id < $obj2->get_id) {
            return 1;
        }
    } elsif (ref $obj1 eq 'MyCabocha::Chunk' and ref $obj2 eq 'MyCabocha::Chunk') {
        if ($obj1->get_id < $obj2->get_id) {
            return 1;
        }
    }
    return 0;
}

=item * after

Check if given object occurs after given object or not.

=cut

sub after {
    my ($self, $obj1, $obj2) = @_;

    if ($obj1->get_text_id ne $obj2->get_text_id) {
        warn "Text id is not the same.\n";
    }

    if (ref $obj1 eq 'MyCabocha::Morph' and ref $obj2 eq 'MyCabocha::Morph') {
        if ($obj1->get_chunk_id > $obj2->get_chunk_id
            or $obj1->get_chunk_id == $obj2->get_chunk_id
            and $obj1->get_id > $obj2->get_id) {
            return 1;
        }
    } elsif (ref $obj1 eq 'MyCabocha::Chunk' and ref $obj2 eq 'MyCabocha::Chunk') {
        if ($obj1->get_id > $obj2->get_id) {
            return 1;
        }
    }
    return 0;
}

=item * incr_morph_num

=cut

sub incr_morph_num {
    my $self = shift;
    $self->{morph_num}++;
}

=item * get_morph_num

=cut

sub get_morph_num {
    my $self = shift;
    return $self->{morph_num};
}

=head2 MyCabocha::Text

A module to hold all text data for each document.

=cut

package MyCabocha::Text;

#use encoding 'euc-jp';

use Carp;
use Data::Dumper;

sub new {
    my $self     = {};
    my $class    = shift;
    bless $self, $class;

    $self->{parent} = shift;
    $self->char(0);
    my $id       = shift;
    my $raw_data = shift;

    $self->set_id($id);
    $self->in_quote(0);

    my @raw_chunks = split /\* /, $raw_data;
    shift @raw_chunks; # empty string
    carp Dumper @raw_chunks if $DEBUG;
    for my $raw_chunk (@raw_chunks) {
        carp ">$raw_chunk<\n" if $DEBUG;
        my $chunk = new MyCabocha::Chunk(\$self, $raw_chunk);
        $self->set_chunk($chunk);
    }

    return $self;
}

=item * puts

=cut

sub puts {
    my $self = shift;

    # FIXME: not defined
    return if !$self->get_chunk;
    for my $chunk (@{ $self->get_chunk }) {
        $chunk->puts;
    }

    print "EOS\n";
}

=item * get_surface

=cut

sub get_surface {
    my $self = shift;

    # FIXME: not defined
    return if !$self->get_chunk;
    return map { $_->get_surface } @{ $self->get_chunk };
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

=item * in_quote

Check if in quotation or not.

=cut

sub in_quote {
    my $self = shift;

    return (@_ > 0) ? $self->{quote} = shift : $self->{quote};
}

=item * get_np

=cut

sub get_np {
    my $self = shift;

    my @nps;

    for my $chunk (@{ $self->get_chunk }) {
        if (my $np_ref = $chunk->get_np) {
            push @nps, @{ $np_ref };
        }
    }

    return \@nps;
}

=item * get_chunk_by_id

=cut

sub get_chunk_by_id {
    my $self = shift;
    my $cid  = shift;

    for my $chunk (@{ $self->get_chunk }) {
        if ($chunk->get_id == $cid) {
            return $chunk;
        }
    }

    return undef;
}

=item * get_parent()

=cut

sub get_parent {
    my $self = shift;
    return $self->{parent};
}

=item * char()

Set and get the number of accumulated characters from BOS.

=cut

sub char {
    my $self = shift;
    if (@_) {
        my $len  = shift;
        $self->{char} += $len;
    } else {
        $self->{char};
    }
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

    $self->{parent} = shift;
    my $raw_chunk   = shift;
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
        my $morph = new MyCabocha::Morph(\$self, $i, $raw_morphs[$i]);
        $self->set_morph($morph);
        if ($morph->get_pos =~ m/^名詞/gmx) {
            $self->set_np($morph);
        }
    }

    # Chunk info
    if ($self->get_id > 0) {
        $self->{prev} = \${$self->get_parent}->get_chunk_by_id($self->get_id - 1);
        ${$self->prev}->next(\$self);
    }

    # Additional info
    $self->{quote} = ${$self->get_parent}->in_quote;

    return $self;
}

=item * get_parent

=cut

sub get_parent {
    my $self = shift;
    return $self->{parent};
}

=item * get_text

Get text document.

=cut

sub get_text {
    my $self = shift;
    return $self->get_parent;
}

=item * get_text_id

Get text id.

=cut

sub get_text_id {
    my $self = shift;
    return ${$self->get_text}->get_id;
}

=item * prev

Previous chunk.

=cut

sub prev {
    my $self = shift;
    return $self->{prev};
}

=item * next

Set and get next chunk.

=cut

sub next {
    my $self = shift;
    if (@_) {
        $self->{next} = shift;
    } else {
        return $self->{next};
    }
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

=item * get_surface

=cut

sub get_surface {
    my $self = shift;

    return map { $_->get_surface } @{ $self->get_morph };
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

=item * in_quote

Check if in quotation or not.

=cut

sub in_quote {
    my $self = shift;

    $self->{quote};
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

=item * get_head

=cut

sub get_head {
    my $self = shift;

    my $head_id = (split q{/}, $self->get_head_func)[0];
    return $self->get_morph_by_id($head_id);
}

=item * get_func

=cut

sub get_func {
    my $self = shift;

    my $func_id = (split q{/}, $self->get_head_func)[1];
    return $self->get_morph_by_id($func_id);
}

=item * get_morph_by_id

=cut

sub get_morph_by_id {
    my ($self, $mid) = @_;

    for my $morph (@{ $self->get_morph }) {
        if ($morph->get_id == $mid) {
            return $morph;
        }
    }

    return undef;
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

=item * set_np

=cut

sub set_np {
    my $self  = shift;
    my $morph = shift;

    push @{ $self->{np} }, $morph;
}

=item * get_np

=cut

sub get_np {
    my $self = shift;

    return $self->{np};
}

=item * get_depend_id

Get depended chunk id.

=cut

sub get_depend_id {
    my $self = shift;

    my ($cid, $type) = ($self->get_link_rel =~ m/^(-?\d+)([a-zA-Z])$/gmx);
    return $cid;
}

=item * get_depend

Get depended chunk.

=cut

sub get_depend {
    my $self = shift;
    return ${$self->get_text}->get_chunk_by_id($self->get_depend_id);
}

=item * get_depend_path

Get depend path.

=cut

sub get_depend_path {
    my ($self, $paths_ref) = @_;

    my $depend = $self->get_depend;
    if (!$depend) {
        return $paths_ref;
    } else {
        push @{ $paths_ref }, $depend->get_id;
        $depend->get_depend_path($paths_ref);
    }
}

#
# set_ and get_ opinion are not intended for general use
#

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

#use encoding 'euc-jp';

sub new {
    my $self      = {};
    my $class     = shift;
    bless $self, $class;

    $self->{parent} = shift;
    my $id          = shift;
    my $raw_morph   = shift;

    my @labels = split /\t/, $raw_morph;

    $self->set_surface( $labels[0]);
    $self->set_base(    $labels[1]);
    $self->set_read(    $labels[2]);
    $self->set_pos(     $labels[3]);
    $self->set_ctype(   $labels[4]);
    $self->set_cform (  $labels[5]);
    $self->set_ne(      $labels[6]);
    $self->set_relation($labels[7]);
    $self->set_argstr(  $labels[8]);

    # extra-morph settings
    $self->set_num;
    $self->set_id($id);
    $self->len(length $self->get_surface);
    $self->char($self->len);

    my ($head_id, $func_id) = split q[/], ${$self->get_chunk}->get_head_func;
    $self->is_head(($head_id == $self->get_id) ? 1 : 0);
    $self->is_func(($func_id == $self->get_id) ? 1 : 0);

    my $text_ref = $self->get_text;
    if ($self->get_base eq '「') {
        ${$text_ref}->in_quote(${$text_ref}->in_quote + 1);
    }
    if ($self->get_base eq '」') {
        ${$text_ref}->in_quote(${$text_ref}->in_quote - 1);
    }
    $self->{quote} = ${$text_ref}->in_quote;

    return $self;
}

=item * get_parent

=cut

sub get_parent {
    my $self = shift;
    return $self->{parent};
}

=item * get_chunk

Get parent chunk.

=cut

sub get_chunk {
    my $self = shift;
    return $self->get_parent;
}

=item * get_chunk_id

Get chunk id of given morpheme.

=cut

sub get_chunk_id {
    my $self = shift;

    return ${$self->get_chunk}->get_id;
}

=item * get_depend_id

Get depended chunk id.

=cut

sub get_depend_id {
    my $self = shift;

    return ${$self->get_chunk}->get_depend_id;
}

=item * get_depend

Get depended chunk.

=cut

sub get_depend {
    my $self = shift;

    return ${$self->get_chunk}->get_depend;
}

=item * is_head

Return true if the morph is head.

=cut

sub is_head {
    my $self = shift;

    if (@_ > 0) {
        $self->{head} = shift;
    } else {
        return $self->{head};
    }
}

=item * is_func

Return trune if the morph is func.

=cut

sub is_func {
    my $self = shift;

    if (@_ > 0) {
        $self->{func} = shift;
    } else {
        return $self->{func};
    }
}

=item * in_quote

Check if in quotation or not.

=cut

sub in_quote {
    my $self = shift;

    return $self->{quote};
}


=item * get_cab

Get cab object.

=cut

sub get_cab {
    my $self = shift;
    return ${$self->get_text}->get_parent;
}

=item * get_text

Get parent text.

=cut

sub get_text {
    my $self = shift;
    return ${$self->get_chunk}->get_parent;
}

=item * get_text_id

Get text id.

=cut

sub get_text_id {
    my $self = shift;
    return ${$self->get_text}->get_id;
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

=item * set_num

=cut

sub set_num {
    my $self = shift;
    my $cab = ${${$self->get_text}->get_parent};
    $self->{num} = $cab->incr_morph_num - 1;
}

=item + get_num

=cut

sub get_num {
    my $self = shift;
    return $self->{num};
}

=item * char

Set and get accumulated number of characters from BOS.

=cut

sub char {
    my $self = shift;
    if (@_) {
        my $len  = shift;
        $self->{char} = ${$self->get_text}->char;
        ${$self->get_text}->char($len);
    } else {
        $self->{char};
    }
}

=item * len()

=cut

sub len {
    my $self = shift;
    if (@_) {
        $self->{len} = shift;
    } else {
        $self->{len};
    }
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

=item * set_argstr

=cut

sub set_argstr {
    my $self = shift;

    $self->{argstr} = $_[0];

    $self->set_type;
    $self->set_case;

    return $self->{argstr};
}

=item * get_argstr

=cut

sub get_argstr {
    my $self = shift;

    return defined $self->{argstr} ? $self->{argstr} : '';
}

=item * set_type

=cut

sub set_type {
    my $self = shift;

    if (my $type = ($self->get_argstr =~ m/(EVENT|PRED)/gmx)[0]) {
        $self->{type} = $type;
    } else {
        $self->{type} = '';
    }
}

=item * get_type

=cut

sub get_type {
    my $self = shift;

    $self->{type};
}

=item * set_case

=cut

sub set_case {
    my $self = shift;

    for my $case (qw(GA WO NI)) {
        if (my $ln = ($self->get_argstr =~ m/$case=([^,\s]*)/gmx)[0]) {
            $self->{$case} = $ln;
        } else {
            $self->{$case} = '';
        }
    }
}

=item * get_case

=cut

sub get_case {
    my $self = shift;
    my $case = shift;

    $self->{$case};
}

1;
