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
#my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
my %sunspots = ();
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
    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
    %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
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
    foreach my $spotNumber (keys (%sunspots)) {
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
        if (scalar @spotSizes == 1) {
            my $maxSpotSize = (sort numeric @spotSizes)[-1];
            my $maxUmbralSize = (sort numeric @umbralSizes)[-1];
#        print "spot_no = $spotNumber ";
#        print "max = $maxSpotSize ";
#        print join(',', @spotSizes);
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
        }
        print "spot_no = $spotNumber ";
        print "max = $maxSpotSize ";
        print join(',', @spotSizes);
        print "longevity = " . $longevity; 
        print "\n";
    }
# now output the results of the longitude bining.
#print Dumper %WholeSpotLongitudeBins;
#   print Dumper %UmbralLongitudeBins;
    for (my $i = -90 + ($binSize/2); $i <= 90; $i = $i + $binSize) {
        #foreach my $binName (keys %LongitudeBins) {
        if (definied($WholeSpotLongitudeBins{$i}) {
            print "longitudeBin = $i wholeSpot = " . $WholeSpotLongitudeBins{$i} . " umbral = " . $UmbralLongitudeBins{$i} . "\n";   
        }
        else {
            print "longitudeBin = $i wholeSpot = 0 umbral = 0\n";   
        }

    }
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

