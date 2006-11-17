#!/usr/local/bin/perl -w
# ===================================================================
my $NAME         = 'Cab.pm';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'CaboCha�ǹ�ʸ���Ϥ�����̤��饪�֥������Ȥ����';
# revised for Seki files
# ===================================================================

use strict;
use GDBM_File;

# my $ZERO_PATH = '/home/ryu-i/work/jcoref/script/ver0/Cab.pm';
# $ZERO_PATH =~ s|[^/]+$||; my $ZERO_DAT_PATH = $ZERO_PATH; 
# $ZERO_DAT_PATH =~ s|[^/]+/+[^/]+/+$|dat/|; unshift @INC, $ZERO_PATH;

require 'check_edr.pl';
require 'check_pronoun_type.pl';
require 'add_func_exp.pl';

my $rengo = $ENV{ENA_GDBM_DIR}.'/rengo.gdbm';
tie my %rengo, 'GDBM_File', $rengo, GDBM_READER, 0644 or die $!;

sub open_cab_file {
    my $file = shift;
    $/ = "EOS\n";
    my @s = ();
    open 'FL', $file or die $!;
    while (<FL>) {
	chomp; 
	my $s = Sentence->new($_);
	push @s, $s if (ref($s) eq 'Sentence');
    }
    close FL;

    my $s_num = @s;
    for (my $sid=0;$sid<$s_num;$sid++) {
	my @b = @{$s[$sid]->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    $b[$bid]->sid($sid);
	}
    }
    my $t = Txt->new;
    $t->Sentence(\@s);
    return $t;
}

sub open_cab_dir {
    my $dir = shift; 
    my $suffix = (@_)? shift : 'cab';
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /$suffix$/, readdir DIR;
    closedir DIR;

    my @t = ();
    for my $file (@file) {
	print STDERR 'cab: ',  $file, "\n";
	my $t = &open_cab_file($dir.'/'.$file);
	my $tid = $file; $tid =~ s/\.$suffix$//; $t->id($tid);
	push @t, $t;
#  	last; ##
    }
    return \@t;
}


# ===================================================================
# �����Ǥξ���򰷤����饹
# ===================================================================
package Mor;

# construct
sub new {
    my $self = {};
    bless $self;
    my $type = shift;
    if (scalar(@_) == 1) {
	my @mor = split '\t', shift;	
	$self->WF($mor[0]);
	$self->READ($mor[1]);
	$self->BF($mor[2]);
	$self->POS($mor[3]);
	$self->CT($mor[4]);
	$self->CF($mor[5]);
	$self->NE($mor[6]) if ($mor[6]);
	$self->EQ($mor[7]) if ($mor[7]);
	$self->ANAPHOR($mor[8]) if ($mor[8]);	
	$self->AUX($self->check_aux());
    } elsif (scalar(@_) > 1) {
	$self->WF($_[0]);
	$self->READ($_[1]);
	$self->BF($_[2]);
	$self->POS($_[3]);
	$self->CT($_[4]);
	$self->CF($_[5]);
	$self->NE($_[6]) if ($_[6]);
	$self->EQ($_[8]) if ($_[8]);
	$self->ANAPHOR($_[9]) if ($_[9]);	
    } else { # init
	$self->WF('');
	$self->READ('');
	$self->BF('');
	$self->POS('');
	$self->CT('');
	$self->CF('');
	$self->NE('');
	$self->ZERO('');
    }
    $self->BF($self->WF) unless ($self->BF);
    $self;
}

# word form
sub WF {
    my $self = shift;
    if (@_) {
	$self->{WF} = $_[0];
    } else {
	return $self->{WF};
    }
}

# read
sub READ {
    my $self = shift;
    if (@_) {
	$self->{READ} = $_[0];
    } else {
	return $self->{READ};
    }
}

# base form
sub BF {
    my $self = shift;
    if (@_) {
	$self->{BF} = $_[0];
    } else {
	return $self->{BF};
    }
}

# part of speech
sub POS {
    my $self = shift;
    if (@_) {
	$self->{POS} = $_[0];
    } else {
	return $self->{POS};
    }
}

# conjugative type
sub CT {
    my $self = shift;
    if (@_) {
	$self->{CT} = $_[0];
    } else {
	return $self->{CT};
    }
}

# conjugative form
sub CF {
    my $self = shift;
    if (@_) {
	$self->{CF} = $_[0];
    } else {
	return $self->{CF};
    }
}

# named entity
sub NE {
    my $self = shift;
    if (@_) {
	$self->{NE} = $_[0];
    } else {
	return $self->{NE};
    }
}

# zero
sub ZERO {
    my $self = shift;
    if (@_) {
	$self->{ZERO} = $_[0];
    } else {
	return $self->{ZERO}
    }
}

# ��ǽ��������礫�ɤ���
# �ºݤ˲��Ϥ������
sub FUNC_EXP {
    my $self = shift;
    if (@_) {
	$self->{FUNC_EXP} = $_[0];
    } else {
	return $self->{FUNC_EXP};
    }
}

# �����դ�������ǽ������ɽ��
sub func_exp {
    my $self = shift;
    if (@_) {
	$self->{func_exp} = $_[0];
    } else {
	return $self->{func_exp};
    }
}

sub AUX {
    my $self = shift;
    if (@_) {
	$self->{AUX} = $_[0];
    } else {
	return $self->{AUX};
    }
}

sub EQ {
    my $self = shift;
    if (@_) {
	$self->{EQ} = $_[0];
    } else {
	return $self->{EQ};
    }
}

sub ANAPHOR {
    my $self = shift;
    if (@_) {
	$self->{ANAPHOR} = $_[0];
    } else {
	return $self->{ANAPHOR};
    }
}

# jsa
sub JSA_ID {
    my $self = shift;
    if (@_) {
	$self->{JSA_ID} = $_[0];
    } else {
	return $self->{JSA_ID};
    }
}

sub JSA_GA {
    my $self = shift;
    if (@_) {
	$self->{JSA_GA} = $_[0];
    } else {
	return $self->{JSA_GA};
    }
}

sub JSA_WO {
    my $self = shift;
    if (@_) {
	$self->{JSA_WO} = $_[0];
    } else {
	return $self->{JSA_WO};
    }
}

sub JSA_NI {
    my $self = shift;
    if (@_) {
	$self->{JSA_NI} = $_[0];
    } else {
	return $self->{JSA_NI};
    }
}

sub JSA_NO {
    my $self = shift;
    if (@_) {
	$self->{JSA_NO} = $_[0];
    } else {
	return $self->{JSA_NO};
    }
}

sub JSA_EQ {
    my $self = shift;
    if (@_) {
	$self->{JSA_EQ} = $_[0];
    } else {
	return $self->{JSA_EQ};

    }
}

sub JSA_REF {
    my $self = shift;
    if (@_) {
	$self->{JSA_REF} = $_[0];
    } else {
	return $self->{JSA_REF};
    }
}

sub sid {
    my $self = shift;
    if (@_) {
	$self->{sid} = $_[0];
    } else {
	return $self->{sid};
    }
}

sub bid {
    my $self = shift;
    if (@_) {
	$self->{bid} = $_[0];
    } else {
	return $self->{bid};
    }
}

sub mid {
    my $self = shift;
    if (@_) {
	$self->{mid} = $_[0];
    } else {
	return $self->{mid};
    }
}

sub PRED_ID {
    my $self = shift;
    if (@_) {
	$self->{PRED_ID} = $_[0];
    } else {
	return $self->{PRED_ID};
    }
}

sub puts {
    my $self = shift;
    my $out = '';
    $out .= $self->WF.   "\t";
    $out .= $self->READ. "\t";
    $out .= $self->BF.   "\t";
    $out .= $self->POS.  "\t";
    if ($self->CT) {
	$out .= $self->CT. "\t";
    } else {
	$out .= "\t";
    }
    if ($self->CF) {
	$out .= $self->CF;
    }
    if ($self->NE) {
	$out .= "\t". $self->NE;
    }
    $out .= "\n";
    return $out;
}

sub puts2 {
    my $self = shift;
    my $out = '';
#     my @out = ();
#     push @out, ($self->WF, $self->READ, $self->BF, $self->POS);

    $out .= $self->WF.   "\t";
    $out .= $self->READ. "\t";
    $out .= $self->BF.   "\t";
    $out .= $self->POS.  "\t";
    $out .= ($self->CT)? $self->CT."\t" : "\t";
    $out .= ($self->CF)? $self->CF."\t" : "\t";
    $out .= ($self->NE)? $self->NE."\t" : "\t";
    $out .= ($self->EQ)? 'EQ:'.$self->EQ."\t" : "\t";
    $out .= ($self->ANAPHOR)? 'ANA:'.$self->ANAPHOR."\t" : "\t";                
# 	$out .= $self->CT. "\t";
#     } else {
# 	$out .= "\t";
#     }
#     if ($self->CF) {
# 	$out .= $self->CF;
#     }
#     if ($self->NE) {
# 	$out .= "\t". $self->NE;
#     }
#     if ($self->EQ) {
# 	$out .= "\t". $self->EQ;
#     } else {

#     }
#     if ($self->EQ
#     $out .= "\n";
    $out =~ s/\t$/\n/;
    return $out;
}

