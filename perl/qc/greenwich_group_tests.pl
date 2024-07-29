#!/usr/bin/perl

use strict;
use sunspot_and_faculae;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Getopt::Std;

# The purpose of this code is to perform a number of tests of the 
# Greenwich group dataset 1874 - 1976. This has been shown to have 
# errors within it.
# A series of tests have been identified 
# http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/GreenwichSunspotGroupReports
# which will be used to give the dataset validity and self consistency.
# Those tests are implemented here.
 
# This code uses sunspot_and_faculae.pm to store sunspot data. It takes the 
# data from STDIN and creates an array of sunspot data.

# TODO
# It would be great to create a interface, which both sunspot.pm 
# and sunspot_and_faculae implement.


################################################################
# this is the main functions. called in order.
################################################################
&read_CommandLine; #this loads and parses spots into the hash's below
&GW_Test_Group_A;  #this performs the Group A test on the dataset


my $sunspots_filename = "";
my %sunspots = ();
my $sunspots_and_faculae_filename = "";
my %sunspots_and_faculae = ();
# this hash collects all the dates with duplicate spots, 
# and how many spots are recoreded more than once.
my %duplicate_spots = ();


# This function collects the Group A tests together.
# Repeated parsing of the file is very innefficient.
# It is implement like this to provide declaritive testing.
sub GW_Test_Group_A {
#
# test No 0
# Check that no spot has the time string '. 0'
#
#&GW_Test_Group_A_No_0($sunspots_filename);
#
# test No 1
# check that not spot occurs more than once for a given day
#
#&GW_Test_Group_A_No_1($sunspots_filename);
#
# test No 2
# check no days are omitted
#
&GW_Test_Group_A_No_2($sunspots_filename);
#
# test No 3
# check no days are omitted
#
#&GW_Test_Group_A_No_3($sunspots_filename);


# now the initial tests have passed, load the sunspots into a hash 
# for further testing
#%sunspots = &Load_Sunspot($sunspots_filename);
}

# test a given file name against test A0
sub GW_Test_Group_A_No_0 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
#
# this is the code to perform test A0
#
        if ($test_spot->getRawDayFraction =~ / /) {
            push(@failed_spots, $test_spot);
            $test_fail = 1;
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A0 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }           
        exit(0); 
    }
    exit(0);
}

# test a given file name against test A1
sub GW_Test_Group_A_No_1 {
    my $filename = shift;
    my $test_fail = 0;
    my %sunspot_array = ();
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
# 
# this is the code to perform test A1
#
        if (exists($sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()})) {
            my $first_spot = $sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()};
            if ($first_spot->getNumberSuffix eq $test_spot->getNumberSuffix) {
                push(@failed_spots, $first_spot);
                push(@failed_spots, $test_spot);
                $test_fail = 1;
            }
        }
        $sunspot_array{$test_spot->getDateTime}{$test_spot->Greenwich_sunspot_group_number} = $test_spot;

    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A1 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->getOrigionalGreenwichFormat;
        }
        exit(0);
    }
    exit(0);
}

# test a given file name against test A2
sub GW_Test_Group_A_No_2 {
    my $filename = shift;
    my $test_fail = 0;
    my %sunspot_array = ();
    if (!(%sunspot_array)) {
        %sunspot_array = &Load_Sunspot($filename);
    }
    my @failed_spots = ();
    my $previous_spot_date = "";
    foreach my $date (sort keys %sunspot_array) {
# 
# this is the code to perform test A2
#
        if (substr($previous_spot_date,0,10) eq substr($date,0,10)) {
            foreach my $spotNo (keys %{$sunspot_array{$previous_spot_date}}) {
                push(@failed_spots, $sunspot_array{$previous_spot_date}{$spotNo}->getOrigionalGreenwichFormat());
            }
            foreach my $spotNo (keys %{$sunspot_array{$date}}) {
                push(@failed_spots, $sunspot_array{$date}{$spotNo}->getOrigionalGreenwichFormat());
            }
            $test_fail = 1;
        }
        $previous_spot_date = $date;
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A2 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print "$failed_spot";
        }
        exit(0);
    }
    exit(0);
}
 
