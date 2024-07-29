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
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/all.txt";
#my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/section.txt";
my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";

# load the data into a hash
#my %sunspots = ();
#my %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);
my %sunspots = &Load_Sunspot_DateCentric($sunspots_filename);

# %sunspots hash needs to be populated for this following sub to work.
&calculateSunspotNumber();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

sub calculateSunspotNumber {
#    my %spotBins = ();
#    my $binSize = 50;
#    my $totalSpotSize = 0;
#    my $totalSpots = 0;
#    my %spotSizeCount = ();
#    my $spotSize; 
#    my @maxSpotSizes = ();
    my %sunspotYearHash = ();
    foreach my $obsTime (sort keys (%sunspots)) {
#        my $prevLatitude = 0;
#        print $spotNumber . " : ";
#        print " $obsTime\n";
#        my $firstTime = 1;
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
#            my @spotSizes = ();
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                #print $spot->getGroupNumber . " ";
                #if ($firstTime) {
                    #    print " 0 ";
#                    $firstTime = 0;
#                }
#                else {
#                    printf ("%2.1f", $prevLatitude - $spot->getLatitude );
#                }
                my $spotYear = $spot->year();
                if (!defined($sunspotYearHash{$spotYear})) {
                    $sunspotYearHash{$spotYear} = 0; 
                }
                if ($spot->Greenwich_group_type() >= 2) {
                    $sunspotYearHash{$spotYear} += 10;
                }
                else {
                    $sunspotYearHash{$spotYear}++;
                }

#                print $spot->getGroupNumber . " ";
#                print $spot->getLatitude . " ";
#                print $spot->getCarringtonLongitude . " ";
##                print $spot->getLongitude . " ";
#                print $spot->getCorrectedUmbralArea . " ";
#                print $spot->getCorrectedWholeSpotArea . " ";
#               
#                print "\n";
                #               $prevLatitude = $spot->getLatitude; 
                #print $spot->getOrigionalGreenwichFormat();
                #    my $spotSize = $spot->getCorrectedWholeSpotArea;
                #push(@spotSizes, $spotSize);
            }
            #my $maxSize = (sort numeric @spotSizes)[-1];
            #print join ', ', @spotSizes;
            #print " max sixe = $maxSize\n";
            #my $maxValue = join (', ', sort @{sunspots{$spotNumber}});
            #my @sortedSpots = @{$sunspots{$spotNumber}{$obsTime}};
        }
    }
    foreach my $year (sort keys %sunspotYearHash) {
        print "$year " . $sunspotYearHash{$year} . "\n";
    }
    #print Dumper %sunspotYearHash;
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
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
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
#sub numeric {
#    $a <=> $b;
#}

1;
