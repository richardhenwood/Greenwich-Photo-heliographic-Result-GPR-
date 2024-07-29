#!/usr/bin/perl

use strict;
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use lib '../../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
#use Statistics::Basic::Variance;
use lib '../../';
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Add_Delta_DHMS Delta_Days);
use List::Util qw(sum max);
use Getopt::Std;

# we check some of the extream events - for example - what is the largest change in latitude a spot make during it's life?
sub usage {
    print STDERR << "EOF";

This program takes a list of numbers in the format:
<number>  # ignored text comment following '#' symbol
<number>
...

and bins the numbers.

usage: $0 -f file

-f      : file containing data in formate outlined above.
-n      : number of bins [default 10]
-l      : do log binning (default linear binning)
-h      : generate high/low values - for candlestick plotting (default = off)
-x      : do not normalise the data (default off)
-r      : values * -1 (default off)
-s      : print status report at the end (default off)
-1      : normalise area under graph 1 but don't transform to mean=0,stddev=1

example: $0 -f -
EOF
    exit;
}

my %opts = ();
getopts("f:n:lhxrs1", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $numberOfBins = 10;
if (defined($opts{n})) { $numberOfBins = $opts{n}; }
my $doLinearBinning = 1;
if (defined($opts{l})) { $doLinearBinning = 0; }
my $genHighLow = 0;
if (defined($opts{h})) { $genHighLow = 1; }
my $doNotNormalise = 0;
if (defined($opts{x})) { $doNotNormalise = 1; }
my $valuesMultiplier = 1;
if (defined($opts{r})) { $valuesMultiplier = -1; }
my $outputStatus = 0;
if (defined($opts{s})) { $outputStatus = -1; }
my $makeArea1 = 0;
if (defined($opts{1})) { $makeArea1 = 1; }


#my %sunspots = ();
#print $opts{f};
#%sunspots = &Load_Sunspot_SpotCentric($opts{f});

my %groupedNumbers = ();
while (my $line = <STDIN>) {
    if ($line =~ m/^ *\s*[-]*\d+/) {
        $line =~ s/\#.*//;
        chop($line);
        #print "line = $line\n";
        push(@{$groupedNumbers{-1}}, $valuesMultiplier * $line);
    }
}
#print Dumper %groupedNumbers;
#exit 0;

my $statusSTR = "";
if ($genHighLow) {
    $statusSTR .= "genHIGHLOW ";
    &genHighLow();
}
else {
    $statusSTR .= "genBINS ";
    &genBinnedValues();
}
if ($outputStatus) {
    print STDERR "status = $statusSTR\n";
}

sub genHighLow {
    my %binOutput = ();
    for (my $numberOfBins = 20; $numberOfBins < 35; $numberOfBins += 3) {
        if ($doLinearBinning) {
            %binOutput = linearBinData(\%groupedNumbers, $numberOfBins, \%binOutput);
        }
        else {
            %binOutput = logBinData(\%groupedNumbers, $numberOfBins, \%binOutput);
        }
    }
    #print Dumper %binOutput;
    &printBinnedOutput(\%binOutput);
}
sub genBinnedValues {
    my %binOutput = ();
    if ($doLinearBinning) {
        %binOutput = linearBinData(\%groupedNumbers, $numberOfBins, \%binOutput);
    }
    else {
        %binOutput = logBinData(\%groupedNumbers, $numberOfBins, \%binOutput);
    }
    &printBinnedOutput(\%binOutput);
}
sub printBinnedOutput {
    my $binRef = shift;
    my %binOutput = %{$binRef};
    foreach my $binNumber (sort numeric keys %binOutput) {
        print "binvalue = $binNumber ";
        #  print "members = ";
        my $minContentTimesSigma = 9999;
        my $maxContentTimesSigma = 0;
        my $minYerror = 9999;
        my $maxYerror = 0;
        foreach my $valuesRef (@{$binOutput{$binNumber}}) {
            #print Dumper $valuesRef;
            my @valuesArr = @{$valuesRef};
            $minContentTimesSigma = $valuesArr[0] if $minContentTimesSigma > $valuesArr[0];
            $maxContentTimesSigma = $valuesArr[0] if $maxContentTimesSigma < $valuesArr[0];
            $minYerror = $valuesArr[2] if $minYerror > $valuesArr[2];
            $maxYerror = $valuesArr[2] if $maxYerror < $valuesArr[2];
            
        }
        print " minYvalue = ";
        print $minContentTimesSigma;
        print " minYIncError = ";
        print $minContentTimesSigma - $maxYerror;
        print " maxYIncError = ";
        print $maxContentTimesSigma + $maxYerror;
        print " maxYvalue = ";
        print $maxContentTimesSigma;
       
        #print $maxContentTimesSigma + $maxYerror;
        #print scalar (@{$binOutput{$binNumber}});
        print "\n";
    }
}

sub linearBinData {
    my ($ageGroupsRef, $numberOfBins, $binOutputRef) = @_;
    my %ageGroups = %{$ageGroupsRef};
    $statusSTR .= "linearBINNING ";
    foreach my $age (sort numeric keys %ageGroups) {
        
        my %binnedSizes = ();
        my %spotSizeVarBins = ();
        my $spotCount = 0;
        my @tmpArr = sort numeric @{$ageGroups{$age}};
        my $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        my $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        $statusSTR .= " initMean = $rawMean initstddev = $rawStddev ";
        if (!$doNotNormalise) {
            @tmpArr = map {($_ - $rawMean)/$rawStddev} @tmpArr;
            $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
            $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        }
        my $range = $tmpArr[-1] - $tmpArr[0] + 0.00000000001; # add a bit so value/range < 1
        my $minOfRange = $tmpArr[0];
        my %binWidths = ();

        #initialise bins 
        foreach my $value (@tmpArr) {
            #$value = ($value - $rawMean) / $rawStddev;
            #my $diff = $value - $ageMean;
            my $linearBinMean = floor((($value-$minOfRange)/$range) * $numberOfBins);
            # print "$value - $minOfRange initlinearmean = $linearBinMean\n";
            $linearBinMean = ($linearBinMean/$numberOfBins) * $range + $minOfRange;
            # print "aftlinearmean = $linearBinMean\n";
            push(@{$spotSizeVarBins{$linearBinMean}}, $value);
            $binWidths{$linearBinMean} = $range/$numberOfBins;
        }
        for (my $binNo = 0; $binNo < $numberOfBins; $binNo++) {
            my $linearBinMean = ($binNo/$numberOfBins) * $range + $minOfRange;
            if (!defined($binWidths{$linearBinMean})) {
                $binWidths{$linearBinMean} = $range/$numberOfBins;
            }
        }

        foreach my $binName (sort numeric keys %spotSizeVarBins) {
            $spotCount += scalar @{$spotSizeVarBins{$binName}};
        }

        $statusSTR .= "rawmean = $rawMean rawstdev = $rawStddev count = $spotCount ";
        if ($doNotNormalise) {
            return %{RawOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev, $binOutputRef)};
        }
        else {
            return %{PDFNormalisedOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev, $binOutputRef)};
        }
    }
}

