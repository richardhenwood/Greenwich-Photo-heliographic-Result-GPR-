#!/usr/bin/perl

use strict;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
#use sunspot_and_faculae;
#use sunspot;
use ussrSunspot;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Delta_Days);
use List::Util qw(sum);
use Getopt::Std;


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

This program loads a ussr format data into a spot centric hash.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in ussr format.

example: $0 -f ~/ihr/data/solnechyi/all.uniqueNumbers.dat
EOF
    exit;
}

my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my ($sunspotsRef, $sunspotsDateRef) = &Load_Sunspot_SpotCentric($opts{f});
my %sunspots = %{$sunspotsRef}; #&Load_Sunspot_DateCentric($opts{f});
my %sunspotDates = %{$sunspotsDateRef}; #&Load_Sunspot_DateCentric($opts{f});
    
&printSpotCentricSpots();


sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                print $spot->getOrigionalGreenwichFormat;
                if (0) {
                    print $spot->getDateTime;
                    print " ";
                    print $spot->getGroupNumber;
                    print " ";
                    print $spot->getCarringtonLongitude;
                    print " ";
                    print $spot->getCorrectedWholeSpotArea;
                    print " ";
                    print $spot->getSolarCycle;
                    print "\n";
                }
            }
        }
    }
}


# this subroutine loads greenwich data into a hash with the spot number as the key.
sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    my %sunspotDate_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        my $testSpotGroupNumber = $test_spot->getGroupNumber();
        if ($test_spot->getGroupNumber() eq "") {
            die "this should be a number\n$line";
        }
        if ($test_spot->getCarringtonLongitude =~ m/\d+/) {
        }
        else {
            if (defined($sunspot_array{$testSpotGroupNumber})) {
                my $previousSpotsRef = $sunspot_array{$testSpotGroupNumber};
                my %previousSpots = %{$previousSpotsRef};
                my @previousDates = keys(%previousSpots);
                my $previousSpotRef = $sunspot_array{$testSpotGroupNumber}{$previousDates[0]};
                my @previousSpots = @{$previousSpotRef};
                my $previousSpot = $previousSpots[0];
                $test_spot->putCarringtonLongitude($previousSpot->getCarringtonLongitude);
                $test_spot->putLatitude($previousSpot->getLatitude);
            }
            else {
                print "get position from previous:";
                print "line = $line";
                print $test_spot->getGroupNumber();
                print "\n";
            }
        }
            push(@{$sunspot_array{$testSpotGroupNumber}{$test_spot->getDateTime}}, $test_spot);
            push(@{$sunspotDate_array{$test_spot->getDate}{$testSpotGroupNumber}}, $test_spot);
    }
    return \%sunspot_array, \%sunspotDate_array;
}

# this function always comes in handy:
sub numeric {
    $a <=> $b;
}
