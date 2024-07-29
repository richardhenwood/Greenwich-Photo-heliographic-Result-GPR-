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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Day_of_Year);
use List::Util qw(sum);
use Getopt::Std;


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

This program prints the solar semidiameter for a given day of year.
It uses values from pmeph.pm

usage: $0 <-d day_of_year|-D date>

-d      : the day of interest
-D      : the date of interest (ie. yyyy/mm/dd)

example: $0 -d 100
EOF
    exit;
}

my %opts = ();
getopts("d:D:", \%opts) ;
if (!defined($opts{D}) && !defined($opts{d})) { usage(); }

my $day_of_year = $opts{d};
if (defined($opts{D})) {
    $day_of_year = Day_of_Year(split(/[\/-]/,$opts{D}));
}



my $ephmis = new pmeph;

print "day_of_year = $day_of_year, solar semidiameter = " . $ephmis->SunSemiDiameter($day_of_year);
print "\n";


exit 0;
