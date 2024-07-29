#!/usr/bin/perl -w

use lib '../';
use lib '../../';
use strict;
use Date::Calc qw(Add_Delta_DHMS);
use pmeph;
use Getopt::Std;
use Data::Dumper;

my $eph = new pmeph;

# From a given starting time, this code generates the future time of the 
# first east and following west limb of the sun for a given longitude.
# 

# the heavy lifting is performed by the pmeph : poor mans ephemerious

my %opts = ();
my $dateTime = "";
my $longitude = "";
getopts('d:l:', \%opts);
if (!defined($opts{'d'}) || !defined($opts{'l'})) {
    &usage();
    exit(0);
}
else { 
    $dateTime = $opts{'d'}; 
    $longitude = $opts{'l'};
}

my @carringtonTime = (split(/[ \-:]/,$dateTime),0);


my @ephResults = $eph->getLimbTimes(@carringtonTime, $longitude);

print Dumper @ephResults;

sub usage {

print <<EOT;
From a given starting time, this code generates the future time of the 
first east and following west limb of the sun for a given longitude.

Usage:
  
$0 -d 'YYYY-MM-dd hh:mm' -l longitude

    -d      : date from which the dates should be calculated.
    -l      : longitude of the desired dates.
EOT
}

exit(1);
