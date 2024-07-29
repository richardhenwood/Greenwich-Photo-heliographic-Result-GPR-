#!/usr/bin/perl -w  

use strict;


my $pi = 3.14159;

for (my $i = -7.001; $i < 10; $i += 0.001) {
    my $Px = exp(-$i) * exp(-exp(-$i));
    my $cdf = exp(-exp(-$i));

    print "x = $i ";
    print "Px = $Px ";
    print " xminusxbarOverSigma = " . ($i - 0.58)/1.28;
    print " PxTimesSigma = " . $Px*1.28;
    print " CDF = " . $cdf;
    my $compCDF = 0;
    for (my $j = $i; $j < 10; $j += 0.01) {
        my $Py = exp(-$j) * exp(-exp(-$j));
        $compCDF += $Py*0.01;
    }
    print " compCDF = $compCDF ";
    print "\n";
}
