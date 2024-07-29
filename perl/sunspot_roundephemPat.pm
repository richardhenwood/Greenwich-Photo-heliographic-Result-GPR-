package sunspot;
#use pmeph;
#use spotTools;
use spotToolsRoundedPat;
use strict;
use Date::Calc qw(Days_in_Month Day_of_Year Delta_YMD Date_to_Days);
use Data::Dumper;
use diagnostics;
use warnings;
use Carp;
use vars qw( $AUTOLOAD );
use subs qw( truncate );
use Math::Trig;
use POSIX qw(ceil floor);
my $PI = pi;

# this module is used to store sunspots, from the Greenwich Group
# Sunspot group reports.
# see www.ukssdc.ac.uk/wdcc1/solar_menu.html

# create a sunspot tool, this is useful for adding the sunposition 
# to the sunspot data.
my $sunspot_tool = new spotTools;

# create an ephemeris, initially to use for working out which
# solar cycle we are in.
my $ephmis = new pmeph;

my %sunspot = (
    raw_string => undef,
    year => undef,
    month => undef,
    day_of_month => undef,
    time_in_thousandths_of_day => undef,
    Greenwich_sunspot_group_number => undef,
    Greenwich_sunspot_group_number_suffix => undef,
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
    Sun_SemiDiameter => undef,
    Sun_East_Limb => undef,
    Sun_West_Limb => undef,
	Carrington_number => undef,
    Calculated_Radial_Distance => undef,
    Calculated_Polar_Angle => undef,
    Calculated_CMD => undef,
    Calculated_Latitude => undef,
    Calculated_Longitude => undef,
    Calculated_CarringtonLongitude => undef,
    Calculated_Projected_Umbral => undef,
    Calculated_Projected_WholeSpot => undef,
    Calculated_Projected_Faculae => undef,   
    Calculated_Corrected_Umbral => undef,
    Calculated_Corrected_WholeSpot => undef,
    Calculated_Helioprojective_Latitude => undef,
    Calculated_Helioprojective_Longitude => undef,
    solarCycle => undef
);

sub parse_data_into_object {
    my $self = shift;
    my $data_string = shift;
    my $needToCalculateAreas = 0;
    $self->raw_string($data_string);
    $self->year(substr($data_string,0,4));
    $self->month(substr($data_string,4,2));
    $self->day_of_month(substr($data_string,6,2));
    $self->time_in_thousandths_of_day(substr($data_string,8,4));
    $self->Greenwich_sunspot_group_number(trim(substr($data_string,14,6)));
    $self->Greenwich_sunspot_group_number_suffix(substr($data_string,20,1));
    $self->Mt_Wilson_magnetic_classification(substr($data_string,21,1));
    if ($self->Mt_Wilson_magnetic_classification =~ m/^\D/) {
# for some reason, post ~1979 mag classification is recorded using characters.
        $self->Mt_Wilson_magnetic_classification(2);}
    $self->Greenwich_group_type(substr($data_string,23,1));
    if ($self->Greenwich_group_type =~ m/^\D/) {
        $self->Greenwich_group_type(2);}
    $self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere(substr($data_string,39,5));
    $self->Corrected_umbral_area_in_millionths_of_solar_hemisphere(substr($data_string,34,5));
    $self->Observed_whole_spot_area_in_millionths_of_solar_disc(substr($data_string,29,5));
    if ($self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere =~ m/^\D/) {
    }
    $self->Observed_umbral_area_in_millionths_of_solar_disc(substr($data_string,24,5));
    if ($self->Corrected_umbral_area_in_millionths_of_solar_hemisphere == 0 &&
        $self->Observed_umbral_area_in_millionths_of_solar_disc != 0) {
        $needToCalculateAreas = 1;
    }
    $self->Distance_from_centre_of_solar_disc_in_solar_radii(substr($data_string,45,5));
    $self->Polar_angle_in_deg(substr($data_string,51,5));
    $self->Carrington_longitude(substr($data_string,57,5));
    $self->Latitude(substr($data_string,63,5));
    $self->Central_meridian_distance(substr($data_string,69,5));
##
# commented out the remaining lines since we are using this module 
# to perform our tests at the moment
##
# calculate the heliographic position from the helioprojective position.
#    $self = $sunspot_tool->calculate_heliographic($self);

##
# for the sake of convienience, we'll generate and store which 
# solar cycle we are in.
##
    my $dateString = sprintf("%4d%02d%02d", $self->year, $self->month, $self->day_of_month);
    my $solarCycle = $ephmis->solarCycle($dateString);
    $self->solarCycle($ephmis->solarCycle($dateString));
    if (0) {
        $sunspot_tool->calculateLBP($self);
        if ($self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere < 100) {
            my $calculatedValue = sprintf("%5d",$self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere * 0.2);
            $self->Corrected_umbral_area_in_millionths_of_solar_hemisphere($calculatedValue);
        }
        else {
            my $calculatedValue = sprintf("%5d",$self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere * 0.17);
            $self->Corrected_umbral_area_in_millionths_of_solar_hemisphere($calculatedValue);
        }
        $self = $sunspot_tool->calculateProjectedArea($self); 
    }
    eval {$sunspot_tool->calculateLBP($self);};
    if ($@) {
        die "calculateLBP is broken.\n";
    }
    $self = $sunspot_tool->calculateProjectedArea($self);
}


