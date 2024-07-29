package sunspot;
use strict;
use Date::Calc qw(Days_in_Month);
use Data::Dumper;
use diagnostics;
use warnings;
use Carp;
use vars qw( $AUTOLOAD );
use subs qw( truncate );
my $PI = 3.14159;
use Math::Trig;
use POSIX qw(ceil floor);

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
    Central_meridian_distance => undef,
	Sun_B0 => undef,
	Sun_L0 => undef,
	Sun_P => undef,
	Carrington_number => undef
);

sub getActualClockAngle {
	my $self = shift;
	return $self->Polar_angle_in_deg / 360 * 2 * $PI;
}
sub getCalculatedClockAngle {
	my $self = shift;
	my $x_pos = sin $self->Central_meridian_distance;
	my $y_pos = sin $self->Latitude;
	my $calculated_clock_angle = atan2 ($y_pos, $x_pos);	
	return $calculated_clock_angle;
}

sub getLatitudeValue {
    my $self = shift;
    print $self->Latitude;
}

# need to implement this 
sub getCalculatedLatitude {
    my $self = shift;
}

sub fixTime {
	my $timeString = shift;
	#print substr ($timeString, 1, 1);
	if ( substr ($timeString, 1, 1) eq ' ') {
		return substr($timeString, 1) / 1000;
		#print "problem time: " . $timeString;
	}
	return $timeString;
}

sub getHeliographicPosition {
	my $self = shift;
	$self->{time_in_thousandths_of_day} = fixTime($self->time_in_thousandths_of_day);
	#print $self->time_in_thousandths_of_day;
	#print "hello!";
	($self->{Sun_L0}, $self->{Sun_B0}, $self->{Sun_P}, $self->{Carrington_number}) = calc_LBP($self->year, $self->month, $self->day_of_month, $self->time_in_thousandths_of_day * 24);
}

#  the following is port of some javascript code which I have taken from
#  http://www.go.ednet.ns.ca/~larry/astro/sunspots.html
my $radian = 180/pi;
my ($B0r, $L0r, $Pr);		# global variables to be used in second calculation

sub truncate {
	my $angle = shift;
    my $n = floor($angle/360);
    my $tangle = $angle-$n*360;
    return $tangle;
}
     
sub calcJD {
	my ($y, $m, $d, $t) = @_;
	#print Dumper @_;
	#my $ref = shift;
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
	my $diffk = ($lngtdr-$k);			# both in raidans
	my $oblr = (23.4392911-0.0130042*$t-0.0000164*$t2+0.0000504*$t3)/$radian;
	my $tx = - cos($lngtdr)*tan($oblr);
	my $ty = - cos($diffk)*tan($inc);
	my $x = atan($tx);
	my $y = atan($ty);
	my $Pr = ($x + $y);			#Postion angle
	my $P = $Pr*$radian;
	my $B0r = asin( sin($diffk)*sin($inc));		#central latitude
    my $B0 = $B0r*$radian;
    my $etay = -sin($diffk)*cos($inc);
    my $etax = -cos($diffk);
    my $eta = (atan2($etay,$etax))*$radian;
    $L0 = $eta - $theta;              # Longitude of center of disk
    $L0 = truncate($L0);
    my $L0r = $L0/$radian;
    my $CarrNo = ($jd - 2398140.22710)/27.2752316;
    print "carr no = $CarrNo L0 = " . $L0 . " B0 = " . $B0 . " P = " . $P . "\n";
    return ($L0, $B0, $P, floor($CarrNo));
}

sub lat_long { 
	my ($rs, $r1, $pa1) = @_;
        #   ROUTINE TO CALCULATE THE LAT, LONG OF SPOTS  uses radius and position angle, not x,y
    $pa1 = $pa1/$radian;
    my $r2 = asin($r1/$rs);
    my $dp = ($Pr - $pa1);
    my $B = asin(sin($B0r)*cos($r2) + cos($B0r)*sin($r2)*cos($dp));
    my $L = asin(sin($r2)*sin($dp)/cos($B)) + $L0r;
    $L = $radian * $L;
    $B = $radian * $B;
    return ($B, $L)
}

sub calc_LBP {
	my ($y, $m, $d, $h) = @_;
    $h = 0;
    print "$y, $m, $d, $h ";
    
    return calc_solar(calcJD($y,$m,$d,$h));
}


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


1;
