#!/usr/bin/perl

use strict;
use lib '../../';
use lib '../';
use lib '../../external_libs/';
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use sunspot_and_faculae;
use sunspot;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum max);
use Getopt::Std;

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
getopts("f:", \%opts);
if (!defined($opts{f})) { usage(); }

my %sunspots = ();
%sunspots = &Load_Sunspot_SpotCentric($opts{f});

    
# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

sub find_unique_sunspots {
    my $spotSize; 
    my @maxSpotSizes = ();
    my %WholeSpotLongitudeBins = ();
    my %WholeSpotMaxSizeBins = ();
    my %UmbralLongitudeBins = ();
    my $binSize = 5;
    my $minLongitude = -60;
    my $maxLongitude = 60;
    my %maxAreaBins = ();
    my @wholeLifeSpots = ();
    my %partLifeSpots = ();
    my $totalSpots = 0;
    my $totalWholeSpots = 0;
    my @sizeArray = ();
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
                push(@maxSpotSizes, $wholespotSize);
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
            $WholeSpotMaxSizeBins{$maxSpotSize}++;
            push(@sizeArray, $maxSpotSize);
            foreach my $spot (@spotArray) {
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    $WholeSpotLongitudeBins{$bin}++;
                }
            }
        }
# but in this program, we are interested in the spots which remain
# after all the 'whole lifetime' spots have been removed.
        else {
            if ($maxSpotSize == 0) {print "spotnumber =$spotNumber\n";}
            push(@wholeLifeSpots, $spotNumber);
            $WholeSpotMaxSizeBins{$maxSpotSize}++;
            push(@sizeArray, $maxSpotSize);
            if (0) {
            #push (@partLifeSpots, $spotNumber);
            foreach my $spot (@spotArray) {
                #   print " size = " . $spot->getProjectedWholeSpotArea;
                #print " position = " . $spot->getCentralMeridianDistance;
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    #   print " bin = $bin ";
                    $WholeSpotLongitudeBins{$bin}++;
                }
                #print "\n";
                push(@{$partLifeSpots{$spot->getGroupNumber()}}, $spot->getDateTime() . " " . $spot->getCarringtonLongitude() . " " . $spot->getCorrectedWholeSpotArea() . " " . $spot->getLatitude());
            }
            }
        }
        
        $totalSpots++;
    }
    # now do the post processing...
    if (0) {
        my $maxWholeSpotSize = max @maxSpotSizes;
        print "max whole spot = $maxWholeSpotSize\n";
    }
    if (0) {
        foreach my $lifeSpotNumber (sort numeric @wholeLifeSpots) {
            print $lifeSpotNumber;
            print "\n";
        }
    }
    # log bin the data.
    my %spotLifeLogBins = ();
    if (1) {
        my $range = (sort numeric keys %WholeSpotMaxSizeBins)[-1];
        my $numberOfBins = 100;
        my @logSizeArray = ();
        my @logBinValues = ();
        foreach my $binName (sort numeric keys %WholeSpotMaxSizeBins) {
            # old method
            #my $bin = $range * $numberOfBins**((floor($numberOfBins * (log($binName)/log($range))))/$numberOfBins)/$numberOfBins;
            # new method
            my $xNormF = floor(&logN($binName,$range) * $numberOfBins);
            my $bin = $range**($xNormF / $numberOfBins);
                                  
            $spotLifeLogBins{$bin}++;
            #print "bin = $bin, binname = $binName \n";
        }
        my $totalInBins = 0;
        foreach my $binName (sort numeric keys %spotLifeLogBins) {
            $totalInBins += $spotLifeLogBins{$binName};
            push (@logBinValues, ($binName) x $spotLifeLogBins{$binName});

        }
        my $totalNormalised = 0;
        foreach my $binName (sort numeric keys %spotLifeLogBins) {
            print "binName = $binName frequency = " . $spotLifeLogBins{$binName};
            print " normalised = " . $spotLifeLogBins{$binName}/$totalInBins; 
            $totalNormalised += $spotLifeLogBins{$binName}/$totalInBins;
            print " error = " . 1/sqrt($totalInBins);
            print "\n";
            push (@logSizeArray, $binName);
        }
        my $mean = Statistics::Basic::Mean->new(\@sizeArray)->query;
        my $stddev = Statistics::Basic::StdDev->new(\@sizeArray)->query;
        my $max = (sort numeric @sizeArray)[-1];
        print "report: mean = $mean stddev = $stddev max = $max total = $totalNormalised total in bins = $totalInBins sizeof sizeArray " . scalar @sizeArray . "\n";
        #print Dumper @logBinValues;
        $mean = Statistics::Basic::Mean->new(\@logBinValues)->query;
        $stddev = Statistics::Basic::StdDev->new(\@logBinValues)->query;
        print "logbinreport mean = $mean stddev = $stddev max = $max total = $totalNormalised total in bins = $totalInBins sizeof sizeArray " . scalar @sizeArray . "\n";

        #$mean = Statistics::Basic::Mean->new(\@logSizeArray)->query;
        #$stddev = Statistics::Basic::StdDev->new(\@logSizeArray)->query;
        #$max = (sort numeric @logSizeArray)[-1];
        #print "report: mean = $mean stddev = $stddev max = $max total = $totalNormalised total in bins = $totalInBins\n";

    }
# linear bin the data.    
    if (0) {
        # filter bins with only one member.
        foreach my $binName (sort numeric keys %WholeSpotMaxSizeBins) {
            if ( $WholeSpotMaxSizeBins{$binName} == 1) {
               delete($WholeSpotMaxSizeBins{$binName});
            }
        }
        # count total in bins
        my $totalInBins = 0;
        foreach my $binName (sort numeric keys %WholeSpotMaxSizeBins) {
            $totalInBins += $WholeSpotMaxSizeBins{$binName};
            
        }
        # log bin the data.
        foreach my $binName (sort numeric keys %WholeSpotMaxSizeBins) {
             
        }

        # output the normalised results
        my @sizeArray = ();
        my $totalNormalised = 0;
        foreach my $binName (sort numeric keys %WholeSpotMaxSizeBins) {
            print "maxSize = $binName frequency = " . $WholeSpotMaxSizeBins{$binName};
            print " normalised = " . $WholeSpotMaxSizeBins{$binName}/$totalInBins; 
            $totalNormalised += $WholeSpotMaxSizeBins{$binName}/$totalInBins;
            print " error = " . 1/sqrt($totalInBins);
            print "\n";
            push (@sizeArray, $WholeSpotMaxSizeBins{$binName});
        }
        my $mean = Statistics::Basic::Mean->new(\@sizeArray)->query;
        my $stddev = Statistics::Basic::StdDev->new(\@sizeArray)->query;
        my $max = (sort numeric @sizeArray)[-1];
        print "report: mean = $mean stddev = $stddev max = $max total = $totalNormalised total in bins = $totalInBins\n";
    }
    if (0) {
    
        foreach my $binName (sort numeric keys %WholeSpotLongitudeBins) {
            print "longitude = $binName frequency = " . $WholeSpotLongitudeBins{$binName} . "\n";
        }
    }
    if (0) {
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
sub logN {
    my ($x, $n) = @_;
    return log($x)/log($n);
}
        

