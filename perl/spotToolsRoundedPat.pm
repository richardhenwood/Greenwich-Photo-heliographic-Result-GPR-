package spotTools;
use roundedEph;
use strict;
use warnings;
use Data::Dumper;
use Math::Trig;
use POSIX;

# this package is a library of tools to be used on sunspots
# They are dependent on the ephemeris code.

# create an empemerisis - this will come in handy throughout!
my $ephmis = new pmeph;

sub calculateLBP {
    my $self = shift;
    my $spot = shift;
    my $datestr = sprintf("%04d/%02d/%02d %02d:%02d:00",
        $spot->getYear(),
        $spot->getMonth(),
        $spot->getDayOfMonth(),
        $spot->getHour(),
        $spot->getMinute());
    my $ephemFile = "./1874_1955_inc_stations.dat";
    #print "datestr from pat = $datestr\n";
    my $ephemline = `grep '$datestr' $ephemFile`;
    chomp $ephemline;
    my @eph = split (/ +/, $ephemline);
    if (scalar @eph < 6) {
        die "can't find data for $datestr";
    }
    #print $eph[3];
    #print ", ";
    #print $eph[4];
    #print ", ";
    #print $eph[5];
    #print ", ";
    #print $eph[6];
    #print "\n";

    $spot->putSun_L0($eph[5]);
    $spot->putSun_B0($eph[4]);
    $spot->putSun_P($eph[3]);
    $spot->putSun_S($eph[6]);

    #exit 0;

    #my ($L_, $B_, $P_, $C_, $Cd_, $S_) = $ephmis->calc_LBP(
    #    $spot->getYear(),
    #    $spot->getMonth(),
    #    $spot->getDayOfMonth(),
    #    $spot->getHour(),
    #    $spot->getMinute(),
    #    $spot->getSecond());
    #$spot->putSun_L0($L_);
    #$spot->putSun_B0($B_);
    #$spot->putSun_P($P_);
    #$spot->putSun_S($S_);
    #print "spot is spot = " . $spot->is_spot();
    return $spot;
}

# ROUTINE TO CALCULATE THE LAT, LONG OF SPOTS uses radius and position angle, not x,y
# this is coded uses the formula given in the books.
sub calculate_heliographic {
    my $self = shift;
	my $spot = shift;
    #print $spot->raw_string;
    my $roe = deg2rad(&calculate_roe($self, $spot));
    my $sunB0 = deg2rad($spot->getSun_B0);
    my $ki = deg2rad($spot->getPositionAngle());
    my $phi = cos($roe)*sin($sunB0) +
        sin($roe)*cos($sunB0)*cos($ki);   
    $phi = asin($phi);
    my $lamda = sin($ki)*sin($roe)*sec($phi);
    $lamda = -1 * asin($lamda);
    $spot->putCalculatedLatitude(rad2deg($phi));
    $spot->putCalculatedLongitude(rad2deg($lamda));
    $spot->putCalculatedCarringtonLongitude(rad2deg($lamda)+$spot->getSun_L0);
    $spot->putCalculatedCMD(rad2deg($lamda));
    return $spot;
}

# returns a value of roe for a given spot.
# roe is returned in degrees.

# this equation is found in the greenwich report books
sub calculate_roe {
    my $self = shift;
    my $spot = shift;
    my $sunS = deg2rad($spot->getSun_S() / (60*60));
    my $r_over_R = $spot->getSolarRadii;
    my $roe_dash = $r_over_R * $sunS;
    my $roe = asin($r_over_R) - $roe_dash;
    return rad2deg($roe);
}

