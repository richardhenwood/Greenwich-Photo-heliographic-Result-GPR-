#!/usr/bin/perl -w

use strict;


for (my $i = 0; $i < 200; $i++) { 
    my $modI = $i % 27;
    if ($modI < 3) {
        print "\$correctionFactor[" . ($i - 1) . "] = 1;\n";
    }
    else {
        print "\$correctionFactor[" . ($i - 1) . "] = 0;\n";
    }
 }
