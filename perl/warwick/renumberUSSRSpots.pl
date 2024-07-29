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

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in ussr format.
-a      : do for all the data, not just cycle 15.
-d      : debug messages

example: $0 -f ~/ihr/data/solnechyi/all.dat -a -d
EOF
    exit;
}

my %opts = ();
getopts("f:ad", \%opts) ;
my $doAll = 1;
my $debug = 0;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{a})) { $doAll = 1; }
if (!defined($opts{d})) { $debug = 1; }

#print $opts{f};
my ($sunspotsRef, $sunspotsDateRef) = &Load_Sunspot_SpotCentric($opts{f});
my %sunspots = %{$sunspotsRef}; #&Load_Sunspot_DateCentric($opts{f});
my %sunspotDates = %{$sunspotsDateRef}; #&Load_Sunspot_DateCentric($opts{f});
    
print Dumper %sunspots;
print "now dates;\n";
print Dumper %sunspotDates;
#&printSpotCentricSpots();


sub printSpotCentricSpots {
    my $longitudeTolleranceTotal = 100;  # 50 degrees either side of the average spot.
    my $latitudeTolleranceTotal = 30;
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $doProcess = 1;
        my $averageLongitude = 0;
        my $numberOfSpots = 0;
        my $lastSpot = 0;
        my $minSpotLongitude = 360;
        my $maxSpotLongitude = 0;
        my $minSpotLatitude = 90;
        my $maxSpotLatitude = -90;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if ($spot->getSolarCycle != 15 && !$doAll) {
                    $doProcess = 0;
                }
                $numberOfSpots++;
                $lastSpot = $spot;
                if ($debug) {
                    print " bounds are: ";
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
                $averageLongitude += $spot->getCarringtonLongitude;
                if ($spot->getCarringtonLongitude > $maxSpotLongitude) {
                    $maxSpotLongitude = $spot->getCarringtonLongitude;
                }
                if ($spot->getCarringtonLongitude < $minSpotLongitude) {
                    $minSpotLongitude = $spot->getCarringtonLongitude;
                }
                if ($spot->getLatitude > $maxSpotLatitude) {
                    $maxSpotLatitude = $spot->getLatitude;
                }
                if ($spot->getLatitude < $minSpotLatitude) {
                    $minSpotLatitude = $spot->getLatitude;
                }
            }
        }
        if ($doProcess) {
            $averageLongitude = $averageLongitude/$numberOfSpots;
            #print "average long = " . $averageLongitude;
            #print "time of av long = " . Dumper $lastSpot->getSun_LimbTimes($averageLongitude);
            my $minLongBound = $minSpotLongitude - $longitudeTolleranceTotal/2;
            #if ($minLongBound < 0) {$minLongBound += 360;}
            my $maxLongBound = $maxSpotLongitude + $longitudeTolleranceTotal/2;
            #if ($maxLongBound >= 360) {$maxLongBound -= 360;}
            my $minLatBound = $minSpotLatitude - $latitudeTolleranceTotal/2;
            my $maxLatBound = $maxSpotLatitude + $latitudeTolleranceTotal/2;
            if ($debug) {
                print "newminLatBound: " . $minLatBound;
                print "newmaxLatBound: " . $maxLatBound;
                print "newminLongBound: " . $minLongBound;
                print "newmaxLongBound: " . $maxLongBound;
            }
            my ($ignoreEast, $maxTimeBound) = $lastSpot->getSun_LimbTimes($minLongBound);
            my ($minTimeBound, $ignoreWest) = $lastSpot->getSun_LimbTimes($maxLongBound);
            if ($debug) {
                print "newminTimeBound: " .Dumper  $minTimeBound;
                print "newmaxTimeBound: " .Dumper  $maxTimeBound;
            }

            $minLongBound = sprintf ("%d", $minLongBound);
            $maxLongBound = sprintf ("%d", $maxLongBound);
            #if ($maxLongBound > 360) {$maxLongBound -= 360;}
            if (!defined(@{$maxTimeBound})) { print Dumper $lastSpot->getSun_LimbTimes($minLongBound); print "avlong = $minLongBound\n"; }
            if (@{$minTimeBound} == []) { print Dumper $lastSpot->getSun_LimbTimes($maxLongBound); print "avlong = $maxLongBound\n"; }
            if ($debug) {
                print "minTimeBound: " . Dumper $minTimeBound;
                print "maxTimeBound: " . Dumper $maxTimeBound;
            }
            $minTimeBound = sprintf ("%04d-%02d-%02d", @{$minTimeBound});
            $maxTimeBound = sprintf ("%04d-%02d-%02d", @{$maxTimeBound});
            
            if ($debug) {
            print "min longitude bound = $minLongBound\n";
            print "max longitude bound = $maxLongBound\n";
            print "min latitude bound = $minLatBound\n";
            print "max latitude bound = $maxLatBound\n";
            print "min time bound = $minTimeBound\n";
            print "max time bound = $maxTimeBound\n";
    #'        print Dumper @maxTimeBoundRef;
            }
            my %possibleSpots = ();
            
            foreach my $obsTime (keys (%sunspotDates)) {
                #    print "obstime = $obsTime\n";
                my $minDiff = "";
                my $maxDiff = "";
                eval {
                    $minDiff = Delta_Days(split(/-/,$minTimeBound), split(/-/,$obsTime));
                    $maxDiff = Delta_Days(split(/-/,$maxTimeBound), split(/-/,$obsTime));
                };
                if ($@) {
                    print "spot number = $spotNumber\n";
                    print "odd dates: $minTimeBound $maxTimeBound $obsTime\n";
                    die "exception occured: $@";
                }
                if ($minDiff > 0 && $maxDiff < 0) {
                    foreach my $spotNumber (keys %{$sunspotDates{$obsTime}}) {
                        if ($debug) { print "spot within time bounds: $spotNumber @ $obsTime\n";}
                        foreach my $spot (@{$sunspotDates{$obsTime}{$spotNumber}}) {
                            my $spotLongitude = $spot->getCarringtonLongitude;
                            if ($maxLongBound > 360 && $spotLongitude < 180) { $spotLongitude += 360;}
                            if ($minLongBound < 0 && $spotLongitude > 180) { $spotLongitude -= 360;}
                            my $spotLatitude = $spot->getLatitude;
                            if ($debug) {print " spotlongitude = $spotLongitude min $minLongBound max $maxLongBound: "; }
                            if ($spotLongitude > $minLongBound && $spotLongitude < $maxLongBound && $spotLatitude > $minLatBound && $spotLatitude < $maxLatBound) {
                                if ($debug) {print " WITHIN \n"; }
                                
                                $possibleSpots{$spot->getGroupNumber} = 1;
                            }
                            else {
                                if ($debug) {print " OUTSIDE \n"; }
                            }
                        }
                    }
                }

            }

            #     print Dumper keys %possibleSpots;
            if (scalar keys %possibleSpots != 0) {
                print "for spot: $spotNumber, pairing candidates are:\n";
                foreach my $pairSpot (keys %possibleSpots) {
                    print "$pairSpot\n";
                }
                # we select all the spots 
                print "\n";
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
    my $uniqueGroupNumberPrefix = 71;
    my $previousNumber = 1;
    my %spotReplacementNumbers = ();
    my %spotReplacementPrefix = ();
    my $lineNumber = 1;
    while (defined (my $line = <FH>)) {
        #print "$line";
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        my $groupNumber = $test_spot->getGroupNumber();
        if ($groupNumber eq "") {
            die "this should be a number\n$line";
        }
        
        if (!defined($spotReplacementNumbers{$groupNumber})) {
            $spotReplacementNumbers{$groupNumber} = 0;
        }
        elsif ($lineNumber - $spotReplacementNumbers{$groupNumber} > 1000) {
            #print "found reused group number";
            #print " $groupNumber -> " . $uniqueGroupNumberPrefix . $groupNumber; 
            #print "\n";
            if (defined($spotReplacementPrefix{$groupNumber})) {
                $spotReplacementPrefix{$groupNumber}++;
            }
            else {
                $spotReplacementPrefix{$groupNumber} = $uniqueGroupNumberPrefix;
            }
        }
        #print "group number = $groupNumber: numbers " . $spotReplacementNumbers{$groupNumber};
        #    print "\n";
        $spotReplacementNumbers{$groupNumber} = $lineNumber;

        if (defined($spotReplacementPrefix{$groupNumber})) {
            $groupNumber = $spotReplacementPrefix{$groupNumber} . $groupNumber;
        }
        print substr($test_spot->raw_string,0, 12) . sprintf("%5d",$groupNumber) . substr($test_spot->raw_string,17, -1);
        print "\n";
        #print $test_spot->raw_string;
        #print $test_spot->getUSSRFormat;
        $lineNumber++;
    }
    return \%sunspot_array, \%sunspotDate_array;
}



# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