sub logBinData {
    my ($ageGroupsRef, $numberOfBins, $binOutputRef) = @_;
    my %ageGroups = %{$ageGroupsRef};
    $statusSTR .= "logBINNING ";
    my $numberOfAfterBins = $numberOfBins;
    my $numberOfBeforeBins = $numberOfBins;
    foreach my $age (sort numeric keys %ageGroups) {
        my %binnedSizes = ();
        my $spotCount = 0;
        my @tmpArr = sort numeric @{$ageGroups{$age}};
        my $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        my $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        #print "mean = $rawMean, stdev = $rawStddev\n";
        @tmpArr = map {($_ - $rawMean)/$rawStddev} @tmpArr;
        $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        # print "mean = $rawMean, stdev = $rawStddev\n";
        my $range = $tmpArr[-1] - $tmpArr[0];
        my $minOfRange = $tmpArr[0];
        #print "age $age, range = $range, count = ";
        #print scalar @tmpArr;
        #print " bins = $numberOfBins";
        #print "\n";
# get the mean of the population;
        my $meanCount = 0;
        my $meanTotal = 0;
        my $totalMin = 9999999;
        my $totalMax = 0;
        foreach my $maxSize (@tmpArr) {
            $maxSize = ($maxSize - $rawMean) / $rawStddev;
            if ($maxSize < $totalMin) {
                $totalMin = $maxSize;
            }
            if ($maxSize > $totalMax) {
                $totalMax = $maxSize;
            }
            $meanTotal += $maxSize; 
            $meanCount++;
        }
        my $ageMean = $meanTotal/$meanCount;
        my %binWidths = ();
        my %spotSizeVarBins = ();
        #my %spotSizeLogBins = ();

        foreach my $maxSize (@tmpArr) {
            $maxSize = ($maxSize - $rawMean) / $rawStddev;
            my ($xNormF, $xNormFc, $bin, $binWidth);
            my $diff = $maxSize - $ageMean;
            if ($diff >= 1) {
                $xNormF = floor(&logN($maxSize - $ageMean,$range) * $numberOfAfterBins);
                $bin = $range**($xNormF / $numberOfAfterBins);
                if (!defined($binWidths{$bin})) {
                    $xNormFc = $xNormF + 1;
                    $binWidth = $bin - $range**($xNormFc / $numberOfAfterBins) ;
                    $binWidths{$bin} = abs($binWidth);
                }
                push(@{$spotSizeVarBins{$bin}}, $maxSize);
            } elsif ($diff >= -1 && $diff < 0) {
                push(@{$spotSizeVarBins{-1}}, $maxSize);
                $binWidths{-1} = 1;
            } elsif ($diff >= 0 && $diff < 1) {
                push(@{$spotSizeVarBins{0}}, $maxSize);
                $binWidths{0} = 1;
            } elsif ($diff < -1) {
                $xNormF = ceil(&logN($ageMean - $maxSize,$range) * $numberOfBeforeBins);
                $bin = $range**($xNormF / $numberOfBeforeBins);
                if (!defined($binWidths{$bin})) {
                    $xNormFc = $xNormF - 1;
                    $binWidth = $bin - $range**($xNormFc / $numberOfBeforeBins);
                    $binWidths{0 - $bin} = abs($binWidth);
                }
                push(@{$spotSizeVarBins{0 - $bin}}, $maxSize);;
            } else { die ("value is invalid\n"); }
        }

        foreach my $binName (sort numeric keys %spotSizeVarBins) {
            $spotCount += scalar @{$spotSizeVarBins{$binName}};
        }
        #print Dumper %binWidths;
        if ($doNotNormalise) {
            return %{RawOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev, $binOutputRef)};
        }
        else {
            return %{PDFNormalisedOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev, $binOutputRef)};
        }
        #print "\n\n";
    }
}
sub RawOutputFromBins {
    my ($PDFDistBinsRef, $binWidthsRef, $numberOfPoints, $rawMean, $rawStddev, $binOutputRef) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    my %binWidths = %{$binWidthsRef};
    my %binOutput = %{$binOutputRef};
    my @postValues = ();
    $statusSTR .= "rawOutput ";
    my $total = 0;
    if (!$makeArea1) {
        $numberOfPoints = 1;
    }
    foreach my $binName (sort numeric keys %binWidths) {
        my $binWidth = $binWidths{$binName};
        my $binPosition = $binName + $binWidth/2;
        if (defined($PDFDistBins{$binName})) {
            my $binContents = scalar @{$PDFDistBins{$binName}};
            push(@{$binOutput{$binPosition}}, [$binContents/$numberOfPoints, 0, 0]);
            push (@postValues, $binWidth x @{$PDFDistBins{$binName}});
            $total += $binContents;
        }
        else {
            push(@{$binOutput{$binPosition}}, [0, 0, 0]);
        }
    }
    my $postmean = Statistics::Basic::Mean->new(\@postValues)->query;
    my $poststddev = Statistics::Basic::StdDev->new(\@postValues)->query;
    my $postvariance = Statistics::Basic::Variance->new(\@postValues)->query;
    #$statusSTR .= "post stats newmean = $postmean stdev = $poststddev newvariance = $postvariance ";
    $statusSTR .= " total = $total ";
    return \%binOutput;
}

