#!/usr/bin/perl

use strict;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Math::Trig qw(asin sec rad2deg deg2rad);

my @progress = qw( / - \ | );
&Load_Sunspots;

sub Load_Sunspots {
    my @sunspot_array = ();
	#print "loading data into array \n";
	my $count = 0;
    while (defined(my $line = <STDIN>)) {
		
#print $progress[$count % 3] . "\r"; $count++;
 #       push(@sunspot_array, make_Sunspot($line));
		my $spot = make_Sunspot($line);

		print $spot->year . "-" .
			trim($spot->month) . "-" .
			trim($spot->day_of_month) . " " . 
			$spot->Latitude . "\n";
#		$spot->getHeliographicPosition();
#		calculate_heliographic($spot);
    }
	
#	print "\ncalculating heliographic pole position and latitude\n";
#	foreach my $spot (@sunspot_array) {
#		print $progress[$count % 3] . "\r"; $count++;
	#	$spot->getHeliographicPosition();
#	}
#	print "\ncalculating heliographic position from clock angle\n";
#	foreach my $spot (@sunspot_array) {
#		print $progress[$count % 3] . "\r"; $count++;
	#	calculate_heliographic($spot);		
#	}
}

sub calculate_heliographic {
	my $spotRef = shift;
	my %spot = %{$spotRef};
	my $SunB0 = $spot{Sun_B0};
	my $SunL0 = $spot{Sun_L0};
	my $Sun_P = $spot{Sun_P};
    my $ki = $spot{Polar_angle_in_deg};

	#print Dumper $spotRef;
    my $day_of_year = (( $spot{month} - 1 ) * 12)+ $spot{day_of_month} - 1;

	my $SunSemiDiameter = &SunSemiDiameter($day_of_year) / 60;
	my $roe_dash = $spot{Distance_from_centre_of_solar_disc_in_solar_radii} * $SunSemiDiameter;
	my $roe = rad2deg(asin($spot{Distance_from_centre_of_solar_disc_in_solar_radii})) - $roe_dash;
	my $phi = cos(deg2rad($roe))*sin(deg2rad($SunB0)) + sin(deg2rad($roe))*cos(deg2rad($SunB0))*cos(deg2rad($ki));
	$phi = rad2deg(asin($phi));

	my $lamda = sin(deg2rad($ki))*sin(deg2rad($roe))*sec(deg2rad($phi));
	$lamda = $SunL0 - rad2deg(asin($lamda)) ;
	if ($lamda > 360.0) { $lamda = $lamda - 360 }
	print $spot{year} . "-".trim($spot{month})."-".trim($spot{day_of_month}). " " .$spot{Greenwich_sunspot_group_number} . " $phi " . $spot{Latitude} . " $lamda " . $spot{Carrington_longitude} . "\n";

}


my $PI = 3.1415967;
my $radian = 180/$PI;
my ($B0r, $L0r, $Pr);      

