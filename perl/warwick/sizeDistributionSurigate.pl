#!/usr/bin/perl -w

use POSIX;
use Data::Dumper;
use warnings;
use Math::Trig qw(pi);
#use Math::Complex qw(log);
use lib '../../external_libs/';
use lib '../external_libs/';
use Statistics::Basic::StdDev;
use Statistics::Basic::Mean;
use strict;

# These are values taken from the greenwich dataset.
#total spots = '29851'
#max spot stddev = '287.42776427889'
#max spot mean = 158.141167800074
#range:     1 ->  6132
# this is all the greenwich spots
my $numberOfPoints = 29851;
my $stddev = 287.4;
my $mean = 158.1;
my $range = 6132;
# this is only the spots which we see the whole life
$numberOfPoints = 12677;
$stddev = 39.1;
$mean = 24.9;
$range = 1226;
# this is for testing purposes.
$numberOfPoints = 1000;
$mean = 1;
$stddev = 1;
$range = 100;

my %bins = ();
my @distributedNos = ();
my $numberOfBins = 50;
my $binWidth = $range/$numberOfBins; 


#&normalPDF();

# this section tests the Box Muller method and the averaging method
my $testMean = 10;
my $testStddev = 5;
#for (my $i = 5; $i < 500; $i += 10) {
#    $testStddev = $i;
#&normalBoxM();
#&normalAv();
#}

#&logNormalPDF();
#&normalPDF();
#&normalBoxM();
#&logNormalPDF();
&logNormalPDFBin();
&logNormalPDFLogBin();
#&logNormalBoxM();
#&logNormalPDFbinned();
#&logNormalBoxM();

&gumbelPDF();
&gumbelPDFBin();
&gumbelPDFLogBin();
#&gumbelRand();


# in order to generate my surigate function, I first generate
# some normally distributed numbers with the givens stddev and 
# mean.

sub normalPDF {
    print "normalPDF\n";
    my @normalDist = ();
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ( $stddev * sqrt( 2 * pi ) );
        my $P_x = exp(-($x - $mean)**2/(2 * $stddev**2));
        $P_x = $A * $P_x;
        push(@normalDist, [$x, $P_x]);
    }
    # output the normal dist points
    foreach my $xRef (@normalDist) { 
        my ($x, $P_x) = @{$xRef};
        print "x = $x ";
        print "P_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}

# now, this function generates random, normalised normal numbers.
sub normalBoxM {
    print "normalBoxM\n";
    my @normalBoxMuller = &normalBoxMuller($numberOfPoints, $mean, $stddev);

# so now count them into bins;
    my %normalDistBins = ();
    foreach my $normValue (@normalBoxMuller) {
        my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);
        push(@{$normalDistBins{$bin}}, $normValue);
    }
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}

