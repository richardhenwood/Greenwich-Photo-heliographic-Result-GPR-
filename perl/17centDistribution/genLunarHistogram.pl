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
# first, we read the data from standard in and parse in to hashes, binning at the same time
##########################

my %dateHistogram = ();
while (defined(my $line = <STDIN>)) {
    if ($line !~ m/^#/ && $line =~ m/\S+/) {

        my @columns = split(/ +/, $line);

        if (!defined($monthsNum{$columns[1]})) {
            die "can't find month for " . $columns[1];
        }

        my $date = $columns[5] - 1;
        my $lunarCycle = sprintf("%d-%d", $date - ($date % 3) +1 , $date -($date % 3) +3);
        #print "date = $date cycle = $lunarCycle\n";

        my $dateStr = sprintf("%4d-%02d-%02d", $columns[0], $monthsNum{$columns[1]}, $columns[2]);
        #print "datestr = $dateStr\n";

        if (!defined($previousDates{$dateStr})) {
            if ($columns[3] eq '*' && $columns[4] eq '*') {
                if (!defined($lunarHistogram{$lunarCycle}{'BOTH'})) {
                    $lunarHistogram{$lunarCycle}{'BOTH'} = 0;
                }
                $lunarHistogram{$lunarCycle}{'BOTH'}++;
            }
            elsif ($columns[3] eq '*') {
                if (!defined($lunarHistogram{$lunarCycle}{'ILGI'})) {
                    $lunarHistogram{$lunarCycle}{'ILGI'} = 0;
                }
                $lunarHistogram{$lunarCycle}{'ILGI'}++;
            }
            elsif ($columns[4] eq '*') {
                if (!defined($lunarHistogram{$lunarCycle}{'SILLOK'})) {
                    $lunarHistogram{$lunarCycle}{'SILLOK'} = 0;
                }
                $lunarHistogram{$lunarCycle}{'SILLOK'}++;
            }

        }
        $previousDates{$dateStr} = 1;
        ##$histogram{$columns[2]}++;
    }
    else {
        #print "ignoring line = $line";
    }
}

##########################
# now print the values out, in a suitable format for gnuplot
##########################

my $monthStrs = "month ";
my $bothStrs = "both ";
my $ilgiStrs = "ILGI ";
my $sillokStrs = "SILLOK ";
my $rows = "lunarBin \"ILGI and SILLOK\" \"ILGI only\" \"SILLOK only\"\n";
foreach my $lunarCycle (sort mySort keys %lunarHistogram) {

    if (!defined($lunarHistogram{$lunarCycle}{'BOTH'})) {
        $lunarHistogram{$lunarCycle}{'BOTH'} = 0;
    }
    if (!defined($lunarHistogram{$lunarCycle}{'SILLOK'})) {
        $lunarHistogram{$lunarCycle}{'SILLOK'} = 0;
    }
    if (!defined($lunarHistogram{$lunarCycle}{'ILGI'})) {
        $lunarHistogram{$lunarCycle}{'ILGI'} = 0;
    }
    
    $rows .= sprintf ("%s %d %d %d\n", $lunarCycle, $lunarHistogram{$lunarCycle}{'BOTH'}, $lunarHistogram{$lunarCycle}{'ILGI'}, $lunarHistogram{$lunarCycle}{'SILLOK'});


}

#print "$monthStrs\n$bothStrs\n$ilgiStrs\n$sillokStrs\n";
print $rows;


sub mySort {
    my @Abin = split(/-/,$a);
    my @Bbin = split(/-/,$b);
    $Abin[0] <=> $Bbin[0];
    #$a cmp $b;
}
#print Dumper %histogram;
