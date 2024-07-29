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


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

It produces an output of averaged spots. 
This becomes relevant if you have a dataset which is linked.
In linked data you can have multiple spots at a given time with
the same number.

usage: $0 -f file

-f      : file containing data, in Greenwich format.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        #print "spot number = $spotNumber\n";
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            #    print "obs time = $obsTime \n"; 
            my @uniqueSpots = ();
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (&isUnique(\@uniqueSpots, $spot)) {
                    #   print $spot->getDateTime;
                    #   print " ";
                    #   print $spot->getGroupNumber;
                    #   print " ";
                    #   print $spot->getCorrectedWholeSpotArea;
                    #   print " ";
                    #   print $spot->getLatitude;
                    #   print " ";
                    #   print $spot->getLongitude;
                    #   print "\n";
                    #        print $spot->getOrigionalGreenwichFormat;
                    push(@uniqueSpots, $spot);
                }
            }
            my $avSpot = &getAverageSpot(@uniqueSpots);
            #print "average spot: ";
            #print $avSpot->getDateTime;
            #print " ";
            #print $avSpot->getGroupNumber;
            #print " ";
            #print $avSpot->getCorrectedWholeSpotArea;
            #print " ";
            #print $avSpot->getLatitude;
            #print " ";
            #print $avSpot->getLongitude;
            #print "\n";
            print $avSpot->getOrigionalGreenwichFormat;
        }
    }
}

sub getAverageSpot {
    my @spots = @_;
    if (!@spots) { print "empty set evalulating!\n";return; }
    my $avSpot = $spots[0];
    my $avLatitude = 0;
    my $avLongitude = 0;
    my $avCarringtonLongitude = 0;
    my $avCWSArea = 0;
    my $avCUArea = 0;
    my $avPWSArea = 0;
    my $avPUArea = 0;
    my $numberOfSpots = 0;
    foreach my $spot (@spots) {
        $avLatitude += $spot->getLatitude;
        $avLongitude += $spot->getLongitude;
        $avCarringtonLongitude += $spot->getCarringtonLongitude;
        $avCWSArea += $spot->getCorrectedWholeSpotArea;
        $avCUArea += $spot->getCorrectedUmbralArea;
        $avPWSArea += $spot->getProjectedWholeSpotArea;
        $avPUArea += $spot->getProjectedUmbralArea;
        
        $numberOfSpots++;
    }
    $avSpot->putLatitude($avLatitude/$numberOfSpots);
    $avSpot->putLongitude($avLongitude/$numberOfSpots);
    $avSpot->putCarringtonLongitude($avCarringtonLongitude/$numberOfSpots);
    $avSpot->putCorrectedWholeSpotArea($avCWSArea/$numberOfSpots);
    $avSpot->putCorrectedUmbralArea($avCUArea/$numberOfSpots);
    $avSpot->putCalculatedProjectedWholeSpot($avPWSArea/$numberOfSpots);
    $avSpot->putCalculatedProjectedUmbralArea($avPUArea/$numberOfSpots);
    return $avSpot;
}

sub isUnique {
    my ($arrRef, $spotRef) = @_;
    my @spotsArray = @{$arrRef};
    if (!@spotsArray) { return 1; } 
    foreach my $existingSpot (@spotsArray) {
        if ($existingSpot->getLatitude == $spotRef->getLatitude &&
            $existingSpot->getLongitude == $spotRef->getLongitude) {
            return 0;
        }
    }
    return 1;
}

# this subroutine loads greenwich data into a hash with the spot number as the key.
sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        # ignore all lines which start with a '#' or are blank
        if (!($line =~ m/^</ || $line =~ m/^\s+/)) {
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
    }
    return %sunspot_array;
}

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
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

