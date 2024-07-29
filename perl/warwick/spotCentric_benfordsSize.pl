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
    $sunspots_filename = "/users/rhenwood/ihr/data/reclassification/allFiltered.txt";
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
    my %benfoldBins;
    my $totalSpots = 0;
    foreach my $spotNumber (keys (%sunspots)) {
        my @spotSizes = ();
        my @umbralSizes = ();
        my $longevity = 0;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
# add zero to make wholespotSize into numerical type.                
                my $wholespotSize = $spot->getCorrectedWholeSpotArea + 0;
                my $umbralSize = $spot->getCorrectedUmbralArea;
#                print "\n$obsTime ";
#               print $spot->getCentralMeridianDistance . " ";
#               print $spot->getCorrectedWholeSpotArea . ",";

#benfords law is simple enough. just examine the most significant figure.
#print "wholespot size = $wholespotSize ";
                my $benfoldBin = substr($wholespotSize,0,1);
                $benfoldBins{$benfoldBin}++;
                #print "'". substr($wholespotSize,0,1) . "'\n";
                
                push(@spotSizes, $wholespotSize);
                push(@umbralSizes, $umbralSize);
                $totalSpots++;
            }
            $longevity++;
        }
    }
    foreach my $benfoldBin (sort numeric keys %benfoldBins) {
        print "bin = $benfoldBin ";
        print "frequency = " . $benfoldBins{$benfoldBin};
        print " normalised = " . $benfoldBins{$benfoldBin} / $totalSpots;
        print "\n";
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

