#!/usr/bin/perl

use strict;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
#use sunspot_and_faculae;
#use wilsonSunspot;
#use ussrSunspot;
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

It outputs a carrington map

usage: $0 -f file

-f      : file containing data, in Greenwich format.

example: $0 -f /users/rhenwood/ihr/data/wilson/mtwilson.88
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
    #print Dumper %sunspots;
    #exit 0;
    print "carrinton# Clongitude latitude size sunspot#\n";
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $previousSpot = undef;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            my $passesCentralMeridian = 0;
            #print "$spotNumber obstime = $obsTime \n";
            #print Dumper %{$sunspots{$spotNumber}};
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (defined($previousSpot)) {
                    my $currentCMD = $spot->getCentralMeridianDistance;
                    my $previousCMD = 90;
                        $previousCMD = $previousSpot->getCentralMeridianDistance;
                    if ($currentCMD > 0 && $previousCMD < 0) {
                        $passesCentralMeridian = 1;
                    }
                    if ($passesCentralMeridian) {
                        #print "passedCMD!\n";
                        my $previousSpotDateTime = $previousSpot->getDateTime;
                        my $thisSpotDateTime = $spot->getDateTime;
                        #print " $previousSpotDateTime $thisSpotDateTime"; 
                        #print " $currentCMD, $previousCMD\n";

                        my $closestSpot = $spot;
                        if (abs($currentCMD) > abs($previousCMD)) {
                            #print "closest:\n";
                            #print $previousSpot->getOrigionalGreenwichFormat;
                            $closestSpot = $previousSpot;
                        }
                        print $closestSpot->getCarringtonRotationNumber;
                        print " ";
                        print $closestSpot->getCarringtonLongitude;
                        print " ";
                        print $closestSpot->getLatitude;
                        print " ";
                        print $closestSpot->getCorrectedWholeSpotArea;
                        print " ";
                        print " $spotNumber ";
                        print "\n";
                    }
                    $passesCentralMeridian = 0;
                }
                $previousSpot = $spot;
            }
        }
    }
}

sub printDateCentricSpots {
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                print $spot->getDateTime;
                my $thisSpotDateTime = $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print " ";
                print $spot->getSun_East_Limb;
                print " ";
                print $spot->getSun_West_Limb;

                print "\n";
            }
        }
    }
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
            if ($test_spot->getGroupNumber() eq '') {
                print Dumper $test_spot;
                exit 0;
            }
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

