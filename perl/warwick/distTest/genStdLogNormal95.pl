#!/usr/bin/perl -w  

use strict;


my $pi = 3.14159;

for (my $i = 0.001; $i < 20; $i += 0.001) {
    my $Px = exp(- ((log($i)**2)/2)) / ($i * sqrt(2 * $pi));
    my $cdf = (1/2)*(1+&erf((log($i))/sqrt(2)));

    
    print "x = $i ";
    print "Px = $Px ";
    print " xminusxbarOverSigma = " . ($i - 1.65)/2.161;
    print " PxTimesSigma = " . $Px*2.161;
    print " CDF = " . $cdf;

    my $minusLog = -log($Px*2.161);
    my $plus5 = -log($Px*2.161 + ($Px*2.161)*0.05);
    my $minus5 = -log($Px*2.161 - ($Px*2.161)*0.05);
    print " minusLog = $minusLog ";
    print " plus5 = $plus5 " ;
    print " minus5 = $minus5" ;
    print "\n";

}


# $y = &erf($x) - normalized error function
sub erf { &erf2($_[0]/1.414213562373095); }

# $y = &erf2($x) - unnormalized error function
sub erf2 { 
    my ($x)=$_[0];
    $x >= 4 ? return 1 : $x <= -4 ? return 0 : 0;
    my ($n,$sum,$term,$x2) = (0, 0.5, $x/1.772453850905516, $x*$x);
    while ($term > 1E-10 || $term < -1E-10) {
        $n++; $sum += $term; $term *= - ($x2 * ($n+$n-1))/(($n+$n+1) * $n); 
    }
    $sum;
}