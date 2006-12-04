#!/usr/bin/env perl

use strict;
use warnings;

my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
unshift @INC, $scriptPath;
require 'centerList.pl'; require 'extractFeatures.pl';
require 'cab.pl';

sub output_opt {
    my ($name, $optref) = @_;
    open 'OPT', '>'.$optref->{d}.'/'.$name.'.opt' or die $!;
    while (my ($key, $val) = each %{$optref}) {
	print OPT $key, "\t", $val, "\n";
    }
    close OPT;
    return;
}

# PRED��ANT�δ֤ˤ���ʸ���mark
sub mark_path {
    my $pred = shift; my $ant = shift;  my $s = shift;
    my @b = @{$s->Bunsetsu}; my $b_num = @b;

    # init
    for (my $bid=0;$bid<$b_num;$bid++) { $b[$bid]->PATH(0); }

    my $p = $pred; my @p = ($p);
    while ($p->has_dep) {
	# $p ��dep ��$p�����äƤ��뤫��check
# 	$p->left_b(0); $p->right_b(0);
	$p = $p->dep; push @p, $p; 
    }
#     $p->left_b(0); $p->right_b(0);

    my $a = $ant;  my @a = ($a);
    while ($a->has_dep) {
	# $a ��dep ��$p�����äƤ��뤫��check
# 	$a->left_b(0); $a->right_b(0);
	$a = $a->dep; push @a, $a; 
    }
#     $a->left_b(0); $a->right_b(0);

    # init
#     my $p_num = @p; my $a_num = @a;
#     for (my $pid=0;$pid<$p_num;$pid++) {
# 	$p[$pid]->left_b(0); $p[$pid]->right_b(0);
#     }
#     for (my $aid=0;$aid<$a_num;$aid++) {
# 	$a[$aid]->left_b(0); $a[$aid]->right_b(0);
#     }
    for (my $bid=0;$bid<$b_num;$bid++) {
 	$b[$bid]->left_b(0); $b[$bid]->right_b(0);
	if ($b[$bid]->GA_b) { $b[$bid]->GA_b->left_b(0); $b[$bid]->GA_b->right_b(0); }
	if ($b[$bid]->WO_b) { $b[$bid]->WO_b->left_b(0); $b[$bid]->WO_b->right_b(0); }
	if ($b[$bid]->NI_b) { $b[$bid]->NI_b->left_b(0); $b[$bid]->NI_b->right_b(0); }
    }

    my $p_label = ($pred->bid < (split '_', $ant->bid)[0])? 'left' : 'right';
    my $a_label = ($p_label eq 'left')? 'right' : 'left';

    my $p_num = @p; my $a_num = @a;
    for (my $pid=0;$pid<$p_num;$pid++) {
	for (my $aid=0;$aid<$a_num;$aid++) {
	    if ($p[$pid]->bid eq $a[$aid]->bid) {

		my %bid = ();
 		for (my $PID=0;$PID<=$pid;$PID++) { 
		    $bid{$p[$PID]->bid} = 1; $p[$PID]->{$p_label.'_b'} = 1 if ($PID != 0 and $PID != $pid);
		}
		for (my $AID=0;$AID<=$aid;$AID++) { 
		    $bid{$a[$AID]->bid} = 1; $a[$AID]->{$a_label.'_b'} = 1 if ($AID != 0 and $AID != $aid);
		}

		my $last = $p[$pid]; my @cand = ($last);
		while (@cand) {
		    my $cand = shift @cand;
  		    $cand->PATH(1) if ($bid{$cand->bid});
# 		    $b[$cand->bid]->PATH(1) if ($bid{$cand->bid} and $cand->bid =~ /^\d+$/);
# 		    $b[$cand->bid]->PATH(1) if ($bid{$cand->bid});

		    if (@{$cand->dtr}) {
			for my $d (@{$cand->dtr}) { push @cand, $d; }
		    }

		}

		# $pred �� $ant �λ�¹ ($pid == 0)���⤷���ϡ�
		# $ant �� $pred �λ�¹ ($aid == 0)�Ǥ������
		# ľ���ˤĤʤ���Τ� left_b, right_b �������롥
		if ($pid == 0 or $aid == 0) {
		    for (my $PID=0;$PID<$p_num;$PID++) {
			$p[$PID]->left_b(0); $p[$PID]->right_b(0);
		    }
		    for (my $AID=0;$AID<$a_num;$AID++) {
			$a[$AID]->left_b(0); $a[$AID]->right_b(0);
		    }
		}


		$s->Bunsetsu(\@b);
 		return;

	    } else { 
#  		if ($p[$pid]->bid ne $a[$aid]->bid) {
# 		    $p[$pid]->{$p_label.'_b'} = 1 if ($pid != 0);
# 		    $a[$aid]->{$a_label.'_b'} = 1 if ($aid != 0);
#  		}
	    }
	}
    }
    # FIXME: 2006/08/21 (mamoru-k)
    #die $!;
    return;
}

