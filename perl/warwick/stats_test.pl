#!/usr/bin/perl -w 

use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::Correlation;
use Statistics::Basic::StdDev;


my @array = qw(5 7 8 12 18);
my $array_ref = \@array;
    my $mean = Statistics::Basic::Mean->new($array_ref)->query;

    print "mean = $mean\n";  # hooray

    my $stddev = Statistics::Basic::StdDev->new($array_ref)->query;
    print "stddev = $stddev\n";
    # That works, but I needed to calculate a LOT of means for a lot of
    # arrays of the same size.  Furthermore, I needed them to operate FIFO
    # style.  So, they do:

    my $mo = new Statistics::Basic::Mean([1..3]);

    print $mo->query, "\n"; # the avearge of 1, 2, 3 is 2
          $mo->insert(4);   # Keeps the vector the same size automatically
    print $mo->query, "\n"; # so, the average of 2, 3, 4 is 3

    # You might need to keep a running average, so I included a growing
    # insert

          $mo->ginsert(5);  # Expands the vector size by one and appends a 5
    print $mo->query, "\n"; # so, the average is of 2, 3, 4, 5 is 7/2

    # And last, you might need the mean of [3, 7] after all the above

          $mo->set_vector([2,3]);  # *poof*, the vector is 2, 3!
    print $mo->query, "\n"; # and the average is now 5/2!  Tadda!

    # These functions all work pretty much the same for ::StdDev and
    # ::Variance but they work slightly differently for CoVariance and
    # Correlation.

    # Not suprisingly, the correlation of [1..3] and [1..3] is 1.0

    my $co = new Statistics::Basic::Correlation( [1..3], [1..3] );

    print $co->query, "\n";

    # Cut the correlation of [1..3, 7] and [1..3, 5] is less than 1

          $co->ginsert( 7, 5 );
    print $co->query, "\n";

my @testArray = qw(3 5 7 8 9);    
print 'arry std test ' . Statistics::Basic::StdDev->new(\@testArray)->query;
