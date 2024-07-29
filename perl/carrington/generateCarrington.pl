#!/usr/bin/perl -w

use lib '../';
use lib '../../';
use lib '/users/rhenwood/ihr/sunspots/perl/';
use strict;
use Date::Calc qw(Add_Delta_DHMS);
use pmeph;
use Getopt::Std;

my $eph = new pmeph;

sub usage {
    print <<END;
this generates this position of the carrington meridian for
each hour from 12 midnight, 9th November, 1853 (= day 1, 0degrees);

call this code with a year: $0 -d <year>
or $0 -f <filename>, and the year will attempt to be extracted from the filename.

-r #    produce a value every # hours.
-n #    number of years

END
    exit 0;
}


# this should the be carrington epoch
#my @startTime = (1853,11,10,0,0,0); 

my %opts = ();
my $year = "";
my $defaultNumberOfYears = 1;
getopts('d:f:r:n:', \%opts);
if (!defined($opts{d}) && !defined($opts{f})) { &usage(); }
if (defined($opts{d})) { $year = $opts{d}; }
if (defined($opts{f})) { $year = $opts{f}; $year =~ s/.*(\d\d\d\d).*/$1/; }
my $hourResolution = 24;
if (defined($opts{r})) { $hourResolution = $opts{r}; }
if (defined($opts{n})) { $defaultNumberOfYears = $opts{n}; }
if ($defaultNumberOfYears == 3) { $year--; };
#if ($year eq $opts{f}) { # this happens when there is no year in the filename
#    $year = 1874;
#    $defaultNumberOfYears = 102;
#}

my @startTime = ($year,1,1,0,0,0);
my @carringtonTime = @startTime;
my $endYear = $startTime[0] + $defaultNumberOfYears;
while ($carringtonTime[0] < $endYear ) {
    #print " carrington '" . $carringtonTime[0] . "' endyear $endYear \n";
    @carringtonTime = Add_Delta_DHMS(@carringtonTime,0,$hourResolution,0,0);

    # this enables sql output.
    if (0) { 
        print "INSERT INTO carrington_daily (";
        printf "'%d-%02d-%02d %02d:%02d'", @carringtonTime;

        my @ephResults = $eph->calc_LBP(@carringtonTime);
        
        print ", ";
        print $ephResults[3];

        print ", ";
        printf("%.1f);", 360.0 * $ephResults[4]); 
        print "\n";
    }

    # this enables plain text output - which includes the heliographic
    # and  carrington longitude of the east limb of the sun.
    # and carrington longitude of the west limb...
    if (1) {
        printf "%d-%02d-%02d %02d:%02d", @carringtonTime;

        my @ephResults = $eph->calc_LBP(@carringtonTime);
        
        print " ";
        print $ephResults[3];

        print " ";
        printf("%.1f ", (270 - (360.0 * $ephResults[4])) % 360); 
        printf("%.1f", (90 - (360.0 * $ephResults[4])) % 360); 
        print "\n";
    }
}
