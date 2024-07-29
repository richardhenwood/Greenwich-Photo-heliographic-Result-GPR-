#!/usr/bin/perl

use strict;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
use sunspot_and_faculae;
use sunspot;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;

# source of faculae data
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1948.REV3.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/test.dat";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1892.FIN";
#my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
my %sunspots = ();
my $sunspots_filename = "";
if (0) {
    #my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/1949.REV3.txt";
    my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
    # load the data into a hash
    #my %sunspots = ();
    %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);
}
if (1) {
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/section.txt";
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/1949.txt";
#    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
#my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/spotWholeLife.txt";
#    $sunspots_filename = "/users/rhenwood/ihr/data/reclassification/allFiltered.txt";
    $sunspots_filename = "/users/rhenwood/ihr/data/reclassification/byAge/1.1.txt";
    
}

my %opts = ();
my $normalisationON = 0;
getopt ('f:b:n', \%opts);
if (defined($opts{'f'})) {
   $sunspots_filename = $opts{'f'}; 
}
%sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
if (defined($opts{'n'})) {
    $normalisationON = 1;
}
my $bins = 30;
if (defined($opts{'b'})) {
    $bins = $opts{'b'};
}

# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

sub find_unique_sunspots {
    my $spotSize; 
    my @maxSpotSizes = ();
    my %WholeSpotLongitudeBins = ();
    my %UmbralLongitudeBins = ();
    my $binSize = 5;
    my $totalNumberOfSpots = 0;
    my $sizeRange = 1226;
    my $numberOfSizeBins = $bins;
    my $sizeBinWidth = $sizeRange/$numberOfSizeBins;
    my %sizeBins = ();
    my %sizeLogBins = ();
    foreach my $spotNumber (keys (%sunspots)) {
        $totalNumberOfSpots++;
        my @spotSizes = ();
        my @umbralSizes = ();
        my $longevity = 0;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                my $wholespotSize = $spot->getCorrectedWholeSpotArea;
                my $umbralSize = $spot->getCorrectedUmbralArea;
#                print "\n$obsTime ";
#               print $spot->getCentralMeridianDistance . " ";
#               print $spot->getCorrectedWholeSpotArea . ",";
                push(@spotSizes, $wholespotSize);
                push(@umbralSizes, $umbralSize);
            }
            $longevity++;
        }
# we want to find out the central meridian distacne of the 
# spot when it is at it's largest.
# i'm going to do this crudely to start with.
        my $maxSpotSize = (sort numeric @spotSizes)[-1];
        my $maxUmbralSize = (sort numeric @umbralSizes)[-1];
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #    print "max spot = $maxSpotSize checking: " . $spot->getCorrectedWholeSpotArea . "\n";
                if ($spot->getCorrectedWholeSpotArea == $maxSpotSize) {
#                    print "max_longitude = " . $spot->getCentralMeridianDistance. "\n";
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    $WholeSpotLongitudeBins{$bin}++;
#                    print "bin = $bin\n";
                }
                if ($spot->getCorrectedUmbralArea == $maxUmbralSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    $UmbralLongitudeBins{$bin}++;
                }
            }
        }
#        print "spot_no = $spotNumber ";
#        print "max = $maxSpotSize ";
#        print join(',', @spotSizes);
#        print "longevity = " . $longevity; 
#        print "\n";
        push(@maxSpotSizes, $maxSpotSize);
        my $sizeBinName = ($sizeBinWidth/2)+$sizeBinWidth * floor($maxSpotSize / $sizeBinWidth);# - exp($mean);
        push(@{$sizeBins{$sizeBinName}}, $maxSpotSize);

        my $sizeLogBinName = ceil($numberOfSizeBins * (log($maxSpotSize)/log($sizeRange)));
        push(@{$sizeLogBins{$sizeLogBinName}}, $maxSpotSize);                             
    }
    my $spotsStddev = Statistics::Basic::Mean->new(\@maxSpotSizes)->query;
    print "total spots = '$totalNumberOfSpots'\n";
    my $maxSpotStdDev = Statistics::Basic::StdDev->new(\@maxSpotSizes)->query;
    print "max spot stddev = '$maxSpotStdDev'\n";
    print "max spot mean = " . Statistics::Basic::Mean->new(\@maxSpotSizes)->query;
    print "\n";
    print "range: " . (sort numeric @maxSpotSizes)[0] . " -> " . (sort numeric @maxSpotSizes)[-1];
    print "\n";
# now output the results of the longitude bining.
#print Dumper %WholeSpotLongitudeBins;
#   print Dumper %UmbralLongitudeBins;
    for (my $i = -90 + ($binSize/2); $i <= 90; $i = $i + $binSize) {
        #foreach my $binName (keys %LongitudeBins) {
            #print "longitudeBin = $i wholeSpot = " . $WholeSpotLongitudeBins{$i} . " umbral = " . $UmbralLongitudeBins{$i} . "\n";   
    }
    print "\n\n";
    foreach my $binName (sort numeric keys %sizeBins) {
        my $sum = 0;
        $sum += $_ for @{$sizeBins{$binName}};
        $sum = $sum / ($totalNumberOfSpots * $sizeBinWidth);
        print "bin = $binName ";
        my $P_x = scalar @{$sizeBins{$binName}} / ($totalNumberOfSpots * $sizeBinWidth);
        print " p_x = $P_x ";
        print " sum = $sum ";
        print "\n";
    }
    print "\n\n";
    my $cumulative = 0;
    foreach my $binName (sort numeric keys %sizeLogBins) {
        my $sum = 0;
        $sum += $_ for @{$sizeLogBins{$binName}};
        $sum = $sum / ($totalNumberOfSpots * $sizeBinWidth);
        my $logBinWidth = ($sizeRange**($binName/$numberOfSizeBins) - $sizeRange**(($binName-1)/$numberOfSizeBins));
        my $binPosition = $sizeRange**(($binName-1)/$numberOfSizeBins) + 0.5*$logBinWidth;
        my $binLowBound = log($sizeRange**(($binName-1)/$numberOfSizeBins));
        my $binHighBound = log($sizeRange**(($binName-1)/$numberOfSizeBins)) + log($logBinWidth);
        $logBinWidth = $binHighBound - $binLowBound;
        #$binPosition = $binLowBound + $logBinWidth/2;
        print "logbin = $binPosition ";
        my $logBinPrime = $binPosition / $spotsStddev;
        print " bin_prime = $logBinPrime ";
        #my $P_x = scalar @{$sizeLogBins{$binName}} / ($totalNumberOfSpots);# * $logBinWidth);
        my $P_x = (((scalar @{$sizeLogBins{$binName}})/$totalNumberOfSpots) / ($binName)) * (1/$logBinWidth);
        # now, i want to normalise these values to make a 
        # proper PDF, so I think I divide them by the stddev.
        # hmmmm i've tried it and maybe not.
        #$P_x = $P_x / $spotsStddev;
        print " p_x = $P_x ";
        print " sum = $sum ";
        $cumulative += $P_x;
        print " cumulative = $cumulative ";
        print "\n";
    }
    print "\n\n";
}


    
# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot_and_Faculae_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

# this code is very similar to the code which shares a similar name,
# but is loads the sunspot data with the sunspot number as the key.
sub Load_Sunspot_and_Faculae_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
        }
    }
    return %sunspot_array;
}

sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
        }
    }
    return %sunspot_array;
}


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

