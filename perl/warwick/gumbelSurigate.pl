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
my $range = 10;

# this is my attemt at a gumbel surigate, 
# this is the CDF
if (0) {
    for ($i = 0; $i < $numberOfPoints; $i++) {
        my $m = 0;
        my $a = 1;
        my $x = rand(20) - 10;
        my $H_x = exp( - exp( - ($x - $m)/$a));
        print "x = $x ";
        print "H_x = $H_x ";
        print "\n";
    }
}

# and this should be the pdf:
# p_x = 1/beta * e((x-mu)/beta) * e(-e*(x-mu)/beta)
if (1) {
    my $beta = 1;
    my $mu = 1;
    for ($beta = 1; $beta <= 4; $beta += 1) { 
        for ($i = 0; $i < $numberOfPoints; $i++) {
            my $x = rand($range - $mu) + $mu;
            #my $x = rand(100);
            my $A = 1 / $beta;
            my $f_x = exp(($x - $mu)/$beta) * exp(-exp(($x - $mu)/$beta));
            $f_x = $A * $f_x;
            print "x = $x ";
            print "f_x = $f_x ";
            print "\n";
        }
        print "\n\n";
    }
}

# now i'm going to plot some log normal values:
if (1) {
    my $mean = 1;
    my $sigma = 1;
    for ($sigma = 1; $sigma <= 4; $sigma += 1) {
        #for ($mean = 1; $mean <= 4; $mean += 1) {
        for (my $i = 0; $i < $numberOfPoints; $i++) {
            my $x = rand($range - $mean) + $mean;
            #$x = rand($range);
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



my $setOf = 10;
if (0) {
    for ($i = 0; $i < $numberOfPoints; $i++) {
        my @tmpSet = ();
        for ($j = 0; $j < $setOf; $j++) {
            #push(@tmpSet, :q
           
        }
    }
}

#sub numeric {
#    $a <=> $b;
#}

