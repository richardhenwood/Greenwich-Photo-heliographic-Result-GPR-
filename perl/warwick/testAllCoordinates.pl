#!/usr/bin/perl

use strict;
use warnings;
use lib '../external_libs/';
use lib '../';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
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

This program tests the maths for converting from polar the helioprojective
and visa versa.
It generates a value for every polar angle step

-d      : date in form 'YYYY-MM-DD hh:mm'
-p      : size of step, in degrees
-r      : radial distance step, must be less than one

example: $0 -d '1938-01-02 08:28' -p 1 -r 0.1 
EOF
    exit;
}

my %opts = ();
getopts("d:p:r:t:c:l:f:", \%opts) ;
if (!defined($opts{d}) && !defined($opts{f})) { usage(); }

my %sunspots = ();

if (defined($opts{p}) && defined($opts{r})) {
    for (my $curAngle = 0; $curAngle < 360.0; $curAngle += $opts{p}) {
        for (my $curRad = 0; $curRad < 1.0; $curRad += $opts{r}) {
            %sunspots = &Construct_Sunspot_PolarAngle($opts{d}, $curAngle, $curRad);
            my ($calLat, $calLong, $calCMD) = &getDifferenceFromRadial();
            %sunspots = &Construct_Sunspot_LatLong($opts{d}, $calLat, $calLong);
            my ($calAngle, $calRadial) = &printCalculatedRadial();
            my $angDiff = abs($curAngle - $calAngle);
            if ($angDiff > 180) {
                $angDiff -= 360;
            }
            my $radDiff = ($curRad - $calRadial);
            printf("point %2d %6.4f anglediff = %9.4f radDiff = %7.4f rgbAngle = %d %d %d rgbRadial = %d %d %d\n", $curAngle, $curRad, $angDiff, $radDiff, &makeRGB($angDiff, 180), &makeRGB($radDiff, 180));
        }
    }
}
elsif (defined($opts{t}) && defined($opts{c})) {
    for (my $curCMD = -90; $curCMD < 90; $curCMD += $opts{c}) {
        for (my $curLat = -90; $curLat < 90; $curLat += $opts{t}) {
            %sunspots = &Construct_Sunspot_LatCMD($opts{d}, $curLat, $curCMD);
            my ($calAngle, $calRadial) = &getDifferenceFromCMD();
            %sunspots = &Construct_Sunspot_PolarAngle($opts{d}, $calAngle, $calRadial);
            my ($calLat, $calCMD) = &printCalculatedLatCMD();
            my $latDiff = abs($curLat - $calLat);
            my $CMDdiff = abs($curCMD - $calCMD);
            printf("point %2d %6.4f latdiff = %9.4f CMDdiff = %7.4f rgbLat = %d %d %d rgbCMD = %d %d %d\n", $curLat, $curCMD, $latDiff, $CMDdiff, &makeRGB($latDiff, 20), &makeRGB90($CMDdiff, 90));
        }
    }

    #&printCalculatedRadial();
}
#elsif (defined($opts{t}) && defined($opts{l})) {
#    %sunspots = &Construct_Sunspot_LatLong($opts{d}, $opts{t}, $opts{l});
#    &printCalculatedRadial();
#}
else {
    &usage();
}

sub makeRGB {
    my ($value, $max) = @_;
    if ($value >= 0) {
        return (($value/$max)*254, 0, 0);
    }
    return (0, 0, abs(($value/$max)*254));

}

sub makeRGB180 {
    my $angle = shift;
    if ($angle >= 0) {
        return (($angle/180)*254, 0, 0);
    }
    return (0, 0, abs(($angle/180)*254));

}
sub makeRGB90 {
    my $angle = shift;
    if ($angle >= 0) {
        return (($angle/90)*254, 0, 0);
    }
    return (0, 0, abs(($angle/90)*254));

}

sub getDifferenceFromCMD {
    my ($calAngle, $calRadial);
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                $calRadial = $spot->getCalculatedRadialDistanace;
                $calAngle = $spot->getCalculatedClockAngle;
            }
        }
    }
    return ($calAngle, $calRadial);
}

    
sub getDifferenceFromRadial {
    my ($calLat, $calLong, $calCMD);
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                $calLat = $spot->getCalculatedLatitude;
                $calLong = $spot->getCalculatedCarringtonLongitude;
                $calCMD = $spot->getCalculatedLongitude;
            }
        }
    }
    return ($calLat, $calLong, $calCMD);
}

    

