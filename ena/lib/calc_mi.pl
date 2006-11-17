#!/usr/local/bin/perl -w

use strict;
# use Getopt::Std;
#use CDB_File;
#use GDBM_File;
use DB_File;

use Carp qw(carp croak);

use ENA::Conf;
my $Ndic = "$ENV{ENA_DB_DIR}/n2id.db";
my $Vdic = "$ENV{ENA_DB_DIR}/v2id.db";

tie my %Ndic, 'DB_File', $Ndic, O_RDONLY, 0644, $DB_HASH
    or croak "Cannot open $Ndic:$!";
tie my %Vdic, 'DB_File', $Vdic, O_RDONLY, 0644, $DB_HASH
    or croak "Cannot open $Vdic:$!";

my $ncv2file = "$ENV{ENA_DB_DIR}/ncv2score.db";
tie my %ncv2score, 'DB_File', $ncv2file, O_RDONLY, 0644, $DB_HASH
    or croak "Cannot open $ncv2file:$!";

package COOC;

use Carp qw(carp croak);

sub calc_mi {
    my $n = shift; my $v = shift; # each variable is 'Bunsetsu' class
    my $type = shift;
    my %case = ( 'GA' => '��',
                 'WO' => '��',
                 'NI' => '��',
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
    $WF = '���ͭ̾��'.$1.'��' 
	if ($b->HEAD_POS =~ /^̾��-��ͭ̾��-(����|��̾|�ȿ�|�ϰ�)/);
    $WF = '���ͭ̾���̾��' if ($b->HEAD_NE =~ /PERSON/);
    $WF = '���ͭ̾���ϰ��' if ($b->HEAD_NE =~ /LOCATION/);
    $WF = '���ͭ̾���ȿ���' if ($b->HEAD_NE =~ /ORGANIZATION/);
    $WF = '���ͭ̾����̡�' if ($b->HEAD_NE =~ /ARTIFACT/);
    return $WF;
}

sub ext_vwf {
    my $b = shift;
    return $b->PRED if ($b->PRED);
    return $b->WF.'����';
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
