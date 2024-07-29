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

# this program compiles our training datafile from greenwich data and training associations
# which are stored in another file.
#

my %opts = ();
getopts("f:t:", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{t})) { usage(); }

my %sunspots = ();
my %linkedSpots = ();
%linkedSpots = &Load_Link_Tests($opts{t});

%sunspots = &Load_Sunspot_SpotCentric($opts{f});
my ($outputStr, $numPats, $nodes) = &printLinkedSpotsARFF();
&patheader($numPats, $nodes);
print $outputStr;

sub Load_Link_Tests {
    my $filename = shift;
    my %linkspot_array = ();
    my $startingSpot = "";
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        #print "line = $line";
        chop($line);
        if ($line =~ m/for spot:/) {
            $line =~ s/.* (\d+),.*/$1/;
            $startingSpot = $line;
            #print "starting spot = $startingSpot\n";
        }
        elsif ($line =~ m/^\d+/) {
            push(@{$linkspot_array{$startingSpot}}, $line);
        }
    }
    return %linkspot_array;
}

sub patheader {
    my ($pats, $nodes) = @_;
    my $dateTime = time();
    print <<SNNSpatHEADER;
SNNS pattern definition file V3.2
generated at Mon Aug 3 15:58:23 2006


No. of patterns : $pats
No. of input units : $nodes
No. of output units : 1

SNNSpatHEADER
}

