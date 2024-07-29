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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

usage: $0 -f file

-f      : file containing data
-n      : number of bins

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("f:n:", \%opts);
if (!defined($opts{f})) { usage(); }
if (!defined($opts{n})) { usage(); }

my $bottom = 1;
my $top = 4700;
my @binEdges = ();
my %bins;
my $numberOfPoints = 1937;
my $numberOfBins = $opts{n};

if (0) {
    for (my $i = $bottom; $i < $numberOfBins; $i += 1) {
        my $lower = $top - $top * &logN($numberOfBins-($i-1), $numberOfBins);
        my $higher = $top - $top * &logN($numberOfBins-$i, $numberOfBins);
        push (@binEdges, $higher); 

        $bins{$i - 1} = [$lower, $higher];
    }
}

if (1) {
    for (my $i = $bottom; $i < $numberOfBins; $i += 1) {
        my $lower = $i*$top/$numberOfBins; #$top - $top * &logN($numberOfBins-($i-1), $numberOfBins);
        my $higher = ($i+1)*$top/$numberOfBins; #$top - $top * &logN($numberOfBins-($i-1), $numberOfBins);
        push (@binEdges, $higher); 

        $bins{$i - 1} = [$lower, $higher];
    }
}

#print Dumper %bins;
#exit(0);

my %data = &bin_data(\@binEdges, $opts{f});

foreach my $bin (sort numeric keys %data) {
    print "bin = $bin ";
    my $ylow = $data{$bin};
    my $yhigh = $ylow;
    my ($xlow, $xhigh) = @{$bins{$bin}};
    my $xdelta = ($xhigh - $xlow)/2;
    my $x = $xlow + ($xdelta);
    my $ydelta = ($yhigh - $ylow)/2;
    my $y = ($ylow + ($ydelta))/($numberOfPoints*$xdelta*2);
    print " $x $y $xdelta $ydelta $ylow $yhigh ";
    print "\n";
}
    
sub bin_data {
    my $ref = shift;
    my $filename = shift;
    my @binEdges = @{$ref};

    my %data;
    my @data;
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my @bits = split(/ /, $line);
        my $num = $bits[2];
        push(@data, $num);
        my $bin = 0;

        while ($num > $binEdges[$bin]) {
            $bin++;
        }
        if (!defined($data{$bin})) {
            $data{$bin} = 0;
        }
        $data{$bin} += 1;

    }

    if (0) {
        my $dataMean = Statistics::Basic::Mean->new(\@data)->query;
        printf "size mean = %s\n", $dataMean;
        printf "size stdv = %s\n", Statistics::Basic::StdDev->new(\@data)->query;
    }


    return %data;
}



sub load_hours {
    my $filename = shift;
    my $binwidth = shift;
    my %bins = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my @bits = split(/ /, $line);
        my $hr = $bits[2];
        #print $line;
        my $round = floor($hr/$binwidth) * $binwidth;
        #    print "hour = $hr, round = $round\n";
        if (!defined($bins{$round})) {
            $bins{$round} = 0;
        }
        $bins{$round} += 1;
    }
    #print Dumper %bins;
    return %bins;
}




# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

sub logN {
    my ($x, $n) = @_;
    return log($x)/log($n);
}

