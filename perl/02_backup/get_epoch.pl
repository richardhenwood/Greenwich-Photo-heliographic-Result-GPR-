#!/usr/bin/perl

use strict;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);

# this is a list of all the times when there is a storm - measured by greenwich.
my @epochs = qw(
1874-10-03
1880-08-12
1881-01-30
1881-09-12
1882-04-17
1882-04-20
1882-06-24
1882-08-04
1882-11-17
1882-11-20
1883-04-03
1883-09-16
1884-07-02
1885-03-15
1885-05-25
1886-03-30
1891-05-13
1892-03-11
1892-05-18
1893-08-18
1894-02-22
1894-02-25
1894-02-28
1894-03-30
1894-07-20
1894-08-20
1894-09-14
1894-11-13
1898-03-15
1898-09-09
1900-05-05
1903-10-31
1903-12-13
1907-02-09
1908-09-11
1908-09-29
1909-01-03
1909-05-14
1909-09-25
1915-06-17
1917-08-09
1917-08-13
1918-06-15
1918-08-09
1918-08-15
1919-08-11
1920-03-05
1920-03-22
1921-05-13
1926-01-26
1926-02-23
1926-04-14
1926-08-13
1927-07-12
1927-08-20
1927-10-12
1928-05-27
1928-07-07
1929-02-27
1929-03-11
1932-05-29
1937-02-03
1937-04-26
1937-04-27
1938-01-16
1938-01-22
1938-01-25
1938-04-16
1938-05-11
1939-02-24
1939-04-16
1939-04-24
1939-08-16
1939-08-22
1939-10-13
1940-03-24
1940-03-29
1940-03-31
1940-06-25
1941-03-01
1941-07-04
1941-09-18
1942-03-01
1944-12-15
1946-02-07
1946-03-23
1946-03-29
1946-04-23
1946-07-26
1946-09-21
1947-03-02
1947-04-17
1947-07-17
1947-08-22
1947-09-23
1948-08-08
1948-08-09
1948-10-17
1949-01-24
1949-01-25
1949-05-12
1949-10-15
1950-02-20
1950-08-18
1951-09-25
1951-10-28
1952-04-21
1952-06-29
);
#make_Sunspot("1874 511.526      88 0 7    0   27    0   44 0.954 294.5 244.8  21.9  69.4");
&Load_Data;

sub Load_Data {
    my @Dates_array = ();
    while (defined(my $line = <STDIN>)) {
        my @fields = split / /, $line;
        push(@Dates_array, \@fields);
    }

#    foreach my $arref (@Dates_array) {
#        my @data = @{$arref};
#        if (defined $data[3]) {
#            print $data[0] . "\n";
#        }
#    }

    my $daysBeforeEpoch = 50;
    my $daysAfterEpoch = 30;
    my %epochData = ();
    my $k = 0;
    for (my $i = 0; $i < scalar(@Dates_array); $i++) {
        my $arref = $Dates_array[$i];
        my @data = @{$arref};
#        print $epochs[$k] . " " . $data[0] . "\n";
        if ($data[0] eq $epochs[$k]) {
#            print "found : " . $epochs[$k];
#           my $filename = ">/users/rhenwood/ihr/sunspots/data/epoch/" . $data[0] . ".dat";
#            open(FH_DATE, $filename) || die ("couldn't open file: $!");
            for (my $j = -$daysBeforeEpoch; $j <= $daysAfterEpoch; $j++) {
                my $dataref = $Dates_array[$i + $j];
                my @Date = @{$dataref};
                #    print FH_DATE ("$j " . join ' ', @Date);
#                my @hashKey = ($epochs[$k], $j);
                $epochData{$j}{$epochs[$k]} = \@Date;
            }
            #close(FH_DATE);
            $k++;
        }
    }
#    print Dumper keys(%epochData);
    #for (my $j = -$daysBeforeEpoch; $j <= $daysAfterEpoch; $j++) {
        foreach my $hour ( sort numerically(keys(%epochData))) {
            my $latitudeAverage = 0;
            my $spotAreaTotal = 0;
            my $latMax = 0;
            my $latMin = 1;
            my $spotMax = 0;
            my $spotMin = 99999;
            my $spotCount = 0;
            my $spotCountMax = 0;
            my $spotCountMin = 99999;
            my @latArr = ();
            my @spotCountArr = ();
            my @spotAreaArr = ();
#            print Dumper %{$epochData{$hour}};
            foreach my $dataref ( values(%{$epochData{$hour}}) ) {
                my @Data = @{$dataref};
                $latitudeAverage += $Data[3];
                $spotAreaTotal += $Data[2];
                $spotCount += $Data[4];
                push (@latArr, $Data[3]);
                push (@spotCountArr, $Data[4]);
                push (@spotAreaArr, $Data[2]);
                if ($latMax < $Data[3]) {$latMax = $Data[3]}
                if ($latMin > $Data[3]) {$latMin = $Data[3]}
                if ($spotMax < $Data[2]) {$spotMax = $Data[2]}
                if ($spotMin > $Data[2]) {$spotMin = $Data[2]}
                if ($spotCountMax < $Data[4]) {$spotCountMax = $Data[4]}
                if ($spotCountMin > $Data[4]) {$spotCountMin = $Data[4]} 
            }
            print $hour;
#            print " " . ($latitudeAverage / ($daysAfterEpoch + $daysBeforeEpoch + 1)) * 1;
#            print " " . $latMax * 1;
#            print " " . $latMin * 1;
#            print " " . ($spotAreaTotal / ($daysAfterEpoch + $daysBeforeEpoch + 1)) * 1;
#            print " " . $spotMax * 1;
#            print " " . $spotMin * 1;
#            print " " . ($spotCount / ($daysAfterEpoch + $daysBeforeEpoch + 1)) * 1;
#            print " " . $spotCountMax * 1;
#            print " " . $spotCountMin * 1;
            print " " . join(' ', simple_stats(@latArr));
            print " " . join(' ', simple_stats(@spotAreaArr));
            print " " . join(' ', simple_stats(@spotCountArr)). "\n";
        }
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