# this is my log normal distribution :
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDF {
    print "logNormalPDF\n";
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ($stddev * sqrt( 2 * pi ) * $x);
        my $P_x = exp (-((log($x/$mean))**2/(2 * $stddev**2)));
        $P_x = $A * $P_x;
# now try and do a transform on the data
        my $normValue = $P_x;
#        $normValue = ($normValue / $stddev) - ($mean / $stddev);        
        $normValue = $normValue * $stddev;        
        $x = $x / $stddev;
        print "x = $x ";
        print " P_x = $normValue ";
        print "\n";
    }
    print "\n\n";
}
# this is my log normal distribution pdf, binned
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDFBin {
    print "logNormalPDFBin\n";
    my %logNormalDistBins = ();
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        #$x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ($stddev * sqrt( 2 * pi ) * $x);
        my $P_x = exp (-((log($x/$mean))**2/(2 * $stddev**2)));
        $P_x = $A * $P_x;
                    
        my $normValue = $P_x;
        my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
        push(@{$logNormalDistBins{$bin}}, $normValue);
    }
    foreach my $binName (sort numeric keys %logNormalDistBins) {
        my $sum = 0;
        $sum += $_ for @{$logNormalDistBins{$binName}};
        $sum = $sum / ($numberOfPoints * $binWidth);
        print "bin = $binName ";
        my $P_x = scalar @{$logNormalDistBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print " sum = $sum ";
        #    my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistBins{$binName}})->query);
        #print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}
# this is my log normal distribution pdf, binned in log bins
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDFLogBin {
    print "logNormalPDFLogBin\n";
    my %logNormalDistBins = ();
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        my $A = 1 / ($stddev * sqrt( 2 * pi ) * $x);
        my $P_x = exp (-((log($x/$mean))**2/(2 * $stddev**2)));
        $P_x = $A * $P_x;
                    
# now try and do a transform on the data
        my $normValue = $P_x;
#        $normValue = ($normValue / $stddev) - ($mean / $stddev);        
        $normValue = $normValue * $stddev;        
        $x = $x / $stddev;
        my $bin = ceil($numberOfBins * (log($x)/log($range)));
        push(@{$logNormalDistBins{$bin}}, $normValue);
    }
    foreach my $binName (sort numeric keys %logNormalDistBins) {
        my $sum = 0;
        my $logBinWidth = ($range**($binName/$numberOfBins) - $range**(($binName-1)/$numberOfBins));
        my $binPosition = $range**(($binName-1)/$numberOfBins) + 0.5*$logBinWidth;
        $sum += $_ for @{$logNormalDistBins{$binName}};
        $sum = $sum / ($numberOfPoints * $logBinWidth);
        print "bin = $binPosition ";
        my $P_x = scalar @{$logNormalDistBins{$binName}} / ($numberOfPoints * $logBinWidth);

# now try and do a transform on the data
#        $P_x = $P_x * $stddev;
        print " p_x = $P_x ";
#        $sum = $sum / $stddev;
        print " sum = $sum ";
        print " num = " . scalar @{$logNormalDistBins{$binName}};
        #    my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistBins{$binName}})->query);
        #print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}

# this is a gumbel pdf implementation;
# p_x = 1/sigma * e^(-e^((x-mu)/sigma));
sub gumbelPDF {
    print "gumbel\n";
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ($stddev);
        my $f_x = exp(-($x - $mean)/$stddev) * exp(-exp(-($x - $mean)/$stddev));
        $f_x = $A * $f_x;
        print "x = $x ";
        print "f_x = $f_x ";
        print "\n";
    }
    print "\n\n";
}
# this is a gumbel pdf implementation binned;
# p_x = 1/sigma * e^(-e^((x-mu)/sigma));
sub gumbelPDFBin {
    print "gumbelPDFBin\n";
    my %gumbelDistBins = ();
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ($stddev);
        my $f_x = exp(-($x - $mean)/$stddev) * exp(-exp(-($x - $mean)/$stddev));
        $f_x = $A * $f_x;

        my $normValue = $f_x;
        my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
        push(@{$gumbelDistBins{$bin}}, $normValue);
    }
    foreach my $binName (sort numeric keys %gumbelDistBins) {
        my $sum = 0;
        $sum += $_ for @{$gumbelDistBins{$binName}};
        $sum = $sum / ($numberOfPoints * $binWidth);
        print "bin = $binName ";
        my $P_x = scalar @{$gumbelDistBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print " sum = $sum ";
        #    my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistBins{$binName}})->query);
        #print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}
# this is a gumbel pdf implementation binned in log bins;
# p_x = 1/sigma * e^(-e^((x-mu)/sigma));
sub gumbelPDFLogBin {
    print "gumbelPDFLogBin\n";
    my %gumbelDistLogBins = ();
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        my $A = 1 / ($stddev);
        my $f_x = exp(-($x - $mean)/$stddev) * exp(-exp(-($x - $mean)/$stddev));
        $f_x = $A * $f_x;

        my $normValue = $f_x;
        my $bin = ceil($numberOfBins * (log($x)/log($range)));
        push(@{$gumbelDistLogBins{$bin}}, $normValue);
    }
    foreach my $binName (sort numeric keys %gumbelDistLogBins) {
        my $sum = 0;
        my $logBinWidth = ($range**($binName/$numberOfBins) - $range**(($binName-1)/$numberOfBins));
        my $binPosition = $range**(($binName-1)/$numberOfBins) + 0.5*$logBinWidth;
        $sum += $_ for @{$gumbelDistLogBins{$binName}};
        $sum = $sum / ($numberOfPoints * $logBinWidth);
        print "bin = $binPosition ";
        my $P_x = scalar @{$gumbelDistLogBins{$binName}} / ($numberOfPoints * $logBinWidth);
        print " p_x = $P_x ";
        print " sum = $sum ";
        #    my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistBins{$binName}})->query);
        #print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}

sub gumbelBoxM {
    print "gumbelboxM\n";
    my %normalDistBins = ();
    my $gumbelSetSize = 16;
    my @gumbelSet = ();
    my $totalNumberOfPoints = 0;
    while ($totalNumberOfPoints < $numberOfPoints) {
        my @randNorms = &normalBoxMuller($gumbelSetSize, $mean, $stddev );#/ $gumbelSetSize );
        my $largest = (sort numeric @randNorms)[-1];
        #    print "binwidth '$binWidth' array = " . join(', ', @randNorms);
        #      print " largest = '$largest' \n";
        
        my $bin = ($binWidth/2)+$binWidth * floor($largest / $binWidth);
        push(@{$normalDistBins{$bin}}, $largest);
        $totalNumberOfPoints++;
    }
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
    print "totalnumber = $totalNumberOfPoints\n";
}

# this function generates random, normalised gumbel numbers.
sub gumbelBoxMOld {
    my $range = 10;
    
# so now count them into bins;
    my %normalDistBins = ();
    my $gumbelSetSize = 4;
    my @gumbelSet = ();
#    my $binWidth = 0.1;
    my $count = 1;
    my $totalNumberOfPoints = 0;
    while ($totalNumberOfPoints < $numberOfPoints) {
        my @normalRandom = &normalBoxMuller($numberOfPoints, $mean, $stddev);# * ($gumbelSetSize-1));
        foreach my $normValue (@normalRandom) {
            if ($count % $gumbelSetSize == 0) {
                my $largest = (sort numeric @gumbelSet)[-1];
                #    print " array = " . join(', ', @gumbelSet);
                #print " largest = '$largest' \n";
                @gumbelSet = ();
                my $bin = ($binWidth/2)+$binWidth * floor($largest / $binWidth);
                push(@{$normalDistBins{$bin}}, $normValue);
                $totalNumberOfPoints++;
            }
            $count++;
            push(@gumbelSet, $normValue);
        }
    }
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}};# / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
    print "totalnumber = $totalNumberOfPoints\n";
}





















sub getRands {
    my ($number, $range) = @_;
    my @rndArray = ();
    for (my $i = 0; $i < $number; $i++) {
        push(@rndArray, rand($range));
    }
    return @rndArray;
}

# this function generates a an array of normally distributed random numbers
# this is generated using the box muller method.
sub normalBoxMuller {                                            
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
    my @normalArray = ();
    for (my $i = 0; $i < $numberOfPoints; $i ++ )  {                    
        push(@normalArray, rand);
    }

    for (my $i = 0; $i < $numberOfPoints; $i += 2 )  {                    
        my $z1 = sqrt( -2.0 * log( $normalArray[$i] ) ) * cos( 2.0 * pi * $normalArray[$i+1] );
        my $z2 = sqrt( -2.0 * log( $normalArray[$i] ) ) * sin( 2.0 * pi * $normalArray[$i+1] );                    
        $normalArray[$i] = ( $z1 * $stddev ) + $mean;                            
        $normalArray[$i+1] = ( $z2 * $stddev ) + $mean;                        
    }                                                                
    return @normalArray;
}               
    
sub numeric {
    $a <=> $b;
}

# this is my method to generate norma numbers with a given std and mean
sub normalAvArray {
    my ($numberOfPoints, $mean, $stddev) = @_;
    my @normalArray = ();
    my $setSize = 10;
    my %normalDistBins = ();
    my $range = $stddev * $setSize * 1/(2*sqrt(2)); # it made this range scaling up.
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $setTotal = 0;
        for (my $i = 0; $i < $setSize; $i++) {
            $setTotal += rand;
        }
        my $value = ($setTotal / $setSize)  - 0.5;
        $value = ($value * $stddev * sqrt(12 * $setSize)) + $mean;
        push(@normalArray, $value);
    }
    return @normalArray;
}

sub normalPDFMangled {
    my @normalDist = ();
    my @logNormalDist = ();
    my $numberInLogNormalDist = 1;
    my $mean = 1;
    my $sigma = 1;
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ( sqrt( 2 * pi * ($sigma**2)));
        my $P_x = exp(-($x - $mean)**2/(2 * $sigma**2));
        $P_x = $A * $P_x;
        push(@normalDist, [$x, $P_x]);

        if (0) {
        my $PN_x = 1;
        for (my $j = 0; $j < $numberInLogNormalDist; $j++) {
            #$x = rand(10) - 4;
            $A = 1 / ( sqrt( 2 * pi * ($sigma**2)) * $x);
            $P_x = exp(-($x - $mean)**2/(2 * $sigma**2));
            $P_x = $A * $P_x;
            $PN_x = $PN_x * exp($P_x); 
            
        }
        if ($PN_x == 0) {
            print "pnx = 0";
        }
            push(@logNormalDist, [$x, $PN_x]);
            #}
            #else {
                #push(@logNormalDist, [$x, 0]);
            #}
        }
    }
    # output the normal dist points
    foreach my $xRef (@normalDist) { 
        my ($x, $P_x) = @{$xRef};
        print "x = $x ";
        print "P_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}
sub normalBoxMMangled {
    my @normalRandom = &normalBoxMuller($numberOfPoints, $testMean, $testStddev);

# so now count them into bins;
    my %normalDistBins = ();
    my $totalNumberOfPoints = 0;
    my @avSet = ();
    foreach my $normValue (@normalRandom) {
        if ($normValue > 0) {
            my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);
            push(@{$normalDistBins{$bin}}, $normValue);
            push(@avSet, $normValue);
            $totalNumberOfPoints++;
        }
    }
    if (0) {
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
}
    print "mean = $testMean stddev = $testStddev ";
    print "mean " . Statistics::Basic::Mean->new(\@avSet)->query;
    print " stdev " . Statistics::Basic::StdDev->new(\@avSet)->query;
##    print "\n";
##    print "\n\n";
}
sub logNormalPDFMangled {
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / ( sqrt( 2 * pi * ($stddev**2)) * $x);
        my $P_x = exp ( 0 - (((log($x/$mean))**2)/(2*($stddev**2))));
        $P_x = $A * $P_x;
        print "x = $x ";
        print "P_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}
# this is a function I use to generate normally distributed random nubmers.
# it uses the averaging of a number of numbers method.
# I have modified it with my own random number range scaling factor so
# I can control the standard deviation of the resulting normal numbers.
sub normalAv {
    my $range = 10;
    my @normalRandom = &normalAvArray($numberOfPoints, $testMean, $testStddev);

# so now count them into bins;
    my %normalDistBins = ();
    my $binWidth = 0.1;
    my $totalNumberOfPoints = 0;
    my @avSet = ();
    foreach my $normValue (@normalRandom) {
        if ($normValue > 0) {
            my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);
            push(@{$normalDistBins{$bin}}, $normValue);
            push(@avSet, $normValue);
            $totalNumberOfPoints++;
        }
    }
    if (0) {
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
}
    print " avmean " . Statistics::Basic::Mean->new(\@avSet)->query;
    print " avstdev " . Statistics::Basic::StdDev->new(\@avSet)->query;
    print "\n";
}


sub normalAvold {
    my $mean = $testMean;
    my $stddev = $testStddev;
    my @avSet = ();
    my $setSize = 10;
    my %normalDistBins = ();
    my $binWidth = 1/$setSize;
    my $range = $stddev * $setSize * 1/(2*sqrt(2)); # it made this range scaling up.
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $setTotal = 0;
        my $x = 0;
        for (my $i = 0; $i < $setSize; $i++) {
            $x = rand($range) + $mean - $range/2;
            #$x = rand;
            $setTotal += $x;
        }
        my $bin = ($binWidth/2)+$binWidth * floor($setTotal / ($setSize * $binWidth));
        push(@{$normalDistBins{$bin}}, $setTotal/$setSize);
        push(@avSet, $x);
    }
    if (0) {
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
}
    print " avmean " . Statistics::Basic::Mean->new(\@avSet)->query;
    print " avstdev " . Statistics::Basic::StdDev->new(\@avSet)->query;
    print "\n";
#    print "\n\n";
}
# and, this function generates random, normalised log-normal numbers.
sub logNormalBoxMmangled { 
    #my $range = 10;
    my @normalRandom = &normalBoxMuller($numberOfPoints, $mean, $stddev);

# so now count them into bins;
    my %normalDistBins = ();
    #my $numberOfBins = 20;
#    my $binWidth = 1;
    my $totalNumberOfPoints = 0;
    my %logDistBins = ();
    foreach my $normValue (@normalRandom) {
#              print "normvlaue = $normValue ";
$normValue = exp($normValue);
        my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);
               print "binnumber = $bin normvalue = $normValue\n";
        push(@{$normalDistBins{$bin}}, $normValue);
        push(@{$logDistBins{ceil(10**$normValue)/$numberOfBins}}, $normValue);
        $totalNumberOfPoints++;
    }
    foreach my $binName (sort numeric keys %normalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$normalDistBins{$binName}} / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
    #   foreach my $binName (sort numeric keys %logDistBins) {
        #    print "bin = $binName ";
        #    my $P_x = scalar @{$logDistBins{$binName}};# / ($totalNumberOfPoints * $binWidth);
        #    print " p_x = $P_x ";
        #    print "\n";
        #}
        #'print "\n\n";
        #print Dumper %logDistBins;
}


