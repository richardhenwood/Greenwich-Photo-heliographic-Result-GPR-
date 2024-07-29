#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Date::Calc qw(Add_Delta_DHMS leap_year Day_of_Year Add_Delta_Days);
use POSIX qw(ceil floor);
use pmeph;

#my $ephmis = new pmeph;
# I know globals are bad, this is just for convienience...
my @problemLines;

# a simple perl code which takes faculae data from stdin
# and checks that the dates are 'correct' by converting from
# day_of_year into year month day, and comparing the calculated 
# with the recorded days.
#
# you might use it like:
#  cat ../1881.FIN | ./testDate.pl
#


#start counting from mid day on jan first for the following years
my %noonStart = (1878 => 1,
    1879 => 1,
    1880 => 1,
    1881 => 1,
    1882 => 1,
    1883 => 1,
    1884 => 1,
    1885 => 1);

my $lineNo = 1;
while (my $line = <STDIN>) {
    chomp $line;
    my @column = &getColumns($line);
    $lineNo++;
}
#print "\n";

print "problems: \n";
foreach my $line (@problemLines) {
    print "$line";
    print "\n";
}


sub convertToNumber {
    my $str = shift;
    
    if ($str eq "     ") {
        return '  ?  ';
    }
    my $num = substr($str, 1);
    my $operator = substr($str, 0, 1);
    if ($operator eq '-') {
        $num = 0 - $num 
    }
    return $num;
}


sub getColumns {
    my $str = shift;
    # add some white space so substr always succeeds.
    $str .= "                                 ";
    my @column;
    $column[0] = substr($str,0,6);
    $column[1] = substr($str,9,7);
    $column[2] = substr($str,36,5);
    $column[3] = substr($str,43,5);
    $column[4] = substr($str,51,5);
    $column[5] = substr($str,58,5);
    $column[6] = substr($str,65,6);
    $column[7] = substr($str,73,5);
    my $date = &convertDate($column[0], $column[1]);
    #print "date = " . Dumper $date;
    if ($date) {
        $column[8] = $date;
    }
    else {
        push(@problemLines, $str);
    }
    return @column;
}

sub convertDate {
    my ($datestr, $daystr) = @_;

    my $year = substr($datestr, 0, 4);
    my $dayAdjust = 0;
    if ($noonStart{$year}) {
        $dayAdjust += 12;
    }
    my $month = substr($datestr, 4, 2);
    my $doy = substr($daystr, 0, 3);
    my $decHr = substr($daystr, 4,3);
    my $Hr = ($decHr/1000)*24;
    my $min = ($Hr - floor($Hr))*60;
    my $sec = ($min - floor($min))*60;
    my @date = Add_Delta_DHMS($year, 1, 1, $dayAdjust, 0, 0, $doy, $Hr, $min, 0);
    if ($date[1] != $month) {
        return undef;
    }
    return sprintf ("%04d-%02d-%02d %02d:%02d:%02d", @date);
}

