#!/usr/local/bin/perl -w

use strict;

sub open_tgr_file {
    my $file = shift;
    open 'FL', $file or die $!;
    
    $/ = "</text>\n"; my @tgr = ();
    while (<FL>) {
	chomp; my $tgr = Tgr->new($_);
	push @tgr, $tgr;
    }
    $/ = "\n";
    return \@tgr;
}

sub open_tgr_dir {
    my $dir = shift;
    opendir 'DIR', $dir or die $!;
    my @file = sort grep /tgr$/, readdir DIR;
    closedir DIR;

    my @tgr = ();
    for my $file (@file) {
 	my $tmp = &open_tgr_file($dir.'/'.$file);
 	push @tgr, @{$tmp};
    }
    return \@tgr;
}

package Tgr; 

sub new {
    my $type = shift; my $in = shift;
    my $self = {}; bless $self;

    my @in = split '\n', $in;

    my $textid = shift @in;
    $self->id($1) if ($textid =~ m|<text id=(\d+)>|);
    
    my $a_flg = 0; my $t_flg = 0; my @tag = ();
    my @cnt = (); my $c_flg = 0; my $attr = '';
    my $l_flg = 0; my $lastid = '';
    for my $i (@in) {
	if ($i =~ m|</contents>|) {
	    $self->contents(\@cnt); $c_flg = 0;
	} elsif ($i =~ m|<contents>|) {
	    $c_flg = 1;
	} elsif ($i =~ m|</attribute>|) {
	    $self->attribute($attr); $a_flg = 0;
	} elsif ($i =~ m|<attribute>|) {
	    $a_flg = 1;
	} elsif ($i =~ m|</tags>|) {
	    $self->tags(\@tag); $t_flg = 0;
	} elsif ($i =~ m|<tags>|) {
	    $t_flg = 1;
	} elsif ($i =~ m|</lastid>|) {
	    $self->lastid($lastid);
	    $l_flg = 0;
	} elsif ($i =~ m|<lastid>|) {
	    $l_flg = 1;
	} elsif ($c_flg) {
	    push @cnt, $i;
	} elsif ($a_flg) {
	    $attr = $i;
	} elsif ($t_flg) {
	    push @tag, Tag->new($i);
	} elsif ($l_flg) {
	    $lastid = $i;
	}
    }

    # added in 2005-12-15(Thu)
    my @CNT = @{$self->contents}; my $c_num = @CNT; my @TAG = @{$self->tags}; my $t_num = @TAG;
    for (my $i=0;$i<$c_num;$i++) {
 	if ($CNT[$i] =~ /<\[((?:..)+?)\]>/) {
	    my $cnt = $CNT[$i]; $cnt =~ s/\(\d+\) //; my $len = 5;
	    while ($cnt =~ /<\[((?:..)+?)\]>/) {
		my $pre = $`; my $blk = $1; $cnt = $'; #'
		$len += length($pre)/2; my $begin = $len; $len += 4; # ³ç¸Ì¤Î¿ô¤ò¹ÍÎ¸
		$len += length($blk)/2;
		my $minus = $len - $begin; 
		for (my $tid=0;$tid<$t_num;$tid++) {
		    if ($TAG[$tid]->sid-1 == $i and $TAG[$tid]->begin == ($begin +2)) {
			$TAG[$tid]->begin($TAG[$tid]->begin - (2+(length($blk)/2)));
			$TAG[$tid]->end($TAG[$tid]->end - (2+(length($blk)/2)));
			$TAG[$tid]->loc('['.$TAG[$tid]->sid.'.'.$TAG[$tid]->begin.', '.$TAG[$tid]->sid.'.'.$TAG[$tid]->end.']');
		    } elsif ($TAG[$tid]->sid-1 == $i and $TAG[$tid]->begin > $begin) {
			$TAG[$tid]->begin($TAG[$tid]->begin - $minus);
			$TAG[$tid]->end($TAG[$tid]->end - $minus);
			$TAG[$tid]->loc('['.$TAG[$tid]->sid.'.'.$TAG[$tid]->begin.', '.$TAG[$tid]->sid.'.'.$TAG[$tid]->end.']');
		    }
		}
		$len -= $minus;
	    }

# 	    while ($cnt =~ /((?:<\[((?:..)+?)\]>)+)/) {
# 		my $pre = $`; my $blk = $1; $cnt = $'; #'
# 		$len += length($pre)/2; my $begin = $len; $blk =~ s/^<\[(.+)\]>$/$1/; $len += 4;
# 		print STDERR 'blk', $blk, "\n";
# 		print STDERR 'begin: ', $begin, "\n";
# 		my @tmp = split '\]><\[', $blk;
# 		$len += 4*(scalar(@tmp)-1);
# 		for my $tmp (@tmp) { $len += length($tmp)/2; }
# 		my $minus = $len - $begin; 
# 		for (my $tid=0;$tid<$t_num;$tid++) {
# 		    if ($TAG[$tid]->sid-1 == $i and $TAG[$tid]->begin > $begin) {
# 			$TAG[$tid]->begin($TAG[$tid]->begin - $minus);
# 			$TAG[$tid]->end($TAG[$tid]->end - $minus);
# 			$TAG[$tid]->loc('['.$TAG[$tid]->sid.'.'.$TAG[$tid]->begin.', '.$TAG[$tid]->sid.'.'.$TAG[$tid]->end.']');
# 		    }
# 		}
# 	    }
	}
    }
    $self->contents(\@CNT);
    $self->tags(\@TAG);


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

sub contents {
    my $self = shift;
    if (@_) {
	$self->{contents} = $_[0];
    } else {
	return $self->{contents};
    }
}

sub attribute {
    my $self = shift; 
    if (@_) {
	$self->{attribute} = $_[0];
    } else {
	return $self->{attribute};
    }
}

sub lastid {
    my $self = shift;
    if (@_) {
	$self->{lastid} = $_[0];
    } else {
	return $self->{lastid};
    }
}

sub tags {
    my $self = shift;
    if (@_) {
	$self->{tags} = $_[0];
    } else {
	return $self->{tags};
    }
}

##################################################
package Tag;

sub new {
    my $type = shift; my $self = {};
    bless $self;
    my $in = shift;
    $self->org($in); ##
    my ($name, $tmp, $loc, $ids) = split '\t', $in;
    $self->name($name); $self->tmp($tmp);
    $self->loc($loc); 
    $loc =~ /\[(\d+)\.(\d+), \d+.(\d+)\]/;
    $self->sid($1); $self->begin($2); $self->end($3);

    if ($ids =~ /id=([^;]+);/) { $self->id($1); }
    if ($ids =~ /ln=([^;]+);/) { $self->ln($1); }

    return $self;
}

sub org {
    my $self = shift;
    if (@_) {
	$self->{org} = $_[0];
    } else {
	return $self->{org};
    }
}

sub name {
    my $self = shift;
    if (@_) {
	$self->{name} = $_[0];
    } else {
	return $self->{name};
    }
}

sub tmp {
    my $self = shift;
    if (@_) {
	$self->{tmp} = $_[0];
    } else {
	return $self->{tmp};
    }
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{id} = $_[0];
    } else {
	return $self->{id};
    }
}

sub ln {
    my $self = shift;
    if (@_) {
	$self->{ln} = $_[0];
    } else {
	return $self->{ln};
    }
}

sub exists_id {
    my $self = shift;
    return ($self->{id})? 1 : 0;
}

sub exists_ln {
    my $self = shift;
    return ($self->{ln})? 1 : 0;
}

sub loc {
    my $self = shift;
    if (@_) {
	$self->{loc} = $_[0];
    } else {
	return $self->{loc};
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

sub begin {
    my $self = shift;
    if (@_) {
	$self->{begin} = $_[0];
    } else {
	return $self->{begin};
    }
}

sub end {
    my $self = shift;
    if (@_) { 
	$self->{end} = $_[0];
    } else {
	return $self->{end};
    }
}

1;