sub calculateProjectedArea {
    my $self = shift;
    my $spot = shift;
    my $roe = deg2rad(&calculate_roe($self, $spot));
    my $area = $spot->getCorrectedUmbralArea();
#    print "area = '$area' roe = '$roe'\n";
    $spot->putCalculatedProjectedUmbralArea(2 * $area * cos($roe));
    $area = $spot->getCorrectedWholeSpotArea();
    $spot->putCalculatedProjectedWholeSpot(2 * $area * cos($roe));
}
sub calculateCorrectedArea {
    my $self = shift;
    my $spot = shift;
    my $roe = deg2rad(&calculate_roe($self, $spot));
    my $area = $spot->getProjectedUmbralArea();
#    print "area = '$area' roe = '$roe'\n";
    $spot->putCalculatedCorrectedUmbralArea(2 * $area / cos($roe));
    $area = $spot->getProjectedWholeSpotArea();
    $spot->putCalculatedCorrectedWholeSpot(2 * $area / cos($roe));
}
sub calculateProjectedAreaFaculae {
    my $self = shift;
    my $spot = shift;
    my $roe = deg2rad(&calculate_roe($self, $spot));
    my $area = $spot->getFaculaeArea();
#    print "area = '$area' roe = '$roe'\n";
    $spot->putCalculatedProjectedFaculaeArea(2 * $area * cos($roe));
}

sub calculate_projected_wholespot {
    my $self = shift;
    my $spot = shift;
    
}

# calculate the helioprojective position of a spot from the 
# heliographic position.
sub calculate_helioprojective {
    my $self = shift;
	my $spot = shift;

# This code is based on a method by D Willis, recorded in the 
# filing cabenet in Richard Henwoods' office.

    my $xlam = -$spot->getCentralMeridianDistance;   # step 1
    #my $xlam = -$spot->getCalculatedCMD;   # step 1
    my $xphi = $spot->getLatitude;   # step 1
    my $xB0 = $spot->getSun_B0;   # step 1
    my $sunS = $spot->getSun_S;
    #print "suns = $sunS\n";

    #print "sun B0 = $xB0\n\n";
    #print "latitude = $xphi\n\n";
    #print "cmd  = $xlam\n\n";

    my $t = pi/180;
    my $a = sin($t*$xphi);
    my $b = sin($t*$xB0);
    my $x = $a*$b;
    my $c = cos($t*$xB0);
    my $d = $c*cos($t*$xphi)*cos($t*$xlam);
    my $y = $x+$d;
    #my $z = $x-$d;

    my $yrho = acos($y)/$t; #  step 3
    #my $zrho = acos($z)/$t; #  step 3

    my $ytemp = cos($t*$xphi)*sin($t*$xlam)/sin($t*$yrho);
    #my $ztemp = cos($t*$xphi)*sin($t*$xlam)/sin($t*$zrho); 
    my $ychi   = asin($ytemp)/$t; # step 4
    my $zchi = 180 - $ychi;
    #my $zchi   = asin($ztemp)/$t; # step 4

    #my $ytc = 0.999;
    #eval {
    #   my $ytc = sin($t*$xlam)/($c*($a/cos($t*$xphi)) - $b*cos($t*$xlam));
    #};
    #if ($@) {
    #    #my $ytc = 0.999;
    #    print "problem\n";
    #}

    my $ytc = sin($t*$xlam)/($c*($a/cos($t*$xphi)) - $b*cos($t*$xlam));
    my $y2chi = atan($ytc)/$t; # step 2

    if ($y2chi < 0) {
        $y2chi += 180.0;
    }
    my $z2chi = $y2chi + 180.0;

    #print "atan chi = $y2chi $z2chi\n";

    #print "rho, cos rho = $y $yrho\n";

    if ($ychi < 0) {
        $ychi += 360;
    }
    #print "eta? chi  = $ychi $zchi\n";
    #print "also chi  = " + (360 + $ychi) + "\n";

    my $correctChi = $y2chi;
    if (abs($z2chi - $ychi) < 0.00001) {
        $correctChi = $z2chi;
        #print "adjusing chi\n";
    }
    elsif (abs($z2chi - $zchi) < 0.00001) {
        $correctChi = $z2chi;
        #print "adjusing chi\n";
    }


    #print "correct chi = $correctChi\n";

    #print "sun _s = " . $sunS/(60*60);
    #print "\n";

    my $roverR = &newtonMethod($yrho, $sunS/(60*60), 0.5, 0.0001); 
    #print "recorded value: " . $spot->getSolarRadii();
    #print "\n";
    #print "r/R= " . $roverR;
    #print "\n";
    $spot->putCalculatedRadialDistanace($roverR);
    $spot->putCalculatedClockAngle($correctChi);

    return $spot;
}

