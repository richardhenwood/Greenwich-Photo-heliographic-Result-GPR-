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
use List::Util qw(sum min max);
use Getopt::Std;

# this code reclassifies the spots who's linkages have been suggested in a separate file
sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

It takes a superset of greenwich data and reclassifies all the linked
spot which are provided in a separate file to create a greenwich
formatted dataset containing only linked spots

usage: $0 -g file -l file

-g      : file containing data, in Greenwich format.
-l      : file containing linked spots in format 'spot# -> spot#\\n'

example: $0 -g /users/rhenwood/ihr/data/greenwich/cycle15.txt -l /users/rhenwood/ihr/data/recurrenceSep07/uniqueLinkedC15All.txt
EOF
    exit;
}


my %opts = ();
getopt('l:g:', \%opts);
if (!defined($opts{'l'}) || !defined($opts{'g'})) { &usage(); }
my $linkedSpotsFile = $opts{'l'};
my $greenwichDataFile = $opts{'g'};

my %sunspots = &Load_Sunspot_SpotCentric($greenwichDataFile);
my %sameSpots = &getLinkSets($linkedSpotsFile);
#print Dumper %sameSpots;
my @LinkedSpotsArray;

&reclassifySpots(\%sameSpots);

sub reclassifySpots {
    my ($hashRef) = @_;
    my %spotLinks = %{$hashRef};
    foreach my $spot (keys %spotLinks) {
        if ($spot != $sameSpots{$spot}) {
            #print "spot $spot -> " . $sameSpots{$spot};
            #   print "\n";
            #print Dumper %{$sunspots{$spot}};
            foreach my $obsTime (keys %{$sunspots{$spot}}) {
                foreach my $sunspot (@{$sunspots{$spot}{$obsTime}}) {
                    #print Dumper $sunspot;
#                    print $sunspot->getOrigionalGreenwichFormat;
                    #$sunspot->putGroupNumber($sameSpots{$spot});
                    $sunspot->putGroupNumber($sameSpots{$spot});
                    print $sunspot->getOrigionalGreenwichFormat;

                }
            }
            #print "samespot{spot} = " . $sameSpots{$spot} . "\n";
            foreach my $obsTime (keys %{$sunspots{$sameSpots{$spot}}}) {
                foreach my $sunspot (@{$sunspots{$sameSpots{$spot}}{$obsTime}}) {
                    #print Dumper $sunspot;
#                    print $sunspot->getOrigionalGreenwichFormat;
                    print $sunspot->getOrigionalGreenwichFormat;

                }
            }
        }
    }
}

sub getLinkSets {
    my $filename = shift;
    my %sunspot_hash1 = ();
    my %sunspot_hash2 = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        chomp $line;
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
        @LinkedSpotsArray = ();
        my @block = ();
        @block = &getLinkedSpots(\%sunspot_hash2, \%sunspot_hash1, $spot);

        #print Dumper @block;
        # now we remove duplicates;
        my %unique = ();
        foreach (@block) { $unique{$_}++; }
        @block = keys %unique;
        my %cronologicalOrder = &orderCronologically(\@block, \%sunspots);

        #print Dumper %cronologicalOrder;
#        print Dumper %cronologicalOrder;
#        exit 1;
        #print Dumper @block;
        if (%cronologicalOrder) {
            my $earliestSpot = (sort keys %cronologicalOrder)[0];
            #if (scalar @{$cronologicalOrder{$earliestSpot}} >= 2) {
                
            my $earliestSpotNo = min(@{$cronologicalOrder{$earliestSpot}});
            #    print  $cronologicalOrder{$earliestSpot};
            #print "earliest spot is ".$cronologicalOrder{$earliestSpot}." on: $earliestSpot\n";
            foreach my $linkedSpots (keys %cronologicalOrder) {
                my @linkedSpots = @{$cronologicalOrder{$linkedSpots}};
                foreach my $spotLink (@linkedSpots) {
                    #            print Dumper %cronologicalOrder;
                    if ($spotLink != $earliestSpotNo) {
                        $linkedSpotsHash{$spotLink} = $earliestSpotNo;
                        #    print "linking $spotLink -> $earliestSpotNo\n";
                    }
                }
            }
            #            }
        } 
    }
    return %linkedSpotsHash;
}

sub getLinkedSpots {
    my ($spotHash1Ref, $spotHash2Ref, $spotNo) = @_;
#    print "linking spots: $spotNo\n";
    if (&isIn(\@LinkedSpotsArray, $spotNo)) {
        return;
    }
    push(@LinkedSpotsArray, $spotNo);
    foreach my $nextSpot (@{${$spotHash1Ref}{$spotNo}}, @{${$spotHash2Ref}{$spotNo}}) {
        &getLinkedSpots($spotHash1Ref, $spotHash2Ref, $nextSpot);
    }
    return @LinkedSpotsArray;
}
# this is a depricated version of the code above, which is tighter.
sub _getLinkedSpots {
    my ($spotHash1Ref, $spotHash2Ref, $spotNo) = @_;
    print "linking spots: $spotNo\n";
    my %spotHash1 = %{$spotHash1Ref};
    my %spotHash2 = %{$spotHash2Ref};
    if (&isIn(\@LinkedSpotsArray, $spotNo)) {
        return;
    }
    push(@LinkedSpotsArray, $spotNo);
    foreach my $nextSpot (@{$spotHash1{$spotNo}}, @{$spotHash2{$spotNo}}) {
        push(@LinkedSpotsArray, &getLinkedSpots($spotHash1Ref, $spotHash2Ref, $nextSpot));
    }
    return @LinkedSpotsArray;
}

