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

This file returns the Central Meridian distance of the maximum size a spot achiveies.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-b      : bin width, in degrees
-a      : age of interest (default = -1 (all in one) any other value: all separatly)
-c      : use calculated corrected areas (default off)
-s      : produce stats

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}


my %opts = ();
getopts("f:b:a:cs", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $binWidth = 5;
if (defined($opts{b})) { $binWidth = $opts{b}; }
my $ageInterest = -1;
if (defined($opts{a})) { $ageInterest = $opts{a}; }
my $useCalculated = 0;
if (defined($opts{c})) { $useCalculated = 1; print STDERR "using Calculated"; }
my $doStats = 0;
if (defined($opts{s})) { $doStats = 1; }



my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    #my $binWidth = 5;
    my $totalspots = 0;
    my %spotCMDbins = ();
    my %spotGreenwichGroupType = ();
    my %allAges = ();
    my $spotCount = 0;
    my $sizeSum = 0;
    my @sizes = ();

    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $timeAtMax = 0;
        my $maxSize = 0;
        my $maxCMD = undef;
        my $greenwichType = 10;
        my @greenwichTypeArray = ();
        my @birth = ();
        my @death = ();
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            @death = split(/[- :]/, $obsTime);
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!$useCalculated) {
                    if ($spot->getCorrectedWholeSpotArea > $maxSize) {
                        $maxSize = $spot->getCorrectedWholeSpotArea;
                        $timeAtMax = $obsTime;
                        $maxCMD = $spot->getCentralMeridianDistance;
                    }
                }
                else {
                    if ($spot->getCalculatedCorrectedWholeSpotArea > $maxSize) {
                        $maxSize = $spot->getCalculatedCorrectedWholeSpotArea;
                        $timeAtMax = $obsTime;
                        $maxCMD = $spot->getCentralMeridianDistance;
                    }
                }
                push(@greenwichTypeArray, $spot->getGroupType);
            }

        }
        $greenwichType = &mostPopular(\@greenwichTypeArray);
        # print "spotnumber = $spotNumber, type = $greenwichType\n";
        if (!defined($maxCMD)) {
            die "no maximum CMD found!";
        }
        my @ageDHMS = Delta_DHMS(@birth, 0, @death, 0);
        if ($ageDHMS[0] > 200) { die "too old!: spot = $spotNumber age = " . $ageDHMS[0]; }