# this binning technique dosen't work. 
sub logNormalPDFbinned {
    my %logNormalDistBins = ();
    my %logDistBins = ();
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = rand($range - $mean) + $mean;
        $x = rand($range);
        $x = ($i / $numberOfPoints) * $range;

        my $A = 1 / ( sqrt( 2 * pi * ($stddev**2)) * $x);
        my $P_x = exp ( 0 - (((log($x/$mean))**2)/(2*($stddev**2))));
        $P_x = $A * $P_x;

        # now put the numbers in bins.
        # linear bins in this case:
        #my $binName = ($binWidth/2)+$binWidth * floor($x / $binWidth);
        my $binName = floor($x/$binWidth)/$binWidth + $binWidth/2;
        push(@{$logNormalDistBins{$binName}}, $P_x * $x);
        # log bins in this case:
        my $logNormValue = $P_x * $x;
        my $logBinName = ceil($numberOfBins**($x/$range));
        push(@{$logDistBins{$logBinName}}, $logNormValue);

    }
# kk    
    foreach my $binName (sort numeric keys %logNormalDistBins) {
        print "bin = $binName ";
        my $sum = 0;
        $sum += $_ for @{$logNormalDistBins{$binName}};
        my $P_x = $sum / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
    foreach my $binName (sort numeric keys %logDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$logDistBins{$binName}};# / ($totalNumberOfPoints * $binWidth);
        print " p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}
# this forumla seems to give a normal distribution.
sub logNormalPDFOld {
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
         my $x = rand($range - $mean) + $mean;
         $x = rand($range);
         $x = ($i / $numberOfPoints) * $range;
         my $A = 1 / ( $stddev * sqrt( 2 * pi) );

         my $P_x = exp ( - (1/2)*(($x - $mean)/$stddev)**2 );
         $P_x = $A * $P_x;
         print "x = $x ";
         print "P_x = $P_x ";
#         print "1overx = " . 1/$x;
         print "\n";
    }
    print "\n\n";
}

