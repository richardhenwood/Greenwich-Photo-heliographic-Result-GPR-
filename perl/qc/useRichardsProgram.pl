#!/usr/bin/perl

use strict;
use lib '../external_libs/';
use Statistics::Basic::Mean;
use Statistics::Basic::StdDev;
use lib '../';
use sunspot_and_faculae;
use sunspot;
use POSIX;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_DHMS Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";
This program uses richards program to generate
This program compairs the sizes generated by Daniels code with those generated 
by richard stephensons code.

usage: $0 -f file

example: $0 
EOF
    exit;
}

#my %opts = ();
#getopts("f:", \%opts) ;
#if (!defined($opts{f})) { usage(); }


my $RichardSProgram = "/users/rhenwood/ihr/sunspots/perl/external_libs/a.out";

#my $filename = $opts{f};
#open (FH, $filename);
my @startDate = (1975, 10, 5, 00, 00, 00);
my @endDate = (1975, 10, 6, 00, 00, 00);
my @currentDate = @startDate;
print "time             | RS value\n";
#print Dumper getSeconds(Delta_DHMS(@currentDate, @endDate));
while (getSeconds(Delta_DHMS(@currentDate, @endDate)) > 0) {
    
    #print join ', ',@currentDate;
    printf("%4d-%02d-%02d %02d:%02d ", @currentDate[0 .. 4]);

    my $dateStr = sprintf("%4d %2d %2d %02d %02d", @currentDate[0 .. 4]);
    my $programCall = "$RichardSProgram $dateStr";
    my $progResult = `$programCall`;
    chomp ($progResult);
    my @progResults = split(/ +/, $progResult);
    my $progSunSD = $progResults[14];
    print "$progSunSD";
    print "\n";


    @currentDate = Add_Delta_DHMS(@currentDate, 0, 1, 0, 0);
   
    # #
    # #print "line = $line";
    # chomp($line);
    # my @components = split(/[-:| T]/, $line);
    # 
    # #print Dumper @components;
    # my ($year, $month, $day) = @components[0 .. 2];
    # my $hour = $components[3];
    # my $minutes = $components[4];
    # my $ut = $hour + $minutes/60;
    # #print "year $year , $month $day ut = $ut\n";
    # my $fileSunSD = $components[10];
    # #print "sunsemidiameter = $fileSunSD";
    # my $programCall = "$RichardSProgram $year $month $day $ut";
    # my $progResult = `$programCall`;
    # chomp ($progResult);
    # my @progResults = split(/ +/, $progResult);
    # #print Dumper @progResults;
    # my $progSunSD = $progResults[14];
    # print "$year-$month-$day $hour:$minutes, ";
    # print "$progSunSD, $fileSunSD, ";
    # print $progSunSD - $fileSunSD ;
    # print "\n";
}

sub getSeconds {
    my ($days, $hours, $minutes, $seconds) = @_;
    return $seconds + ($minutes * 60) + ($hours * 60 * 60) + ($days * 60 * 60 * 24);
}

