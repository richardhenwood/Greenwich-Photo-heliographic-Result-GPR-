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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Delta_Days);
use List::Util qw(sum max);
use Getopt::Std;

# we check some of the extream events - for example - what is the largest change in latitude a spot make during it's life?
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
my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my @latitudeDelta = ();
    my @longitudeDelta = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $minLatitude = 90;
        my $maxLatitude = -90;
        my $minCarringtonLongitude = 360;
        my $maxCarringtonLongitude = 0;
        my $cycleNumber;
        my @birth = ();
        my @death = ();
        my $latitudeDeviation = undef;
        my $initialLatitude = undef;
        my $longitudeDeviation = undef;
        my $initialLongitude = undef;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($initialLatitude)) { 
                    $initialLatitude = $spot->getLatitude;
                    $initialLongitude = $spot->getCarringtonLongitude;
                }
                $latitudeDeviation += $spot->getLatitude - $initialLatitude;
                if ($spot->getCarringtonLongitude - $initialLongitude >= 360) {
                    $longitudeDeviation -= 360;
                }
                if ($spot->getCarringtonLongitude - $initialLongitude <= 360) {
                    $longitudeDeviation += 360;
                }
                if ($spot->getLatitude < $minLatitude) {
                    $minLatitude = $spot->getLatitude;
                }
                if ($spot->getLatitude > $maxLatitude) {
                    $maxLatitude = $spot->getLatitude;
                }
                if ($spot->getCarringtonLongitude < $minCarringtonLongitude) {
                    $minCarringtonLongitude = $spot->getCarringtonLongitude;
                }
                if ($spot->getCarringtonLongitude > $maxCarringtonLongitude) {
                    $maxCarringtonLongitude = $spot->getCarringtonLongitude;
                }
                $cycleNumber = $spot->getSolarCycle;
            }
            @death = split(/[- :]/, $obsTime);
        }
        my @ageDHMS = Delta_DHMS(@birth, 0, @death, 0);
        if ($ageDHMS[0] > 26) {
            print "spotNumber: $spotNumber ";
            print " birth: " . $birth[0] . "-" . $birth[1] . "-" . $birth[2] . " " . $birth[3] . ":" . $birth[4];
            print " min = $minLatitude, max = $maxLatitude ";
            print "latitudedeviation = $latitudeDeviation ";
            print " min = $minCarringtonLongitude, max = $maxCarringtonLongitude ";
            print "longitudedeviation = $longitudeDeviation"; # . sprintf("%3f",($maxCarringtonLongitude - $minCarringtonLongitude));
            print " age = " . $ageDHMS[0];
            print " initiallongitude = $initialLongitude ";
            print "\n";
            push (@latitudeDelta, ($maxLatitude - $minLatitude));
            push (@longitudeDelta, ($maxCarringtonLongitude - $minCarringtonLongitude));
        }
    }
#    print "max = " . max(@latitudeDelta) . "\n"; 
#    print "max = " . max(@longitudeDelta) . "\n"; 
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

