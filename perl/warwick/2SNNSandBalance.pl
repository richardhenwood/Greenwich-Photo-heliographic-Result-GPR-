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
use Switch;

# this program compiles our training datafile from greenwich data and training associations
# which are stored in another file.
#
sub usage {
    print STDERR << "EOF";

This program creates SNNS format data from Greenwich format data.

See http://weka.sourceforge.net/wekadoc/index.php/en:SNNS_%283.4.6%29 for SNNS format.
See http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt or Greenwich format.
The link candidates format is self documenting.

usage: $0 -f file -t triningdata

-f      : file containing data, in Greenwich format.
-t      : file containing link candidates in our made up format
-b      : balance the dataset by introducing more positives.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1920.grp -t ~/ihr/data/reclassification/cycle15latitudeFilteredMulti.txt
EOF
    exit;
}
                                                                                                                        

my %opts = ();
getopts("f:t:b", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{t})) { usage(); }
my $BALANCE = 0;
if (defined($opts{b})) { $BALANCE = 1; }

#my %sunspots = ();
my ($linkedSpotsRef, $posShortfall) = &Load_Link_Tests($opts{t});
#print "length = " . scalar keys(%linkedSpots);

my $sunspotRef = &Load_Sunspot_SpotCentric($opts{f});
#print "length = " . scalar keys(%sunspots);
#exit 0;
my ($outputStr, $numPats, $nodes) = &printLinkedSpotsSNNS($sunspotRef, $linkedSpotsRef, $posShortfall);
&patheader($numPats, $nodes);
print $outputStr;

sub Load_Link_Tests {
    my $filename = shift;
    my %linkspot_array = ();
    my $startingSpot = "";
    open (FH, $filename);
    my $totalExamples = 0;
    my $posExamples = 0;
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
            $totalExamples++;
            if ($line =~ m/y/) {
                $posExamples++;
            }

        }
    }
    #print Dumper %linkspot_array;
    return (\%linkspot_array, $totalExamples - $posExamples);
}

sub patheader {
    my ($pats, $nodes) = @_;
    my $dateTime = localtime();
    print <<SNNSpatHEADER;
SNNS pattern definition file V3.2
generated at $dateTime


No. of patterns : $pats
No. of input units : $nodes
No. of output units : 1

SNNSpatHEADER
}

my $addNoise = 0;
my $noiseCount = 7*4;

