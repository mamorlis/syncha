#!/bin/env perl 

use strict;
use warnings;
use Getopt::Std;

my $usage = <<USG;
./mkmodelIntra2.pl -m modelsPath -T {GA,WO,NI}
USG

my %options;
getopts("m:T:h", \%options);
die $usage if ($options{h});
die $usage unless ($options{m});
die $usage unless ($options{T});

my $scriptPath = __FILE__; $scriptPath =~ s|//|/|g;
# my $scriptPath = $ENV{PWD}.'/'.__FILE__; 
$scriptPath =~ s|/\./|/|g; $scriptPath =~ s|[^/]+$||;
my $rootPath = $scriptPath; $rootPath =~ s|[^/]+/$||;
my $bactPath = $rootPath.'tools/bact-0.13/';

my $modelsPath = $options{m};
my $type = $options{T};

system "$bactPath/bact_mkmodel -i $modelsPath/model_0_${type} -o $modelsPath/model_0_${type}.bin -O $modelsPath/model_0_${type}.O";
