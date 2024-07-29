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
# It is hard coded to accept data in the format:
# pre-disappearence spot data followed post disappearence spot data


my %opts = ();
getopts("f:t:d", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{t})) { usage(); }

my %sunspots = ();
my %linkedSpots = ();
%linkedSpots = &Load_Link_Tests($opts{t});

&ARFFheader;
if (defined($opts{d})) {
    %sunspots = &Load_Sunspot_DateCentric($opts{f});
    &printDateCentricSpots();
}
else { 
    %sunspots = &Load_Sunspot_SpotCentric($opts{f});
    &printLinkedSpotsARFF();
}

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

sub ARFFheader {
    print <<ARFFHEADER;
%
% 1. Title: Linked spots of the Greenwich dataset for solar cycle 15.
%
\@RELATION Cycle15ReoccurantSpots

\@ATTRIBUTE pairnumber  NUMERIC
\@ATTRIBUTE position {pre_01, pre_02, pre_03, pre_04, pre_05, pre_06, pre_07, pre_08, pre_09, pre_10, pre_11, pre_12, pre_13, pre_14, pre_15, post_16, post_17, post_18, post_19, post_20, post_21, post_22, post_23, post_24, post_25, post_26, post_27, post_28, post_29, post_30}
\@ATTRIBUTE timestamp   DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE latitude    NUMERIC
\@ATTRIBUTE longitude   NUMERIC
\@ATTRIBUTE longitudeSTR {latitude_010, latitude_020, latitude_030, latitude_040, latitude_050, latitude_060, latitude_070, latitude_080, latitude_090, latitude_100, latitude_110, latitude_120, latitude_130, latitude_140, latitude_150, latitude_160, latitude_170, latitude_180, latitude_190, latitude_200, latitude_210, latitude_220, latitude_230, latitude_240, latitude_250, latitude_260, latitude_270, latitude_280, latitude_290, latitude_300, latitude_310, latitude_320, latitude_330, latitude_340, latitude_350, latitude_360}
\@ATTRIBUTE umbralsize        NUMERIC
\@ATTRIBUTE wholespotsize        NUMERIC
\@ATTRIBUTE greenwichNumber      NUMERIC
\@ATTRIBUTE classification  {linked, notlinked}

\@DATA
ARFFHEADER
}

sub printLinkedSpotsARFF {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    my $daysFromLimb = 1;
    my $pairNumber = 1;

    foreach my $initialSpot (keys (%linkedSpots)) {
        #print "initial spot = $initialSpot\n";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
        my $classification = "notlinked";
        foreach my $linkCandidate (@{$linkedSpots{$initialSpot}}) {
            my $initialSpotARFF = "";
            my $linkedSpotARFF = "";
            $daysFromLimb = 16;
            if ($linkCandidate =~ m/y/) {
                $classification = "linked";
            }
            else { $classification = "notlinked";}
            $linkCandidate =~ s/(\d+).*/$1/;
            #         print "link = $initialSpot -> $linkCandidate = $classification\n";
            foreach my $obsTime (reverse sort keys %{$sunspots{$linkCandidate}}) {
                foreach my $spot (@{$sunspots{$linkCandidate}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $daysFromLimb++;
                        $foundStart = 1;
                    }

                    $linkedSpotARFF .= $pairNumber;
                    $linkedSpotARFF .= sprintf (", post_%02d", $daysFromLimb);
                    $linkedSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    $linkedSpotARFF .= ", " . $spot->getLatitude;
                    $linkedSpotARFF .= ", " . $spot->getCarringtonLongitude;
                    $linkedSpotARFF .= sprintf (", latitude_%02d0", $spot->getCarringtonLongitude/10);
                    $linkedSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $linkedSpotARFF .= ", " . $spot->getCorrectedWholeSpotArea;
                    $linkedSpotARFF .= ", " . $spot->getGroupNumber;
                    $linkedSpotARFF .= ", " . $classification;
                    $linkedSpotARFF .= "\n";
                    $daysFromLimb++;
                    #              print "\n";
                }
            }
            my $daysFromLimb = 1;
            foreach my $obsTime (reverse sort keys %{$sunspots{$initialSpot}}) {
                foreach my $spot (@{$sunspots{$initialSpot}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $daysFromLimb++;
                        $foundStart = 1;
                    }

                    $initialSpotARFF .= $pairNumber;
                    $initialSpotARFF .= sprintf (", pre_%02d", $daysFromLimb);
                    $initialSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    $initialSpotARFF .= ", " . $spot->getLatitude;
                    $initialSpotARFF .= ", " . $spot->getCarringtonLongitude;
                    $initialSpotARFF .= sprintf (", latitude_%02d0", $spot->getCarringtonLongitude/10);
                    $initialSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $initialSpotARFF .= ", " . $spot->getCorrectedWholeSpotArea;
                    $initialSpotARFF .= ", " . $spot->getGroupNumber;
                    $initialSpotARFF .= ", " . $classification;
                    $initialSpotARFF .= "\n";
                    $daysFromLimb++;
                    
                    #    print "\n";
                }
            }
            print "$initialSpotARFF";
            print "$linkedSpotARFF";
            $pairNumber++;
        }
    }
    if (0) {
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

usage: $0 -f file -t triningdata

-f      : file containing data, in Greenwich format.
-t      : file containing link candidates in our made up format

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -t 
EOF
    exit;
}
                                                                                                                        


# this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}