sub puts_e {
    my $self = shift;
    my $out = '';

    $out .= $self->WF.   "\t";
    $out .= $self->READ. "\t";
    $out .= $self->BF.   "\t";
    $out .= $self->POS.  "\t";
    $out .= ($self->CT)? $self->CT."\t" : "\t";
    $out .= ($self->CF)? $self->CF."\t" : "\t";
    $out .= ($self->NE)? $self->NE."\t" : "\t";
    $out .= ($self->EQ)? 'EQ:'.$self->EQ."\t" : "\t";

    my @tmp = ();
    if ($self->EVENT) {
	my @foo = (); 
	push @foo, 'GA='.$self->GA if ($self->GA);
	push @foo, 'WO='.$self->WO if ($self->WO); 
	push @foo, 'NI='.$self->NI if ($self->NI);
	push @tmp, 'EVENT:'.join ',', @foo;
    }
    if ($self->PRED_ID) {
	my @foo = (); 
	push @foo, 'GA='.$self->GA if ($self->GA);
	push @foo, 'WO='.$self->WO if ($self->WO); 
	push @foo, 'NI='.$self->NI if ($self->NI);
	push @tmp, 'PRED:'.join ',', @foo;
    }
    if ($self->ID) {
	push @tmp, 'ID='.$self->ID;
    }
    $out .= join ' ', @tmp if (@tmp);
    return $out;
}

sub check_aux {
    my $m = shift;
    return 1 if ($m->BF =~ /^(?:���|����|����|������|�ۤ���|��餦|��������|
			      ����|�����|������|��������|���|������)$/x);
    return 0;
}

# copy constructor
sub copy {
    my $self = shift;
    my $copy = Mor->new($self->WF, $self->READ, $self->BF, $self->POS,
			$self->CT, $self->CF, $self->NE, $self->ZERO);
    return $copy;
}

sub puts_xml_begin {
    my $self = shift;
    my @m = ();
#     my $out = '<m ';
    push @m, 'wf="'.  $self->WF.  '"';
    push @m, 'read="'.$self->READ.'"';
    push @m, 'bf="'.  $self->BF.  '"';
    push @m, 'pos="'. $self->POS. '"';
    push @m, 'ct="'.  $self->CT.  '"';
    push @m, 'cf="'.  $self->CF.  '"';
    push @m, 'ne="'.  $self->NE.  '"';
    return '<m '.join(' ', @m).'>';
}

sub puts_xml_end {
    my $self = shift;
    return '</m>';
}

sub GA {
    my $self = shift;
    if (@_) {
	$self->{GA} = $_[0];
    } else {
	return $self->{GA};
    }
}
sub WO {
    my $self = shift;
    if (@_) {
	$self->{WO} = $_[0];
    } else {
	return $self->{WO};
    }
}
sub NI {
    my $self = shift;
    if (@_) {
	$self->{NI} = $_[0];
    } else {
	return $self->{NI};
    }
}
sub EVENT {
    my $self = shift;
    if (@_) {
	$self->{EVENT} = $_[0];
    } else {
	return $self->{EVENT};
    }
}
sub ID {
    my $self = shift;
    if (@_) {
	$self->{ID} = $_[0];
    } else {
	return $self->{ID};
    }
}


# ===================================================================
# ʸ��ξ���򰷤����饹
# ===================================================================
package Bunsetsu;

sub new {
    my $self = {};
    my $type = shift;
    bless $self;
    if (@_) {
	my ($id, $dep, $dep_type, $head, $func, $weight, $dref) = @_;
	$self->id($id);	
	$self->dep($dep);
	$self->dep_type($dep_type);
	$self->head($head);
	$self->func($func);
	$self->weight($weight);
  	$self->dtr($dref);	
  	$self->ZERO('');
    } else { # init
	$self->id('');	
	$self->dep('');
	$self->dep_type('');
	$self->head('');
	$self->func('');
	$self->weight('');
	$self->ZERO('');
    }
    bless $self;
    $self;
}

sub sid {
    my $self = shift;
    if (@_) {
	$self->{sid} = $_[0];
    } else {
	return $self->{sid};
    }
}

sub ID {
    my $self = shift;
    if (@_) {
	$self->{ID} = $_[0];
    } else {
	return $self->{ID};
    }
}

# NULL�Ǥ��뤳�Ȥ�ɽ��
# �ֳ����ȱ��פǤ��ä��ꡤ�־ȱ���̵���פξ����Ѥ���
sub NULL {
    my $self = shift;
    if (@_) {
	$self->{NULL} = $_[0];
    } else {
	return $self->{NULL};
    }
}

# ʸ��ID
sub id {
    my $self = shift;
    if (@_) {
	$self->{id} = $_[0];
    } else {
	return $self->{id};
    }
}

# �������ʸ��ID
sub dep {
    my $self = shift;
    if (@_) {
	$self->{dep} = $_[0];
    } else {
	return $self->{dep};
    }
}

# �缭�Ȥʤ����Ƹ�η�����ID
sub head {
    my $self = shift;
    if (@_) {
	$self->{head} = $_[0];
    } else {
	return $self->{head};
    }
}

# 
sub tmp_head {
    my $self = shift;
    if (@_) {
	$self->{tmp_head} = $_[0];
    } else {
	return $self->{tmp_head};
    }
}

# ��ǽ��η�����ID
sub func {
    my $self = shift;
    if (@_) {
	$self->{func} = $_[0];
    } else {
	return $self->{func};
    }
}

# SVM�ν��Ϥ���Ť�
sub weight {
    my $self = shift;
    if (@_) {
	$self->{weight} = $_[0];
    } else {
	return $self->{weight};
    }
}

# �����Ȥ�����
sub dtr {
    my $self = shift;
    if (@_) {
	$self->{dtr} = (ref($_[0]) eq 'ARRAY')? $_[0] : [];
    } else {
	return $self->{dtr};
    }
}

# D, O, P, I
sub dep_type {
    my $self = shift;
    if (@_) {
	$self->{dep_type} = $_[0];
    } else {
	return $self->{dep_type};
    }
}

sub SENT_INDEX {
    my $self = shift;
    if (@_) {
	$self->{SENT_INDEX} = $_[0];
    } else {
	return $self->{SENT_INDEX};
    }
}

sub Mor {
    my $self = shift;
    if (@_) {
	$self->{mor} = $_[0];
    } else {
	return $self->{mor};
    }
}

sub NOUN {
    my $self = shift;
    if (@_) {
	$self->{NOUN} = $_[0];
    } else {
	return $self->{NOUN};
    }
}

sub I_NOUN {
    my $self = shift;
    if (@_) {
	$self->{I_NOUN} = $_[0];
    } else {
	return $self->{I_NOUN};
    }
}

sub PRED {
    my $self = shift;
    if (@_) {
	$self->{PRED} = $_[0];
    } else {
	return $self->{PRED};
    }
}

sub PRED_ID {
    my $self = shift;
    if (@_) {
        $self->{PRED_ID} = $_[0];
    } else {
        return $self->{PRED_ID};
    }
}

sub PRED_TYPE {
    my $self = shift;
    if (@_) {
        $self->{PRED_TYPE} = $_[0];
    } else {
        return $self->{PRED_TYPE};
    }
}

sub LENGTH {
    my $self = shift;
    if (@_) {
	$self->{LENGTH} = $_[0];
    } else {
	return $self->{LENGTH};
    }
}
	
# zero
sub ZERO {
    my $self = shift;
    if (@_) {
	$self->{ZERO} = $_[0];
    } else {
	return $self->{ZERO}
    }
}

sub EQ {
    my $self = shift;
    if (@_) {
	$self->{EQ} = $_[0];
    } else {
	return $self->{EQ};
    }
}

sub HEAD_EQ {
    my $self = shift;
    if (@_) {
	$self->{HEAD_EQ} = $_[0];
    } else {
	return $self->{HEAD_EQ};
    }
}

sub HEAD_ANA {
    my $self = shift;
    if (@_) {
	$self->{HEAD_ANA} = $_[0];
    } else {
	return $self->{HEAD_ANA};
    }
}

sub EQ_FIRST {
    my $self = shift;
    if (@_) {
	$self->{EQ_FIRST} = $_[0];
    } else {
	return $self->{EQ_FIRST};
    } 
}

sub EQ_TYPE {
    my $self = shift;
    if (defined $_[1]) {
	# ex: EQ_TYPE ('��', '1') = true;
	$self->{EQ_TYPE}{$_[0]}{$_[1]} = 1;
#    	push @{$self->{EQ_CHECK}{$_[1]}}, $_[0];
    	$self->{EQ_CHECK}{$_[1]}{$_[0]} = 1;	
    } elsif (defined $_[0]) {	
     # return hash reference
	if ($self->{EQ_TYPE}{$_[0]}) {
	    return $self->{EQ_TYPE}{$_[0]};
	} else {
  	    return {};
	}
    } else {
	return $self->{EQ_TYPE};
    }
}

sub EQ_CHECK {
    my $self = shift;
    if (ref($self->{EQ_TYPE}) eq 'HASH') {
	return 1;
    } else {
	return 0;
    }
}

sub EQ_CHECK2 {
    my $self = shift;
    if (@_) {
	if ($self->{EQ_CHECK}{$_[0]}) {
	    return $self->{EQ_CHECK}{$_[0]};
	} else {
	    return undef;
	}
    } else {
	die "cannot use no argment in EQ_CHECK2\n";
    }
}

