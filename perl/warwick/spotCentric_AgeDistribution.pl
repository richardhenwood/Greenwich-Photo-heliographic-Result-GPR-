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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS Add_Delta_DHMS Delta_Days);
use List::Util qw(sum max);
use Getopt::Std;

# we check some of the extream events - for example - what is the largest change in latitude a spot make during it's life?
sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

This code calculates the age of sunspot nests - or just sunspots if there are no nests.

usage: $0 -f file

-f      : file containing data, in Greenwich format.
-n      : normalising factor

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp
EOF
    exit;
}
my %opts = ();
getopts("f:n:", \%opts) ;
if (!defined($opts{f})) { usage(); }
my $normalisationFactor = 1;
if (defined($opts{n})) { $normalisationFactor = $opts{n}; }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_SpotCentric($opts{f});
    
&printSpotCentricSpots();

sub printSpotCentricSpots {
    my %ageCount = ();
    my @latitudeDelta = ();
    my @longitudeDelta = ();
    my %averageAge = ();
    my $totalCount = 0;
    for (my $i = 0; $i < 200; $i++) {
        $ageCount{$i} = 0;
    }
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        my $minLatitude = 90;
        my $maxLatitude = -90;
        my $minCarringtonLongitude = 360;
        my $maxCarringtonLongitude = 0;
        my $cycleNumber;
        my @birth = ();
        my @death = ();
        my $latitudeDeviation = undef;
        my $initialLatitude = undef;
        my $longitudeDeviation = undef;
        my $initialLongitude = undef;
        my $firstCMD = undef;
        my $lastCMD = undef;
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            if (!@birth) { @birth = split(/[- :]/, $obsTime);}
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                if (!defined($firstCMD)) { $firstCMD = $spot->getCentralMeridianDistance; }
                $lastCMD = $spot->getCentralMeridianDistance;
            }
            @death = split(/[- :]/, $obsTime);
        }
        my @ageDHMS = Delta_DHMS(@birth, 0, @death, 0);

        if ($ageDHMS[0] > 0) {
            my $uncertainBirth = 0;
            my $uncertainDeath = 0;
            if ($firstCMD < -60) {
                $uncertainBirth = 1;
            }
            if ($lastCMD > 60) {
                $uncertainDeath = 1;
            }

            my @possibleBirth = (@birth, 0);
            if ($uncertainBirth) { @possibleBirth = Add_Delta_DHMS(@birth, 0, -20, 0, 0, 0); }
            my @possibleDeath = (@death, 0);
            if ($uncertainDeath) { @possibleDeath = Add_Delta_DHMS(@death, 0, 20, 0, 0, 0); }
            #my @lowPossibleAge = Delta_DHMS(@possibleBirth, @possibleDeath);
            my @highPossibleAge = Delta_DHMS(@possibleBirth, @possibleDeath);


            if (0) {
                print "spotNumber: $spotNumber ";
                print " birth: " . $birth[0] . "-" . $birth[1] . "-" . $birth[2] . " " . $birth[3] . ":" . $birth[4];
                print " possibleBirth: ". $possibleBirth[0] . "-" . $possibleBirth[1] . "-" . $possibleBirth[2] . " " . $possibleBirth[3] . ":" . $possibleBirth[4];

                print " ageav = " . ($ageDHMS[0] + $highPossibleAge[0])/2;
                print " lowpossible = " . $ageDHMS[0];
                print " highpossible = " . $highPossibleAge[0];
                print "\n";
            }
            push (@latitudeDelta, ($maxLatitude - $minLatitude));
            push (@longitudeDelta, ($maxCarringtonLongitude - $minCarringtonLongitude));
            push (@{$averageAge{$birth[0] . "-" . $birth[1] . "-" . $birth[2]}}, $ageDHMS[0]);
            if ($ageDHMS[0] == $highPossibleAge[0]) {
                $ageCount{($ageDHMS[0] + $highPossibleAge[0])/2} += 1;
            }
        }
    }
    my @correctionFactor = &getFilter();
    foreach my $age (sort numeric keys %ageCount) {
        if (defined ($correctionFactor[$age]) && $correctionFactor[$age] != 0) {
            print "age = $age count " . $ageCount{$age};
            print " corrected = " . ($ageCount{$age} * $correctionFactor[$age]/$normalisationFactor);
            #print " correction = " + ($correctionFactor[$age]/$normalisationFactor);
            print "\n";
            $totalCount += $ageCount{$age};
        }
    }
    print "total count = $totalCount\n";
