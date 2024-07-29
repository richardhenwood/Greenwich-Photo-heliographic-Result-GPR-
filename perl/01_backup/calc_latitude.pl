#!/usr/bin/perl 

use strict;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Math::Trig qw(asin sec rad2deg deg2rad);

&Load_Data;

sub Load_Data {
    my @Dates_array = ();
    while (defined(my $line = <STDIN>)) {
        my @fields = split / /, $line;
        push(@Dates_array, \@fields);
    }
    foreach my $spot (@Dates_array) {
        calculate_position($spot);
        #print Dumper $spot;

    }
}

sub calculate_position {
    my $arr_ref = shift;
    my ($date,
        $CalculatedLatitude, 
        $CalculatedCentrealMeridianDistance, 
        $LatitudeDeg,
        $CarringtonLong,
        $SunL0,
        $SunB0,
        $SunP,
        $SunSemiDiameter,
        $distanceFromCentre,
        $positionAngle, 
        $spotNo) = @{$arr_ref};

        my $ki = $positionAngle;# - $SunP;
        #print Dumper $arr_ref;
        $SunSemiDiameter = $SunSemiDiameter / 60;
        my $roe_dash = $distanceFromCentre * $SunSemiDiameter;
        my $roe = rad2deg(asin($distanceFromCentre)) - $roe_dash;
        my $phi = cos(deg2rad($roe))*sin(deg2rad($SunB0)) + sin(deg2rad($roe))*cos(deg2rad($SunB0))*cos(deg2rad($ki));
        $phi = rad2deg(asin($phi));
        
        my $lamda = sin(deg2rad($ki))*sin(deg2rad($roe))*sec(deg2rad($phi));
        $lamda = $SunL0 - rad2deg(asin($lamda)) ;
        if ($lamda > 360.0) { $lamda = $lamda - 360 }
        print "$spotNo $date: phi = $phi ($LatitudeDeg)  lamda = $lamda ($CarringtonLong)\n";
}

sub simple_stats {
    my @data = @_;
#    print Dumper @data;
    my $size = @data;
    return unless $size;
    my ($sum_x, $sum_x2) = (0, 0);
    for (@data) {
        $sum_x  += $_;
        $sum_x2 += $_ ** 2;
    }
    my $mean  = $sum_x / $size;
    my $var   = ($sum_x2 - ($sum_x ** 2 / $size)) / ($size - 1);
    my $stdev = sqrt($var);
    return ($mean, $var, $stdev);
}

sub numerically {$b <=> $a;}

sub make_Sunspot { 
    my $data_string = shift;
    my $new_sunspot = new sunspot;
    $new_sunspot->raw_string($data_string);
    $new_sunspot->year(substr($data_string,0,4));
    $new_sunspot->month(substr($data_string,4,2)); 
    $new_sunspot->day_of_month(substr($data_string,6,2)); 
    $new_sunspot->time_in_thousandths_of_day(substr($data_string,8,4));
    $new_sunspot->Greenwich_sunspot_group_number(trim(substr($data_string,14,6)));
    $new_sunspot->Mt_Wilson_magnetic_classification(substr($data_string,21,1)); 
    $new_sunspot->Greenwich_group_type(substr($data_string,23,1)); 
    $new_sunspot->Observed_umbral_area_in_millionths_of_solar_disc(substr($data_string,24,5)); 
    $new_sunspot->Observed_whole_spot_area_in_millionths_of_solar_disc(substr($data_string,29,5)); 
    $new_sunspot->Corrected_umbral_area_in_millionths_of_solar_hemisphere(substr($data_string,34,5));
    $new_sunspot->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere(substr($data_string,39,5)); 
    $new_sunspot->Distance_from_centre_of_solar_disc_in_solar_radii(substr($data_string,45,5));  
    $new_sunspot->Polar_angle_in_deg(substr($data_string,51,5)); 
    $new_sunspot->Carrington_longitude(substr($data_string,57,5));
    $new_sunspot->Latitude(substr($data_string,63,5));
    $new_sunspot->Central_meridian_distance(substr($data_string,69,5));

    return $new_sunspot;
}

sub testSunspotForError_lookup {
    my $error_spots_ref = shift;
    #print Dumper $error_spots_ref;
    my @my_error_spots = @{$error_spots_ref};
    my $sunspots_ref = shift;
    my @sunspots = @{$sunspots_ref};
    foreach my $err_no (@my_error_spots) {
        foreach my $sunspot (@sunspots) {
            if ($sunspot->Greenwich_sunspot_group_number == $err_no) {
                print $sunspot->raw_string;
                #           print Dumper $sunspot;
            }
        }
    }
}