# Ϣ��ν�����Ԥä����
sub CASE {
    my $self = shift;
    if (@_) {
	$self->{CASE} = $_[0];
    } else {
	return $self->{CASE};
    }
}

# ʿ������
sub CASE_H {
    my $self = shift;
    if (@_) {
	$self->{CASE_H} = $_[0];
    } else {
	return $self->{CASE_H};
    }
}

# Ϣ��ν�����Ԥ鷺��������򤽤Τޤ����
sub CASE_ORG {
    my $self = shift;
    if (@_) {
	$self->{CASE_ORG} = $_[0];
    } else {
	return $self->{CASE_ORG};
    }
}

sub STRING {
    my $self = shift;
    if (@_) {
	$self->{STRING} = $_[0];
    } else {
	return $self->{STRING};
    }
}

sub SHIFT_WF {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_WF} = $_[0];
    } else {
	return $self->{SHIFT_WF};
    }
}

sub WF {
    my $self = shift;
    if (@_) {
	$self->{WF} = $_[0];
    } else {
	return $self->{WF};
    }
}

sub FUNC {
    my $self = shift;
    if (@_) {
	$self->{FUNC} = $_[0];
    } else {
	return $self->{FUNC};
    }
}

sub DEFINITE {
    my $self = shift;
    if (@_) {
	$self->{DEFINITE} = $_[0];
    } else {
	return $self->{DEFINITE};
    }
}

sub PRE_DEFINITE {
    my $self = shift;
    if (@_) {
	$self->{PRE_DEFINITE} = $_[0];
    } else {
	return $self->{PRE_DEFINITE};
    }
}

sub EDR_PERSON {
    my $self = shift;
    if (@_) {
	$self->{EDR_PERSON} = $_[0];
    } else {
	return $self->{EDR_PERSON};
    }
}

sub EDR_ORG {
    my $self = shift;
    if (@_) {
	$self->{EDR_ORG} = $_[0];
    } else {
	return $self->{EDR_ORG};
    }
}

sub ANIMACY {
    my $self = shift;
    if (@_) {
	$self->{ANIMACY} = $_[0];
    } else {
	return $self->{ANIMACY};
    }
}

sub HEAD_WF {
    my $self = shift;
    if (@_) {
	$self->{HEAD_WF} = $_[0];
    } else {
	return $self->{HEAD_WF};
    }
}

sub HEAD_BF {
    my $self = shift;
    if (@_) {
	$self->{HEAD_BF} = $_[0];
    } else {
	return $self->{HEAD_BF};
    }
}

sub HEAD_POS {
    my $self = shift;
    if (@_) {
	$self->{HEAD_POS} = $_[0];
    } else {
	return $self->{HEAD_POS};
    }
}

sub TMP_HEAD_POS {
    my $self = shift;
    if (@_) {
	$self->{TMP_HEAD_POS} = $_[0];
    } else {
	return $self->{TMP_HEAD_POS};
    }
}

sub HEAD_NE {
    my $self = shift;
    if (@_) {
	$self->{HEAD_NE} = $_[0];
    } else {
	return $self->{HEAD_NE};
    }
}

sub HEAD_NOUN {
    my $self = shift;
    if (@_) {
	$self->{HEAD_NOUN} = $_[0];
    } else {
	return $self->{HEAD_NOUN};
    }
}

sub HEAD_FUNC_EXP {
    my $self = shift;
    if (@_) {
	$self->{HEAD_FUNC_EXP} = $_[0];
    } else {
	return $self->{HEAD_FUNC_EXP};
    }
}

sub head_func_exp {
    my $self = shift;
    if (@_) {
	$self->{head_func_exp} = $_[0];
    } else {
	return $self->{head_func_exp};
    }
}

sub SHIFT_HEAD_POS {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD_POS} = $_[0];
    } else {
	$self->{SHIFT_HEAD_POS};	
    }
}

sub SHIFT_HEAD_NOUN {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD_NOUN} = $_[0];
    } else {
	return $self->{SHIFT_HEAD_NOUN};
    }
}

sub SHIFT_HEAD_WF {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD_WF} = $_[0];
    } else {
	return $self->{SHIFT_HEAD_WF};
    }
}

sub SHIFT_HEAD_BF {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD_BF} = $_[0];
    } else {
	return $self->{SHIFT_HEAD_BF};
    }
}

sub SHIFT_HEAD_NE {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD_NE} = $_[0];
    } else {
	return $self->{SHIFT_HEAD_NE};
    }
}

sub MAIN_HEAD {
    my $self = shift;
    if (@_) {
	$self->{MAIN_HEAD} = $_[0];
    } else {
	return $self->{MAIN_HEAD};
    }
}

sub EMBEDDED {
    my $self = shift;
    if (@_) {
	$self->{EMBEDDED} = $_[0];
    } else {
	return $self->{EMBEDDED};
    }
}

sub CHAIN_LENGTH {
    my $self = shift;
    if (@_) {
	$self->{CHAIN_NUM} = $_[0];
    } else {
	return $self->{CHAIN_NUM};
    }
}

sub PRONOUN_TYPE {
    my $self = shift;
    if (@_) {
	$self->{PRONOUN_TYPE} = $_[0];
    } else {
	return $self->{PRONOUN_TYPE};
    }
}

sub SENT_END {
    my $self = shift;
    if (@_) {
	$self->{SENT_END} = $_[0];
    } else {
	return $self->{SENT_END};
    }
}

sub SENT_BEGIN {
    my $self = shift;
    if (@_) {
	$self->{SENT_BEGIN} = $_[0];
    } else {
	return $self->{SENT_BEGIN};
    }
}

sub AGT {
    my $self = shift;
    if (@_) {
	$self->{AGT} = $_[0];
    } else {
	return $self->{AGT};
    }
}

sub SWITCH_REF {
    my $self = shift;
    if (@_) {
	$self->{SWITCH_REF} = $_[0];
    } else {
	return $self->{SWITCH_REF};
    }
}

sub S_MARKER {
    my $self = shift;
    if (@_) {
	$self->{S_MARKER} = $_[0];
    } else {
	return $self->{S_MARKER};
    }
}

sub CONJ_VAL {
    my $self = shift;
    if (@_) {
	$self->{CONJ_VAL} = $_[0];
    } else {
	return $self->{CONJ_VAL};
    }
}

sub DEP_CASE {
    my $self = shift;
    if (@_) {
	$self->{DEP_CASE} = $_[0];
    } else {
	return $self->{DEP_CASE};
    }
}

sub IN_QUOTE {
    my $self = shift;
    if (@_) {
	$self->{IN_QUOTE} = $_[0];
    } else {
	return $self->{IN_QUOTE};
    }
}

sub QUOTE_TYPE {
    my $self = shift;
    if (@_) {
	$self->{QUOTE_TYPE} = $_[0];
    } else {
	return $self->{QUOTE_TYPE};
    }
}

sub descendant {
    my $self = shift;
    if (@_) {
	$self->{descendant} = $_[0];
    } else {
	return $self->{descendant};
    }
}

sub is_exophora {
    my $self = shift;
    if (@_) {
	$self->{is_exophora} = $_[0];
    } else {
	return $self->{is_exophora};
    }
}

# ����
sub voice {
    my $self = shift;
    if (@_) {
	$self->{voice} = $_[0];
    } else {
	return $self->{voice};
    }
}

# ���Ϸ��
sub VOICE {
    my $self = shift;
    if (@_) {
	$self->{VOICE} = $_[0];
    } else {
	return $self->{VOICE};
    }
}

sub COMMENT {
    my $self = shift;
    if (@_) {
	$self->{COMMENT} = $_[0];
    } else {
	return $self->{COMMENT};
    }
}

sub MULTISUB {
    my $self = shift;
    if (@_) {
	$self->{MULTISUB} = $_[0];
    } else {
	return $self->{MULTISUB};
    }
}

sub CAND {
    my $self = shift;
    if (@_) {
	$self->{CAND} = $_[0];
    } else {
	return $self->{CAND};
    }
}

sub CAND_ADD {
    my $self = shift;
    if (@_) {
	push @{$self->{CAND}}, $_[0];
    } else {
	return $self->{CAND};
    }
}

# ��α
sub RESERVE {
    my $self = shift;
    if (@_) {
	$self->{RESERVE} = $_[0];
    } else {
	return $self->{RESERVE};
    }
}

# ɽ�إ�
sub SURF_GA {
    my $self = shift;
    if (@_) {
	$self->{SURF_GA} = $_[0];
    } else {
	return $self->{SURF_GA};
    } 
} 

sub SURF_GA_ADD {
    my $self = shift;
    if (@_) {
	push @{$self->{SURF_GA}}, $_[0];
    } else {
	return $self->{SURF_GA};
    } 
} 

sub JSA_EQ {
    my $self = shift;
    if (@_) {
	$self->{JSA_EQ} = $_[0];
    } else {
	return $self->{JSA_EQ};
    }
}

sub JSA_EQ_ID {
    my $self = shift;
    if (@_) {
	$self->{JSA_EQ_ID} = $_[0];
    } else {
	return $self->{JSA_EQ_ID};
    }
}

sub JSA_EQ_LNK {
    my $self = shift;
    if (@_) {
	$self->{JSA_EQ_LNK} = $_[0];
    } else {
	return $self->{JSA_EQ_LNK};
    }
}

