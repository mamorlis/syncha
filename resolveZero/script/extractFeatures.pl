#!/usr/bin/env perl

use strict;
use warnings;

# my $ZERO_PATH = $ENV{ZERO_PATH};
# unshift @INC, $ZERO_PATH.'/ver0/';

# my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
my $scriptPath = __FILE__; $scriptPath =~ s|//|/|g;
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
my $miscPath = $scriptPath.'misc/';
# print STDERR $miscPath, "\n";
unshift @INC, $miscPath;
# my $path = __FILE__; $path =~ s|[^/]+$||; unshift @INC, $path;
require 'check_ntt.pl';
# require 'check_log_like.pl';
#require 'calc_mi.pl';
use NCVTool;
my $ncvtool = new NCVTool;

# my $path = __FILE__; $path =~ s|[^/]+$||;

# -----------------------------------------------------------
# svm (inter)
# -----------------------------------------------------------

sub ext_features_svm_inter_t {
    my ($pred, $r, $l, $cl, $t, $case, $optref) = @_; # $case: GA, WO, NI

#     $optref->{b} = 1; ### ext

    # left 
    my $l_label = 'L_';
#     my $fe_l_p  = &ext_ana_t_inter($pred, $l_label.'P_'); # pred only
    my $fe_l_p  = &ext_ana_t($pred, $l_label.'P_'); # pred only
#     my $fe_l_c  = &ext_cand_t_inter($l, $l_label.'A_CAND_', $cl); # cand only
    my $fe_l_c  = &ext_cand_t($l, $l_label.'A_CAND_', $cl); # cand only
    my $fe_l_pc = &ext_ana_cand_t($pred, $l, $l_label.'A_AC_', $case); # pred-cand
    my $l_clabel = $l_label.'A';
#     my $l_cinfo = '('.$l_clabel.&ext_b_info_sub($l_clabel, $l).')'; 
    my $l_cinfo = &ext_b_info_sub_svm($l_clabel, $l);
    my $l_plabel = $l_label.'P';
    my $l_pinfo = &ext_b_info_sub_svm($l_plabel, $pred);
    my $l_fe = $l_cinfo.' '.$l_pinfo.' '.$fe_l_p.' '.$fe_l_c.' '.$fe_l_pc;

    # right
    my $r_label = 'R_';
    my $fe_r_p  = &ext_ana_t($pred, $r_label.'P_'); # pred only
    my $fe_r_c  = &ext_cand_t($r, $r_label.'A_CAND_', $cl); # cand only
    my $fe_r_pc = &ext_ana_cand_t($pred, $r, $r_label.'A_AC_', $case); # pred-cand
    my $r_clabel = $r_label.'A';
    my $r_cinfo = &ext_b_info_sub_svm($r_clabel, $r);
    my $r_plabel = $r_label.'P';
    my $r_pinfo = &ext_b_info_sub_svm($r_plabel, $pred);
    my $r_fe = $r_cinfo.' '.$r_pinfo.' '.$fe_r_p.' '.$fe_r_c.' '.$fe_r_pc;

    return $l_fe.' '.$r_fe;
}

sub ext_features_svm_inter {
    my ($pred, $c, $cl, $t, $case, $optref) = @_; # $case: GA, WO, NI
    my $fe_p = &ext_ana_t_inter($pred, 'P_'); # pred only
    my $fe_c = &ext_cand_t_inter($c, 'C_', $cl); # cand only
    my $fe_pc = &ext_ana_cand_t($pred, $c, 'PC_', $case); # pred-cand
    my $cinfo = &ext_b_info_sub_svm('ANT', $c);
    my $pinfo = &ext_b_info_sub_svm('PRED', $pred);
    my $fe = $cinfo.' '.$pinfo.' '.$fe_p.' '.$fe_c.' '.$fe_pc;
    return $fe;
}

# -----------------------------------------------------------
# svml
# -----------------------------------------------------------
sub ext_features_svml {
    my ($pred, $r, $l, $cl, $s, $case, $optref) = @_; # $case: GA, WO, NI
    my @fe = ();
    push @fe, &ext_one_pair_svml($pred, $r, $cl, $s, $case, 'R_', $optref);
    push @fe, &ext_one_pair_svml($pred, $l, $cl, $s, $case, 'L_', $optref);

    my @FE = ();
    for my $label ('R_', 'L_') {
	my $cand = ($label eq 'R_')? $r : $l;
	push @FE, &ext_ana_t($pred, $label.'P_'); # pred only
	push @FE, &ext_cand_t($cand, $label.'A_CAND_', $cl); # cand only
	push @FE, &ext_ana_cand_t($pred, $cand, $label.'A_AC_', $case); # pred-cand
    }
    
#     return '(~ROOT'.join('', @fe).')'."\t".'|STD|'."\t".join ' ', @FE;
    return '(~ROOT '.join('', @fe).') |STD| '.join ' ', @FE;
}

sub ext_features_one_svml {
    my ($pred, $cand, $cl, $s, $case, $optref) = @_;
    my @fe = ();
    push @fe, &ext_one_pair_svml($pred, $cand, $cl, $s, $case, 'R_', $optref);
    my @FE = (); my $label = 'AC_';
    push @FE, &ext_ana_t($pred, $label.'P_'); # pred only
    push @FE, &ext_cand_t($cand, $label.'A_CAND_', $cl); # cand only
    push @FE, &ext_ana_cand_t($pred, $cand, $label.'A_AC_', $case); # pred-cand
    return '(~ROOT '.join('', @fe).') |STD| '.join ' ', @FE;    
}

# -----------------------------------------------------------
# bact (comp)
# -----------------------------------------------------------

sub ext_features_comp {
    my ($pred, $r, $l, $cl, $s, $case, $optref) = @_; # $case: GA, WO, NI
    my @fe = ();

    if ($optref->{S}) {
# 	$out = &ext_one_str_new2($pred, $cand, $cl, $s, $case, $label, $optref);
	push @fe, &ext_one_new_str($pred, $l, $r, $cl, $s, $case, $optref);
    } else {
	push @fe, &ext_one_pair_bact($pred, $r, $cl, $s, $case, 'R_', $optref);
	push @fe, &ext_one_pair_bact($pred, $l, $cl, $s, $case, 'L_', $optref);
	# R_L pair で素性を抽出する．
    }

#     my $LABEL = &ext_label($b, $pred, $cand, $label);

#     push @fe, &ext_two_cands_bact($r, $l, $cl, $s, $case, 'LR_');
    return '(~ROOT'.join('', @fe).')';
}

