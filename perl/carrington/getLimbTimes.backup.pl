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
my $latitude = "";
getopts('d:l:', \%opts);
if (!defined($opts{'d'}) || !defined($opts{'l'})) {
    &usage();
    exit(0);
}
else { 
    $dateTime = $opts{'d'}; 
    $latitude = $opts{'l'};
}



my @carringtonTime = (split(/[ \-:]/,$dateTime),0);

#print Dumper @carringtonTime;

#printf "%04d-%02d-%02d %02d:%02d", @carringtonTime;
my $iterations = 0;
my $finished = 0;
my $doneEast = 0;
while ($iterations < 10000 && !$finished) {
    @carringtonTime = Add_Delta_DHMS(@carringtonTime, 0, 0, 20 ,0); # iterate around the sun by 30 mins.

    my @ephResults = $eph->calc_LBP(@carringtonTime);

    #print " ";
#print $ephResults[3];

    #print " ";
    my $eastLimb = sprintf("%.1f ", (270 - (360.0 * $ephResults[4])) % 360); 
    my $westLimb = sprintf("%.1f", (90 - (360.0 * $ephResults[4])) % 360); 
    if ($eastLimb == $latitude && !$doneEast) {
        print "latitude = $latitude, eastlimb = $eastLimb @ @carringtonTime\n";
        $doneEast = 1;
    }
    if ($westLimb == $latitude && $doneEast) {
        print "latitude = $latitude, westLimb = $westLimb @ @carringtonTime\n";
        $finished = 1;
    }
    #print "\n";
    $iterations++;
}

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
