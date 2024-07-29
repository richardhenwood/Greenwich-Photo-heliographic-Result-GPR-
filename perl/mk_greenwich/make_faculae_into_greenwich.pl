#!/usr/bin/perl 

use strict;
use lib '..';
use sunspot_and_faculae;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Getopt::Std;
use Math::Trig;

# This code uses sunspot_and_faculae.pm to store sunspot data. It takes the 
# data from a file on the command line: -f <filename>
# and creates an array of greenwich formatted sunspot data.

# this code has been hacked to try and create a greenwich format file which 
# accomodates faculae (by representing faculae with spot no 0000).
# This is a unsatisfactory and un extensible approach, but if you want 
# to play with it, set the variable below to 1,
my $include_faculae_in_greenwich = 0;


################################################################
# this is the main functions. called in order.
################################################################
my $sunspots_filename = &read_CommandLine; #this loads and parses spots into the hash's below
my %sunspots_and_faculae = &Load_Sunspot_and_Faculae($sunspots_filename);
#print Dumper %sunspots_and_faculae;
#exit 0;
&Find_Multiple_Spots();

#my $sunspots_filename = "";
#my %sunspots_and_faculae = ();

# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
# INPUT: faculae data in the form defined by the folks in the states
# OUTPUT: Greenwich format data - with a special type of record to identify 
#   faculae data: faculae entries are given a group number of 0, and have 0
#   corrected whole spot, corrected umbral and projected umbral areas.

sub Load_Sunspot_and_Faculae {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->{'Calculate_Position_From_Measured'} = 1;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}}, $test_spot);
#            print "found spot:    " . $test_spot->raw_string();
        }
# new'ing and re-parsing fac_spot appears unnecessary but otherwise
# the spot in the array is the same!?! wierd.
        my $fac_spot = new sunspot_and_faculae;
        $fac_spot->parse_data_into_object($line);
        if ($fac_spot->is_faculae() && $include_faculae_in_greenwich) {
# if faculae letter = '', we can just plot the faculae as we would a wholespot value
            my ($usa, $wsa) = 0;
            if (!($fac_spot->getFaculaeQualifyingLetters =~ m/\w+/)) {
                $usa = 0;
                $wsa = $fac_spot->getCalcuatedProjectedFaculaeArea();
                print "letters= '" . $fac_spot->getFaculaeQualifyingLetters . "'\n";
            }
# if faculae letter = 'c', we adjust the faculae to plot it concentricly with the 
# sunspot.
            if (index($fac_spot->getFaculaeQualifyingLetters,'C') != -1) {
                $usa = $fac_spot->getCalculatedProjectedWholeSpotArea();
                $wsa = $fac_spot->getCalcuatedProjectedFaculaeArea() + $usa;
            }
# if faculae letter = 'f', we move the faculae to follow the spot.
            if (index($fac_spot->getFaculaeQualifyingLetters,'F') != -1) {

            }
            $fac_spot->putGroupNumber('0000');
            $fac_spot->putCorrectedUmbralArea(0);
            $fac_spot->putCorrectedWholeSpotArea(0);
            $fac_spot->putCalculatedProjectedUmbralArea($usa);
            $fac_spot->putCalculatedProjectedWholeSpot($wsa);
            push(@{$sunspot_array{$fac_spot->getDateTime}{'faculae'}}, $fac_spot);
            #            print "found faculae: " . $fac_spot->raw_string();
        }
    }
    return %sunspot_array;
}

# find the occations where the same spot is measured multiple times
# on a given date. requires %sunspots_and_faculae to be populated.
sub Find_Multiple_Spots {
#    print Dumper %sunspots_and_faculae;
    foreach my $date (sort keys %sunspots_and_faculae) {
#        print $date . "\n";
        foreach my $spotNo (keys %{$sunspots_and_faculae{$date}}) {
            #           print "spot no = $spotNo\n";#

# if you want to be able to print all spots, 'amalgamate_spots'!            
            &Amalgamate_Spots(\@{$sunspots_and_faculae{$date}{$spotNo}});
# this bit prints all the spots, so we can display them with my java code;
            #        foreach my $spot (@{$sunspots_and_faculae{$date}{$spotNo}}) {
            #    print $spot->getOrigionalGreenwichFormat();
            #}

            
#            if (scalar @{$sunspots_and_faculae{$date}{$spotNo}} == 1) {
                # print @{$sunspots_and_faculae{$date}{$spotNo}}[0]->getOrigionalGreenwichFormat();
                #print "$date $spotNo " . scalar @{$sunspots_and_faculae{$date}{$spotNo}} . "\n" ;
#            }
            
        }
    }
#    print Dumper %sunspots_and_faculae;
}

sub Amalgamate_Spots {
    my $spot_ref = shift;
    my @spot_array = @{$spot_ref};
    # copy the first spot as the average - so we get the time and spot number.
    # we subsequently over write the position and spot area data.
    my $averaged_spot = new sunspot_and_faculae;
    $averaged_spot = $spot_array[0];
    my $total_corrected_WS_spot_mass = 0;
    my $total_corrected_U_spot_mass = 0;
    my $total_projected_WS_spot_mass = 0;
    my $total_projected_U_spot_mass = 0;
    my $averaged_radial_distance = 0;
    my $averaged_position_angle = 0;
    my $averaged_latitude = 0;
    my $averaged_longitude = 0;
    foreach my $spot (@spot_array) {
        $total_corrected_WS_spot_mass += $spot->getCorrectedWholeSpotArea();
        $total_corrected_U_spot_mass += $spot->getCorrectedUmbralArea();
        $total_projected_WS_spot_mass += $spot->getProjectedWholeSpotArea();
        $total_projected_U_spot_mass += $spot->getProjectedUmbralArea();
        $averaged_radial_distance += $spot->getSolarRadii() * $spot->getCorrectedWholeSpotArea();
        $averaged_position_angle += $spot->getPositionAngle() * $spot->getCorrectedWholeSpotArea();
        $averaged_latitude += $spot->getLatitude() * $spot->getCorrectedWholeSpotArea();
        $averaged_longitude += $spot->getCarringtonLongitude() * $spot->getCorrectedWholeSpotArea();
    }
    $averaged_spot->putCorrectedWholeSpotArea($total_corrected_WS_spot_mass); 
    $averaged_spot->putCorrectedUmbralArea($total_corrected_U_spot_mass);
    $averaged_spot->putCalculatedProjectedWholeSpot($total_projected_WS_spot_mass);
    $averaged_spot->putCalculatedProjectedUmbralArea($total_projected_U_spot_mass);
    $averaged_spot->putSolarRadii($averaged_radial_distance/$total_corrected_WS_spot_mass);
    $averaged_spot->putPositionAngle($averaged_position_angle/$total_corrected_WS_spot_mass);
    $averaged_spot->putLatitude($averaged_latitude/$total_corrected_WS_spot_mass);
    $averaged_spot->putCarringtonLongitude($averaged_longitude/$total_corrected_WS_spot_mass);
   
    #print "'" . $averaged_spot->day_of_year . "'";
    #print $averaged_spot->raw_string;
    print $averaged_spot->getOrigionalGreenwichFormat();
}

sub read_CommandLine {
    my %args;
    getopt("f:", \%args);
    if (!defined($args{f})) { &usage(); }
    return $args{f};
}

sub usage {
        print STDERR << "EOF";
This program converts a sunspot datafile formatted 
as 'faculae' style and converts them to greenwich format

-f      : file containing faculae formatted data

example: $0 -f combinedObservationsREFfaculaeFormat.txt
EOF
    exit;
}
            
