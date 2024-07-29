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


# this code dose processing of sunspot data into spots with different 
# longevities.

my %opts = ();
getopt ('sb:e:g:', \%opts);
if (!defined($opts{'b'}) || !defined($opts{'e'})) {
    print "need to pass -b <begin time> and -e <end time> on the command line\n";
    print "-g <directory> will put sunspots of different ages into files in the given directory\n";
    print "-s will generate stats about the different age groups - can't be used with -g!\n";
    exit 0;
}
if ($opts{'b'} >= $opts{'e'}) {
    print "it dosen't make sence to have the beginning time before the end time\n";
    exit 0;
}


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
if (1) {
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/section.txt";
    #my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/1949.txt";
    my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
#my $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/spotWholeLife.txt";
#    my $sunspots_filename = "/users/rhenwood/ihr/data/reclassification/GRNallFiltered.txt";
#    $sunspots_filename = "/users/rhenwood/ihr/data/greenwich/1949.txt";
    
    %sunspots = &Load_Sunspot_SpotCentric($sunspots_filename);
}
    
# this is used for counting the number of spots of a given age during calls to 
# getSpotsOfLifetime();
my $count = 0;
if (defined($opts{'g'})) {
    # this mode means generate a whole load of data sets, grouped
    # by sunspot age, and put them in a directory
    my $maximumAge = 200;
    my $duration = $opts{'e'} - $opts{'b'};
    for (my $lowerLimit = $opts{'b'}; $lowerLimit <= $maximumAge; $lowerLimit += $duration) {
        my $upperLimit = $lowerLimit + $duration;
        my $filename = $opts{'g'} . "$lowerLimit.$duration.txt";
        
        open DATA, ">$filename" or die "can't open $filename";
        print "generating spot set of lifetime between $lowerLimit and $upperLimit days\n";
        
        print DATA &getSpotsOfLifetime($lowerLimit, $upperLimit);
        print "written data to $filename\n";
        close (DATA);
    }
}
elsif (exists($opts{'s'})) {
    my $maximumAge = 200;
    my $duration = $opts{'e'} - $opts{'b'};
    for (my $lowerLimit = $opts{'b'}; $lowerLimit <= $maximumAge; $lowerLimit += $duration) {
        $count = 0;
        my $upperLimit = $lowerLimit + $duration;
        &getSpotsOfLifetime($lowerLimit, $upperLimit);
        print "lifetime = $upperLimit count = $count\n";
    }
}
else {
# %sunspots hash needs to be populated for this following sub to work.
    print &getSpotsOfLifetime($opts{'b'},$opts{'e'});
#print "number of entries = " . scalar(keys(%sunspots)) . "\n";
}

# gets the sunspots which have a life time between lowerTime and upperTime;
sub getSpotsOfLifetime {
    my $outputStr = "";
    my ($lowerTime, $upperTime) = @_;
    foreach my $spotNumber (keys (%sunspots)) {
        my $earliestTime = (sort keys %{$sunspots{$spotNumber}})[0];
        my $latestTime = (sort keys %{$sunspots{$spotNumber}})[-1];
        my @spotLifeTime = Delta_DHMS(split(/\D/,$earliestTime),00,split(/\D/,$latestTime),00);
        if ($spotLifeTime[0] >= $lowerTime && $spotLifeTime[0] < $upperTime) {
            #print "spot = $spotNumber has lifetime between $lowerTime, $upperTime days\n";
            foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
                #print "spotnumber = $spotNumber @ $obsTime\n";
                foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                    $outputStr .= $spot->getOrigionalGreenwichFormat;
                }
            }
            $count++;
        }
    }
    return $outputStr;
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
#sub numeric {
#    $a <=> $b;
#}

