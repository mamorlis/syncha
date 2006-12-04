#! /usr/bin/env perl

#------------------------------------------------------
# 入力ファイルの文字コードはeuc-jpと仮定．
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
	"\xad\xa1" => '（１）',	"\xad\xa2" => '（２）',
	"\xad\xa3" => '（３）',	"\xad\xa4" => '（４）',
	"\xad\xa5" => '（５）',	"\xad\xa6" => '（６）',
	"\xad\xa7" => '（７）',	"\xad\xa8" => '（８）',
	"\xad\xa9" => '（９）',	"\xad\xaa" => '（１０）',
	"\xad\xab" => '（１１）',"\xad\xac" => '（１２）',
	"\xad\xad" => '（１３）',"\xad\xae" => '（１４）',
	"\xad\xaf" => '（１５）',"\xad\xb0" => '（１６）',
	"\xad\xb1" => '（１７）',"\xad\xb2" => '（１８）',
	"\xad\xb3" => '（１９）',"\xad\xb4" => '（２０）',
	"\xad\xb5" => 'Ｉ',	"\xad\xb6" => 'ＩＩ',
	"\xad\xb7" => 'ＩＩＩ',	"\xad\xb8" => 'ＩＶ',
	"\xad\xb9" => 'Ｖ',	"\xad\xba" => 'ＶＩ',
	"\xad\xbb" => 'ＶＩＩ',	"\xad\xbc" => 'ＶＩＩＩ',
	"\xad\xbd" => 'ＩＸ',	"\xad\xbe" => 'Ｘ',
	"\xad\xc0" => 'ミリ', "\xad\xc1" => 'キロ',
	"\xad\xc2" => 'センチ',	"\xad\xc3" => 'メートル', "\xad\xc4" => 'グラム',
	"\xad\xc5" => 'トン',	"\xad\xc6" => 'アール',
	"\xad\xc7" => 'ヘクタール',"\xad\xc8" => 'リットル',
	"\xad\xc9" => 'ワット',	"\xad\xca" => 'カロリー',
	"\xad\xcb" => 'ドル',	"\xad\xcc" => 'センチ',
	"\xad\xcd" => 'パーセント',	"\xad\xce" => 'ミリバール',
	"\xad\xcf" => 'ページ',	"\xad\xd0" => 'ｍｍ',
	"\xad\xd1" => 'ｃｍ',	"\xad\xd2" => 'ｋｍ',
	"\xad\xd3" => 'ｍｇ',	"\xad\xd4" => 'ｋｇ',
	"\xad\xd5" => 'ｃｃ',	"\xad\xd6" => '平方メートル',
	"\xad\xdc" => '平成',	"\xad\xe0" => '“',
	"\xad\xe1" => '”',	"\xad\xe2" => 'Ｎｏ．',
	"\xad\xe3" => 'Ｋ．Ｋ．',"\xad\xe4" => 'ＴＥＬ',
	"\xad\xe5" => '（上）',	"\xad\xe6" => '（中）',
	"\xad\xe7" => '（下）',	"\xad\xe8" => '（左）',
	"\xad\xe9" => '（右）',	"\xad\xea" => '（株）',
	"\xad\xeb" => '（有）',	"\xad\xec" => '（代）',
	"\xad\xed" => '明治',	"\xad\xee" => '大正',
	"\xad\xef" => '昭和',	"\xad\xf0" => '≒',
	"\xad\xf1" => '≡',	"\xad\xf2" => '∫',  
	"\xad\xf3" => 'ｃ∫',	"\xad\xf4" => 'Σ',
	"\xad\xf5" => '√',	"\xad\xf6" => '⊥',
	"\xad\xf7" => '∠',	"\xad\xf8" => '└',
	"\xad\xf9" => 'Δ',	"\xad\xfa" => '∵',
	"\xad\xfb" => '∩',	"\xad\xfc" => '∪',
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
              if($one !~ /^(?:。|！|？|．)/) {
                    #--- 後ろが括弧ならば切らない ---#
		    if($one eq ')' or $one eq '）' or $one eq '」' or $one eq '】') { $c .= $one }
                    #--- 後ろが数字ならば切らない ---#
		    elsif($one =~ /(:?[0-9]|$Zdigit)/) { $c .= $one }
		    else { push @s_array, $c; $c = $one; }
                    $flag = 0;
		}
	    } else {
                #---　機種依存文字を適当に変換 ---#
		if(exists $table{$one}) { $c .= $table{$one} }
		else {$c .= $one }
		$flag = 1 if($one eq '。' or $one eq '！' or $one eq '？' or $one eq '．');
	    }
	}
	push @s_array, $c;
        foreach my $k (@s_array) { print $k,"\n" if($k) }
    }
}