sub JSA_EQ_LNK_ADD {
    my $self = shift;
    if (@_) {
	push @{$self->{JSA_EQ_LNK}}, $_[0];
    } else {
	die "jSA_EQ_LNK_ADD\n";
    }
}

sub JSA_EXO_GA {
    my $self = shift;
    if (@_) {
	$self->{JSA_EXO_GA} = $_[0];
    } else {
	return $self->{JSA_EXO_GA};
    }
}

sub JSA_EXO_WO {
    my $self = shift;
    if (@_) {
	$self->{JSA_EXO_WO} = $_[0];
    } else {
	return $self->{JSA_EXO_WO};
    }
}

sub JSA_EXO_NI {
    my $self = shift;
    if (@_) {
	$self->{JSA_EXO_NI} = $_[0];
    } else {
	return $self->{JSA_EXO_NI};
    }
}

sub JSA_EXO_NP {
    my $self = shift;
    if (@_) {
	$self->{JSA_EXO_NP} = $_[0];
    } else {
	return $self->{JSA_EXO_NP};
    }
}

# ɽ�إ�
sub SURF_WO {
    my $self = shift;
    if (@_) {
	$self->{SURF_WO} = $_[0];
    } else {
	return $self->{SURF_WO};
    } 
} 

sub SURF_WO_ADD {
    my $self = shift;
    if (@_) {
	push @{$self->{SURF_WO}}, $_[0];
    } else {
	return $self->{SURF_WO};
    } 
} 

# ɽ�إ�
sub SURF_NI {
    my $self = shift;
    if (@_) {
	$self->{SURF_NI} = $_[0];
    } else {
	return $self->{SURF_NI};
    } 
} 

sub SURF_NI_ADD {
    my $self = shift;
    if (@_) {
	push @{$self->{SURF_NI}}, $_[0];
    } else {
	return $self->{SURF_NI};
    } 
} 

sub EMPHASIS {
    my $self = shift;
    if (@_) {
	$self->{EMPHASIS} = $_[0];
    } else {
	return $self->{EMPHASIS};
    }
}

sub QUOTE {
    my $self = shift;
    if (@_) {
	$self->{QUOTE} = $_[0];
    } else {
	return $self->{QUOTE};
    }
}

sub SPEAKER {
    my $self = shift;
    if (@_) {
	return $self->{SPEAKER}{$_[0]};
    } else {
	return ($self->{SPEAKER})? $self->{SPEAKER} : {};
    }
}

sub SPEAKER_ADD {
    my $self = shift;
    if (@_) {
	$self->{SPEAKER}{$_[0]} = 1;
    } else {
	die "SPEAKER_ADD: cannot take no argument\n";
    }
}

sub EX_SPEAKER {
    my $self = shift;
    if (@_) {
	$self->{EX_SPEAKER} = $_[0];
    } else {
	return $self->{EX_SPEAKER};
    }
}

sub ZERO_GA {
    my $self = shift;
    if (@_) {
	$self->{ZERO_GA} = $_[0];
    } else {
	return $self->{ZERO_GA};
    }
}

sub ZERO_WO {
    my $self = shift;
    if (@_) {
	$self->{ZERO_WO} = $_[0];
    } else {
	return $self->{ZERO_WO};
    }
}

sub ZERO_NI {
    my $self = shift;
    if (@_) {
	$self->{ZERO_NI} = $_[0];
    } else {
	return $self->{ZERO_NI};
    }
}

sub ELLIPSIS_GA {
    my $self = shift;
    if (@_) {
	$self->{ELLIPSIS_GA} =  $_[0];
    } else {
	return $self->{ELLIPSIS_GA};
    }
}

sub ELLIPSIS_WO {
    my $self = shift;
    if (@_) {
	$self->{ELLIPSIS_WO} =  $_[0];
    } else {
	return $self->{ELLIPSIS_WO};
    }
}

sub ELLIPSIS_NI {
    my $self = shift;
    if (@_) {
	$self->{ELLIPSIS_NI} =  $_[0];
    } else {
	return $self->{ELLIPSIS_NI};
    }
}

# for ext_tgr3.pl��
sub d_ga {
    my $self = shift;
    if (@_) {
	$self->{d_ga} = $_[0];
    } else {
	return $self->{d_ga};
    }
}

sub d_wo {
    my $self = shift;
    if (@_) {
	$self->{d_wo} = $_[0];
    } else {
	return $self->{d_wo};
    }
}

sub d_ni {
    my $self = shift;
    if (@_) {
	$self->{d_ni} = $_[0];
    } else {
	return $self->{d_ni};
    }
}

# ���δط�
sub D_SOTO {
    my $self = shift;
    if (@_) {
	$self->{D_SOTO} = $_[0];
    } else {
	return $self->{D_SOTO};
    }
}

# for Hirano
sub D_GA {
    my $self = shift;
    if (@_) {
	$self->{D_GA} = $_[0];
    } else {
	return $self->{D_GA};
    }
}

sub D_ZERO_GA {
    my $self = shift;
    if (@_) {
	$self->{D_ZERO_GA} = $_[0];
    } else {
	return $self->{D_ZERO_GA};
    }
}

sub D_WO {
    my $self = shift;
    if (@_) {
	$self->{D_WO} = $_[0];
    } else {
	return $self->{D_WO};
    }
}

sub D_ZERO_WO {
    my $self = shift;
    if (@_) {
	$self->{D_ZERO_WO} = $_[0];
    } else {
	return $self->{D_ZERO_WO};
    }
}

sub D_NI {
    my $self = shift;
    if (@_) {
	$self->{D_NI} = $_[0];
    } else {
	return $self->{D_NI};
    }
}

sub D_ZERO_NI {
    my $self = shift;
    if (@_) {
	$self->{D_ZERO_NI} = $_[0];
    } else {
	return $self->{D_ZERO_NI};
    }
}

sub incompatible {
    my $self = shift;
    if (@_) {
	$self->{incompatible} = $_[0];
    } else {
	return $self->{incompatible};
    }
}

sub D_RERU {
    my $self = shift;
    if (@_) {
	$self->{D_RERU} = $_[0];
    } else {
	return $self->{D_RERU};
    }
}

sub D_SERU {
    my $self = shift;
    if (@_) {
	$self->{D_SERU} = $_[0];
    } else {
	return $self->{D_SERU};
    }
}

sub D_HOSHII {
    my $self = shift;
    if (@_) {
	$self->{D_HOSHII} = $_[0];
    } else {
	return $self->{D_HOSHII};
    }
}

sub D_MORAU {
    my $self = shift;
    if (@_) {
	$self->{D_MORAU} = $_[0];
    } else {
	return $self->{D_MORAU};
    }
}

sub D_KURERU {
    my $self = shift;
    if (@_) {
	$self->{D_KURERU} = $_[0];
    } else {
	return $self->{D_KURERU};
    }
}

sub D_YARU {
    my $self = shift;
    if (@_) {
	$self->{D_YARU} = $_[0];
    } else {
	return $self->{D_YARU};
    }
}

# �ط�np
sub relNP {
    my $self = shift;
    if (@_) {
	$self->{relNP} = $_[0];
    } else {
	return $self->{relNP};
    }
}

# sub ANAPHOR {
#     my $self = shift;
#     if (@_) {
# 	$self->{ANAPHOR} = $_[0];
#     } else {
# 	return $self->{ANAPHOR};
#     }
# }

# Ʊ...
sub DOU {
    my $self = shift;
    if (@_) {
	$self->{DOU} = $_[0];
    } else {
	return $self->{DOU};
    }
}
    
sub SHIFT_HEAD {
    my $self = shift;
    if (@_) {
	$self->{SHIFT_HEAD} = $_[0];
    } else {
	return $self->{SHIFT_HEAD};
    }
}


# bunsetsu method end
    
sub puts {
    my $self = shift;
    my @mor = @{$self->Mor};
    my $out = '';
    $out .= '* '.$self->id.' '.$self->dep.$self->dep_type.' '.
	    $self->head.'/'.$self->func.' '.$self->weight."\n";
    for my $m (@mor) {
	$out .= $m->puts;
    }
    return $out;
}

sub puts2 {
    my $self = shift;
    my @mor = @{$self->Mor};
    my $out = '';
    $out .= '* '.$self->id.' '.$self->dep.$self->dep_type.' '.
	    $self->head.'/'.$self->func."\n";
    $out .= &puts2_sub($self->GA, '��') if ($self->GA);
    $out .= &puts2_sub($self->WO, '��') if ($self->WO);
    $out .= &puts2_sub($self->NI, '��') if ($self->NI);    
    for my $m (@mor) {
	$out .= $m->puts;
    }
    if ($self->TMP) {
	$out .= $self->TMP.' '.$self->CONJ_TYPE.' by '.$self->CONJ."\n";
    }
    return $out;
}

sub puts2_sub {
    my $zero = shift;
    my $ellipsis = shift;
    my $out = '';
    $out .= '!COREF '.$zero->COREF. "\t";
    $out .= ($zero->COREF_TYPE)? $zero->COREF_TYPE."\t" : "\t"; 
    $out .= $zero->voice. "\t";
    $out .= $ellipsis. "\t";
    $out .= $zero->WF. "\n";
    return $out;
}

sub puts_e {
    my $self = shift;
    my @mor = @{$self->Mor};
    my $out = '';
    $out .= '* '.$self->id.' '.$self->dep.$self->dep_type.' '.
	    $self->head.'/'.$self->func.' '.$self->weight."\n";
    for my $m (@mor) {
	$out .= $m->puts_e."\n";;
    }
    return $out;
}

