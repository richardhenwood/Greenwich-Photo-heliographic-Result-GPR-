package sunspot;
use strict;
use Date::Calc qw(Days_in_Month);
use Data::Dumper;
use diagnostics;
use warnings;
use Carp;
use vars qw( $AUTOLOAD );
use POSIX qw(ceil floor);
use Math::Trig;


my %sunspot = (
    raw_string => undef,
    year => undef,
    month => undef,
    day_of_month => undef,
    time_in_thousandths_of_day => undef,
    Greenwich_sunspot_group_number => undef,
    Mt_Wilson_magnetic_classification => undef,
    Greenwich_group_type => undef,  
    Observed_umbral_area_in_millionths_of_solar_disc => undef, 
    Observed_whole_spot_area_in_millionths_of_solar_disc => undef, 
    Corrected_umbral_area_in_millionths_of_solar_hemisphere => undef,  
    Corrected_whole_spot_area_in_millionths_of_solar_hemisphere => undef,  
    Distance_from_centre_of_solar_disc_in_solar_radii => undef,  
    Polar_angle_in_deg => undef,  
    Carrington_longitude => undef,  
    Latitude => undef,  
    Central_meridian_distance => undef 
);

sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my $self = {
        _permitted => \%sunspot,
        %sunspot,
    };
    bless $self, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) || croak "$self is not an object";
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    unless (exists $self->{_permitted}->{$name} ) {
        croak "Can't access `$name' field in object of class $type";
    }
    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

sub DESTROY {
    my $self = shift;
    my $Debugging = 0;
    if ($Debugging) { carp "Destroying $self " . $self->name }
}

#  the following is port of some javascript code which I have taken from
#  http://www.go.ednet.ns.ca/~larry/astro/sunspots.html
# it adds the hielographic axis to spots for their time.
my $radian = 180/pi;
my $B0r;
my $L0r;
my $Pr;        # global variables to be used in second calculation

sub truncate {
    my $angle = shift;
    my $n = floor($angle/360);
    my $tangle = $angle-$n*360;
    return $tangle;
}

sub calcJD {
    my $arr_ref = shift;
    my ( $y, $m, $d, $t) = @{$arr_ref};
    if ($m <= 2) {
        $y = $y - 1;
        $m = $m + 12;
    }   
    my $a = floor($y/100);
    my $b = 2 - $a + floor($a/4);
    $d += $t/24;
    my $jdg = floor(365.25*($y+4716))+floor(30.6001*($m+1))+$d+$b-1524.5;
    my $jd0 = floor($jdg+0.5)-0.5;
    return $jdg;
}
=begin comment

public double[] calc_solar(double jd) {
    double theta = (jd-2398220)*360/25.38;
    double inc = 7.25/radian;
    double k = (73.6667+1.3958333*(jd-2396758)/36525)/radian;
    double t = (jd-2451545)/36525;
    double t2=t*t;
    double t3=t*t2;
    double L0 = 280.46645+36000.76983*t+0.0003032*t2;
    double M = 357.52910+35999.05030*t-0.0001559*t2-0.00000048*t3;
    double Mr = M/radian;
    double C = (1.914600-0.004817*t-0.000014*t2)*Math.sin(Mr)+(0.019993-0.000101*t)*Math.sin(2*Mr)+0.000290*Math.sin(3*Mr);
    double sunL = L0+C;
    double v = M+C;
    double omega = 125.04-1934.136*t;
    double lngtd = sunL-0.00569-0.00478*Math.sin(omega/radian);
    double lngtdr = lngtd/radian;
    double diffk = (lngtdr-k);          // both in raidans
    double oblr = (23.4392911-0.0130042*t-0.0000164*t2+0.0000504*t3)/radian;
    double tx = - Math.cos(lngtdr)*Math.tan(oblr);
    double ty = - Math.cos(diffk)*Math.tan(inc);
    double x = Math.atan(tx);
    double y = Math.atan(ty);
    double Pr = (x + y);            //Postion angle
    double P = Pr*radian;
    double B0r =Math.asin( Math.sin(diffk)*Math.sin(inc));      //central latitude
    double B0 = B0r*radian;
    double etay = -Math.sin(diffk)*Math.cos(inc);
    double etax = -Math.cos(diffk);
    double eta = (Math.atan2(etay,etax))*radian;
    L0 = eta - theta;               // Longitude of center of disk
    L0 = truncate(L0);
    double L0r = L0/radian;
    double CarrNo = Math.floor((jd - 2398140.22710)/27.2752316);
    //    System.out.println("L0 = " + L0 + " Carr = " + CarrNo + " B0 = " + B0 + " P = " + P);
    double[] values = new double[4];
    values[0] = L0;
    values[1] = B0;
    values[2] = P;
    values[3] = CarrNo;
    return values;
}

public double[] calc_LBP(int y, int m, int d, double h) {
    return calc_solar(calcJD(y,m,d,h));
    // return;
}

private double[] lat_long(double rs, double r1, double pa1) {
    //   ROUTINE TO CALCULATE THE LAT, LONG OF SPOTS  uses radius and position angle, not x,y
    pa1 = pa1/radian;
    double r2 = Math.asin(r1/rs);
    double dp = (Pr - pa1);
    double B = Math.asin(Math.sin(B0r)*Math.cos(r2) + Math.cos(B0r)*Math.sin(r2)*Math.cos(dp));
    double L = Math.asin(Math.sin(r2)*Math.sin(dp)/Math.cos(B)) + L0r;
    L = radian * L;
    B = radian * B;
    double[] coord = new double[2];
    coord[0] = B;
    coord[1] = L;
    return coord;
}
//  end ported code    

=cut


1;