# test a given file name against test A3
sub GW_Test_Group_A_No_3 {
    my $filename = shift;
    my $test_fail = 0;
    my %sunspot_array = ();
    if (!(%sunspot_array)) {
        %sunspot_array = &Load_Sunspot($filename);
    }
    my @failed_spots = ();
    my $test_date = 0;
    my ($start_year, $end_year) = (1874,1889);
    foreach my $date (sort keys %sunspot_array) {
# 
# this is the code to perform test A3
#
    print "date = $date\n";
        my $test_date_string = ""; 
        $test_date_string = sprintf "%4d-%02d-%02d", Add_Delta_Days($start_year,1,1,$test_date); 
        print "testing: $test_date_string\n";
        while ($test_date_string ne substr($date,0,10) && 
            substr($test_date_string,0,4) ne $end_year) {
            print "    missing = " . $test_date_string . "\n";
            push(@failed_spots, $test_date_string);
            $test_date++;
            $test_date_string = sprintf "%4d-%02d-%02d", Add_Delta_Days($start_year,1,1,$test_date); 
            $test_fail = 1;
            if ($test_date == 10000) {
                exit 0;
            }
        }
        print "not missing = " . substr($date,0,10) . "\n";
        $test_date++;
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A3 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print "$failed_spot\n";
        }
        exit(0);
    }
    exit(0);
}


# this code loads lines from a data file, parses them in to a 
# sunspot data structrue, and adds those sunspots together into 
# hash of sunspots.
# It requires test A1 to have passed for it to work safely.
sub Load_Sunspot {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        $sunspot_array{$test_spot->getDateTime}{$test_spot->Greenwich_sunspot_group_number} = $test_spot;
    }
    return %sunspot_array;
}

# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot_and_Faculae {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            print $test_spot->getOrigionalGreenwichFormat();
#            print $test_spot->getRoe() . "\n";
            # if we have more than one spot on a day, average them.
            if (exists($sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()})) {
                #      &count_duplicate_spots($test_spot);
                #  $test_spot = &average_spots( $sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber}, $test_spot);
#                print $test_spot->raw_string;
#                print "\n";
            }
            $sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()} = $test_spot;
        }
    }
    #print Dumper %duplicate_spots;
    foreach my $date (sort(keys(%duplicate_spots))) {
        print "$date " . $duplicate_spots{$date} . "\n";
    }
    #&average_multiple_spots(\%sunspot_array);
    return %sunspot_array;
}
sub count_duplicate_spots {
    my $spot1 = shift;
    if (defined($duplicate_spots{$spot1->getDateTime})) {
        $duplicate_spots{$spot1->getDateTime}++;   
        print_spot($spot1);
        print "\n";
    }
    else {
        $duplicate_spots{$spot1->getDateTime} = 1;
    }
}

sub read_CommandLine {
    my %args;
    getopt("sf", \%args);
    $sunspots_filename = $args{s};
}

=begin checks
sub average_spots {
    my ($spot1, $spot2) = @_;
    $spot1->putSolarRadii(($spot1->getSolarRadii + $spot2->getSolarRadii)/2);    
    $spot1->putPositionAngle(($spot1->getPositionAngle + $spot2->getPositionAngle)/2);
    $spot1->putCarringtonLongitude(($spot1->getCarringtonLongitude + $spot2->getCarringtonLongitude)/2);
    $spot1->putLatitude(($spot1->getLatitude + $spot2->getLatitude)/2);
    $spot1->putCorrectedUmbralArea(($spot1->getCorrectedUmbralArea + $spot2->getCorrectedUmbralArea)/2);
    $spot1->putCorrectedWholeSpotArea(($spot1->getCorrectedWholeSpotArea + $spot2->getCorrectedWholeSpotArea)/2);
    return $spot1;
}


sub get_spot {
    my $ref = shift;
    my $date = shift;
    my $spot_no = shift;
    my @spots = @{$ref};
    foreach my $spot (@spots) {
        my $spot_date = $spot->year . "-" . $spot->month . "-28";
#        print $spot->raw_string;
        print "$spot_date, $date ,, '" . $spot->group_number . "', '$spot_no'\n";
        if ($spot_date eq $date && $spot->group_number eq $spot_no) {
            print Dumper $spot;
        }
    }
}