sub ext_features_one {
    my ($pred, $c, $cl, $s, $case, $optref) = @_; # $case: GA, WO, NI
    my @fe = ();
    push @fe, &ext_one_pair_bact($pred, $c, $cl, $s, $case, 'C_', $optref);

    return '(~ROOT'.join('', @fe).')';
}

sub ext_one_pair_bact {
    my ($pred, $cand, $cl, $s, $case, $label, $optref) = @_;

#     my $out = '';
#     if ($optref->{s}) {
# 	$out = &ext_one_str_new($pred, $cand, $cl, $s, $case, $label, $optref);
#     } else {
#     }

    my $fe_p  = &ext_ana_t_bact($pred, $label.'P_'); # pred only
    my $fe_c  = &ext_cand_t_bact($cand, $label.'A_CAND_', $cl); # cand only
    my $fe_pc = &ext_ana_cand_t_bact($pred, $cand, $label.'A_AC_', $case); # pred-cand

#     return $out;
    if ($optref->{b}) { # baseline
	my $clabel = $label.'A';
	my $cinfo = '('.$clabel.&ext_b_info_sub($clabel, $cand).')'; 
	my $plabel = $label.'P';
	my $pinfo = '('.$plabel.&ext_b_info_sub($plabel, $pred).')'; 
	return $cinfo.$pinfo.$fe_p.$fe_c.$fe_pc;
    } else { 
	&mark_path($pred, $cand, $s);
	my @b = @{$s->Bunsetsu}; my $b_num = @b;
	my $out = '';
	for (my $bid=$b_num-1;$bid>=0;$bid--) {
	    my $b = $b[$bid];
	    next unless ($b->PATH);
	    if ($optref->{p}) {
		$out = &ext_one_pair_bact_dep($b, $pred, $cand,
					      $cl, $s, $case, $label, $optref);
	    } else {
		$out = &ext_one_pair_bact_sub($b, $pred, $cand, 
					      $cl, $s, $case, $label, $optref);
	    }
	    last;
	}
	return $out.$fe_p.$fe_c.$fe_pc;
    }
}

sub ext_one_pair_svml {
    my ($pred, $cand, $cl, $s, $case, $label, $optref) = @_;
    &mark_path($pred, $cand, $s);


    my @b = @{$s->Bunsetsu}; my $b_num = @b; my $out = '';
    for (my $bid=$b_num-1;$bid>=0;$bid--) {
	my $b = $b[$bid];
	next unless ($b->PATH);
	$out = &ext_one_pair_svml_sub($b, $pred, $cand, 
				      $cl, $s, $case, $label, $optref);
	last;
    }
    return $out;
}