##########################################################
# now come the 'get' fuctions to return the data structure
##########################################################
sub getActualClockAngle {
	my $self = shift;
	return $self->Polar_angle_in_deg / 360 * 2 * $PI;
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
sub getCalculatedLatitude {
    my $self = shift;
    if (!defined($self->Calculated_Latitude)) {
        $self = $sunspot_tool->calculate_heliographic($self); 
    }
    return $self->Calculated_Latitude;
}
sub getCalculatedLongitude {
    my $self = shift;
    if (!defined($self->Calculated_Longitude)) {
        &calculated_heliographic();
    }
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
    if (!defined($self->Calculated_CarringtonLongitude)) {
        $self = $sunspot_tool->calculate_heliographic($self); 
        #&calculated_heliographic();
    }
    return $self->Calculated_CarringtonLongitude;
}
sub getCalculatedCorrectedUmbralArea {
    my $self = shift;
    return $self->Calculated_Corrected_Umbral;
}
sub getCalculatedCorrectedWholeSpotArea {
    my $self = shift;
    return $self->Calculated_Corrected_WholeSpot;
}
sub getCalculatedProjectedUmbralArea {
    my $self = shift;
    return $self->Calculated_Projected_Umbral;
}
sub getCalculatedProjectedWholeSpotArea {
    my $self = shift;
    return $self->Calculated_Projected_WholeSpot;
}
sub getDateTime {
    my $self = shift;
    my $time = (substr($self->time_in_thousandths_of_day, 1) / 1000) * 24;
    #print $self->time_in_thousandths_of_day . "\n";
    #print "time = $time\n";
    my $hour = floor $time;
    my $minute = ($time - $hour) * 60;
    if ($self->isObservationInterpolated) {
        $hour = 12;
        $minute = 0;
        #print "interpolated: ";
        #print $self->raw_string;
    }
    #print "hour = $hour $time\n";
    #print "minute = $minute\n";
    return sprintf("%4d-%02d-%02d %02d:%02d",$self->year, $self->month, $self->day_of_month, $hour, $minute);
}
sub getDate {
    my $self = shift;
    my $time = (substr($self->time_in_thousandths_of_day, 1) / 1000) * 24;
    return sprintf("%4d-%02d-%02d",$self->year, $self->month, $self->day_of_month);
}
sub getYear {
    my $self = shift;
    return $self->year;
}
sub getMonth {
    my $self = shift;
    return trim($self->month);
}
sub getDayOfMonth {
    my $self = shift;
    return trim($self->day_of_month);
}
sub getDayOfYear {
    my $self = shift;
    return Day_of_Year($self->getYear, $self->getMonth, $self->getDayOfMonth);
}
sub getHour {
    my $self = shift;
    my $fraction_of_day = $self->time_in_thousandths_of_day;
    $fraction_of_day =~ s/ //g;
    return $fraction_of_day * 24;
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

sub getRawDayFraction {
    my $self = shift;
    return $self->time_in_thousandths_of_day;
}
sub getFractionOfDay {
    my $self = shift;
    my $fraction_of_day = $self->time_in_thousandths_of_day;
    $fraction_of_day =~ s/ //g;
    return $fraction_of_day * 1000;
}
sub getGroupNumber {
    my $self = shift;
    if (!defined($self->Greenwich_sunspot_group_number)) {
        return "000";
    }
    return $self->Greenwich_sunspot_group_number;
}
sub getGroupNumberAugmented {
    my $self = shift;
    if (!defined($self->Greenwich_sunspot_group_number)) {
        return "000";
    }
    my $numSuffix = $self->getNumberSuffix();
    if ($numSuffix ne " 0" && $numSuffix ne " ") {
        #print "numsuffix = '$numSuffix'\n";
        $numSuffix += 0; # this should cast it into an integer?
        return sprintf("%d999%d", $self->Greenwich_sunspot_group_number, $numSuffix);
    }
    #$self->Greenwich_sunspot_group_number =~ s/\s+$//;
    return $self->Greenwich_sunspot_group_number;
}
sub getNumberSuffix {
    my $self = shift;
    return $self->Greenwich_sunspot_group_number_suffix;
}
sub hasSuffix {
    my $self = shift;
    my $numSuffix = $self->getNumberSuffix();
    if ($numSuffix ne " 0" && $numSuffix ne " ") {
        return 1;
    }
    return 0;
}

sub getWilsonClassification {
    my $self = shift;
    return $self->Mt_Wilson_magnetic_classification;
}
sub getGroupType {
    my $self = shift;
    return $self->Greenwich_group_type;
}
sub getSolarRadii {
    my $self = shift;
    return $self->Distance_from_centre_of_solar_disc_in_solar_radii;
}
sub getPositionAngle {
    my $self = shift;
    return $self->Polar_angle_in_deg;
}
sub getCarringtonLongitude {
    my $self = shift;
    return $self->Carrington_longitude;
}
sub getLatitude {
    my $self = shift;
    return $self->Latitude;
}
#sub getLongitude {
#    my $self = shift;
#    return $self->Central_meridian_distance;
#}
sub getProjectedUmbralArea {
    my $self = shift;
    return $self->Observed_umbral_area_in_millionths_of_solar_disc;
}
sub getProjectedWholeSpotArea {
    my $self = shift;
    return $self->Observed_whole_spot_area_in_millionths_of_solar_disc;
}
sub getCorrectedUmbralArea {
    my $self = shift;
    return $self->Corrected_umbral_area_in_millionths_of_solar_hemisphere;
}
sub getCorrectedWholeSpotArea {
    my $self = shift;
    return $self->Corrected_whole_spot_area_in_millionths_of_solar_hemisphere;
}
sub getCentralMeridianDistance {
    my $self = shift;
    return $self->Central_meridian_distance;
}
sub getOrigionalGreenwichFormat {
    my $self = shift;
    return sprintf("%4d%2d%2d.%03d  %6d%1s%1d %1d%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f\n",
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getNumberSuffix(),
        $self->getWilsonClassification(),
        $self->getGroupType(),
        $self->getProjectedUmbralArea(),
        $self->getProjectedWholeSpotArea(),
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getSolarRadii(),
        $self->getPositionAngle(),
        $self->getCarringtonLongitude(),
        $self->getLatitude(),
        $self->getCentralMeridianDistance()
    );
    #return $self->raw_string;
}
sub getCalculatedGreenwichFormat {
    my $self = shift;
    return sprintf("%4d%2d%2d.%03d  %6d%1s%1d %1d%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f\n",
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getNumberSuffix(),
        $self->getWilsonClassification(),
        $self->getGroupType(),
        $self->getProjectedUmbralArea(),
        $self->getProjectedWholeSpotArea(),
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getCalculatedRadialDistanace(),
        $self->getCalculatedClockAngle(),
        $self->getCarringtonLongitude(),
        $self->getLatitude(),
        $self->getCentralMeridianDistance()
    );
    #return $self->raw_string;
}
sub getCalculatedGreenwichFormatForward {
    my $self = shift;
    return sprintf("%4d%2d%2d.%03d  %6d%1s%1d %1d%5d%5d%5d%5d %5.3f %5.1f %5.1f %5.1f %5.1f\n",
        $self->getYear,
        $self->getMonth,
        $self->getDayOfMonth(),
        $self->getFractionOfDay(),
        $self->getGroupNumber(),
        $self->getNumberSuffix(),
        $self->getWilsonClassification(),
        $self->getGroupType(),
        $self->getProjectedUmbralArea(),
        $self->getProjectedWholeSpotArea(),
        $self->getCorrectedUmbralArea(),
        $self->getCorrectedWholeSpotArea(),
        $self->getSolarRadii(),
        $self->getPositionAngle(),
        $self->getCalculatedCarringtonLongitude(),
        $self->getCalculatedLatitude(),
        $self->getCalculatedCMD()
    );
    #return $self->raw_string;
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
    #print "trying to get sun s\n";
    #print $self->Sun_SemiDiameter;
    #print "\n";
    return $self->Sun_SemiDiameter;
}
sub getSun_East_Limb {
    my $self = shift;
    my @spotTime = my @carringtonTime = (split(/[ \-:]/,$self->getDateTime()),0);
    my @ephResults = $ephmis->calc_LBP(@spotTime);
    return sprintf("%.1f ", (270 - (360.0 * $ephResults[4])) % 360);
}
sub getSun_West_Limb {
    my $self = shift;
    my @spotTime = my @carringtonTime = (split(/[ \-:]/,$self->getDateTime()),0);
    my @ephResults = $ephmis->calc_LBP(@spotTime);
    return sprintf("%.1f", (90 - (360.0 * $ephResults[4])) % 360);
}
sub getSun_LimbTimes { # returns two arrays: eastLimb time followed by west limb time.
    my $self = shift;
    my $longitude = shift;
    my $time = $self->getDateTime();
    my ($eastLimbRef, $westLimbRef) = $ephmis->getLimbTimes((split(/[ \-:]/,$time),0), $longitude);
    return ($eastLimbRef, $westLimbRef);
}
sub getCarringtonRotationNumber {
    my $self = shift;
    my @spotTime = my @carringtonTime = (split(/[ \-:]/,$self->getDateTime()),0);
    my @ephResults = $ephmis->calc_LBP(@spotTime);
    return $ephResults[3];
}
sub getSolarCycle { 
    my $self = shift;
    return $self->solarCycle;
}   
sub getSolarCycleProgress {
    my $self = shift;
    my $value = shift;
    my $solarCycle = $self->getSolarCycle();
    my ($beg, $end) = $ephmis->solarCycleDates($solarCycle);
    my @begYMD = ();
    my @endYMD = ();
    if ($beg =~ m/(....)(..)(..)/) {
        @begYMD = ($1, $2, $3);
    }
    else {
        die "can't parse '$beg'\n" . $self->raw_string;
    }
    if ($end =~ m/(....)(..)(..)/) {
        @endYMD = ($1, $2, $3);
    }
    else {
        die "can't parse '$beg'\n";
    }
    my @deltaYMD = Delta_YMD(@begYMD, @endYMD);
    my $cycleDays = Date_to_Days(@endYMD) - Date_to_Days(@begYMD);

    my $obsDays = Date_to_Days($self->getYear, $self->getMonth, $self->getDayOfMonth) - Date_to_Days(@begYMD);
    return sprintf ("%.1f", $obsDays / $cycleDays);
}
sub calculateHelioprojective {
    my $self = shift;
    $self = $sunspot_tool->calculate_helioprojective($self);
}
# this method maintains compatibility with sunspot_and_faculae.pm
# everything is a spot in the greenwich dataset
sub is_spot {
    return 1;
}
sub isObservationInterpolated {
    my $self = shift;
    if (!defined($self->raw_string)) {
        return 0;
    }
    if (substr($self->raw_string, 8, 4) eq '.  0') {
        return 1;
    }
    return 0;
}


##########################################################
# now come the 'put' fuctions to alter the data structure
##########################################################
sub putGroupNumber {
    my $self = shift;
    my $value = shift;
    if ($value =~ m/\d\d999\d/) {
        my ($prefix, $suffix) = split(/999/, $value);
        #print "fixing augmented value: '$value' (suffix = '$suffix')\n";
        $value = $prefix;
        $self->Greenwich_sunspot_group_number_suffix($suffix);
    }
    #print "substituting: $value\n";
    $self->Greenwich_sunspot_group_number($value);
}
sub putSolarRadii {
    my $self = shift;
    my $value = shift;
    $self->Distance_from_centre_of_solar_disc_in_solar_radii($value);
}
sub putPositionAngle {
    my $self = shift;
    my $value = shift;
    $self->Polar_angle_in_deg($value);
}
sub putCarringtonLongitude {
    my $self = shift;
    my $value = shift;
    $self->Carrington_longitude($value);
}
sub putLatitude {
    my $self = shift;
    my $value = shift;
    $self->Latitude($value);
}
sub putCMD {
    my $self = shift;
    my $value = shift;
    $self->Central_meridian_distance($value);
}
sub putLongitude {
    my $self = shift;
    my $value = shift;
    $self->Central_meridian_distance($value);
}
sub putCorrectedUmbralArea {
    my $self = shift;
    my $value = shift;
    $self->Corrected_umbral_area_in_millionths_of_solar_hemisphere($value);
}
sub putCorrectedWholeSpotArea {
    my $self = shift;
    my $value = shift;
    $self->Observed_whole_spot_area_in_millionths_of_solar_disc($value);
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
sub putCalculatedCMD {
    my $self = shift;
    my $value = shift;
    $self->Calculated_CMD($value);
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
sub putRawDayFraction {
    my $self = shift;
    my $value = shift;
    $self->time_in_thousandths_of_day($value);
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
sub putCalculatedProjectedFaculaeArea {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Projected_Faculae($value);
}
sub putCalculatedCorrectedUmbralArea {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Corrected_Umbral($value);
}
sub putCalculatedCorrectedWholeSpot {
    my $self = shift;
    my $value = shift;
    $self->Calculated_Corrected_WholeSpot($value);
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
sub putDateTime {
    my $self = shift;
    my $year = shift;
    my $month = shift;
    my $day = shift;
    my $dectime = shift;
    $self->year($year);
    $self->month($month);
    $self->day_of_month($day);
    $self->time_in_thousandths_of_day($dectime);
}
    


#################################################
# these are some module house keeping functions
#################################################
sub trim ($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
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
##################################################
# this is the end of the module!
##################################################

1;
