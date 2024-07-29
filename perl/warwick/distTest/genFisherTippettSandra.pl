#!/usr/bin/perl -w  

use strict;
use Getopt::Std;
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use lib '../../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use POSIX;
use Data::Dumper;



sub usage {
    print STDERR << "EOF";
this program generates normalised frechet with a given value
of a:

-a      : value
-v      : verbose
-x #    : calculate Px for a given value of x or:
-f      : take list of x values from stdin
-n #    : generate # values of the pdf. (default = 100)
-l #    : lowest value of the sequence
-h #    : highest value of the sequence


example $0 -a 1
EOF
    exit;
}

my %opts = ();
getopts("a:x:n:vf", \%opts);
my $a = 1.0;
if (!defined($opts{a})) { &usage(); }
$a = $opts{a};

my $verbose = 0;
if (defined($opts{v})) { $verbose = 1; }

my $singleValue = 0;
if (defined($opts{x})) { $singleValue = 1; }

my $numberOfValues = 100;
if (defined($opts{n})) { $numberOfValues = $opts{n}; }

my %groupedNumbers = ();
my $usingSTDIN = 0;
if (defined($opts{f})) { 
    $usingSTDIN = 1;
    while (my $line = <STDIN>) {
        if ($line =~ m/minusXbarOverSigma/) {
            chop($line);
            my @values = split(/ /, $line);
            #$line =~ s/\#.*//;
            $groupedNumbers{$values[3]} = 1;
            #print "line = $line\n";
            #print Dumper @values;
            #push(@{$groupedNumbers{1}}, $line);
        }
    }
}


my $pi = 3.14159;
my $piOver2 = 1.57079633;

my $totalX = 0;
my $Xcount = 0;
my $maxX = 0;

my $FNmean = 0;
my $FNmax = 0.367879;
my $FNvariance = 1;

print "finding mean and stdvar... ";
for (my $i = 0; $i < 50; $i++) {
    ($FNmean, $FNvariance) = &genFN(0, $FNmean, $FNvariance, $numberOfValues);
}
print "found: ";
printf ("mean = %6f ", $FNmean);
printf ("stdev = %6f \n", $FNvariance);


if ($singleValue) {
    my $x = $opts{x};
    my $Px = &getPx($x, $a);
    print "x = $x ";
    print "Px = $Px ";
    print "\n";
    exit 0;

}
elsif ($usingSTDIN) {
    #print Dumper %groupedNumbers;
    #my @sorted = keys %groupedNumbers;
    #print Dumper @sorted;
    #print Dumper (sort numeric @sorted);
    foreach my $x (sort  keys %groupedNumbers) {
        my $Nx = ($x*$FNvariance) + $FNmean;
        my $NPx = &getPx($Nx, $a);# / $FNvariance;

        my $Px = $NPx * $FNvariance;
        
        print "x = $Nx ";
        print "Px = $NPx ";
        print "xminusxBarOverSigma = $x ";
        print "PxTimesSigma = $Px ";
        print "\n";
    } 
    exit 0;
}
else {
    &genFN($verbose, $FNmean, $FNvariance, $numberOfValues);
}


sub genFN {
    my ($verbose, $FNmean, $FNvariance, $numberOfValues) = @_;
    my %xHash = ();
    my @xList = ();
    my $cumulativeTotal = 0;
    my $lower = 0.001;
    my $upper = 25;
    my $minPx = 999;
    for (my $i = $lower; $i < $upper; $i += ($upper-$lower)/$numberOfValues) {
        my $Px = &getPx($i, $a);
        if ($Px >= 0.001) {
            my $Ni = ($i - $FNmean)/$FNvariance;
            my $NPx = $Px*$FNvariance;
            #if (1) {
            if ($verbose) {
                $cumulativeTotal += $NPx;
                printf "x = %4f ", $i;
                print "Px = $Px ";
                print " xminusxbarOverSigma = " . $Ni;
                print " PxTimesSigma = " . $NPx;
                print " total = $cumulativeTotal";
                print "\n";
            }
            if ($Px < $minPx) { $minPx = $Px; }
            $xHash{$i} = $Px;
            #push (@xList, $Px);
        }
    }
    #print "haSH = ";
    #print Dumper %xHash;
    #print "min px = $minPx\n";
    foreach my $band (sort keys %xHash) {
        # print "($band) $minPx x " . $xHash{$band} . " " .  floor($xHash{$band}/$minPx);
        #print "\n";
        push (@xList, ($band) x floor($xHash{$band}/$minPx));
        #@xList = map {$_/$minPx} @xList;
    }
    #print "list = ";
    #print Dumper @xList;
    $FNmean = Statistics::Basic::Mean->new(\@xList)->query;
    #$FNmean = $FNmean/$numberOfValues;
    $FNvariance = Statistics::Basic::StdDev->new(\@xList)->query;
    #$FNvariance = $FNvariance/$numberOfValues;
    if ($verbose) {
        print STDERR "total = $cumulativeTotal\n";
        print STDERR "mean = $FNmean, stddev = $FNvariance\n";
    }
    if ($FNvariance == 0) {
        print STDERR "var = 0!\n";
        print STDERR Dumper @xList;
    }
    return ($FNmean, $FNvariance**(1/2))
}


# this is fisher-tippett(?) distribution PDF i think~!
sub getPx {
    my ($i, $a) = @_;
#    $i = -$i;
#    my $z = exp($i);
#    my $Px = exp($i-exp($i))**$a; 

    my $Px = ($a/($i**(1+$a)))*exp(-1/($i**$a));

    if ($Px < 0.001) { 
        return 0;
    }
    if (!defined($Px)) {
        die "can't generate function value for: i = $i, a = $a\n";
    }
    return $Px;
}


