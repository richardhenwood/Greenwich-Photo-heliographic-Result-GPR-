#!/usr/bin/perl

use strict;
use lib '../../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../../';
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
This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

This program generates a density function of size for given greenwich input.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-r      : number of regions to divide the density function into (default = 6)

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("f:r:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $regions = 6;
if (defined($opts{r})) { $regions = $opts{r}; }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    
    my %wholeSizes = ();
    my $totalSpots = 0;
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {

                my $spotSize =  $spot->getCorrectedWholeSpotArea;
                if (!defined($wholeSizes{$spotSize})) {
                    $wholeSizes{$spotSize} = 0;
                }
                $wholeSizes{$spotSize}++;
                $totalSpots++;
            }
        }
    }
    #print Dumper %wholeSizes;
    #printf("%d %d\n",$totalSpots,$regions);
    my $boundary = ceil($totalSpots/$regions);
    my $regionCount = 0;
    my $previousRegionCount = 0;
    my @boundarys = (0);
    foreach my $size (sort numeric keys %wholeSizes) {
        printf ("size %d count %d\n", $size, $wholeSizes{$size});
        $regionCount += $wholeSizes{$size};
        if ($regionCount % $boundary < $previousRegionCount % $boundary) {
            #print "crossed boundary: $boundary, $regionCount\n";
            push(@boundarys, $size);
        }
        $previousRegionCount = $regionCount;
    }
    print "# total = $totalSpots";
    print " boundarys: " . (join ", ", @boundarys);
    print "\n";
}
                                                                                                                                                                                                                                                                            


# this subroutine loads greenwich data into a hash with the spot number as the key.
sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        # ignore all lines which start with a '#' or are blank
        if (!($line =~ m/^</ || $line =~ m/^\s+/)) {
            my $test_spot = new sunspot;
            $test_spot->parse_data_into_object($line);
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
                $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
            }
        }
    }
    return %sunspot_array;
}

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
sub Load_Sunspot_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

