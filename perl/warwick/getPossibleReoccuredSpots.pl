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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Delta_Days);
use List::Util qw(sum min max);
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
-a      : do for all the data, not just cycle 15.
-l      : file containing linked spots in format 'spot# -> spot#\\n'

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}

my %opts = ();
getopts("f:l:a", \%opts) ;
my $doAll = 1;
my $debug = 0;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{a})) { $doAll = 1; }


#print $opts{f};

my %sunspots = &Load_Sunspot_SpotCentric($opts{f});
my %sameSpots;
if (defined($opts{l})) { %sameSpots = &getLinkSets(\%sunspots, $opts{'l'}); }
#exit 0;

#print Dumper %sameSpots;
#exit 0;

my %sunspotDates = &Load_Sunspot_DateCentric($opts{f});
    
&printSpotCentricSpots(\%sameSpots);


sub printSpotCentricSpots {
    my $sameSpotsRef = shift;
    my %sameSpots = %{$sameSpotsRef};
    my $longitudeTolleranceTotal = 100;  # 50 degrees either side of the average spot.
    my $latitudeTolleranceTotal = 30; # 15 degrees either side of the average spot.
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $doProcess = 1;
        my $averageLongitude = 0;
        my $numberOfSpots = 0;
        my $lastSpot = 0;
        my $minSpotLongitude = 360;
        my $maxSpotLongitude = 0;
        my $minSpotLatitude = 90;
        my $maxSpotLatitude = -90;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if ($spot->getSolarCycle != 15 && !$doAll) {
                    $doProcess = 0;
                }
                $numberOfSpots++;
                $lastSpot = $spot;
                if ($debug) {
                    print " bounds are: ";
                    print $spot->getDateTime;
                    print " ";
                    print $spot->getGroupNumberAugmented;
                    print " ";
                    print $spot->getCarringtonLongitude;
                    print " ";
                    print $spot->getLatitude;
                    print " ";
                    print $spot->getCorrectedUmbralArea;
                    print " ";
                    print $spot->getSolarCycle;
                    print "\n";
                }
                $averageLongitude += $spot->getCarringtonLongitude;
                if ($spot->getCarringtonLongitude > $maxSpotLongitude) {
                    $maxSpotLongitude = $spot->getCarringtonLongitude;
                }
                if ($spot->getCarringtonLongitude < $minSpotLongitude) {
                    $minSpotLongitude = $spot->getCarringtonLongitude;
                }
                if ($spot->getLatitude > $maxSpotLatitude) {
                    $maxSpotLatitude = $spot->getLatitude;
                }
                if ($spot->getLatitude < $minSpotLatitude) {
                    $minSpotLatitude = $spot->getLatitude;
                }
            }
        }
        if ($doProcess) {
            $averageLongitude = $averageLongitude/$numberOfSpots;
            #print "average long = " . $averageLongitude;
            #print "time of av long = " . Dumper $lastSpot->getSun_LimbTimes($averageLongitude);
            my $minLongBound = $minSpotLongitude - $longitudeTolleranceTotal/2;
            #if ($minLongBound < 0) {$minLongBound += 360;}
            my $maxLongBound = $maxSpotLongitude + $longitudeTolleranceTotal/2;
            if ($maxLongBound > 360 && $minLongBound < 0) {
                #print "changing max long bound to " . ($maxLongBound - 360);
                #print "\n";
                $maxLongBound = $maxLongBound - 360;
            }
            #if ($maxLongBound >= 360) {$maxLongBound -= 360;}
            my $minLatBound = $minSpotLatitude - $latitudeTolleranceTotal/2;
            my $maxLatBound = $maxSpotLatitude + $latitudeTolleranceTotal/2;
            if ($debug) {
                print "newminLatBound: " . $minLatBound;
                print "newmaxLatBound: " . $maxLatBound;
                print "newminLongBound: " . $minLongBound;
                print "newmaxLongBound: " . $maxLongBound;
            }
            my ($ignoreEast, $maxTimeBound) = $lastSpot->getSun_LimbTimes($minLongBound);
            my ($minTimeBound, $ignoreWest) = $lastSpot->getSun_LimbTimes($maxLongBound);
            if ($debug) {
                print "newminTimeBound: " .Dumper  $minTimeBound;
                print "newmaxTimeBound: " .Dumper  $maxTimeBound;
            }

            $minLongBound = sprintf ("%d", $minLongBound);
            $maxLongBound = sprintf ("%d", $maxLongBound);
            #if ($maxLongBound > 360) {$maxLongBound -= 360;}
            if (!defined(@{$maxTimeBound})) { print Dumper $lastSpot->getSun_LimbTimes($minLongBound); print "avlong = $minLongBound\n"; }
            if (@{$minTimeBound} == []) { print Dumper $lastSpot->getSun_LimbTimes($maxLongBound); print "avlong = $maxLongBound\n"; }
            if ($debug) {
                print "minTimeBound: " . Dumper $minTimeBound;
                print "maxTimeBound: " . Dumper $maxTimeBound;
            }
            $minTimeBound = sprintf ("%04d-%02d-%02d", @{$minTimeBound});
            $maxTimeBound = sprintf ("%04d-%02d-%02d", @{$maxTimeBound});
            
            if ($debug) {
            print "min longitude bound = $minLongBound\n";
            print "max longitude bound = $maxLongBound\n";
            print "min latitude bound = $minLatBound\n";
            print "max latitude bound = $maxLatBound\n";
            print "min time bound = $minTimeBound\n";
            print "max time bound = $maxTimeBound\n";
    #'        print Dumper @maxTimeBoundRef;
            }
            my %possibleSpots = ();
            
            foreach my $obsTime (keys (%sunspotDates)) {
                #    print "obstime = $obsTime\n";
                my $minDiff = "";
                my $maxDiff = "";
                eval {
                    $minDiff = Delta_Days(split(/-/,$minTimeBound), split(/-/,$obsTime));
                    $maxDiff = Delta_Days(split(/-/,$maxTimeBound), split(/-/,$obsTime));
                };
                if ($@) {
                    print "spot number = $spotNumber\n";
                    print "odd dates: $minTimeBound $maxTimeBound $obsTime\n";
                    die "exception occured: $@";
                }
                if ($minDiff > 0 && $maxDiff < 0) {
                    foreach my $spotNumber (keys %{$sunspotDates{$obsTime}}) {
                        if ($debug) { print "spot within time bounds: $spotNumber @ $obsTime\n";}
                        foreach my $spot (@{$sunspotDates{$obsTime}{$spotNumber}}) {
                            my $spotLongitude = $spot->getCarringtonLongitude;
                            if ($maxLongBound > 360 && $spotLongitude < 180) { $spotLongitude += 360;}
                            if ($minLongBound < 0 && $spotLongitude > 180) { $spotLongitude -= 360;}
                            my $spotLatitude = $spot->getLatitude;
                            if ($debug) {print " spotlongitude = $spotLongitude min $minLongBound max $maxLongBound: "; }
                            if ($spotLongitude > $minLongBound && $spotLongitude < $maxLongBound && $spotLatitude > $minLatBound && $spotLatitude < $maxLatBound) {
                                if ($debug) {print " WITHIN \n"; }

                                $possibleSpots{$spot->getGroupNumberAugmented} = 1;
                            }
                            else {
                                if ($debug) {print " OUTSIDE \n"; }
                            }
                        }
                    }
                }

            }

            #     print Dumper keys %possibleSpots;
            if (scalar keys %possibleSpots != 0) {
                print "for spot: $spotNumber, pairing candidates are:\n";
                foreach my $pairSpot (keys %possibleSpots) {
                    print "$pairSpot";
                    if (defined($sameSpots{$spotNumber})) {
                        if (&isIn(\@{$sameSpots{$spotNumber}}, $pairSpot)) {
                                print " y";
                        }
                    }
                    #    my $spotsUnpaired = 0;
                    #    foreach my $tmpSpotNo (@{$sameSpots{$pairSpot}}) {
                    #        print "testing : $tmpSpotNo\n";
                    #        if ($sameSpots{$pairSpot} == $tmpSpotNo) {
                    #            print " y";
                    #        }
                    #        else {
                    #            $spotsUnpaired = 1;
                    #        }
                    #    }

                    #}
                    print "\n";
                }
                # we select all the spots 
                print "\n";
            }
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
            #print $test_spot->getGroupNumber();
            #print "\n";
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getGroupNumberAugmented()}{$test_spot->getDateTime}},
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
            push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumberAugmented()}},
                $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

 