sub ext_one_pair_svml_sub {
    my $b = shift; my ($pred, $cand, $cl, $s, $case, $label, $optref) = @_;
    my $out = ''; my @dtr = @{$b->dtr};

    # here the information from $b is extracted
    my $fe = &ext_one_bunsetsu_info_svml($b, $pred, $cand, $cl, $s, $case, $label);

    return '('.$fe.')' unless (@dtr);
    
    my $d_num = @dtr; my @dinfo = ();
    for (my $did=$d_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_svml_sub($dtr[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dtr[$did]->PATH);
    }

    # dtr_zero
    my @dz = @{$b->dtr_zero}; my $dz_num = @dz;
    for (my $did=$dz_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_svml_sub($dz[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dz[$did]->PATH);
    }

    return '('.$fe.join('', @dinfo).')';
}

sub ext_one_pair_bact_sub {
    my $b = shift; my ($pred, $cand, $cl, $s, $case, $label, $optref) = @_;
    my $out = '';
    my @dtr = @{$b->dtr}; 

    # here the information from $b is extracted
    my $fe = &ext_one_bunsetsu_info($b, $pred, $cand, $cl, $s, $case, $label);

    return '('.$fe.')' unless (@dtr);
    
    my $d_num = @dtr; my @dinfo = ();
    for (my $did=$d_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_bact_sub($dtr[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dtr[$did]->PATH);
    }

    # dtr_zero
    my @dz = @{$b->dtr_zero}; my $dz_num = @dz;
    for (my $did=$dz_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_bact_sub($dz[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dz[$did]->PATH);
    }

    return '('.$fe.join('', @dinfo).')';
}

# 係り関係のパスをそのまま利用する
sub ext_one_pair_bact_dep {
    my ($b, $pred, $cand, $cl, $s, $case, $label, $optref) = @_;
    my $out = '';
    my @dtr = @{$b->dtr};
    
    my $fe = &ext_dep_info_in_a_mor($b, $pred, $cand, $cl, $s, $case, $label);
    return '('.$fe.')' unless (@dtr);
    
    my $d_num = @dtr; my @dinfo = ();
    for (my $did=$d_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_bact_dep($dtr[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dtr[$did]->PATH);
    }
    # dtr_zero
    my @dz = @{$b->dtr_zero}; my $dz_num = @dz;
    for (my $did=$dz_num-1;$did>=0;$did--) {
	push @dinfo, &ext_one_pair_bact_dep($dz[$did], $pred, $cand, $cl, $s, $case, $label, $optref)
	    if ($dz[$did]->PATH);
    }
    return '('.$fe.join('', @dinfo).')';
}

sub ext_dep_info_in_a_mor {
    my ($b, $pred, $cand, $cl, $s, $case, $label) = @_;
    my $LABEL = &ext_label2($b, $pred, $cand, $label);
    $LABEL .= '_LEFT'  if ($b->left_b);
    $LABEL .= '_RIGHT' if ($b->right_b);
    $b->left_b(0); $b->right_b(0);

    my @m = @{$b->Mor}; my $m_num = @m;
    
    my $cnt = ($b->sid eq $cand->sid and $b->bid eq $cand->bid)? $LABEL : $LABEL.'_'.$b->HEAD_ORG_BF;
    $cnt .= '(ZERO)' if ($b->sid eq $pred->sid and $b->bid eq $pred->bid);
    unless ($m_num-1 == $b->HEAD_ORG) {
	for (my $i=$m_num-1;$i>$b->HEAD_ORG;$i--) {
	    $cnt = $m[$i]->BF.'('.$cnt.')';
	}
    }
    return $cnt;
}

sub ext_two_cands_bact {
    my ($r, $l, $cl, $s, $case, $label) = @_;
    return '';
}

sub ext_one_bunsetsu_info {
    my ($b, $pred, $cand, $cl, $s, $case, $label) = @_;
    my $LABEL = &ext_label($b, $pred, $cand, $label);

    $LABEL .= '_LEFT'  if ($b->left_b);
    $LABEL .= '_RIGHT' if ($b->right_b);

    if ($b->left_b and $b->right_b) {
	print STDERR $b->STRING, "\n";
	print STDERR $pred->STRING, "\n";
	print STDERR $cand->STRING, "\n";
	print STDERR $s->STRING, "\n\n\n";
    }

    my $binfo = &ext_b_info_sub($LABEL, $b); my $out = '';

    $out = $LABEL.$binfo;

    $b->left_b(0); $b->right_b(0);
    # ↓述語，候補の箇所に素性を埋め込む場合は以下の記述を使う．
#     if ($b->sid eq $pred->sid and $b->bid eq $pred->bid) { # PRED
#  	my $fe = &ext_ana_t_bact($pred, $LABEL.'_');
# 	$out = $LABEL.$fe.$binfo;
#     } elsif ($b->sid eq $cand->sid and $b->bid eq $cand->bid) { # ANT
# 	my $fe = &ext_cand_t_bact($b, $LABEL.'_CAND_', $cl);
# 	my $fe2 = &ext_ana_cand_t_bact($pred, $b, $LABEL.'_AC_', $case);
# 	$out = $LABEL.$fe.$fe2.$binfo;
#     }  else { # B
# 	$out = $LABEL.$binfo;
#     }

    return $out;
}

sub ext_one_bunsetsu_info_svml {
    my ($b, $pred, $cand, $cl, $s, $case, $label) = @_;
    my $LABEL = &ext_label($b, $pred, $cand, $label);
    $LABEL .= '_LEFT'  if ($b->left_b);
    $LABEL .= '_RIGHT' if ($b->right_b);
    if ($b->left_b and $b->right_b) {
	print STDERR $b->STRING, "\n";
	print STDERR $pred->STRING, "\n";
	print STDERR $cand->STRING, "\n";
	print STDERR $s->STRING, "\n\n\n";
    }
    my $binfo = &ext_b_info_sub_svml($LABEL, $b); my $out = '';
    $out = $LABEL.' '.$binfo;
    $b->left_b(0); $b->right_b(0);
    return $out;    
}

# P(redicate) / A(ntecedent candidate) / B(unsetsu) を区別する．
sub ext_label {
    my ($b, $pred, $cand, $label) = @_;
    my $LABEL = $label;
    if ($b->sid eq $pred->sid and $b->bid eq $pred->bid) {
	$LABEL .= 'P';
    } elsif ($b->sid eq $cand->sid and $b->bid eq $cand->bid) {
	$LABEL .= 'A'; # candidate antecedent
    } else {
	$LABEL .= 'B';
# 	$LABEL .= '_LEFT'  if ($b->left_b);
# 	$LABEL .= '_RIGHT' if ($b->right_b);
    }
    
    return $LABEL;
}

# A(ntecedent candidate) / B(unsetsu) を区別する．
sub ext_label2 {
    my ($b, $pred, $cand, $label) = @_;
    my $LABEL = $label;
    if ($b->sid eq $cand->sid and $b->bid eq $cand->bid) {
	$LABEL .= 'A';
    } else {
	$LABEL .= 'B';
    }
    return $LABEL;
}















# ------

sub ext_features_t {
#     my ($pred, $left, $right, $case, $cl, $logref) = @_;
#     my ($pred, $left, $right, $case, $cl) = @_;
    my ($pred, $right, $left, $case, $cl) = @_;
    
    my @fe = ();
    push @fe, &ext_ana_t($pred, 'ANA_');

    push @fe, &ext_cand_t($left, 'L_', $cl);
    push @fe, &ext_cand_t($right, 'R_', $cl);
    
    push @fe, &ext_ana_cand_t($pred, $left, 'AL_', $case);
    push @fe, &ext_ana_cand_t($pred, $right, 'AR_', $case);

    push @fe, &ext_two_cands_t($left, $right, 'LR_', $cl);

    return join ' ', @fe;

}

sub ext_features_t2 {
    my ($pred, $cand, $case, $cl) = @_;
    my @fe = ();
    push @fe, &ext_ana_t($pred, 'ANA_');
    push @fe, &ext_cand_t($cand, 'CAND_', $cl);
    push @fe, &ext_ana_cand_t($pred, $cand, 'AC_', $case);
    return join ' ', @fe;
}

sub ext_ana_t_bact {
    my $pred = shift; my $label = shift;
    my $fe = &ext_ana_t($pred, $label);
    my @tmp = ();
    for (split ' ', $fe) {
	push @tmp, '('.(split '\:', $_)[0].')';
    }
    return join '', @tmp;
}

sub ext_ana_t { 
    my $pred = shift; my $label = shift;

    my @fe = ();

    # 表層文字列(基本形)
    push @fe, 'PRED_'.$pred->PRED if ($pred->PRED);

     # 主節に存在
    push @fe, $pred->MAIN_HEAD if ($pred->MAIN_HEAD and
                                  $pred->MAIN_HEAD eq 'MAIN_HEAD');
    # 埋め込み文の中
    push @fe, 'EMBEDDED' if ($pred->EMBEDDED);
    # 文末
    push @fe, $pred->SENT_END if ($pred->SENT_END);

    # 態の交替
    # (1)[れる，られる]
    push @fe, 'VOICE_'.$pred->VOICE if ($pred->VOICE);
    # (2)[せる,させる,ほしい,もらう,いただく,くれる,下さる,くださる,やる,あげる]
    push @fe, 'AUX' if ($pred->AUX);
    # (1)(2)の両方
    push @fe, 'ALT' if ($pred->VOICE or $pred->AUX);
    
    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }
    return join ' ', @fe;
   
    
}

sub ext_ana_t_inter { 
    my $pred = shift; my $label = shift;

    my @fe = ();

    # 表層文字列(基本形)
    push @fe, 'PRED_'.$pred->PRED if ($pred->PRED);

     # 主節に存在
    push @fe, $pred->MAIN_HEAD if ($pred->MAIN_HEAD and
                                  $pred->MAIN_HEAD eq 'MAIN_HEAD');
    # 埋め込み文の中
    push @fe, 'EMBEDDED' if ($pred->EMBEDDED);
    # 文末
    push @fe, $pred->SENT_END if ($pred->SENT_END);

    # 態の交替
    # (1)[れる，られる]
    push @fe, 'VOICE_'.$pred->VOICE if ($pred->VOICE);
    # (2)[せる,させる,ほしい,もらう,いただく,くれる,下さる,くださる,やる,あげる]
    push @fe, 'AUX' if ($pred->AUX);
    # (1)(2)の両方
    push @fe, 'ALT' if ($pred->VOICE or $pred->AUX);
    
    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }
    return join ' ', @fe;
   
    
}

sub ext_cand_t_bact {
    my $cand = shift; my $label = shift; my $cl = shift;
    my $fe = &ext_cand_t($cand, $label, $cl);
    my @tmp = ();
    for (split ' ', $fe) {
	push @tmp, '('.(split '\:', $_)[0].')';
    }
    return join '', @tmp;

}

sub ext_cand_t {
    my $cand = shift; my $label = shift;
    my $cl = shift;
    my @fe = ();

    # 一文目
    push @fe, 'FIRST_SENT' if ($cand->sid == 0);

    push @fe, 'HEAD_BF_'.$cand->HEAD_BF; # HEAD_BF
    push @fe, 'HEAD_POS_'.$cand->HEAD_POS; # HEAD_POS
    push @fe, 'CASE_'.$cand->CASE; # 表層格
    push @fe, 'DEFINITE_'.$cand->DEFINITE if ($cand->DEFINITE); # DEFINITE
    push @fe, 'PRE_DEFINITE_'.$cand->PRE_DEFINITE if ($cand->PRE_DEFINITE); # PRE_DEFINITE
    if ($cand->HEAD_NE ne 'O') { # NE
        my $ne = $cand->HEAD_NE;
        # LOCATIONとORGANIZATIONは同じように扱う
        $ne =~ s/^(?:LOCATION|ORGANIZATION)$/LOC_ORG/;
        push @fe, 'NE_'.$ne;
    }
    push @fe, $cand->EDR_PERSON if ($cand->EDR_PERSON); # EDR_PERSON
    push @fe, $cand->EDR_ORG if ($cand->EDR_ORG); # EDR_ORG
    push @fe, $cand->PRONOUN_TYPE if ($cand->PRONOUN_TYPE); # PRONOUN_TYPE
    push @fe, $cand->SENT_END if ($cand->SENT_END); # SENT_END
    push @fe, $cand->SENT_BEGIN if ($cand->SENT_BEGIN); # SENT_BEGIN     

    push @fe, 'IN_QUOTE' if ($cand->IN_QUOTE); # 引用の中か

    # IS_MAIN_HEAD
    push @fe, $cand->MAIN_HEAD if ($cand->MAIN_HEAD and $cand->MAIN_HEAD eq 'MAIN_HEAD');
    # EMBEDDED
    if ($cand->EMBEDDED) {
        my $depth = $cand->EMBEDDED; if ($depth > 3) { $depth = 3; };
        push @fe, 'EMBEDDED' if ($cand->EMBEDDED);      
    }
    if ($cand->MAIN_HEAD and $cand->MAIN_HEAD =~ /\d/ and
        $cand->id eq $cand->MAIN_HEAD) {
        push @fe, 'DEP_MAIN_HEAD';
    }

    # (ゼロ代名詞は候補になっているとして)
    # もし対象が補完されたゼロ代名詞ならば，
    # 表層何格か

    # Center List の情報をここに
    my $clrank  = $cl->rank($cand);
    push @fe, 'CL_RANK_'.$clrank if ($clrank);
    my $clorder = $cl->order($cand);
    push @fe, 'CL_ORDER_'.$clorder if ($clorder);
    
    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }

    return join ' ', @fe;

}

sub ext_cand_t_inter {
    my $cand = shift; my $label = shift;
    my $cl = shift;
    my @fe = ();

    # 一文目
    push @fe, 'FIRST_SENT' if ($cand->sid == 0);

#     push @fe, 'HEAD_BF_'.$cand->HEAD_BF; # HEAD_BF
    push @fe, 'HEAD_POS_'.$cand->HEAD_POS; # HEAD_POS
    push @fe, 'CASE_'.$cand->CASE; # 表層格
    push @fe, 'DEFINITE_'.$cand->DEFINITE if ($cand->DEFINITE); # DEFINITE
    push @fe, 'PRE_DEFINITE_'.$cand->PRE_DEFINITE if ($cand->PRE_DEFINITE); # PRE_DEFINITE
    if ($cand->HEAD_NE ne 'O') { # NE
        my $ne = $cand->HEAD_NE;
        # LOCATIONとORGANIZATIONは同じように扱う
        $ne =~ s/^(?:LOCATION|ORGANIZATION)$/LOC_ORG/;
        push @fe, 'NE_'.$ne;
    }
    push @fe, $cand->EDR_PERSON if ($cand->EDR_PERSON); # EDR_PERSON
    push @fe, $cand->EDR_ORG if ($cand->EDR_ORG); # EDR_ORG
    push @fe, $cand->PRONOUN_TYPE if ($cand->PRONOUN_TYPE); # PRONOUN_TYPE
    push @fe, $cand->SENT_END if ($cand->SENT_END); # SENT_END
    push @fe, $cand->SENT_BEGIN if ($cand->SENT_BEGIN); # SENT_BEGIN     

    push @fe, 'IN_QUOTE' if ($cand->IN_QUOTE); # 引用の中か

    # IS_MAIN_HEAD
    push @fe, $cand->MAIN_HEAD if ($cand->MAIN_HEAD and $cand->MAIN_HEAD eq 'MAIN_HEAD');
    # EMBEDDED
    if ($cand->EMBEDDED) {
        my $depth = $cand->EMBEDDED; if ($depth > 3) { $depth = 3; };
        push @fe, 'EMBEDDED' if ($cand->EMBEDDED);      
    }
    if ($cand->MAIN_HEAD and $cand->MAIN_HEAD =~ /\d/ and
        $cand->id eq $cand->MAIN_HEAD) {
        push @fe, 'DEP_MAIN_HEAD';
    }

    # (ゼロ代名詞は候補になっているとして)
    # もし対象が補完されたゼロ代名詞ならば，
    # 表層何格か

    # Center List の情報をここに
    my $clrank  = $cl->rank($cand);
    push @fe, 'CL_RANK_'.$clrank if ($clrank);
    my $clorder = $cl->order($cand);
    push @fe, 'CL_ORDER_'.$clorder if ($clorder);
    
    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }

    return join ' ', @fe;

}

sub ext_ana_cand_t_bact {
    my $pred = shift; my $cand = shift; my $label = shift;
    my $case = shift;
    my $fe = &ext_ana_cand_t($pred, $cand, $label, $case);
    my @tmp = ();
    for (split ' ', $fe) {
	push @tmp, '('.(split '\:', $_)[0].')';
    }
    return join '', @tmp;
}

sub ext_ana_cand_t {
    my $pred = shift; my $cand = shift; my $label = shift;
    my $case = shift; # GA, WO, NI
    my @fe = ();

    # 対象の述語と候補の位置関係
    if ($cand->sid == $pred->sid) {
	if ($cand->bid =~ /^\d+$/ and $pred->bid =~ /^\d+$/) {
	    # (1) 候補 が 述語 に先行する
	    # (2) 述語 が 候補 に先行する    
	    if ($cand->bid < $pred->bid) { # 前方照応
		push @fe, 'CAND_PRECEDES_ANA'; # (1)
	    } elsif ($pred->bid < $cand->bid) { # 後方照応
		push @fe, 'ANA_PRECEDES_CAND'; # (2)
	    }
	} elsif ($cand->bid =~ /^\d+$/) { # 3_GA
	    my $bid = (split '_', $pred->bid)[0];
	    if ($cand->bid < $bid) {
		push @fe, 'CAND_PRECEDES_ANA'; # (1)
	    } elsif ($cand->bid == $bid) {
		push @fe, 'CAND_PRECEDES_ANA'; # (1)
	    } elsif ($cand->bid > $bid) {
		push @fe, 'ANA_PRECEDES_CAND'; # (2)
	    }
	} elsif ($pred->bid =~ /^\d+$/) {
	    my $bid = (split '_', $cand->bid)[0];
# 	print STDERR 'bid: ', $bid, "\n";
# 	print STDERR 'pred: ', $pred, "\n";
	    if ($bid < $pred->bid) {
		push @fe, 'CAND_PRECEDES_ANA'; # (1)
	    } elsif ($bid > $pred->bid) {
		push @fe, 'ANA_PRECEDES_CAND'; # (2)
	    }
	}
    }

    # pred と cand の係り関係での距離を追加する
    # mark_path を参考に

    # 候補が対象の述語に係る
    if ($pred->sid == $cand->sid) {
        push @fe, 'C_DEP_P' if (ref($cand->dep) eq 'Bunsetsu' and 
                            $cand->dep->bid eq $pred->bid);
	push @fe, 'P_DEP_C' if (ref($pred->dep) eq 'Bunsetsu' and
			    $pred->dep->bid eq $cand->bid);
    }

    # 語彙大系を用いた選択制限
#     my $select = &NTT::check_select_rest($pred, $cand, 'ガ');
     my $select = &NTT::check_select_rest($pred, $cand, $case);
    push @fe, $select if ($select);
 

    # 対数尤度比を用いた選択制限
#     my $log = &check_log_like($pred, $cand, $case);    
#     if ($log) {
# 	for (my $i=1;$i<=$log;$i++) {
# 	    push @fe, 'LOG_LIKE_'.$i;
# 	}
#     }

    # MI
    #my $score = &COOC::set_fe($cand, $pred, $case, 'MI');
    my %case_of = ( 'GA' => 'が', 'NI' => 'に', 'WO' => 'を' );
    my $q = $cand->HEAD_WF.':'.$case_of{$case}.':'.$pred->PRED;
    my $score = $ncvtool->get_score($q);
    if ($score) {
	if ($score > 0) {
	    for (my $i=1;$i<=$score;$i++) {
		push @fe, 'COOC_MI_PLUS'.$i;
	    }
	} else { # $score < 0
	    for (my $i=-1;$i>=$score;$i--) {
		push @fe, 'COOC_MI_MINUS'.$i;
	    }
	}
    }
    # 括弧の情報やら，話者の情報やら


    if ($cand->sid != $pred->sid) {
	# 前しか見に行ってないため．
	my $diff = abs($pred->sid - $cand->sid);
	$diff = 3 if ($diff > 3);
	for (my $i=1;$i<=$diff;$i++) {
	    push @fe, 'SENT_DIST_'.$i;
	}
    }

    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }
    return join ' ', @fe;
}

