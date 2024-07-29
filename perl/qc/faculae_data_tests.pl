#!/usr/bin/perl 

use strict;
use lib '..';
use sunspot_and_faculae;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Delta_Days);
use POSIX qw( mktime );
use List::Util qw(sum);
use Getopt::Std;

# The purpose of this code is to perform a number of tests of the 
# Greenwich Faculae dataset 1874 ~ 1955 . This has been shown to have 
# errors within it.
# A series of tests have been identified 
# http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/FaculaeDataTests
# which will be used to give the dataset validity and self consistency.
# Those tests are implemented here.
 
# This code uses sunspot_and_faculae.pm to store sunspot data. It takes the 
# in a file specified on the command line with the -f flag.

# TODO
# It would be great to create a interface, which both sunspot.pm 
# and sunspot_and_faculae.pm implement.


################################################################
# this is the main functions. called in order.
################################################################
#this loads and parses spots into the hash's below
my $sunspots_and_faculae_filename = &read_CommandLine; 
#this performs the Group A tests on the dataset
&F_Test_Group_A;  
#this performs the Group B tests on the dataset
&F_Test_Group_B;
#this performs the Group C tests on the dataset
&F_Test_Group_C;

# This function collects the Group A tests together.
# Repeated parsing of the file is very innefficient.
# It is implement like this to provide declaritive testing.
sub F_Test_Group_A {
#
# test No 1
# Check that there are no occations where position data is missing
#
&F_Test_Group_A_No_1($sunspots_and_faculae_filename);

#
# test No 2
# Check there are no occations where a sunspot dosen't have spot size data
#
&F_Test_Group_A_No_2($sunspots_and_faculae_filename);

# 
# test No 3
# Check that area and faculae data are correctly formed
#
&F_Test_Group_A_No_3($sunspots_and_faculae_filename);

}

# This function collects the Group B tests together.
sub F_Test_Group_B {
#
# test No 0
# Create short list of spots where the dates are wrong.
#
my $date_error_shortlist_ref = &F_Test_Group_B_No_0($sunspots_and_faculae_filename);
if ( length $date_error_shortlist_ref != 0 ) {
#
# test No 1
# Perform test B0 on shortlist created by Test B0
&F_Test_Group_B_No_1($date_error_shortlist_ref);
#
# test No 2
# Perform test B1 on shortlist created by Test B1
&F_Test_Group_B_No_2($date_error_shortlist_ref);
}

#
# test No 3
# provided the previous tests pass, check the data is in cronological order
&F_Test_Group_B_No_3($sunspots_and_faculae_filename);
}

sub F_Test_Group_C {
# these tests benifit from the spot data being parsed into a hash to begin with.
my %sunspots = &Load_Sunspot_and_Faculae($sunspots_and_faculae_filename);
#
# test No 1
# Check the sum values at the end of grouped measurements are correct: Umbral Areas
#
&F_Test_Group_C_No_1(\%sunspots);
#
# test No 2
# Check the sum values at the end of grouped measurements are correct: Whole Spot
#
&F_Test_Group_C_No_2(\%sunspots);
#
# test No 3
# Check the sum values at the end of grouped measurements are correct: Faculae
#
&F_Test_Group_C_No_3(\%sunspots);
#
# test No 4
# Check the heliographic and helioprojective spot positions coincide
#
#&F_Test_Group_C_No_4(\%sunspots);
}

# test a given file name against test A1
sub F_Test_Group_A_No_1 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
#
# this is the code to perform test A1
#
        if ($test_spot->is_sun_position()) {
            if ($test_spot->getCarringtonLongitude eq '    ' ||
                $test_spot->getLatitude eq '    ') {
                push(@failed_spots, $test_spot);
                $test_fail = 1;
            }
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A1 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }           
        exit(0); 
    }
    exit(0);
}
 
# test a given file name against test A2
sub F_Test_Group_A_No_2 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
#
# this is the code to perform test A2
#
        if ($test_spot->is_spot()) {
            if ($test_spot->getCorrectedUmbralArea eq '' ||
                $test_spot->getCorrectedWholeSpotArea eq '') {
                push(@failed_spots, $test_spot);
                $test_fail = 1;
            }
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A2 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }           
        exit(0); 
    }
    exit(0);
}

# test a given file name against test A3
sub F_Test_Group_A_No_3 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
#
# this is the code to perform test A3
#
        if (!($test_spot->getCorrectedUmbralArea eq '') !=
            !($test_spot->getCorrectedWholeSpotArea eq '')) {
                push(@failed_spots, $test_spot);
                $test_fail = 1;
        }
        elsif ($test_spot->getCorrectedUmbralArea eq '' &&
            $test_spot->getCorrectedWholeSpotArea eq '' && 
            $test_spot->getFaculaeArea eq '') {
                push(@failed_spots, $test_spot);
                $test_fail = 1;
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test A3 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }           
        exit(0); 
    }
    exit(0);
}