sub GA {
    my $self = shift;
    if (@_) {
	$self->{GA} = $_[0];
    } else {
	return $self->{GA};
    }
}

sub WO {
    my $self = shift;
    if (@_) {
	$self->{WO} = $_[0];
    } else {
	return $self->{WO};
    }
}

sub NI {
    my $self = shift;
    if (@_) {
	$self->{NI} = $_[0];
    } else {
	return $self->{NI};
    }
}

sub AUX {
    my $self = shift;
    if (@_) {
	$self->{AUX} = $_[0];
    } else {
	return $self->{AUX};
    }
}
# end: obligatory case

sub CONJ {
    my $self = shift;
    if (@_) {
	$self->{CONJ} = $_[0];
    } else {
	return $self->{CONJ};
    }
}    

sub CONJ_TYPE {
    my $self = shift;
    if (@_) {
	$self->{CONJ_TYPE} = $_[0];
    } else {
	return $self->{CONJ_TYPE};
    }
}    

# copy constructor
sub copy {
    my $self       = shift;
    my $zero_id    = shift; # -2 >= zero_id
    my $type       = shift; # '�ե�' �ʤ�
    my $ana        = shift;
    
    my $copy = Bunsetsu->new($zero_id, $ana->id, 'D', $self->head,
			     $self->func, $self->weight, {$ana->id=>[]});
    my @mor = @{$self->Mor};
    my @cp_mor = ();
    my $head = $copy->head;
    for (my $i=0;$i<=$head;$i++) {
	push @cp_mor, $mor[$i]->copy;
    }
    my $case;
    $case = Mor::new('Mor', '��', '��', '��', '����-�ʽ���-����',
  		     '', '', 'O') if ($type =~ /��$/);
    $case = Mor::new('Mor', '��', '��', '��', '����-�ʽ���-����',
		     '', '', 'O') if ($type =~ /��$/);
    $case = Mor::new('Mor', '��', '��', '��', '����-�ʽ���-����',
		     '', '', 'O') if ($type =~ /��$/);
    push @cp_mor, $case;

    $copy->Mor(\@cp_mor);
    if ($ana->AUX or $ana->voice eq 'passive') {
	
    } else {
	$copy->EQ_TYPE('��', $ana->PRED_ID) if ($type =~ /��$/);
	$copy->EQ_TYPE('��', $ana->PRED_ID) if ($type =~ /��$/);
	$copy->EQ_TYPE('��', $ana->PRED_ID) if ($type =~ /��$/);	
    }
    $copy->WF($self->WF);
    $copy->dtr([]);

    $self->CONJ_TYPE('');
    $self->CONJ('');
    $copy->EQ($self->EQ);
    $copy->NOUN($self->NOUN);
    $copy->PRED($self->PRED);
    $copy->CASE($case->WF);
    $copy->CASE_H($case->WF);
    $copy->CASE_ORG($case->WF);    
    $copy->STRING($self->WF.$case->WF);
    $copy->DEFINITE($self->DEFINITE);
    $copy->PRE_DEFINITE($self->PRE_DEFINITE);
    $copy->EDR_PERSON($self->EDR_PERSON);
    $copy->EDR_ORG($self->EDR_ORG);
    $copy->ANIMACY($self->ANIMACY);
    $copy->PRONOUN_TYPE($self->PRONOUN_TYPE);
    $copy->SENT_INDEX($ana->SENT_INDEX);
    $copy->HEAD_POS($self->HEAD_POS);
    ($copy->HEAD_POS =~ /^̾��(?!-��Ω)/)?
	$copy->I_NOUN(1) : $copy->I_NOUN(0);
    $copy->HEAD_NE($self->HEAD_NE);
    $copy->HEAD_WF($self->HEAD_WF);
    $copy->HEAD_BF($self->HEAD_BF);            
    $copy->HEAD_NOUN($self->HEAD_NOUN);
#      $copy->AGT(1) if ($type eq 'GA');
    $copy->ZERO_GA(1) if ($type =~ /��$/);
    $copy->ZERO_WO(1) if ($type =~ /��$/);
    $copy->ZERO_NI(1) if ($type =~ /��$/);    
    # OBJ, IOB���������
    my $main_head = ($ana->MAIN_HEAD eq 'MAIN_HEAD')? $ana->id : $ana->MAIN_HEAD;
    $copy->MAIN_HEAD($main_head);
    $copy->SENT_BEGIN($ana->SENT_BEGIN);
    $copy->IN_QUOTE(1) if ($ana->IN_QUOTE);
    $copy->QUOTE($ana->QUOTE) if ($ana->QUOTE);    
    $copy->SPEAKER($self->SPEAKER) if ($self->SPEAKER);
#      $copy->is_exophora(0);
    # sent_begin, main_head, embedded
    return $copy;
}

# copy constructor
sub copy2 {
    my $self = shift;
    my $copy = Bunsetsu->new($self->id, $self->dep, 'D', $self->head,
			     $self->func, $self->weight, $self->dtr);
    my @mor = @{$self->Mor}; my $m_num = @mor;
    my @cp_mor;
    for (my $i=0;$i<$m_num;$i++) {
	push @cp_mor, $mor[$i]->copy;
    }

    $copy->Mor(\@cp_mor);
    $copy->WF($self->WF);
    $self->CONJ_TYPE('');
    $self->CONJ('');
    $copy->EQ($self->EQ);
    $copy->NOUN($self->NOUN);
    $copy->PRED($self->PRED);
    $copy->CASE($self->CASE);
    $copy->CASE_H($self->CASE_H);
    $copy->CASE_ORG($self->CASE_ORG);        
    $copy->STRING($self->STRING);
    $copy->DEFINITE($self->DEFINITE);
    $copy->PRE_DEFINITE($self->PRE_DEFINITE);
    $copy->EDR_PERSON($self->EDR_PERSON);
    $copy->EDR_ORG($self->EDR_ORG);
    $copy->ANIMACY($self->ANIMACY);
    $copy->PRONOUN_TYPE($self->PRONOUN_TYPE);
    $copy->HEAD_POS($self->HEAD_POS);
    ($copy->HEAD_POS =~ /^̾��(?!-��Ω)/)?
	$copy->I_NOUN(1) : $copy->I_NOUN(0);
    $copy->HEAD_NE($self->HEAD_NE);
    $copy->HEAD_WF($self->HEAD_WF);
    $copy->HEAD_BF($self->HEAD_BF);            
    $copy->HEAD_NOUN($self->HEAD_NOUN);
    return $copy;
}

sub puts_xml_begin {
    my $self = shift;
    my @b = ();
    push @b, 'id="'.      $self->id.      '"';
    push @b, 'dep="'.     $self->dep.     '"';
    push @b, 'dep_type="'.$self->dep_type.'"';
    push @b, 'head="'.$self->tmp_head.'"';
    push @b, 'func="'.$self->func.'"';
    return '<b '.join(' ', @b).'>';
}

sub puts_xml_end {
    my $self = shift;
    return '</b>';
}

sub puts_mod {
    my $self = shift;
    my @m = @{$self->Mor};
    my $out = '';
    $out .= '* '.$self->id.' '.$self->dep.$self->dep_type.' '.
	    $self->head.'/'.$self->func.' '.$self->weight."\n";
    $out .= '! ID:'.$self->ID."\n" if ($self->ID);
    $out .= '! PRED_ID:'.$self->PRED_ID."\n" if ($self->PRED_ID);
    for ('GA', 'WO', 'NI') {
	$out .= '! '.$_.':'.$self->{$_}."\n" if ($self->{$_});
    }
    for (@m) {
	$out .= $_->puts;
    }
    return $out;
}

# ===================================================================
# 1ʸ�ξ�����ݻ����륯�饹
# ===================================================================
package Sentence;