sub PDFNormalisedOutputFromBins {
    my ($PDFDistBinsRef, $binWidthsRef, $numberOfPoints, $rawMean, $rawStddev, $binOutputRef) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    my %binWidths = %{$binWidthsRef};
    $statusSTR .= "normalising ";
    my $total = 0;
    my $numTotal = 0;
    my $areaTotal = 0;
    my @values = ();
    my %binOutput = %{$binOutputRef};
##
# this section calculates stddev and mean;
##
    foreach my $binName (sort numeric keys %PDFDistBins) {
        if (defined($binWidths{$binName})) {
            push (@values, ($binName) x @{$PDFDistBins{$binName}});
        }
        else {
            print STDERR Dumper %PDFDistBins;
            foreach my $binName (sort numeric keys %binWidths) {
                print STDERR "binname: $binName => " . $binWidths{$binName} . "\n";
            }
            die "calculating stddev and mean, undefined bin!\nbinname = $binName\n";
        }
    }
##
# and finally calculate the normalised values
##
    my @postValues = ();
    my $cumulativeBinContents = 0;
    foreach my $binName (sort numeric keys %PDFDistBins) {
        if (defined($binWidths{$binName}) && $rawStddev != 0) {
            my $binWidth = $binWidths{$binName};
            my $binPosition = $binName + $binWidth/2;
            my $binContents = scalar @{$PDFDistBins{$binName}};
            $total += $binContents;

            my $rawContents = $binContents;
            $binContents = $binContents / ($numberOfPoints * $binWidth);
            $areaTotal +=  $binContents * $binWidth;

            $cumulativeBinContents += $binContents;
            my $Xerror = $binWidth/($rawStddev*2);
            my $Yerror = (sqrt ($rawContents)/ ($numberOfPoints * $binWidth * 2)) * $rawStddev;
             
            push (@postValues, ($binWidth/$rawStddev) x @{$PDFDistBins{$binName}});
            push(@{$binOutput{($binPosition - $rawMean)/$rawStddev}}, [$binContents*$rawStddev, $Xerror, $Yerror]);
            
            if ($genHighLow) { 
                push(@{$binOutput{(($binPosition -($binWidth/2)) - $rawMean)/$rawStddev}}, [$binContents*$rawStddev, $Xerror, $Yerror]);
                push(@{$binOutput{(($binPosition +($binWidth/2)) - $rawMean)/$rawStddev}}, [$binContents*$rawStddev, $Xerror, $Yerror]);
            }
        }
        elsif ($rawStddev == 0) {
            print "only one point!\n";
            print "ignoring.\n";
        }
        else {
            print STDERR Dumper %PDFDistBins;
            foreach my $binName (sort numeric keys %binWidths) {
                print STDERR "binname: $binName => " . $binWidths{$binName} . "\n";
            }
            die "undefined bin!\nbinname = $binName\n";
        }
    }
    if (1) {
        my $postmean = Statistics::Basic::Mean->new(\@postValues)->query;
        my $poststddev = Statistics::Basic::StdDev->new(\@postValues)->query;
        #my $postvariance = Statistics::Basic::Variance->new(\@postValues)->query;
        $statusSTR .= "post stats newmean = $postmean stdev = $poststddev";
        $statusSTR .= " total = $areaTotal ";
    }
    return \%binOutput;
}