#    print "max = " . max(@latitudeDelta) . "\n"; 
#    print "max = " . max(@longitudeDelta) . "\n"; 
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
                                                                                                                        
sub getCorrectionFactor {
    my @correctionFactor = ();
    $correctionFactor[0] = 0;
    $correctionFactor[1] = 0;
    $correctionFactor[2] = 1;
    $correctionFactor[3] = 2;
    $correctionFactor[4] = 3;
    $correctionFactor[5] = 4;
    $correctionFactor[6] = 5;
    $correctionFactor[7] = 6;
    $correctionFactor[8] = 7;
    $correctionFactor[9] = 8;
    $correctionFactor[10] = 0;
    $correctionFactor[11] = 0;
    $correctionFactor[12] = 0;
    $correctionFactor[13] = 0;
    $correctionFactor[14] = 0;
    $correctionFactor[15] = 0;
    $correctionFactor[16] = 0;
    $correctionFactor[17] = 0;
    $correctionFactor[18] = 9;
    $correctionFactor[19] = 8;
    $correctionFactor[20] = 7;
    $correctionFactor[21] = 6;
    $correctionFactor[22] = 5;
    $correctionFactor[23] = 4;
    $correctionFactor[24] = 3;
    $correctionFactor[25] = 2;
    $correctionFactor[26] = 1;
    $correctionFactor[27] = 0;
    $correctionFactor[28] = 1;
    $correctionFactor[29] = 2;
    $correctionFactor[30] = 3;
    $correctionFactor[31] = 4;
    $correctionFactor[32] = 5;
    $correctionFactor[33] = 6;
    $correctionFactor[34] = 7;
    $correctionFactor[35] = 8;
    $correctionFactor[36] = 9;
    $correctionFactor[37] = 0;
    $correctionFactor[38] = 0;
    $correctionFactor[39] = 0;
    $correctionFactor[40] = 0;
    $correctionFactor[41] = 0;
    $correctionFactor[42] = 0;
    $correctionFactor[43] = 0;
    $correctionFactor[44] = 0;
    $correctionFactor[45] = 9;
    $correctionFactor[46] = 8;
    $correctionFactor[47] = 7;
    $correctionFactor[48] = 6;
    $correctionFactor[49] = 5;
    $correctionFactor[50] = 4;
    $correctionFactor[51] = 3;
    $correctionFactor[52] = 2;
    $correctionFactor[53] = 1;
    $correctionFactor[54] = 0;
    $correctionFactor[55] = 1;
    $correctionFactor[56] = 2;
    $correctionFactor[57] = 3;
    $correctionFactor[58] = 4;
    $correctionFactor[59] = 5;
    $correctionFactor[60] = 6;
    $correctionFactor[61] = 7;
    $correctionFactor[62] = 8;
    $correctionFactor[63] = 9;
    $correctionFactor[64] = 0;
    $correctionFactor[65] = 0;
    $correctionFactor[66] = 0;
    $correctionFactor[67] = 0;
    $correctionFactor[68] = 0;
    $correctionFactor[69] = 0;
    $correctionFactor[70] = 0;
    $correctionFactor[71] = 0;
    $correctionFactor[72] = 9;
    $correctionFactor[73] = 8;
    $correctionFactor[74] = 7;
    $correctionFactor[75] = 6;
    $correctionFactor[76] = 5;
    $correctionFactor[77] = 4;
    $correctionFactor[78] = 3;
    $correctionFactor[79] = 2;
    $correctionFactor[80] = 1;
    $correctionFactor[81] = 0;
    $correctionFactor[82] = 1;
    $correctionFactor[83] = 2;
    $correctionFactor[84] = 3;
    $correctionFactor[85] = 4;
    $correctionFactor[86] = 5;
    $correctionFactor[87] = 6;
    $correctionFactor[88] = 7;
    $correctionFactor[89] = 8;
    $correctionFactor[90] = 9;
    $correctionFactor[91] = 0;

    return @correctionFactor;
}

