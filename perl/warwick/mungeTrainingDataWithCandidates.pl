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


# this program takes two files. cycle15candidates : candidate pairs unfiltered for latitude.
#  cycle15LatitudeFiltered - candidate pairs filtered for latitude.
# the latter of these files is a subset of the former. However, the former includes linking information
# which is necessary for training our Neural Network
#
sub usage {
    print STDERR << "EOF";
 this program takes two files. cycle15candidates : candidate pairs unfiltered for latitude.
  cycle15LatitudeFiltered - candidate pairs filtered for latitude.
 the latter of these files is a subset of the former. However, the former includes linking information
 which is necessary for training our Neural Network

 -f: training dataset.
 -u: candidate spots, without teaching data.
EOF
    exit;
}
                                                                                                                        

my %opts = ();
getopts("f:u:", \%opts) ;
if (!defined($opts{f}) || !defined($opts{u})) { usage(); }

my %sunspotsFiltered = ();
my %sunspotsUnfiltered = ();

%sunspotsFiltered = &Load_Sunspot_TrainingData($opts{f});
%sunspotsUnfiltered = &Load_Sunspot_TrainingData($opts{u});
    &printFilteredTrainingData();


sub printFilteredTrainingData {
    foreach my $candidateSpot (sort keys %sunspotsUnfiltered) {
        
        if (defined($sunspotsFiltered{$candidateSpot})) {
            print "\nfor spot: $candidateSpot, pairing candidates are:\n";
            foreach my $linkedSpot (sort @{$sunspotsFiltered{$candidateSpot}}) {
               # print "link to: $linkedSpot\n";
                for (my $i = 0; $i < scalar @{$sunspotsUnfiltered{$candidateSpot}}; $i++) {
                    #print "i = $i ";
                    
                    my $foundSpot = ${$sunspotsUnfiltered{$candidateSpot}}[$i];
                    $foundSpot =~ s/^(\d+).*/$1/;
                    #print "testing spots: $linkedSpot $foundSpot\n";
                    #print "\n";
                    if ($foundSpot == $linkedSpot) {
                        print ${$sunspotsUnfiltered{$candidateSpot}}[$i];
                        print "\n";
                    }
                }
            }
          #  print Dumper $sunspotsUnfiltered{$candidateSpot};
        }
        else {
            print "candidate $candidateSpot doesn't exist!\n";
        }
    }
}

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
sub Load_Sunspot_TrainingData {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    my $linkedSpot = 0;
    my $candidateSpot = "";
    while (defined (my $line = <FH>)) {
        chop($line);
        if ($line =~ m/^$/) {
            $linkedSpot = 0;
        }
        if ($linkedSpot) {
            push(@{$sunspot_array{$candidateSpot}}, $line);
        }
	
	if ($line =~ m/for spot/) {
            $linkedSpot = 1;
	    #print "line = $line";
            $candidateSpot = $line;
            $candidateSpot =~ s/(.*) (\d+)(.*)/$2/;
            #print "candidate = $candidateSpot\n";
            @{$sunspot_array{$candidateSpot}} = ();
	}

        

    }
  #  print Dumper %sunspot_array;
    #print Dumper $sunspot_array{7117};
    return %sunspot_array;
}



# this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}