sub getLinkSets {
    my ($sunspotRef, $filename) = @_;
    my %sunspots = %{$sunspotRef};
    my %sunspot_hash1 = ();
    my %sunspot_hash2 = ();
    my %linkedSpots = ();
    open (FH, $filename) or die "can't open file '$filename'\n";
    while (defined (my $line = <FH>)) {
        chomp $line;
        my ($spot1, $spot2) = split(/ -> /, $line);
        if ($spot1 eq $spot2) {
            die "duplicate: $line\n";
        }

        #    print "$spot1, $spot2\n";
        my $spot1birth = &getSpotBirth(\%sunspots, $spot1);
        my $spot2birth = &getSpotBirth(\%sunspots, $spot2);
        if ($spot1birth eq $spot2birth) {
            die "something is up with $line, they appear to have the same birthday.\n";
        }
        elsif (!&inTimeOrder($spot1birth, $spot2birth)) { 
            # switch around to spot so they are cronologically ordered.
            my $tmpspot = $spot1;
            $spot1 = $spot2;
            $spot2 = $tmpspot;
        }
        if (!defined($linkedSpots{$spot1})) {
            $linkedSpots{$spot1} = [ $spot2 ];
        }
        else {
            if (!&isIn(\@{$linkedSpots{$spot1}}, $spot2)) {
                push(@{$linkedSpots{$spot1}}, $spot2);
            }
            else {
                die ("$spot2 already is associated with $spot1\n");
            }
        }
    }
    #print Dumper %linkedSpots;
    #exit 0;
    return %linkedSpots;
}

