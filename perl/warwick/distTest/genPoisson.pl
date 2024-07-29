#!/usr/bin/perl -w  

use strict;
use Getopt::Std;
use Math::Trig;
use Math::BigInt;

sub usage {
    print STDERR <<EOF;
this program generates gumbel numbers. 
It generates 'standardadized' values.

-l #    : lamda, default = 1; 
-n #    : number of values to generate (default = 100)

example:
$0 -m 0 -v 1
EOF
    exit 0;
}

my %opts = ();
getopts("l:n:", \%opts);
my $lamda = 0;
if (defined($opts{l})) { $lamda = $opts{l}; }
my $numberOfValues = 40;
if (defined($opts{n})) { $numberOfValues = $opts{n}; }


my $xbar = &getMean($lamda);
my $sigma = &getSigma($lamda);
print STDERR "lamda = $lamda xbar = $xbar, sigma = $sigma\n";

for (my $i = 0; $i < $numberOfValues; $i += 1) {
    my $Px = &getPx($i, $lamda);# exp(-$i) * exp(-exp(-$i));

    print "x = $i ";
    print "Px = $Px ";
    print " xminusxbarOverSigma = " . ($i - $xbar)/$sigma;
    print " PxTimesSigma = " . $Px*$sigma;
    print "\n";

}

sub getPx {
    my ($x, $lamda) = @_;
    my $Px = (exp(-$lamda)*$lamda**$x)/(&fac($x));
    if ($Px < 0.001) {
        return 0;
    }
    if (!defined($Px)) {
        die "can't generate function value for: i = $x, a = $lamda\n";
    }
    return $Px;
}

sub getMean {
    return @_;
}

sub getSigma {
    return @_;
}

sub fac {
    my $x = Math::BigInt->new($_[0]);
    $x->bfac();
    return $x->numify();
}

1;
