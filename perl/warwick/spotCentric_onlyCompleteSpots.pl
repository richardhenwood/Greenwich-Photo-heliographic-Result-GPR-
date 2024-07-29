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

sub usage {
    print STDERR << "EOF";
This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

Specifically: This is program selects only spots who's life is completly 
observed in the dataset.


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
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
&find_unique_sunspots();

sub find_unique_sunspots {
    my $spotSize; 
    my @maxSpotSizes = ();
    my %WholeSpotLongitudeBins = ();
    my %UmbralLongitudeBins = ();
    my $binSize = 5;
    my $minLongitude = -65;
    my $maxLongitude = 65;
    my %maxAreaBins = ();
    my @wholeLifeSpots = ();
    my @partLifeSpots = ();
    my $totalSpots = 0;
    foreach my $spotNumber (keys (%sunspots)) {
        my @spotSizes = ();
        my @umbralSizes = ();
        my $longevity = 0;
        my @spotArray = ();
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                push (@spotArray, $spot);
                my $wholespotSize = $spot->getProjectedWholeSpotArea;
                my $umbralSize = $spot->getCorrectedUmbralArea;
                push(@spotSizes, $wholespotSize);
                push(@umbralSizes, $umbralSize);
            }
            $longevity++;
        }
# now select out the sunspots which we can see their whole
# existance.
        my $maxSpotSize = (sort numeric @spotSizes)[-1];
        if ($spotArray[0]->getCentralMeridianDistance > $minLongitude 
            && $spotArray[-1]->getCentralMeridianDistance < $maxLongitude 
            && scalar @spotArray <= 9 ) {
            #print "number = $spotNumber "; 
            push(@wholeLifeSpots, $spotNumber);
            foreach my $spot (@spotArray) {
                #   print " size = " . $spot->getProjectedWholeSpotArea;
                #print " position = " . $spot->getCentralMeridianDistance;
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    #   print " bin = $bin ";
                            $WholeSpotLongitudeBins{$bin}++;
                }
                #print "\n";
            }
        }
        else {
            push (@partLifeSpots, $spotNumber);
            foreach my $spot (@spotArray) {
                #   print " size = " . $spot->getProjectedWholeSpotArea;
                #print " position = " . $spot->getCentralMeridianDistance;
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    #   print " bin = $bin ";
                    $WholeSpotLongitudeBins{$bin}++;
                }
                #print "\n";
            }
        }
        $totalSpots++;
    }
    #foreach my $partSpot (@partLifeSpots) {
        
    foreach my $spotNumber (@wholeLifeSpots) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                print $spot->raw_string;
            }
        }
    }
    #print "totalSpots = $totalSpots \n";
    #$totalSpots = scalar @wholeLifeSpots + scalar @partLifeSpots;
    #print "totalSpots = $totalSpots \n";
    #foreach my $binName (sort numeric keys %WholeSpotLongitudeBins) {
    #    print "longitude = $binName frequency = " . $WholeSpotLongitudeBins{$binName} . "\n";
#        print Dumper %maxAreaBins;
    #}
}


    
# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot_and_Faculae_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

# this code is very similar to the code which shares a similar name,
# but is loads the sunspot data with the sunspot number as the key.
sub Load_Sunspot_and_Faculae_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
        }
    }
    return %sunspot_array;
}

sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
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
    return %sunspot_array;
}


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

