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

usage: $0 -f file -c [degree threshold]

-f      : file containing data, in Greenwich format.
-c      : threshold for spot clumping. i.e. number of spots which are closer than -c degrees

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -c 30
EOF
    exit;
}

my %opts = ();
getopts("f:c:", \%opts) ;
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
#print $opts{f};
#%sunspots = &Load_Sunspot_SpotCentric($opts{f});
#%sunspots = &Load_Sunspot_DateCentric($opts{f});
%sunspots = &Load_Sunspot_CarringtonCentric($opts{f});
#%sunspots = &Load_Sunspot_DateCentric($opts{f});
    

&printClumpedSpots();

#&printSpotCentricSpots();
#&printDateCentricSpots();

sub printClumpedSpots {
    my %carringtonDifferences = ();
    my $previousCTime = undef;
    foreach my $carringtonTime (sort keys (%sunspots)) {
        $carringtonDifferences{$carringtonTime} = 0;
        #print "carrington Time = $carringtonTime $previousCTime\n";
        foreach my $spotNumber (sort keys %{$sunspots{$carringtonTime}}) {
            my $outputStr = undef; 
            foreach my $spot (@{$sunspots{$carringtonTime}{$spotNumber}}) {
                if (0) {
                    $outputStr .= $carringtonTime . " ";
                    $outputStr .= $previousCTime . " ";
                    $outputStr .= $spot->getGroupNumber . " ";
                    $outputStr .= $spot->getCarringtonRotationNumber . " ";
                    $outputStr .= $spot->getLongitude . " ";
                    $outputStr .= $spot->getDateTime . "\n ";
                    $outputStr .= $spot->raw_string;
                }
                if (defined($previousCTime)) {
                    $carringtonDifferences{$previousCTime} = $carringtonTime - $previousCTime;
                }
            }
            print "$outputStr\n";
        }
        $previousCTime = $carringtonTime;
    }
    #print Dumper %carringtonDifferences;
    foreach my $carringtonTime (sort keys %carringtonDifferences) {
        print " $carringtonTime " ;
        print $carringtonDifferences{$carringtonTime};
        print "\n";
    }
=begin
    foreach my $obsTime (sort keys (%sunspots)) {
        my @carringtonLongitudes = ();
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            my $outputStr = undef; 
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                #if (!defined($outputStr)) {
                    my $carringtonNo = $spot->getCarringtonRotationNumber;
                    my $carringtonIndex = $carringtonNo + ((360 - $spot->getCarringtonLongitude)/360);
                    push(@carringtonLongitudes, $carringtonIndex);
                    
                    $outputStr .= $obsTime . " ";
                    $outputStr .= $spot->getGroupNumber . " ";
                    $outputStr .= $carringtonIndex . " ";
                    $outputStr .= $spot->getLongitude . " ";
                    $outputStr .= $spot->getDateTime . "\n";
                    $outputStr .= $spot->raw_string;
                    #}
            }
            print "$outputStr\n";
        }
        print "obstime = $obsTime\n";
        print Dumper @carringtonLongitudes;
    }
=cut    
}

sub printSpotCentricSpots {
    my %sunspotStart = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $outputStr = undef; 
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($outputStr)) {
                    $outputStr .= $spot->getGroupNumber . " ";
                    $outputStr .= $spot->getCarringtonRotationNumber . " ";
                    $outputStr .= $spot->getLongitude . " ";
                    my $alexisSpecialDatetimeFormat = $spot->getDateTime;
                    $alexisSpecialDatetimeFormat =~ s/[-:]/ /g;
                    $outputStr .= $alexisSpecialDatetimeFormat . " ";
                    $sunspotStart{$spot->getDateTime} .= $outputStr . "\n";;
                }
            }
        }
    }
    foreach my $date (sort keys (%sunspotStart)) {
        print $sunspotStart{$date};
    }
}


sub printDateCentricSpots {
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            my $outputStr = undef; 
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                if (!defined($outputStr)) {
                    $outputStr .= $spot->getGroupNumber . " ";
                    $outputStr .= $spot->getCarringtonRotationNumber . " ";
                    $outputStr .= $spot->getLongitude . " ";
                    $outputStr .= $spot->getDateTime . " ";
                }
            }
            print "$outputStr\n";
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

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
sub Load_Sunspot_CarringtonCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            my $carringtonNo = $test_spot->getCarringtonRotationNumber;
            my $carringtonIndex = $carringtonNo + ((360 - $test_spot->getCarringtonLongitude)/360);
            push(@{$sunspot_array{$carringtonIndex}{$test_spot->getGroupNumber()}}, $test_spot);
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