sub inTimeOrder {
    my ($date1, $date2) = @_;
    my @date1 = split(/[- :]/, $date1);
    my @date2 = split(/[- :]/, $date2);
    my $delta_Days = Delta_Days(@date1[0..2], @date2[0..2]);
    if ($delta_Days > 0) {
        return 1;
    }
    elsif ($delta_Days < 0) {
        return 0;
    }
    die "these dates are the same, which shouldn't happen.";
}

sub getSpotBirth {
    my ($sunspotsRef, $spotNo) = @_;
    my %sunspots = %{$sunspotsRef};
    my $spot1ref = $sunspots{$spotNo};
    my @spot1 = sort keys %{$spot1ref};
    if (!defined($spot1[0])) {
        die "this should happen. '$spotNo' is undefined\n";
    }
    return $spot1[0];
}


#my @LinkedSpotsArray = ();
sub _getLinkSets {
    my ($sunspotRef, $filename) = @_;
    my %sunspots = %{$sunspotRef};
    my %sunspot_hash1 = ();
    my %sunspot_hash2 = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        chomp $line;
        #print "line = $line\n";
        my ($spot1, $spot2) = split / -> /,$line;
        $spot1 = $spot1+0; $spot2 = $spot2+0; # force into integers;
        if ($spot1 != $spot2) {
            if (defined($sunspot_hash1{$spot1.""})) {
                push( @{$sunspot_hash1{$spot1.""}}, $spot2 );
            }
            elsif (!defined($sunspot_hash1{$spot1.""})) {
                $sunspot_hash1{$spot1.""} = [$spot2];
            }
            if (defined($sunspot_hash2{$spot2.""})) {
                push( @{$sunspot_hash2{$spot2.""}}, $spot1 );
            }
            elsif (!defined($sunspot_hash2{$spot2.""})) {
                $sunspot_hash2{$spot2.""} = [$spot1];
            }

        }
    }
    close FH;
    my %linkedSpotsHash = ();
    foreach my $spot (sort (keys %sunspot_hash2, keys %sunspot_hash1)) {
        # this is used globally and need to be reset before another list of links
        # is found.
        #if ($spot == 14838) {
        #              print "doing spot : $spot\n";
        my @LinkedSpotsArray = ();
        my @block = ();
        #print "linking spots: $spot\n";
        @block = &getLinkedSpots(\%sunspot_hash2, \%sunspot_hash1, $spot);

        #print Dumper @block;
        # now we remove duplicates;
        #my %unique = ();
        #foreach (@block) { $unique{$_}++; }
        #@block = keys %unique;
        #print Dumper @block;
        #print Dumper %sunspots;
        my %cronologicalOrder = &orderCronologically(\@block, \%sunspots);

        #print "order, yungest first\n";
        #print Dumper %cronologicalOrder;
        #print "\n";
        #        print Dumper %cronologicalOrder;
        #        exit 1;
        #print Dumper @block;
        if (%cronologicalOrder) {
            my $earliestSpot = (sort keys %cronologicalOrder)[0];
            #if (scalar @{$cronologicalOrder{$earliestSpot}} >= 2) {

            my $earliestSpotNo = min(@{$cronologicalOrder{$earliestSpot}});
            #    print  $cronologicalOrder{$earliestSpot};
            #print "earliest spot is ".$cronologicalOrder{$earliestSpot}." on: $earliestSpot\n";
            foreach my $linkedSpots (sort keys %cronologicalOrder) {
                #print "$earliestSpotNo linked spot $linkedSpots\n";
                my @linkedSpots = @{$cronologicalOrder{$linkedSpots}};
                foreach my $spotLink (@linkedSpots) {
                    #            print Dumper %cronologicalOrder;
                    if ($spotLink != $earliestSpotNo) {
                        if (!defined($linkedSpotsHash{$spotLink.""})) {
                            $linkedSpotsHash{$spotLink.""} = [$earliestSpotNo];
                        }
                        else {
                            #print Dumper %linkedSpotsHash;
                            if (&isIn(\@{$linkedSpotsHash{$spotLink.""}}, $earliestSpotNo)) {
                                #     print "alreay got link $spotLink, $earliestSpotNo\n";
                            }
                            else {
                                #print "adding another link  $spotLink, $earliestSpotNo\n";
                                push (@{$linkedSpotsHash{$spotLink.""}}, $earliestSpotNo);
                            }
                            #print Dumper $linkedSpotsHash{$spotLink};
                            #die "already one link for ";
                        }
                        #                        print "linking $spotLink -> $earliestSpotNo\n";
                    }
                }
            }
            #            }
        }
    }
    #print Dumper %linkedSpotsHash;
    #exit 0;
    return %linkedSpotsHash;
}

