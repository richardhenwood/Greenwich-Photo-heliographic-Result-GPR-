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
use Date::Calc qw( Days_in_Year Add_Delta_Days Add_Delta_DHMS Delta_DHMS);
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

This code does some tests for sunspot visability before storms.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-s      : file containing storm dates: YYYY-MM-DD hh:mm
-d      : file containing the semidiameter of the sun for all dates of GRN data
-r      : use richard stephensons' values, not from file.
-c #    : central meridian distance cutoff, default 50;

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -s ~/ihr/sunspots/perl/storm/aastar.lst -d ~/ihr/sunspots/perl/storm/semi_diam5.txt
EOF
    exit;
}

my %opts = ();
getopts("c:f:s:d:r", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{s})) { usage(); }
#if (!defined($opts{d})) { usage(); }
if (defined($opts{d}) && defined($opts{r})) { usage(); }
my $useRSsemiBOOL = 0;
my $RichardSProgram = "/users/rhenwood/ihr/sunspots/perl/external_libs/a.out";
my $CMDfilter = 50;
if (defined($opts{c})) { $CMDfilter = $opts{c}; }


if (defined($opts{r})) { $useRSsemiBOOL = 1; }

my %sunspotsMins = ();
my %dateMinLookup = ();
#print $opts{f};
#%sunspots = &Load_Sunspot_SpotCentric($opts{f});
my ($sunspotsDatesRef, $obsDatesRef) = &Load_Sunspot_DateCentric($opts{f});
my %sunspotsDates = %{$sunspotsDatesRef};
my %obsDates = %{$obsDatesRef};

#%sunspotsMins = &Load_Sunspot_Mins($opts{f});
#print Dumper %obsDates;
#print Dumper keys %sunspotsDates;
    
my %aaStarStorms = ();
%aaStarStorms = &Load_AAstar_Storms($opts{s});

my %aaStormDates = ();
%aaStormDates = &Find_Storm_Dates(\%aaStarStorms, \%sunspotsDates);
#print Dumper %aaStormDates;

my %sunSemiDiameter = ();
if ($useRSsemiBOOL) {
    %sunSemiDiameter = &GEN_Sun_SemiDiameter(\%obsDates);

} else {
    %sunSemiDiameter = &Load_Sun_SemiDiameter($opts{d});
}
#exit 0;

#print Dumper %aaStormDates;

my %grnAAstarStats = &Get_AAstar_GRNstats(\%aaStormDates, \%sunspotsDates, \%sunSemiDiameter);
#print Dumper %grnAAstarStats;
&print_Storm_Stats(\%grnAAstarStats);

