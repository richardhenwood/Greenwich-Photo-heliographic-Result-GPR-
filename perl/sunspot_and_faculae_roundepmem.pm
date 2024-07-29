package sunspot_and_faculae;
#use pmeph;
use spotToolsRounded;
use strict;
use Date::Calc qw(Days_in_Month Add_Delta_Days);
use Data::Dumper;
use diagnostics;
use warnings;
use Carp;
use vars qw( $AUTOLOAD );
use subs qw( truncate );
use Math::Trig;
use POSIX qw(ceil floor);
my $PI = pi;

# This module is used to store sunspot and faculae data - of the type 
# published by GRO in their Photo-Heliographic Results books
# format is found here:
# ftp://ftp.ngdc.noaa.gov/STP/SOLAR_DATA/SOLAR_WHITE_LIGHT_FACULAE/White_Light_Faculae.fmt

# some spots have an additional letter, we can convert this to a int to get the
# group number - which is useful so all the spots have integer numbers.
my $group_suffix_index = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ';

# create an empemerisis - this will come in handy throughout!
my $ephmis = new pmeph;

# create a sunspot tool, this is useful for adding the sunposition
# to the sunspot data.
my $sunspot_tool = new spotTools;

my %sunspot_and_faculae = (
    raw_string => undef,
    year => undef,
    month => undef,
    station_code => undef, 
    day_of_year => undef,             
    group_number => undef,
    letter_following_rotation_number => undef,
    radial_distance => undef, 
    position_angle => undef,
    position_angle_of_suns_axis_from_north_point => undef,
    heliographic_longitude => undef,
    heliographic_longitude_of_centre_of_disk => undef,
    heliographic_latitude => undef,
    heliographic_latitude_of_centre_of_disk => undef, 
    umbral_area_corrected => undef,
    umbral_area_corrected_total_for_day => undef,
    whole_spot_area_corrected => undef,
    total_spot_area_total_for_day => undef,
    faculae_area => undef,
    faculae_qualifying_letters => undef,
    faculae_area_total_for_day => undef,
    has_faculae_information => 0,
    Sun_B0 => undef,
    Sun_L0 => undef,
    Sun_P => undef,
    Sun_SemiDiameter => undef,
    Carrington_number => undef,
    Calculated_CMD => undef,
    Calculated_Radial_Distance => undef,
    Calculated_Polar_Angle => undef,
    Calculated_Latitude => undef,
    Calculated_Longitude => undef,
    Calculated_CarringtonLongitude => undef, 
    Calculated_Projected_WholeSpot => undef,
    Calculated_Projected_Umbral => undef,
    Calculated_Projected_Faculae => undef,
    _roe => undef,
    Calculate_Position_From_Measured => 0
);

sub parse_data_into_object {
    my $self = shift;
    my $data_string = shift;
    $self->raw_string($data_string);
    $self->year(substr($data_string,0,4));
    $self->month(substr($data_string,4,2));
    $self->station_code(substr($data_string,7,1));
    $self->day_of_year(substr($data_string,9,7));
# this is a supplemental letter - which we should incorporate into the group number...
    $self->group_number(trimWhiteSpace(substr($data_string,19,5)));
    $self->letter_following_rotation_number(substr($data_string,24,1));
# it would seem that I have miss interpreted the letter after the group 
# number as a extenstion to the number. commented out now.
#    if (substr($data_string,24,1) ne ' ') {
#        my $new_group_number = $self->group_number . sprintf("%02d", index($group_suffix_index,(substr($data_string,24,1))));
#        $self->group_number($new_group_number);
#    }
    $self->radial_distance(substr($data_string,27,5));
    $self->position_angle(substr($data_string,35,7));
    $self->heliographic_longitude(substr($data_string,42,7));
# we should manually check for the sign before the latitude, and munge it back into the 
# integer value
    my $latitude = substr($data_string,52,4);
    if (substr($data_string,51,1) eq '-') {
        $latitude = substr($data_string,52,4) * -1.0;
    }
    $self->heliographic_latitude($latitude);
    $self->umbral_area_corrected(substr($data_string,57,7));
    $self->whole_spot_area_corrected(substr($data_string,64,8));
    if (length($data_string) > 74) { 
        $self->faculae_area(substr($data_string,73,5));
        $self->faculae_qualifying_letters(substr($data_string, 78,2));
        $self->has_faculae_information(1);
    }
    else {
        $self->faculae_area(0);
    }
##
# the following code should be activiate if you want to calculate the 
# observed spot size.
# generally this is not desired when performing tests, but is deinitly 
# required when averaging the faculae dataset to greenwich style. 
# Enabling this code must be done when the object is instatnciated.
# This is done by setting Calculate_Position_From_Measured to 1;
##
#my $calculate_position = 0;
    if ($self->Calculate_Position_From_Measured) {
# put sun position data into the object.
        $sunspot_tool->calculateLBP($self);
        if ($self->is_faculae()) {
# calculate projected faculae area from area            
            $sunspot_tool->calculateProjectedAreaFaculae($self);
        }
        if ($self->is_spot()) {
# calculate projected spot area from calculated area.
            $sunspot_tool->calculateProjectedArea($self);
        }
    }
}