sub ext_two_cands_t {
    my $l = shift; my $r = shift; my $label = shift;
    my $cl = shift;
    my @fe = ();

#     # 候補間の距離
#     my $dist = $r->sid - $l->sid;
#     $dist = 3 if ($dist > 3);
#     push @fe, 'DIST_'.$dist;

    # Center Listのrank, orderの比較
    my $rank_l = $cl->rank($l); my $order_l = $cl->order($l);
    my $rank_r = $cl->rank($r); my $order_r = $cl->order($r);
    if ($rank_l and !$rank_r) {
	push @fe, 'CL_RANK_PREFERS_L';
    } elsif (!$rank_l and $rank_r) {
	push @fe, 'CL_RANK_PREFERS_R';
    } elsif ($rank_l and $rank_r) {
	if ($rank_l < $rank_r) {
	    push @fe, 'CL_RANK_PREFERS_L';
	} elsif ($rank_l > $rank_r) {
	    push @fe, 'CL_RANK_PREFERS_R';
	}
    }
    if ($order_l and !$order_r) {
	push @fe, 'CL_ORDER_PREFERS_L';
    } elsif (!$order_l and $order_r) {
	push @fe, 'CL_ORDER_PREFERS_R';
    } elsif ($order_l and $order_r) {
	if ($order_l < $order_r) {
	    push @fe, 'CL_ORDER_PREFERS_L';
	} elsif ($order_l > $order_r) {
	    push @fe, 'CL_ORDER_PREFERS_R';
	}
    }

    


    # 候補lが候補rに係る
    if ($l->sid == $r->sid) {
        if (ref($l->dep) eq 'Bunsetsu' and
            $l->dep->bid eq $r->bid) {
            push @fe, 'L_DEP_R';
        }
        if ($r->descendant and $r->descendant->{$l->id}) {
            push @fe, 'L_DESCENDANT_R';
        }
    }

    my $f_num = @fe;
    for (my $fid=0;$fid<$f_num;$fid++) {
        $fe[$fid] = $label.$fe[$fid].':1';
    }
    return join ' ', @fe;
}

