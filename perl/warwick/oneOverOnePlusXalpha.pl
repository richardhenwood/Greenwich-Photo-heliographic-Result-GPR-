#!/usr/bin/perl -w

use POSIX;
use Data::Dumper;
use warnings;
use Math::Trig qw(pi);
use Math::Complex;

my $numberOfPoints = 1000;
my %bins = ();
my $binWidth = 0.1;
my @distributedNos = ();
# this is my attempt at a sample distributed over 1/(1+x^alpha)
if (0) {
for (my $alpha = 0.2; $alpha <= 2; $alpha = $alpha + 0.4) {
    #print "alpha $alpha\n";
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand(100);
        my $A = 1;
        my $P_x = $A / (1 + $x**$alpha);
        print "x = $x p_x = $P_x\n";
        #push(@{$bins{floor(($x / 10) * 10), $P_x);
        push(@distributedNos, $P_x);
    }
    print "\n\n";
}
}
# this the probability density function of  1/(1+x*alpha)
if (0) {
for (my $alpha = 0.2; $alpha <= 2; $alpha = $alpha + 0.4) {
    #print "alpha $alpha\n";
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand(100);
        my $A = 1;
        my $P_x = ($alpha * sin(pi / $alpha) / pi) * $A / (1 + $x**$alpha);
        print "x = $x p_x = $P_x\n";
        push(@{$bins{floor(($x / 10) * 10)}}, $P_x);
        push(@distributedNos, $P_x );
    }
    print "\n\n";
}
}
#print Dumper @distributedNos;
#print Dumper %bins;
foreach my $bin (sort numeric keys %bins) {
    print "bin = $bin ";
    print "quantity = " . scalar @{$bins{$bin}};
    print "\n";
}

# this is the reverse operation, y limited between 1 and 1/2
%bins = ();
$numberOfBins = 10;
if (1) {
#for (my $alpha = 0.2; $alpha <= 2; $alpha = $alpha + 0.4) {
    for (my $alpha = 2) {
%bins = ();
%logBins = ();

    #for ($alpha = 0.5) {
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $y = rand;
        $y = ($y / 2) + 1/2;
        my $A = 1;
        my $P_x = (($A - $y)/$y)**(1/$alpha);
#        my $P_x = ($alpha * sin(pi / $alpha) / pi) * $A / (1 + $x**$alpha);
#    print "x = $P_x y = $y ";
#        print 10**$P_x . " ";
#        print ceil(10**$P_x);
#        print "\n";
#my $binWidth = log10(ceil(10**$P_x)) - log10(floor(10**$P_x));
        
        #print "$P_x " . log10(floor(10**$P_x)) . " : " . log10(ceil(10**$P_x)) . "\n";
    
       #print "binwidth = $binWidth\n";
        push(@{$logBins{ceil(10**$P_x)/$numberOfBins}}, $P_x);
        push(@{$bins{floor($P_x * 10) / 10}}, $P_x);
        #print "bin = " . floor($x * 10) / 10 . " value = $x\n";
        #if (!defined $bins{floor($x * 10) / 10}) {
            #$bins{floor($x * 10) / 10} = 0;
            #}
            #$bins{floor($x * 10) / 10}++;
    }
    print "\n\n";
foreach my $bin (sort numeric keys %bins) {
    print "bin = $bin ";
    print "quantity = " . scalar @{$bins{$bin}};
    print " normalised = " . scalar @{$bins{$bin}} / ($numberOfPoints * (1 / $numberOfBins));
    
    print "\n";
}
print "\n\n";
foreach my $bin (sort numeric keys %logBins) {
    print "logbin = " . $bin ;
    my $binWidth = 99999;
    eval {
        #print "bin = $bin ";
        #print log10(10*$bin). " ,  ". log10((10*$bin)-1);
        $binWidth = log10(10*$bin) - log10((10*$bin)-1);
    };
    #if ($@) {
    print " quantity = " . scalar @{$logBins{$bin}};
    print " normalised = " . scalar @{$logBins{$bin}} / ($numberOfPoints * $binWidth);
    
    print " binwidth = $binWidth";
    print "\n";
}
}
#print Dumper %bins;
}

sub numeric {
    $a <=> $b;
}

