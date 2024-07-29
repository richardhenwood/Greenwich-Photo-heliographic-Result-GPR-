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

# This is just a simple class to count spots.

# source of faculae data
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1948.REV3.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/test.dat";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1892.FIN";
my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";

# load the data into a hash
#my %sunspots = ();
#my %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);

my %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

sub find_unique_sunspots {
    my %spotBins = ();
    my $binSize = 50;
    my $totalSpotSize = 0;
    my $totalSpots = 0;
    my %spotSizeCount = ();
    my $spotSize; 
    my @maxSpotSizes = ();
    my $maxLatitude = 0;
    my $minLatitude = 0;
    foreach my $spotNumber (keys (%sunspots)) {
#        print $spotNumber . " : ";
        my @spotSizes = ();
        foreach my $obsTime (keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                $spotSize = $spot->getCorrectedWholeSpotArea;
                push(@spotSizes, $spotSize);
                if ($spot->getLatitude <= $minLatitude) {
                    $minLatitude = $spot->getLatitude;
                }
                if ($spot->getLatitude >= $maxLatitude) {
                    $maxLatitude = $spot->getLatitude;
                }
            }
            #my $maxValue = join (', ', sort @{sunspots{$spotNumber}});
            #my @sortedSpots = @{$sunspots{$spotNumber}{$obsTime}};

        }
        my $maxSpotSize = (sort numeric @spotSizes)[-1];
        #$binMean = Statistics::Basic::Mean->new(\@spotSizes)->query;
        #$binStdDev = Statistics::Basic::StdDev->new(\@spotSizes)->query;
        #print "\n";
        $spotSizeCount{$maxSpotSize}++;
        #      print " mean = $binMean ";
        #print " stddev = $binStdDev ";
        #print "spot no = $spotNumber binsize $binSize, spotsize = $maxSpotSize index = ". $binSize * floor($spotSize / $binSize) . "\n";
# hash index is in the middle of the bin.
#if (!defined($spotBins{($binSize/2)+$binSize * floor($maxSpotSize / $binSize)})) {
    #           $spotBins{($binSize/2)+$binSize * floor($maxSpotSize / $binSize)} = ();
    #   }
        push(@maxSpotSizes, $maxSpotSize);
        push(@{$spotBins{($binSize/2)+$binSize * floor($maxSpotSize / $binSize)}},$maxSpotSize);
    }
    #print Dumper %spotSizeCount;
    #print scalar @maxSpotSizes;
    my $mean = Statistics::Basic::Mean->new(\@maxSpotSizes)->query;
    my $stddev = Statistics::Basic::StdDev->new(\@maxSpotSizes)->query;
    #print scalar values %spotBins;
    
    if (0) {
    foreach my $binName (sort numeric keys %spotBins) {
# lets start by asking how many spots are in each bin:
        print "bin_name = $binName members = " . scalar @{$spotBins{$binName}};
        print " including " . join (',',@{$spotBins{$binName}});

# now let's find P_x of the spot bins:
        my $P_x = scalar @{$spotBins{$binName}} / scalar (keys %sunspots);
        print " P_x = $P_x";
        
# new we can generate a guassian PDF from the numbers:
#print " mean = $mean, stddev = $stddev ";
#        my $mean = Statistics::Basic::Mean->new(\@{$spotBins{$binName}})->query;
        my $A = 1 / ($stddev * ((2 * 3.14159)**0.5));
        my $P_g = $A * exp(-(($binName - $mean)**2/$stddev**2));
        print " P_g = $P_g";
    
# do the transformation of the data:        
# calculate x^prime
            my $x_prime = ($P_x - $mean)/$stddev;
            my $p_x_prime = exp(-(($x_prime)**2));
            print " x_prime = $x_prime $p_x_prime ";

                    


         print "\n";
    } 
}
# do some statistics on the whole set
#    foreach my $spotSize (sort numeric keys %spotSizeCount) {
        #print "$spotSize " . $spotSizeCount{$spotSize} . "\n";
#        $totalSpotSize += $spotSize;
#    }

    print "maxlatitude = $maxLatitude minlatitude = $minLatitude \n";
# now output,
# bined area output 
    if (0) {
    my $binMean;
    my $binStdDev;
    foreach my $spotSize (sort numeric keys %spotBins) {
        #    print join ', ', @{$spotBins{$spotSize}};
        #print "\n\n";
        $binMean = Statistics::Basic::Mean->new($spotBins{$spotSize})->query;
        $binStdDev = Statistics::Basic::StdDev->new($spotBins{$spotSize})->query;
        if ($binStdDev == 0) {$binStdDev = 1;}
        my $P_x = $binStdDev * (scalar@{$spotBins{$spotSize}}) / $totalSpotSize;
        my $x_minus_mu_over_sigma = ($spotSize - $binMean) / $binStdDev;
        print "$spotSize $binMean $binStdDev $P_x $x_minus_mu_over_sigma\n";

        #print $spotBins{$spotSize}/$totalSpotSize . "\n";
    }
}
# each spot area output 
    if (0) {
    foreach my $spotSize (sort numeric keys %spotSizeCount) {
        print "$spotSize " . $spotSizeCount{$spotSize} . " ";
        print $spotSizeCount{$spotSize}/$totalSpotSize . "\n";
    }
}
    #print "total spot size = $totalSpotSize\n";
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

