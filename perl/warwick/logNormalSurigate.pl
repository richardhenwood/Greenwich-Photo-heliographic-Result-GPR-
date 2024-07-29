#!/usr/bin/perl -w

use POSIX;
use Data::Dumper;
use warnings;
use Math::Trig qw(pi);
#use Math::Complex qw(log);

my $numberOfPoints = 100;
my %bins = ();
my $binWidth = 0.1;
my @distributedNos = ();
my $range = 100;

# in order to generate my surigate function, I first generate
# some normally distributed numbers with the givens stddev and 
# mean.

if (1) {
    my @normalDist = ();
    my @logNormalDist = ();
    my $numberInLogNormalDist = 3;
    my $mean = 1;
    my $sigma = 1;
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand(10 - $mean) + $mean;
        my $A = 1 / ( sqrt( 2 * pi * ($sigma**2)) * $x);
        my $P_x = exp(-($x - $mean)**2/(2 * $sigma**2));
        $P_x = $A * $P_x;
        push(@normalDist, [$x, $P_x]);
        my $PN_x = 1;
        for (my $j = 0; $j < $numberInLogNormalDist; $j++) {
            #$x = rand(10) - 4;
            $A = 1 / ( sqrt( 2 * pi * ($sigma**2)) );
            $P_x = exp(-($x - $mean)**2/(2 * $sigma**2));
            $P_x = $A * $P_x;
            $PN_x = $PN_x * $P_x; 
        }
        push(@logNormalDist, [$x, log($P_x)]);
    }
    # output the normal dist points
    foreach my $xRef (@normalDist) { 
        my ($x, $P_x) = @{$xRef};
        print "x = $x ";
        print "P_x = $P_x ";
        print "\n";
    }
    print "\n\n";
    # output the lognormal dist points
    foreach my $xRef (@logNormalDist) { 
        my ($x, $P_x) = @{$xRef};
        print "x = $x ";
        print "PN_x = $P_x ";
        print "\n";
    }
}


# this is my attempt to make a log normal distribution :
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
if (0) {
    my $mean = 1;
    my $sigma = 1;
#for ($sigma = 1; $sigma <= 4; $sigma += 1) {
for ($mean = 1; $mean <= 4; $mean += 1) {
    for (my $i = 0; $i < $numberOfPoints; $i++) {
         my $x = rand($range - $mean) + $mean;
         $x = rand($range);
        my $A = 1 / ( sqrt( 2 * pi * ($sigma**2)) );
#        $A = 1;
        
        #print " log (e) = " . exp(1);
        my $P_x = exp ( 0 - (((log($x/$mean))**2)/(2*($sigma**2))));
        #my $P_x = exp ( - ((1/2) * ((log($x) - $mean)/$sigma)**2));
        $P_x = $A * $P_x;
        print "x = $x ";
        print "P_x = $P_x ";
        print "1overx = " . 1/$x;
        print "\n";
    }
    print "\n\n";
}
}

# another attempt to do a log normal dist, this time with 
# an alternative form of the pdf
if (0) {
    my $mean = 1;
    for (my $sigma = 1; $sigma <= 4; $sigma += 1) {
        for (my $i = 0; $i < $numberOfPoints; $i++) {
    
            my $x = rand($range - $mean) + $mean;
            #        $x = rand($range);
            $mu_x = (1 / (2 * $sigma**2) ) * log($x/$mean);
            $A = 1 / ($mean * sqrt(2 * pi * $sigma**2));
            $P_x = $A * ($x/$mean)**(-1-$mu_x);
            print "X = $x ";
            print "P_x = $P_x ";
            print "\n";
        }
    print "\n\n";
    }
}

# now trying the reverse pdf, giving P_x and getting x,,,
if (0) {
    my $mean = 1;
    for (my $sigma = 1; $sigma <= 4; $sigma += 1) {
        for (my $i = 0; $i < $numberOfPoints; $i++) {
            my $y = rand(0.9) + 0.1;
            my $x = exp(-((2*$sigma)**2*log($y) + $mean));
            
            print "x = $x ";
            print "y = $y ";
            print "\n";

        }
        print "\n\n";
    }
}

#sub numeric {
#    $a <=> $b;
#}

