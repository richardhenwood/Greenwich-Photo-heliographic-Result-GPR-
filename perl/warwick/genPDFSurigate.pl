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
=begin comment
my $numberOfPoints = 29851;
my $stddev = 287.4;
my $mean = 158.1;
my $range = 6132;
# this is only the spots which we see the whole life
$numberOfPoints = 12677;
$stddev = 79.8;
$mean = 31.2;
$range = 1226;
# this is for testing purposes.
$numberOfPoints = 1000;
$mean = 1;
$stddev = 1;
$range = 100;
=cut comment

&main;

sub main {
#&normalPDF();

# this section tests the Box Muller method and the averaging method
#for (my $i = 5; $i < 500; $i += 10) {
#    $testStddev = $i;
#&normalBoxM();
#&normalAv();
#}

#&logNormalPDF();
#&normalPDF();
#&normalBoxM();
#&logNormalPDF();
#&logNormalPDFBin();
my $numberOfPoints = 1000;
my $mean = 25;
my $stddev = 25;
my $range = 100;
#$numberOfPoints = 1000; $mean = 5; $stddev = 5; $range = 1000;
my %bins = ();
my @distributedNos = ();
my $numberOfBins = 50;
$numberOfPoints = 12677; $stddev = 79.8; $mean = 31.2; $range = 2427;
$numberOfPoints = 29851; $stddev = 287.4; $mean = 158.1; $range = 6132;
$numberOfPoints = 196; $stddev = 2.58; $mean = 2.47; $range = 368;
# the values below are for a filtered set, filtering out all bins
# with only one item in them.
# the values below are log binned values
#$numberOfPoints = 406; $stddev = 4.5; $mean = 5.7; $range = 2427;

# below is the most recent estimate
$numberOfPoints = 12677; $stddev = 68.5; $mean = 41.5; $range = 2427;
# right, now i've log binned the read data, and taken the mean 
# and stddev of the log bined data.
$numberOfPoints = 12677; $stddev = 207.8; $mean = 233.3; $range = 2427;

# this is for all the spots:
#$numberOfPoints = 29851; $stddev = 1029.5; $mean = 1197.2; $range = 11281;

# this is for my filtered set: H2006m.
#$numberOfPoints = 15229; $stddev = 221.9; $mean = 80; $range = 6132;
# and after log binning:
#$numberOfPoints = 15229; $stddev = 942.5; $mean = 854.4; $range = 11281;

if (1) {
    $numberOfBins = 100;
    srand(42); # this line means we always get the same rand numbers
    #$numberOfBins = 50;
#    &logNormalPDFLinBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    srand(42); # this line means we always get the same rand numbers
    #$numberOfBins = 50;
    &logNormalPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    srand(42); # this line means we always get the same rand numbers
    #$numberOfBins = 50;
    #&gumbelPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);

    srand(42); # this line means we always get the same rand numbers
    #$numberOfBins = 50;
    &fisherTippettPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}

if (0) {
for (my $stddev = 10; $stddev < 50; $stddev = $stddev + 10) {
    # $numberOfPoints = 12677; $stddev = 68.5; $mean = 41.5; $range = 2427;
    $numberOfPoints = 1000; $mean = 50; $stddev = 50; $range = 2400;
    $numberOfPoints = 100; $mean = 50; $stddev = 50; $range = 2400;
    srand(42); # this line means we always get the same rand numbers
            # for successive calls of the functions in this loop.
    &logNormalPDFstats($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
            
    #&logNormalPDF($numberOfPoints, $mean, $i, $range, $numberOfBins);
    #&gumbelPDF($numberOfPoints, $mean, $i, $range, $numberOfBins);
    # &logNormalPDFBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    print "\n";
    &logNormalPDFLinBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    print "\n";
    &logNormalPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    #&gumbelPDFLogBin($numberOfPoints, $mean, $i, $range, $numberOfBins);
#    exit;
}
}

if (0) {
    $numberOfPoints = 12677; $stddev = 39.1; $mean = 24.9; $range = 1226;
    $numberOfPoints = 1000; $stddev = 1; $mean = 1; $range = 100;
    #$numberOfPoints = 29851; $stddev = 287.4; $mean = 158.1; $range = 6132;
    srand(42); # this line means we always get the same rand numbers
    &logNormalPDF($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    &gumbelPDF($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    &fisherTippettPDF($numberOfPoints, $mean, $stddev, $range, $numberOfBins);

    #&logNormalBoxM();
}

#&gumbelPDF();
#&gumbelPDFBin();
#&gumbelPDFLogBin();
#&gumbelRand();
}


# in order to generate my surigate function, I first generate
# some normally distributed numbers with the givens stddev and 
# mean.

sub normalPDF {
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
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
sub logNormalPDF {
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
    print "logNormalPDF\n";
    my @values = ();
    for (my $i = 1; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        my $f_x = &logNormalPDFvalue($x, $mean, $stddev);
        print "x = $x ";
        print "P_x = $f_x ";
        print "\n";
    }
    print "\n\n";
}    
sub logNormalPDFstats {
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
    print "logNormalPDFstats\n";
    my $logNormalPeak = getLogNormalPeak($mean, $stddev, $range);
    my @values = ();
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range);
        my $y = rand($logNormalPeak);
        my $P_x = &logNormalPDFvalue($x, $mean, $stddev);
        if ($y < $P_x ) {
            push(@values, $x);
            $i++;
        }
    }
    my $newmean = Statistics::Basic::Mean->new(\@values)->query;
    my $newstddev = Statistics::Basic::StdDev->new(\@values)->query;
    print "total = $i mean = $mean stddev = $stddev newmean = $newmean newstddev = $newstddev\n";
    #print "\n\n";

}    
sub gumbelPDF {
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
    print "gumbel\n";
    for (my $i = -100; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        my $f_x = &gumbelPDFvalue($x, $mean, $stddev);
        print "x = $x ";
        print "P_x = $f_x ";
        print "\n";
    }
    print "\n\n";
}    
sub fisherTippettPDF {
    my ($numberOfPoints, $mean, $stddev, $range) = @_;
    print "fisherTippett\n";
    for (my $i = -100; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        my $f_x = &fisherTippettPDFvalue($x, $mean, $stddev);
        print "x = $x ";
        print "P_x = $f_x ";
        print "\n";
    }
    print "\n\n";
}    

# this is my log normal distribution pdf, binned in linear bins
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDFLinBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    print "logNormalPDFLinBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    my $logNormalPeak = getLogNormalPeak($mean, $stddev, $range);
    my %logNormalDistBins = ();
    my $binWidth = $range/$numberOfBins;
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range);
        my $y = rand($logNormalPeak);
        my $P_x = &logNormalPDFvalue($x, $mean, $stddev);
        if ($y < $P_x ) {
            my $normValue = $P_x;
            my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
            push(@{$logNormalDistBins{$bin}}, $normValue);
            $i++;
        }
    }
    &PDFLinearOutput(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
# this is my log normal distribution pdf, binned in log bins
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDFLogBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    print "logNormalPDFLogBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins range $range\n";
    my $logNormalPeak = &getLogNormalPeak($mean, $stddev, $range);
    my %logNormalDistBins = ();
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range)  + 1;
        my $y = rand($logNormalPeak);
        my $P_x = &logNormalPDFvalue($x, $mean, $stddev);
        if ($y < $P_x ) {
            # origional binning mechanism. i think it's broken.
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            # new version.
            my $xNormF = floor(&logN($x,$range) * $numberOfBins);
            my $bin = $range**($xNormF / $numberOfBins);
            #print "$x binnorm = $xNormF binname = $bin\n";
            push(@{$logNormalDistBins{$bin}}, $P_x);
            $i++;
        }
    }
    PDFLinearOutput(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
# this is a gumbel pdf implementation binned in log bins;
# p_x = 1/sigma * e^(-e^((x-mu)/sigma));
sub gumbelPDFLogBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $binWidth) = @_;
    print "gumbelPDFLogBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    my $gumbelPeak = &getGumbelPeak($mean, $stddev, $range);
    my %gumbelDistLogBins = ();
    my $i = 0;
    #my $scale = (sqrt(6) * $stddev) / pi;
    #my $mode = $mean + (-0.577216 * $scale); 
    while ($i < $numberOfPoints) {
        my $x = rand($range) + 1;
        my $y = rand($gumbelPeak);
        my $f_x = &gumbelPDFvalue($x, $mean, $stddev);
        if ($y < $f_x) {
            my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            push(@{$gumbelDistLogBins{$bin}}, $f_x);
            $i++;
        }
    }
    PDFLinearOutput(\%gumbelDistLogBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
sub fisherTippettPDFLogBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $binWidth) = @_;
    print "fisherTippettPDFLogBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    my $gumbelPeak = &getFisherTippettPeak($mean, $stddev, $range);
    my %FTDistLogBins = ();
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range) + 1;
        my $y = rand($gumbelPeak);
        my $f_x = &fisherTippettPDFvalue($x, $mean, $stddev);
        if ($y < $f_x) {
            # old method.
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            # new method
            my $xNormF = floor(&logN($x,$range) * $numberOfBins);
            my $bin = $range**($xNormF / $numberOfBins);
            push(@{$FTDistLogBins{$bin}}, $f_x);
            $i++;
        }
    }
    PDFLinearOutput(\%FTDistLogBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
sub PDFLinearOutput {
    my ($PDFDistBinsRef, $numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    #print Dumper %PDFDistLinBins;
    my $total = 0;
    my $numTotal = 0;
    my $areaTotal = 0;
    my @values = ();
    foreach my $binName (sort numeric keys %PDFDistBins) {
        print " BinName = $binName ";
        
        my $binContents = scalar @{$PDFDistBins{$binName}};
        $total += $binContents;
        $binContents = $binContents / $numberOfPoints;
        $areaTotal += $binContents;
        print " contents = $binContents ";

        my $error = 1 / sqrt ($numberOfPoints);
        print " error = $error ";
        print "\n";
        #print "\n$binName ";
        #       print Dumper @{$PDFDistBins{$binName}};
        push (@values, ($binName) x @{$PDFDistBins{$binName}});
    }
    print "bin contents total $total numtotal = $numTotal areatotal = $areaTotal\n";
    if (1) {
        #print Dumper @values;
        my $newmean = Statistics::Basic::Mean->new(\@values)->query;
        my $newstddev = Statistics::Basic::StdDev->new(\@values)->query;
        print "stats mean = $mean stddev = $stddev newmean = $newmean newstddev = $newstddev\n";
    }
    print "\n\n";
}
# this function get the height of the tallest peak on a log normal distn
sub getLogNormalPeak {
    my ($mean, $stddev, $range) = @_;
    my $numberOfPoints = 1000;
    my $peakValue = 0;
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        if (&logNormalPDFvalue($x, $mean, $stddev) > $peakValue) {
            $peakValue = &logNormalPDFvalue($x, $mean, $stddev);
        }
    }
    return $peakValue;
}
sub getGumbelPeak {
    my ($mean, $stddev, $range) = @_;
    my $numberOfPoints = 1000;
    my $peakValue = 0;
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        if (&gumbelPDFvalue($x, $mean, $stddev) > $peakValue) {
            $peakValue = &gumbelPDFvalue($x, $mean, $stddev);
        }
    }
    return $peakValue;
}
sub getFisherTippettPeak {
    my ($mean, $stddev, $range) = @_;
    my $numberOfPoints = 1000;
    my $peakValue = 0;
    for (my $i = 0; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        if (&fisherTippettPDFvalue($x, $mean, $stddev) > $peakValue) {
            $peakValue = &fisherTippettPDFvalue($x, $mean, $stddev);
        }
    }
    return $peakValue;
}
# this is my log normal distribution :
sub logNormalPDFvalue {
    my ($x, $mean, $stddev) = @_;
    $stddev = $stddev**2;
    my $S = sqrt(log(($stddev + exp(2 * log($mean)))/exp(2 * log($mean))));
    my $M = (2 * log($mean) - $S**2)/2; 
    my $A = 1 / ($S * sqrt( 2 * pi ) * $x);
    my $P_x = exp (-((log($x)-$M)**2/(2 * $S**2)));
    $P_x = $A * $P_x;
    return $P_x;
}
# this is a gumbel pdf implementation;
sub gumbelPDFvalue {
    my ($x, $mean, $stddev) = @_;
    $stddev = $stddev**2;
    my $beta = ($stddev * sqrt(6)) / pi;
    my $mu = $mean - (0.5772 * $beta);
    my $A = 1 / $beta;
    my $f_x = exp(($x - $mu)/$beta) * exp(-exp(($x - $mu)/$beta));
    $f_x = $A * $f_x;
    return $f_x;
}
# this is a fisher-tippett distribution, which is more general than the gumbel distn' 
sub fisherTippettPDFvalue {
    my ($x, $mean, $stddev) = @_;
    my $eulerMascheroni = 0.57721;
    $stddev = $stddev**2;
    my $beta = sqrt((6 * $stddev) / pi**2);
    my $mu = $mean - ($beta * $eulerMascheroni); 
    my $A = 1 / $beta; 
    #my $z = exp(-(($x - $mu)/$beta));
    #my $f_x = (exp((-$z) * $z))/$beta;
    my $f_x = exp((($mu - $x)/$beta) - exp(($mu - $x)/$beta));
    return $A * $f_x;
}

