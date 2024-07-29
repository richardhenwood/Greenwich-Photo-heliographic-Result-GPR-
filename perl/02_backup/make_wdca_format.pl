#!/usr/bin/perl

use strict;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days );
use List::Util qw(sum);
use Math::Trig qw(asin sec rad2deg deg2rad);


while (defined(my $line = <STDIN>)) {
    my $returnString = $line;
    if (substr($line, 9, 3) == '000') {
        $returnString = substr($line,0,9) . '  0' . substr($line, 12);
    }
    if (substr($returnString, 20, 2) == '00') {
        $returnString = substr($returnString,0, 20) . ' 0' . substr($returnString, 22);
    }
    print $returnString;
}


sub substituteZeros {
    while (defined(my $line = <STDIN>)) {
        my $returnString = $line;
        if (substr($line, 9, 3) == '000') {
            $returnString = substr($line,0,9) . '  0' . substr($line, 12);
        }
        if (substr($returnString, 20, 2) == '00') {
            $returnString = substr($returnString,0, 20) . ' 0' . substr($returnString, 22);
        }
        print $returnString;
        
    }
}