# this function always comes in handy:
sub numeric {
    $a <=> $b;
}
sub logN {
    my ($x, $n) = @_;
    return log($x)/log($n);
}

##############################################
# unused functions below
##############################################
sub _rawOutputFromBins {
    my ($PDFDistBinsRef, $binWidthsRef, $numberOfPoints, ) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    my %binWidths = %{$binWidthsRef};
    foreach my $binName (sort numeric keys %PDFDistBins) {
        my $binContents = scalar @{$PDFDistBins{$binName}};
        my $binWidth = $binWidths{$binName};
        my $binPosition = $binName + $binWidth/2;
        print " BinName = $binPosition ";
        print " rawContents = $binContents ";
        print "\n";
    }
}

sub _QuantityBinData {
    my ($ageGroupsRef) = @_;
    my %ageGroups = %{$ageGroupsRef};
    my $numberPerBin = 12;
    foreach my $age (sort numeric keys %ageGroups) {
        my %binnedSizes = ();
        my %spotSizeVarBins = ();
        my $spotCount = 0;
        my @tmpArr = sort @{$ageGroups{$age}};
        my $range = $tmpArr[-1] - $tmpArr[0];

        print "age $age, range = $range\n";
# get the mean of the population;
        my $meanCount = 0;
        my $meanTotal = 0;
        foreach my $maxSize (sort @{$ageGroups{$age}}) {
            $meanTotal += $maxSize; 
            $meanCount++;
        }
        my $ageMean = $meanTotal/$meanCount;

        my %binWidths = ();
        my @varBinContents = ();
        my $inBin = 1;
        foreach my $maxSize (sort @{$ageGroups{$age}}) {
            my $maxSize = $maxSize - $ageMean;
            push (@varBinContents, $maxSize);

            if ($inBin % $numberPerBin == 0) {
                my $varBinMean = Statistics::Basic::Mean->new(\@varBinContents)->query;
                #  my $varBinStddev = Statistics::Basic::StdDev->new(\@varBinContents)->query;
                my $varBinRange = $varBinContents[-1] - $varBinContents[0];
                push(@{$spotSizeVarBins{$varBinMean}}, @varBinContents);
                $binWidths{$varBinMean} = $varBinRange;

                @varBinContents = ();
            }
            $inBin++;
        }

        foreach my $binName (sort numeric keys %spotSizeVarBins) {
            $spotCount += scalar @{$spotSizeVarBins{$binName}};
        }
        print "total count = $spotCount\n";

        PDFNormalisedOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount);
        print "\n\n";
    }
}