# we filter out spots which are only seen for one day 
# since they noisy!
        if ($ageDHMS[0] > 1) {
            if ($ageInterest == -1) { $ageDHMS[0] = -1; }

            my $bin = (floor($maxCMD) - (floor($maxCMD) % $binWidth)) + $binWidth/2;
            $spotCMDbins{$bin}{$ageDHMS[0]} += 1;

            if (!defined($allAges{$ageDHMS[0]})) {
                $allAges{$ageDHMS[0]} = 1;
            }

            $spotGreenwichGroupType{$greenwichType}{$ageDHMS[0]} += 1;

            $totalspots++;
        }
               $spotCount++;
        $sizeSum += $maxSize;
        #print "spoot number = $spotNumber\n";
        push(@sizes, $maxSize);

        #print "maxSize = ";
        #print "type = '$greenwichType'\n";
    }
    #print Dumper %spotGreenwichGroupType;
    #print "binwidth $binWidth age $ageInterest";
    #print join ',', (sort numeric keys %allAges);
    #print "\n";
    if (0) {
        for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
            print "bin $bin ";
            foreach my $age (sort numeric keys %allAges) {
                if (defined($spotCMDbins{$bin}{$age})) {
                    my $tmpValue = $spotCMDbins{$bin}{$age}/$totalspots;
                    printf "%6e ", $tmpValue;
                }
                else { print "0 "; }
            }

            print "\n";
        }
    }
    if (0){
        my $headerLine = "age ";
        my $dataLine = "";
        foreach my $age (sort numeric keys %allAges) {
            $headerLine .= "$age" . "day ";
        }
        for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
            $dataLine .= "$bin ";
            foreach my $age (sort numeric keys %allAges) {
                #print Dumper $spotCMDbins{$bin}{$age};
                if (defined($spotCMDbins{$bin}{$age})) {
                    $dataLine .= sprintf "%6d ", $spotCMDbins{$bin}{$age};
                    #$dataLine .= sprintf "%6e ", $spotCMDbins{$bin}{$age}/$totalspots;
                    #$dataLine .= sprintf "error %6e ", sqrt($spotCMDbins{$bin}{$ageInterest})/$totalspots; 
                }
                else { $dataLine .= "0 "; }
                    #print "bin $bin to " . ($bin + $binWidth - 0.1) . " = ";
                    #print $spotCMDbins{$ageInterest}{$bin}/$totalspots;
                    #print " error " . sqrt($spotCMDbins{$ageInterest}{$bin}); 
                    #print " normError " . sqrt($spotCMDbins{$ageInterest}{$bin})/$totalspots;
                    #print "\n";
            }
            $dataLine .= "\n";
        }
        print "$headerLine\n$dataLine";
        print STDERR "total spots = $totalspots\n";
    }

    # this does greenwich group type.
    if (1){
        #print "greenwichtypedata\n";
        my $headerLine = "age ";
        my $dataLine = "";
        foreach my $age (sort numeric keys %allAges) {
            $headerLine .= "\"$age day\" ";
        }
        for (my $bin = 0; $bin <= 9; $bin += 1) {
            $dataLine .= "$bin ";
            foreach my $age (sort numeric keys %allAges) {
                if (defined($spotGreenwichGroupType{$bin}{$age})) {
                    $dataLine .= sprintf "%6d ", $spotGreenwichGroupType{$bin}{$age};
                }
                else { $dataLine .= "0 "; }
            }
            $dataLine .= "\n";
        }
        print "$headerLine\n$dataLine";
        #print Dumper %spotGreenwichGroupType;
        print STDERR "total spots = $totalspots\n";
    }

    if (0) {
        my $headerLine = "bin ";
        my $dataLine = "";
        for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
            $headerLine .= "$bin ";
        }
        #foreach my $age (sort numeric keys %allAges) {
        #    $headerLine .= "$age ";
        #}
        foreach my $age (sort numeric keys %allAges) {
            $dataLine .= "$age ";
            for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
                #print Dumper $spotCMDbins{$bin}{$age};
                if (defined($spotCMDbins{$bin}{$age})) {
                    $dataLine .= sprintf "%6e ", $spotCMDbins{$bin}{$age}/$totalspots;
                }
                else { $dataLine .= "- "; }
                    #print "bin $bin to " . ($bin + $binWidth - 0.1) . " = ";
                    #print $spotCMDbins{$ageInterest}{$bin}/$totalspots;
                    #print " error " . sqrt($spotCMDbins{$ageInterest}{$bin}); 
                    #print " normError " . sqrt($spotCMDbins{$ageInterest}{$bin})/$totalspots;
                    #print "\n";
            }
            $dataLine .= "\n";
        }
        print "$headerLine\n$dataLine";
        print STDERR "total spots = $totalspots\n";
    }

####
# chi squared test: 
####
    if (0) {
        my $sum = 0;
        my $totalBins = 0;
        for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
            foreach my $age (sort numeric keys %allAges) {
                if (defined($spotCMDbins{$bin}{$age})) {
                    $sum += $spotCMDbins{$bin}{$age};
                }
            }
            $totalBins++;
        }
        my $mean = $sum/$totalBins;
        print STDERR "mean = $mean\n";
        my $chiSquared = 0;
        for (my $bin = -90+$binWidth/2; $bin <= 90; $bin += $binWidth) {
            my $binTotal = 0;
            foreach my $age (sort numeric keys %allAges) {
                if ($spotCMDbins{$bin}{$age} < 5) { print "not enough points in $age bin $bin\n"; }
                $binTotal = $spotCMDbins{$bin}{$age};
            }
            $chiSquared += (($binTotal - $mean)**2)/$mean;
        }
        print STDERR "chi squared = $chiSquared\n";

    }

    if ($doStats) {
        my $spotMean = Statistics::Basic::Mean->new(\@sizes)->query;
        printf "size mean = %s\n", $spotMean;
        printf "size stdv = %s\n", Statistics::Basic::StdDev->new(\@sizes)->query;
        my $top = 0;
        my $bottom = 0;
        foreach my $size (@sizes) {
            $top += ($size - $spotMean)**3;
            $bottom += ($size - $spotMean)**2;
        }
        my $skewness = 0;
        if ($bottom != 0) {
            $skewness = ($spotCount**(1/2))*$top/(($bottom)**(3/2));
        }
        printf "size skew = %s\n", $skewness;
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

                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
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