# code to produce short list as idenitified in B0
# makes shortlist of spots where date data is inconsistent
sub F_Test_Group_B_No_0 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
#
# this is the code to perform test B0
#
        if (substr($test_spot->getDate,0,7) ne 
            $test_spot->getYear . "-" . $test_spot->getMonth) {
            push(@failed_spots, $test_spot);
            $test_fail = 1;
        }
    }
    if (!$test_fail) {
        return \@failed_spots;
    }
    else {
        return \@failed_spots;
        exit(0); 
    }
    exit(0);
}

# code to test against B1
# wrong month was taken from previous block of data
sub F_Test_Group_B_No_1 {
    my $time_error_spots_ref = shift;
    my @time_error_spots = @{$time_error_spots_ref};
    my $test_fail = 0;
    my @failed_spots = ();
    foreach my $time_error_spot (@time_error_spots) {
#
# this is the code to perform test B1
#
        if (substr($time_error_spot->getDate,0,7) eq
            $time_error_spot->getYear . "-" . sprintf("%02d",$time_error_spot->getMonth + 1)) {
            push(@failed_spots, $time_error_spot);
            $test_fail = 1;
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test B1 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }
        exit(0);
    }
    exit(0);
}
# code to test against B2
# spots have decimal place in the wrong place
sub F_Test_Group_B_No_2 {
    my $time_error_spots_ref = shift;
    my @time_error_spots = @{$time_error_spots_ref};
    my $test_fail = 0;
    my @failed_spots = ();
    foreach my $time_error_spot (@time_error_spots) {
#
# this is the code to perform test B2
#
        if (substr($time_error_spot->getDate,0,7) ne
            $time_error_spot->getYear . "-" . sprintf("%02d",$time_error_spot->getMonth + 1)) {
            push(@failed_spots, $time_error_spot);
            $test_fail = 1;
        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test B2 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }
        exit(0);
    }
    exit(0);
}

# code to test against B3
# spots are cronological 
sub F_Test_Group_B_No_3 {
    my $filename = shift;
    my $test_fail = 0;
    my @failed_spots = ();
    open (FH, $filename);
    my $previous_spot = new sunspot_and_faculae;
    my $firsttime = 1;
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        #
        # this is the code to perform test B3
        #
        if ($firsttime) {
            $previous_spot = $test_spot;
            $firsttime = 0;
        }
        my @time1 = ($previous_spot->getDateTime() =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
        my @time2 = ($test_spot->getDateTime() =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/,0);
        my @diff = Delta_DHMS(@time1, @time2);
        my $result = $diff[3] + ($diff[2]*60) + ($diff[1]*3600) + ($diff[0]*86400);
        if ($result < 0) {
            push(@failed_spots, $test_spot);
            $test_fail = 1;
        }
        $previous_spot = $test_spot;
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test B3 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }
        exit(0);
    }
    exit(0);
}

# code to test against C1
# the sum of individual umbral areas is equal to the recorded sum.
sub F_Test_Group_C_No_1 {
    my $sunspots_ref = shift;
    my %sunspots = %{$sunspots_ref};
    my $test_fail = 0;
    my @failed_obs_date = ();
    foreach my $obs_date (sort keys %sunspots) {
        my $umbralArea = 0;
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            foreach my $spot (@{$sunspots{$obs_date}{$spot_no}}) {
                if ($spot_no ne 'group_total') {
                    $umbralArea += $spot->getCorrectedUmbralArea();
                }
            }
        }
        my $totals = ${$sunspots{$obs_date}{'group_total'}}[0];
        if ( $totals->getCorrectedUmbralArea() != $umbralArea) {
            $test_fail = 1;
            push(@failed_obs_date, substr($totals->raw_string,0, 16));

        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test C3 with data:\n";
        for (my $i = 0; $i < scalar @failed_obs_date; $i++) {
            print $failed_obs_date[$i] . "\n";
        }
        exit(0);
    }
    exit(0);
}