sub do_consistency_checks {
    foreach my $obs_date (sort keys %sunspots) {
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            my $spot = $sunspots{$obs_date}{$spot_no};
#check the helioprojective longitude maps to the heliographic longitude
            my $tollerance = 0.1;
            if ($spot->getCalculatedLatitude - $spot->getLatitude > $tollerance) {
    #            print $spot->getCalculatedLatitude . " " . $spot->getLatitude . "\n";
                print "$obs_date $spot_no latitude_difference " . 
               ($spot->getCalculatedLatitude - $spot->getLatitude) . "\n";
            }
            $tollerance = 0.1;
            if ($spot->getCalculatedLongitude - $spot->getLongitude > $tollerance) {
    #            print $spot->getCalculatedLongitude . " " . $spot->getLongitude . "\n";
                print "$obs_date $spot_no longitude_difference " . 
               ($spot->getCalculatedLongitude - $spot->getLongitude) . "\n";
            }
            $tollerance = 0.1;
            if ($spot->getCalculatedCarringtonLongitude - $spot->getCarringtonLongitude > $tollerance) {
                print $spot->getCalculatedCarringtonLongitude . " " . $spot->getCarringtonLongitude . "\n";
                print "$obs_date $spot_no longitude_difference " . 
               ($spot->getCalculatedCarringtonLongitude - $spot->getCarringtonLongitude) . "\n";
            }
        }
    }    
}


# this function checks to see if spots from two different sources (greenwich 
# origional and greenwich sunspot and faculae data) are the same.
# It reports differences in the dataset.
sub compair_sets {
    foreach my $obs_date (sort keys %sunspots) {
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            my $spot = $sunspots{$obs_date}{$spot_no};
               print $spot->raw_string;
            #print Dumper $sunspots_and_faculae{$obs_date};
            if (defined($sunspots_and_faculae{$obs_date}{$spot_no})) {
                print $sunspots_and_faculae{$obs_date}{$spot_no}->getOrigionalGreenwichFormat();
                my $spot_and_f = $sunspots_and_faculae{$obs_date}{$spot_no};
                print "$obs_date Spot no $spot_no :";
                print &compair_spots($spot, $spot_and_f);
            }
            else {
                print "$obs_date Spot no: $spot_no : no spot found";
            }
            print "\n";
        }
    }
}

sub compair_spots {
    my ($spot, $spot_and_f) = @_;
    #print Dumper $spot_ref;
    my $identical = 1;
    my $s_radii_result = "";
    if ($spot->getSolarRadii != $spot_and_f->getSolarRadii) { 
        $s_radii_result = $spot->getSolarRadii . " != " . $spot_and_f->getSolarRadii; 
    } 
    my $position_angle_result = ""; 
    if ($spot->getPositionAngle != $spot_and_f->getPositionAngle) { 
        $position_angle_result = $spot->getPositionAngle . " != " . $spot_and_f->getPositionAngle; 
    }
    my $carrington_result = "";
    if ($spot->getCarringtonLongitude != $spot_and_f->getCarringtonLongitude) {
        $carrington_result = $spot->getCarringtonLongitude . " != " . $spot_and_f->getCarringtonLongitude;
    }
    my $latitude_result = "";
    if ($spot->getLatitude != $spot_and_f->getLatitude) {
        $latitude_result = $spot->getLatitude . " != " . $spot_and_f->getLatitude;
    }
    my $c_umb_result = "";
    if ($spot->getCorrectedUmbralArea != $spot_and_f->getCorrectedUmbralArea) {
        $c_umb_result = $spot->getCorrectedUmbralArea . " != " . $spot_and_f->getCorrectedUmbralArea;
    }
    my $c_ws_result = "";
    if ($spot->getCorrectedWholeSpotArea != $spot_and_f->getCorrectedWholeSpotArea) {
        $c_ws_result = $spot->getCorrectedWholeSpotArea . " != " . $spot_and_f->getCorrectedWholeSpotArea;
    }
    if ($identical) {
        return "ide ntical";
    }
    else {
        return $s_radii_result, $position_angle_result, $carrington_result, $latitude_result, $c_umb_result, $c_ws_result;
    }
}

sub print_spot {
    my $spot = shift;
    print $spot->getDate . " ";
    print $spot->getGroupNumber . " ";
    print $spot->getSolarRadii . " ";
    print $spot->getPositionAngle . " ";
    print $spot->getCarringtonLongitude . " ";
    print $spot->getLatitude . " ";
    print $spot->getCorrectedUmbralArea . " ";
    print $spot->getCorrectedWholeSpotArea . " ";
}

sub Get_Ephemeris_Data {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
    }
}
=cut checks