sub new {
    my $type = shift; # Sent
    my $in = shift;;
#     my $self = {};
#     bless $self;
    my @cab = (); my @mor = (); my $bunsetsu;
    my @line = split '\n', $in;

    return '' unless (@line);

    my $self = {};
    bless $self;

    pop @line if ($line[-1] eq 'EOS'); # delete EOS
    my %dtr = (); # daughters
    for my $l (@line) {
	if ($l =~ m|^\* (\d+) (-?\d+)(\w) (\d+)/(\d+) ([\d\.]+)|) { # ʸ�����	    
	    my $id       = $1; # ʸ��ID
	    my $dep      = $2; # �������ʸ��ID
	    my $dep_type = $3; # D, P, I, A
	    my $head     = $4; # �缭�Ȥʤ����Ƹ�η�����ID
	    my $func     = $5; # ��ǽ��η�����ID
	    my $weight   = $6;
	    push @{$dtr{$2}}, $1;
	    my @dtr = (); 
	    for my $d (@{$dtr{$id}}) { push @dtr, $cab[$d]; }
	    $bunsetsu =	Bunsetsu->new($id, $dep, $dep_type,
				      $head, $func, $weight, \@dtr);
	    push @cab, $bunsetsu;
	} elsif ($l =~ m|^\! |) {
	    my @tag = split ' ', $l; shift @tag; # shift '! ' 
	    for my $t (@tag) {
		my ($tagname, $tagvalue) = split '\:', $t;
		if ($tagname eq 'pred') {
		    $bunsetsu->PRED($tagvalue);
		} elsif ($tagname eq 'id') {
		    $bunsetsu->ID($tagvalue);
		} elsif ($tagname eq 'eq') {
		    $bunsetsu->EQ($tagvalue);
# 		} elsif ($tagname eq 'ga' or $tagname eq 'zero_ga') {
		} elsif ($tagname eq 'ga') {
		    $bunsetsu->D_GA($tagvalue);		    
		} elsif ($tagname eq 'zero_ga') {
		    $bunsetsu->D_ZERO_GA($tagvalue);		    
# 		} elsif ($tagname eq 'wo' or $tagname eq 'zero_wo') {
		} elsif ($tagname eq 'wo') {
		    $bunsetsu->D_WO($tagvalue);		    
		} elsif ($tagname eq 'zero_wo') {
		    $bunsetsu->D_ZERO_WO($tagvalue);		    
# 		} elsif ($tagname eq 'ni' or $tagname eq 'zero_ni') {
		} elsif ($tagname eq 'ni') {
		    $bunsetsu->D_NI($tagvalue);		    
		} elsif ($tagname eq 'zero_ni') {
		    $bunsetsu->D_ZERO_NI($tagvalue);		    
		} elsif ($tagname eq 'soto') {
		    $bunsetsu->D_SOTO($tagvalue);		    
		} else {
		    print STDERR 'yet another !-marked strings: ', $l, "\n";
		}
	    }
	} else { # �����Ǿ���
	    my $mor = Mor->new($l);
	    push @{$bunsetsu->{mor}}, $mor;
	}
    }

    
    my $c_num = @cab;
    for (my $i=0;$i<$c_num;$i++) {
	my @mor  = @{$cab[$i]->{mor}};
	$cab[$i]->NOUN(&check_noun($cab[$i]));
	$cab[$i]->I_NOUN(&check_i_noun($cab[$i])); # ��Ω���̾��	

	# change_head������head_eq��õ��
	$cab[$i]->HEAD_EQ(&ext_head_eq($cab[$i]));
	$cab[$i]->HEAD_ANA(&ext_head_ana($cab[$i]));	
	
	# ̾���ȱ��Τ����shift_head
	$cab[$i]->SHIFT_HEAD(&shift_head($cab[$i]));

	# ̾��-��Ω�Τ����ư���ª���뤳�Ȥ��Ǥ��ʤ��Τǡ��ѹ�
#  	$cab[$i]->head(&change_head($cab[$i]));
  	$cab[$i] = (&change_head($cab[$i]));	


	$cab[$i]->AUX(&check_aux($cab[$i]));
	$cab[$i]->VOICE(&check_voice($cab[$i]));
	$cab[$i] = &ext_head_info($cab[$i]);
	$cab[$i]->LENGTH(&check_length($cab[$i]));
# 	$cab[$i]->CASE(&ext_case($cab[$i]));
# 	$cab[$i]->CASE_H(&ext_case_h($cab[$i]));
# 	$cab[$i]->CASE_ORG(&ext_case_org($cab[$i]));	
	$cab[$i]->STRING(&ext_str($cab[$i]));
	$cab[$i]->WF(&ext_wf($cab[$i]));
	$cab[$i]->SHIFT_WF(&ext_shift_wf($cab[$i]));	
	$cab[$i]->FUNC(&ext_func($cab[$i]));
	$cab[$i]->ZERO(&check_zero($cab[$i]));
	$cab[$i]->DEFINITE(&ext_definite($cab[$i]));
	$cab[$i]->PRE_DEFINITE(&ext_pre_definite($cab[$i], @cab));	
	$cab[$i]->EDR_PERSON(&EDR::check_edr_person($cab[$i]));
	$cab[$i]->EDR_ORG(&EDR::check_edr_org($cab[$i]));
	$cab[$i]->ANIMACY(&check_animacy($cab[$i]));
	$cab[$i]->PRONOUN_TYPE(&PRONOUN::check_pronoun_type($cab[$i]));
	$cab[$i]->descendant(&ext_descendant($i, @cab));
	$cab[$i]->DOU(&check_dou($cab[$i]));
#  	$cab[$i]->is_exophora(0);
    }

    for (my $i=$c_num-1;$i>=0;$i--) {
	# �����褬pred���ɤ����򸫤�Τǵդ����������
	$cab[$i]->PRED(&check_pred($cab[$i], @cab));
	$cab[$i]->DEP_CASE(&ext_dep_case($i, @cab));
    }

    # PRED����äƤ���Ǥʤ��ȷ����ʤ���
    for (my $i=0;$i<$c_num;$i++) {
	my @mor  = @{$cab[$i]->{mor}};
	$cab[$i]->CONJ_VAL(&ext_conj_val($cab[$i]));

    }

    # SENT_END
    $cab[-1]->SENT_END('SENT_END');
    @cab = &check_sent_begin(@cab);
    @cab = &ext_main_head(@cab);
#     @cab = &check_embedded(@cab);
    @cab = &check_in_quote(@cab);
    $self->Bunsetsu(\@cab);
    
    # 1ʸ��ʸ���󤹤٤�
    $self->STRING(&ext_str_all($self));
    &FUNC_EXP::add_func_exp($self);

    return $self;
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{id} = $_[0];
    } else {
	return $self->{id};
    }
}

sub ATTR {
    my $self = shift;
    if (@_) {
	$self->{ATTR} = $_[0];
    } else {
	return $self->{ATTR};
    }
}

sub TYPE {
    my $self = shift;
    if (@_) {
	$self->{TYPE} = $_[0];
    } else {
	return $self->{TYPE};
    }
}

sub Bunsetsu {
    my $self = shift;
    if (@_) {
	$self->{Bunsetsu} = $_[0];
    } else {
	return $self->{Bunsetsu};
    }
}

sub STRING {
    my $self = shift;
    if (@_) {
	$self->{STRING} = $_[0];
    } else {
	return $self->{STRING};
    }
}

sub LOOKED {
    my $self = shift;
    if (@_) {
	$self->{LOOKED} = $_[0];
    } else {
	return $self->{LOOKED};
    }
}

sub change_head {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor}; my $m_num = @mor;
    my $head = $bunsetsu->head;

    $bunsetsu->tmp_head($bunsetsu->head);
    # �ǽ��ư�켫Ω��缭��
    for (my $i=0;$i<$head;$i++) {
	if ($mor[$i]->POS eq 'ư��-��Ω') {
	    $bunsetsu->head($i);
	    return $bunsetsu;
	}
    }

    return $bunsetsu unless ($mor[$head]->POS ne '̾��-��Ω');

    for (my $i=0;$i<$head;$i++) {
	if ($mor[$i]->POS eq 'ư��-��Ω') {
	    $bunsetsu->head($i);
	    return $bunsetsu;
	}
    }
    return $bunsetsu;
}

sub shift_head {
    my $b = shift;
    my $head = $b->head;
    return $head if ($head == 0);
    my $wf = $b->Mor->[$head]->WF; my $pos = $b->Mor->[$head]->POS;
#     die 'error2' , "\n" unless ($wf);
#     print STDERR 'ref: ', ref($b), "\n";
#     use Data::Dumper;
#     print STDERR Dumper $b;
    unless ($wf) { print STDERR "error\n"; print STDERR $b->STRING, "\n" }
#     return $head-1 if ($wf =~ /^(?:����|��|¦)$/ and $pos =~ /^̾��-����/);
    return $head-1 if ($wf =~ /^(?:����|��)$/ and $pos =~ /^̾��-����/);    

    return $head;
}

sub check_noun {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->{mor}};
    my $head = $bunsetsu->head;
    my $mor = $mor[$head];
#    return ($mor->POS =~ /^̾��/)? 1 : 0;
    # �ʲ��Τ褦���ѹ�
    my $m_num = @mor;
    for (my $i=$m_num-1;$i>=$head;$i--) {
	return 1 if ($mor[$i]->POS =~ /^̾��/);
    }
    return 0;
}

sub check_i_noun {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->{mor}};
    my $head = $bunsetsu->head;
    my $mor = $mor[$head];
    return ($mor->POS =~ /^̾��(?!-��Ω)/)? 1 : 0;
}

sub check_pred {
    my $bunsetsu = shift;
    my @B = @_;
    my @mor = @{$bunsetsu->{mor}};
    my $head = $bunsetsu->head; my $dep = $bunsetsu->dep;
    my $m_num = @mor;
    my $m = $mor[$head];
    if ($m->POS =~ /^(ư��|���ƻ�)-��Ω/) {
	my $pos = $1;
	if ($pos eq 'ư��' and $head != 0 and $m->BF eq '����' and
	    $mor[$head-1]->POS eq '̾��-������³') {
	    return $mor[$head-1]->BF.'����';
	} elsif ($pos eq 'ư��' and $head != 0 and $m->BF eq '����' and
		 $mor[$head-1]->POS eq '̾��-����ư��촴' and
		 ($mor[$head-1]->BF eq '����' or
		  $mor[$head-1]->BF eq '�Լ�ͳ' or
		  $mor[$head-1]->BF eq '̵��' or
		  $mor[$head-1]->BF eq '����')) {
	    # �ְ��ꤹ��ס��Լ�ͳ����ס�̵������ס����Ǥ���פ��ɲ�
	    return $mor[$head-1]->BF.'����';
	}
 	return $mor[$head]->BF;
    } elsif ($m->POS =~ /^̾��-(?!��Ω)/) {
	return if ($head == $m_num-1);
	my $n = $mor[$head+1];
	return $m->BF. '��' if ($n->BF eq '��');
	return;
    } elsif ($m->POS eq '̾��-������³' or $m->POS eq '̾��-����-������³') {
	return $m->BF.'����' if ($dep eq '-1');
	return '' if ($head == $m_num-1);
	my $n = $mor[$head+1];
#  	return '' unless ($n->POS =~ /^(?:����-�����|����-�ʽ���-����|
#  				     ����-����|����-����)/x);    
	if ($n->POS =~ /^����-����/) {
	    return $m->BF.'����' if (&check_pred_sahen($bunsetsu, @B));
	}
    }
    return '';
}