sub fill_zero {
    my $s = shift; my $pred = shift;

    # init
    my @b = @{$s->Bunsetsu}; my $b_num = @b;    
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid]; $b->GA_b(''); $b->WO_b(''); $b->NI_b('');
    }


    my %ID2b = (); # ID -> Bunsetsu
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid]; $ID2b{$b->ID} = $b if ($b->ID);
    }

#     my $S = $s->copy;
    my $S = $s;
    my @B = @{$S->Bunsetsu}; my $B_num = @B; my $PRED;
    for (my $Bid=0;$Bid<$B_num;$Bid++) {
	my $B = $B[$Bid];
	# �оݤȤ���Ҹ�˴ؤ��Ƥϲ����ɲä��ʤ���
	$PRED = $B if ($B->bid eq $pred->bid);
	next if ($B->bid eq $pred->bid);

 	$B[$Bid]->GA_b($ID2b{$B->GA}->copy_zero($B, 'GA')) 
 	    if ($B->GA and $ID2b{$B->GA});
	$B[$Bid]->WO_b($ID2b{$B->WO}->copy_zero($B, 'WO')) 
	    if ($B->WO and $ID2b{$B->WO});
	$B[$Bid]->NI_b($ID2b{$B->NI}->copy_zero($B, 'NI')) 
	    if ($B->NI and $ID2b{$B->NI});
    }

    $S->Bunsetsu(\@B);


    return ($S, $PRED);
}

sub fill_zero_text {
    my $t = shift; my $SID = shift; my $b = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    return $t if ($SID == 0);

    # init 
    my %ID2b = ();
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; $b->GA_b(''); $b->WO_b(''); $b->NI_b('');
	    $ID2b{$b->ID} = $b if ($b->ID);
	}
    }

    for (my $sid=0;$sid<$SID;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
	    $b[$bid]->GA_b($ID2b{$b->GA}->copy_zero($b, 'GA'))
		if ($b->GA and $ID2b{$b->GA});
	    $b[$bid]->WO_b($ID2b{$b->WO}->copy_zero($b, 'WO'))
		if ($b->WO and $ID2b{$b->WO});
	    $b[$bid]->NI_b($ID2b{$b->NI}->copy_zero($b, 'NI'))
		if ($b->NI and $ID2b{$b->NI});
	}
    }

    return $t;
}

sub fill_zero_all {
    my $t = shift; my $SID = shift; my $pred = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    
    # init
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; $b->GA_b(''); $b->WO_b(''); $b->NI_b('');
	}
    }

    my %ID2b = ();
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    return $t if ($sid == $pred->sid and $bid == $pred->bid);
	    my $b = $b[$bid];
	    $b[$bid]->GA_b($ID2b{$b->GA}->copy_zero($b, 'GA'))
		if ($b->GA and $ID2b{$b->GA});
	    $b[$bid]->WO_b($ID2b{$b->WO}->copy_zero($b, 'WO'))
		if ($b->WO and $ID2b{$b->WO});
	    $b[$bid]->NI_b($ID2b{$b->NI}->copy_zero($b, 'NI'))
		if ($b->NI and $ID2b{$b->NI});
	    $ID2b{$b->ID} = $b if ($b->ID);
	}
    }

    die "check 'fill_zero_all' subroutine\n";
}

sub fill_zero_pre {
    my $t = shift; my $SID = shift; my $pred = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;

    # init
    my %ID2b = ();
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; $b->GA_b(''); $b->WO_b(''); $b->NI_b('');
	    $ID2b{$b->ID} = $b if ($b->ID);
	}
    }
    for (my $sid=0;$sid<=$SID;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];

	    # �оݤȤʤ�Ҹ�˴ؤ��Ƥϲ����ɲä��ƤϤ����ʤ���
	    next if ($b->sid eq $pred->sid and $b->bid eq $pred->bid);

	    $b[$bid]->GA_b($ID2b{$b->GA}->copy_zero($b, 'GA'))
		if ($b->GA and $ID2b{$b->GA});
	    $b[$bid]->WO_b($ID2b{$b->WO}->copy_zero($b, 'WO'))
		if ($b->WO and $ID2b{$b->WO});
	    $b[$bid]->NI_b($ID2b{$b->NI}->copy_zero($b, 'NI'))
		if ($b->NI and $ID2b{$b->NI});
	}
    }
    return $t;
}

sub mark_path_sub {
    my $c = shift;
}

sub ext_clause {
    my $pred = shift; my $ant = shift;
    my @b = @_; my $b_num = @b; my $cid = 0; # clause id
    my @elm = (); my @cls = (); my $eid = 0; # element id
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid];
	if ($b->PATH) {
#  	    print STDERR "\t", $b->STRING, "\n";
	    $b->cid($cid);
	    if ($b->CLAUSE_END) {
		my $cls = CLAUSE->new;
		$cls->cid($cid); $cls->pred($b); 
		my @ELM = @elm; $cls->elm(\@ELM);
		push @cls, $cls;
		$cid++; @elm = (); $eid = 0;
	    } else {
		my $elm = ELEM->new;
		$elm->eid($eid++); $elm->b($b);
		push @elm, $elm;
	    }
	} 
    }