sub printLinkedSpotsARFF {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    #my $daysFromLimb = 1;
    my $pairNumber = 0;
    my $outputStr = "";
    my $lowPreCut = 2;
    my $highPreCut = 8;
    my $lowPostCut = 17;
    my $highPostCut = 23;
    my $outputValues = 0;
    my $latitudeBinsPre = 5;
    my $longitudeBinsPre = 7;
    my $latitudeBinsPost = 9;
    my $longitudeBinsPost = 21;
    my $previousLatitude = 0;
    my $previousLongitude = 0;

    foreach my $initialSpot (keys (%linkedSpots)) {
        #print "initial spot = $initialSpot\n";
        my $tmpOutput = "";
        #my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
        my $classification = "notlinked";
        my $preGreenwichNumber = "";
        my $postGreenwichNumber = "";
        my $initialSpotLongitude = 180;
        my $initialSpotLatitude = 0;
        foreach my $linkCandidate (@{$linkedSpots{$initialSpot}}) {
            $pairNumber++;
            $outputValues = 0;
            my $foundStartPre = 0;
            my $foundStartPost = 0;
            my $firstTimePre = 1;
            my $firstTimePost = 1;
            my $initialSpotARFFlat = "";
            my $linkedSpotARFFlat = "";
            my $initialSpotARFFlong = "";
            my $linkedSpotARFFlong = "";
            if ($linkCandidate =~ m/y/) {
                $classification = "1";
            }
            else { $classification = "0";}
            $linkCandidate =~ s/(\d+).*/$1/;
            my $daysFromLimb = 1;
            foreach my $obsTime (reverse sort keys %{$sunspots{$initialSpot}}) {
                foreach my $spot (@{$sunspots{$initialSpot}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime  = $thisSpotDateTime;
                    }
                    my $sunWestLimb = $spot->getSun_West_Limb;
                    if ($sunWestLimb < $spot->getCarringtonLongitude) { $sunWestLimb += 360;}
                    my $degreesFromLimb = $sunWestLimb - $spot->getCarringtonLongitude;
                    $degreesFromLimb = abs($degreesFromLimb);
                    while ($degreesFromLimb > ($dayDegrees * $daysFromLimb) && !$foundStartPre) {
                        # $initialSpotARFFlong .= "$obsTime $spot suneast $sunWestLimb " .$spot->getCarringtonLongitude . "  degfromlimb $degreesFromLimb < daysfromlimb $daysFromLimb * daydegs: $dayDegrees\n";
                        if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                            for (my $i = 0; $i < $latitudeBinsPre; $i++) {
                                $initialSpotARFFlat .= "0 ";
                                $outputValues++;
                            }
                            $initialSpotARFFlat .= "\n";
                            for (my $i = 0; $i < $longitudeBinsPre; $i++) {
                                $initialSpotARFFlong .= "0 ";
                                $outputValues++;
                            }
                            $initialSpotARFFlong .= "\n";
                            $daysFromLimb++;
                        }
                        elsif ($daysFromLimb < $lowPreCut) {
                            $daysFromLimb++;
                        }
                        else {
                            $previousLatitude = $spot->getLatitude;
                            $previousLongitude = $spot->getCarringtonLongitude;
                            $foundStartPre = 1;
                        }
                    }
                    $foundStartPre = 1;
                    if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                        #    $initialSpotARFFlong .= "found!\n";
                        if ($firstTimePre) {
                            my $qLat = $latitudeBinsPre/2;
                            $qLat = sprintf("%d",$qLat);
                            for (my $i = 0; $i < $latitudeBinsPre; $i++) {
                                if ($i == $qLat) {
                                    $initialSpotARFFlat .= "1 ";
                                }
                                else {
                                    $initialSpotARFFlat .= "0 ";
                                }
                                $outputValues++;
                            }
                            $initialSpotARFFlat .= "\n";
                            my $qLong = $longitudeBinsPre/2;
                            $qLong = sprintf("%d",$qLong);
                            for (my $i = 0; $i < $longitudeBinsPre; $i++) {
                                if ($i == $qLong) {
                                    $initialSpotARFFlong .= "1 ";
                                }
                                else {
                                    $initialSpotARFFlong .= "0 ";
                                }
                                $outputValues++;
                            }
                            $initialSpotARFFlong .= "\n";
                            $previousLatitude = $spot->getLatitude;
                            $previousLongitude = $spot->getCarringtonLongitude;
                            $firstTimePre = 0;
                        }
                        else {
                            my $qLat = $spot->getLatitude - $previousLatitude;
                            $qLat = sprintf("%d",($qLat/35)*($latitudeBinsPre)+$latitudeBinsPre/2);
                            for (my $i = 0; $i < $latitudeBinsPre; $i++) {
                                if ($i == $qLat) {
                                    $initialSpotARFFlat .= "1 ";
                                }
                                else {
                                    $initialSpotARFFlat .= "0 ";
                                }
                                $outputValues++;
                            }
                            $initialSpotARFFlat .= "\n";
                            my $qLong = $spot->getCarringtonLongitude - $previousLongitude;
                            if ($qLong > 360) {$qLong = $qLong - 360;}
                            $qLong = sprintf("%d",(($qLong)/160)*($longitudeBinsPre) + $longitudeBinsPre/2);
                            for (my $i = 0; $i < $longitudeBinsPre; $i++) {
                                if ($i == $qLong) {
                                    $initialSpotARFFlong .= "1 ";
                                }
                                else {
                                    $initialSpotARFFlong .= "0 ";
                                }
                                $outputValues++;
                            }
                            $initialSpotARFFlong .= "\n";
                        }
                        $previousLatitude = $spot->getLatitude;
                        $previousLongitude = $spot->getCarringtonLongitude;
                    }
                    $daysFromLimb++;
                    $preGreenwichNumber = $spot->getGroupNumber;
                    $initialSpotLatitude = $spot->getLatitude;
                    $initialSpotLongitude = $spot->getCarringtonLongitude;
                    if (!defined($initialSpotLatitude)) { 
                        print Dumper $spot;
                        exit 0;
                    }
                }
            }
            while ($daysFromLimb <= 16) {
                if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                    for (my $i = 0; $i < $latitudeBinsPre; $i++) {
                        $initialSpotARFFlat .= "0 ";
                        $outputValues++;
                    }
                    $initialSpotARFFlat .= "\n";

                    for (my $i = 0; $i < $longitudeBinsPre; $i++) {
                        $initialSpotARFFlong .= "0 ";
                        $outputValues++;
                    }
                    $initialSpotARFFlong .= "\n";
                } 
                $daysFromLimb++;
            }
            #$foundStart = 0;
            $daysFromLimb = 1;
            foreach my $obsTime (sort keys %{$sunspots{$linkCandidate}}) {
                #$linkedSpotARFFlong .= "daysfromlimb: $daysFromLimb\n";
                foreach my $spot (@{$sunspots{$linkCandidate}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $sunEastLimb = $spot->getSun_East_Limb;
                    if ($sunEastLimb > $spot->getCarringtonLongitude) { $sunEastLimb -= 360; }
                    my $degreesFromLimb = $sunEastLimb - $spot->getCarringtonLongitude;
                    $degreesFromLimb = abs($degreesFromLimb);
                    #$linkedSpotARFFlong .= "$obsTime $spot suneast $sunEastLimb " .$spot->getCarringtonLongitude . "  degfromlimb $degreesFromLimb < daysfromlimb $daysFromLimb * daydegs: $dayDegrees\n";
                    while ($degreesFromLimb > ($dayDegrees * $daysFromLimb) && !$foundStartPost) {
                        if ($daysFromLimb <= $highPostCut - 16 && $daysFromLimb >= $lowPostCut - 16) {
                            for (my $i = 0; $i < $latitudeBinsPost; $i++) {
                                $linkedSpotARFFlat .= "0 ";
                                $outputValues++;
                            }
                            $linkedSpotARFFlat .= "\n";
                            for (my $i = 0; $i < $longitudeBinsPost; $i++) {
                                $linkedSpotARFFlong .= "0 ";
                                $outputValues++;
                            }
                            $linkedSpotARFFlong .= "\n";
                            $daysFromLimb++;
                        }
                        elsif ($daysFromLimb < $lowPostCut) {
                            $daysFromLimb++;
                        }
                        else {
                            $previousLatitude = $spot->getLatitude;
                            $previousLongitude = $spot->getCarringtonLongitude;
                            $foundStartPost = 1;
                        }
                        #            $linkedSpotARFFlong .= " days = $daysFromLimb\n ";
                    }
                    #$linkedSpotARFFlong .= "endwhile$obsTime $spot sunwest $sunWestLimb " .$spot->getCarringtonLongitude . " daysfromlimb $daysFromLimb degfromlimb $degreesFromLimb daydegs: $dayDegrees\n";
                    $foundStartPost = 1;
                    if ($daysFromLimb <= $highPostCut - 16 && $daysFromLimb >= $lowPostCut - 16) {
                        #    $linkedSpotARFFlong .= " found spot\n ";

                        if ($firstTimePost && 0) {
                            my $qLat = $latitudeBinsPost/2;
                            $qLat = sprintf("%d",$qLat);
                            for (my $i = 0; $i < $latitudeBinsPost; $i++) {
                                if ($i == $qLat) {
                                    $linkedSpotARFFlat .= "1 ";
                                }
                                else {
                                    $linkedSpotARFFlat .= "0 ";
                                }
                                $outputValues++;
                            }
                            #$linkedSpotARFFlat .= "\n";
                            my $qLong = $longitudeBinsPost/2;
                            $qLong = sprintf("%d",$qLong);
                            #print "qlong = $qLong\n";
                            for (my $i = 0; $i < $longitudeBinsPost; $i++) {
                                if ($i == $qLong) {
                                    $linkedSpotARFFlong .= "1 ";
                                }
                                else {
                                    $linkedSpotARFFlong .= "0 ";
                                }
                                $outputValues++;
                            }
                            #$linkedSpotARFFlong .= "\n";
                            $previousLatitude = $spot->getLatitude;
                            $previousLongitude = $spot->getCarringtonLongitude;
                            $firstTimePost = 0;
                        }
                        else {
                            #my $qLat = $spot->getLatitude - $previousLatitude;
                            my $qLat = $spot->getLatitude - $initialSpotLatitude;
                            $qLat = sprintf("%d",($qLat/35)*($latitudeBinsPost)+$latitudeBinsPost/2);
                            #$linkedSpotARFFlat .= "qlat = $qLat ". $spot->getLatitude . " $previousLatitude\n";
                            for (my $i = 0; $i < $latitudeBinsPost; $i++) {
                                if ($i == $qLat) {
                                    $linkedSpotARFFlat .= "1 ";
                                }
                                else {
                                    $linkedSpotARFFlat .= "0 ";
                                }
                                $outputValues++;
                            }
                            # $linkedSpotARFFlat .= "\n";
                            #my $qLong = $spot->getCarringtonLongitude - $previousLongitude;
                            my $qLong = $spot->getCarringtonLongitude - $initialSpotLongitude;
                            if ($qLong > 360) {$qLong = $qLong - 360;}
                            $qLong = sprintf("%d",(($qLong)/160)*($longitudeBinsPost)+$longitudeBinsPost/2);
                            #print "qlong = $qLong\n";
                            #$linkedSpotARFFlong .= "qlong $qLong\n";
                            #$linkedSpotARFFlong .= "qlong = $qLong " . $spot->getCarringtonLongitude . " $initialSpotLongitude  bins = $longitudeBinsPost diff = " . ($spot->getCarringtonLongitude - $initialSpotLongitude) . "\n";
                           
                            #$linkedSpotARFFlong .= ($spot->getCarringtonLongitude - $initialSpotLongitude) . "\n"
                            for (my $i = 0; $i < $longitudeBinsPost; $i++) {
                                if ($i == $qLong) {
                                    $linkedSpotARFFlong .= "1 ";
                                }
                                else {
                                    $linkedSpotARFFlong .= "0 ";
                                }
                                $outputValues++;
                            }
                        }
                        $previousLatitude = $spot->getLatitude;
                        $previousLongitude = $spot->getCarringtonLongitude;
                        $linkedSpotARFFlat .= "\n";
                        $linkedSpotARFFlong .= "\n";
                        #$outputValues++;
                    }
                    $postGreenwichNumber = $spot->getGroupNumber;
                    $daysFromLimb++;
                }
            }
            #$linkedSpotARFFlong .= "padding end\n";
            while ($daysFromLimb <= 16) {
                if ($daysFromLimb <= $highPostCut -16 && $daysFromLimb >= $lowPostCut - 16) {
                    for (my $i = 0; $i < $latitudeBinsPost; $i++) {
                        $linkedSpotARFFlat .= "0 ";
                            $outputValues++;
                    }
                    $linkedSpotARFFlat .= "\n";

                    for (my $i = 0; $i < $longitudeBinsPost; $i++) {
                        $linkedSpotARFFlong .= "0 ";
                            $outputValues++;
                    }
                    $linkedSpotARFFlong .= "\n";
                }
                $daysFromLimb++;
            }
            $tmpOutput .= "# Input pattern $pairNumber $preGreenwichNumber -> $postGreenwichNumber \n";
            $tmpOutput .= "# potential link spot, longitude\n";
            $tmpOutput .= "$linkedSpotARFFlong";
            $tmpOutput .= "# initial spot, longitude\n";
            $tmpOutput .= "$initialSpotARFFlong";
            $tmpOutput .= "# potential link spot, latitude\n";
            $tmpOutput .= "$linkedSpotARFFlat";
            $tmpOutput .= "# initial spot, latitude\n";
            $tmpOutput .= "$initialSpotARFFlat";

            $tmpOutput .= "# Output pattern $pairNumber\n";
            $tmpOutput .= "" . $classification;
            $tmpOutput .= " \n";
            $tmpOutput .= " \n";
        }
        $outputStr .= $tmpOutput;
    }
    return ($outputStr, $pairNumber, $outputValues);
}

