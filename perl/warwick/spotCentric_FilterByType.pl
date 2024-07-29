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

This filters spots which stray outside CMD limits.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-t #    : return spots of type # (1 = single)

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -t 1
EOF
    exit;
}

my %opts = ();
getopts("f:t:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $classificationType;
if (!defined($opts{t})) { usage(); }
$classificationType = $opts{t};

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my @allObserved = ();
    my @onlySomeObserved = ();
    my $minCMD = -60;
    my $maxCMD = 60;
    my %greenwichTypeHash = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $timeAtMax = 0;
        my $maxSize = 0;
        my $maxCMD = undef;
        my $greenwichType = 10;
        my @greenwichTypeArray = ();
        my @birth = ();
        my @death = ();
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            #if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            #@death = split(/[- :]/, $obsTime);
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #if (!$useCalculated) {
                #    if ($spot->getCorrectedWholeSpotArea > $maxSize) {
                #        $maxSize = $spot->getCorrectedWholeSpotArea;
                #        $timeAtMax = $obsTime;
                #        $maxCMD = $spot->getCentralMeridianDistance;
                #    }
                #}
                #else {
                #    if ($spot->getCalculatedCorrectedWholeSpotArea > $maxSize) {
                #        $maxSize = $spot->getCalculatedCorrectedWholeSpotArea;
                #        $timeAtMax = $obsTime;
                #        $maxCMD = $spot->getCentralMeridianDistance;
                #    }
                #}
                push(@greenwichTypeArray, $spot->getGroupType);
            }
        }
        $greenwichType = &mostPopular(\@greenwichTypeArray);
        if ($greenwichType == $classificationType) { 
            $greenwichTypeHash{$spotNumber} = $greenwichType;
            #print "spotNumber = $spotNumber popular type = $greenwichType\n";
        }
    }
    foreach my $spotNumber (sort numeric keys (%greenwichTypeHash)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            #if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            #@death = split(/[- :]/, $obsTime);
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                print $spot->raw_string;
            }
        }
    }
}


sub mostPopular {
    my $arrayRef = shift;
    my @array = @{$arrayRef};
    my %count;
    for (@array) {
        $count{$_}++;

    }

    my $biggest = 0;
    for (sort keys %count) {
        #if (defined($count{$_}) ) {
        if ($count{$biggest}<$count{$_}) {
            $biggest=$_;
        }
        #}
    }
    #  print join ',', @array;
    #  print $biggest;
    #  print "\n";
    return $biggest;


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

