#!/usr/local/bin/perl -w

package PRONOUN;

use strict;
use DB_File;

# my $ZERO_DAT_PATH = $ENV{ZERO_DAT_PATH};

# my $miscPath = $ENV{PWD}.'/'.__FILE__; 
my $miscPath = __FILE__; $miscPath =~ s|//|/|g;
$miscPath =~ s|/\./|/|g; $miscPath =~ s|[^/]+$||;
my $rootPath = $miscPath; $rootPath =~ s|[^/]+/$||; $rootPath =~ s|[^/]+/$||;
my $dbPath = $rootPath.'../dict/db/';

my $pronoun = $dbPath.'/pronoun.db';
tie my %pronoun, 'DB_File', $pronoun, O_RDONLY, 0444, $DB_HASH or die $!;

sub check_pronoun_type {
    my $bunsetsu = shift;
    my $noun = $bunsetsu->HEAD_NOUN;
    my $pos  = $bunsetsu->HEAD_POS;
    my $in   = $noun.':'.$pos;
    return ($pronoun{$in})? $pronoun{$in} : '';
}

# test
if ($0 eq __FILE__) {
    my $noun = 'それ:名詞-代名詞-一般';
    print $pronoun{$noun}, "\n";
}

1;
