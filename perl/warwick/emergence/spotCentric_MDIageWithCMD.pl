#!/usr/bin/perl

use strict;
use lib '../../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../../';
#use sunspot_and_faculae;
use mdiSunspot;
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

This program loads a SF Cat format data into a spot centric hash.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-l      : provide boundarys on input.

exaeple: $0 -f /local/scratch/SFcat/ASCII_sunspot_size_19961122000000_19961127235959_d6a41c -l "0, 2, 4, 7, 17"
EOF
    exit;
}

my $MAXSPOTSIZE = 10000; # there will not be spots bigger than this.
my %opts = ();
getopts("f:l:", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{l})) { usage(); }
my @boundaries = map {sprintf("%d",$_)} split(',', $opts{l});
push(@boundaries, $MAXSPOTSIZE);

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my %sizeBins = ();
    my $bin = undef;
    my $size = undef;
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if ($spot->getCorrectedWholeSpotArea > 2) {
                    $bin = &quantizePosition($spot->getCentralMeridianDistance);
                    $size = &quantizeProjectedSize($spot->getCorrectedWholeSpotArea);
                    if (!defined($sizeBins{$bin}{$size})) {
                        $sizeBins{$bin}{$size} = 0;
                    }
                    $sizeBins{$bin}{$size}++;
                }
            }
        }
    }
    #print Dumper %sizeBins;
    print "# bin; size ";
    print join " size: ", @{&getSizeBands}; 
    print " total\n";
    print "bin size";
    print join " size", @{&getSizeBands}; 
    print " total\n";
    foreach my $bin (sort numeric keys %sizeBins) {
        print "$bin ";
        my $total = 0;
        foreach my $size (sort numeric @{&getSizeBands}) {
            if (!defined($sizeBins{$bin}{$size})) {
                $sizeBins{$bin}{$size} = 0;
            }
            printf (" %d ", $sizeBins{$bin}{$size});
            $total += $sizeBins{$bin}{$size};
            #print "size = $size ";
        }
        print " $total\n";
    }
}

sub quantizePosition {
    my $value = shift;
    my $quantizeTo = 5;
    return floor($value/$quantizeTo) * $quantizeTo;
}

sub quantizeProjectedSize {
    my $value = shift;
    my @values = @{&getSizeBands()};
    for (my $i = 0; $i < scalar @values; $i++) {
        if ($value <= $values[$i]) {
            return $values[$i];
        }
    }
    return $MAXSPOTSIZE;
}
sub getSizeBands {
    return \@boundaries;
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

