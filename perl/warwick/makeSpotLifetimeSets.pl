#!/usr/bin/perl -w

use strict;
use Getopt::Std;

my $outputDirectory = "/users/rhenwood/ihr/data/reclassification/byAge/";

my %opts = ();
getopt('be', \%opts);
my $b = $opts{'b'};
my $e = $opts{'e'};
if (!defined($opts{'b'}) || !defined($opts{'e'})) {
    print "need to pass -b <begin time> and -e <end time> on the command line\n";
    exit 0;
}

$| = 1;

my $maximumAge = 100;

my $duration = $e - $b;
for (my $lowerLimit = $b; $lowerLimit <= $maximumAge; $lowerLimit += $duration) {
    my $upperLimit = $lowerLimit + $duration;
    print "generating spot set of lifetime between $lowerLimit and $upperLimit days\n";
    my $getLifetimeCMD = "./spotCentric_getSpotsOfLifetime.pl -b $lowerLimit -e $upperLimit > $outputDirectory$lowerLimit.$duration.txt";
    #print "$getLifetimeCMD\n";
    `$getLifetimeCMD`;
}

