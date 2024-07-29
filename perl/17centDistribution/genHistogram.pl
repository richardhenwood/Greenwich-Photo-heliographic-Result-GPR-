#!/usr/bin/perl -w

use Date::Calc qw(Delta_Days);

use Data::Dumper;

my %monthsNum = (
    "Jan", 1,
    "Feb", 2,
    "Mar", 3,
    "Apr", 4,
    "May", 5,
    "Jun", 6,
    "Jul", 7,
    "Aug", 8,
    "Sep", 9,
    "Oct",10,
    "Nov",11,
    "Dec",12 );
my %numMonths = (
     1,"Jan",
     2,"Feb",
     3,"Mar",
     4,"Apr",
     5,"May",
     6,"Jun",
     7,"Jul",
     8,"Aug",
     9,"Sep",
    10,"Oct",
    11,"Nov",
    12,"Dec" );


##########################
# first, we read the data from standard in and parse in to hashes.
##########################

my %dateHistogram = ();
while (defined(my $line = <STDIN>)) {
    if ($line !~ m/^#/ && $line =~ m/\S+/) {

        my @columns = split(/ +/, $line);

        if (!defined($monthsNum{$columns[1]})) {
            die "can't find month for " . $columns[1];
        }
        my $dateStr = sprintf("%4d-%02d-%02d", $columns[0], $monthsNum{$columns[1]}, $columns[2]);
        #print "datestr = $dateStr\n";

        if (!defined($dateHistogram{$dateStr})) {
            if ($columns[3] eq '*') {
                $dateHistogram{$dateStr}{"ILGI"} = 1;
            }
            if ($columns[4] eq '*') {
                $dateHistogram{$dateStr}{"SILLOK"} = 1;
            }
        }
        ##$histogram{$columns[2]}++;
    }
    else {
        #print "ignoring line = $line";
    }
}

#print Dumper %dateHistogram;
#exit 1;


##########################
# now we bin the data
##########################

my %monthHistogram;
foreach my $dates (keys %dateHistogram) {
#    print "dates = $dates\n";
#    print Dumper $dateHistogram{$dates};
    my @date = split(/-/, $dates);
    #print Dumper @date;
    if (defined($dateHistogram{$dates}{'ILGI'}) && defined($dateHistogram{$dates}{'SILLOK'})) {
        if (!defined($monthHistogram{$date[1]}{'BOTH'})) {
            $monthHistogram{$date[1]}{'BOTH'} = 0;
        }
        $monthHistogram{$date[1]}{'BOTH'}++;
    }
    else {
        if (!defined($monthHistogram{$date[1]}{'ILGI'})) {
            $monthHistogram{$date[1]}{'ILGI'} = 0;
        }
        if (!defined($monthHistogram{$date[1]}{'SILLOK'})) {
            $monthHistogram{$date[1]}{'SILLOK'} = 0;
        }

        if (defined($dateHistogram{$dates}{'ILGI'})) {
            $monthHistogram{$date[1]}{'ILGI'}++;

        }
        if (defined($dateHistogram{$dates}{'SILLOK'})) {
            $monthHistogram{$date[1]}{'SILLOK'}++;
        }
    }
}

#print Dumper %monthHistogram;
#exit 0;

##########################
# finally we output the bin data 
##########################

my $monthStrs = "month ";
my $bothStrs = "both ";
my $ilgiStrs = "ILGI ";
my $sillokStrs = "SILLOK ";
my $rows = "month \"ILGI and SILLOK\" \"ILGI only\" \"SILLOK only\"\n";
foreach my $months (1 .. 12) {
    my $month = sprintf("%02d", $months);
    #my @dates = (1628, $month, 1);

    #print "month = $month\n";
    #print " " . $numMonths{$month} . "\n";
    #print " " . $monthsNum{$numMonths{$month}} . "\n";
    if (!defined($monthHistogram{$month}{'BOTH'})) {
        $monthHistogram{$month}{'BOTH'} = 0;
    }
    if (!defined($monthHistogram{$month}{'SILLOK'})) {
        $monthHistogram{$month}{'SILLOK'} = 0;
    }
    if (!defined($monthHistogram{$month}{'ILGI'})) {
        $monthHistogram{$month}{'ILGI'} = 0;
    }
    $monthStrs .= sprintf ("%s ", $numMonths{$month+0});
    $bothStrs .= sprintf ("%d ", $monthHistogram{$month}{'BOTH'});
    $ilgiStrs .= sprintf ("%d ", $monthHistogram{$month}{'ILGI'});
    $sillokStrs .= sprintf ("%d ", $monthHistogram{$month}{'SILLOK'});
    $rows .= sprintf ("%s %d %d %d\n", $numMonths{$month+0}, $monthHistogram{$month}{'BOTH'}, $monthHistogram{$month}{'ILGI'}, $monthHistogram{$month}{'SILLOK'});


}

#print "$monthStrs\n$bothStrs\n$ilgiStrs\n$sillokStrs\n";
print $rows;

#print Dumper %histogram;