sub printLinkedSpotsSNNS {
    #print Dumper %sunspots;
    #exit 0;
    my ($sunspotRef, $linkedRef, $posShortfall) = @_;
#print "posShortfall = $posShortfall\n";
#exit 0;
    my %sunspots = %{$sunspotRef};
    my %linkedSpots = %{$linkedRef};
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    #my $daysFromLimb = 1;
    my $pairNumber = 0;
    my $outputStr = "";
    my $outputValues = 0;
    my $previousLatitude = 0;
    my $previousLongitude = 0;
    # these variables configure the output
    # cuts indicate how many steps for the limb we should start,
    # pre spots go from 1 - 16
    # post spots from 17 - 32
    my $lowPreCut = 2;
    my $highPreCut = 8;
    my $lowPostCut = 17;
    my $highPostCut = 23;
    # number of bins which should descretise the long/lat into
    my $latitudeBinsPre = 5;
    my $longitudeBinsPre = 7;
    my $latitudeBinsPost = 9;
    my $longitudeBinsPost = 21;
    my $noSpotFails = "";

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
        my $copies = 1;
        $addNoise = 0;
        $noiseCount = 7*4;
        foreach my $linkCandidate (@{$linkedSpots{$initialSpot}}) {
            $tmpOutput = "";
             $copies = 1;
            # these values distribute the points away from the middle value
            my $initialSpotLongitudeSensitivity = 15; # lower means more sensitive
            my $initialSpotLatitudeSensitivity = 35;
            my $linkedSpotLongitudeSensitivity = 100;
            my $linkedSpotLatitudeSensitivity = 15;
            if ($linkCandidate =~ m/y/) {
                $classification = "1";
                if ($BALANCE) {
                    $copies = 6;
                    $noiseCount = 7*4;
                }
            }
            else { $classification = "0";}
            #print "links: $initialSpot -> $linkCandidate copies = $copies $pairNumber\n";
            my $emptyDays = 0;
            while ($copies) {
                $tmpOutput = "";
                $pairNumber++;
                $outputValues = 0;
                my $foundStartPre = 0;
                my $foundStartPost = 0;
                my $firstTimePre = 1;
                my $firstTimePost = 1;
                my $initialSpotSNNSlat = "";
                my $linkedSpotSNNSlat = "";
                my $initialSpotSNNSlong = "";
                my $linkedSpotSNNSlong = "";
                #print "$linkCandidate\n";
                $linkCandidate =~ s/(\d+).*/$1/;
                #print "$linkCandidate\n";
                my $daysFromLimb = 1;
                #  print Dumper keys %sunspots;
                foreach my $obsTime (reverse sort keys %{$sunspots{$initialSpot}}) {
                    foreach my $spot (@{$sunspots{$initialSpot}{$obsTime}}) {
                        my $thisSpotDateTime = $spot->getDateTime;
                        if (!defined($firstGroupTime)) {
                            $firstGroupTime  = $thisSpotDateTime;
                        }
                        #my $sunWestLimb = $spot->getSun_West_Limb;
                        #if ($sunWestLimb < $spot->getCarringtonLongitude) { $sunWestLimb += 360;}
                        #my $degreesFromLimb = $sunWestLimb - $spot->getCarringtonLongitude;
                        my $degreesFromLimb = 90 - $spot->getCentralMeridianDistance;
                        $degreesFromLimb = abs($degreesFromLimb);
#                     $initialSpotSNNSlong .= "$obsTime  " .$spot->getCarringtonLongitude . "  degfromlimb $degreesFromLimb < daysfromlimb $daysFromLimb * daydegs: $dayDegrees \n";
                        while ($degreesFromLimb > ($dayDegrees * $daysFromLimb) && !$foundStartPre) {
                            if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                                #$initialSpotSNNSlong .= "padding\n";
                                $initialSpotSNNSlat .= &printBinaryLine($latitudeBinsPre, -1) . "\n"; 
                                $initialSpotSNNSlong .= &printBinaryLine($longitudeBinsPre, -1) . "\n"; 
                                $outputValues += $latitudeBinsPre;
                                $outputValues += $longitudeBinsPre;
                                $daysFromLimb++;
                            }
                            elsif ($daysFromLimb < $lowPreCut) {
                                #$initialSpotSNNSlong .= "checking the next day\n";
                                $daysFromLimb++;
                            }
                            else {
                                #    $initialSpotSNNSlong .= "found and quitting this while loop\n";
                                $previousLatitude = $spot->getLatitude;
                                $previousLongitude = $spot->getCarringtonLongitude;
                                $foundStartPre = 1;
                            }
                        }
                        $foundStartPre = 1;
                        if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                            if ($firstTimePre) {
                                #$initialSpotSNNSlong .= "found start!\n";
                                my $qLat = $latitudeBinsPre/2;
                                $qLat = sprintf("%d",$qLat);
                                $initialSpotSNNSlat .= &printBinaryLine($latitudeBinsPre, $qLat) . "\n";
                                my $qLong = $longitudeBinsPre/2;
                                $qLong = sprintf("%d",$qLong);
                                $initialSpotSNNSlong .= &printBinaryLine($longitudeBinsPre, $qLong) . "\n";
                                $outputValues += $latitudeBinsPre;
                                $outputValues += $longitudeBinsPre;
                                $previousLatitude = $spot->getLatitude;
                                $previousLongitude = $spot->getCarringtonLongitude;
                                $firstTimePre = 0;
                            }
                            else {
                                my $qLat = $spot->getLatitude - $previousLatitude;
                                $qLat = sprintf("%d",($qLat/$initialSpotLatitudeSensitivity)*($latitudeBinsPre)+$latitudeBinsPre/2);
                                $initialSpotSNNSlat .= &printBinaryLine($latitudeBinsPre, $qLat) . "\n";
                                my $qLong = $spot->getCarringtonLongitude - $previousLongitude;
                                #$initialSpotSNNSlong .= "qlong = $qLong\n";
                                if ($qLong > 180) {$qLong = $qLong - 360;}
                                if ($qLong < -180) {$qLong = $qLong + 360;}
                                #$initialSpotSNNSlong .= "qlong = $qLong\n";
                                $qLong = sprintf("%d",(($qLong)/$initialSpotLongitudeSensitivity)*($longitudeBinsPre) + $longitudeBinsPre/2);
                                #$initialSpotSNNSlong .= "qlong = $qLong\n";
                                $initialSpotSNNSlong .= &printBinaryLine($longitudeBinsPre, $qLong) . "\n";
                                $outputValues += $latitudeBinsPre;
                                $outputValues += $longitudeBinsPre;
                            }
                            #$previousLatitude = $spot->getLatitude;
                            #$previousLongitude = $spot->getCarringtonLongitude;
                        }
                        $daysFromLimb++;
                        $preGreenwichNumber = $spot->getGroupNumberAugmented;
                        $initialSpotLatitude = $spot->getLatitude;
                        $initialSpotLongitude = $spot->getCarringtonLongitude;
                        if (!defined($initialSpotLatitude)) { 
                            print "something isn't right, exiting\n";
                            print Dumper $spot;
                            exit 0;
                        }
                    }
                }
                while ($daysFromLimb <= 16) {
                    if ($daysFromLimb <= $highPreCut && $daysFromLimb >= $lowPreCut) {
                        $initialSpotSNNSlat .= &printBinaryLine($latitudeBinsPre, -1) . "\n";
                        $initialSpotSNNSlong .= &printBinaryLine($longitudeBinsPre, -1) . "\n";
                        $outputValues += $latitudeBinsPre;
                        $outputValues += $longitudeBinsPre;
                    } 
                    $daysFromLimb++;
                }
                # days from limb must be 17 by the time we reach this point
                # but for some reason, with spot 7756 is makes it to 18, breaking things below....
                # so i'm forceing it back to 17.
                $daysFromLimb = 17;
                if (!defined($sunspots{$linkCandidate})) {
                    die "can't find candidate : $linkCandidate";
                }
                #print "candidate = $linkCandidate\n";
                foreach my $obsTime (sort keys %{$sunspots{$linkCandidate}}) {
                    #print "link candidate = $linkCandidate\n";
                    foreach my $spot (@{$sunspots{$linkCandidate}{$obsTime}}) {
                        my $thisSpotDateTime = $spot->getDateTime;
                        if (!defined($firstGroupTime)) {
                            $firstGroupTime = $thisSpotDateTime;
                        }
                        my $sunEastLimb = $spot->getSun_East_Limb;
                        if ($sunEastLimb > $spot->getCarringtonLongitude) { $sunEastLimb -= 360; }
                        #my $degreesFromLimb = $sunEastLimb - $spot->getCarringtonLongitude;
                        #$degreesFromLimb = abs($degreesFromLimb);
                        my $degreesFromLimb = $spot->getCentralMeridianDistance + 90;
                        #$linkedSpotSNNSlong .= "$daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut in region\n";
                        while ($degreesFromLimb > ($dayDegrees * ($daysFromLimb - 16)) && !$foundStartPost) {
                            #$linkedSpotSNNSlong .= "padding beginning\n";
                            #$linkedSpotSNNSlong .= "$obsTime $spot days = $daysFromLimb degfromlimb $degreesFromLimb < daysfromlimb " . ($daysFromLimb - 16) . " * daydegs: $dayDegrees " . (($daysFromLimb-16) * $dayDegrees) . "\n";
                            #$linkedSpotSNNSlong .=  "if expr: $daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut\n";
                            if ($daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut) {
                                #    print "latitude bin post = '$latitudeBinsPost'\n";
                                $linkedSpotSNNSlat .= &printBinaryLine($latitudeBinsPost, -1);
                                $linkedSpotSNNSlat .= "\n";
                                $linkedSpotSNNSlong .= &printBinaryLine($longitudeBinsPost, -1);
                                $linkedSpotSNNSlong .= "\n";
                                $outputValues += $latitudeBinsPost;
                                $outputValues += $longitudeBinsPost;
                                $daysFromLimb++;
                                $emptyDays++;
                            }
                            elsif ($daysFromLimb < $lowPostCut) {
                                $daysFromLimb++;
                            }
                            else {
                                #$previousLatitude = $spot->getLatitude;
                                #$previousLongitude = $spot->getCarringtonLongitude;

                                $foundStartPost = 1;
                            }
                            #$linkedSpotSNNSlong .= "emptydays: $emptyDays limbdays = $daysFromLimb\n";
                            #            $linkedSpotSNNSlong .= " days = $daysFromLimb\n ";
                        }
                        #$linkedSpotSNNSlong .= "endwhile$obsTime $spot sunwest $sunWestLimb " .$spot->getCarringtonLongitude . " daysfromlimb $daysFromLimb degfromlimb $degreesFromLimb daydegs: $dayDegrees\n";
                        $foundStartPost = 1;
                        #    $linkedSpotSNNSlong .= "$daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut in region\n";
                        if ($daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut) {
                            my $qLat = $spot->getLatitude - $initialSpotLatitude;
                            $qLat = sprintf("%d",($qLat/$linkedSpotLatitudeSensitivity)*($latitudeBinsPost)+$latitudeBinsPost/2);
                            if ($qLat < 0) { $qLat = 0;}
                            #print "qlat = $qLat\n";
                            $linkedSpotSNNSlat .= &printBinaryLine($latitudeBinsPost, $qLat) . "\n";
                            my $qLong = $initialSpotLongitude - $spot->getCarringtonLongitude;
                            if ($spot->getCarringtonLongitude - $initialSpotLongitude > 180) { 
                                $qLong = $spot->getCarringtonLongitude - (360 + $initialSpotLongitude);
                            }
                            if ($spot->getCarringtonLongitude - $initialSpotLongitude <  - 180) { 
                                $qLong = ($spot->getCarringtonLongitude + 360) - $initialSpotLongitude;
                            }
                            #  $linkedSpotSNNSlong .= "current " . $spot->getCarringtonLongitude . " - " . $initialSpotLongitude;
                            #     $linkedSpotSNNSlong .= "\n";
                            $qLong = sprintf("%d",(($qLong)/$linkedSpotLongitudeSensitivity)*($longitudeBinsPost)+$longitudeBinsPost/2);
                            if ($qLong < 0) { $qLong = 0; }
                            #$linkedSpotSNNSlong .= "qlong = $qLong\n";
                            $linkedSpotSNNSlong .= &printBinaryLine($longitudeBinsPost, $qLong) . "\n";
                            $outputValues += $latitudeBinsPost;
                            $outputValues += $longitudeBinsPost;
                            #}
                            #$previousLatitude = $spot->getLatitude;
                            #$previousLongitude = $spot->getCarringtonLongitude;
                        }
                        $postGreenwichNumber = $spot->getGroupNumberAugmented;
                        $daysFromLimb++;
                    }
                    
                }
                while ($daysFromLimb <= 32) {
                    if ($daysFromLimb <= $highPostCut && $daysFromLimb >= $lowPostCut) {
                        $linkedSpotSNNSlat .= &printBinaryLine($latitudeBinsPost, -1);
                        $linkedSpotSNNSlat .= "\n";
                        $linkedSpotSNNSlong .= &printBinaryLine($longitudeBinsPost, -1);
                        $linkedSpotSNNSlong .= "\n";
                        $outputValues += $latitudeBinsPost;
                        $outputValues += $longitudeBinsPost;
                        #        $emptyDays++;
                    }
                        $daysFromLimb++;
                }
                if ($preGreenwichNumber eq "" || $postGreenwichNumber eq "") {
                    die "a sunspot is empty and this cannot be!";
                }

                my $copyStr = "($copies,$addNoise)";
                $tmpOutput .= "# Input pattern $pairNumber $copyStr $preGreenwichNumber -> $postGreenwichNumber \n";
                $tmpOutput .= "# potential link spot, longitude\n";
                $tmpOutput .= "$linkedSpotSNNSlong";
                $tmpOutput .= "# initial spot, longitude\n";
                $tmpOutput .= "$initialSpotSNNSlong";
                $tmpOutput .= "# potential link spot, latitude\n";
                $tmpOutput .= "$linkedSpotSNNSlat";
                $tmpOutput .= "# initial spot, latitude\n";
                $tmpOutput .= "$initialSpotSNNSlat";
                $tmpOutput .= "# pre and post group numbers of this spot:\n";
                $tmpOutput .= "$preGreenwichNumber $postGreenwichNumber\n";

                $tmpOutput .= "# Output pattern $pairNumber\n";
                $tmpOutput .= "" . $classification;
                $tmpOutput .= " \n";
                $tmpOutput .= " \n";
                #print "completed loop, copies = $copies\n";
                $copies--;
                    switch ($copies % 4) {
                        #print " value = " . $copies % 4;
                        case 0 {$initialSpotLongitudeSensitivity += 15} # lower means more sensitive
                        case 1 {$initialSpotLatitudeSensitivity += 30}
                        case 2 {$linkedSpotLongitudeSensitivity += 30}
                        case 3 {$linkedSpotLatitudeSensitivity += 15}
                        else { die " this shouldn't happen!"; }
                    }
                $addNoise = 1 + int(rand(4*7));
                $noiseCount = 7*4;
                #print $tmpOutput;
                # only produce output if the linked spot
                # is not blank.
                    $outputStr .= $tmpOutput;
                    #if ($emptyDays == 7) {
                    #    $outputStr .= $tmpOutput;
                    #    #    $linkedSpotSNNSlong .= "emptydays: $emptyDays limbdays = $daysFromLimb\n";
                    #}
                    #else {
                    #    $pairNumber--;
                    #}
            }
        }
    }
    #print " no spots:\n $noSpotFails\n";
    return ($outputStr, $pairNumber, $outputValues + 2);
}

