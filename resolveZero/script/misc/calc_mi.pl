#!/usr/local/bin/perl -w

use strict;
# use Getopt::Std;
use DB_File;

# my $miscPath = $ENV{PWD}.'/'.__FILE__; $miscPath =~ s|//|/|g;
my $miscPath = __FILE__; $miscPath =~ s|//|/|g;
$miscPath =~ s|/\./|/|g; $miscPath =~ s|[^/]+$||;
my $rootPath = $miscPath; $rootPath =~ s|[^/]+/$||; $rootPath =~ s|[^/]+/$||;
my $modelPath = $rootPath.'../dict/cooc/';
# print STDERR 'modelPath: ', $modelPath, "\n";
my $ncvtoolPath = $rootPath.'tools/ncvtool/';

my $Ndic = $modelPath.'n2id.db';
my $Vdic = $modelPath.'v2id.db';

tie my %Ndic, 'DB_File', $Ndic, O_RDONLY, 0444, $DB_BTREE or die $!;
tie my %Vdic, 'DB_File', $Vdic, O_RDONLY, 0444, $DB_BTREE or die $!;

# my $ncv2score;
# if ($host =~ /^vine/) {
#     $ncv2score = '/work2/ryu-i/zstruct/dat/ncv2score.gdbm';
# } else {
#     $ncv2score = '/work/ryu-i/zstruct/dat/ncv2score.gdbm';
# }

# tie my %ncv2score, 'GDBM_File', $ncv2score, GDBM_READER, 0644 or die $!;

package COOC;

use GDBM_File;

sub calc_mi_tmp {
# sub calc_mi {
    my $n = shift; my $v = shift; # each variable is 'Bunsetsu' class
    my $type = shift;
    my $c = ($type eq 'GA')? '¤¬': ($type eq 'WO')? '¤ò' : '¤Ë';
    my $nwf = &ext_nwf($n); my $vwf = $c.':'.&ext_vwf($v);
    my $nid = $Ndic{$nwf}; my $vid = $Vdic{$vwf};
    return '' unless ($nid); return '' unless ($vid);
    my $in = $nwf.':'.$vwf;

#     die $! if  ($host !~ /^fir/);
    my $ncv2score = '/work/ryu-i/zstruct/dat/ncv2scoreFIT2006.gdbm';
    tie my %ncv2score, 'GDBM_File', $ncv2score, GDBM_READER, 0644 or die $!;

#     my $score = $ncv2score{$ncv2score};
    my $score = $ncv2score{$in};

    untie %ncv2score;

    if ($score) {
	return '' if ($score eq '4294967295');
	return $score;
    } else {
	return 0;
    } 
}

# sub calc_mi_org {
sub calc_mi {
    my $n = shift; my $v = shift; # each variable is 'Bunsetsu' class
    my $type = shift; my $TYPE = shift;
    die "set MI/Cond/loglike\n" unless ($TYPE);
    my $c = ($type eq 'GA')? '¤¬': ($type eq 'WO')? '¤ò' : '¤Ë';
    my $nwf = &ext_nwf($n); my $vwf = $c.':'.&ext_vwf($v);
    my $nid = $Ndic{$nwf}; my $vid = $Vdic{$vwf};
    return '' unless ($nid); return '' unless ($vid);
    my $in = $nwf.':'.$vwf;

    my $tool = $ncvtoolPath.'/scorer';
    my $res = `echo \"$in\" | $tool -u 3 -d $modelPath/n1000 -m Pos -p $TYPE`; #"
    my $score = $res; $score =~ s/\n//g;
    return '' if ($score eq '4294967295');
    return $score;
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
    return '';
}

sub set_fe {
    my $n = shift; my $v = shift; my $type = shift; # GA,WO,NI
    my $TYPE = shift;
#     print STDERR $n->WF, "\t", $v->WF, "\n"; 
    my $score = &calc_mi($n, $v, $type, $TYPE);
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
