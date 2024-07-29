#!/usr/bin/perl -w  

use strict;
use Getopt::Std;
use Math::Trig;


sub usage {
    print STDERR <<EOF;
this program generates gumbel numbers. 
It generates 'standardadized' values.

-m #    : mu, default = 0; 
-v #    : var, default = 1;
-n #    : number of values to generate (default = 100)

example:
$0 -m 0 -v 1
EOF
    exit 0;
}

my %opts = ();
getopts("m:v:n:", \%opts);
my $mean = 0;
my $var = 1;
if (defined($opts{m})) { $mean = $opts{m}; }
if (defined($opts{v})) { $var = $opts{v}; }


my $xbar = &getMean($mean, $var);
my $sigma = &getSigma($mean, $var);
print STDERR "xbar = $xbar, sigma = $sigma\n";

for (my $i = 0.001; $i < 20; $i += 0.001) {
    my $Px = &getPx($i);# exp(-$i) * exp(-exp(-$i));
    my $cdf = exp(-exp(-$i));

    print "x = $i ";
    print "Px = $Px ";
    print " xminusxbarOverSigma = " . ($i - $xbar)/$sigma;
    print " PxTimesSigma = " . $Px*$sigma;
    print "\n";

    #print " CDF = " . $cdf;
    #my $compCDF = 0;
    # for (my $j = $i; $j < 10; $j += 0.01) {
    #     my $Py = exp(-$j) * exp(-exp(-$j));
    #     $compCDF += $Py*0.01;
    # }
    #print " compCDF = $compCDF ";
}

sub getPx {
    my $x = shift;
    my $Px = exp(-((log($x))**2)/2)/($x*(sqrt(2*pi)));
    return $Px;
}

sub getMean {
    my ($mu, $sig) = @_;
    return exp($mu+(($sig**2)/2));
    #return $mu + 0.5772*$sig;
}

sub getSigma {
    my ($mu, $sig) = @_;
    my $var = (exp($sig**2)-1)*exp(2*$mu+$sig**2);
    return sqrt($var);
}

1;
