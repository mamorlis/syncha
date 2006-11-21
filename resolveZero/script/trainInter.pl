#!/bin/env perl 

use strict;
use warnings;
use Getopt::Std;

my $usage = <<USG;
./trainInter.pl -m modelsPath -T {GA,WO,NI}
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

my $modelsPath = $options{m};
my $type = $options{T};

system "bact_learn -L4 $modelsPath/fe_inter_t_0_${type} $modelsPath/model_inter_t_0_${type}";
