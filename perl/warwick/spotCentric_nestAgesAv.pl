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

This code applies an averaging window over sunspot data

usage: $0 -f file -d days

-f      : file containing data, in Greenwich format.
-d #    : width of the averaging window in days
-i
-s      : perform average with resspect to number of sunspots, not time
-l      : when more than one sunspot exists for a given day, use the oldest.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -d 8025 
EOF
    exit;
}
my %opts = ();
getopts("f:d:i:sl", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{d})) { usage(); }
my $avWindow = $opts{d};
my $AVWRTSUNSPOTS = 0;
if (defined($opts{s})) { $AVWRTSUNSPOTS = 1; }
my $JUSTTHEOLDEST = 0;
if (defined($opts{l})) { $JUSTTHEOLDEST = 1; }
my $stride = 1;
if (defined($opts{i})) { $stride = $opts{i}; }


my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
my %allDates = &genAllDates();
#print Dumper %allDates;

my %lifetimeAtBirth = &getSpotAgesAtBirth(\%allDates);
#print Dumper %lifetimeAtBirth;

&performAv(\%lifetimeAtBirth);

sub performAv {
    my $allDatesRef = shift;
    my @start = (1874, 5, 9);
    my @end = (1976, 12, 31);
    my %dateAges = %{$allDatesRef};
    my @windowLow = @start;
    my @windowHigh = Add_Delta_Days(@start, $avWindow);
    my $count = 0;
    #my @currentDate = Add_Delta_Days(@start, $avWindow/2);
    while (Delta_Days(@windowHigh, @end)) {
        my $loLifetimes = 0;
        my $avLifetimes = 0;
        my $highLifetimes = 0;
        my $sunspotCount = 0;
        my @currentDate = @windowLow;
        while (Delta_Days(@currentDate, @windowHigh)) {
            my $currentdateStr = sprintf("%4d-%02d-%02d", @currentDate);
            #    print "currentdate = $currentdateStr\n";
            if (defined($dateAges{$currentdateStr})) {
                foreach my $date (@{$dateAges{$currentdateStr}}) {
                    my @dates = @{$date};
                    #    printf ("low %d av %d high %d\n", @dates);
                    #print "date = " + join (',', @dates );
                    $loLifetimes += $dates[0]; 
                    $avLifetimes += $dates[1]; 
                    $highLifetimes += $dates[2]; 
                    $sunspotCount++;
                }
                #print "\n";
            }
            @currentDate = Add_Delta_Days(@currentDate, 1);
        }
        if (!$AVWRTSUNSPOTS || !$sunspotCount) {
            $sunspotCount = $avWindow; 
        }
        if (!($count % $stride)) {
            printf("low = %4d-%02d-%02d ", @windowLow);
            printf("high = %4d-%02d-%02d ", @windowHigh);
            printf("date = %4d-%02d-%02d ", Add_Delta_Days(@currentDate, -$avWindow/2));
            printf(" loav = %5f", $loLifetimes/$sunspotCount);
            printf(" av = %5f", $avLifetimes/$sunspotCount);
            printf(" highav = %5f", $highLifetimes/$sunspotCount);
            #printf(
            print "\n";
        }

        @windowLow = Add_Delta_Days(@windowLow, 1);
        @windowHigh = Add_Delta_Days(@windowHigh, 1);

        $count++;
    }
}


sub genAllDates {   
    my @start = (1874, 5, 9);
    my @end = (1976, 12, 31);
    my %allDates;
    my @currentDate = @start;
    while (Delta_Days(@currentDate, @end)) {
        my $currentDateStr = sprintf("%4d-%02d-%02d", @currentDate);
#        print "current date = $currentDateStr\n";
        $allDates{$currentDateStr} = ();
        @currentDate = Add_Delta_Days(@currentDate, 1);
    }
    return %allDates;
}


sub getSpotAgesAtBirth {
    my $allDatesRef = shift;
    my %dateAges = %{$allDatesRef};
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
            my @highPossibleAge = Delta_DHMS(@possibleBirth, @possibleDeath);

            #print " birth: " . $birth[0] . "-" . $birth[1] . "-" . $birth[2] . " " . $birth[3] . ":" . $birth[4];
            #print " possibleBirth: ". $possibleBirth[0] . "-" . $possibleBirth[1] . "-" . $possibleBirth[2] . " " . $possibleBirth[3] . ":" . $possibleBirth[4];

            #print " ageav = " . ($ageDHMS[0] + $highPossibleAge[0])/2;
            #print " lowpossible = " . $ageDHMS[0];
            #print " highpossible = " . $highPossibleAge[0];
            #print "\n";

            my $birthdayStr = sprintf("%4d-%02d-%02d", @birth[0 .. 2]);
            my $averageAge = ($ageDHMS[0] + $highPossibleAge[0])/2;
            my $lowAge = $ageDHMS[0];
            my $highAge = $highPossibleAge[0];
            my @agesArr = ($lowAge, $averageAge, $highAge);
            if ($JUSTTHEOLDEST) {
                if (&isOlder($dateAges{$birthdayStr}, $highAge)) {
                    #$dateAges{$birthdayStr} = \@agesArr;
                    #print "older!\n";
                    shift (@{$dateAges{$birthdayStr}});
                    push (@{$dateAges{$birthdayStr}}, \@agesArr);
                }
            }
            else {
                push (@{$dateAges{$birthdayStr}}, \@agesArr);
            }
            #print Dumper @{$dateAges{$birthdayStr}};
        }
    }
    return %dateAges
}


sub isOlder {
    my ($arrRef, $testAge) = @_;
    if (defined($arrRef)) {
        my @ages = @{$arrRef};
        #print Dumper $ages[0];
        #print $ages[0][0];
        if ($ages[0][2] < $testAge) {
            return 1;
        }
        else {
            #print $ages[2] . " < ";
            #print "test age $testAge is younger!\n";
            return 0;
        }
    }
    return 1;
    #print "hello";
    #exit;
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