sub printCalculatedLatCMD {
    my ($calLat, $calCMD);
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #print $spot->getDateTime;
                #print " r/R = ";
                #print $spot->getSolarRadii;
                #print " angle = ";
                #print $spot->getPositionAngle;
                #print " c_latitude = ";
                #printf "%5.3f", $spot->getCalculatedLatitude;
                #print " c_longitude = ";
                #printf "%5.3f", $spot->getCalculatedCarringtonLongitude;
                #print " c_CMD = ";
                #printf "%5.3f", $spot->getCalculatedLongitude;
                #print "\n";
                $calLat = $spot->getCalculatedLatitude;
                $calCMD = $spot->getCalculatedLongitude;
            }
        }
    }
    return ($calLat, $calCMD);
}


sub printCalculatedRadial {
    my ($calAngle, $calRadial);
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                #print $spot->getDateTime;
                #print " lat = ";
                #print $spot->getLatitude;
                #print " cmd = ";
                #printf "%5.2f", $spot->getLongitude;
                #print " long = ";
                #printf "%5.2f", $spot->getCarringtonLongitude;
                #print " c_r/R = ";
                #printf "%6.3f", $spot->getCalculatedRadialDistanace;
                #print " c_angle = ";
                #printf "%5.2f", $spot->getCalculatedClockAngle;
                $calRadial = $spot->getCalculatedRadialDistanace;
                $calAngle = $spot->getCalculatedClockAngle;
                #print "\n";
            }
        }
    }
    return ($calAngle, $calRadial);
}
sub printDateCentricSpots {
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


sub Construct_Sunspot_PolarAngle {
    my ($date, $polar, $radial) = @_;
    my %sunspot_array = ();
    my @date = split(/[- :]/, $date);
    my $decHour = ($date[3]/24.0) + ($date[4]/60.0)*(1/24.0);
    $date[3] = $decHour*1000;
    #print "radial = '$radial'";
    my $sunspotStr = sprintf("%4d%2d%2d.%3d       0 0 0    0    0    0    0 %5.3f %5.1f     0     0   0.0\n", @date[0..3], $radial, $polar);
    my $test_spot = new sunspot;
    $test_spot->parse_data_into_object($sunspotStr);
    push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}}, $test_spot);

    return %sunspot_array;
}

sub Construct_Sunspot_LatCMD {
    my ($date, $lat, $cmd) = @_;
    my %sunspot_array = ();
    my @date = split(/[- :]/, $date);
    my $decHour = ($date[3]/24.0) + ($date[4]/60.0)*(1/24.0);
    $date[3] = $decHour*1000;
    #print "radial = '$radial'";
    my $sunspotStr = sprintf("%4d%2d%2d.%3d       0 0 0    0    0    0    0 0.0     0.0   0.0 %5.1f %5.1f\n", @date[0..3], $lat, $cmd);
    my $test_spot = new sunspot;
    $test_spot->parse_data_into_object($sunspotStr);
    #print "$sunspotStr";
    
    push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}}, $test_spot);

    return %sunspot_array;
}


sub Construct_Sunspot_LatLong {
    my ($date, $lat, $long) = @_;
    my %sunspot_array = ();
    my @date = split(/[- :]/, $date);
    my $decHour = ($date[3]/24.0) + ($date[4]/60.0)*(1/24.0);
    $date[3] = $decHour*1000;
    #print "long = '$long'";
    my $sunspotStr = sprintf("%4d%2d%2d.%3d       0 0 0    0    0    0    0 0.0     0.0 %5.1f %5.1f   0.0\n", @date[0..3], $long, $lat );
    my $test_spot = new sunspot;
    $test_spot->parse_data_into_object($sunspotStr);
    #print "$sunspotStr";
    my $SunL0 = $test_spot->getSun_L0();
    #my $long = $spot->getCarringtonLongitude;
    my $pi = 3.14159265358979323846264338327950288419;
    #print "sun l0 = $SunL0 ";
    #print "\n\nl0 = $long " . ($long - $SunL0) . "\n";# - 360*$SunL0/(2*$pi)) . "\n";

    $test_spot->putLongitude($long - $SunL0);

    push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}}, $test_spot);

    return %sunspot_array;
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

