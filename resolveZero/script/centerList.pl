#!/usr/local/bin/perl -w

use strict;

package Center;

sub new {
    my $type = shift;
    my $self = {};
    bless $self;
    
    return $self;
}

sub HA {
    my $self = shift;
    if (@_) {
	push @{$self->{HA}}, $_[0];
    } else {
	return $self->{HA};
    }
}

sub GA {
    my $self = shift;
    if (@_) {
	push @{$self->{GA}}, $_[0];
    } else {
	return $self->{GA};
    }
}

sub NI {
    my $self = shift;
    if (@_) {
	push @{$self->{NI}}, $_[0];
    } else {
	return $self->{NI};
    }
}

sub WO {
    my $self = shift;
    if (@_) {
	push @{$self->{WO}}, $_[0];
    } else {
	return $self->{WO};
    }
}

sub OTHER {
    my $self = shift;
    if (@_) {
	push @{$self->{OTHER}}, $_[0];
    } else {
	return $self->{OTHER};
    }
}

sub add {
    my $self = shift;
    my $b = shift;
    return unless ($b->NOUN);
    if ($b->CASE eq 'は') {
	$self->HA($b); $self->order($b, 1);
    } elsif ($b->CASE eq 'が') {
	$self->GA($b); $self->order($b, 2);
    } elsif ($b->CASE eq 'に') {
	$self->NI($b); $self->order($b, 3);
    } elsif ($b->CASE eq 'を') {
	$self->WO($b); $self->order($b, 4);
#     } elsif ($b->CASE eq '') { # その他はとりあえず使わない
    }
    return;
}

# sub add_rank {
    
# }

sub order { # 入力文節の順位を返す
    my $self = shift; my $b = shift; 
    if (@_) {
	my $order = shift;
	return '' unless ($b->NOUN);
	unshift @{$self->{order}->[$order]}, $b;
    } else {
	return '' unless (ref($self->{order}) eq 'ARRAY');
	for (my $i=1;$i<=$self->order_last;$i++) {
	    next unless ($self->{order}->[$i]);
	    my $B = $self->{order}->[$i]->[0];
	    die $! if (ref($B) ne 'Bunsetsu');
	    return $i if ($B->sid eq $b->sid and $B->bid eq $b->bid);
	}
	return '';
    }
}

sub rank {
    my $self = shift; my $b = shift;
    return '' unless (ref($self->{order}) eq 'ARRAY');
    my $rank = 1;
    for (my $i=0;$i<=$self->order_last;$i++) {
	next unless ($self->{order}->[$i]); # Listが空
	my $B = $self->{order}->[$i]->[0];
# 	print STDERR ref($B), "\n";
	return $rank if ($B->sid eq $b->sid and $B->bid eq $b->bid);
	$rank++; # Listに要素がある場合のみインクリメント
    }
    return '';
}

sub order_last {
    my $self = shift;
    return 4;
}

1;
