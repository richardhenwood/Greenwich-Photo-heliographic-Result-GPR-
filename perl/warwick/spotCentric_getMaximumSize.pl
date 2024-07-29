#!/usr/bin/perl

use strict;
#use lib '../external_libs/';
#use lib '../';
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use lib '/users/rhenwood/ihr/sunspots/perl/';
#use Statistics::Basic::Mean;
#use Statistics::Basic::StdDev;
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

It returns the maximum size each sunspot achievies within it's lifetime.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
[-a #]  : return only spots of given age, in consecutive observations

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("a:f:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $age = $opts{a};

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $maxSize = 0;
        my $currentSize = 0;
        my $obsPerSpot = -1;
        #print "spotnumber: $spotNumber\n";
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if(0) {
                    print $spot->getDateTime;
                    print " ";
                    print $spot->getGroupNumber;
                    print " ";
                    print $spot->getCorrectedWholeSpotArea;
                    print " ";
                    print $spot->getCorrectedUmbralArea;
                    print "\n";
                }
                $currentSize = $spot->getCorrectedWholeSpotArea;
            }
            if ($maxSize < $currentSize) {
                $maxSize = $currentSize;
            }
            $obsPerSpot++;
        }
        if ($obsPerSpot) {
            if (defined($age)) {
                if($obsPerSpot == $age) {
                    print "$maxSize\n";
                }
            } else {

                print " $maxSize\n";
            }
        }
    }
}

# this subroutine loads greenwich data into a hash with the spot number as the key.
sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    my @inData = ();
    #print "filename = '$filename'\n";
    if ($filename eq '-') {
        @inData = <STDIN>;
    } else {
        open (FH, $filename);
        @inData = <FH>;
    }
    foreach my $line (@inData) {
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

