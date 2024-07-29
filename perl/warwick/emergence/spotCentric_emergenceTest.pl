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

We return a cound of the different ages of spots in days. We round ages up.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-b deg  : beginning of the emergence region, in degrees from central meridian
-e deg  : end of the emergence region, in degrees from central meridian
-n      : normalise totals output (area underneath = 1)
-t      : just produce totals, ignoring 0 day lifetimes.
-r      : just produce raw data, suitable for matlab fitting.
-l      : upper lifetime limit, days or hours. default = 7
-h      : calculate lifetime in hours, not days (deault = days).
-s      : include the start of the window as a third column on the output.
-a      : range the spots in terms of minimum projected size, 0-10,11-50,50-100,100-250,250+ (default = on)

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("f:b:e:l:ntrhs", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{b})) { usage(); }
my $emergenceBegin = $opts{b};
if (!defined($opts{e})) { usage(); }
my $emergenceEnd = $opts{e};
my $normalise = 0;
if (defined($opts{n})) { $normalise = 1; }
my $justTotals = 0;
if (defined($opts{t})) { $justTotals = 1; }
my $matlabFitting = 0;
if (defined($opts{r})) { $matlabFitting = 1; } 
my $upperLimit = 7;
if (defined($opts{l})) { $upperLimit = $opts{l}; } 
my $useHours = 0;
if (defined($opts{h})) { $useHours = 1; } 
my $includeWindow = 0;
if (defined($opts{s})) { $includeWindow = 1; } 

#print "upperlimit = $upperLimit\n";


if (!$matlabFitting) {
    &main();
}
else {
    &matlabOutput();
}

sub main {
    my %sunspots = ();
    #print $opts{f};
    %sunspots = &Load_Sunspot_SpotCentric($opts{f});
    my %emergedSpots = &getEmergenceDistribution(\%sunspots);
    #print Dumper %emergedSpots;

    my $totalCount = 0;
    my %totals = ();
    foreach my $year (sort keys %emergedSpots) {
        foreach my $lifetime (sort keys %{$emergedSpots{$year}}) {
            if ($lifetime != 0 && $lifetime <= $upperLimit) { # ignore 0 day lifetimes, they are unreliable
                foreach my $band (@{getSizeBands()}) {
                    #print "band = '$band'";
                    if (!defined($emergedSpots{$year}{$lifetime}{$band})) {
                        $emergedSpots{$year}{$lifetime}{$band} = 0;
                    }
                    if (!$justTotals) {
                        printf ("%d %d %d %d\n", $year, $lifetime, $band, $emergedSpots{$year}{$lifetime}{$band});
                    }
                    if (!defined($totals{$lifetime}{$band})) {
                        $totals{$lifetime}{$band} = 0;
                    }
                    $totals{$lifetime}{$band} += $emergedSpots{$year}{$lifetime}{$band};
                    $totalCount += $emergedSpots{$year}{$lifetime}{$band};
                }
            }
        }
        print "\n\n";
    }
    if (!$normalise) { $totalCount = 1; }
    print "# totals: ";
    print join " ", @{&getSizeBands};
    print "\n";
    #print Dumper %totals;
    foreach my $lifetime (sort keys %totals) {
        if ($lifetime != 0 && $lifetime <= $upperLimit) {   
            printf("%d ", $lifetime);
            foreach my $size (sort numeric keys %{$totals{$lifetime}}) {
                #print Dumper $totals{$lifetime}{$size};
                printf(" %f", $totals{$lifetime}{$size}/$totalCount);
                if ($includeWindow) { print " $emergenceBegin"; }
            }
            print "\n";
        }
    }
}

