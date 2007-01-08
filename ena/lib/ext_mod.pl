#!/usr/local/bin/perl -w

# ===================================================================
my $NAME         = 'ext_mod.pl';
my $AUTHOR       = 'Ryu IIDA';
my $RCSID        = q$Id$;
my $PURPOSE      = '';
# ===================================================================

use strict;
use Getopt::Std;

my $usage = <<USG;
./ext_mod.pl -c cab_dir -t tgr_dir -o mod_dir
USG

my %options;
getopts("c:t:o:h", \%options);
die $usage if ($options{h});
die $usage unless ($options{c});
die $usage unless ($options{t});
die $usage unless ($options{o});

my $path = __FILE__; $path =~ s|[^/]+$||;
unshift @INC, $path; require 'tgr.pm'; require 'Cab.pm';

&main;

sub main {
    my $tgrref = &open_tgr_dir($options{t});
    my $txtref = &open_cab_dir($options{c});
    &make_mod($tgrref, $txtref);
    &output_mod($txtref);
}

sub make_mod {
    my $tgrref = shift;   my $txtref = shift;
    my @tgr = @{$tgrref}; my @t = @{$txtref}; my $t_num = @t;


    for (my $tid=0;$tid<$t_num;$tid++) {
	my $tgr = $tgr[$tid]; my $t = $t[$tid];
 	print STDERR $tid, ': ', ref($tgr), "\t", ref($t), "\n";
 	&make_mod_sub($tgr, $t);
    }
    return; 
}

sub make_mod_sub {
    my $tgr = shift; my $t = shift;

    my @s2tgr = &make_s2tgr($tgr);
    my $ln2exo = &ext_exo($tgr); # 外界の場所を抽出

    my %c2C = ('ガ'=>'GA', 'ヲ'=>'WO', 'ニ'=>'NI');

    # とりあえず文節単位で処理を行うことを前提に．

    # (1) ガヲニ格の場所を保持する
    my %pid2b = (); # pred_id => case_type => Bunsetsu
    my @s = @{$t->Sentence}; my $s_num = @s;
    my %sid2mtag = ();
    my $ID = 1;
    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid]; my @b = @{$s->Bunsetsu}; my $b_num = @b;
	my @tag = ($s2tgr[$sid])? @{$s2tgr[$sid]} : ();
	my @mtag = &modify_tag(\@tag); my $t_num = @mtag;
	my @cp_mtag = @mtag; $sid2mtag{$sid} = \@cp_mtag;
	my $len = 0;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; 
	    my @m = @{$b->Mor}; my $m_num = @m;
	    for (my $mid=0;$mid<$m_num;$mid++) {
		my $m = $m[$mid];
		$len += (length $m->WF)/2;

		for (my $tid=0;$tid<$t_num;$tid++) {
		    my $t = $mtag[$tid];
		    if ($t->end <= $len) {
			splice @mtag, $tid, 1; $tid--; $t_num--;
			if ($t->name =~ /^(ガ|ヲ|ニ)$/) {
			    # pred_id => case_type => Bunsetsu
			    $pid2b{$t->ln}{$c2C{$1}} = $m; 
			    $m->ID($ID++) unless ($m->ID);
			} elsif ($t->name eq '事態') {
			    $m->EVENT($t->id);
			    # 外界のタグを付与
			    if ($ln2exo->{$t->id}) {
				my %case2exo = %{$ln2exo->{$t->id}};
				while (my ($case, $exo) = each %case2exo) {
				    $m->{$case} = $exo; # EXO1, EXO2, EXOg, CREF
				}
			    }
 			} elsif ($t->name eq '述語') {
#  			    $b->PRED_ID($t->id);
 			    $m->PRED_ID($t->id);
 			    # 外界のタグを付与
 			    if ($ln2exo->{$t->id}) {
 				my %case2exo = %{$ln2exo->{$t->id}};
 				while (my ($case, $exo) = each %case2exo) {
 				    $m->{$case} = $exo; # EXO1, EXO2, EXOg, CREF
 				}
 			    }
 			}
		    }
		    # ここに「照応詞」「照応」とか追加可能．
		}
	    }
	}
    }

    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid];  my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; my @m = @{$b->Mor}; my $m_num = @m;
