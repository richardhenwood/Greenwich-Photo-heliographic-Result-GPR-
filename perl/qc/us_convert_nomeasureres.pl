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
my @previousValues = ();
while (defined (my $line = <FH>)) {
    my $skipline = 0;
    my $totalsLine = 0;
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
# split off the alpha annotation from the spot number
    my $annotation = " ";
    if ($values[1] =~ m/\D/) {
        $annotation = chop($values[1]);
        $values[1] = sprintf("%4d", $values[1]);
    }
# check to see if there isn't a radial distance    
    if ($values[2] ne "") {
        $values[2] = sprintf "%5.3f", $values[2];
    }
# check to see if there isn't a angle    
    if ($values[3] ne "") {
        $values[3] = sprintf "%5.1f", $values[3];
    }
# check to see if there isn't a longitude    
    if ($values[4] ne "") {
        $values[4] = sprintf "%5.1f", $values[4];
    }
# check to see if there isn't a latitude    
    if ($values[5] ne "") {
        $values[5] =~ s/ //g;
        $values[5] = sprintf "%+5.1f", $values[5];
    }
    #if (!$skipline) {

    # check to see if there isn't a umbral area    
    if ($values[6] ne "") {
        $values[6] =~ s/[\(\)]//g;
        $values[6] = sprintf "%6d", $values[6];
    }
    else { $values[6] = "     0"; };
    # check to see if there isn't a wholespot area    
    if ($values[7] ne "") {
        $values[7] =~ s/[\(\)]//g;
        $values[7] = sprintf "%8d", $values[7];
    }
    else { $values[7] = "       0"; };
# print the letters after the faculae prettily
    my $characters = ""; 
    if (defined($values[8])) {
        if ($values[8] =~ m/.*\u.*/) {
            $characters = $values[8];
            $characters =~ s/\(?\d+\)?//g; #remove brackets and value
            $characters =~ s/ //g; #remove white space
            $values[8] =~ s/\D//g;
        }
        $values[8] = sprintf("%7d", $values[8]);
    }
    else { 
        $values[8] = '       ';
    }
    if ($skipline) {
        #print "not skpline\n";
        $values[0] = $previousValues[0];
        $values[1] = "     ";
        $values[2] = "     ";
        $values[3] = "     ";
        $values[4] = "     ";
        $values[5] = "     ";
        $values[6] = sprintf ("(%5d)", $values[6]);
        $values[7] = sprintf ("(%6d)", $values[7]);
        if ($values[8] ne '       ') {
            $values[8] = sprintf ("(%5d)", $values[8]);
        }
    }

    printf "%d G %7.3f %5s$annotation    %5s    %5s  %5s  %6s %6s%6s%6s%-2s\n", $date, @values[0 .. 8], $characters;
    @previousValues = @values;
}