# this should be the pdf of the gumbal distribution:
# p_x = 1/beta * e((x-mu)/beta) * e(-e*(x-mu)/beta)
sub gumbelPDFOld {
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        my $A = 1 / $stddev;
        my $P_x = exp( - exp(($x - $mean)/$stddev));
        $P_x = $P_x * $A;
        print "x = $x ";
        print "p_x = $P_x ";
        print "\n";
    }
    print "\n\n";
}

# this is an attempt to generate random numbers with gumbel distn
# http://www.brighton-webs.co.uk/distributions/gumbel.asp
# r = g(u)
# r = mode - .scale * log(log(1/u))
sub gumbelRand {
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $u = rand;
        my $r = $mean - $stddev * log(log(1/$u));
        print "x = $r ";
        print "y = $u ";
        print "\n";
    }
    print "\n\n";
}

# now, this function generates random, normalised normal numbers.
# and then makes them into a log normal distribution
# however, this distn' dosen't have the mean and stdev of the normal
# distn' which is the 'seed'.
sub logNormalBoxM {
    print "logNormalBoxM\n";

# so now count them into bins;
    my %logNormalDistBins = ();
    my $localCount = 0;
    while ($localCount < $numberOfPoints) {
        my @normalBoxMuller = &normalBoxMuller(100, $mean, $stddev );
        @normalBoxMuller = &normalBoxMuller(100, log($mean) - ($stddev**2)/2, sqrt(log($stddev/($mean**2) + 1)) );
        foreach my $normValue (@normalBoxMuller) {
            if ($normValue > 1) { # only take the RHS of the normal distn'
                $normValue = exp($normValue) - sqrt(pi * 2);
                if ($normValue > 0 && $normValue < $range) {
                    my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);# - exp($mean);
                    push(@{$logNormalDistBins{$bin}}, $normValue);
                    $localCount++;
                }
            }
        }
    }
    my @binnedLogNormal = ();
    foreach my $binName (sort numeric keys %logNormalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$logNormalDistBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistBins{$binName}})->query);
        print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}
