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

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in Greenwich format.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
#-i      : ignore spots which only observed once in the data.
    exit;
}

my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $filename = $opts{f};
if (-s $filename == 0) { 
    exit 0;
}


my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($filename);
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my $spotCount = 0;
    my $sizeSum = 0;
    my @sizes = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $maxSize = 0;
        my $moreThanOnce = -1;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                # print $spot->getDateTime;
                # print " ";
                # print $spot->getGroupNumber;
                # print " ";
                # print $spot->getCorrectedWholeSpotArea;
                # print " ";
                # print $spot->getCorrectedUmbralArea;
                # print "\n";
                if ($maxSize < $spot->getCorrectedWholeSpotArea) {
                    $maxSize = $spot->getCorrectedWholeSpotArea;
                }
            }
            $moreThanOnce++;
        }
        if ($moreThanOnce) {
            $spotCount++;
            $sizeSum += $maxSize;
            #print "spoot number = $spotNumber\n";
            push(@sizes, $maxSize);
        }
    }
    printf "spotcount = %s\n", $spotCount;
    my $spotMean = Statistics::Basic::Mean->new(\@sizes)->query;
    printf "size mean = %s\n", $spotMean;
    printf "size stdv = %s\n", Statistics::Basic::StdDev->new(\@sizes)->query;
    my $top = 0;
    my $bottom = 0;
    foreach my $size (@sizes) {
        $top += ($size - $spotMean)**3;
        $bottom += ($size - $spotMean)**2;
    }
    my $skewness = 0;
    if ($bottom != 0) {
        $skewness = ($spotCount**(1/2))*$top/(($bottom)**(3/2));
    }
    printf "size skew = %s\n", $skewness;

}
sub printDateCentricSpots {
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                print $spot->getDateTime;
                my $thisSpotDateTime = $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print " ";
                print $spot->getSun_East_Limb;
                print " ";
                print $spot->getSun_West_Limb;

                print "\n";
            }
        }
    }
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