#     print STDERR "\n";

    # add 'dep'
    my $c_num = @cls;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $cls = $cls[$cid];
	my $b = $cls->pred;
	if ($b->has_dep and $b->dep->cid) {
	    $cls->dep($cls[$b->dep->cid]);
	} else {
	    $cls->dep(-1);
	}
    }

    # delete elm when not including ant or pred
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $cls = $cls[$cid];
	my @elm = @{$cls->elm}; my $flg = 1;
	for (@elm) { 
	    $flg = 0 if ($_->b->bid == $pred->bid or $_->b->bid == $ant->bid);
	}
	$cls->elm(()) if ($flg); # delete elm
    }
    return @cls;
}


sub ext_clause_tmp {
    my @b = @_; my $b_num = @b; my $cid = 0; # clause id
    my @elm = (); my @cls = (); my $eid = 0; # element id
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid];
# 	print STDERR $b->STRING, "\n";
# 	print STDERR 'C:'.$b->STRING, ' ' if ($b->PATH);
# 	print STDERR 'c:'.$b->STRING, ' ' unless ($b->PATH);
	if ($b->PATH) {
	    $b->cid($cid);
	    if ($b->CLAUSE_END) {
		my $cls = CLAUSE->new;
		$cls->cid($cid); $cls->pred($b); 
		my @ELM = @elm; $cls->elm(\@ELM);
		push @cls, $cls;
		$cid++; @elm = (); $eid = 0;
	    } else {
		my $elm = ELEM->new;
		$elm->eid($eid++); $elm->b($b);
		push @elm, $elm;
	    }
	} 
    }
#     print STDERR "\n";

    # add 'dep'
    my $c_num = @cls;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $cls = $cls[$cid];
	my $b = $cls->pred;
	if ($b->has_dep and $b->dep->cid) {
	    $cls->dep($cls[$b->dep->cid]);
	} else {
	    $cls->dep(-1);
	}
    }
    return @cls;
}

# sub ext_bact_format {
#     my $s = shift; my $pred = shift; # Bunsetsu
#     my $case = shift; # GA, WO, NI

#     my @b = @{$s->Bunsetsu}; my $b_num = @b;

#     # $pred�η�����/���긵��%dep����Ͽ
#     my %dep = ();
#     $dep{$pred->dep->bid} = 1 if (ref($pred->dep) eq 'Bunsetsu');
#     my @dtr = @{$pred->dtr};
#     for my $d (@dtr) {
# 	$dep{$d->bid} = 1;
#     }

#     my %out = ();
#     for (my $bid=0;$bid<$b_num;$bid++) {
# 	my $ant = $b[$bid];
# 	next if ($dep{$ant->bid}); # ����ط��ˤ���ʸ��Ͻ���

# 	# ̾��ʳ��Ͻ�����
# 	# ��������ȱ��ʤɤξ��ˤ��ѹ����ʤ���Фʤ�ʤ�
# 	next unless ($ant->NOUN);  
# 	next unless ($ant->ID);


# 	my $val = ($ant->ID and 
# 		   $ant->ID eq $pred->{$case})? '+1' : '-1';
#  	my $out = &ext_bact_format_sub($s, $pred, $ant, $case);
# 	$out{$val.' '.$out} = 1;
#     }
#     return keys %out;
# }
    
# sub ext_bact_format_sub {
#     my $s = shift; my $pred = shift; my $ant = shift;
#     my $case = shift; # GA, WO, NI

#     my $flg = 1; my @list = ($pred);
    
#     while ($flg) {
# 	my $b = shift @list;
# 	unshift if (ref($b->dep) eq 'Bunsetsu');
# 	unshift @chk, @{$pred->dtr};
#     }
# #     my @b = @{$s->Bunsetsu}; my $b_num = @b;
# #     my $p_num = 0; my $out = '';
# #     for (my $bid=$b_num-1;$bid>=0;$bid--) {
# # 	my $b = $b[$bid];
# #     }
# }

sub fe2num {
    my $fe = shift; my $f2n = shift;
    my @num = ();
    for my $f (split ' ', $fe) {
	my ($fname, $fval) = split '\:', $f;
	push @num, $f2n->{$fname}.':'.$fval if ($f2n->{$fname});
    }
    return join ' ', @num;
}

