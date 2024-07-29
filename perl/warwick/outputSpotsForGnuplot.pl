#!/usr/bin/perl

use strict;
use lib '../../';
use lib '../';
use lib '../../external_libs/';
use lib '../external_libs/';
use lib '/users/rhenwood/ihr/sunspots/perl/external_libs/';
use lib '/users/rhenwood/ihr/sunspots/perl/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use sunspot_and_faculae;
use sunspot;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;

# This code attempts to detect reoccurance. It starts by 
# disposeing of the spots who's life is completly 
# observed in the dataset.
#

sub usage {
    print <<END;
call this code with a greenwich data file: -f <filename>
    
END
exit(0);
}

# source of faculae data
my %opts = ();
my $sunspots_filename = "";
getopts('f:', \%opts);
if (!defined($opts{'f'})) { &usage(); }
else { $sunspots_filename = $opts{'f'}; }

my %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
&outputForGnuplot(\%sunspots);
#&find_unique_sunspots();

sub outputForGnuplot {
    my $sunspotRef = shift;
    my %sunspotHash = %{$sunspotRef};

    my $dataStr = "";
    my $labelStr = "";
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $dateTime = "";
        my $carringLong = "";
        my $cWSarea = "";
        my $latitude = "";
        my $madeAdjustment = 0;
        my $previousLong = 0;
        my $nearEdge = 0;
        my $adjustment = 0;
        my $numberOfSpots = scalar (keys %{$sunspots{$spotNumber}});
        #print "number of spots = $numberOfSpots\n";
        if ($numberOfSpots > 5 && $numberOfSpots < 9) {
            foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
                foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                    $dateTime = $spot->getDateTime();
                    $carringLong = $spot->getCarringtonLongitude();
                    $cWSarea = $spot->getCorrectedWholeSpotArea();
                    $latitude = $spot->getLatitude();
                    $dataStr .= "$spotNumber ";
                    # check that the longitude isn't looping overaround 0 or 360  deg.
                    if (abs($previousLong - $carringLong) > 340 && $numberOfSpots > 1 ) { 
                        if ($previousLong > 340) {
                            $nearEdge = 360;
                        }
                        else {
                            $nearEdge = -360;
                        }


                        if ($previousLong < 30) {
                            $adjustment = -360;
                        }
                        elsif ($previousLong > 330) {
                            $adjustment = 360;
                        }
                        else {
                            die ("trying to adjust for near 360 deg and failed. quitting.");
                        }
                        $madeAdjustment = 1;
                        $previousLong = $carringLong + $nearEdge;    
                    }
                    else {
                        $previousLong = $carringLong; 
                    }
                    $dataStr .= sprintf("%s %5.1f  %3d %5.1f (nearedge  = $nearEdge) %5.1f", $dateTime, $previousLong, $cWSarea, $latitude, $carringLong);
                    $dataStr .= "\n";
                }
            }
            $dataStr .= "\n\n";
            $labelStr .= "$spotNumber $dateTime $previousLong $cWSarea $latitude\n";  
        }
    }
    print "$labelStr \n\n";
    print $dataStr;
    
    #print Dumper %sunspotHash;
}

sub find_unique_sunspots {
    my $spotSize; 
    my @maxSpotSizes = ();
    my %WholeSpotLongitudeBins = ();
    my %UmbralLongitudeBins = ();
    my $binSize = 5;
    my $minLongitude = -60;
    my $maxLongitude = 60;
    my %maxAreaBins = ();
    my @wholeLifeSpots = ();
    my %partLifeSpots = ();
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
            }
        }
# but in this program, we are interested in the spots which remain
# after all the 'whole lifetime' spots have been removed.
        else {
            foreach my $spot (@spotArray) {
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    $WholeSpotLongitudeBins{$bin}++;
                }
                push(@{$partLifeSpots{$spot->getGroupNumber()}}, $spot->getDateTime() . " " . $spot->getCarringtonLongitude() . " " . $spot->getCorrectedWholeSpotArea() . " " . $spot->getLatitude());
            }
        }
        $totalSpots++;
    }
    if (1) {
        my $dataStr = "";
        my $labelStr = "";
        foreach my $spotNumber (sort numeric keys %partLifeSpots) {
            my $previousLong = 0;
            my $nearEdge = 0;
            my $adjustment = 0;
            my $madeAdjustment = 0;
            foreach my $spot (@{$partLifeSpots{$spotNumber}}) {
                $dataStr .= "$spotNumber ";
                my @spotData = split(/ +/, $spot);
                # check that the longitude isn't looping overaround 0 or 360  deg.
                if (abs($previousLong - $spotData[2]) > 340 && scalar @{$partLifeSpots{$spotNumber}} > 1 ) { 
                    if ($previousLong > 340) {
                        $nearEdge = 360;
                    }
                    else {
                        $nearEdge = -360;
                    }


                    if ($previousLong < 30) {
                        $adjustment = -360;
                    }
                    elsif ($previousLong > 330) {
                        $adjustment = 360;
                    }
                    else {
                        die ("trying to adjust for near 360 deg and failed. quitting.");
                    }
                    $madeAdjustment = 1;
                    $previousLong = $spotData[2] + $nearEdge;    
                }
                else {
                    $previousLong = $spotData[2]; 
                }
                $dataStr .= sprintf("%s %s %5.1f  %3d %5.1f (nearedge  = $nearEdge) %5.1f", $spotData[0], $spotData[1], $previousLong, $spotData[3], $spotData[4], $spotData[2]);
                $dataStr .= "\n";
            }
            $dataStr .= "\n\n";
            $labelStr .= "$spotNumber " . ${$partLifeSpots{$spotNumber}}[0] . "\n";
            
        }
        print $labelStr . "\n\n";
        print $dataStr;
    }
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

