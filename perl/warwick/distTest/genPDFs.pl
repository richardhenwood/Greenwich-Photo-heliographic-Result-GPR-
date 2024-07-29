#!/usr/bin/perl -w

use POSIX;
use Data::Dumper;
use warnings;
use Math::Trig qw(pi);
#use Math::Complex qw(log);
use lib '../../external_libs/';
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use Statistics::Basic::StdDev;
use Statistics::Basic::Mean;
use Getopt::Std;
use strict;


my $numberOfPoints = 1000;
my $mean = 1;
my $stddev = 1;
my $range = 6;
my $numberOfBins = 10;
my $startValue = 0;

# we set the random seed so that we always get the same same pdf
# independent of which command line options we select.
#srand(14);

my %opts = ();
getopts("b:m:v:n:r:s:h", \%opts) ;
if (defined($opts{b})) { $numberOfBins = $opts{b}; }
if (defined($opts{m})) { $mean = $opts{m}; }
if (defined($opts{v})) { $stddev = $opts{v}; }
if (defined($opts{n})) { $numberOfPoints = $opts{n}; }
if (defined($opts{r})) { $range = $opts{r}; }
if (defined($opts{s})) { $startValue = $opts{s}; }
if (defined($opts{h})) { &usage(); }
sub usage {
    print <<END;

generates probability distribution function. See code to change which function 
is generated.

command line options include:
-h      : this text
-b #    : number of bins
-m #    : mean of the PDF
-n #    : number of points
-v #    : variance of the PDF
-r #    : range of the output values
-s #    : start of the range

example usage:
$0 -b 10 -m 1
END
    exit 0;
}

&stdlogNormalPDFLinBin($numberOfPoints, $mean, $stddev, 10, $numberOfBins);
&stdGumbelPDFLinBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $startValue);

#&normalPDF($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#&logNormalPDF($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#&logNormalPDFLinBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#&logNormalPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#print "\n\n";
#&gumbelPDF($numberOfPoints, $mean, $stddev, $range);
#print "\n\n";
#&fisherTippettPDF($numberOfPoints, $mean, $stddev, $range);
#print "\n\n";
#&fisherTippettPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#&gumbelPDFLogBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins);
#&stdGumbelPDFLinBin($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $startValue);

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
    #print "logNormalPDF\n";
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
    print "total = $i mean = $mean stddev = $stddev newmean = $newmean new_variance = $newstddev\n";
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

sub stdlogNormalPDFLinBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    print "stdLogNormalPDFLinBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    my $logNormalPeak = getStdLogNormalPeak($mean, $stddev, $range);
    my %logNormalDistBins = ();
    my $binWidth = $range/$numberOfBins;
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range);
        my $y = rand($logNormalPeak);
        my $P_x = &stdlogNormalPDFvalue($x, $mean, $stddev);
        if ($y < $P_x ) {
            my $normValue = $P_x;
            my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
            push(@{$logNormalDistBins{$bin}}, $normValue);
            $i++;
        }
    }
    &PDFLinearOutput(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
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
        my $x = rand($range);# + 1;
        my $y = rand($logNormalPeak);
        my $P_x = &logNormalPDFvalue($x, $mean, $stddev);
        if ($y < $P_x) {
            # origional binning mechanism. i think it's broken.
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            # new version.
            my $xNormF = floor(&logN($x,$range) * $numberOfBins);
            my $bin = $range**($xNormF / $numberOfBins);
            if ($xNormF >= 0) { 
                push(@{$logNormalDistBins{$bin}}, $P_x);
                $i++;
                #    print "bin $bin <- $f_x\n";
            }
        }
    }
    PDFNormalisedOutputLogBins(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
    #PDFLinearOutput(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
sub stdGumbelPDFLinBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $startValue) = @_;
    print "stdGumbelPDFLinBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    #my $logNormalPeak = &getStdGumbelPeak($mean, $stddev, $range);
    my $logNormalPeak = 0.367879441171442;
    #print "peak = $logNormalPeak";
    my %logNormalDistBins = ();
    my $binWidth = $range/$numberOfBins;
    my $i = 0;
    #exit 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range) + $startValue;
        my $y = rand($logNormalPeak);
        my $P_x = &stdGumbelPDFvalue($x, $mean, $stddev);
        #print "$i $x $y $P_x ";
        if ($y < $P_x ) {
            my $normValue = $P_x;
            my $bin = ($binWidth/2)+$binWidth * floor($x / $binWidth);# - exp($mean);
            push(@{$logNormalDistBins{$bin}}, $normValue);
            $i++;
            #    print "good!";
        }
        else {
            #print "discard";
        }
        #     print "\n";
    }
    &PDFLinearOutput(\%logNormalDistBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
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
        my $x = rand($range);# + 1;
        my $y = rand($gumbelPeak);
        my $f_x = &gumbelPDFvalue($x, $mean, $stddev);
        if ($y < $f_x) {
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            my $xNormF = floor(&logN($x,$range) * ($numberOfBins));
            my $bin = $range**($xNormF / $numberOfBins);
            if ($xNormF < 0) { $bin = 0; }
            push(@{$gumbelDistLogBins{$bin}}, $xNormF);
            #push(@{$gumbelDistLogBins{$bin}}, $f_x);
            $i++;
        }
    }
    PDFNormalisedOutputLogBins(\%gumbelDistLogBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
sub fisherTippettPDFLogBin {
    my ($numberOfPoints, $mean, $stddev, $range, $numberOfBins, $binWidth) = @_;
    print "fisherTippettPDFLogBin\n";
    print "no of points : $numberOfPoints mean $mean, stdev $stddev bins $numberOfBins\n";
    my $ftPeak = &getFisherTippettPeak($mean, $stddev, $range);
    my %FTDistLogBins = ();
    my $i = 0;
    while ($i < $numberOfPoints) {
        my $x = rand($range);#+ 1;
        my $y = rand($ftPeak);
        my $f_x = &fisherTippettPDFvalue($x, $mean, $stddev);
        if ($y < $f_x) {
            # old method.
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($x)/log($range))))/$numberOfBins)/$numberOfBins;
            # new method
            my $xNormF = floor(&logN($x,$range) * ($numberOfBins));
            my $bin = $range**($xNormF / $numberOfBins);
            if ($xNormF >= 1) { 
                push(@{$FTDistLogBins{$bin}}, $f_x);
                #    print "bin $bin <- $f_x\n";
            }
                $i++;
        }
    }
    #print Dumper %FTDistLogBins;
    PDFNormalisedOutputLogBins(\%FTDistLogBins, $numberOfPoints, $mean, $stddev, $range, $numberOfBins);
}
sub PDFNormalisedOutputLogBins {
    my ($PDFDistBinsRef, $numberOfPoints, $mean, $stddev, $range, $numberOfBins) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    #print Dumper %PDFDistLinBins;
    my $total = 0;
    my $numTotal = 0;
    my $areaTotal = 0;
    my @values = ();
    #my %binWidths = (0 => 1);
    my %binWidths = ();
    for (my $binNumber = 0; $binNumber < $numberOfBins; $binNumber++) {
        #my $xNormF = floor(&logN($binNumber,$range) * ($numberOfBins -1));
        #my $xNormF = &logN($binNumber,$numberOfBins);
        my $bin = $range**($binNumber / $numberOfBins);
        my $nextBin = $range**(($binNumber+1)/$numberOfBins);
        $binWidths{$bin} = ($nextBin - $bin);
        #my $bin = $range*($xNormF);
        #       print "binname = " . $bin;
        if (0) {
            print "$binNumber $numberOfBins $bin ";
            print "binwidth = ($nextBin - $bin) ";
            print "binwidth = " . ($nextBin - $bin);
            print "\n";
        }
    }
    foreach my $binName (sort numeric keys %PDFDistBins) {
        if (defined($binWidths{$binName})) {
            my $binWidth = $binWidths{$binName};
            my $binPosition = $binName + ($binWidth/2);
            print " BinName = $binPosition ";
            #print " binwidth = " . $binWidths{$binName};
            
            my $binContents = scalar @{$PDFDistBins{$binName}};
            $total += $binContents;
            #    print " $binContents / ($numberOfPoints * $binWidth)\n";
            $binContents = $binContents / ($numberOfPoints * $binWidth);
            $areaTotal +=  $binContents * $binWidth;
            print " contents = $binContents ";
            #print " area = $areaTotal $binWidth  contents = $binContents ";

            my $error = 1 / sqrt ($numberOfPoints);
            print " error = $error ";
            print "binwidth = $binWidth ";
            print "\n";
            #print "\n$binName ";
            #       print Dumper @{$PDFDistBins{$binName}};
            push (@values, ($binName) x @{$PDFDistBins{$binName}});
        }
        else {
            die "undefined bin!\nbinname = $binName\n"; 
        }
    }
    print "bin contents total $total numtotal = $numTotal areatotal = $areaTotal\n";
    if (1) {
        #print Dumper @values;
        my $newmean = Statistics::Basic::Mean->new(\@values)->query;
        my $newstddev = Statistics::Basic::StdDev->new(\@values)->query;
        print "stats mean = $mean stddev = $stddev newmean = $newmean variance = $newstddev\n";
    }
    print "\n\n";
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
        print "stats mean = $mean stddev = $stddev newmean = $newmean variance = $newstddev\n";
    }
    print "\n\n";
}
sub getStdLogNormalPeak {
    my ($mean, $stddev, $range) = @_;
    my $numberOfPoints = 1000;
    my $peakValue = 0;
    for (my $i = 1; $i <= $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        if (&stdlogNormalPDFvalue($x, $mean, $stddev) > $peakValue) {
            $peakValue = &stdlogNormalPDFvalue($x, $mean, $stddev);
        }
    }
    return $peakValue;
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
sub getStdGumbelPeak {
    my ($mean, $stddev, $range) = @_;
    #print "getting std Gumbel peak\n";
    my $numberOfPoints = 1000;
    my $peakValue = 0;
    for (my $i = -100; $i < $numberOfPoints; $i++) {
        my $x = ($i / $numberOfPoints) * $range;
        #    print "i = $i, $x , " . &stdGumbelPDFvalue($x, $mean, $stddev) . "\n";
        if (&stdGumbelPDFvalue($x, $mean, $stddev) > $peakValue) {
            $peakValue = &stdGumbelPDFvalue($x, $mean, $stddev);
        }
    }
    #print "returning $peakValue\n";
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
sub _logNormalPDFvalue {
    my ($x, $mean, $stddev) = @_;
    $stddev = $stddev**2;
    my $S = sqrt(log(($stddev + exp(2 * log($mean)))/exp(2 * log($mean))));
    my $M = (2 * log($mean) - $S**2)/2; 
    my $A = 1 / ($S * sqrt( 2 * pi ) * $x);
    my $P_x = exp (-((log($x)-$M)**2/(2 * $S**2)));
    $P_x = $A * $P_x;
    return $P_x;
}
sub stdlogNormalPDFvalue {
    my ($x, $mean, $stddev) = @_;
    # my $w = exp($stddev**2);
    # my $skewness = ($w + 2) * sqrt($w - 1);
    # #my $A = - (((log($x) - $mean)/$stddev) ** 2)/2;
    # my $A = - ((log($x)**2)/2*($stddev**2));
    # my $B = ($x * $stddev * sqrt(2 * pi));
    # my $P_x = exp($A) / $B;
    my $P_x = 1/($x*(sqrt(2*pi)))*(exp(-(log($x)**2)/2));
    return $P_x;
    # P_x = exp(- ((log(x)**2)/2*(stddev2**2))) / (x * stddev2 * sqrt(2 * pi))
}
sub logNormalPDFvalue {
    my ($x, $mean, $stddev) = @_;
    my $w = exp($stddev**2);
    my $skewness = ($w + 2) * sqrt($w - 1);
    #my $A = - (((log($x) - $mean)/$stddev) ** 2)/2;
    my $A = - ((log($x)**2)/2*($stddev**2));
    my $B = ($x * $stddev * sqrt(2 * pi));
    my $P_x = exp($A) / $B;
    return $P_x;
    # P_x = exp(- ((log(x)**2)/2*(stddev2**2))) / (x * stddev2 * sqrt(2 * pi))
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
sub stdGumbelPDFvalue {
    my ($x, $mean, $stddev) = @_;
    my $f_x =  exp($x) * exp(-exp($x));
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
    # t(x) = exp(((mean - ((sqrt((6 * stddev**2) / pi**2) * 0.57721)) - x)/(((6 * stddev**2) / pi**2))**0.5) - exp((mean - ((sqrt((6 * stddev**2) / pi**2) * 0.57721)) - x)/sqrt((6 * stddev**2) / pi**2)));
    # t(x) = exp(((mu - x)/beta) - exp((mu - x)/beta));
}

sub numeric {
    $a <=> $b;
}
sub logN {
    my ($x, $n) = @_;
#    print "x $x n $n " . log($x) . " " . log($n) . "\n";
    return (log($x)/log($n));
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
#&main;

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