sub ext_bact_format { 
    my $s = shift; my $pred = shift; # Bunsetsu
    my $case = shift; # GA, WO, NI
    my $cl = shift; # Center List
    my $logref = shift; 

    my @b = @{$s->Bunsetsu}; my $b_num = @b;

    # $pred�η�����/���긵��%dep����Ͽ
    my %dep = ();
    $dep{$pred->dep->bid} = 1 if (ref($pred->dep) eq 'Bunsetsu');
    my @dtr = @{$pred->dtr};
    for my $d (@dtr) {
	$dep{$d->bid} = 1;
    }

    my %out = ();
    for (my $bid=0;$bid<$b_num;$bid++) {
	my $ant = $b[$bid];
	next if ($dep{$ant->bid}); # ����ط��ˤ���ʸ��Ͻ���

	# ̾��ʳ��Ͻ�����
	# ��������ȱ��ʤɤξ��ˤ��ѹ����ʤ���Фʤ�ʤ�
	next unless ($ant->NOUN);  

	next unless ($ant->ID);


	my $val = ($ant->ID and 
		   $ant->ID eq $pred->{$case})? '+1' : '-1';
# 	print STDERR $val, "\t", $case, ' ', $ant->ID, ' ',
# 		   $pred->{$case}, "\n";
	my $fe = &ext_bact_format_one($pred, $ant, $s, $case, $cl, $logref);
#  	my $out = &ext_bact_format_one($s, $pred, $ant, $case);
#  	print $val.' '.$out."\n";
# 	my $fe = &ext_fe($pred, $ant, $case, $cl, $logref);
	$out{$val.' '.$fe} = 1;
    }
    return keys %out;
}

sub ext_bact_format_one {
    my $pred = shift; my $ant = shift;
    my $s = shift; my $case = shift;
    my $cl = shift; my $logref = shift;

    my $out = &ext_structure($s, $pred, $ant, $case);
    my $fe = &ext_fe($pred, $ant, $case, $cl, $logref);
    return '(~ROOT'.$out.$fe.')';
}


sub ext_structure {
    my $s = shift; my $pred = shift; my $ant = shift;
    my $case = shift; # GA, WO, NI
    
    my @b = @{$s->Bunsetsu}; my $b_num = @b;
    my $p_num = 0; my $out = '';
    for (my $bid=$b_num-1;$bid>=0;$bid--) {
	my $b = $b[$bid];


# 	$out .= '('.&ext_bunsetsu_info($b, $pred, $ant).')';
#  	$out .= 'A'.$b->DEPTH;

#  	$out .= $b->DEPTH.':'.$b->bid;
	my $tmp = &ext_bunsetsu_info($b, $pred, $ant);
	$tmp .= '(BOS)' if ($b->bid == 0);
# 	$tmp = '('.$tmp.')';
	$out .= $tmp;
#  	$out = &ext_bunsetsu_info($b, $pred, $ant);
# 	$out = 
# 	$out = '('.$out.')';

#  	if ($bid > 1 and $b[$bid]->DEPTH < $b[$bid-1]->DEPTH) {
 	if ($bid > 0) {
# 	    $out .= '( ';
	    my $dif = $b[$bid]->DEPTH - $b[$bid-1]->DEPTH;
	    if ($dif > 0) {
		for (0..$dif) { $out .= ')'; $p_num--; }
 	    } elsif ($dif == 0) {
#  		$out .= ')(';
 		$out .= ')'; $p_num--;
	    }
	    $out .= '('; $p_num++;
	}
    }
    for (0..$p_num-1) { $out .= ')'; };
    $out = '(EOS('.$out.'))';
    return $out;
}

# ʸ�����Ի����ĥ�����̾�����ĽҸ��mark
sub mark_zero {
    my $t = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;

	# %s �ˤ�ʸ��˽и����Ƥ���ID���ͤ������
	my %s = ();
	for (my $Bid=0;$Bid<$b_num;$Bid++) {
	    my $B = $b[$Bid];
	    $s{$B->ID} = 1 if ($B->ID and $B->NOUN); 
	}

	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];

	    # PRED_ID ���Ф���
	    next unless ($b->PRED_ID);

	    # %dep �ˤϷ�����/���긵,Ʊ��ʸ���ID���ͤ������
	    my %dep = ();
	    $dep{$b->dep->ID} = 1 if (ref($b->dep) eq 'Bunsetsu' and
				      $b->dep->ID);
	    for my $d (@{$b->dtr}) {
		$dep{$d->ID} = 1 if ($d->ID);
	    }
	    $dep{$b->ID} = 1 if ($b->ID);

	    for my $case (('GA', 'WO', 'NI')) {
		my $ln = $b->{$case}; next unless ($ln);
		
		# %dep�����äƤ��餺��%s�����äƤ������mark
		if (!$dep{$ln} and $s{$ln}) {
		    $b->{'ZERO_'.$case} = 1;
		}
	    }
	}
    }
    return;
}