# this method only counts sunspots every day. 
# it calculates the sunspot number using:
#  R = K (10G + I)
# K = 1 (instrumental factor) 
# G = number of sunspot groups visable on the sun
# I = total number of individual spots visible (weather in groups or not)
# spot type definitions are available in 
# http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt
sub meanSunspotNumber {
    my $sunspot_ref = shift;
    my @sunspots = @{$sunspot_ref};
    foreach my $year (1874 .. 1976) {
        my $numberOfSpots = 0;
        #my $lastSpotNo = $sunspots[0]->Greenwich_sunspot_group_number();
        foreach my $sunspot (@sunspots) {
            if ($sunspot->year() == $year) {
                my $spotType = $sunspot->Greenwich_group_type();
                if ($spotType >= 1) {
                    $numberOfSpots += 10;
                }
#                else {
                    $numberOfSpots++;
#                }
            }
        }
        my $meanSpotNumber = $numberOfSpots / Days_in_Year($year, 12);
        print "$year $meanSpotNumber\n";
    }
}

# this method only counts sunspot groups once. 
sub countSunspotsYear {
    my $sunspot_ref = shift;
    my @sunspots = @{$sunspot_ref};
    foreach my $year (1874 .. 1976) {
        my $numberOfSpots = 0;
        my $lastSpotNo = $sunspots[0]->Greenwich_sunspot_group_number();
        foreach my $sunspot (@sunspots) {
            if ($sunspot->year() == $year) {
                my $thisSpotNo = $sunspot->Greenwich_sunspot_group_number();
                if ($thisSpotNo != $lastSpotNo) {
                    $numberOfSpots++;
                    $lastSpotNo = $sunspot->Greenwich_sunspot_group_number();
                }
            }
        }
        print "$year $numberOfSpots\n";
    }
}

# this is a pretty poor method of calculating sunspots.
# it should be done but counting single spots once (from the 
# sunspot number), this counts all the spots for a given day.
sub calculateYearlyMeans {
    my $sunspot_ref = shift;
    my @sunspots = @{$sunspot_ref};
#    my @yeardate = ();
    foreach my $year (1874 .. 1976) {
        my @yearvalues = ();
        my @yeardate = ($year, 1, 1);
        foreach my $dayofyear (1 .. Days_in_Year($year, 12)) {
            @yeardate = Add_Delta_Days(@yeardate, 1);
            my $sunspotsPerDay = 0;
            foreach my $sunspot (@sunspots) {
                if ($sunspot->year == $yeardate[0] &&
                    $sunspot->month == $yeardate[1] &&
                    $sunspot->day_of_month == $yeardate[2] ) {
                    $sunspotsPerDay++;
                }
            }
            if ($sunspotsPerDay != 0) {
                push @yearvalues, $sunspotsPerDay;
            }
            
        }
        print $year . " "; 
        if (scalar(@yearvalues) != 0) {
            print calculateMean(\@yearvalues);
        }
        print "\n";
    }
}

sub calculateMean {
    my $ref = shift;
    my @array = @{$ref};
    my $sum = sum(@array);
    
    return $sum / scalar @array;
}

sub getMedian {
    my $ref = shift;
    my @array = @{$ref};
    my $count = scalar @array;
    if ($count == 0) { # no values to compute median from.
        return "   ";
    }
    if (($count % 2) == 0) { #even number of elements
        my $tmp = (sort { $a <=> $b } @array)[int($#array) / 2];
        $tmp = $tmp + (sort { $a <=> $b } @array)[int($#array + 1) / 2];
        $tmp = $tmp / 2;
        return $tmp;
    }
    else { # odd number of elements
        my $tmpMed = (sort { $a <=> $b } @array) [$#array / 2];
        return $tmpMed;
    }
}


sub trim ($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


=begin comment
private double SunSemiDiameter(int dayOfYear) {
    return SunSemiDiameter[dayOfYear % 364] / 120;
}

=cut
my @SunSemiDiameter = 
(
    1951.753,
    1951.770,
    1951.778,
    1951.778,
    1951.770,
    1951.753,
    1951.727,
    1951.692,
    1951.646,
    1951.590,
    1951.523,
    1951.444,
    1951.353,
    1951.249,
    1951.132,
    1951.002,
    1950.859,
    1950.704,
    1950.536,
    1950.357,
    1950.168,
    1949.969,
    1949.761,
    1949.543,
    1949.318,
    1949.085,
    1948.845,
    1948.597,
    1948.343,
    1948.083,
    1947.816,
    1947.542,
    1947.263,
    1946.976,
    1946.683,
    1946.383,
    1946.076,
    1945.761,
    1945.439,
    1945.107,
    1944.766,


