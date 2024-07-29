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

my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $birthday;
        my $deathday;
        my $deltaLatitude;
        my $deltaLongitude;
        my $previousLatitude;
        my $previousLongitude;
        my $totalArea;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!defined($birthday)) {
                $birthday = $obsTime;
            }
            $deathday = $obsTime;
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($previousLatitude)) {
                    $previousLatitude = $spot->getLatitude;
                    $previousLongitude = $spot->getCarringtonLongitude;
                }
                else {
                    $deltaLatitude += $spot->getLatitude - $previousLatitude; 
                    if ($spot->getCarringtonLongitude - $previousLongitude > 180) {
                        $previousLongitude -= 360;
                    }
                    if ($spot->getCarringtonLongitude - $previousLongitude < -180) {
                        $previousLongitude += 360;
                    }
                    $deltaLongitude += $spot->getCarringtonLongitude - $previousLongitude;
                }
                $totalArea += $spot->getCorrectedWholeSpotArea;
#                print $spot->getDateTime;
#                print " ";
#                print $spot->getGroupNumber;
#                print " ";
#                print $spot->getCorrectedWholeSpotArea;
#                print " ";
#                print $spot->getCorrectedUmbralArea;
#                print " ";
#                print $spot->getLatitude;
#                print "\n";
            }
        }
        print "spotno $spotNumber ";
        print "birthday $birthday ";
        #print "deathday $deathday ";
        my ($deltaDay) = Delta_DHMS(split(/[- :]/, $birthday), 0, split(/[- :]/, $deathday), 0);
        $deltaDay++; # only complete days are counded, so we add one to round up.kkkkkkk
        print "lifetime $deltaDay ";
        print "deltaLat $deltaLatitude ";
        print "latitudeChangeRate " . ($deltaLatitude / $deltaDay);
        print " longitudeChange $deltaLongitude ";
        print " totalarea " . $totalArea;
        print "\n";
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

sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in Greenwich format.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}
                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