sub mark_inter_zero {
    my $t = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;

    my %s = (); # ��ʸ�ޤǤ˽и����Ƥ�������ID��ä���
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
	    next unless ($b->PRED_ID);
	    
	    my %dep = (); 
	    $dep{$b->dep->ID} = 1 if ($b->has_dep and $b->dep->ID);
	    for my $d (@{$b->dtr}) { $dep{$d->ID} = 1 if ($d->ID); }
	    $dep{$b->ID} = 1 if ($b->ID);

	    for my $case ('GA', 'WO', 'NI') {
		my $ln = $b->{$case}; next unless ($ln);
		# %dep �����äƤ��餺��%s�����äƤ������mark
		if (!$dep{$ln} and $s{$ln}) {
		    $b->{'ZERO_INTER_'.$case} = 1;
		}
	    }
	}

	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
# 	    $s{$b->ID} = 1 if ($b->ID and $b->NOUN);
 	    $s{$b->ID} = 1 if ($b->ID); # and $b->NOUN);
	}
    }
    return;
}

sub ext_bunsetsu_info {
    my $b = shift;
    my $pred = shift; my $ant = shift;
    my $out = '';

#     $out = '(~BOS)' if ($b->bid == 0);
    my @m = @{$b->Mor}; my $m_num = @m;

    # ʸ��ξ���򤽤줾�� ( ) �ǳ�ä��֤�
    if ($b->bid == $pred->bid) { # $b���Ҹ�ξ��
	$out = '(PRED'.$out.')';
	if ($b->head != $m_num-1) {
	    for (my $mid=$b->head+1;$mid<$m_num;$mid++) {
		$out = '('.$m[$mid]->BF.$out.')';
	    }
	}
    } elsif ($b->bid == $ant->bid) { # %b����Ի�(����)�ξ��
	$out = '(ANT'.$out.')';
	if ($b->head != $m_num-1) {
	    for (my $mid=$b->head+1;$mid<$m_num;$mid++) {
		$out = '('.$m[$mid]->BF.$out.')';
	    }
	}
    } else {

	# �缭���ʻ�Ȥ�����Ƥߤ�
  	$out = '('.(split '-', $b->HEAD_POS)[0].')';
# # 	my @tmp = ();
# #  	push @tmp, '('.(split '-', $b->HEAD_POS)[0].')';
# # 	push @tmp, '('.$b->HEAD_BF.')';

	if ($b->head != $m_num-1) {
	    for (my $mid=$b->head+1;$mid<$m_num;$mid++) {
		my $m = $m[$mid];
 		$out = '('.$m->BF.$out.')';

	    }
 	}
# # 	$out = join '', @tmp;
# # ���Ȥ��᤹
# 	for (my $mid=0;$mid<$m_num;$mid++) {
# 	    my $m = $m[$mid];
# 	    $out = '('.$m->BF.$out.')';
# 	}
    }
    $out =~ s/^\((.+)\)$/$1/;
    return $out;
}

sub ext_candidates {
    my $s = shift; my $pred = shift;
    my @b = @{$s->Bunsetsu}; my $b_num = @b;
    my @c = ();

    my %dep = ();
    for (@{$pred->dtr}) {
	$dep{$_->bid} = 1;
    }
    $dep{$pred->dep->bid} = 1 if (ref($pred->dep) eq 'Bunsetsu');

    for (my $bid=0;$bid<$b_num;$bid++) {
	my $b = $b[$bid];
	next if ($b->bid == $pred->bid); # �оݤȤʤ�Ҹ�Ͻ���
	if ($b->PRED_ID) {
	    # �Ҹ�ȷ���ط��ˤ���GA,WO,NI��ä���ȡ�
	    # ��Ȥ�ȷ��äƤ������Ƚ�ʣ���뤳�Ȥˤʤ�Τǡ�
	    # ���ξ��Ͻ�����

 	    for my $type (('GA', 'WO', 'NI')) {
		
		if ($b->{$type.'_b'} and # $b �� GA �������
		    !$dep{$b->{$type.'_b'}->bid} and # GA �� $b ����ط��ˤʤ�
		    $b->{$type.'_b'}->NOUN) { # ̾��Ǥ�����
		    my $z = $b->{$type.'_b'}; my $flg = 1;
		    if (ref($z->dep) eq 'Bunsetsu') {
			my @dtr = @{$z->dep->dtr};
			for my $dtr (@dtr) {
			    # ����ط��ˤ����Τ������
 			    $flg = 0 if ($dtr->bid eq $z->bid_org);
			}
		    }
		    push @c, $b->{$type.'_b'} if ($flg);
		}
	    }
	}
	push @c, $b if (!$dep{$b->bid} and $b->NOUN);
    }

    # ʸ������ʸƬ�ν��
    return reverse @c;
}