sub getFilter {
    my @correctionFactor = ();
    $correctionFactor[0] = 0;
    $correctionFactor[1] = 0;
    $correctionFactor[2] = 1;
    $correctionFactor[3] = 2;
    $correctionFactor[4] = 3;
    $correctionFactor[5] = 4;
    $correctionFactor[6] = 5;
    $correctionFactor[7] = 6;
    $correctionFactor[8] = 7;
    $correctionFactor[9] = 8;
    $correctionFactor[10] = 0;
    $correctionFactor[11] = 0;
    $correctionFactor[12] = 0;
    $correctionFactor[13] = 0;
    $correctionFactor[14] = 0;
    $correctionFactor[15] = 0;
    $correctionFactor[16] = 0;
    $correctionFactor[17] = 0;
    $correctionFactor[18] = 0;
    $correctionFactor[19] = 0;
    $correctionFactor[20] = 0;
    $correctionFactor[21] = 0;
    $correctionFactor[22] = 0;
    $correctionFactor[23] = 0;
    $correctionFactor[24] = 0;
    $correctionFactor[25] = 0;
    $correctionFactor[26] = 1;
    $correctionFactor[27] = 1;
    $correctionFactor[28] = 1;
    $correctionFactor[29] = 0;
    $correctionFactor[30] = 0;
    $correctionFactor[31] = 0;
    $correctionFactor[32] = 0;
    $correctionFactor[33] = 0;
    $correctionFactor[34] = 0;
    $correctionFactor[35] = 0;
    $correctionFactor[36] = 0;
    $correctionFactor[37] = 0;
    $correctionFactor[38] = 0;
    $correctionFactor[39] = 0;
    $correctionFactor[40] = 0;
    $correctionFactor[41] = 0;
    $correctionFactor[42] = 0;
    $correctionFactor[43] = 0;
    $correctionFactor[44] = 0;
    $correctionFactor[45] = 0;
    $correctionFactor[46] = 0;
    $correctionFactor[47] = 0;
    $correctionFactor[48] = 0;
    $correctionFactor[49] = 0;
    $correctionFactor[50] = 0;
    $correctionFactor[51] = 0;
    $correctionFactor[52] = 0;
    $correctionFactor[53] = 1;
    $correctionFactor[54] = 1;
    $correctionFactor[55] = 1;
    $correctionFactor[56] = 0;
    $correctionFactor[57] = 0;
    $correctionFactor[58] = 0;
    $correctionFactor[59] = 0;
    $correctionFactor[60] = 0;
    $correctionFactor[61] = 0;
    $correctionFactor[62] = 0;
    $correctionFactor[63] = 0;
    $correctionFactor[64] = 0;
    $correctionFactor[65] = 0;
    $correctionFactor[66] = 0;
    $correctionFactor[67] = 0;
    $correctionFactor[68] = 0;
    $correctionFactor[69] = 0;
    $correctionFactor[70] = 0;
    $correctionFactor[71] = 0;
    $correctionFactor[72] = 0;
    $correctionFactor[73] = 0;
    $correctionFactor[74] = 0;
    $correctionFactor[75] = 0;
    $correctionFactor[76] = 0;
    $correctionFactor[77] = 0;
    $correctionFactor[78] = 0;
    $correctionFactor[79] = 0;
    $correctionFactor[80] = 1;
    $correctionFactor[81] = 1;
    $correctionFactor[82] = 1;
    $correctionFactor[83] = 0;
    $correctionFactor[84] = 0;
    $correctionFactor[85] = 0;
    $correctionFactor[86] = 0;
    $correctionFactor[87] = 0;
    $correctionFactor[88] = 0;
    $correctionFactor[89] = 0;
    $correctionFactor[90] = 0;
    $correctionFactor[91] = 0;
    $correctionFactor[92] = 0;
    $correctionFactor[93] = 0;
    $correctionFactor[94] = 0;
    $correctionFactor[95] = 0;
    $correctionFactor[96] = 0;
    $correctionFactor[97] = 0;
    $correctionFactor[98] = 0;
    $correctionFactor[99] = 0;
    $correctionFactor[100] = 0;
    $correctionFactor[101] = 0;
    $correctionFactor[102] = 0;
    $correctionFactor[103] = 0;
    $correctionFactor[104] = 0;
    $correctionFactor[105] = 0;
    $correctionFactor[106] = 0;
    $correctionFactor[107] = 1;
    $correctionFactor[108] = 1;
    $correctionFactor[109] = 1;
    $correctionFactor[110] = 0;
    $correctionFactor[111] = 0;
    $correctionFactor[112] = 0;
    $correctionFactor[113] = 0;
    $correctionFactor[114] = 0;
    $correctionFactor[115] = 0;
    $correctionFactor[116] = 0;
    $correctionFactor[117] = 0;
    $correctionFactor[118] = 0;
    $correctionFactor[119] = 0;
    $correctionFactor[120] = 0;
    $correctionFactor[121] = 0;
    $correctionFactor[122] = 0;
    $correctionFactor[123] = 0;
    $correctionFactor[124] = 0;
    $correctionFactor[125] = 0;
    $correctionFactor[126] = 0;
    $correctionFactor[127] = 0;
    $correctionFactor[128] = 0;
    $correctionFactor[129] = 0;
    $correctionFactor[130] = 0;
    $correctionFactor[131] = 0;
    $correctionFactor[132] = 0;
    $correctionFactor[133] = 0;
    $correctionFactor[134] = 1;
    $correctionFactor[135] = 1;
    $correctionFactor[136] = 1;
    $correctionFactor[137] = 0;
    $correctionFactor[138] = 0;
    $correctionFactor[139] = 0;
    $correctionFactor[140] = 0;
    $correctionFactor[141] = 0;
    $correctionFactor[142] = 0;
    $correctionFactor[143] = 0;
    $correctionFactor[144] = 0;
    $correctionFactor[145] = 0;
    $correctionFactor[146] = 0;
    $correctionFactor[147] = 0;
    $correctionFactor[148] = 0;
    $correctionFactor[149] = 0;
    $correctionFactor[150] = 0;
    $correctionFactor[151] = 0;
    $correctionFactor[152] = 0;
    $correctionFactor[153] = 0;
    $correctionFactor[154] = 0;
    $correctionFactor[155] = 0;
    $correctionFactor[156] = 0;
    $correctionFactor[157] = 0;
    $correctionFactor[158] = 0;
    $correctionFactor[159] = 0;
    $correctionFactor[160] = 0;
    $correctionFactor[161] = 1;
    $correctionFactor[162] = 1;
    $correctionFactor[163] = 1;
    $correctionFactor[164] = 0;
    $correctionFactor[165] = 0;
    $correctionFactor[166] = 0;
    $correctionFactor[167] = 0;
    $correctionFactor[168] = 0;
    $correctionFactor[169] = 0;
    $correctionFactor[170] = 0;
    $correctionFactor[171] = 0;
    $correctionFactor[172] = 0;
    $correctionFactor[173] = 0;
    $correctionFactor[174] = 0;
    $correctionFactor[175] = 0;
    $correctionFactor[176] = 0;
    $correctionFactor[177] = 0;
    $correctionFactor[178] = 0;
    $correctionFactor[179] = 0;
    $correctionFactor[180] = 0;
    $correctionFactor[181] = 0;
    $correctionFactor[182] = 0;
    $correctionFactor[183] = 0;
    $correctionFactor[184] = 0;
    $correctionFactor[185] = 0;
    $correctionFactor[186] = 0;
    $correctionFactor[187] = 0;
    $correctionFactor[188] = 1;
    $correctionFactor[189] = 1;
    $correctionFactor[190] = 1;
    $correctionFactor[191] = 0;
    $correctionFactor[192] = 0;
    $correctionFactor[193] = 0;
    $correctionFactor[194] = 0;
    $correctionFactor[195] = 0;
    $correctionFactor[196] = 0;
    $correctionFactor[197] = 0;
    $correctionFactor[198] = 0;
    return @correctionFactor;
}


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}