sub newtonMethod {
    my ($rho, $s, $rR, $tolerance) = @_;
    my $rRdash = rand();
    #print "rho = " . ($rho/pi*180);
    #print "start values = $rho ($rRdash), $s, $rR, $tolerance\n";
    while (1) { #abs($rRdash - $rR) > $tolerance) {
        #    print "rR = $rR ($rRdash)\n";
        $rRdash = sin(($rR*$s+$rho)*pi/180);
        #print "rR = $rR ($rRdash)\n";
        if (abs($rRdash - $rR) < $tolerance) {
            last;
        }
        $rR = $rRdash;
    }
    #print "found value: $rR, $rRdash\n";
    return $rRdash;
}

## THis is the first way to perform the calculation,
## it was origionally coded from the maths derived a few years ago:
## ~ 2006/7/8 ish.
## I believe it has an error. the sign during calculation of ytemp and ztemp.
## A newer version (above) has corrected this.
##
## # calculate the helioprojective position of a spot from the 
## # heliographic position.
## sub calculate_helioprojective {
##     my $self = shift;
## 	my $spot = shift;
## 
## # This code is based on a method by D Henwood, recorded in the 
## # filing cabenet in Richard Henwoods' office.
## 
##     my $xlam = $spot->getCentralMeridianDistance;
##     my $xphi = $spot->getLatitude;
##     my $xB0 = $spot->getSun_B0;
## 
##     #print "sun B0 = $xB0\n\n";
##     my $t = pi/180;
##     my $a = sin($t*$xphi);
##     my $b = sin($t*$xB0);
##     my $x = $a*$b;
##     my $c = cos($t*$xB0);
##     my $d = $c*cos($t*$xphi)*cos($t*$xlam);
##     my $y = $x+$d;
##     my $z = $x-$d;
## 
##     my $yrho = acos($y)/$t;
##     my $zrho = acos($z)/$t;
## 
##     my $ytemp = -cos($t*$xphi)*sin($t*$xlam)/sin($t*$yrho);
##     my $ztemp = -cos($t*$xphi)*sin($t*$xlam)/sin($t*$zrho); 
##     my $ypsi   = asin($ytemp)/$t;
##     my $zpsi   = asin($ztemp)/$t;
## 
##     my $r1 = $a-$b*cos($t*$zrho)-$c*sin($t*$zrho)*cos($t*$zpsi);
##     my $yr = abs($r1);
## 
##     my $r2 = $a-$b*cos($yrho)-$c*sin($yrho)*cos($ypsi);
##     my $zr = abs($r2);
## 
##     my $angle;
##     my $north = $yr * 1.0;
##     if ($north < 0.5) {
##         $angle = (360 + $ypsi);
##     }
##     else {
##         $angle = (180 - $ypsi);
##     }
## 
##     if ($angle > 360) {
##         $angle -= 360;
##     }
##     my $radii = sin(deg2rad($yrho));
##     #printf ("\n%5.3f %5.3f %5.3f %5.3f %5.3f %5.3f %5.3f\n", $yrho, $ypsi, $yr, $zrho, $zpsi, $zr, $xB0 );
##     $spot->putCalculatedRadialDistanace($radii);
##     $spot->putCalculatedClockAngle($angle);
## 
##     return $spot;
## }

sub sf4 { 
    my $n = shift;
    return floor($n*100)/100;
}

sub new { return bless{};}

1;