sub ext_candidates_including_dep {
    my $s = shift; my $pred = shift;
    my @b = @{$s->Bunsetsu}; my $b_num = @b;
    my @c = ();

    my %except = ();
    for my $type ('GA', 'WO', 'NI') {
	next unless ($pred->{$type});
	my $c = $pred->{$type};
	$except{$c->sid.':'.$c->bid} = 1;
    }

    for (my $bid=0;$bid<$b_num;$bid++) {
	next if ($b[$bid]->bid == $pred->bid); # �оݤȤʤ�Ҹ�Ͻ���
	next if ($except{$b[$bid]->sid.':'.$b[$bid]->bid});
	push @c, $b[$bid] if ($b[$bid]->NOUN);
    }

    return reverse @c;
}

sub ext_inter_candidates {
    my $t = shift; my $pred = shift;
    return () if ($pred->sid == 0);

    my %except = ();
    for my $type ('GA', 'WO', 'NI') {
	next unless ($pred->{$type});
	my $c = $pred->{$type};
	$except{$c->sid.':'.$c->bid} = 1;
    }

    my @c = ();
    my @s = @{$t->Sentence}; my $s_num = @s;
    for (my $sid=$pred->sid-1;$sid<$pred->sid;$sid++) {
	next if ($sid < 0);
	my @b = @{$s[$sid]->Bunsetsu}; my $b_num = @b;
 	for (my $bid=0;$bid<$b_num;$bid++) {
	    next if ($except{$b[$bid]->sid.':'.$b[$bid]->bid});
 	    push @c, $b[$bid] if ($b[$bid]->NOUN);
	}
    }
    return reverse @c;
}

sub ext_all_candidates {
    my $t = shift; my $pred = shift;
    my @s = @{$t->Sentence}; my $s_num = @s;
    my @c = ();

#     return () if ($pred->sid == 0);

    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	last if ($sid > $pred->sid);
	for (my $bid=0;$bid<$b_num;$bid++) {
# 	    return reverse @c 
# 		if ($sid == $pred->sid and $bid == $pred->bid);
	    my $b = $b[$bid];
	    if ($b->PRED_ID) {
		for my $type ('GA', 'WO', 'NI') {
		    if ($b->{$type.'_b'} and # $b ��������̾������
			$b->{$type.'_b'}->NOUN) { # ̾��Ǥ�����
			push @c, $b->{$type.'_b'};
		    }
		}
	    }
	    push @c, $b if ($b->NOUN);
	}
    }
    
    return reverse @c; # �Ҹ��ޤ�ʸ��ʸ���ޤ�
    die "check ext_all_candidates\n";
}