sub ext_fe {
    my $pred = shift; my $ant = shift;
    my $type = shift; # GA, WO, NI
    my $cl = shift; # Center List
    my $logref = shift; # Log-Likelihood 
    my @fe = ();

    push @fe, &ext_ana($pred);
    push @fe, &ext_ant($ant, $cl);
    push @fe, &ext_ana_ant($pred, $ant, $logref);
    return join '', @fe;
}

sub ext_ana {
    my $pred = shift;

    my @fe = ();
    push @fe, 'POS_'.$pred->HEAD_POS; 
    push @fe, 'PRED_'.$pred->PRED if ($pred->PRED);
    push @fe, $pred->MAIN_HEAD if ($pred->MAIN_HEAD eq 'MAIN_HEAD');
    push @fe, $pred->SENT_END if ($pred->SENT_END);

    # 動詞の意味クラスを加えたい
    
    my $f_num = @fe;
    for (my $i=0;$i<$f_num;$i++) {
	$fe[$i] = '(FE_ANA_'.$fe[$i].')';
    }
    return join '', @fe;
}

sub ext_ant {
    my $ant = shift; my $cl = shift;

    my @fe = ();
    push @fe, 'POS_'.$ant->HEAD_POS;
    # ゼロ代名詞として補完された候補か否か
    push @fe, 'CASE_'.$ant->CASE;                              # CASE MARKER
    push @fe, 'DEFINITE_'.$ant->DEFINITE if ($ant->DEFINITE); # DEFINITE
#     push @fe, $ant->PRE_DEFINITE if ($ant->PRE_DEFINITE);     # PRE_DEFINITE
    if ($ant->HEAD_NE ne 'O') {                                # NE
	my $ne = $ant->HEAD_NE;
	# LOCATIONとORGANIZATIONは同じように扱う
	$ne =~ s/^(?:LOCATION|ORGANIZATION)$/LOC_ORG/;
	push @fe, 'NE_'.$ne;
    }
    push @fe, $ant->PRONOUN_TYPE if ($ant->PRONOUN_TYPE);     # PRONOUN_TYPE
    push @fe, $ant->SENT_END if ($ant->SENT_END);             # SENT_END
    push @fe, $ant->SENT_BEGIN if ($ant->SENT_BEGIN);         # SENT_BEGIN    

    # 引用の中か否か
#     if ($optref->{q}) {
# 	push @fe, 'IN_QUOTE' if ($ant->QUOTE);
#     }

    push @fe, $ant->MAIN_HEAD if ($ant->MAIN_HEAD and $ant->MAIN_HEAD eq 'MAIN_HEAD');

    if ($ant->EMBEDDED) {
	my $depth = $ant->EMBEDDED; if ($depth > 3) { $depth = 3; };
	push @fe, 'EMBEDDED' if ($ant->EMBEDDED);	
    }
    if ($ant->MAIN_HEAD and $ant->MAIN_HEAD =~ /\d/ and
	$ant->id eq $ant->MAIN_HEAD) {
	push @fe, 'DEP_MAIN_HEAD';
    }

    my $rank = $cl->rank($ant); my $order = $cl->order($ant);
    push @fe, 'CENTER_LIST_RANK_'.$rank if ($rank);
    push @fe, 'CENTER_LIST_ORDER_'.$order if ($order);
#     my $index = $ant->sid.':'.$ant->bid;
#     if ($SRL->{$index}) {
# 	push @fe, 'SRL_'.$SRL->{$index}{'label'};
# 	push @fe, 'SRL_PREF_'.$SRL->{$index}{'pref'};	
#     }

    if ($ant->CHAIN_LENGTH) {
	my $len = $ant->CHAIN_LENGTH;
	$len = 3 if ($len > 3);
	push @fe, 'CHAIN_LEN_'.$len;
    }
    
    my $f_num = @fe;
    for (my $i=0;$i<$f_num;$i++) {
	$fe[$i] = '(FE_ANT_'. $fe[$i].')';
    }

    return join '', @fe;
}

