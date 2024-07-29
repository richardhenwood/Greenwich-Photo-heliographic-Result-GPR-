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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Add_Delta_DHMS Delta_Days);
use List::Util qw(sum max);
use Getopt::Std;

# we check some of the extream events - for example - what is the largest change in latitude a spot make during it's life?
sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

This code calculates the age of sunspot nests - or just sunspots if there are no nests.

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
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my @latitudeDelta = ();
    my @longitudeDelta = ();
    my %averageAge = ();
    my %avAge;
    my %highAge;
    my %lowAge;
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $minLatitude = 90;
        my $maxLatitude = -90;
        my $minCarringtonLongitude = 360;
        my $maxCarringtonLongitude = 0;
        my $cycleNumber;
        my @birth = ();
        my @death = ();
        my $latitudeDeviation = undef;
        my $initialLatitude = undef;
        my $longitudeDeviation = undef;
        my $initialLongitude = undef;
        my $firstCMD = undef;
        my $lastCMD = undef;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($firstCMD)) { $firstCMD = $spot->getCentralMeridianDistance; }
                $lastCMD = $spot->getCentralMeridianDistance;
            }
            @death = split(/[- :]/, $obsTime);
        }
        my @ageDHMS = Delta_DHMS(@birth, 0, @death, 0);
        if ($ageDHMS[0] > 0) {
            my $uncertainBirth = 0;
            my $uncertainDeath = 0;
            #print "spotNumber: $spotNumber ";
            if ($firstCMD < -60) {
                $uncertainBirth = 1;
            }
            if ($lastCMD > 60) {
                $uncertainDeath = 1;
            }

            my @possibleBirth = (@birth, 0);
            if ($uncertainBirth) { @possibleBirth = Add_Delta_DHMS(@birth, 0, -20, 0, 0, 0); }
            my @possibleDeath = (@death, 0);
            if ($uncertainDeath) { @possibleDeath = Add_Delta_DHMS(@death, 0, 20, 0, 0, 0); }
            #my @lowPossibleAge = Delta_DHMS(@possibleBirth, @possibleDeath);
            my @highPossibleAge = Delta_DHMS(@possibleBirth, @possibleDeath);


            #print " birth: " . $birth[0] . "-" . $birth[1] . "-" . $birth[2] . " " . $birth[3] . ":" . $birth[4];
            #print " possibleBirth: ". $possibleBirth[0] . "-" . $possibleBirth[1] . "-" . $possibleBirth[2] . " " . $possibleBirth[3] . ":" . $possibleBirth[4];

            my $tmpAge = ($ageDHMS[0] + $highPossibleAge[0])/2;
            #print " ageav = " . $tmpAge; #($ageDHMS[0] + $highPossibleAge[0])/2;
            #print " lowpossible = " . $ageDHMS[0];
            #print " highpossible = " . $highPossibleAge[0];
            #print "\n";
            if (!defined{$avAge{$tmpAge}}) {
                $avAge{$tmpAge} = 0;
            }
            if (!defined{$highAge{$highPossibleAge[0]}}) {
                $highAge{$highPossibleAge[0]} = 0;
            }
            if (!defined{$lowAge{$ageDHMS[0]}}) {
                $lowAge{$ageDHMS[0]} = 0;
            }
            $avAge{$tmpAge}++;
            $highAge{$highPossibleAge[0]}++;
            $lowAge{$ageDHMS[0]}++;

            push (@latitudeDelta, ($maxLatitude - $minLatitude));
            push (@longitudeDelta, ($maxCarringtonLongitude - $minCarringtonLongitude));
            push (@{$averageAge{$birth[0] . "-" . $birth[1] . "-" . $birth[2]}}, $ageDHMS[0]);
        }
    }
    #print Dumper %avAge;
    #foreach my $age (sort { $a <=> $b}  keys %lowAge) {
    #    print $age;
    #    print " ";
    #    print $lowAge{$age};
    #    print "\n";
    #}
    #foreach my $age (sort { $a <=> $b}  keys %avAge) {
    #    print $age;
    #    print " ";
    #    print $avAge{$age};
    #    print "\n";
    #}
    foreach my $age (sort { $a <=> $b}  keys %highAge) {
        print $age;
        print " ";
        print $highAge{$age};
        print "\n";
    }
#    print "max = " . max(@latitudeDelta) . "\n"; 
#    print "max = " . max(@longitudeDelta) . "\n"; 
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

