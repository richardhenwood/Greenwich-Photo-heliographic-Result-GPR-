#!/usr/bin/perl

use strict;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
use sunspot_and_faculae;
use sunspot;


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-h      : file containing hour data.


example: $0 -h ~/warwick/papers/asym/data/lifetime_distn.txt -f ~/ihr/data/greenwich/1928.grn
EOF
    exit;
}

my %opts = ();
getopts("f:h:", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{h})) { usage(); }


my @spotnumbers = &get_spot_numbers($opts{h});
my %sunspots = &Load_Sunspot_SpotCentric($opts{f});

#print Dumper @spotnumbers;

foreach my $spotNo (sort numeric @spotnumbers) {
    my @profile = &get_profile(\%sunspots, $spotNo);
    
    print "\n\n";
    #print Dumper @profile;
}


sub get_profile {
    my ($spotsref, $spotNo) = @_;
    my %sunspots = %{$spotsref};
    my %profile;
    my $initialTime;
    my $endTime;
    my $maxSize = 0;
    foreach my $obsTime (sort keys %{$sunspots{$spotNo}}) {
        if (!defined($initialTime)) {
            $initialTime = substr($obsTime, 0, 10);
        }
        $endTime = substr($obsTime, 0, 10);
        # print "time = $obsTime\n";
        foreach my $spot (@{$sunspots{$spotNo}{$obsTime}}) {
            my $size = $spot->getCorrectedWholeSpotArea;
            $profile{substr($obsTime, 0, 10)} = $size;
            if ($size > $maxSize) {
                $maxSize = $size;
            }
        }
    }
    #print "begin $initialTime end $endTime\n";
    #print Dumper %profile;

    my $currentTime = $initialTime;
    my $obs = 0;
    my @profile = ();
    while ($currentTime ne $endTime) {
        if (!defined($profile{$currentTime})) {
            $profile{$currentTime} = '-';
        }

        #print "current time = $currentTime ";
        #print " obs = $obs ";
        #print $profile{$currentTime};
        #print "\n";
        push (@profile, $profile{$currentTime});
        my @currentTime = split(/-/, $currentTime);
        my @newdate = Add_Delta_Days(@currentTime, 1);
        $currentTime = sprintf("%04d-%02d-%02d", @newdate);
        $obs++;
    }

    my $totalObs = $obs;
    $obs = 0;
    foreach my $size (@profile) {
        if ($size ne '-') {
            print "obs = ";
            print $obs/$totalObs;
            print " ";
            print $size/$maxSize;
            print "\n";
        }
        else {
            print "obs = ";
            print $obs/$totalObs;
            print " -";
            print "\n";
        }
        $obs++;
    }
    
}
                                                                                               
sub get_spot_numbers {
    my $filename = shift;
    open (FH, $filename);
    my @spotnumbers = ();
    while (defined (my $line = <FH>)) {
        chomp($line);
        my @bits = split(/ /, $line);
        if ($bits[2] > 500.0 && $bits[2] < 750.0) {
            $bits[3] =~ s/[\(\)\#]//g;
            push (@spotnumbers, $bits[3]);
        }
        #last;
    }

    return @spotnumbers;
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