sub _logBinData {
    my ($ageGroupsRef, $numberOfBins) = @_;
    my %ageGroups = %{$ageGroupsRef};
    my $numberOfAfterBins = $numberOfBins;
    my $numberOfBeforeBins = $numberOfBins;
    foreach my $age (sort numeric keys %ageGroups) {
        my %binnedSizes = ();
        my %spotSizeLogBins = ();
        my $spotCount = 0;
        my @tmpArr = sort @{$ageGroups{$age}};
        my $range = $tmpArr[-1] + 1;

#        print "age $age, range = $range ";
# get the mean of the population;
        my $meanCount = 0;
        my $meanTotal = 0;
        foreach my $maxSize (sort @{$ageGroups{$age}}) {
            $meanTotal += $maxSize; 
            $meanCount++;
        }
        my $ageMean = $meanTotal/$meanCount;

        my %binWidths = ();
        foreach my $maxSize (sort @{$ageGroups{$age}}) {
            my ($xNormF, $xNormFc, $bin, $binWidth);
            my $diff = $maxSize - $ageMean;
            if ($diff >= 1) {
                $xNormF = floor(&logN($maxSize - $ageMean,$range) * $numberOfAfterBins);
                $bin = $range**($xNormF / $numberOfAfterBins);
                if (!defined($binWidths{$bin})) {
                    $xNormFc = $xNormF + 1;
                    $binWidth = $bin - $range**($xNormFc / $numberOfAfterBins) ;
                    $binWidths{$bin} = abs($binWidth);
                }
                push(@{$spotSizeLogBins{$bin}}, $maxSize);
            } elsif ($diff >= -1 && $diff < 0) {
                push(@{$spotSizeLogBins{-1}}, $maxSize);
                $binWidths{-1} = 1;
            } elsif ($diff >= 0 && $diff < 1) {
                push(@{$spotSizeLogBins{0}}, $maxSize);
                $binWidths{0} = 1;
            } elsif ($diff < -1) {
                $xNormF = ceil(&logN($ageMean - $maxSize,$range) * $numberOfBeforeBins);
                $bin = $range**($xNormF / $numberOfBeforeBins);
                if (!defined($binWidths{$bin})) {
                    $xNormFc = $xNormF - 1;
                    $binWidth = $bin - $range**($xNormFc / $numberOfBeforeBins);
                    $binWidths{0 - $bin} = abs($binWidth);
                }
                push(@{$spotSizeLogBins{0 - $bin}}, $maxSize);;
            } else { die ("value is invalid\n"); }
        }

        foreach my $binName (sort numeric keys %spotSizeLogBins) {
            $spotCount += scalar @{$spotSizeLogBins{$binName}};
        }
        print "total count = $spotCount\n";

        PDFNormalisedOutputFromBins(\%spotSizeLogBins, \%binWidths, $spotCount);
        print "\n\n";
    }
}



1;
