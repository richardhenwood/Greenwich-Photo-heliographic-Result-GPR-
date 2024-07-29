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

my $FNmean = 9;
my $FNmax = 0.367879;
my $FNstddev = 10;

print "finding mean and stdvar... ";
for (my $i = 0; $i < 50; $i++) {
    #$FNmean += 0.1;
    ($FNmean, $FNstddev) = &genFN(0, $FNmean, $FNstddev, $numberOfValues);
    #printf STDERR ("found: mean = %6f stdev = %6f \n", $FNmean, $FNstddev);
}
printf STDERR ("found: mean = %6f stdev = %6f \n", $FNmean, $FNstddev);


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
        my $Nx = ($x*$FNstddev) + $FNmean;
        my $NPx = &getPx($Nx, $a);# / $FNstddev;

        my $Px = $NPx * $FNstddev;
        
        print "x = $Nx ";
        print "Px = $NPx ";
        print "xminusxBarOverSigma = $x ";
        print "PxTimesSigma = $Px ";
        print "\n";
    } 
    exit 0;
}
else {
    &genFN($verbose, $FNmean, $FNstddev, $numberOfValues);
}


sub genFN {
    my ($verbose, $FNmean, $FNstddev, $numberOfValues) = @_;
    my %xHash = ();
    my @xList = ();
    my $cumulativeTotal = 0;
    my $lower = 0.08;
    my $upper = 30;
    my $minPx = 999;
    for (my $i = $lower; $i < $upper; $i += ($upper-$lower)/$numberOfValues) {
        my $Px = &getPx($i, $a);
        $cumulativeTotal += $Px;
    }
    for (my $i = $lower; $i < $upper; $i += ($upper-$lower)/$numberOfValues) {
        my $Px = &getPx($i, $a)/$cumulativeTotal;
        if ($Px != 0) {
            my $Ni = ($i - $FNmean)/$FNstddev;
            my $NPx = $Px*$FNstddev;
            if ($verbose) {
                printf "x = %4f ", $i;
                print "Px = $Px ";
                print " xminusxbarOverSigma = " . $Ni;
                print " PxTimesSigma = " . $NPx;
                #print " total = $cumulativeTotal";
                print "\n";
            }
            if ($Px < $minPx) { $minPx = $Px; }
            $xHash{$i} = $NPx;
            #push (@xList, $Px);
        }
    }
    #print "haSH = ";
    #print Dumper %xHash;
    #exit 0;
    foreach my $band (keys %xHash) {
        #print " ($band) x " . floor($xHash{$band}/$minPx);
        #print "\n";
        #print Dumper ($band) x floor($xHash{$band}/$minPx);
        push (@xList, ($band) x floor($xHash{$band}/$minPx));
        #@xList = map {$_/$minPx} @xList;
    }
    #print "list = ";
    #print Dumper @xList;
    $FNmean = Statistics::Basic::Mean->new(\@xList)->query;
    #$FNmean = $FNmean/$numberOfValues;
    $FNstddev = Statistics::Basic::StdDev->new(\@xList)->query;
    #$FNstddev = $FNstddev/$numberOfValues;
    if ($verbose) {
        print STDERR "total = $cumulativeTotal ";
        print STDERR "mean = $FNmean, stddev = $FNstddev\n";
    }
    if ($FNstddev == 0) {
        print STDERR "var = 0!\n";
        print STDERR Dumper @xList;
    }
    return ($FNmean, $FNstddev)
}

#sub _getPx {
#    my ($i, $a) = @_;
#    my $Px = exp(-$i) * exp(-exp(-$i/$a));
#    if (!defined($Px)) {
#        die "can't generate function value for: i = $i, a = $a\n";
#    }
#    return $Px;
#}

# this is frechet distribution PDF
sub getPx {
    my ($x, $mu) = @_;
    #$x = -$x;
    # below is the frechet CDF    
    #my $eta = 1;
    #my $Px = exp (-1/((1+$eta*($i)/$a)**(1/$eta)));
    #my $Px = (1/$a) * exp(-(1+$i/$a)**(-1))*(1 + ($i/$a))**(-2);
    
    # below is normalised frechet, but this causes me problems,,
    #my $u = -log($x) - log(2);
    #my $Px = exp(2*log(2))*(exp($u-exp($u)))**$a;

    # this is the un-normalised ersion which I'm numerically normalising;
    #my $Px = (($a)/($x**(1+$a)))*exp(-(1/($x**$a)));

    # eqn 32 & 33 from sandras paper.
    my $a = ($mu+1)/$mu;
    my $u = -$mu*log($x)-log(($mu+1)/$mu);
    my $Px = $mu*exp((($mu+1)/$mu)*log(($mu+1)/$mu))*(exp($u-exp($u)))**$a;
    if ($Px eq 'nan') {
        #print STDERR "can't generate function value for: i = $i, a = $a\n";
        $Px = 0;
    }
    elsif (!defined($Px) || $Px eq '') {
        die "can't generate function value for: x = $x, a = $a\n";
    }
    #print "px = '$Px'\n";
    return $Px;
}

# this is a gumbel CDF
#sub getPx {
#    my ($i, $a) = @_;
#    my $Px = exp(-exp(-$i/$a));
##    my $Px = exp($a-$i) * exp(-exp($a-$i));
#    if (!defined($Px)) {
#        die "can't generate function value for: i = $i, a = $a\n";
#    }
#    return $Px;
#}

# this function always comes in handy:
#sub numeric {
#    $b <=> $a;
#}