sub printSpotCentricSpots {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    my $daysFromLimb = 1;
    foreach my $spotNumber (keys (%sunspots)) {
        #print $spotNumber;
        print "spot group\n";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
       
        # we want to write out data with position_1 being closet to the time
        # when the spot is obscured by solar rotation.
        # this means that we need to order the spots before and after 
        # obscuring opposite cronologically.
        foreach my $obsTime (reverse sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                my $thisSpotDateTime = $spot->getDateTime;
                if (!defined($firstGroupTime)) {
                    $firstGroupTime = $thisSpotDateTime;
                }
                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                    $daysFromLimb++;
                    $foundStart = 1;
                }

                print "position_$daysFromLimb ";
                print $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCarringtonLongitude;
                print " ";
                print $spot->getSun_West_Limb;
                print " ";

#                print $spot->getSun_West_Limb - $spot->getCarringtonLongitude;
#                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
#                print " degrees from limb = $degreesFromLimb ";
#                print "within degrees: ". $dayDegrees * $daysFromLimb;
#                if ($degreesFromLimb < $dayDegrees * $daysFromLimb) {
#                    print " days from limb = $daysFromLimb ";
#                }
                #my $westLimb = $spot->getSun_West_Limb;
                #my $position = ($westLimb - $dayDegrees) % 360;
                #print $position;
                $daysFromLimb++;
                
                print "\n";
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
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}}, $test_spot);
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
        if (!($line =~ m/^</ || $line =~ m/^\s+/)) {
            my $test_spot = new sunspot;
            $test_spot->parse_data_into_object($line);
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumber()}}, $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
            }
        }
    }
    return %sunspot_array;
}

sub usage {
    print STDERR << "EOF";

This program creates ARFF format data from Greenwich format data.

See http://weka.sourceforge.net/wekadoc/index.php/en:ARFF_%283.4.6%29 for ARFF format.
See http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt or Greenwich format.
The link candidates format is self documenting.

usage: $0 -f file -t triningdata

-f      : file containing data, in Greenwich format.
-t      : file containing link candidates in our made up format

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -t ~sfell/sunspotData/cycle15latitudeFilteredMulti.txt
EOF
    exit;
}
                                                                                                                        


# this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}