#sub getLinkedSpots {
#    my ($spotHash1Ref, $spotHash2Ref, $spotNo) = @_;
#        #print Dumper $spotHash1Ref, $spotHash2Ref;
#    if (&isIn(\@LinkedSpotsArray, $spotNo)) {
#        return;
#    }
#    push(@LinkedSpotsArray, $spotNo);
#    foreach my $nextSpot (@{${$spotHash1Ref}{$spotNo}}, @{${$spotHash2Ref}{$spotNo}}) {
#        &getLinkedSpots($spotHash1Ref, $spotHash2Ref, $nextSpot);
#    }
#    return @LinkedSpotsArray;
#}

sub isIn {
    my ($arrayRef, $value) = @_;
    my @array = @{$arrayRef};
    # print "CHECKING isIn $value:\n";
    #print Dumper $arrayRef;

    if (scalar @array == 0) {
        return 0;
    }
    foreach my $arrayValue (@array) {
        if ($arrayValue == $value) {
            # print "found: $arrayValue == $value\n";
            return 1;
        }
    }
    return 0;
}

sub orderCronologically {
    my ($linkedSpotsRef, $sunspotsRef) = @_;
    my @linkedSpots = @{$linkedSpotsRef};
    my %sunspots = %{$sunspotsRef};
    my %linkspotsTime = ();
    #print Dumper @linkedSpots;
    #exit 0;
    foreach my $linkedSpot (@linkedSpots) {
        if (defined($sunspots{$linkedSpot})) {
            #print "found: $linkedSpot\n";
            my $mostRecent = "";
            #foreach my $obsTime (sort keys %{$sunspots{$linkedSpot}}) {
            #             print "obstime = $obsTime\n";
            #       }
            $mostRecent = (sort keys %{$sunspots{$linkedSpot}})[0];
            if (!$linkspotsTime{$mostRecent}) {
                $linkspotsTime{$mostRecent} = ();
                #push(@{$linkspotsTime{$mostRecent}}, $linkedSpot;
                #            print Dumper %linkspotsTime;
                #    print "earliest time = $mostRecent\n";
                #die "this shouldn't happen\n";
            }
            push(@{$linkspotsTime{$mostRecent}}, $linkedSpot);
            #$linkspotsTime{$mostRecent} = $linkedSpot;
        }
        else {
            print "can't find spot $linkedSpot\n";
            exit 1;
        }
        #print Dumper $sunspots{$linkedSpot};
    }
    #print "cronologic dump\n";
    #print Dumper %linkspotsTime;
    #exit 0;
    return %linkspotsTime;
}



# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

