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
my $sunspots_filename = "/users/rhenwood/tmp/sunspots/greenwich/section.txt";

# load the data into a hash
#my %sunspots = ();
#my %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);
my %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);

# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

sub find_unique_sunspots {
#    my %spotBins = ();
#    my $binSize = 50;
#    my $totalSpotSize = 0;
#    my $totalSpots = 0;
#    my %spotSizeCount = ();
#    my $spotSize; 
#    my @maxSpotSizes = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $prevLatitude = 0;
#        print $spotNumber . " : ";
#my @spotSizes = ();
            my $firstTime = 1;
        foreach my $obsTime (keys %{$sunspots{$spotNumber}}) {
            print " $obsTime ";
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #$spotSize = $spot->getCorrectedWholeSpotArea;
                print $spot->getGroupNumber . " ";
                if ($firstTime) {
                    print " 0 ";
                    $firstTime = 0;
                }
                else {
                    printf ("%2.1f", $prevLatitude - $spot->getLatitude );
                }
               print $spot->getLatitude . " ";

                print $spot->getCarringtonLongitude . " ";
                print $spot->getLongitude . " ";

               
                print "\n";
                $prevLatitude = $spot->getLatitude; 
                #print $spot->getOrigionalGreenwichFormat();
                # push(@spotSizes, $spotSize);
            }
            #my $maxValue = join (', ', sort @{sunspots{$spotNumber}});
            #my @sortedSpots = @{$sunspots{$spotNumber}{$obsTime}};
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

# this code is very similar to the code which shares a similar name,
# but is loads the sunspot data with the sunspot number as the key.
# we are also loading data from the origional greenwich dataset.
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

1;