sub check_pred_sahen {
    my $b = shift;
    return 1 if ($b->dep eq '-1');
    my @B = @_; my $dep = $b->dep;
    return 1 if ($B[$dep]->PRED);
    return 0;
}

sub ext_head_info {
    my $bunsetsu = shift;
    my $head  = $bunsetsu->head;
    my $shead = $bunsetsu->SHIFT_HEAD;
    my $tmp_head = $bunsetsu->tmp_head;    
    my @mor = @{$bunsetsu->Mor};

    # head
    $bunsetsu->HEAD_POS($mor[$head]->POS);
    $bunsetsu->HEAD_NOUN($mor[$head]->BF);
    $bunsetsu->HEAD_WF($mor[$head]->WF);
    $bunsetsu->HEAD_BF($mor[$head]->BF);
    if ($mor[$head]->NE) {
	my $ne = $mor[$head]->NE;
	$ne =~ s/^[BI]-//;
	$bunsetsu->HEAD_NE($ne);
    }

    # TMP_HEAD
    $bunsetsu->TMP_HEAD_POS($mor[$tmp_head]->POS);    
    
    # SHIFT_HEAD
    $bunsetsu->SHIFT_HEAD_POS($mor[$shead]->POS);
    $bunsetsu->SHIFT_HEAD_NOUN($mor[$shead]->BF);
    $bunsetsu->SHIFT_HEAD_WF($mor[$shead]->WF);
    $bunsetsu->SHIFT_HEAD_BF($mor[$shead]->BF);
    if ($mor[$shead]->NE) {
	my $ne = $mor[$shead]->NE;
	$ne =~ s/^[BI]-//;
	$bunsetsu->SHIFT_HEAD_NE($ne);
    }
    return $bunsetsu;
}

# sub ext_shift_head_info {
#     my $b = shift;
#     my $shead = $b->SHIFT_HEAD;
#     my @
# }

sub check_length {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $len = 0;
    for my $m (@mor) {
	$len += length $m->WF;
    }
    return $len;
}

sub check_length_all {
    my $self = shift;
    my @B = @{$self->Bunsetsu};
    my $len = 0;
    for (@B) {
	$len += $_->LENGTH;
    }
    return $len;
}

sub check_zero {
    my $bunsetsu = shift;
    return ($bunsetsu->GA or
	    $bunsetsu->WO or
	    $bunsetsu->NI)? 1 : 0;
}

sub ext_case {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $case = '';
#     for my $m (@mor) {
# 	if ($m->POS =~ /^����-�ʽ���-����/) {
# 	    $case .= $m->WF unless ($m->WF =~ /^(��|����|����|�ʤ�|�Τ�)$/);
# 	} elsif ($m->POS =~ /^����-�ʽ���-Ϣ��/) {
# 	    $case .= $rengo{$m->WF};
# 	} elsif ($m->POS =~ /^����(?!-��³����)/) {
# 	    unless ($m->WF =~ /^(��|����|����|�ʤ�|�Τ�)$/) {
# 		$case .= $m->WF;
# 	    }
# 	}
#     }
    if ($case) {
	return $case;
    } else {
	return '��';
    }
}

sub ext_case_h {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $case = '';
    my $m_num = @mor;
    my $num = 1;
    my $temp ='';
    for my $m (@mor) {
	$temp .= $m->WF;
	if ($m->POS =~ /^����-�ʽ���-Ϣ��/) {
	    if ($m->WF eq '�ˤȤä�'){
		$case .= $rengo{$m->WF};
	    }else{
		$case .= $m->WF;
	    }
	}else{
	    $case .= $m->WF if ($m->POS =~ /��ư��촴$/);
	    $case .= $m->WF if ($m->POS =~ /^����(?!-��³����)/ and $m->WF !~ /^(��|����|����|�Τ�|��)$/);
	    $case .= "�ʤ�" if ($m->POS =~ /^����(?!-��³����)/ and $m->WF =~ /^��$/ and $num == $m_num and $temp =~ /�ʤ�$/);
	}

	$num++;
    }

    if ($case =~ /^�ʤ�(.+)/){
	$case = $1 unless ($case eq '�ʤ�');
    }
    if ($case =~ /^��(.+)/){
	$case = $1 unless ($case eq '��');
    }
    if ($case =~ /^����(.+)/){
	$case = $1 unless ($case eq '����');
    }
    if ($case =~ /^�ޤ�(.+)/){
	$case = $1 unless ($case eq '�ޤ�');
    }
    if ($case =~ /(.+)�ޤ�$/){
	$case = $1 unless ($case eq '�ޤ�');
    }


    if ($case) {
	return $case;
    } else {
	return '��';
    }
}

sub ext_case_org {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $case = '';
    for my $m (@mor) {
	$case .= $m->WF if ($m->POS =~ /^����/);
    }
    return ($case)? $case : '��';
}

sub ext_str {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $str = '';
    for (@mor) {
	$str .= $_->WF;
    }
    return $str;
}

sub ext_str_all {
    my $self = shift;
    my @B = @{$self->Bunsetsu};
    my $str = '';
    for (@B) {
	$str .= $_->STRING;
    }
    return $str;
}

sub ext_wf {
    my $bunsetsu = shift;
    my $head = $bunsetsu->head;
    my @mor = @{$bunsetsu->Mor};
    my $wf = '';
    for (my $i=0;$i<=$head;$i++) {
	$wf .= $mor[$i]->WF;
    }
    return $wf;
}

sub ext_shift_wf {
    my $bunsetsu = shift;
    my $shead = $bunsetsu->SHIFT_HEAD;
    my @mor = @{$bunsetsu->Mor};
    my $wf = '';
    for (my $i=0;$i<=$shead;$i++) {
	$wf .= $mor[$i]->WF;
    }
    return $wf;
}

sub ext_func {
    my $bunsetsu = shift;
    my $head = $bunsetsu->head;
    my @mor = @{$bunsetsu->Mor};
    my $m_num = @mor;
    return '' if ($head == $m_num-1);
    my $str = '';
    for (my $i=$head+1;$i<$m_num;$i++) {
	$str .= $mor[$i]->WF;
    }
    return $str;
}

sub ext_definite {
    my $bunsetsu = shift;
    my @mor = @{$bunsetsu->Mor};
    my $m_num = @mor;
    for (my $i=0;$i<$m_num;$i++) {
	my $def = &ext_definite_sub($mor[$i]->BF);
	return $def if ($def);
    }
    return '';
}

sub ext_definite_sub {
    my $BF = shift;
    return '����' if ($BF =~ /^(����|����|�����|������|������|���ä�|
				����|�����|��������|��������|�������ä�|
				����|����ʤ�|����ʤդ���)$/x);
    
    return '����' if ($BF =~ /^(����|����|������|�����|������|���ä�|
				����|�����|��������|��������|�������ä�|
				����|����ʤ�|����ʤդ���)$/x);

    return '����' if ($BF =~ /^(����|������|�����|������|���ä�|����|
				�����|��������|��������|�������ä�|����|
				����ʤ�|����ʤդ���)$/x);
    '';
}

sub ext_pre_definite {
    my $bunsetsu = shift;
    my @B        = @_;
    my @dtr = @{$bunsetsu->dtr};
    for my $d (@dtr) {
#  	return 'PRE_DEF_'.$1 if ($B[$d]->HEAD_BF =~ /^(����|����|����)/);
	return 'PRE_DEF_'.$1 if ($d->HEAD_BF =~ /^(����|����|����)/);	
    }
    return '';
}

sub check_animacy {
    my $bunsetsu = shift;
    return unless ($bunsetsu->HEAD_NE);
    return ($bunsetsu->EDR_PERSON or $bunsetsu->EDR_ORG or
	    $bunsetsu->HEAD_NE =~ /(?:PERSON|ORGANIZATION)/)? 'ANIMACY' : '';
}

sub ext_conj_val {
    my $bunsetsu = shift;
    return '' unless ($bunsetsu->PRED);
    my $conj_val = 'Ϣ�����';
    my @mor = @{$bunsetsu->Mor}; my $m_num = @mor; 
    my $head = $bunsetsu->head;
    return $conj_val if ($head == $m_num-1);
    my $tmp = '';
    for (my $i=$head+1;$i<$m_num;$i++) {
	my $m = $mor[$i];
	if ($m->POS eq '����-��³����') {
	    $tmp .= $m->WF;
	}
    }
    if ($tmp) {
	return $tmp;
    } else {
	return $conj_val;
    }
}

