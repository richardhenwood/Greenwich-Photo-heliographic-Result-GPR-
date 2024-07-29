#!/usr/bin/perl

use strict;
use sunspot;
use Data::Dumper;
use lib '../';
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Math::Trig;
use POSIX qw(ceil floor);
use subs qw( truncate );

my @progress = qw( / - \ | );
my $radian = 180/3.14159;
my ($B0r, $L0r, $Pr);

#&Load_Sunspots;
&calculate_heliographic; 

sub calculate_heliographic {
    my $ki = 0;
    my $r_ovr_R = 0;


    foreach my $day_of_year (1 .. 365) {
 
# do the calculations for year = jan 1 1951
       my $julian_day = 2433648;
        my ($SunB0, $SunL0, $Sun_P) = calc_solar($julian_day + $day_of_year);
        my $SunSemiDiameter = &SunSemiDiameter($day_of_year) / 60;
        my $roe_dash = $r_ovr_R * $SunSemiDiameter;
        my $roe = rad2deg(asin($r_ovr_R)) - $roe_dash;
        my $phi = cos(deg2rad($roe))*sin(deg2rad($SunB0)) + sin(deg2rad($roe))*cos(deg2rad($SunB0))*cos(deg2rad($ki));
        $phi = rad2deg(asin($phi));

        my $lamda = sin(deg2rad($ki))*sin(deg2rad($roe))*sec(deg2rad($phi));
        $lamda = $SunL0 - rad2deg(asin($lamda));
        if ($lamda > 360.0) { $lamda = $lamda - 360 }
        if ($lamda < 0.0) { $lamda = $lamda + 360 }

        print "$day_of_year $SunL0 $SunB0 $Sun_P $SunSemiDiameter $roe $phi $lamda  \n";
    }
}


sub truncate {
    my $angle = shift;
    my $n = floor($angle/360);
    my $tangle = $angle-$n*360;
    return $tangle;
}

sub calc_solar {
    my $jd = shift;
    my $theta = ($jd-2398220)*360/25.38;
    my $inc = 7.25/$radian;
    my $k = (73.6667+1.3958333*($jd-2396758)/36525)/$radian;
    my $t = ($jd-2451545)/36525;
    my $t2=$t*$t;
    my $t3=$t*$t2;
    my $L0 = 280.46645+36000.76983*$t+0.0003032*$t2;
    my $M = 357.52910+35999.05030*$t-0.0001559*$t2-0.00000048*$t3;
    my $Mr = $M/$radian;
    my $C = (1.914600-0.004817*$t-0.000014*$t2)*sin($Mr)+(0.019993-0.000101*$t)*sin(2*$Mr)+0.000290*sin(3*$Mr);
    my $sunL = $L0+$C;
    my $v = $M+$C;
    my $omega = 125.04-1934.136*$t;
    my $lngtd = $sunL-0.00569-0.00478*sin($omega/$radian);
    my $lngtdr = $lngtd/$radian;
    my $diffk = ($lngtdr-$k);           # both in raidans
    my $oblr = (23.4392911-0.0130042*$t-0.0000164*$t2+0.0000504*$t3)/$radian;
    my $tx = - cos($lngtdr)*tan($oblr);
    my $ty = - cos($diffk)*tan($inc);
    my $x = atan($tx);
    my $y = atan($ty);
    my $Pr = ($x + $y);         #Postion angle
    my $P = $Pr*$radian;
    my $B0r = asin( sin($diffk)*sin($inc));     #central latitude
    my $B0 = $B0r*$radian;
    my $etay = -sin($diffk)*cos($inc);
    my $etax = -cos($diffk);
    my $eta = (atan2($etay,$etax))*$radian;
    $L0 = $eta - $theta;              # Longitude of center of disk
    $L0 = truncate($L0);
    my $L0r = $L0/$radian;
    my $CarrNo = ($jd - 2398140.22710)/27.2752316;
    #print "carr no = $CarrNo L0 = " . $L0 . " B0 = " . $B0 . " P = " . $P . "\n";
    return ($L0, $B0, $P, floor($CarrNo));
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