sub open_model_t_bact {
    my $dir = shift; my $type = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_t_\d_${type}\.bin/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_bact {
    my $dir = shift; my $type = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_\d_${type}\.bin/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_t2_bact {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_t2_\d\.bin/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_inter_t {
    my $dir = shift; my $type = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_inter_t_\d+_${type}\.bin$/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_all_t {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_all_t_\d+\.bin$/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_inter {
    my $dir = shift; my $type = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_inter_\d+_${type}\.bin$/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_all {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_all_\d+\.bin$/, readdir DIR;
    closedir DIR;

    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub ext_ants {
    my $pred = shift; my $case = shift; my @c = @_;
    my @tmp = ();
    for my $c (@c) {
	push @tmp, $c->tsb if ($c->ID and $c->ID eq $pred->{$case});
    }
    return join ',', @tmp;
}

sub ext_ant_b {
    my $pred = shift; my $case = shift; my @c = @_;
    my @tmp = ();
    for my $c (@c) {
	return $c if ($c->ID and $c->ID eq $pred->{$case});
    }
    return '';
}

sub check_dep_case {
    my $b = shift; my $case = shift;
    my $ln = $b->{$case};
    return 0 unless ($ln);

    my @dtr = @{$b->dtr};
    my @dep = @dtr;
    push @dep, $b->dep if (ref($b->dep) eq 'Bunsetsu');
    for my $dep (@dep) {
	return 1 if ($dep->ID and $dep->ID eq $ln);
    }
    return 0;
}

sub identify_ant_bact {
    my $pred = shift; my $s = shift; my $cl = shift;
    my $m = shift;
    my $dir = shift; my $T = shift;
    my @c = &ext_candidates($s, $pred);
    return -1 unless (@c);

    my $max_score = -10000; my $max_c; my $max_rule; my $max_fe;
    for my $c (@c) {
	my $fe;
	if ($T == 1) {
	    $fe = &ext_features_with_str($pred, $c, $cl, $s);
	} elsif ($T == 2) {
	    $fe = &ext_features_wo_str($pred, $c, $cl, $s);
	} elsif ($T == 3) {
	    $fe = &ext_features_with_str_flat($pred, $c, $cl, $s);
	} else {
	    die "set -T option with 1,2 or 3\n";
	}
	my $testfile = $dir.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `bact_classify -v 3 $testfile $m`;
	my $score = (split ' ', (split '\n', $r)[1])[1];
	my $rule = &ext_rules_from_bact_log($r);
	if ($max_score < $score) {
	    $max_score = $score; $max_c = $c;
	    $max_rule = $rule; $max_fe = $fe;
	}
    }
    return ($max_c, $max_score, $max_rule, $max_fe);
}

sub identify_ant_bact_tou {
    my $pred = shift; my $s = shift; my $cl = shift;
    my $m = shift; # model file
    my $dir = shift; my $T = shift;
    my @c = &ext_candidates($s, $pred); 
    return -1 unless (@c);

    my $ant = shift @c;
    my $c_num = @c; my $max_rule; my $max_fe;
    for (my $cid=0;$cid<$c_num;$cid++) {
	# right to left
	my $c = $c[$cid];

	my $fe = &ext_features_str_tou($pred, $ant, $c, $cl, $s);	
	# $c:left, $ant:right
# 	$fe = &ext_features_str_tou($pred, $c, $ant, $cl, $s); # �ۤ�ȤϤ��ä���make_ex_bact_tou.pl��񤭴ְ�ä����Τǡ�

	my $testfile = $dir.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `bact_classify -v 3 $testfile $m`;
	my $score = (split ' ', (split '\n', $r)[1])[1];
	my $rule = &ext_rules_from_bact_log($r);
	$ant = $c if ($score < 0);
	$max_rule = $rule if ($score < 0);
	$max_fe = $fe;
    }
    my $max_score = 0;
    return ($ant, $max_score, $max_rule, $max_fe);
}

sub ext_rules_from_bact_log {
    my $r = shift;
    my @r = split '\n', $r; 
    shift @r; # <instance>
    shift @r; # result
    my @rule = ();
    for my $rule (@r) {
	last if ($rule =~ m|</instance>|);
	push @rule, $rule;
    }
    return \@rule;
}

sub identify_ant_inter {
    my ($t, $pred, $case, $cl, $m, $f2n, $optref) = @_; # $case: GA, WO, NI
    my @c = &ext_inter_candidates($t, $pred);
    return '' unless (@c);
    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	# $c: left, $ant: right
	my $fe  = &ext_features_svm_inter_t($pred, $ant, $c, $cl, $t, $case, $optref);
	my $num = &fe2num($fe, $f2n);
	my $res = $m->classify($num);
# 	print STDERR $res, "\n";
	$ant = $c if ($res < 0);
    }
    return $ant;
}

sub identify_ant_inter_bact {
    my ($t, $pred, $case, $cl, $m, $optref) = @_; # $case: GA, WO, NI
    my @c = &ext_inter_candidates($t, $pred);
    return '' unless (@c);

    my $s = $t->Sentence->[$pred->sid];

    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	# $c: left, $ant: right
	my $fe  = &ext_features_comp($pred, $ant, $c, $cl, $s, $case, $optref);
	my $testfile = $optref->{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `bact_classify -v 3 $testfile $m`;
	my $res = (split ' ', (split '\n', $r)[1])[1];
	$ant = $c if ($res < 0);
    }
    return $ant;
}

sub determine_ana_inter {
    my ($t, $pred, $ant, $case, $cl, $m, $f2n, $optref) = @_; # $case: GA, WO, NI
    my $fe  = &ext_features_svm_inter($pred, $ant, $cl, $t, $case, $optref);
    my $num = &fe2num($fe, $f2n);
    my $res = $m->classify($num);
    return $res;
}

sub determine_ana_inter_bact {
    my ($t, $pred, $ant, $case, $cl, $m, $optref) = @_; # $case: GA, WO, NI
    my $s = $t->Sentence->[$pred->sid];
    my $fe  = &ext_features_one($pred, $ant, $cl, $s, $case, $optref);
    my $testfile = $optref->{d}.'/TMP_FE_DUMMY2';
    open 'TMP', '>'.$testfile or die $!;
    print TMP '+1 '.$fe."\n";
    close TMP;
    my $r = `bact_classify -v 3 $testfile $m`;
    my $res = (split ' ', (split '\n', $r)[1])[1];
    return $res;
}

sub identify_ant_all {
    my ($t, $pred, $case, $cl, $m, $f2n, $optref) = @_; # $case: GA, WO, NI
    my @c = &ext_all_candidates($t, $pred);
    return '' unless (@c);
    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	# $c: left, $ant: right
	my $fe  = &ext_features_svm_inter_t($pred, $ant, $c, $cl, $t, $case, $optref);
	my $num = &fe2num($fe, $f2n);
	my $res = $m->classify($num);
# 	print STDERR $res, "\n";
	$ant = $c if ($res < 0);
    }
    return $ant;
}

sub identify_ant_all_bact {
    my ($t, $pred, $case, $cl, $m, $optref) = @_; # $case: GA, WO, NI
    my @c = &ext_all_candidates($t, $pred);
    return '' unless (@c);

    my $s = $t->Sentence->[$pred->sid];

    my $ant = shift @c; my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	# $c: left, $ant: right
	my $fe  = &ext_features_comp($pred, $ant, $c, $cl, $s, $case, $optref);
	my $testfile = $optref->{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `bact_classify -v 3 $testfile $m`;
	my $res = (split ' ', (split '\n', $r)[1])[1];
	$ant = $c if ($res < 0);
    }
    return $ant;
}

sub determine_ana_all {
    my ($t, $pred, $ant, $case, $cl, $m, $f2n, $optref) = @_; # $case: GA, WO, NI
    my $fe  = &ext_features_svm_inter($pred, $ant, $cl, $t, $case, $optref);
    my $num = &fe2num($fe, $f2n);
    my $res = $m->classify($num);
    return $res;
}

sub determine_ana_all_bact {
    my ($t, $pred, $ant, $case, $cl, $m, $optref) = @_; # $case: GA, WO, NI
    
    my $s = $t->Sentence->[$pred->sid];

    my $fe  = &ext_features_one($pred, $ant, $cl, $s, $case, $optref);
    my $testfile = $optref->{d}.'/TMP_FE_DUMMY2';
    open 'TMP', '>'.$testfile or die $!;
    print TMP '+1 '.$fe."\n";
    close TMP;
    my $r = `bact_classify -v 3 $testfile $m`;
    my $res = (split ' ', (split '\n', $r)[1])[1];
    return $res;
}

sub ext_EQ2ID {
    my $t = shift; my @s = @{$t->Sentence}; my $s_num = @s;
    my %EQ2ID = ();
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid];
	    push @{$EQ2ID{$b->EQ}}, $b->ID if ($b->EQ and $b->ID);
	}
    }
    return \%EQ2ID;
}

sub open_model_t_svml {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_t_\d+\.t6$/, readdir DIR;
    closedir DIR;

#     print STDERR map "$_\n", @file;

    return @file;
}

sub open_model_svml {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /^model_\d+\.t6$/, readdir DIR;
    close DIR;

#     print STDERR map "$_\n", @file;

    return @file;
}

sub modify_fe_svml {
    my $fe = shift; my $f2n = shift;
    my ($tree, $FE) = split ' \|STD\| ', $fe;
    my @fe = split ' ', $FE;
    my @FE = ();
    for my $fe (@fe) {
	my ($fname, $fval) = split '\:', $fe;
	if ($f2n->{$fname}) {
	    my $fnum = $f2n->{$fname};
	    push @FE, $fnum.':'.$fval;
	}
    }
    return $tree.' |STD| '.join ' ', sort {(split '\:', $a)[0] <=> (split '\:', $b)[0]} @FE;
}

sub identify_antecedent_intra {
    my ($pred, $s, $case, $cl, $mt, $optref) = @_;
    my @c = &ext_candidates($s, $pred);
    return '' unless (@c);
    die "not exist candidates\n" unless (@c);

    my %ansbid = (); # ext_ans
    my $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	$ansbid{$c->bid} = 1 if ($c->ID and $pred->{$case} and $c->ID eq $pred->{$case});
    }

    my $ant = shift @c; $c_num = @c;
    for (my $cid=0;$cid<$c_num;$cid++) {
	my $c = $c[$cid];
	my $fe = &ext_features_comp($pred, $ant, $c, $cl, $s, $case, $optref);

	my $testfile = $optref->{d}.'/TMP_FE_DUMMY';
	open 'TMP', '>'.$testfile or die $!;
	print TMP '+1 '.$fe."\n";
	close TMP;
	my $r = `bact_classify -v 3 $testfile $mt`;

	my $score = (split ' ', (split '\n', $r)[1])[1];

# 	my $rule = &ext_rules_from_bact_log($r);
# 	push @log, $ant->bid.' '.$c->bid."\t".$score."\t".join "\t", @{$rule};
	
# 	push @wrg, $c if (defined $ansbid{$ant->bid} and $score < 0);
# 	push @wrg, $ant if (defined $ansbid{$c->bid} and $score > 0);

	$ant = $c if ($score < 0);
    }

    
#     return ($ant, \@log, \@wrg);
    return $ant;
}

sub open_model_intra_inter {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_three_\d+_intra_inter.bin/, readdir DIR;
    closedir DIR;
    
    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_intra_exo {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_three_\d+_intra_exo.bin/, readdir DIR;
    closedir DIR;
    
    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub open_model_inter_exo {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /model_three_\d+_inter_exo.bin/, readdir DIR;
    closedir DIR;
    
    my @m = ();
    for my $file (@file) {
# 	print STDERR 'open ', $file, "\n";
	push @m, $dir.'/'.$file;
    }
    return @m;
}

sub modify_fe {
    my $fe = shift;
    my ($val, @fe) = split ' ', $fe;
    my @out = ();
    for (@fe) {
	my ($fname, $fval) = split '\:', $_;
	push @out, '('.$fname.')';
    }
    return '(~ROOT'.join('', @out).')';
}

1;
