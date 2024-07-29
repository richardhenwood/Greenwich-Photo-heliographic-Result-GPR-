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

examine spots which live greater than 10 days and get their total heliographic movement

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-s      : flag to include information regarding position in solar cycle.
-n      : flag to request normalised values.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}
my %opts = ();
getopts("f:sn", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $solarCycleBOOL = 0;
if (defined($opts{s})) { $solarCycleBOOL = 1; }
my $normaliseBOOL = 0;
if (defined($opts{n})) { $normaliseBOOL = 1; }

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
        my $cycleFraction = 0;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #print "solar cycle = ";
                if ($solarCycleBOOL) {
                    $cycleFraction = $spot->getSolarCycleProgress();
                }
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
        if ($ageDHMS[0] > 10) {
            if ($maxCarringtonLongitude - $minCarringtonLongitude > 180) { $minCarringtonLongitude += 360;}
            #push (@latitudeDelta, ($latitudeDeviation));
            my $latMaxMin = sprintf("%.1f", $maxLatitude - $minLatitude);
            my @tmpArrLat = ($latMaxMin, $cycleFraction);
            push (@latitudeDelta, \@tmpArrLat);
            #push (@longitudeDelta, ($longitudeDeviation));
            my $longMaxMin = sprintf("%.1f", $maxCarringtonLongitude - $minCarringtonLongitude);
            my @tmpArrLong = ($longMaxMin, $cycleFraction);
            push (@longitudeDelta, \@tmpArrLong);
            if (0) {
                print "Num: $spotNumber ";
                print "latmin= $minLatitude, max= $maxLatitude ";
                #print "latdev = $latitudeDeviation ";
                print "min-max= $latMaxMin ";
                print "longmin= $minCarringtonLongitude, max= $maxCarringtonLongitude ";
                #print "longdev = $longitudeDeviation"; # . sprintf("%3f",($maxCarringtonLongitude - $minCarringtonLongitude));
                print "max-min= $longMaxMin ";
                print "age= " . $ageDHMS[0];
                #print " initlong = $initialLongitude ";
                print " cf= $cycleFraction";
                print "\n";
            }
        }
    }
    my $latitudeBinWidth = 1;
    my %latitudeBins = ();
    foreach my $latRef (@latitudeDelta) {
        #print Dumper $latRef;
        my ($latDelta, $cycleFraction) = @{$latRef};
        #print $latDelta;
        my $bin = floor($latDelta) - (floor($latDelta) % $latitudeBinWidth);
        if (!defined($latitudeBins{$bin}{$cycleFraction})) {
            $latitudeBins{$bin}{$cycleFraction} = 0;
        }
        $latitudeBins{$bin}{$cycleFraction} += 1;
    }
    for (my $j = 0; $j <= $solarCycleBOOL; $j += 0.1) {
        my $total = 0;
        for (my $i = 0; $i <= 15; $i += $latitudeBinWidth) {
            if (defined($latitudeBins{$i}{$j})) {
                $total += $latitudeBins{$i}{$j};
            }
        }
        for (my $i = 0; $i <= 15; $i += $latitudeBinWidth) {
            if (defined($latitudeBins{$i}{$j})) {
                print "latitudebin = $i cycle = $j count = " . $latitudeBins{$i}{$j} . " normalised = " . $latitudeBins{$i}{$j}/$total;
            }
            else {
                print "latitudebin = $i cycle = $j count = 0 normalised = 0";
                
            }
            print "\n";
        }
        print "\n\n";
    }
    print "\n\n";
    my $longitudeBinWidth = 1;
    my %longitudeBins = ();
    foreach my $longRef (@longitudeDelta) {
        my ($longDelta, $cycleFraction) = @{$longRef};
        my $bin = floor($longDelta) - (floor($longDelta) % $longitudeBinWidth);
        if (!defined($longitudeBins{abs($bin)}{$cycleFraction})) {
            $longitudeBins{abs($bin)}{$cycleFraction} = 0;
        }
        $longitudeBins{abs($bin)}{$cycleFraction} += 1;
    }
    for (my $j = 0; $j <= $solarCycleBOOL; $j += 0.1) {
        my $total = 0;
        for (my $i = 0; $i <= 24; $i += $longitudeBinWidth) {
            if (defined($longitudeBins{$i}{$j})) {
                $total += $longitudeBins{$i}{$j};
            }
        }
        for (my $i = 0; $i <= 24; $i += $longitudeBinWidth) {
            if (defined($longitudeBins{$i}{$j})) {
                print "longitudebin = $i cycle = $j count = " . $longitudeBins{$i}{$j} . " normalised = " . $longitudeBins{$i}{$j}/$total;
            }
            else {
                print "longitudebin = $i cycle = $j count = 0 normalised = 0";
                
            }
            print "\n";
        }
        print "\n\n";
        #if (defined($longitudeBins{$i})) {
        #    print "longitudebin = $i count = " . $longitudeBins{$i};
        #    print " normalised = " . $longitudeBins{$i}/(scalar @longitudeDelta) . "\n";
        #}
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

