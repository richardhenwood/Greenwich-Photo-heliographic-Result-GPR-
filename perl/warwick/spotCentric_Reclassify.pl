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
It outputs the data, sorted by sunspot number

usage: $0 -f file

-f      : file containing linked spots in format '# -> #'
-g      : file containing data, in Greenwich format.

example: $0 -f ~/ihr/data/recurrenceSep07/uniqueLinkedC15All.txt -g /users/rhenwood/ihr/data/greenwich/cycle15.txt
EOF
    exit;
}



my %opts = ();
getopt('f:g:', \%opts);
if (!defined($opts{f}) || !defined($opts{g})) {
    &usage();
}
my $file = $opts{f};
my $grnData = $opts{g};

=begin
# source of faculae data
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1948.REV3.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/test.dat";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1892.FIN";
#my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
my %sunspots = ();
if (0) {
    #my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/1949.REV3.txt";
    my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
    # load the data into a hash
    #my %sunspots = ();
    %sunspots = &Load_Sunspot_and_Faculae_SpotCentric($sunspots_and_faculae_filename);
}
if (0) {
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/section.txt";
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/1949.txt";
    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
#    my $sunspots_filename = $file;
    %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
}
=cut
    
# load the sunspots reclassifications into a hash.
my $RECLASSIFICATIONFILE = $file;
my %sameSpots = &Load_Reclassifications($RECLASSIFICATIONFILE);

# put all the spots which are linked into an array for convienience.
my @linkedSpots = (keys %sameSpots, values %sameSpots);

#print Dumper @linkedSpots;

# load up the data associated with spot numbers.
my %sunspots = &Load_Sunspot_SpotCentric($grnData);
#print Dumper %sunspots;

# find the most recently reclassified spot.
my %cronologicalLinks = &orderCronologically(\@linkedSpots, \%sunspots);
#print Dumper %cronologicalLinks;

foreach my $spotTime (reverse sort keys %cronologicalLinks) {
    &findAllLinks(@{$cronologicalLinks{$spotTime}});
}

sub findAllLinks {
    #my $spotArrRef = shift;
    my @spots = @_;
    my %linkages = ();
    foreach my $spot (@spots) {
        print "spot = $spot\n";
        print "finding all links:\n";
        open (FH, $RECLASSIFICATIONFILE);
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
                #    print "obstime = $obsTime\n";
                #}
            $mostRecent = (sort keys %{$sunspots{$linkedSpot}})[-1]; 
            #print "most recent = $mostRecent\n";
            push(@{$linkspotsTime{$mostRecent}}, $linkedSpot);
                #    foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
        }
        else {
            print "can't find spot $linkedSpot\n";
        }
        #print Dumper $sunspots{$linkedSpot};
    }
    #print Dumper %linkspotsTime;
    return %linkspotsTime;
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
&reclassify_spots();

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
sub Load_Reclassifications {
    my $filename = shift;
    my %sunspot_hash = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        chomp $line;
        my ($spot1, $spot2) = split / -> /,$line;
        if ($spot1 != $spot2) {
            #print "spot = $spot1, $spot2 ";
            my $keyMax = max($spot1, $spot2);
            my $valueMin = min($spot1, $spot2);
            if (defined($sunspot_hash{$keyMax})) {
                # this section resolves already linked spots by 
                # linking spots to the lowest spot number.

                #            print "collision: $keyMax -> $valueMin already defined as ";
                #print " $keyMax -> " . $sunspot_hash{$keyMax};
                #print "\nredefining all to the lowest spot number:\n";
                my $newMinValue = min($sunspot_hash{$keyMax}, $valueMin);
                my $nextMinValue = max($sunspot_hash{$keyMax}, $valueMin);
                $sunspot_hash{$keyMax} = $newMinValue;
                $sunspot_hash{$nextMinValue} = $newMinValue;
                #print "$keyMax -> $newMinValue\n";
                #print $nextMinValue ." -> ". $newMinValue;
                #print "\n";
                #print Dumper $sunspot_hash{max($spot1, $spot2)};
            }
            else {
                $sunspot_hash{$keyMax} = $valueMin;
            }
        }
        #if (!defined($spot1)) {
            #    exit;
            #}
        #print "spot = $spot1, $spot2 ";
        #$test_spot->parse_data_into_object($line);
        #if ($test_spot->is_spot()) {
            #    push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
            #$test_spot);
            #}#
            #elsif ($test_spot->is_group_total()) {
                #push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
                #}
    }
    close FH;
    return %sunspot_hash;
}


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