# 	    my $pid = $b->PRED_ID;
# 	    next if (!defined $pid);
	    for (my $mid=0;$mid<$m_num;$mid++) {
		my $m = $m[$mid];
		my $pid = $m->EVENT;
		next unless ($pid);
		if ($pid2b{$pid}) {
		    my %case2b = %{$pid2b{$pid}};
		    while (my ($case, $ln) = each %case2b) {
			if ($m->{$case}) {
			    print STDERR 'err: 同一の格に重複してタグが付与されている',
			    $case, "\t", $m->{$case}, ' tid:', $t->id, ' ', $m->WF, ' ', $s->STRING, "\n";
			}
			$m->{$case} = $ln->ID; # ガヲニ格のタグを埋める
		    }
		}
	    }

	}
    }

    for (my $sid=0;$sid<$s_num;$sid++) {
	my $s = $s[$sid];  my @b = @{$s->Bunsetsu}; my $b_num = @b;
	for (my $bid=0;$bid<$b_num;$bid++) {
	    my $b = $b[$bid]; my @m = @{$b->Mor}; my $m_num = @m;
# 	    my $pid = $b->PRED_ID;
# 	    next if (!defined $pid);
	    for (my $mid=0;$mid<$m_num;$mid++) {
		my $m = $m[$mid];
		my $pid = $m->PRED_ID;
		next unless ($pid);
		if ($pid2b{$pid}) {
		    my %case2b = %{$pid2b{$pid}};
		    while (my ($case, $ln) = each %case2b) {
			if ($m->{$case}) {
			    print STDERR 'err: 同一の格に重複してタグが付与されている',
			    $case, "\t", $m->{$case}, ' tid:', $t->id, ' ', $m->WF, ' ', $s->STRING, "\n";
			}
			$m->{$case} = $ln->ID; # ガヲニ格のタグを埋める
		    }
		}
	    }

	}
    }
    return;
}

sub make_s2tgr {
    my $tgr = shift; my @tag = @{$tgr->tags};
    my @s2tgr = ();
    for my $tag (@tag) {
	if ($tag->sid >= 2) {
	    push @{$s2tgr[$tag->sid - 3]}, $tag;
	    # tgrの3行目を sid=0 とする
	}
    }
    return @s2tgr;
}

# 外界の場所を抽出
sub ext_exo {
    my $tgr = shift; my @tag = @{$tgr->tags};
    my $ln2exo = {};

    #      76 [1.0, 1.11]  外界一人称
    #      60 [1.13, 1.24] 外界二人称
    #     269 [1.26, 1.36] 外界一般
    #      68 [1.38, 1.45] 節照応

    my %c2C = ('ガ'=>'GA', 'ヲ'=>'WO', 'ニ'=>'NI');

    for my $tag (@tag) {
	# ガヲニ格のみ
	next if ($tag->name ne 'ガ' and $tag->name ne 'ヲ' and $tag->name ne 'ニ');

	if ($tag->ln and $tag->loc eq '[1.0, 1.11]') {       # 外界一人称
	    $ln2exo->{$tag->ln}{$c2C{$tag->name}} = 'EXO1';
	} elsif ($tag->ln and $tag->loc eq '[1.13, 1.24]') { # 外界二人称
	    $ln2exo->{$tag->ln}{$c2C{$tag->name}} = 'EXO2';
	} elsif ($tag->ln and $tag->loc eq '[1.26, 1.36]') { # 外界一般
	    $ln2exo->{$tag->ln}{$c2C{$tag->name}} = 'EXOg';
	} elsif ($tag->ln and $tag->loc eq '[1.38, 1.45]') { # 節照応
	    $ln2exo->{$tag->ln}{$c2C{$tag->name}} = 'CREF';
	}
    }

    return $ln2exo;
}

sub modify_tag {
    my $tagref = shift; my @tag = @{$tagref}; my $t_num = @tag;
    for (my $tid=0;$tid<$t_num;$tid++) {
	my $t = $tag[$tid];
	if ($t->sid == 1 or $t->sid == 2) { # 外界のタグを削除
	    splice @tag, $tid, 1; $tid--; $t_num--;
	} elsif ($t->name =~ /^(?:|np|候補|サ変名詞)$/) {
	    
	} else { 
# 	    $tag[$tid]->sid($tag[$tid]->sid - 2);
	    $tag[$tid]->begin($tag[$tid]->begin - 5);
	    $tag[$tid]->end($tag[$tid]->end - 5);
	}
    }
    return @tag;
}

sub output_mod {
    my $txtref = shift; my @t = @{$txtref}; my $t_num = @t;

    for (my $tid=0;$tid<$t_num;$tid++) {
	my $t = $t[$tid];
	open 'OUT', '>'.$options{o}.'/'.$t->id.'.mod' or die $!;
	print OUT $t->puts_e;
	close OUT;
    }
    return;
}