sub numeric {
    $a <=> $b;
}
sub logN {
    my ($x, $n) = @_;
    return log($x)/log($n);
}








# this is my log normal distribution pdf, binned
# P(x) = 1/sigma sqrt(2) pi x * e^(ln x - mu)/(2 sigma)^2
sub logNormalPDFBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    print "logNormalPDFBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev\n";
    my $logNormalPeak = getLogNormalPeak($mean, $stddev, $range);
    my %logNormalDistBins = ();
    my $preTotal = 0;
    my $binWidth = $range/$numberOfBins; 
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range);
        my $y = rand($logNormalPeak);
        my $P_x = &logNormalPDFvalue($x, $mean, $stddev);
        #my $A = 1 / ($stddev * sqrt( 2 * pi ) * $x);
        #my $P_x = exp (-((log($x/$mean))**2/(2 * $stddev**2)));
        #$P_x = $A * $P_x;
                    
        if ($y < $P_x) {
            my $normValue = $P_x;
            my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
            push(@{$logNormalDistBins{$bin}}, $normValue);
            $i++;
            #print "bin = $bin normvalue = $normValue \n";
        }
    }
    my $total = 0;
    foreach my $binName (sort numeric keys %logNormalDistBins) {
        print "bin = $binName ";
        my $P_x = scalar @{$logNormalDistBins{$binName}} / ($numberOfPoints);# * $binWidth);
        print " p_x = $P_x ";
        $total += $P_x;
        print "\n";
    }
    print "total = $total\n";
    print "\n\n";
}

