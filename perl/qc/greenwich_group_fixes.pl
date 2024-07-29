#!/usr/bin/perl

use strict;
use sunspot_and_faculae;
use sunspot;
use Getopt::Std;

# The purpose of this code is to provide fixes so the Greenwich group dataset
# 1874-1976 passes all the tests identified 
# http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/GreenwichSunspotGroupReports
#
# Some fixes are easier done with a text editor - or other tools. A brief
# description of this fix will be included here.
# The change log of the RCS controlled dataset will document the changes which 
# have been made to the dataset.
#
# this file is the complement of greenwich_group_tests.pl

# This code uses sunspot_and_faculae.pm to store sunspot data. It takes the 
# data from STDIN and creates an array of sunspot data.

# TODO
# It would be great to create a interface, which both sunspot.pm 
# and sunspot_and_faculae implement.


################################################################
# this is the main functions. called in order.
################################################################
&read_CommandLine; #this loads and parses spots into the hash's below
&GW_Fix_Group_A;  #this performs the Group A test on the dataset


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
sub GW_Fix_Group_A {
#
# test No 0
# Check that no spot has the time string '. 0'
#
&GW_Fix_Group_A_No_0($sunspots_filename);
# test No 1
# check that not spot occurs more than once for a given day
#
#&GW_Test_Group_A_No_1($sunspots_filename);
# now the initial tests have passed, load the sunspots into a hash 
# for further testing
%sunspots = &Load_Sunspot($sunspots_filename);

}

# fix a given file name to pass test A0
sub GW_Fix_Group_A_No_0 {
    my $filename = shift;
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
#
# this is the code to fix failures due to test A0
#
        if ($test_spot->getRawDayFraction =~ / /) {
            my $fixed_time = $test_spot->getRawDayFraction;
            $fixed_time =~ s/ /0/g;    
            $test_spot->putRawDayFraction($fixed_time);
        }
        print $test_spot->getOrigionalGreenwichFormat;
    }
    exit(0);
}



sub read_CommandLine {
    my %args;
    getopt("sf", \%args);
    $sunspots_filename = $args{s};
}