sub ext_ana_ant {
    my $pred = shift; my $ant = shift;
    my $logref = shift;
    return;
}

sub ext_features_with_str {
    my $pred = shift; my $ant = shift; my $cl = shift; my $s = shift;

    my $str  = &ext_features_str($pred, $ant, $s, $cl);
    return $str;
}

sub ext_features_with_str_flat {
    my $pred = shift; my $ant = shift; my $cl = shift; my $s = shift;
    my $pair = &ext_features_pair($pred, $ant, $cl);
    my $str  = &ext_features_str_no_info($pred, $ant, $s, $cl);
    return '(~ROOT'.$str.$pair.')';
}

sub ext_features_str_tou {
    my $pred = shift; my $left = shift; my $right = shift; my $cl = shift;
    my $s = shift;

    my $l_pair = &ext_features_pair($pred, $left, $cl);
    my $l_str  = &ext_features_str_no_info($pred, $left, $s, $cl);
    $l_pair =~ s|\((?!\()|\(L_|g; $l_str =~ s|\((?!\()|\(L_|g;
    
    my $r_pair = &ext_features_pair($pred, $right, $cl);
    my $r_str  = &ext_features_str_no_info($pred, $right, $s, $cl);
    $r_pair =~ s|\((?!\()|\(R_|g; $r_str =~ s|\((?!\()|\(R_|g;
    
    return '(~ROOT'.$l_str.$l_pair.$r_str.$r_pair.')';
}

sub ext_features_wo_str {
    my $pred = shift; my $ant = shift; my $cl = shift;
    my $pair = &ext_features_pair($pred, $ant, $cl);
    return '(~ROOT'.$pair.')';
}

sub ext_features_SVM {
    my $pred = shift; my $ant = shift; my $cl = shift;
    my $case = shift;
    my @fe = ();
    # とりあえずtournament modelと同じ素性を利用
    push @fe, &ext_ana_t($pred, 'ANA_');
    push @fe, &ext_cand_t($ant, 'C_', $cl);
    push @fe, &ext_ana_cand_t($pred, $ant, 'AC_', $case);

    return join ' ', @fe;
}

sub ext_features_pair {
    my $pred = shift; my $ant = shift; my $cl = shift;

    my $case = shift;
    
    my @fe = ();
    # とりあえずtournament modelと同じ素性を利用
    push @fe, &ext_ana_t($pred, 'ANA_');
    push @fe, &ext_cand_t($ant, 'C_', $cl);
    push @fe, &ext_ana_cand_t($pred, $ant, 'AC_', $case);

    my @FE = ();
    for my $f (@fe) {
# 	print STDERR $f, "\n";
	next unless ($f);
	push @FE, '('.(split '\:', $f)[0].')';
    }
    return join '', @FE;
}

sub ext_b_info_sub_svm {
    my $LABEL = shift;
    my $b = shift; my @m = @{$b->Mor}; my $m_num = @m;
    my @tmp = ();

    if ($b->head != $m_num-1) {
	for (my $i=$b->head+1;$i<$m_num;$i++) {
	    push @tmp, $LABEL.'_FUNC_'.$m[$i]->BF.':1';
	}
    }
    return join ' ', @tmp;
}

sub ext_b_info_sub {
    my $LABEL = shift;
    my $b = shift; my @m = @{$b->Mor}; my $m_num = @m;
    my @tmp = ();


    # CNT は除く．
#     for (my $i=0;$i<=$b->head;$i++) {
# 	push @tmp, '(CNT_'.$m[$i]->BF.')';
#     }

    # FUNC only
    if ($b->head != $m_num -1) {
	for (my $i=$b->head+1;$i<$m_num;$i++) {
	    push @tmp, '('.$LABEL.'_FUNC_'.$m[$i]->BF.')';
	}
    }
    return join '', @tmp;
}

sub ext_b_info_sub_svml {
    my $LABEL = shift;
    my $b = shift; my @m = @{$b->Mor}; my $m_num = @m;
    my @tmp = ();

    # とりあえず，機能語のみ．
    if ($b->head != $m_num-1) {
	for (my $i=$b->head+1;$i<$m_num;$i++) {  
# 	    push @tmp, '('.$LABEL.'_FUNC_'.$m[$i]->BF.')';
	    push @tmp, '('.$LABEL.'_POS_'.$m[$i]->POS.' '.
		$LABEL.'_FUNC_'.$m[$i]->BF.')';
	}
    }
    return join '', @tmp;

}

sub ext_b_info_sub2 {
    my $LABEL = shift;
    my $b = shift; my @m = @{$b->Mor}; my $m_num = @m;
    my @tmp = ();

    push @tmp, '('.$LABEL.'_HEAD_POS_'.(split '-', $b->HEAD_POS)[0].')';

    # FUNC only
    if ($b->head != $m_num -1) {
	for (my $i=$b->head+1;$i<$m_num;$i++) {
	    push @tmp, '('.$LABEL.'_FUNC_'.$m[$i]->BF.')';
	}
    }
    return join '', @tmp;
}

### HDAG kernel ####
sub ext_fe_sample_one {
    my $pred = shift; my $ant = shift; my $cl = shift; my $s = shift;
    my @b = @{$s->Bunsetsu}; my $b_num = @b;
#     print STDERR 'ext_fe_sample_one', "\n";
    &mark_path($pred, $ant, $s);
    

    my $pid = 0; my @p = ();
    my %bid2pid = ();
    my %pid2elm = ();
    for my $b (@b) {
	next unless ($b->PATH); # ant <-> pred のPATHのみを対象に
	my @m = @{$b->Mor}; my $m_num = @m;
	my @elm = (); # array of morpheme elm
	for (my $i=0;$i<$m_num;$i++) {
	    my $elm; $elm->{pid} = $pid++;
	    $elm->{type} = 'm'; $elm->{elm} = $m[$i];
	    $elm->{dep} = $elm->{pid} - 1 if ($i != 0);
	    push @p, $elm;
	    push @elm, $elm;
	}

	my $elm; $elm->{pid} = $pid++;
	$elm->{type} = 'b'; $elm->{elm} = $b;
	my @dtr = @{$b->dtr}; my @dep = ();
	for my $dtr (@dtr) {
	    next unless ($dtr->PATH);
	    push @dep, $bid2pid{$dtr->bid} if ($bid2pid{$dtr->bid});
	}
	$elm->{dep} = join ',', @dep;
	push @p, $elm;
	$bid2pid{$b->bid} = $elm->{pid};
	$pid2elm{$elm->{pid}} = \@elm;
    }

    my $p_num = @p;
    my @fe = ();
    for (my $pid=0;$pid<$p_num;$pid++) {
	my $p = $p[$pid];
	my $f1 = $p->{pid};
	my $f2; my $f3 = '';
	if (ref($p->{elm}) eq 'Bunsetsu') {
	    $f2 = &ext_bunsetsu_fe($p->{elm}, $pred, $ant, $cl, $s);
	    my @m = @{$p->{elm}->Mor}; my $m_num = @m;
	    my @elm = @{$pid2elm{$p->{pid}}}; my $e_num = @elm;
	    my @mid = ();
	    for (my $i=0;$i<$e_num;$i++) { 
		push @mid, $elm[$i]->{pid};
	    }
	    $f3 = join ',', @mid; # morphemes
	} else { # Morpheme
	    $f2 = &ext_morpheme_fe($p->{elm}, $pred, $ant, $cl, $s);	    
	}
	my $f4 = ($p->{dep})? $p->{dep} : '';
	my $fe = $f1.':'.$f2.':'.$f3.':'.$f4;
	push @fe, $fe;
    }
    
    return join ' ', @fe;
}

sub ext_bunsetsu_fe {
    my ($b, $pred, $ant, $cl, $s) = @_;
    my @fe = ();
    if ($b->bid == $pred->bid) {
	push @fe, &ext_fe_b_ana($pred, $ant);
	push @fe, 'ANA';
    } elsif ($b->bid == $ant->bid) {
	push @fe, &ext_fe_b_ant($ant, $cl);
	push @fe, 'ANT';
    }
    push @fe, &ext_fe_b($b);
    return join ',', @fe;
}

sub ext_morpheme_fe {
    my ($m, $pred, $ant, $cl, $s) = @_;
    my @fe = ();
    push @fe, 'BF_'.$m->BF;
    push @fe, 'POS_'.$m->POS;
    return join ',', @fe;
}

sub ext_fe_b {
    my $b = shift;
    my @fe = ();
    push @fe, 'HEAD_BF_'.$b->HEAD_BF;
    push @fe, 'HEAD_POS_'.$b->HEAD_POS;

    my @m = @{$b->Mor}; my $m_num = @m;
    if ($b->head != $m_num -1) {
	for (my $mid=$b->head+1;$mid<$m_num;$mid++) {
	    push @fe, 'FUNC_BF_'.$m[$mid]->BF;
	    push @fe, 'FUNC_POS_'.$m[$mid]->POS;
	}
    }

    return join ',', @fe;
}

sub ext_fe_b_ant {
    my $ant = shift; my $cl = shift;
    my @fe = ();
    for (split ' ', &ext_cand_t($ant, 'CAND_', $cl)) {
	push @fe, (split '\:', $_)[0];
    }
    return join ',', @fe;
}

sub ext_fe_b_ana {
    my $pred = shift; my $ant = shift;
    my $case = shift;
    my @fe = ();
    for (split ' ', &ext_ana_t($pred, 'ANA_')) {
	push @fe, (split '\:', $_)[0];
    }
    for (split ' ', &ext_ana_cand_t($pred, $ant, 'AC_', $case)) {
	push @fe, (split '\:', $_)[0];
    }
    return join ',', @fe;
}

sub ext_one_str_new {
    my ($pred, $cand, $cl, $s, $case, $label, $optref) = @_;

    my @b = @{$s->Bunsetsu}; my $b_num = @b; my @seq = ();
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid];
	my @z = ();
	push @seq, $b->GA_b if ($b->GA_b and $b->GA_b->PATH); 
	push @seq, $b->WO_b if ($b->WO_b and $b->WO_b->PATH); 
	push @seq, $b->NI_b if ($b->NI_b and $b->NI_b->PATH); 
	push @seq, $b if ($b->PATH);
    }

    my $out = '';
    for my $seq (@seq) {
	$out = '('.&ext_one_bunsetsu_info($seq, $pred, $cand, $cl, $s, $case, $label).$out.')';
    }
    
#     my $pbid = $pred->bid;
#     my $abid = $cand->bid; $abid = (split '_', $abid)[0];
#     my $begin; my $end;
#     if ($pbid < $abid) {
# 	$begin = $pbid; $end = $abid;
#     } else {
# 	$begin = $abid; $end = $pbid;
#     }
#     # とりあえず，，
#     if ($abid < $pbid) { # 先行詞が述語より前に出現．
# 	# antecedent
# 	my $ant = '('.&ext_one_b_info($cand, $pred, $cand, $cl, $s, $case, $label).')';
# 	$out = $ant;
# 	for (my $bid=$begin+1;$bid<$end;$bid++) {
# 	    if ($b[$bid]->CLAUSE_END) {
# 		$out = '('.&ext_one_b_info($b[$bid], $pred, $cand, $cl, $s, $case, $label).$out.')';
# 	    }
# 	}
#     }
    

    return $out;
}

sub ext_one_b_info {
    my ($b, $pred, $cand, $cl, $s, $case, $label) = @_;
    my $LABEL = &ext_label($b, $pred, $cand, $label);
#     my $binfo = &ext_b_info_sub2($LABEL, $b); my $out = '';
    my $binfo = &ext_b_info_sub($LABEL, $b); my $out = '';

    $out = $LABEL.$binfo;
}

sub ext_one_new_str {
    my ($pred, $l, $r, $cl, $s, $case, $optref) = @_;

    my @b = @{$s->Bunsetsu};

    # left
    &mark_path($pred, $l, $s);
    my @bl = @{$s->Bunsetsu}; my $bl_num = @bl; my @lpath = ();
    for (my $bid=0;$bid<$bl_num;$bid++) {
	push @lpath, $b[$bid] if ($b[$bid]->PATH);
	# 述語を除くPATH の bid を 追加する．
    }

    # right
    &mark_path($pred, $r, $s);
    my @br = @{$s->Bunsetsu}; my $br_num = @br; my @rpath = ();
    for (my $bid=0;$bid<$br_num;$bid++) {
	push @rpath, $b[$bid] if ($b[$bid]->PATH);
    }

    # delete left_b, right_b
    my $cur_p = $pred;
    while ($cur_p->has_dep) {
	$cur_p = $cur_p->dep; $cur_p->left_b(0); $cur_p->right_b(0); 
    }
    my $cur_l = $l;
    while ($cur_l->has_dep) {
	$cur_l = $cur_l->dep; $cur_l->left_b(0); $cur_l->right_b(0); 
    }
    my $cur_r = $r;
    while ($cur_r->has_dep) {
	$cur_r = $cur_r->dep; $cur_r->left_b(0); $cur_r->right_b(0); 
    }
    

    my %both = ();
    for my $lp (@lpath) {
	next if ($lp->bid eq $pred->bid); # 述語を除く．
	for my $rp (@rpath) {
	    $both{$lp->bid} = 1 if ($lp->bid eq $rp->bid);
	}
    }

    my $out = '';
    if ($pred->bid > (split '_', $r->bid)[0]) {
	for my $lp (@lpath) {
	    next if (defined $both{$lp->bid});
 	    my $label = 'L_'; ###
# 	    my $label = &ext_label($lp, $pred, $l, $label);
	    $out = '('.&ext_one_bunsetsu_info($lp, $pred, $l, $cl, $s, $case, $label).$out.')';
	}
	for my $rp (@rpath) {
 	    my $label = 'R_'; ###
# 	    my $label = &ext_label($rp, $pred, $r, $label);
	    $out = '('.&ext_one_bunsetsu_info($rp, $pred, $r, $cl, $s, $case, $label).$out.')';
	}

    } elsif ($pred->bid < (split '_', $l->bid)[0]) {
	for my $lp (@lpath) {
 	    my $label = 'L_'; ###
# 	    my $label = &ext_label($lp, $pred, $l, $label);
	    $out = '('.&ext_one_bunsetsu_info($lp, $pred, $l, $cl, $s, $case, $label).$out.')';
	}
	for my $rp (@rpath) {
	    next if (defined $both{$rp->bid});
 	    my $label = 'R_'; ###
# 	    my $label = &ext_label($rp, $pred, $r, $label);
	    $out = '('.&ext_one_bunsetsu_info($rp, $pred, $r, $cl, $s, $case, $label).$out.')';
	}
    } elsif ((split '_', $l->bid)[0] < $pred->bid and $pred->bid < (split '_', $r->bid)[0]) {
	for my $lp (@lpath) {
 	    my $label = 'L_'; ###
# 	    my $label = &ext_label($lp, $pred, $l, $label);
	    $out = '('.&ext_one_bunsetsu_info($lp, $pred, $l, $cl, $s, $case, $label).$out.')';
	}
	for my $rp (@rpath) {
	    next if ($rp->bid eq $pred->bid); # 述語だけ重複するので．
 	    my $label = 'R_'; ###
# 	    my $label = &ext_label($rp, $pred, $r, $label);
	    $out = '('.&ext_one_bunsetsu_info($rp, $pred, $r, $cl, $s, $case, $label).$out.')';
	}
    } else {
	die "hoge\n";
    }

    my $fe_l_p  = &ext_ana_t_bact($pred, 'L_P_'); # pred only
    my $fe_l_c  = &ext_cand_t_bact($l, 'L_A_CAND_', $cl); # cand only
    my $fe_l_pc = &ext_ana_cand_t_bact($pred, $l, 'L_A_AC_', $case); # pred-cand

    my $fe_r_p  = &ext_ana_t_bact($pred, 'R_P_'); # pred only
    my $fe_r_c  = &ext_cand_t_bact($r, 'R_A_CAND_', $cl); # cand only
    my $fe_r_pc = &ext_ana_cand_t_bact($pred, $r, 'R_A_AC_', $case); # pred-cand

    return $out.$fe_l_p.$fe_l_c.$fe_l_pc.$fe_r_p.$fe_r_c.$fe_r_pc;
}

1;
