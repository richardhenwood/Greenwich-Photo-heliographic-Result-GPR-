#!/usr/bin/perl -w

# convert data which I have typed up into formated faculae data 
# so we can test it - and use our other tools on it!

# richard_convert takes a file typed into gnumeric and 'save as'
# with the following critieria:
# 1 text export
# 2 separator: comma
#   quoting: never
# 
# there will also be some hand editing needed to get the file to parse
#
# it is then necessary to adjust the '$this_year' variable in this file
# and then hand check the first and last few entries in the resulting 
# file to check they have the right date.
 
# note, there the dates need to be +0.5 in our case the case of 
# 1878 1879 1880 1881 1882 1883 1884 
# times are mesaured from greenwich noon.

use Date::Calc qw(Days_in_Month Add_Delta_Days);

$filename = "/users/rhenwood/ihr/sunspots/data_scans/typed/1878f.txt";

$this_year = 1878;
open (FH, $filename);
    $my_previous_date = ""; 
while (defined (my $line = <FH>)) {
#    $line = substr($line,-1,1);
    chop($line);
    $line = "000000,G," . $line . ",,,,,";
    my @values = split(",",$line);
# copy the dates
    if ($values[2] ne "") {
        $my_previous_date = $values[2]
    }
    if ($values[2] eq "") {
        $values[2] = $my_previous_date;
    }
# generate the correct year and month.
# note, we adjust the date for greenwich noon start here:
    $values[2] = $values[2] + 0.5;
    if ($values[0] eq "000000") {
        my @time1 = Add_Delta_Days($this_year,1,1,$values[2]);
        $values[0] = sprintf "%4d%02d",@time1[0..2];
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
    if (exists$values[10]) {
        if ($values[10] =~ m/.*\w.*/) {
            $characters = $values[10];
            $characters =~ s/(\d+)(.*)/$2/;
            $values[10] =~ s/(\d+).*/$1/;
        }
    }
    else {
        $values[10] = "";
    }
#    print "line = '" . (join ',', @values) . "'\n";
    printf "%d %s %#7.3f    %-6s %5s    %5s  %5s  %5s  %5s  %6s  %5s%-3s\n",@values[0 .. 10], $characters;
    
}