sub print_Storm_Stats {
    my $aaStarStormsRef = shift;
    # for every aa* storm, is there at least one S?
    my %aaStarStorms = %{$aaStarStormsRef};

    my $stormCount = 0;
    my %stormResults = ();
    foreach my $storm (sort keys %aaStarStorms) {
        $stormCount++;
        #print "storm time: $storm\n";
        my $ESOfound = 0;
        my $ESObestResults = '';
        my $ASOfound = 0;
        my $ASObestResults = '';
TEST:   foreach my $tDayNumber (sort keys %{$aaStormDates{$storm}}) {
            if (defined($aaStarStorms{$storm}{$tDayNumber}{'ESO'})) {
                #print "  day = $tDayNumber $ESOsuccessCount $ESOfound \n";
                #print $aaStarStorms{$storm}{$tDayNumber}{'ESO'};
                #print "   " . $aaStarStorms{$storm}{$tDayNumber}{'ASO'};
                #print "\n";
                if (!$aaStarStorms{$storm}{$tDayNumber}{'interpolated'}) {
                    $ESObestResults .= &getBestResult($aaStarStorms{$storm}{$tDayNumber}{'ESO'});
                    $ASObestResults .= &getBestResult($aaStarStorms{$storm}{$tDayNumber}{'ASO'});
                }
                else {
                    $ESObestResults .= 'x';
                    $ASObestResults .= 'x';                
                }

#if ((index($aaStarStorms{$storm}{$tDayNumber}{'ESO'}, 'S') != -1) && !$ESOfound) {
                #    #print "success!";
                #    $ESOsuccessCount++;
                #    $ESOfound = 1;
                #    $ESOresult = 'S';
                #}
                #if ((index($aaStarStorms{$storm}{$tDayNumber}{'ASO'}, 'S') != -1) && !$ASOfound) {
                #    #print "success!";
                #    $ASOsuccessCount++;
                #    $ASOfound = 1;
                #}
                #if ($ESOfound && $ASOfound) {
                #    #last TEST;
                #}
            }
        }
        my $allInterpolated = 1;
        foreach my $tDayNumber (sort keys %{$aaStormDates{$storm}}) {
            if (defined($aaStarStorms{$storm}{$tDayNumber}{'ESO'})) {
                #print "  day = $tDayNumber $ESOsuccessCount $ESOfound \n";
                #print $aaStarStorms{$storm}{$tDayNumber}{'ESO'};
                #print "   " . $aaStarStorms{$storm}{$tDayNumber}{'ASO'};
                #print "\n";
                if (!$aaStarStorms{$storm}{$tDayNumber}{'interpolated'}) {
                    $allInterpolated = 0;
                }
            }
        }
        if ($allInterpolated) {
#            print "all interpolated for: $storm\n";
            #    print Dumper $aaStarStorms{$storm};
        }

        $stormResults{$storm}{'ESO'} = $ESObestResults;
        $stormResults{$storm}{'ASO'} = $ASObestResults;
    }
    #my $ESOSuccessCount = 0;
    #my $ASOSuccessCount = 0;
    #my $ESOsuccessCount = 0;
    #my $ASOsuccessCount = 0;
    #my $ESOAmbigCount = 0;
    #my $ASOAmbigCount = 0;
    #my $ESOambigCount = 0;
    #my $ASOambigCount = 0;
    #my $ESOfailuresCount = 0;
    #my $ASOfailuresCount = 0;
    #my $ESOFailuresCount = 0;
    #my $ASOFailuresCount = 0;
    #print Dumper %stormResults;
    my %stormResult = ();
    foreach my $storm (sort keys %stormResults) {
        my $bestESOResult = &getBestResult($stormResults{$storm}{'ESO'});
        $stormResult{$bestESOResult}{'ESO'}++;
        my $bestASOResult = &getBestResult($stormResults{$storm}{'ASO'});
        $stormResult{$bestASOResult}{'ASO'}++;
        
        print "storm = $storm ";
        print "bestESO = $bestESOResult ";
        print "bestASO = $bestASOResult ";
        print "\n";
    }
    #print Dumper %stormResults;
#    print "totalStorm = $stormCount\n";
    #print Dumper %stormResult;
    # print "ESOsuccess = $ESOsuccessCount\n";
    # print "ASOsuccess = $ASOsuccessCount\n";

}

