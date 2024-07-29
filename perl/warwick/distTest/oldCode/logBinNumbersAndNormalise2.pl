#!/usr/bin/perl

use strict;
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use lib '../../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
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

example: $0 -f -
EOF
    exit;
}

my %opts = ();
getopts("f:n:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $numberOfBins = 10;
if (defined($opts{n})) { $numberOfBins = $opts{n}; }

#my %sunspots = ();
#print $opts{f};
#%sunspots = &Load_Sunspot_SpotCentric($opts{f});

my %groupedNumbers = ();
while (my $line = <STDIN>) {
    if ($line =~ m/^\s*[-]*\d+/) {
        $line =~ s/\#.*//;
        chop($line);
        #print "line = $line\n";
        push(@{$groupedNumbers{-1}}, $line);
    }
}
#print Dumper %groupedNumbers;
#exit 0;

#linearBinData(\%groupedNumbers, $numberOfBins);
#QuantityBinData(\%groupedNumbers);
logBinData(\%groupedNumbers, $numberOfBins);

sub linearBinData {
    my ($ageGroupsRef, $numberOfBins) = @_;
    my %ageGroups = %{$ageGroupsRef};
    foreach my $age (sort numeric keys %ageGroups) {
        my %binnedSizes = ();
        my %spotSizeVarBins = ();
        my $spotCount = 0;
        my @tmpArr = sort @{$ageGroups{$age}};
        my $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        my $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        #print "mean = $rawMean, stdev = $rawStddev\n";
        @tmpArr = map {($_ - $rawMean)/$rawStddev} @tmpArr;
        $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        #print "mean = $rawMean, stdev = $rawStddev\n";
        my $range = $tmpArr[-1] - $tmpArr[0];
        my $minOfRange = $tmpArr[0];
        print "age $age, range = $range, count = ";
        print scalar @tmpArr;
        print " bins = $numberOfBins";
        print "\n";
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

        foreach my $maxSize (@tmpArr) {
            $maxSize = ($maxSize - $rawMean) / $rawStddev;
            my $diff = $maxSize - $ageMean;
            my $linearBinMean = floor((($maxSize-$minOfRange)/$range) * $numberOfBins);
            $linearBinMean = ($linearBinMean/$numberOfBins) * $range + $minOfRange;
            push(@{$spotSizeVarBins{$linearBinMean}}, $maxSize);
            $binWidths{$linearBinMean} = $range/$numberOfBins;
        }

        foreach my $binName (sort numeric keys %spotSizeVarBins) {
            $spotCount += scalar @{$spotSizeVarBins{$binName}};
        }
        PDFNormalisedOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev);
        print "\n\n";
    }
}

sub logBinData {
    my ($ageGroupsRef, $numberOfBins) = @_;
    my %ageGroups = %{$ageGroupsRef};
    my $numberOfAfterBins = $numberOfBins;
    my $numberOfBeforeBins = $numberOfBins;
    foreach my $age (sort numeric keys %ageGroups) {
        my %binnedSizes = ();
        my $spotCount = 0;
        my @tmpArr = sort @{$ageGroups{$age}};
        my $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        my $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        #print "mean = $rawMean, stdev = $rawStddev\n";
        @tmpArr = map {($_ - $rawMean)/$rawStddev} @tmpArr;
        $rawMean = Statistics::Basic::Mean->new(\@tmpArr)->query;
        $rawStddev = Statistics::Basic::StdDev->new(\@tmpArr)->query;
        # print "mean = $rawMean, stdev = $rawStddev\n";
        my $range = $tmpArr[-1] - $tmpArr[0];
        my $minOfRange = $tmpArr[0];
        print "age $age, range = $range, count = ";
        print scalar @tmpArr;
        print " bins = $numberOfBins";
        print "\n";
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
        PDFNormalisedOutputFromBins(\%spotSizeVarBins, \%binWidths, $spotCount, $rawMean, $rawStddev);
        print "\n\n";
    }
}



sub PDFNormalisedOutputFromBins {
    my ($PDFDistBinsRef, $binWidthsRef, $numberOfPoints, $rawMean, $rawStddev) = @_;
    my %PDFDistBins = %{$PDFDistBinsRef};
    my %binWidths = %{$binWidthsRef};
    my $total = 0;
    my $numTotal = 0;
    my $areaTotal = 0;
    my @values = ();
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
            my $binPosition = undef;
            my $binWidth = $binWidths{$binName};
#            if ($binName > 0) { 
                $binPosition = $binName + $binWidth/2;
#            } else {
#                $binPosition = $binName - $binWidth/2;
#            }
            my $binContents = scalar @{$PDFDistBins{$binName}};
            $total += $binContents;

            my $rawContents = $binContents;
            $binContents = $binContents / ($numberOfPoints * $binWidth);
            $areaTotal +=  $binContents * $binWidth;

            $cumulativeBinContents += $binContents;
            #    print " BinName = $binPosition ";
            #    print " rawContents = $rawContents ";
            #    print " NormContents = $binContents ";
            #    print " rawBinWidth = " . $binWidth;
            #    print " normalisedError = " . sqrt($rawContents)/($numberOfPoints*$binWidth);
            #my $LNmean = 1.65;
            #my $LNsigma = 2.16;
            print " minusXbarOverSigma = " . ($binPosition - $rawMean)/$rawStddev;
            print " contentsTimesSigma = " . $binContents*$rawStddev;
            #    print " cumulativeTotal = " . $areaTotal;

            #my $error = 1 / sqrt ($numberOfPoints);
            my $Xerror = $binWidth/($rawStddev*2);
            print " Xerror = $Xerror ";
            my $Yerror = (sqrt ($rawContents)/ ($numberOfPoints * $binWidth * 2)) * $rawStddev;
            print " Yerror = $Yerror ";
            #   print " BinName = $binPosition ";
            #    print " rawContents = $rawContents ";
            #print " binwidth = " . $binWidth/$rawStddev;
            #print " binOverSig = " . ($binPosition)/$rawStddev;
            #print " contentTimesSig = " . $binContents * $rawStddev;
            #print " rawError = " . sqrt($rawContents);
            #print " numberInBin = 
            print "\n";
            push (@postValues, ($binWidth/$rawStddev) x @{$PDFDistBins{$binName}});
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
    print "bin contents total $total numtotal = $numTotal areatotal = $areaTotal\n";
    if (1) {
        #$rawMean = Statistics::Basic::Mean->new(\@values)->query;
        #$rawStddev = Statistics::Basic::StdDev->new(\@values)->query;
        my $postmean = Statistics::Basic::Mean->new(\@postValues)->query;
        my $poststddev = Statistics::Basic::StdDev->new(\@postValues)->query;
        print "stats rawMean = $rawMean rawStddev = $rawStddev ";
        print "post stats newmean = $postmean newstddev = $poststddev\n";
    }
    print "\n\n";
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

        print "age $age, range = $range ";
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

