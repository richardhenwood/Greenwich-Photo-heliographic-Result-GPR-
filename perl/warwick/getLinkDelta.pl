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
-l      : file containing a list of links: # -> #

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -l ./links.txt
EOF
    exit;
}

my %opts = ();
getopts("f:l:", \%opts) ;
if (!defined($opts{f}) || !defined($opts{l})) { usage(); }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
my %links = &Load_Links($opts{l});
#print Dumper $sunspots{'13666'};
#exit (0);
#&printSpotCentricSpots();

while (my ($first, $last) = each (%links)) {
    my @times = (sort keys %{$sunspots{$first}});
    if (!defined(${$sunspots{$first}{$times[-1]}}[0])) {
        die "spot problem with first: $first, $last\n";
    }
    my $firstspot = ${$sunspots{$first}{$times[-1]}}[0];
    @times = (sort keys %{$sunspots{"$last"}});
    #print "last = '$last'\n";
    #@times = (sort keys %{$sunspots{$last .""}});
    #@times = (sort keys %{$sunspots{"13681"}});
    #print "times = ";
    #print Dumper @times;
    #print "\n";
    #print " time " . $times[-1];
    #print "\n";
    #print "times = " .Dumper $sunspots{$last}{$times[-1].''};
    #print "\n";


    #print "$first:$last ";
    if (!defined(${$sunspots{$last}{$times[-1]}}[0])) {
        #print Dumper $sunspots{$last};
        die "spot problem with last: $first, $last\n";
    }

    my $lastspot = ${$sunspots{$last}{$times[0]}}[0];

    my @lasttime = split('[- :]',$firstspot->getDateTime);
    my @firsttime = split('[- :]',$lastspot->getDateTime);
    my @timediff = Delta_DHMS(@lasttime, 00, @firsttime, 00);
    my $deltatime = ($timediff[0]*24+$timediff[1])/24;
    my $result = "inside ";
    if ($deltatime > 19.5) {
        $result = "outside ";
    }

    my $deltalatitude = abs($lastspot->getLatitude - $firstspot->getLatitude);
    if ($deltalatitude > 8.5) {
        $result = "outside ";
    }
    my $deltaLongitude = abs($lastspot->getCarringtonLongitude - $firstspot->getCarringtonLongitude);

    print "$result $first -> $last ";
    print " Dtime $deltatime";
    print " Dlatit $deltalatitude";
    print " Dlong $deltaLongitude";
    print "\n";
}

sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                print $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print "\n";
            }
        }
    }
}

sub Load_Links {
    my $filename = shift;
    my %spotLinks = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        chomp $line;
        $line =~ s/\s+//g;
        my @links = split (/->/, $line);
        $spotLinks{$links[0]} = $links[1];
        #foreach my $spot (sort numeric @links) {
        #    print $spot;
        #    print "\n";
        #}
        #print "\n";
    }
    return %spotLinks;
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
                push(@{$sunspot_array{$test_spot->getGroupNumberAugmented()}{$test_spot->getDateTime}},
                $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
            }
            #print $test_spot->getGroupNumberAugmented();
            #print $test_spot->getDateTime();
            #print "\n";
        }
    }
    #print Dumper keys %{$sunspot_array{'13681'}};
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
            push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumberAugmented()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

#sub printDateCentricSpots {
#    foreach my $obsTime (sort keys (%sunspots)) {
#        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
#            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
#                print $spot->getDateTime;
#                my $thisSpotDateTime = $spot->getDateTime;
#                print " ";
#                print $spot->getGroupNumber;
#                print " ";
#                print $spot->getCorrectedWholeSpotArea;
#                print " ";
#                print $spot->getCorrectedUmbralArea;
#                print " ";
#                print $spot->getSun_East_Limb;
#                print " ";
#                print $spot->getSun_West_Limb;
#
#                print "\n";
#            }
#        }
#    }
#}
                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

