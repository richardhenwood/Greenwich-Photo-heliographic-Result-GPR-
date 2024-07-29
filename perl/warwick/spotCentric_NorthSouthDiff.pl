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

# This is program selects only spots who's life is completly 
# observed in the dataset.
#

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
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/2001.grp";
    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
    %sunspots = &Load_Sunspot_DateCentric($sunspots_filename);
}
    
# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";
print Dumper %sunspots;

sub find_unique_sunspots {
    my $spotSize; 
    my @maxSpotSizes = ();
    my %WholeSpotLongitudeBins = ();
    my %UmbralLongitudeBins = ();
    my $binSize = 5;
    my $minLongitude = -60;
    my $maxLongitude = 60;
    my %maxAreaBins = ();
    my @wholeLifeSpots = ();
    my @partLifeSpots = ();
    my $totalSpots = 0;
    my $avWindow = 300;
    foreach my $obsTime (sort keys %sunspots) {
        my $a_N = 0;
        my $a_S = 0;
        my $N_count = 0;
        my $S_count = 0;
        my $daysAveraged = 0;
        my $spotCount = 0;

        my @windowCentre = Add_Delta_Days(1800, 1, 1, int($avWindow/2));
        my @startTime = ($obsTime =~ /(\d+)-(\d+)-(\d+)/, 0);
        eval {
           @windowCentre = Add_Delta_Days(@startTime[0..2], int($avWindow/2));
        };
        if ($@) {
            #        print Dumper $@;
            print Dumper @startTime;
            print Dumper $avWindow;
        }
        my $windowCentreStr = sprintf("%4d-%02d-%02d", @windowCentre[0,1,2]);
        
        for (my $i = 1; $i < $avWindow; $i++) {
            my $dataFound = 0;
            my @testTime = Add_Delta_Days(@startTime[0..2], $i);
            my $avTime = sprintf("%4d-%02d-%02d", @testTime[0,1,2]);
            # print "\tav time = $avTime \n";
            foreach my $spotNumber (sort keys %{$sunspots{$avTime}}) {
                $dataFound = 1;
                foreach my $spot (@{$sunspots{$avTime}{$spotNumber}}) {
#                    print $spot->getOrigionalGreenwichFormat;
                    if ($spot->getLatitude > 0) {
                        $a_N += $spot->getCorrectedUmbralArea();
                        $N_count++;
                    }
                    else {
                        $a_S += $spot->getCorrectedUmbralArea();
                        $S_count++;
                    }
                    if ($avTime eq $windowCentreStr) {
                        if ($spot->getGroupType > 1) {
                            $spotCount += 10;
                        }
                        else {
                            $spotCount++;
                        }
                    }
                }
            }
            if ($dataFound) {
                $daysAveraged++;
            }
        }
        if ($daysAveraged > $avWindow - 150) { # here we allow a few days to be missing.
            printf "%4d-%02d-%02d", @windowCentre[0,1,2];
            my $a_NS = ($a_N - $a_S) / ($a_N + $a_S);
            print " index = $a_NS ";
            print " spotcount = $spotCount ";
            print " a_N = $a_N as = $a_S ";
            print " days = $daysAveraged a_N, a_S = $a_N $a_S ; N,S count $N_count , $S_count\n";
        }
    }
    if (0) {
        foreach my $data (sort @partLifeSpots) {
            print $data;
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
# this code is very similar to the code which shares a similar name,
# but is loads the sunspot data with the sunspot number as the key.
# we are also loading data from the origional greenwich dataset.
sub Load_Sunspot_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}
                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

