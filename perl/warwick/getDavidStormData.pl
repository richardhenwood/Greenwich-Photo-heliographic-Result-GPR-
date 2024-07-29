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
use List::Util qw(sum);

# This code attempts to detect reoccurance. It starts by 
# disposeing of the spots who's life is completly 
# observed in the dataset.
#

# source of faculae data
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1948.REV3.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/test.dat";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1892.FIN";
#my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
my %sunspots = ();
if (0) {
    #my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/1949.REV3.txt";
    my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.fixed.dat";
    # load the data into a hash
    #my %sunspots = ();
    %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);
}
if (1) {
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/section.txt";
#    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/1957.grp";
    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
    %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
}
    
# %sunspots hash needs to be populated for this following sub to work.
&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";


sub find_unique_sunspots {
my @usedDates = qw( 1957-02-24 1957-02-25 1957-02-26 1957-02-27 1957-02-28 1957-03-01 1957-06-29 1957-06-30 1957-07-01 1957-07-02 1957-07-03 1957-07-04 1957-09-07 1957-09-08 1957-09-09 1957-09-10 1957-09-11 1957-09-12 1957-09-15 1957-09-16 1957-09-17 1957-09-18 1957-09-19 1957-09-20 1958-02-05 1958-02-06 1958-02-07 1958-02-08 1958-02-09 1958-02-10 1958-12-07 1958-12-08 1958-12-09 1958-12-10 1958-12-11 1958-12-12 1960-03-24 1960-03-25 1960-03-26 1960-03-27 1960-03-28 1960-03-29 1960-04-24 1960-04-25 1960-04-26 1960-04-27 1960-04-28 1960-04-29 1960-11-07 1960-11-08 1960-11-09 1960-11-10 1960-11-11 1960-11-12);
    my %usedDates = ();
    foreach my $usedDate (@usedDates) {
        #print "used date = $usedDate\n";
        $usedDates{$usedDate} = 0;
    }
    #print Dumper %usedDates;
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
            my $obsDate = substr($obsTime, 0, 10);
            #        print "obstime = '$obsTime' obsdate = '$obsDate'\n";
            if (defined($usedDates{$obsDate})) {
                foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                    print $spot->getOrigionalGreenwichFormat();
                }
            }
        }
    }
}

 
 
=begin
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
=cut

    
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
        

