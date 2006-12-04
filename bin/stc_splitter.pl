#! /usr/bin/env perl

#------------------------------------------------------
# ���ϥե������ʸ�������ɤ�euc-jp�Ȳ��ꡥ
# ./stc_splitter.pl < file.euc
#------------------------------------------------------

use strict;
use warnings;

use Getopt::Std;
use vars qw($opt_h);

my $usage =<<"USAGE";
This scirpt reads input from stdin.
USAGE

getopts('h');
die $usage if $opt_h;

my $ascii = '[\x00-\x7F]';
my $twoBytes = '[\x8E\xA1-\xFE][\xA1-\xFE]';
my $undef = '[\xA9-\xAF\xF5-\xFE][\xA1-\xFE]';
my $Zdigit = '(?:\xA3[\xB0-\xB9])';
my $Zspace = '(?:\xA1\xA1)'; # EUC-JP

my %table = (
	"\xad\xa1" => '�ʣ���',	"\xad\xa2" => '�ʣ���',
	"\xad\xa3" => '�ʣ���',	"\xad\xa4" => '�ʣ���',
	"\xad\xa5" => '�ʣ���',	"\xad\xa6" => '�ʣ���',
	"\xad\xa7" => '�ʣ���',	"\xad\xa8" => '�ʣ���',
	"\xad\xa9" => '�ʣ���',	"\xad\xaa" => '�ʣ�����',
	"\xad\xab" => '�ʣ�����',"\xad\xac" => '�ʣ�����',
	"\xad\xad" => '�ʣ�����',"\xad\xae" => '�ʣ�����',
	"\xad\xaf" => '�ʣ�����',"\xad\xb0" => '�ʣ�����',
	"\xad\xb1" => '�ʣ�����',"\xad\xb2" => '�ʣ�����',
	"\xad\xb3" => '�ʣ�����',"\xad\xb4" => '�ʣ�����',
	"\xad\xb5" => '��',	"\xad\xb6" => '�ɣ�',
	"\xad\xb7" => '�ɣɣ�',	"\xad\xb8" => '�ɣ�',
	"\xad\xb9" => '��',	"\xad\xba" => '�֣�',
	"\xad\xbb" => '�֣ɣ�',	"\xad\xbc" => '�֣ɣɣ�',
	"\xad\xbd" => '�ɣ�',	"\xad\xbe" => '��',
	"\xad\xc0" => '�ߥ�', "\xad\xc1" => '����',
	"\xad\xc2" => '�����',	"\xad\xc3" => '�᡼�ȥ�', "\xad\xc4" => '�����',
	"\xad\xc5" => '�ȥ�',	"\xad\xc6" => '������',
	"\xad\xc7" => '�إ�������',"\xad\xc8" => '��åȥ�',
	"\xad\xc9" => '��å�',	"\xad\xca" => '����꡼',
	"\xad\xcb" => '�ɥ�',	"\xad\xcc" => '�����',
	"\xad\xcd" => '�ѡ������',	"\xad\xce" => '�ߥ�С���',
	"\xad\xcf" => '�ڡ���',	"\xad\xd0" => '���',
	"\xad\xd1" => '���',	"\xad\xd2" => '���',
	"\xad\xd3" => '���',	"\xad\xd4" => '���',
	"\xad\xd5" => '���',	"\xad\xd6" => 'ʿ���᡼�ȥ�',
	"\xad\xdc" => 'ʿ��',	"\xad\xe0" => '��',
	"\xad\xe1" => '��',	"\xad\xe2" => '�Σ',
	"\xad\xe3" => '�ˡ��ˡ�',"\xad\xe4" => '�ԣţ�',
	"\xad\xe5" => '�ʾ��',	"\xad\xe6" => '�����',
	"\xad\xe7" => '�ʲ���',	"\xad\xe8" => '�ʺ���',
	"\xad\xe9" => '�ʱ���',	"\xad\xea" => '�ʳ���',
	"\xad\xeb" => '��ͭ��',	"\xad\xec" => '�����',
	"\xad\xed" => '����',	"\xad\xee" => '����',
	"\xad\xef" => '����',	"\xad\xf0" => '��',
	"\xad\xf1" => '��',	"\xad\xf2" => '��',  
	"\xad\xf3" => '���',	"\xad\xf4" => '��',
	"\xad\xf5" => '��',	"\xad\xf6" => '��',
	"\xad\xf7" => '��',	"\xad\xf8" => '��',
	"\xad\xf9" => '��',	"\xad\xfa" => '��',
	"\xad\xfb" => '��',	"\xad\xfc" => '��',
);

&main;

sub main {
    sentence_splitter();
}

#----------------------------------------------------------------------------------------------------
sub sentence_splitter {
    while(my $stc = <>) {
	chomp($stc);
	my @s_array = (); my $c = '';
	my $flag = 0;
	while($stc =~ /($twoBytes|$ascii|$undef)/) {
	    $stc = $';
	    my $one = $1;
	    if($flag) {
              if($one !~ /^(?:��|��|��|��)/) {
                    #--- �����̤ʤ���ڤ�ʤ� ---#
		    if($one eq ')' or $one eq '��' or $one eq '��' or $one eq '��') { $c .= $one }
                    #--- ��������ʤ���ڤ�ʤ� ---#
		    elsif($one =~ /(:?[0-9]|$Zdigit)/) { $c .= $one }
		    else { push @s_array, $c; $c = $one; }
                    $flag = 0;
		}
	    } else {
                #---�������¸ʸ����Ŭ�����Ѵ� ---#
		if(exists $table{$one}) { $c .= $table{$one} }
		else {$c .= $one }
		$flag = 1 if($one eq '��' or $one eq '��' or $one eq '��' or $one eq '��');
	    }
	}
	push @s_array, $c;
        foreach my $k (@s_array) { print $k,"\n" if($k) }
    }
}
