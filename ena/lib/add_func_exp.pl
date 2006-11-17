#!/usr/local/bin/perl -w
# ===================================================================
my $NAME         = 'add_func_exp.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = 'Cab.pmの中で機能語相当語になる文字列に情報を付与';
# ===================================================================

use strict;

package FUNC_EXP;

my $ZERO_DAT_PATH = $ENV{ZERO_DAT_PATH};
my $ascii         = '[\x00-\x7F]';
my $twoBytes      = '[\x8E\xA1-\xFE][\xA1-\xFE]';
my $threeBytes    = '\x8F[\xA1-\xFE][\xA1-\xFE]';

# global variable
my $STRUCTREF = &init_func_exp;

use File::Basename qw(dirname);

sub init_func_exp {
    my $file = dirname(__FILE__)."/func_exp.tsv";
    my @array = ();
    my %struct   = ();
    open 'FE', $file or die "$file:$!";
    while (<FE>) {
	chomp; 	my $in = $_;
	next if ($in =~ /^\#/); $in =~ s/\#.*//;
	next unless ($in =~ /^[hA]/);
	my ($id, $exp, $tmp) = split '\t', $in;
	&make_struct(\%struct, $exp);
    }
    close FE;

    return \%struct;
}

sub make_struct {
    my $structref = shift;
    my $exp       = shift;
    while ($exp =~ /^($twoBytes|$threeBytes)/) {
	my $w = $1; $exp = $';
	$structref = \%{$structref->{$w}};
    }
    $structref->{'end'} = -1;    
}
    
sub add_func_exp {
    my $s = shift;
    my @B = @{$s->Bunsetsu}; my $B_num = @B;
    my $arrayref = &make_match_array($s->STRING);
    my $w_num = -1;    
    for (my $i=0;$i<$B_num;$i++) {
	my $b = $B[$i]; my @mor = @{$b->Mor}; my $m_num = @mor;
	for (my $j=0;$j<$m_num;$j++) {
	    my $w_pre = $w_num;
	    $w_num += length($mor[$j]->WF) / 2;
#  	    $mor[$j]->FUNC_EXP(1) if ($arrayref->[$w_pre+1] and $arrayref->[$w_num]);
	    $mor[$j]->FUNC_EXP(1) if ($arrayref->[$w_num]);
	}
	my $head = $b->head;
	if ($mor[$head]->FUNC_EXP) {
	    $b->HEAD_FUNC_EXP(1);
	    $b->PRED('');
	}
    }
}

sub make_match_array {
    my $str = shift;
    my @refs = (); my @array = ();
    my $w_num = 0;
    while ($str =~ /^($twoBytes|$threeBytes)/) {
	my $w = $1; $str = $';
	$array[$w_num] = 0;
	my $r_num = @refs;
	for (my $i=0;$i<$r_num;$i++) {
	    if ($refs[$i]->{$w}) {
		my $pre = $refs[$i];
		$refs[$i] = \%{$refs[$i]->{$w}};
		$refs[$i]->{'begin'} = $pre->{'begin'};
		if (defined $refs[$i]->{'end'}) {
		    $refs[$i]->{'end'} = undef;
#  		    $array[$_] = 1 for ($refs[$i]->{'begin'}..$w_num);
		    for (my $j=$refs[$i]->{'begin'};$j<=$w_num+1;$j++) {
			$array[$j] = 1;
		    }
		}
	    } else { # @refsの要素がmatchしない場合
		splice @refs, $i, 1;
		$r_num = @refs;
		$i--;
	    }
	}
	if ($STRUCTREF->{$w}) {
	    my $REF = &cp_ref($STRUCTREF->{$w});
	    $REF->{'begin'} = $w_num;
	    push @refs, $REF;
	}
	$w_num++;
    }
    return \@array;
}

sub cp_ref {
    my $ref = shift;
    my $cp;
    return $ref if (ref($ref) ne 'HASH');
    for my $key (keys %{$ref}) {
	$cp->{$key} = &cp_ref($ref->{$key});
    }
    return $cp;
}

# test
if ($0 eq __FILE__) {
#      my $structref = &init_func_exp;
#      use Data::Dumper;
#      print Dumper $structref;
    my $file = $ZERO_DAT_PATH.'/func_expressional/func_exp.tsv';
    open 'FL', $file or die $!;
    while (<FL>) {
	chomp; 	my $in = $_;
	next if ($in =~ /^\#/); $in =~ s/\#.*//;
	next unless ($in =~ /^h/);
	my ($id, $exp, $tmp) = split '\t', $in;
	print $exp, "\n";
    }
    close FL;
    
}

1;
