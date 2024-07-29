#!/usr/bin/perl -w

use Data::Dumper;

# this script takes a file which david willis has typed up in execl 
# and converts it to the 'standard' faculae format.
# you need to export from excel as CSV using:
# field delimiter ','
# text delimiter 'none' or remove the text delimiters using a text editor.

$filename = "/users/rhenwood/ihr/sunspots/data_scans/typed/chinese.txt";

my %offset_years = ();
$offset_years{'1878'} = ();
$offset_years{'1879'} = ();
$offset_years{'1880'} = ();
$offset_years{'1881'} = ();
$offset_years{'1882'} = ();
$offset_years{'1883'} = ();
$offset_years{'1884'} = ();

open (FH, $filename);
while (defined (my $line = <FH>)) {
    my @values = split(",",$line);
# if the year is one we know to start dates at noon jan 1st, 
# correct the time for it:
    if (exists($offset_years{substr($values[0],0,4)})) {
        #    print "adding 0.5 to correct date.\n";
        $values[2] = $values[2] + 0.5;
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
    
}