sub ext_descendant {
    my $num = shift;
    my @cab = @_;
    my %des = ();
    my @dtr = @{$cab[$num]->dtr};
    return \%des unless (@dtr);
    &ext_descendant_sub(\%des, @dtr);
    return \%des;
}

sub ext_descendant_sub {
    my $desref = shift;
    my @dtr    = @_;
    return unless (@dtr);
    for my $d (@dtr) {
	$desref->{$d->id} = 1;
	next unless (@{$d->dtr});
	&ext_descendant_sub($desref, @{$d->dtr});
    }
}

sub ext_dep_case {
    my $num = shift;
    my @cab = @_;
    my $b = $cab[$num];
    return '' if ($b->dep eq '-1');
    my $dep = $cab[$b->dep];
    return $dep->CASE;
}
sub ext_main_head {
    my @cab = @_;
    my $c_num = @cab;
    my $m_head;
    for (my $i=$c_num-1;$i>=0;$i--) {
	my $b = $cab[$i];
	if ($b->PRED or $b->I_NOUN) {
	    $b->MAIN_HEAD('MAIN_HEAD');
	    $m_head = $b->id;
	    last;
	}
    }

    for (my $i=0;$i<$c_num;$i++) {
	my $b = $cab[$i];
	$b->MAIN_HEAD($m_head) if ($m_head);
    }
    
    return @cab;
}

sub check_embedded {
    my @cab = @_;
    my $c_num = @cab;
    my $depth = 0;
    my $b = $cab[-1];
    &check_embedded_sub($depth, $b, @cab);
    return @cab;
}

sub check_embedded_sub {
    my $depth = shift;
    my $b     = shift;
    my @cab   = @_;
    my @dtr   = @{$b->dtr};
    $b->EMBEDDED($depth);
    return unless (@dtr);

#      if (!$b->PRED_ID and $b->HEAD_POS =~ /^̾��/ and $b->MAIN_HEAD and $b->MAIN_HEAD ne 'MAIN_HEAD') { # ʸ����̾����̵��
#      if (!$b->PRED_ID and $b->NOUN and $b->MAIN_HEAD and $b->MAIN_HEAD ne 'MAIN_HEAD') { # ʸ����̾����̵��
    if ($b->NOUN and $b->PRED_ID and !$b->I_NOUN) {
	$b->EMBEDDED($depth+1);
    }
    if (!$b->PRED_ID and $b->NOUN) {
	$depth++;
    }
    for my $d (@dtr) {
	&check_embedded_sub($depth, $d, @cab);
    }
}

sub check_in_quote {
    my @cab = @_;
    my $quote_flg = 0;
    for my $b (@cab) {
	my @mor = @{$b->Mor}; my $m_num = @mor;
	my $head = $b->head; my $head_flg = 0;
#  	my $pre = $quote_flg;
	my $end_flg = 0;
	for (my $i=0;$i<$m_num;$i++) {
	    $head_flg = $quote_flg if ($i == $head);
	    $quote_flg = 1 if ($mor[$i]->BF eq '��');
	    if ($mor[$i]->BF eq '��') {
		$quote_flg = 0;
		$end_flg = 1;
	    }
	}
	$b->IN_QUOTE($head_flg);

	$b->QUOTE_TYPE('I') if ($head_flg); # intermediate
	$b->QUOTE_TYPE('E') if (!$head_flg and $end_flg); # end
	$b->QUOTE_TYPE('O') if (!$b->QUOTE_TYPE); # other

#  	# ��̤˸�ͭ̾���񤤤Ƥ����硤�����̾���Ȥ���
#  	$b->NOUN if ($b->NE ne 'O' and $pre == 1 and $quote_flg == 0);

    }
    return @cab;
}

sub check_voice {
    my $b = shift;
    my $head = $b->head;
    my @mor = @{$b->Mor}; my $m_num = @mor;
    return 'active' if ($head == $m_num-1);
    my $rare_flg  = 0;
    for (my $i=$head;$i<$m_num;$i++) {
	my $m = $mor[$i];
	if ($rare_flg) { # (?:��|���)�ʤ�
	    return 'active' if ($m->BF eq '�ʤ�');
	    return 'passive';
	} elsif ($m->BF =~ /^(?:���|����)$/) {
	    $rare_flg = 1;
	}
    }
    return ($rare_flg)? 'passive' : 'active';
}

sub check_sent_begin {
    my @cab = @_;
    for my $b (@cab) {
	if ($b->NOUN) {
	    $b->SENT_BEGIN('SENT_BEGIN'); last;
	}
    }
    return @cab;
}

sub check_aux {
    my $b    = shift;
##  ��롤����
# ���Ȥˤϥ������դ��Ƥ���Τǡ�����ʳ���check
#  ���롤������   
#  �ۤ���   
#  ��餦����������   
#  ����롤�����롤��������   
#  ��롤������
    my $head = $b->head;
    my @mor  = @{$b->Mor}; my $m_num = @mor;
    return 0 if ($m_num-1 == $head);
    for (my $i=$head+1;$i<$m_num;$i++) {
	my $m = $mor[$i];
	if ($m->BF =~ /^(?:����|������|�ۤ���|��餦|��������|
			 �����|������|��������|���|������)$/x) {
	    return 1;
	}
    }
    return 0;

}

sub ext_head_eq {
    my $b = shift;
    my $head = $b->head; # == $b->tmp_head
    my @m = @{$b->Mor};
    return $m[$head]->EQ;
}

sub ext_head_ana {
    my $b = shift;
    my $head = $b->head; # == $b->tmp_head
    my @m = @{$b->Mor};
    return $m[$head]->ANAPHOR;
}

sub check_dou {
    my $b = shift;
    my @m = @{$b->Mor}; my $m_num = @m;
    for (my $mid=0;$mid<$m_num;$mid++) {
	my $w = $m[$mid]->WF; my $p = $m[$mid]->POS;
	return 'ƱOPTIONAL' if ($w eq 'Ʊ' and $p eq '��Ƭ��-̾����³');
	return 'ƱLOCATION' if ($w =~ /^(ƱĮ|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ¼|Ʊ��|
					 Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|
					 Ʊ��|ƱŹ|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|
					 Ʊ��|Ʊģ|ƱŸ|Ʊ��|Ʊ��)$/x);
	return 'ƱPERSON:1' if ($w =~ /^(Ʊ̾|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��)$/x);
	return 'ƱARTIFACT:1' if ($w =~ /^(Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��|Ʊ��)$/x);
	return 'ƱTIME:1' if ($w =~ /^(Ʊ��|Ʊ��|Ʊ��|Ʊͼ)$/x);
	return 'ƱDATE:1' if ($w =~ /^Ʊǯ$/x);   
	return 'ƱMONEY:1' if ($w =~ /^Ʊ��$/x);  
    }
    return '';
}

sub puts {
    my $self = shift;
    my $out = '';
    $out .= '# S-ID:'. $self->id. "\n";
    my @B = @{$self->Bunsetsu};
    for my $b (@B) {
	$out .= $b->puts;
    }
    $out .= "EOS\n";
    return $out;
}

sub puts2 {
    my $self = shift;
    my $out = '';
    $out .= '# S-ID:'. $self->id. "\n";
    my @B = @{$self->Bunsetsu};
    for my $b (@B) {
	$out .= $b->puts2;
    }
    $out .= "EOS\n";
    return $out;
}

sub puts_e {
    my $self = shift;
    my $out = '';
#     $out .= '# S-ID:'. $self->id. "\n";
    my @B = @{$self->Bunsetsu};
    for my $b (@B) {
	$out .= $b->puts_e;
    }
    $out .= "EOS\n";
    return $out;
}

sub puts_xml_begin {
    my $self = shift;
    return '<s id="'.$self->id.'">';
}

sub puts_xml_end {
    my $self = shift;
    return '</s>';
}

sub puts_mod {
    my $self = shift;
    my @b = @{$self->Bunsetsu};
    my $out = '';
    for (@b) {
	$out .= $_->puts_mod;
    }
    $out .= "EOS\n";
    return $out;
}

# ===================================================================
# 1ʸ�Ϥξ�����ݻ����륯�饹
# ===================================================================
package Txt;

sub new {
    my $type = shift;
    my $self = {};
    bless $self;
    return $self;
}

# text filename
sub id {
    my $self = shift;
    if (@_) {
	$self->{id} = $_[0];
    } else {
	return $self->{id};
    }
}

# general or editorial
sub TYPE {
    my $self = shift;
    if (@_) {
	$self->{TYPE} = $_[0];
    } else {
	return $self->{TYPE};
    }
}

# general or editorial
sub Sentence {
    my $self = shift;
    if (@_) {
	$self->{SENT} = $_[0];
    } else {
	return $self->{SENT};
    }
}

# directory
sub DIR {
    my $self = shift;
    if (@_) {
	$self->{DIR} = $_[0];
    } else {
	return $self->{DIR};
    }
}

sub PATH {
    my $self = shift;
    if (@_) {
	$self->{PATH} = $_[0];
    } else {
	return $self->{PATH};
    }
}

sub puts_mod {
    my $self = shift;
    my @s = @{$self->Sentence};
    my $out = '';
    for (@s) {
	$out .= $_->puts_mod;
    }
    return $out;
}

sub puts_e {
    my $self = shift;
    my @s = @{$self->Sentence};
    my $out = '';
    for (@s) {
	$out .= $_->puts_e;
    }
    return $out;
}

1;