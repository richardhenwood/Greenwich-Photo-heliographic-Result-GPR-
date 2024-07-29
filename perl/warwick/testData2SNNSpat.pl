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
my ($outputStr, $numPats) = &printLinkedSpotsARFF();
&patheader($numPats);
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
    my $pats = shift;
    my $dateTime = time();
    print <<SNNSpatHEADER;
SNNS pattern definition file V3.2
generated at Mon Aug 3 15:58:23 2006


No. of patterns : $pats
No. of input units : 96
No. of output units : 1

SNNSpatHEADER
}

sub printLinkedSpotsARFF {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    my $daysFromLimb = 1;
    my $pairNumber = 0;
    my $outputStr = "";

    foreach my $initialSpot (keys (%linkedSpots)) {
        #print "initial spot = $initialSpot\n";
        my $tmpOutput = "";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
        my $classification = "notlinked";
        my $preGreenwichNumber = "";
        my $postGreenwichNumber = "";
        foreach my $linkCandidate (@{$linkedSpots{$initialSpot}}) {
            $pairNumber++;
            my $initialSpotARFF = "";
            my $linkedSpotARFF = "";
            my $outputValues = 0;
            if ($linkCandidate =~ m/y/) {
                $classification = "1";
            }
            else { $classification = "-1";}
            $linkCandidate =~ s/(\d+).*/$1/;
            #         print "link = $initialSpot -> $linkCandidate = $classification\n";
            my $daysFromLimb = 1;
            foreach my $obsTime (reverse sort keys %{$sunspots{$initialSpot}}) {
                foreach my $spot (@{$sunspots{$initialSpot}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime  = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $initialSpotARFF .= "0 ";
                        $initialSpotARFF .= "0 ";
#                        $initialSpotARFF .= " ?";
#                        $initialSpotARFF .= " ?";
#                        $initialSpotARFF .= " ?";
                        $initialSpotARFF .= "0 ";

                        $daysFromLimb++;
                        $foundStart = 1;
                        $outputValues++;
                    }

                    $initialSpotARFF .= $spot->getLatitude . " ";
                    $initialSpotARFF .= $spot->getCarringtonLongitude . " ";
                    #                   $initialSpotARFF .= sprintf (", longitude_%02d0", 1 + $spot->getCarringtonLongitude/10);
                    #$initialSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    #$initialSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $initialSpotARFF .= $spot->getCorrectedWholeSpotArea . " ";

                    $preGreenwichNumber = $spot->getGroupNumber;

                    $daysFromLimb++;
                    $outputValues++;
                }
            }
            while ($daysFromLimb <= 16) {
                $initialSpotARFF .= "0 ";
                $initialSpotARFF .= "0 ";
#                $initialSpotARFF .= " ?";
#                $initialSpotARFF .= " ?";
#                $initialSpotARFF .= " ?";
                $initialSpotARFF .= "0 ";

                $daysFromLimb++;
                $outputValues++;
            }
            
            foreach my $obsTime (reverse sort keys %{$sunspots{$linkCandidate}}) {
                foreach my $spot (@{$sunspots{$linkCandidate}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $linkedSpotARFF .= "0 ";
                        $linkedSpotARFF .= "0 ";
#                        $linkedSpotARFF .= " ?";
#                        $linkedSpotARFF .= " ?";
#                        $linkedSpotARFF .= " ?";
                        $linkedSpotARFF .= "0 ";

                        $daysFromLimb++;
                        $foundStart = 1;
                        #print "days = $daysFromLimb ";
                        $outputValues++;
                    }

                    $linkedSpotARFF .= $spot->getLatitude . " ";
                    $linkedSpotARFF .= $spot->getCarringtonLongitude . " ";
                    #$linkedSpotARFF .= sprintf (", longitude_%02d0", 1 + $spot->getCarringtonLongitude/10);
                    #$linkedSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    #$linkedSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $linkedSpotARFF .= $spot->getCorrectedWholeSpotArea . " ";

                    #$postGreenwichNumber = $spot->getGroupNumber;

                    $daysFromLimb++;
                    $outputValues++;
                }
            }
            while ($daysFromLimb <= 32) {
                $linkedSpotARFF .= "0 ";
                $linkedSpotARFF .= "0 ";
#                $linkedSpotARFF .= ", ?";
#                $linkedSpotARFF .= ", ?";
#                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= "0 ";

                $daysFromLimb++;
                $outputValues++;
            }

            #           print $pairNumber;
            $tmpOutput .= "# Input pattern $pairNumber\n";
            $tmpOutput .= "$initialSpotARFF";
            $tmpOutput .= "$linkedSpotARFF";
#           $tmpOutput .=t ", " . $preGreenwichNumber;
#           $tmpOutput .=t ", " . $postGreenwichNumber;
#           $tmpOutput .=t ", " . $classification;
            $tmpOutput .= "\n";

            $tmpOutput .= "# Output pattern $pairNumber\n";
            $tmpOutput .= "" . $classification;
            $tmpOutput .= "\n";
#            $tmpOutput .= "outputvalues =  $outputValues";
#            $tmpOutput .= "\n";
            #print " - values = $outputValues\n\n";
        }
        $outputStr .= $tmpOutput;
    }
    return ($outputStr, $pairNumber);
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

