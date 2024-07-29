#!/usr/bin/perl

use strict;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
#use sunspot_and_faculae;
use sunspot_roundephem;
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
    exit;
}

my %opts = ();
getopts("f:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
#print $opts{f};
#%sunspots = &Load_Sunspot_SpotCentric($opts{f});
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
#&printDateCentricSpots();
&printSpotCentricSpots();
#print "\n";

sub printSpotCentricSpots {
    my $count = 0;
    my $total = 0;
    my $radiidiff = 0;
    my $anglediff = 0;
    my $bothdiff = 0;
    my %anglediff = ();
    my %radiidiff = ();
    my %spotdiff = ();
    my %histogram = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $prevLongitude = undef;
        #print "spot number = $spotNumber\n";
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($prevLongitude)) {
                    $prevLongitude = $spot->getCarringtonLongitude;
                }
                else {
                    my $longDiff = $prevLongitude - $spot->getCarringtonLongitude;
                    if ($longDiff > 180.0) {
                        $longDiff -= 360.0;
                    }
                    if ($longDiff < -180.0) {
                        $longDiff += 360.0;
                    }
                    my $bin = sprintf("%.1f", $longDiff);
                    #print "difference = $bin, " . ($longDiff);
                    #print "\n";
                    if (!defined($histogram{$bin})) {
                        $histogram{$bin} = 0;
                    }
                    $histogram{$bin}++;

                }
                $prevLongitude = $spot->getCarringtonLongitude;
            }
        }
    }
    foreach my $bin (sort keys %histogram) {
        print $bin;
        print " ";
        print $histogram{$bin};
        print "\n";
    }
    #print Dumper %histogram;
    
}
sub printDateCentricSpots {
    my $count = 0;
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                #my $thisSpotDateTime = $spot->getDateTime;
                #print $spot->getDateTime;
                #print " ";
                #print $spot->getGroupNumber;
                #print " ";
                #print $spot->getCorrectedWholeSpotArea;
                #print " ";
                #print $spot->getCorrectedUmbralArea;
                #print " ";
                #print $spot->getSun_East_Limb;
                #print " ";
                #print $spot->getSun_West_Limb;

                #print "\n";
                #print $spot->raw_string;
                #print $spot->getOrigionalGreenwichFormat;
                $spot->calculateHelioprojective;
                #print $spot->getCalculatedGreenwichFormat;
                if ($spot->getCalculatedGreenwichFormat ne $spot->getOrigionalGreenwichFormat) {
                    $count++;
                }

            }
        }
    }
    return $count;
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