sub getBestResult {
    my $results = shift;
    if (index($results, 'S') != -1) {
        return 'S';
    }
    elsif (index($results, 's') != -1) {
        return 's';
    }
    elsif (index($results, 'a') != -1) {
        return 'a';
    }
    elsif (index($results, 'A') != -1) {
        return 'A';
    }
    elsif (index($results, 'f') != -1) {
        return 'f';
    }
    elsif (index($results, 'F') != -1) {
        return 'F';
    }
    else { return 'x'; }
}
#
sub Get_AAstar_GRNstats {
    my $aaStarRef = shift;
    my $sunspotDatesRef = shift;
    my $sunSemiDiameterRef = shift;
    my %aaStormDates = %{$aaStarRef};
    my %sunspotDates = %{$sunspotDatesRef};
    my %sunSemiDiameter = %{$sunSemiDiameterRef};
    my %AAstarStormStats = ();

    foreach my $storm (sort keys %aaStormDates) {
        my %dayResults = ();
        #print "storm = $storm\n";
        foreach my $tDayNumber (sort keys %{$aaStormDates{$storm}}) {
            my $obsTime = $aaStormDates{$storm}{$tDayNumber};
            #   print " day = $tDayNumber\n";
            #    print "obstime = '$obsTime'";
            #if (!defined($sunspotDates{$obsTime})) {
                #print "no observation on: '$obsTime'\n";
                #print Dumper %sunspotDates;
                #die "can't find obstime\n";
                #}
            else {
                foreach my $spotNumber (sort keys %{$sunspotDates{$obsTime}}) {
                    
                    if (!defined($sunSemiDiameter{$obsTime})) {
                        die "should be a value for semidiameter on: '$obsTime'";
                    }
                    my $W_0exp = (25/($sunSemiDiameter{$obsTime}*2))**2 * 1000000;
                    my $W_0avg = (41/($sunSemiDiameter{$obsTime}*2))**2 * 1000000;
                    my $U_0avg = (15/($sunSemiDiameter{$obsTime}*2))**2 * 1000000;
                    #print " W_0exp W_0avg U_0avg = $W_0exp $W_0avg $U_0avg \n";

                    foreach my $spot (@{$sunspotDates{$obsTime}{$spotNumber}}) {

                        my $successValue = 'S';
                        my $interpolated = 0;
                        if ($spot->isObservationInterpolated) {
                            $interpolated = 1;
                            $successValue = 's';
                        }
                        $dayResults{$tDayNumber}{'interpolated'} = $interpolated; 

                        #    print " spot ws = " . $spot->getProjectedWholeSpotArea;
                        #print " spot u = " . $spot->getProjectedUmbralArea;
                        #print "  " . $spot->raw_string;

                        if ($spot->getCentralMeridianDistance > -$CMDfilter &&
                            $spot->getCentralMeridianDistance < $CMDfilter) {
##
# logic for expert observer
##                       
                            if ($spot->getProjectedWholeSpotArea > $W_0exp) {
                                $dayResults{$tDayNumber}{'ESO'} .= $successValue; 
                            }
                            else {
                                $dayResults{$tDayNumber}{'ESO'} .= 'F'; 
                            }
##
# logic for average observer
## 
                            if ($spot->getProjectedWholeSpotArea > $W_0avg &&
                                $spot->getProjectedUmbralArea > $U_0avg) {
                                $dayResults{$tDayNumber}{'ASO'} .= $successValue; 
                            }
                            elsif ($spot->getProjectedWholeSpotArea > $W_0avg &&
                                $spot->getProjectedUmbralArea < $U_0avg) {
                                $dayResults{$tDayNumber}{'ASO'} .= 'a'; 
                            }
                            elsif ($spot->getProjectedWholeSpotArea < $W_0avg &&
                                $spot->getProjectedUmbralArea > $U_0avg) {
                                $dayResults{$tDayNumber}{'ASO'} .= 'A'; 
                            }
                            else {
                                $dayResults{$tDayNumber}{'ASO'} .= 'F'; 
                            }
                        }
                        else {
                            $dayResults{$tDayNumber}{'ESO'} .= 'f'; 
                            $dayResults{$tDayNumber}{'ASO'} .= 'f'; 
                        }
                    }
                }
            }
        }
        $AAstarStormStats{$storm} = \%dayResults;
    }

    return %AAstarStormStats;
}

sub Find_Storm_Dates {
    my $aaStarRef = shift;
    my $sunspotDatesRef = shift;
    my %aaStarStorms = %{$aaStarRef};
    my %sunspotDates = %{$sunspotDatesRef};
    #my $onsetTime = 17.5 * 60; # number of minutes till storm onset
    my $aaStormDates = ();
    foreach my $stormTime (sort keys %aaStarStorms) {
        my $t1Date = undef;
        my %stormDates = ();
        my @stormDate = split(/[- :]/,$stormTime);
        #print "stormtime = $stormTime\n";
        my $t1TestDate = sprintf("%d-%02d-%02d %02d:%02d", Add_Delta_DHMS(@stormDate, 00, 0, -17, -30, 00));
        #print Dumper @stormDate;
        #print "testdate = $t1TestDate\n";
        #print " difference = " . &getTimeDifferenceHours($t1TestDate, $stormTime);
        #print "\n";
        my @spotNumber = keys %{$sunspotDates{substr($t1TestDate, 0, 10)}};
        if (defined($spotNumber[0]) && $spotNumber[0] ne '') {
            my $spot = ${$sunspotDates{substr($t1TestDate, 0, 10)}{$spotNumber[0]}}[0];
            my $timeDifference = &getTimeDifferenceHours($t1TestDate, $spot->getDateTime);
            #print Dumper $spot->getGroupNumber;
            #print Dumper $spot->time_in_thousandths_of_day;
            #print Dumper $spot->getDateTime;
            #print "difference = $timeDifference\n";
            if ($timeDifference > 0) {
                $t1Date = &getDateMinusDay(substr($t1TestDate, 0, 10), 1);
            }
            else {
                $t1Date = substr($t1TestDate, 0, 10);
            }
        }
        else {
            # there is a observation here, we are not bothered about exactly when
            # because it is at least 17.5 hours (more like 2 days) before storm.
            $t1Date = &getDateMinusDay(substr($t1TestDate, 0, 10), 1);
        }
        $stormDates{'t1'} = $t1Date;
        $stormDates{'t2'} = &getDateMinusDay($t1Date, 1);
        $stormDates{'t3'} = &getDateMinusDay($t1Date, 2);
        $stormDates{'t4'} = &getDateMinusDay($t1Date, 3);
        $stormDates{'t5'} = &getDateMinusDay($t1Date, 4);
        $stormDates{'t6'} = &getDateMinusDay($t1Date, 5);
        $aaStormDates{$stormTime} = \%stormDates;
    }
    return %aaStormDates;
}