sub PDFLogOutput {
    my ($PDFDistLogBinsRef, $numberOfPoints, $mean, $stddev, $range, $numberOfBins, $binWidth) = @_;
    my %PDFDistLogBins = %{$PDFDistLogBinsRef};
    my $total = 0;
    my $numTotal = 0;
    my $areaTotal = 0;
    foreach my $binName (sort numeric keys %PDFDistLogBins) {
        my $sum = 0;
        my $logBinWidth = ($range**($binName/$numberOfBins) - $range**(($binName-1)/$numberOfBins));
        my $binPosition = $range**(($binName-1)/$numberOfBins) + 0.5*$logBinWidth;
        print " bin = ". $binPosition .  " ";
        print " normBin = " . ($binPosition / $stddev) ;
        my $P_x = scalar @{$PDFDistLogBins{$binName}} / ($numberOfPoints * $logBinWidth);

# now try and do a transform on the data
#        $P_x = $P_x * $stddev;
        $areaTotal += $logBinWidth * $P_x;
        print " p_x = $P_x ";
        $total += $P_x;
#        print " num = " . scalar @{$PDFDistLogBins{$binName}};
        print " normNum = " . scalar @{$PDFDistLogBins{$binName}} * $stddev;
        $numTotal += scalar @{$PDFDistLogBins{$binName}}; 
#        print " bin = $binName ";
        print " error = " . (1/sqrt($numberOfPoints)); #(1/sqrt(@{$PDFDistLogBins{$binName}}));
        print "\n";
    }
    print "total  $total numtotal = $numTotal areatotal = $areaTotal\n";
    print "\n\n";
}
# this is a gumbel pdf implementation binned;
# p_x = 1/sigma * e^(-e^((x-mu)/sigma));
sub gumbelPDFBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $binWidth) = @_;
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