sub orderCronologically { 
    my ($linkedSpotsRef, $sunspotsRef) = @_;
    my @linkedSpots = @{$linkedSpotsRef};
    my %sunspots = %{$sunspotsRef};
    my %linkspotsTime = ();
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
                #print Dumper %linkspotsTime;
                #print "earliest time = $mostRecent\n";
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
    return %linkspotsTime;
}

sub isIn {
    my ($arrayRef, $value) = @_;
    my @array = @{$arrayRef};
    #print "CHECKING isIn:\n";
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

# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

# put all the spots which are linked into an array for convienience.
#my @linkedSpots = (keys %sameSpots, values %sameSpots);

#print Dumper @linkedSpots;

# load up the data associated with spot numbers.
#my %sunspots = &Load_Sunspot_SpotCentric("/users/rhenwood/ihr/data/greenwich/1949.txt");

# find the most recently reclassified spot.
#my %cronologicalLinks = &orderCronologically(\@linkedSpots, \%sunspots);
#print Dumper %cronologicalLinks;

#foreach my $spotTime (reverse sort keys %cronologicalLinks) {
#    &findAllLinks(@{$cronologicalLinks{$spotTime}});
#}

sub findAllLinks {
    #my $spotArrRef = shift;
    my @spots = @_;
    my %linkages = ();
    foreach my $spot (@spots) {
        print "spot = $spot\n";
        print "finding all links:\n";
        open (FH, $linkedSpotsFile);
        while (defined (my $line = <FH>)) {
            chomp $line;
            my ($spot1, $spot2) = split / -> /,$line;
            if ($spot1 != $spot2) {
                if ($spot1 == $spot) {
                    push(@{$linkages{$spot}}, $spot2);
                }
                elsif ($spot2 == $spot) {
                    push(@{$linkages{$spot}}, $spot1);
                }
            }
        }
        close FH;
    }
    print Dumper %linkages;
}




#print Dumper %sameSpots;
#&check_for_multiReoccurance();

sub _check_for_multiReoccurance {
    foreach my $spotNumber (keys %sameSpots) {
        my $firstCheck = 0;
        while ( my ($startSpot, $linkedSpot) = each %sameSpots) {
            if ($spotNumber == $linkedSpot) {
                print "multi reoccurance $spotNumber == $linkedSpot\n";
                print "$spotNumber -> " . $sameSpots{$spotNumber};
                print "\n $startSpot -> $linkedSpot";
                
                my $minSpotNumber = min($linkedSpot, $sameSpots{$spotNumber});
                my $maxSpotNumber = max($spotNumber, $startSpot);
                $sameSpots{$maxSpotNumber} = $minSpotNumber;
                print "\n relinking: $maxSpotNumber -> $minSpotNumber";
                print "\n";

            }
        }
    }
}
#print Dumper %sameSpots;
#&reclassify_spots();

sub reclassify_spots {
    foreach my $keyRef (keys %sameSpots) {
        my $spotNumberTest = 232;
        #    print $keyRef;
        #print " -> " . $sameSpots{$keyRef} . "\n";
        if (exists($sameSpots{$spotNumberTest})) {
            print Dumper $sameSpots{$spotNumberTest};
        }
    }
    foreach my $spotNumber (keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {

            }
        }
    }
}


# %sunspots hash needs to be populated for this following sub to work.
#&find_unique_sunspots();
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";

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
                #push (@partLifeSpots, $spot->getOrigionalGreenwichFormat());
            }
        }
        else {
            #push (@partLifeSpots, $spotNumber);
            foreach my $spot (@spotArray) {
                #   print " size = " . $spot->getProjectedWholeSpotArea;
                #print " position = " . $spot->getCentralMeridianDistance;
                if ($spot->getProjectedWholeSpotArea == $maxSpotSize) {
                    my $bin = ($binSize/2)+$binSize * floor($spot->getCentralMeridianDistance / $binSize);
                    #   print " bin = $bin ";
                    $WholeSpotLongitudeBins{$bin}++;
                }
                push (@partLifeSpots, $spot->getOrigionalGreenwichFormat());
                #print "\n";
            }
        }
        $totalSpots++;
    }
    #foreach my $partSpot (@partLifeSpots) {
        
    #print "totalSpots = $totalSpots \n";
    #$totalSpots = scalar @wholeLifeSpots + scalar @partLifeSpots;
    #print "totalSpots = $totalSpots \n";

    
    # now do the post processing...
    
    if (0) {
    
        foreach my $binName (sort numeric keys %WholeSpotLongitudeBins) {
            print "longitude = $binName frequency = " . $WholeSpotLongitudeBins{$binName} . "\n";
    #        print Dumper %maxAreaBins;
        }
    }
    if (1) {
        foreach my $data (sort @partLifeSpots) {
            print $data;
        }
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
