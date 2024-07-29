#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $group = $ARGV[1];
#my $group = $ARGV[1];

my %ages;
open (FILE, $ARGV[0]) or die "can't find file";

while (<FILE>) {
    my $line = $_;
    my @bits = split(/ +/, $line);
    push(@{$ages{$bits[4]}}, $line);
}
close (FILE);

#print Dumper %ages;

foreach my $age (sort {$a <=> $b} keys %ages) {
    $age = $age + 0;
    #   print "age = $age\n";

    if ($age > 0 && $age < 45 && $group eq '1') {
        foreach my $line (@{$ages{$age}}) {
            print $line;
        }
    }
    if ($age >= 45 && $age < 72 && $group eq '2') {
        foreach my $line (@{$ages{$age}}) {
            print $line;
        }
    }
    if ($age >= 72 && $group eq '3') {
        foreach my $line (@{$ages{$age}}) {
            print $line;
        }
    }
}
#'print Dumper %ages;
