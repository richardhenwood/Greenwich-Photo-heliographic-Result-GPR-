#!/usr/bin/perl -w

# this script generates the command lines for a movie of images,
# designed origionally for the 'widescreen' mercator projection.

use Date::Calc qw(Add_Delta_Days);
use Data::Dumper;

my $year_start = 1982;
my $year_end = 2005;
#my @monthlist = qw( January    February    March   April   May     June    July    August      September   October     November    December);

if (0) {
for (my $year = $year_start; $year <= $year_end; $year++) {
    for (my $month = 1; $month <= 12; $month++) {
        for (my $day = 1; $day <= 31; $day++) {
            my $command = sprintf("w3m -dump ftp://ftp.bbso.njit.edu/pub/archive/%d/%02d/%02d/\n",$year, $month, $day);
#            my $command = "w3m -dump 'http://soi.stanford.edu/cgi-bin/mdi/gif_dir.pl?Directory=/synoptic/gifs/intensitygrams/dark/";
#           $command .= "/$year/" . $monthlist[$month] . "' >> MDI_whitelight_dark_availability.txt\n";
#print $command;
            my @dirContents = `$command`;
            my @grepResult = grep(/white/, @dirContents); #`echo $dirContents | grep -i white`;
            #print Dumper @grepResult;
            foreach my $whiteImage (@grepResult) {
                printf ("%d-%02d-%02d ", $year, $month, $day);
                print $whiteImage;
#                print "\n";
            }
        }
    }
}
}

for (my $days = 0; $days <= 8700; $days++) {
    my ($year, $month, $day) = Add_Delta_Days($year_start, 01, 01, $days);
    print "year = $year, mont = $month, day = $day\n";
}