sub printBinaryLine {
    my ($length, $position) = @_;
    my $returnSTR = "";
    #$returnSTR .= "printing binary line: $length $position\n";
    if ($position > $length) {
        $position = $length - 1;
        #     print STDERR "outside range $position $length\n"; $position = $length - 1;
    }
    # this bit of code should introduce some random varition in on bit across all the patterns.
    if ($noiseCount == $addNoise && $position > 0) {
        #    $returnSTR .= "$noiseCount == $addNoise, position from $position ";
        $position += -1;
        if (int(rand(2))) {
            $position += 2;
        } 
        #$returnSTR .= " changing position to $position\n";
    }
    #else {
    #    $returnSTR .= "$noiseCount != $addNoise, position from $position\n";
    #}

    for (my $i = 0; $i < $length; $i++) {
        if ($i == $position) {
            $returnSTR .= "1 ";
        }
        else {
            $returnSTR .= "0 ";
        }
    }
    $noiseCount--;
    return $returnSTR;
}

#sub printSpotCentricSpots {
#    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
#    my $preSunspot = 1;
#    my $daysFromLimb = 1;
#    foreach my $spotNumber (keys (%sunspots)) {
#        #print $spotNumber;
#        print "spot group\n";
#        my $foundStart = 0;
#        my $firstGroupTime;
#        my $secondGroupTime;
#       
#        # we want to write out data with position_1 being closet to the time
#        # when the spot is obscured by solar rotation.
#        # this means that we need to order the spots before and after 
#        # obscuring opposite cronologically.
#        foreach my $obsTime (reverse sort keys %{$sunspots{$spotNumber}}) {
#            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
#                my $thisSpotDateTime = $spot->getDateTime;
#                if (!defined($firstGroupTime)) {
#                    $firstGroupTime = $thisSpotDateTime;
#                }
#                #my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
#                my $degreesFromLimb = $spot->getLongitude + 90;
#                while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
#                    $daysFromLimb++;
#                    $foundStart = 1;
#                }
#
#                print "position_$daysFromLimb ";
#                print $spot->getDateTime;
#                print " ";
#                print $spot->getGroupNumber;
#                print " ";
#                print $spot->getCarringtonLongitude;
#                print " ";
#                print $spot->getSun_West_Limb;
#                print " ";
#
##                print $spot->getSun_West_Limb - $spot->getCarringtonLongitude;
##                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
##                print " degrees from limb = $degreesFromLimb ";
##                print "within degrees: ". $dayDegrees * $daysFromLimb;
##                if ($degreesFromLimb < $dayDegrees * $daysFromLimb) {
##                    print " days from limb = $daysFromLimb ";
##                }
#                #my $westLimb = $spot->getSun_West_Limb;
#                #my $position = ($westLimb - $dayDegrees) % 360;
#                #print $position;
#                $daysFromLimb++;
#                
#                print "\n";
#            }
#        }
#    }
#}
#
#sub printDateCentricSpots {
#    foreach my $obsTime (sort keys (%sunspots)) {
#        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
#            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
#                print $spot->getDateTime;
#                my $thisSpotDateTime = $spot->getDateTime;
#                print " ";
#                print $spot->getGroupNumber;
#                print " ";
#                print $spot->getCorrectedWholeSpotArea;
#                print " ";
#                print $spot->getCorrectedUmbralArea;
#                print " ";
#                print $spot->getSun_East_Limb;
#                print " ";
#                print $spot->getSun_West_Limb;
#
#                print "\n";
#            }
#        }
#    }
#}

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
                push(@{$sunspot_array{$test_spot->getGroupNumberAugmented()}{$test_spot->getDateTime}}, $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
            }
        }
    }
    #print Dumper keys %sunspot_array;
    return \%sunspot_array;
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


# this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}

