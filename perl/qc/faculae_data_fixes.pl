#!/usr/bin/perl

use strict;
use lib '../';
use sunspot_and_faculae;
use sunspot;
use Getopt::Std;

# The purpose of this code is to provide fixes so the Greenwich group dataset
# 1874-1976 passes all the tests identified 
# http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/FaculaeDataTests
#
# Some fixes are easier done with a text editor - or other tools. A brief
# description of this fix will be included here.
# The change log of the RCS controlled dataset will document the changes which 
# have been made to the dataset.
#
# this file is the complement of faculae_data_tests.pl

# This code uses sunspot_and_faculae.pm to store sunspot data. It takes the 
# data from STDIN and creates an array of sunspot data.

# TODO
# It would be great to create a interface, which both sunspot.pm 
# and sunspot_and_faculae implement.


################################################################
# this is the main functions. called in order.
################################################################
my $sunspots_and_faculae_filename = &read_CommandLine; #this loads and parses spots into the hash's below
&F_Fix_Group_B($sunspots_and_faculae_filename);  #this fixes data which fails Group B test.


# These are fixes corresponding to checks in Test B
sub F_Fix_Group_B {
#
# fix No 1
# Check that no spot has the time string '. 0'
#
&GW_Fix_Group_B_No_1($sunspots_and_faculae_filename);

}

# fix a given file name to pass test B1
sub GW_Fix_Group_B_No_1 {
    my $filename = shift;
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        #
        # this is the code to perform test B0
        #
        if (substr($test_spot->getDate,0,7) ne
        $test_spot->getYear . "-" . $test_spot->getMonth) {

            #
            # this is the code to perform test B1
            #
            if (substr($test_spot->getDate,0,7) eq
                $test_spot->getYear . "-" . sprintf("%02d",$test_spot->getMonth + 1)) {
                print $test_spot->getYear . sprintf("%02d",$test_spot->getMonth + 1) . substr($test_spot->raw_string, 6);
            }
            else {
                print $test_spot->raw_string;
            }
        }
        else {
            print $test_spot->raw_string;
        }
    }
    exit(0);
}



sub read_CommandLine {
    my %args;
    getopt("sf", \%args);
    return $args{f};
}

