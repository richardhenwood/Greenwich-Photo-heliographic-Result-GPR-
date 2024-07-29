#!/usr/bin/perl -w

# this script generates the command lines for a movie of images,
# designed origionally for the 'widescreen' mercator projection.

use Date::Calc qw(Add_Delta_Days);

my $year_start = 1996;
my $year_end = 2005;
my @monthlist = qw( January    February    March   April   May     June    July    August      September   October     November    December);

#print "java -classpath ./external_libs/epsgraphics.jar:./ ral.ukssdc.solar.Sunspot_CommandLine ";
for (my $year = $year_start; $year <= $year_end; $year++) {
    for (my $month = 0; $month <= 11; $month++) {
        my $command = "w3m -dump 'http://soi.stanford.edu/cgi-bin/mdi/gif_dir.pl?Directory=/synoptic/gifs/intensitygrams/dark";
        $command .= "/$year/" . $monthlist[$month] . "' >> MDI_whitelight_dark_availability_raw.txt\n";
        print $command;
        `$command`;
    }
}
