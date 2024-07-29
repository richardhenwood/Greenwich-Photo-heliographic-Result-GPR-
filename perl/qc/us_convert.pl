#!/usr/bin/perl -w

use Data::Dumper;
use Date::Calc qw(Days_in_Month Add_Delta_Days);
use Getopt::Std;

# this script takes a file which david willis has typed up in execl 
# and converts it to the 'standard' faculae format.
# please consult the wiki for documention on this code:
# http://www.ukssdc.ac.uk:8001/twiki/bin/view/Main/ConvertUStyping


my %opts = ();
getopts('y:f:', \%opts);
if (defined($opts{'f'}) && defined($opts{'y'})) {
    $filename = $opts{'f'};
    $this_year = $opts{'y'};
}
else {
    die "useage requires -y <year> -f <file name>\n";
}
#$filename = "/users/rhenwood/ihr/sunspots/data_scans/typed/US1878.txt";
#$this_year = 1878;

my %offset_years = ();
$offset_years{'1878'} = ();
$offset_years{'1879'} = ();
$offset_years{'1880'} = ();
$offset_years{'1881'} = ();
$offset_years{'1882'} = ();
$offset_years{'1883'} = ();
$offset_years{'1884'} = ();


open (FH, $filename);
my $currentDay = undef;
my $date = undef;
while (defined (my $line = <FH>)) {
    my $skipline = 0;
    chop($line);
    my @values = split(/:/,$line.':::::::'); # add some |||'s on incase the lines are short
# loose the first element     
    shift( @values );
# check the first column is a number:    
# remove 'd' because first date on a page has 'd' in it.
#  print "values 1 = '" . $values[0] . "'\n";
    $values[0] =~ s/d//g;
    if ($values[0] =~ /[^\d\.]/) {
# if the year is one we know to start dates at noon jan 1st, 
# correct the time for it:
        $skipline = 1;
    } 
    else {
# this must be one of the date strings which are included.       
        if ($values[0] ne '') {
            $values[0] = $values[0] + 0.5;
            $currentDay = $values[0];
            my @time1 = Add_Delta_Days($this_year,1,1,$values[0]);
            $date = sprintf "%4d%02d",@time1[0..2];

        }
        else {
            $values[0] = 0;
            $values[0] = $currentDay;
        }
    }
# check to see if the measurers are recorded
    if ($values[1] ne "") {
        $values[1] = sprintf "%s", $values[1];
    }
# split off the alpha annotation from the spot number
    my $annotation = " ";
    if ($values[2] =~ m/\D/) {
        $annotation = chop($values[2]);
    }
# check to see if there isn't a radial distance    
    if ($values[3] ne "") {
        $values[3] = sprintf "%5.3f", $values[3];
    }
# check to see if there isn't a angle    
    if ($values[4] ne "") {
        $values[4] = sprintf "%5.1f", $values[4];
    }
# check to see if there isn't a longitude    
    if ($values[5] ne "") {
        $values[5] = sprintf "%5.1f", $values[5];
    }
# check to see if there isn't a latitude    
    if ($values[6] ne "") {
        $values[6] =~ s/ //g;
        $values[6] = sprintf "%+5.1f", $values[6];
    }
    if (!$skipline) {
    # check to see if there isn't a umbral area    
        if ($values[7] ne "") {
            $values[7] = sprintf "%5d", $values[7];
        }
    # check to see if there isn't a wholespot area    
        if (defined($values[8])) { # ne "") {
            $values[8] = sprintf "%6d", $values[8];
        }
        else {
            $values[8] = "      ";
        }
    }
# print the letters after the faculae are prettily
    my $characters = ""; 
    if (exists$values[9]) {
        if ($values[9] =~ m/.*\u.*/) {
            $characters = $values[9];
            $characters =~ s/(\d+)(.*)/$2/;
            $values[9] =~ s/(\d+).*/$1/;
        }
    }
    else { 
        $values[9] = '';
    }
=begin    
# if the year is one we know to start dates at noon jan 1st, 
# correct the time for it:
    if (exists($offset_years{substr($values[0],0,4)})) {
        #    print "adding 0.5 to correct date.\n";
        $values[0] = $values[0] + 0.5;
    }
# split off the alpha annotation from the spot number
    my $annotation = " ";
    if ($values[3] =~ m/\D/) {
        $annotation = chop($values[3]);
    }
# check to see if there isn't a radial distance    
    if ($values[4] ne "") {
        $values[4] = sprintf "%5.3f", $values[4];
    }
# check to see if there isn't a angle    
    if ($values[5] ne "") {
        $values[5] = sprintf "%5.1f", $values[5];
    }
# check to see if there isn't a longitude    
    if ($values[6] ne "") {
        $values[6] = sprintf "%5.1f", $values[6];
    }
# check to see if there isn't a latitude    
    if ($values[7] ne "") {
        $values[7] = sprintf "%+5.1f", $values[7];
    }
# check to see if there isn't a umbral area    
    if ($values[8] ne "") {
        $values[8] = sprintf "%5d", $values[8];
    }
# check to see if there isn't a wholespot area    
    if ($values[9] ne "") {
        $values[9] = sprintf "%6d", $values[9];
    }
# print the letters after the faculae are prettily
    my $characters = ""; 
    if ($values[10] =~ m/.*\u.*/) {
        $characters = $values[10];
        $characters =~ s/(\d+)(.*)/$2/;
        $values[10] =~ s/(\d+).*/$1/;
    }
    printf "%d %s %#7.3f   %5s$annotation %5s    %5s  %5s  %5s  %5s  %6s  %5s%-3s\n",@values[0 .. 10], $characters;
=cut    
    if (!$skipline) {
        printf "%d G %7.3f %5s %5s$annotation   %5s    %5s  %5s  %5s  %5s  %6s  %5s%-3s\n", $date, @values[0 .. 9], $characters;
    }
}

