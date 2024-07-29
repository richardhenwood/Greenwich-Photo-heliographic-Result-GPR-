#!/usr/bin/perl -w  

use strict;


my $pi = 3.14159;

#values taken from matlab: evstat(0,1)
my $xbar = 0.5772;
my $sigma = 1.644;

for (my $i = -7.001; $i < 10; $i += 0.001) {
    #my $Px = exp(-$i) * exp(-exp(-$i));
    my $Px = exp(-$i-exp(-$i));
    my $cdf = exp(-exp(-$i));

    print "x = $i ";
    print "Px = $Px ";
    print " xminusxbarOverSigma = " . ($i - $xbar)/$sigma;
    print " PxTimesSigma = " . $Px*$sigma;
    print " CDF = " . $cdf;
    my $compCDF = 0;
    # for (my $j = $i; $j < 10; $j += 0.01) {
    #     my $Py = exp(-$j) * exp(-exp(-$j));
    #     $compCDF += $Py*0.01;
    # }
    print " compCDF = $compCDF ";
    print "\n";
}