sub matlabOutput {
    my %sunspots = ();
    #print $opts{f};
    %sunspots = &Load_Sunspot_SpotCentric($opts{f});
    my %emergedSpots = &getEmergenceDistribution(\%sunspots);
    #print Dumper %emergedSpots;

    my $totalCount = 0;
    my %totals = ();
    foreach my $year (sort keys %emergedSpots) {
        foreach my $lifetime (sort keys %{$emergedSpots{$year}}) {
            if ($lifetime != 0) { # ignore 0 day lifetimes, they are unreliable
                for (my $i = 0; $i < $emergedSpots{$year}{$lifetime}; $i++) {
                    printf ("%d\n", $lifetime);
                }
            }
        }
    }
}


sub getEmergenceDistribution {
    my $sunspotsRef = shift;
    my %sunspots = %{$sunspotsRef};
    my %spotAgeCount = ();
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my @ageDHMS = &getAgeAndMinimumProjectedSize(\%{$sunspots{$spotNumber}});
        my $minimumProjectedSize = $ageDHMS[-1];
        #printf ("pre rounding: %f\n", ($ageDHMS[0] + $ageDHMS[1]/24));
        my $spotAge = undef;
        if ($useHours) {
            $spotAge = $ageDHMS[0] * 24 + $ageDHMS[1]; #we round up.
        }
        else {
            $spotAge= &toClosestInt(($ageDHMS[0] + $ageDHMS[1]/24)); #we round up.
        }
        # quantize the minimum projected size
        $minimumProjectedSize = &quantizeProjectedSize($minimumProjectedSize);
        my $firstObsCMD = undef;
        my $year = undef;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($firstObsCMD)) {
                    $firstObsCMD = $spot->getCentralMeridianDistance;
                    $year = $spot->getYear;
                }
            }
        }
        #print "firstObsCMD $firstObsCMD $emergenceBegin $emergenceEnd \n";
        if ($firstObsCMD >= $emergenceBegin &&
            $firstObsCMD < $emergenceEnd ) {
            #    print "\nIn range!\n";
            if (!defined($spotAgeCount{$year}{$spotAge}{$minimumProjectedSize})) {
                $spotAgeCount{$year}{$spotAge}{$minimumProjectedSize} = 0;
            }
            $spotAgeCount{$year}{$spotAge}{$minimumProjectedSize}++;
        }
    }
    return %spotAgeCount;
}

sub toClosestInt {
    my $value = shift;
    if (ceil ($value - 0.5) == floor ($value)) {
        return floor($value);
    }
    else {
        return ceil ($value);
    }
}

sub quantizeProjectedSize {
    my $value = shift;
    if ($value <= 10) {
        return 10;
    }
    elsif ($value <= 50) {
        return 50;
    }
    elsif ($value <= 100) {
        return 100;
    }
    #elsif ($value <= 250) {
    #    return 250;
    #}
    return 500;
}

sub getSizeBands {
    return [10, 50, 100, 500];
}

sub getAgeAndMinimumProjectedSize {
    my $spotsRef = shift;
    my %spots = %{$spotsRef};
    my (@birth, @death) = ();
    my ($firstCMD, $lastCMD) = undef;
    my $minimumSize = 9999999;
    foreach my $obsTime (sort keys %spots) {
        if (!@birth) { @birth = split(/[- :]/, $obsTime);}
        foreach my $spot (@{$spots{$obsTime}}) {
            if (!defined($firstCMD)) { $firstCMD = $spot->getCentralMeridianDistance; }
            $lastCMD = $spot->getCentralMeridianDistance;
            if ($minimumSize > $spot->getProjectedWholeSpotArea) {
                $minimumSize = $spot->getProjectedWholeSpotArea;
            }
        }
        @death = split(/[- :]/, $obsTime);
    }
    #print "\nfirstCMD, lastCMD\n";
    #print "$firstCMD , $lastCMD\n";
    #print "\nbirth,death,diff\n";
    #print Dumper @birth, @death, Delta_DHMS(@birth, 0, @death, 0);
    return Delta_DHMS(@birth, 0, @death, 0), $minimumSize;
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