sub lat_long {
		my ($rs, $r1, $pa1) = shift;
        #   ROUTINE TO CALCULATE THE LAT, LONG OF SPOTS  uses radius and position angle, not x,y
        $pa1 = $pa1/$radian;
        my $r2 = asin($r1/$rs);
        my $dp = ($Pr - $pa1);
        my $B = asin(sin($B0r)*cos($r2) + cos($B0r)*sin($r2)*cos($dp));
        my $L = asin(sin($r2)*sin($dp)/cos($B)) + $L0r;
        $L = $radian * $L;
        $B = $radian * $B;
        return ($B, $L);
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


sub SunSemiDiameter {
	my $dayOfYear = shift;
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
    1944.416,
    1944.055,
    1943.684,
    1943.302,
    1942.911,
    1942.509,
    1942.098,
    1941.679,
    1941.252,
    1940.817,
    1940.376,
    1939.930,
    1939.478,
    1939.021,
    1938.561,
    1938.096,
    1937.629,
    1937.158,
    1936.685,
    1936.209,
    1935.731,
    1935.250,
    1934.767,
    1934.282,
    1933.793,
    1933.301,
    1932.806,
    1932.306,
    1931.801,
    1931.292,
    1930.776,
    1930.255,
    1929.728,
    1929.196,
    1928.658,
    1928.115,
    1927.568,
    1927.017,
    1926.464,
    1925.908,
    1925.351,
    1924.793,
    1924.235,
    1923.676,
    1923.119,
    1922.563,
    1922.008,
    1921.456,
    1920.906,
    1920.358,
    1919.813,
    1919.271,
    1918.731,
    1918.193,
    1917.657,
    1917.122,
    1916.588,
    1916.054,
    1915.520,
    1914.985,
    1914.450,
    1913.914,
    1913.376,
    1912.839,
    1912.301,
    1911.763,
    1911.227,
    1910.692,
    1910.159,
    1909.628,
    1909.101,
    1908.578,
    1908.059,
    1907.546,
    1907.037,
    1906.535,
    1906.039,
    1905.550,
    1905.068,
    1904.593,
    1904.126,
    1903.665,
    1903.210,
    1902.762,
    1902.319,
    1901.881,
    1901.447,
    1901.018,
    1900.592,
    1900.170,
    1899.750,
    1899.334,
    1898.922,
    1898.513,
    1898.108,
    1897.708,
    1897.312,
    1896.922,
    1896.537,
    1896.159,
    1895.788,
    1895.425,
    1895.069,
    1894.722,
    1894.384,
    1894.056,
    1893.738,
    1893.429,
    1893.131,
    1892.844,
    1892.566,
    1892.297,
    1892.038,
    1891.787,
    1891.544,
    1891.308,
    1891.079,
    1890.856,
    1890.639,
    1890.428,
    1890.223,
    1890.024,
    1889.830,
    1889.643,
    1889.462,
    1889.288,
    1889.121,
    1888.962,
    1888.810,
    1888.667,
    1888.533,
    1888.408,
    1888.293,
    1888.189,
    1888.096,
    1888.014,
    1887.944,
    1887.885,
    1887.839,
    1887.803,
    1887.778,
    1887.764,
    1887.758,
    1887.762,
    1887.775,
    1887.795,
    1887.822,
    1887.857,
    1887.898,
    1887.946,
    1888.000,
    1888.061,
    1888.128,
    1888.202,
    1888.283,
    1888.371,
    1888.466,
    1888.569,
    1888.681,
    1888.801,
    1888.930,
    1889.068,
    1889.217,
    1889.377,
    1889.547,
    1889.729,
    1889.923,
    1890.127,
    1890.343,
    1890.568,
    1890.804,
    1891.048,
    1891.301,
    1891.561,
    1891.829,
    1892.103,
    1892.384,
    1892.670,
    1892.962,
    1893.260,
    1893.562,
    1893.870,
    1894.183,
    1894.501,
    1894.825,
    1895.154,
    1895.489,
    1895.830,
    1896.177,
    1896.532,
    1896.894,
    1897.265,
    1897.644,
    1898.032,
    1898.429,
    1898.835,
    1899.251,
    1899.675,
    1900.107,
    1900.547,
    1900.993,
    1901.446,
    1901.904,
    1902.367,
    1902.834,
    1903.305,
    1903.779,
    1904.256,
    1904.736,
    1905.217,
    1905.701,
    1906.187,
    1906.675,
    1907.165,
    1907.657,
    1908.151,
    1908.648,
    1909.148,
    1909.651,
    1910.158,
    1910.669,
    1911.185,
    1911.707,
    1912.234,
    1912.767,
    1913.305,
    1913.847,
    1914.395,
    1914.946,
    1915.500,
    1916.056,
    1916.614,
    1917.174,
    1917.734,
    1918.293,
    1918.852,
    1919.410,
    1919.966,
    1920.521,
    1921.073,
    1921.622,
    1922.169,
    1922.713,
    1923.254,
    1923.793,
    1924.330,
    1924.865,
    1925.399,
    1925.932,
    1926.464,
    1926.996,
    1927.529,
    1928.063,
    1928.597,
    1929.132,
    1929.667,
    1930.202,
    1930.736,
    1931.269,
    1931.800,
    1932.328,
    1932.853,
    1933.373,
    1933.889,
    1934.400,
    1934.906,
    1935.405,
    1935.897,
    1936.382,
    1936.860,
    1937.330,
    1937.792,
    1938.247,
    1938.694,
    1939.135,
    1939.568,
    1939.995,
    1940.416,
    1940.833,
    1941.244,
    1941.651,
    1942.054,
    1942.453,
    1942.848,
    1943.239,
    1943.625,
    1944.006,
    1944.382,
    1944.751,
    1945.114,
    1945.470,
    1945.818,
    1946.157,
    1946.488,
    1946.809,
    1947.120,
    1947.421,
    1947.711,
    1947.989,
    1948.256,
    1948.511,
    1948.754,
    1948.986,
    1949.207,
    1949.417,
    1949.618,
    1949.810,
    1949.993,
    1950.167,
    1950.334,
    1950.494,
    1950.646,
    1950.791,
    1950.930,
    1951.060,
    1951.184,
    1951.299,
    1951.406,
    1951.505,
    1951.594,
    1951.674,
    1951.744,
    1951.803,
    1951.852        
);
    return $SunSemiDiameter[$dayOfYear % 364] / 120;
}



my @error_spots = qw/ 
87
96
99
100
109
111
115
121
124
127
134

151
155
160
162
184

194
196
224
225

238
240
*249 
261
264

282
291
*295

305
*312
316
319
332
*333
*346
355
357
367
368
393
400

404
*410
412
413
424
435
436
445
*455
458
460
481
485
503
516
561
568
581
592
614

664
587
597
702
703
705
726
728
729
759
762
777
787
788
808
817
846
848
868
872
875
876
877
*890
894
898
903

920
925
933
978
981
982
984
992
999
1000
1004
1027
1030
1040
1046
1052
1054
1056
1058
1064
1066
1067
*1068
1071
1074
1080
1094
1103
1107
1108
1109
1114
1122
1133
1135
1136
1142
1144
1149
*1156
1163
1172
1173
1177
1180
1197
1212
1216

*1231
1237
1251
1255
1267
1284
1285
1302
*1303
1308
1317
1330
1343
1351
1363
1369
1370
1371
1373
1381
1389
1393
1396
*1404
1419
1438
1444
1491
1495
1497
1498
1516
1520
1522
1532
1542
1556
1557

*1572
1573
1580
1587
1589
1592
1594
*1606
1614
1617
1619
1632
1653
1687
1690
1694
1710
1713
1714
1715
1717
1718
1722
1728
1733
1737
1738
1748
1754
1756
1763
1773
1783
1790

1821
1828
1833
1835
1847
*1848
1852
1860
1861
1874
1878
1884
1891
1901
1906

1978
1987
1993
1995
1999
2021
2024
/;