sub trimWhiteSpace($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub is_faculae {
    my $self = shift;
    if ($self->has_faculae_information && !$self->is_sun_position() && $self->faculae_area ne '     ') { 
        return 1;
    }
    return 0;
}
sub is_sun_position {
    my $self = shift;
    if ($self->raw_string =~ m/[()]/) {
        return 1;
    }
    if (substr($self->raw_string,17,25) eq '                         ') {
        return 1;
    }
    return 0;
}
sub get_recorded_sunP {
    my $self = shift;
    my $strvalue = substr($self->raw_string,36,5);
    #print "strvalue = $strvalue ";
    return &convert_to_value($strvalue);
}

sub convert_to_value {
    #my $self = shift;
    my $strvalue = shift;
    if ($strvalue !~ m/\d/) {
        return undef;
    }
    my $value = $strvalue;
    $value =~ s/[- ]//g;
    if ($strvalue =~ m/-/) {
        return $value * -1.0;
    }
    return $value;
}
sub get_recorded_sunL {
    my $self = shift;
    return &convert_to_value(substr($self->raw_string,43,5));
}

sub get_recorded_sunB {
    my $self = shift;
    return &convert_to_value(substr($self->raw_string,51,5));
}

sub is_group_total {
    my $self = shift;
    return $self->is_sun_position();
}
sub is_spot {
    my $self = shift;
    if ($self->group_number eq '     ' || $self->group_number eq '') {
        return 0;
    }
    return 1;
}

sub getStation {
    my $self = shift;
    return $self->station_code;
}

sub getDateTime {
    my $self = shift;
    my $date = substr($self->day_of_year,0,3); # jan 1st = day 0
    my ($year, $month, $day_of_month) = Add_Delta_Days($self->year, 1, 1, $date);
    #print "doy = " .$self->day_of_year;
    #print " dec = " .substr($self->day_of_year, 3);
    my $time = (substr($self->day_of_year, 3)) * 24;
    #print " time = " . $time;
    my $hour = floor $time;
    #print " hour = " . $hour;
    my $minute = ($time - $hour) * 60;
    #print " minute = " . $minute;
    $minute = sprintf("%d", $minute);
    #print " minute = " . $minute;
    #print "\n";
    return sprintf("%4d-%02d-%02d %02d:%02d",$year, $month, $day_of_month, $hour, $minute);
}
sub getDate {
    my $self = shift;
    my $date = substr($self->day_of_year,0,3); # jan 1st = day 0
    my ($year, $month, $day_of_month) = Add_Delta_Days($self->year, 1, 1, $date);
    return sprintf("%4d-%02d-%02d",$year, $month, $day_of_month);
}

sub getYear {
    my $self = shift;
    return $self->year;
}
sub getMonth {
    my $self = shift;
    return $self->month;
}
sub getDayOfMonth {
    my $self = shift;
    my ($year,$month,$day) = Add_Delta_Days($self->getYear,1,1,floor($self->day_of_year));
    return $day;
}
sub getFractionOfDay {
    my $self = shift;
    my $dayFrac = $self->day_of_year;
    $dayFrac =~ s/\d*\.//;
    return $dayFrac;
    #return 1000 * ($self->day_of_year - floor($self->day_of_year)) ;
}
sub getHour {
    my $self = shift;
    return $self->getFractionOfDay / 1000 * 24;
}
sub getMinute {
    my $self = shift;
    my $time = $self->getDateTime();
    my @bits = split(/[- :]/, $time);
    return $bits[4];
}
sub getSecond {
    return 0;
}

sub getDayOfYear {
    my $self = shift;
    return $self->day_of_year;
}
sub getGroupNumber {
    my $self = shift;
    return $self->group_number;
}

sub getNumberSuffix {
    my $self = shift;
    return $self->Greenwich_sunspot_group_number_suffix;
}

sub getProjectedUmbralArea {
    my $self = shift;
    return $self->Calculated_Projected_Umbral;
}
sub getProjectedWholeSpotArea {
    my $self = shift;
    return $self->Calculated_Projected_WholeSpot;
}
sub getCorrectedUmbralArea {
    my $self = shift;
    my $value = $self->umbral_area_corrected;
    $value =~ s/[\(\)]//g;
    $value = trimWhiteSpace($value);
    if ($value eq '') {
        return 0;
    }
    return $value;
}
sub getCorrectedWholeSpotArea {
    my $self = shift;
    my $value = $self->whole_spot_area_corrected;
    $value =~ s/[\(\)]//g;
    $value = trimWhiteSpace($value);
    if ($value eq '') {
        return 0;
    }
    return $value;
}
sub getCalculatedProjectedUmbralArea {
    my $self = shift;
    return $self->Calculated_Projected_Umbral;
}
sub getCalculatedProjectedWholeSpotArea {
    my $self = shift;
    return $self->Calculated_Projected_WholeSpot;
}
sub getCalcuatedProjectedFaculaeArea {
    my $self = shift;
    return $self->Calculated_Projected_Faculae;
}
sub getCalculatedLatitude {
    my $self = shift;
    return $self->Calculated_Latitude;
}
sub getCalculatedLongitude {
    my $self = shift;
    return $self->Calculated_Longitude;
}
sub getCalculatedCMD {
    my $self = shift;
    if (!defined($self->Calculated_CMD)) {
        $self = $sunspot_tool->calculate_heliographic($self);
        #&calculated_heliographic();
        my $cCMD = $self->getCarringtonLongitude - $self->getSun_L0;
        $self->putCalculatedCMD($cCMD);
    }
    return $self->Calculated_CMD;
}



sub getCalculatedCarringtonLongitude {
    my $self = shift;
    return $self->Calculated_CarringtonLongitude;
}
sub getCalculatedRadialDistanace {
    my $self = shift;
    if (!defined($self->Calculated_Radial_Distance)) {
        $self = $sunspot_tool->calculate_helioprojective($self);
    }
    return $self->Calculated_Radial_Distance;
}

sub getCalculatedClockAngle {
    my $self = shift;
    if (!defined($self->Calculated_Polar_Angle)) {
        $self = $sunspot_tool->calculate_helioprojective($self);
    }
    return $self->Calculated_Polar_Angle;
}



sub getSolarRadii {
    my $self = shift;
    return $self->radial_distance;
}
sub getPositionAngle {
    my $self = shift;
    return $self->position_angle;
}
sub getCarringtonLongitude {
    my $self = shift;
    return $self->heliographic_longitude;
}
sub getLatitude {
    my $self = shift;
    return $self->heliographic_latitude;
}
sub getFaculaeArea {
    my $self = shift;
    my $value = $self->faculae_area;
    $value =~ s/[\(\)]//g;
    $value = trimWhiteSpace($value);
    if ($value eq '') {
        return 0;
    }
    return $value;

}
sub getFaculaeQualifyingLetters {
    my $self = shift;
    return $self->faculae_qualifying_letters;
}
sub getCentralMeridianDistance {
    my $self = shift;
    my ($L_, $B_, $P_, $Car_no) = $ephmis->calc_LBP(
        $self->getYear(),
        $self->getMonth(),
        $self->getDayOfMonth(),
        $self->getHour()); 
    #print "car = ". $self->getCarringtonLongitude ." l = " .$L_;
    my $prelim_res = $self->getCarringtonLongitude - $L_;
    if ($prelim_res < -180.0) {
        $prelim_res = $prelim_res + 360;
    }
    if ($prelim_res > 180.0) {
        $prelim_res = $prelim_res - 360;
    }
    
    return $prelim_res;
}
sub getLBP {
    my $self = shift;
    print $self->day_of_year . " ";
    print join ' ', $ephmis->calc_LBP(
        $self->getYear(),
        $self->getMonth(),
        $self->getDayOfMonth(),
        $self->getHour());
    print "\n";
    return;
}
sub calculateLBP {
    my $self = shift;
    $sunspot_tool->calculateLBP($self);
}           
sub getCalculatedHelioprojective {
    my $self = shift;
    my $new_spot = new sunspot_and_faculae;
    $sunspot_tool->calculate_heliographic($self);
    return (1.1, 10.10);
}
sub getOrigionalGreenwichFormat {
    my $self = shift;
    return sprintf("%4d%2d%2d.%3d  %6d 0 0%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f \n", 
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getCalculatedProjectedUmbralArea()+0.5, 
        $self->getCalculatedProjectedWholeSpotArea()+0.5,
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getSolarRadii(),
        $self->getPositionAngle(),
        $self->getCarringtonLongitude(),
        $self->getLatitude(),
        $self->getCentralMeridianDistance()
    );
}

sub getCalculatedGreenwichFormat {
    my $self = shift;
    return sprintf("%4d%2d%2d.%3d  %6d 0 0%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f \n", 
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getCalculatedProjectedUmbralArea()+0.5, 
        $self->getCalculatedProjectedWholeSpotArea()+0.5,
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getCalculatedRadialDistanace(),
        $self->getCalculatedClockAngle(),
        $self->getCalculatedCarringtonLongitude(),
        $self->getLatitude(),
        $self->getCentralMeridianDistance()
    );
}

sub getCalculatedGreenwichFormatForward {
    my $self = shift;
    return sprintf("%4d%2d%2d.%3d  %6d 0 0%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f \n", 
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getCalculatedProjectedUmbralArea()+0.5, 
        $self->getCalculatedProjectedWholeSpotArea()+0.5,
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getSolarRadii(),
        $self->getPositionAngle(),
        $self->getCalculatedCarringtonLongitude(),
        $self->getCalculatedLatitude(),
        $self->getCalculatedCMD()
    );
}



sub getRoe {
    my $self = shift;
    print $sunspot_tool->calculate_roe($self);
}
sub getSun_B0 {
    my $self = shift;
    return $self->Sun_B0;
}
sub getSun_L0 {
    my $self = shift;
    return $self->Sun_L0;
}
sub getSun_P {
    my $self = shift;
    return $self->Sun_P;
}
sub getSun_S {
    my $self = shift;
    return $self->Sun_SemiDiameter;
}

sub putDayOfYear {
    my $self = shift;
    my $value = shift;
    $self->day_of_year($value);
}
sub putGroupNumber {
    my $self = shift;
    my $value = shift;
    $self->group_number($value);
}
sub putSolarRadii {
    my $self = shift;
    my $value = shift;
    $self->radial_distance($value);
}
sub putPositionAngle {
    my $self = shift;
    my $value = shift;
    $self->position_angle($value);
}
sub putCarringtonLongitude {
    my $self = shift;
    my $value = shift;
    $self->heliographic_longitude($value);
}
sub putLatitude {
    my $self = shift;
    my $value = shift;
    $self->heliographic_latitude($value);
}
sub putCorrectedUmbralArea {
    my $self = shift;
    my $value = shift;
    $self->umbral_area_corrected($value);
}
sub putCalculatedCMD {
    my $self = shift;
    my $value = shift;
    $self->Calculated_CMD($value);
}

sub putCorrectedWholeSpotArea {
    my $self = shift;
    my $value = shift;
    $self->whole_spot_area_corrected($value);
}
sub putCalculatedProjectedUmbralArea {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Projected_Umbral($value);
}
sub putCalculatedProjectedWholeSpot {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Projected_WholeSpot($value);
}
sub putFaculaeArea {
    my $self = shift;
    my $value = shift;
    $self->faculae_area($value);
}
sub putCalculatedProjectedFaculaeArea {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Projected_Faculae($value);
}
sub putCalculatedLatitude {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Latitude($value);
}
sub putCalculatedLongitude {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Longitude($value);
}
sub putCalculatedCarringtonLongitude {
    my $self = shift;
    my $value = shift;
    $self->Calculated_CarringtonLongitude($value);
}

sub putCalculatedRadialDistanace {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Radial_Distance($value);
}
sub putCalculatedClockAngle {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Polar_Angle($value);
}



sub putFaculaeLetters {
    my $self = shift;
    my $value = shift;
    $self->faculae_qualifying_letters($value);
}           
sub putRoe {
    my $self = shift;
    my $value = shift;
    $self->_roe($value);
}
sub putSun_B0 {
    my $self = shift;
    my $value = shift;
    $self->Sun_B0($value);
}
sub putSun_L0 {
    my $self = shift;
    my $value = shift;
    $self->Sun_L0($value);
}
sub putSun_P {
    my $self = shift;
    my $value = shift;
    $self->Sun_P($value);
}
sub putSun_S {
    my $self = shift;
    my $value = shift;
    $self->Sun_SemiDiameter($value);
}

sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my $self = {
        _permitted => \%sunspot_and_faculae,
        %sunspot_and_faculae,
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
