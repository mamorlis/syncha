#!/usr/bin/env perl

use strict;
use warnings;
BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

use Carp qw(carp croak);

use ENA::Conf;
my $Ndic      = "$ENV{ENA_DB_DIR}/n2id.db";
my $Vdic      = "$ENV{ENA_DB_DIR}/v2id.db";
my $ncv2score = "$ENV{ENA_DB_DIR}/ncv2score.db";

my (%Ndic, %Vdic, %ncv2score);
if (eval "require BerkeleyDB; 1") {
    tie %Ndic, 'BerkeleyDB::Hash',
        -Filename => $Ndic,
        -Flags    => DB_RDONLY,
        -Mode     => 0644
        or croak "Cannot open $Ndic:$!";
    tie %Vdic, 'BerkeleyDB::Hash',
        -Filename => $Vdic,
        -Flags    => DB_RDONLY,
        -Mode     => 0644
        or croak "Cannot open $Vdic:$!";
    tie %ncv2score, 'BerkeleyDB::Hash',
        -Filename => $ncv2score,
        -Flags    => DB_RDONLY,
        -Mode     => 0644,
        or croak "Cannot open $ncv2score:$!";
} elsif (eval "require DB_File; 1") {
    tie %Ndic, 'DB_File', $Ndic, O_RDONLY, 0644, $DB_HASH
        or croak "Cannot open $Ndic:$!";
    tie %Vdic, 'DB_File', $Vdic, O_RDONLY, 0644, $DB_HASH
        or croak "Cannot open $Vdic:$!";
    tie %ncv2score, 'DB_File', $ncv2score, O_RDONLY, 0644, $DB_HASH
        or croak "Cannot open $ncv2score:$!";
}

package COOC;

use Carp qw(carp croak);

sub calc_mi {
    my $n = shift; my $v = shift; # each variable is 'Bunsetsu' class
    my $type = shift;
    my %case = ( 'GA' => '¤¬',
                 'WO' => '¤ò',
                 'NI' => '¤Ë',
                );
    my $nwf = &ext_nwf($n);
    my $vwf = $case{$type}.':'.&ext_vwf($v);
    my $nid = $Ndic{$nwf};
    my $vid = $Vdic{$vwf};
    return '' unless ($nid or $vid);
    my $in = $nwf.':'.$vwf;

    my $score = $ncv2score{$in};
    if ($score) {
        return ($score eq '4294967295') ? '' : $score;
    } else {
        return 0;
    }
}

sub ext_nwf {
    my $b = shift;
    my $WF = $b->HEAD_WF;
    $WF = '¡ã¸ÇÍ­Ì¾»ì'.$1.'¡ä' 
	if ($b->HEAD_POS =~ /^Ì¾»ì-¸ÇÍ­Ì¾»ì-(°ìÈÌ|¿ÍÌ¾|ÁÈ¿¥|ÃÏ°è)/);
    $WF = '¡ã¸ÇÍ­Ì¾»ì¿ÍÌ¾¡ä' if ($b->HEAD_NE =~ /PERSON/);
    $WF = '¡ã¸ÇÍ­Ì¾»ìÃÏ°è¡ä' if ($b->HEAD_NE =~ /LOCATION/);
    $WF = '¡ã¸ÇÍ­Ì¾»ìÁÈ¿¥¡ä' if ($b->HEAD_NE =~ /ORGANIZATION/);
    $WF = '¡ã¸ÇÍ­Ì¾»ì°ìÈÌ¡ä' if ($b->HEAD_NE =~ /ARTIFACT/);
    return $WF;
}

sub ext_vwf {
    my $b = shift;
    return $b->PRED if ($b->PRED);
    return $b->WF.'¤¹¤ë';
}

sub set_fe {
    my $n = shift; my $v = shift; my $type = shift; # GA,WO,NI
#     print STDERR $n->WF, "\t", $v->WF, "\n"; 
    my $score = &calc_mi($n, $v, $type);
    return 0 unless ($score); 
    if ($score > 0) {
	my $val = ($score > 5)? 5 : ($score > 4)? 4 : ($score > 3)? 3 :
	    ($score > 2)? 2 : ($score > 1)? 1 : 0;
	return $val;
    } else {
	my $val = ($score < -5)? -5 : ($score < -4)? -4 : ($score < -3)? -3 :
	    ($score < -2)? -2 : ($score < -1)? 1 : 0;
	return $val;
    }
}

1;
