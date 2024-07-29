#!/usr/bin/perl -w

use lib '../';
use lib '../../';
use strict;
use Date::Calc qw(Add_Delta_DHMS);
use pmeph;
use Getopt::Std;
use Data::Dumper;

my $eph = new pmeph;

# this code generates the longitude and of the east and west limb of the sun 
# for a given date and time - using the carrington rotation number.

# the heavy lifting is performed by the pmeph : poor mans ephemerious

my %opts = ();
my $dateTime = "";
getopts('d:', \%opts);
if (!exists($opts{'d'})) {
    print "call this code with a datetime: -d <YYYY-MM-dd hh:mm>\n\n";
    exit(0);
}
else { $dateTime = $opts{'d'}; }

#print "date time = $dateTime\n";


my @carringtonTime = (split(/[ \-:]/,$dateTime),0);

#print Dumper @carringtonTime;

#printf "%04d-%02d-%02d %02d:%02d", @carringtonTime;

my @ephResults = $eph->calc_LBP(@carringtonTime);

print " ";
#print $ephResults[3];

print " ";
printf("%.1f ", (270 - (360.0 * $ephResults[4])) % 360); 
printf("%.1f", (90 - (360.0 * $ephResults[4])) % 360); 
print "\n";


exit(1);