# now I put my lognormally distributed random numbers into log 
# bins.
sub logNormalBoxMLogBins {
    print "logNormalBoxMLogBins\n";

# so now count them into bins;
    my %logNormalDistLogBins = ();
    my $localCount = 0;
    while ($localCount < $numberOfPoints) {
        my @normalBoxMuller = &normalBoxMuller(100, $mean, $stddev );
        @normalBoxMuller = &normalBoxMuller(100, log($mean) - ($stddev**2)/2, sqrt(log($stddev/($mean**2) + 1)) );
        foreach my $normValue (@normalBoxMuller) {
            if ($normValue > 1) { # only take the RHS of the normal distn'
                $normValue = exp($normValue) - sqrt(pi * 2);
                if ($normValue > 0 && $normValue < $range) {
                    my $bin = ($binWidth/2)+$binWidth * floor($normValue / $binWidth);
                    push(@{$logNormalDistLogBins{$bin}}, $normValue);
                    $localCount++;
                }
            }
        }
    }
    my @binnedLogNormal = ();
    foreach my $binName (sort numeric keys %logNormalDistLogBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$logNormalDistLogBins{$binName}} / ($numberOfPoints * $binWidth);
        print " p_x = $P_x ";
        my $stdError = sqrt(Statistics::Basic::StdDev->new(\@{$logNormalDistLogBins{$binName}})->query);
        print " stderr = $stdError"; 
        print "\n";
    }
    print "\n\n";
}