# code to test against C2
# the sum of individual whole spot areas is equal to the recorded sum.
sub F_Test_Group_C_No_2 {
    my $sunspots_ref = shift;
    my %sunspots = %{$sunspots_ref};
    my $test_fail = 0;
    my @failed_obs_date = ();
    foreach my $obs_date (sort keys %sunspots) {
        my $umbralArea = 0;
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            foreach my $spot (@{$sunspots{$obs_date}{$spot_no}}) {
                if ($spot_no ne 'group_total') {
                    $umbralArea += $spot->getCorrectedWholeSpotArea();
                }
            }
        }
        my $totals = ${$sunspots{$obs_date}{'group_total'}}[0];
        if ( $totals->getCorrectedWholeSpotArea() != $umbralArea) {
            $test_fail = 1;
            push(@failed_obs_date, substr($totals->raw_string,0, 16));

        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test C3 with data:\n";
        for (my $i = 0; $i < scalar @failed_obs_date; $i++) {
            print $failed_obs_date[$i] . "\n";
        }
        exit(0);
    }
    exit(0);
            
}

# code to test against C3
# the sum of individual whole spot areas is equal to the recorded sum.
sub F_Test_Group_C_No_3 {
    my $sunspots_ref = shift;
    my %sunspots = %{$sunspots_ref};
    my $test_fail = 0;
    my @failed_obs_date = ();
    foreach my $obs_date (sort keys %sunspots) {
        my $umbralArea = 0;
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            foreach my $spot (@{$sunspots{$obs_date}{$spot_no}}) {
                if ($spot_no ne 'group_total') {
                    $umbralArea += $spot->getFaculaeArea();
                }
            }
        }
        my $totals = ${$sunspots{$obs_date}{'group_total'}}[0];
        if ( $totals->getFaculaeArea() != $umbralArea) {
            $test_fail = 1;
            push(@failed_obs_date, substr($totals->raw_string,0, 16));

        }
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test C3 with data:\n";
        for (my $i = 0; $i < scalar @failed_obs_date; $i++) {
            print $failed_obs_date[$i] . "\n";
        }
        exit(0);
    }
    exit(0);
}


# code to test against C4
# the heliographic and helioprojective position of spots coincide.
sub F_Test_Group_C_No_4 {
    my $sunspots_ref = shift;
    my %sunspots = %{$sunspots_ref};
    my $test_fail = 0;
# this is the tollerance for the margin of error with heliographic->helioprojective conversion.    
    my ($long_tollerance, $lat_tollerance) = (0.1, 0.1);
    my @failed_spots = ();
    foreach my $obs_date (sort keys %sunspots) {
        my $umbralArea = 0;
        my $max_in_group = 0;
        foreach my $spot_no (sort keys %{$sunspots{$obs_date}}) {
            foreach my $spot (@{$sunspots{$obs_date}{$spot_no}}) {
                if ($spot->is_spot()) {
                    $spot->calculateLBP();
                    $spot->getCalculatedHelioprojective();
                    #print $spot->getCalculatedLatitude() . " =?= " . $spot->getLatitude() . "\n";
                    my $diff = $spot->getCalculatedLatitude() - $spot->getLatitude(); 
                    if (abs($diff) > $max_in_group) {
                        $max_in_group = $diff;
                    }
                    #my ($calculated_long, $calculated_lat) = $spot->getCalculatedHelioprojective();
                    #if ($calculated_long - $spot->getCarringtonLongitude <= $long_tollerance ||
                    #    $calculated_lat - $spot->getLatitude <= $lat_tollerance) {
                        #        push(@failed_spots, $spot);
                        #    $test_fail = 1;
                            
                        #}
                }
            }
        }
        print "$obs_date  $max_in_group\n";
    }
    if (!$test_fail) {
        return;
    }
    else {
        print "Failure of test B3 with data:\n";
        foreach my $failed_spot (@failed_spots) {
            print $failed_spot->raw_string;
        }
        exit(0);
    }
    exit(0);
}

# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot_and_Faculae {
    my $filename = shift;
    my %sunspot_array = ();
    my $line_no = 1;
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}}, $test_spot);
        }
        elsif ($test_spot->is_faculae()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'faculae'}}, $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
        }
        else {
            print "Cannot classify spot data for line $line_no. Exiting.\n";
#            exit(1);
        }
        $line_no++;
    }
    return %sunspot_array;
}
sub read_CommandLine {
    my %opts;
    getopts("f:", \%opts);
        if (!$opts{f}) {&usage()};
    return $opts{f};
}

sub usage() {
    print STDERR << "EOF";
usage: $0 -f file

-f file  : file containing faculae data formatted according to
     ftp://ftp.ngdc.noaa.gov/STP/SOLAR_DATA/SOLAR_WHITE_LIGHT_FACULAE/White_Light_Faculae.fmt

This program applies the tests identified at
http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/FaculaeDataTests
to the file containing faculae data.
     
EOF
    exit;
}
1;