sub getTimeDifferenceHours {
    my ($eventTime, $testTime) = @_;
    my @eventTime = split(/[- :]/,$eventTime);
    my @testTime = split(/[- :]/,$testTime);
    my @timeDifference = Delta_DHMS(@eventTime, 00, @testTime, 00);
    my $hourDifference = $timeDifference[0] * 24 + $timeDifference[1] + $timeDifference[2]/60;
    return $hourDifference;
}
sub getDateMinusDay {
    my ($testTime, $days) = @_;
    my @testTime = split(/[- :]/,$testTime);
    my @minus1Day = Add_Delta_Days(@testTime, -$days);
    my $minus1DayDate = sprintf("%d-%02d-%02d", @minus1Day);
    return $minus1DayDate;
}

sub Load_Sun_SemiDiameter {
    my $filename = shift;
    my %sunSemiDiameter = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        if ($line =~ m/^\d/) {
            my @date = split(/[-:T| ]/,$line);
            #print Dumper @date;
            #exit 0;
            my $semiDiameter = $date[7]; 
            chomp $semiDiameter;
            $sunSemiDiameter{sprintf("%d-%02d-%02d", @date)} = $semiDiameter;
        }
    }
    return %sunSemiDiameter;
}

sub GEN_Sun_SemiDiameter {
    my $datesRef = shift;
    my %dates = %{$datesRef};
    my @dates = keys %dates;
    my %sunSemiDiameter = ();
    foreach my $date (sort @dates) {
        my @values = split(/[- :]/, $date);
        if ($dates{$date}) {
            $values[3] = 12;
        }
        my $dateStr = sprintf("%4d %2d %2d %02d %02d", @values);
        my $programCall = "$RichardSProgram $dateStr";
        #print " $programCall\n";
        my $progResult = `$programCall`;
        chomp ($progResult);
        my @progResults = split(/ +/, $progResult);
        my $progSunSD = $progResults[14];

        #print "$date";
        #print " | $progSunSD";
        #print "\n";

        $sunSemiDiameter{sprintf("%d-%02d-%02d", @values)} = $progSunSD;
        #print"\n";
    }
    #print Dumper %sunSemiDiameter;
    #exit 0;
    
    return %sunSemiDiameter;
}

sub Load_AAstar_Storms {
    my $filename = shift;
    my %storm_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        if ($line =~ m/^ *\d/) {
            my @date = split(/[ \/]/,$line);
            $storm_array{sprintf("%d-%02d-%02d %02d:%02d", $date[0], $date[1], $date[2], substr($date[6],0,2), substr($date[6],2))} = 1;
        }
    }
    return %storm_array;
}

sub printDateCentricSpots {
    my $sunspotsRef = shift;
    my %sunspots = %{$sunspotsRef};
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                print $spot->getDateTime;
                my $thisSpotDateTime = $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print " ";
                print $spot->getSun_East_Limb;
                print " ";
                print $spot->getSun_West_Limb;

                print "\n";
            }
        }
    }
}

# this subroutine loads the sunspot data with the number of minutes since 18740101 as the key.
sub Load_Sunspot_Mins {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            my @dateTime = split(/[- :]/, $test_spot->getDateTime);
            #print Dumper @dateTime;
            my @minsSince1874 = Delta_DHMS(1871,01,01,12,00,00, @dateTime, 00);
            my $minsSince1874 = $minsSince1874[0]*60*24 + $minsSince1874[1]*60 + $minsSince1874[2];
            #print "minsSince = $minsSince1874\n";
            push(@{$sunspot_array{$minsSince1874}{$test_spot->getGroupNumber()}}, $test_spot);
            $dateMinLookup{$test_spot->getDateTime} = $minsSince1874;
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
sub Load_Sunspot_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    my %obsDates = ();
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
        if (!defined($obsDates{$test_spot->getDateTime})) {
            $obsDates{$test_spot->getDateTime} = $test_spot->isObservationInterpolated;
        }
    }
    return (\%sunspot_array, \%obsDates);
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
                                                                                                                        


## this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}

