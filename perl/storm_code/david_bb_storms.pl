#!/usr/bin/perl

use strict;
use lib '..';
use sunspot_and_faculae;
use sunspot;
use Data::Dumper;
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);

# this script takes a whole data set (defined with the variable:
# $sunspot_and_faculae_filename) and prints to standard out, a dataset consisting 
# of data surrounding epochs (an array at the bottom of this file).


# source of faculae data
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1948.REV3.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/test.dat";
#my $sunspots_and_faculae_filename = "/users/rhenwood/tmp/sunspots/faculae/1892.FIN";
my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/greenwich/all.txt";
#my $sunspots_and_faculae_filename = "/users/rhenwood/ihr/data/faculae/all.txt";
my $sunImagesFilename = "/users/rhenwood/ihr/sunspots/perl/storm/bb_whitelight_availability.txt";

# load the data into a hash
#my %sunspots = ();
#my %sunspots = &Load_Sunspot($sunspots_and_faculae_filename);
#my %sunspots = &Load_Sunspot_and_Faculae($sunspots_and_faculae_filename);
my $archiveName = "BB_sunImage";
my %sunImages = &Load_SunImages($sunImagesFilename);

# print the data $pre days before and $post days after the 
# dates from @epochs
# assume a storm is within $tolerance number of hour from the epoch.
my $pre = 6;
my $post = 0;
my $tolerance = 0;
my $imagesPerDay = 7; # this is a worst case estimate.
#&get_epochs($pre, $post, $tolerance, &get_storm_dates(), \%sunspots);
&get_epochs($pre, $post, $tolerance, &get_storm_dates_complete(), \%sunImages);

# prints the 'raw' data from before and after an epoch.
sub get_epochs {
    my ($pre, $post, $tolerance, $epochs_ref, $sunspots_ref) = @_;
    my @storms = @{$epochs_ref};
    my %spots = %{$sunspots_ref};
    my $storm_date = "";
    my @storms_found = ();
    my @storms_missed = ();
    my $storm_index = 0;
    my $i = 0;
    my $j = 0;
    my @monthlist = qw( January    February    March   April   May     June    July    August      September   October     November    December);
    my %outImages = ();
    my @obs_times = (sort keys %sunImages);
    #  print Dumper @obs_times;
# take the first entry in the spot dataset - used to compair against the first storm date
    while ($i < scalar @obs_times) {
        my @time1 = ($obs_times[$i] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
# go throught the storm dates until you find one which has a positive difference
        while ($j < scalar @storms) {
            #       print "i,j = $i,$j\n";
            #     print "obs = " . $obs_times[$i] . " storm " . $storms[$j] . "\n";
# note: assume the storm time is measured at 12 noon.
            my @time2 = ($storms[$j] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
            my @diff = Delta_DHMS(@time1, @time2);
            my $result = $diff[3] + ($diff[2]*60) + (($diff[1]-$tolerance)*3600) + ($diff[0]*86400);
            #  print "result = $result\n";
            if ($result > 0) { # obs_time is before storm time.
# now run through the spot obs_data to find the smallest difference to storm date.
                my $is_minimum = 0;                
                my $previous_result = $result + 999; # assume we are within 999 hrs of the epoch.
                while (!$is_minimum && $i < scalar @obs_times) {
                    @time1 = ($obs_times[$i] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
                    @diff = Delta_DHMS(@time1, @time2);
                    $result = $diff[3] + ($diff[2]*60) + (($diff[1]-$tolerance)*3600) + ($diff[0]*86400);
# check that we are still getting closer to the epoch time.                    
                    if (abs($result) < abs($previous_result)) { 
                        $previous_result = $result;
                        $i++;
                    }
# we have found the smallest value - infact it was the previous iteration.                    
                    else {
                        $is_minimum = 1;
                        $storm_index = $i - 1; # the previous date was the closest.
                    }
                }
# print $pre + $post spot obs values from this point 
                print "attempting to match: " . $storms[$j];
                print " closest record is: " . $obs_times[$storm_index] . "\n";
                push @storms_found, $storms[$j];
# now we need to find out which storms correspond to which epoch offsets.
                my %epoch_hours = ();
                for (my $k = - $pre * $imagesPerDay; $k <= $post * $imagesPerDay; $k++) {
                    @time1 = ($obs_times[$storm_index + $k] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
                    @diff = Delta_DHMS(@time2, @time1);
                    $epoch_hours{$diff[0]*24 + $diff[1] + $diff[2]/60 + $diff[3]/3600} = $storm_index + $k;
#                    print "storm index = $storm_index + $k\n";
                }
                $i = $i - $post ; # just incase there is a storm the very next day.
                my %epoch = ();
                foreach my $hour_diff (reverse sort numeric keys %epoch_hours) {
# search to see if each of the value fits an appropriate epoch time region.
#print Dumper %epoch_hours;
                    my $k = - $pre;
                    while ($k <= $post) {
                        my $lower_bound = ($k -1) * 24 + 12;
                        my $upper_bound = ($k) * 24 + 12;
#                        print "k = $k lower = $lower_bound upper = $upper_bound diff = $hour_diff\n";
                        if ($hour_diff > $lower_bound && $hour_diff < $upper_bound) {
                            $epoch{$k} = $epoch_hours{$hour_diff};
                        }
                       $k++; 
                    }
                }
# finally, iterate through the epoch values printing the result.
                my $some_data = 0;
                for (my $k = - $pre; $k <= $post; $k++) {
                        printf "day %2d, ", $k;
                        my $outPath = "/tmp/sundata/david_storms/bb/";
                        #   print " epoch{k} " . $epoch{$k} . " k = $k \n";
                    if (!exists($epoch{$k})) {
                        my @epoch_time = ($storms[$j] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/, 0);
                        printf "%4d-%02d-%02d", Add_Delta_Days(@epoch_time[0..2], $k);
                        print ", no data\n";
                        push(@{$outImages{$storms[$j]}}, $outPath . "no_data.png");
                    }
                    else { 
                        my $fileTime = $obs_times[$epoch{$k}];
#                        print Dumper $sunImages{$fileTime}{'MDI_SunImage'};
                        print "$fileTime \n";
                        my @fileTime = ($fileTime =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/);
                        my $rotatedStr = "";
                        if (defined(@{$sunImages{$fileTime}{$archiveName}}[0])) {
#                            print "\n sunimg = " . $sunImages{$fileTime}{'MDI_SunImage'}[0];
                            $rotatedStr = ".rotated";
                #            print @{$sunImages{$fileTime}{$archiveName}}[0];
                        }
                        my $fileName = @{$sunImages{$fileTime}{$archiveName}}[0]; 
#                        . $fileTime[0].".".$fileTime[1].".".$fileTime[2] .
#                            "_".$fileTime[3].":".$fileTime[4].$rotatedStr.".gif";
                        my $outFileName = $fileName;
                        $outFileName =~ s/\./_/g;
                        $outFileName =~ s/\:/_/g;
                        my $wgetCommand = "wget -O $outPath$outFileName ftp://ftp.bbso.njit.edu/pub/archive/" .
                            $fileTime[0] . "/" . $fileTime[1] . "/" . $fileTime[2] . "/" . $fileName; 
                            #print "$wgetCommand\n"; 
                            #          system ($wgetCommand);
                        $some_data = 1;
                        #            print "match storm: " . $storms[$j] . "\n";
                        push(@{$outImages{$storms[$j]}}, $outPath . $outFileName . ".png");
                    }
                }
                if (!$some_data) {
                    print "no data at all!\n";
                    pop @storms_found; # change our mind, we didn't find a storm.
                }
                if ($i == scalar @obs_times || $j == scalar @storms) {
                    goto SUMMARY;
                }
            }
            $j++;
            @time1 = ($obs_times[$i] =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+)/ ,0);
        }
        $i++;
    } 
SUMMARY:    
    if ($i == scalar @obs_times || $j == scalar @storms) {
        print "finished processing.\n";
        print "searched $i records of " . @obs_times . " total spot records.\n";
        print "found ". @storms_found . " of a total of " . @storms . " storms:\n";
        print "@storms_found\n";
        my %storms_caught = ();
        @storms_caught{@storms_found} = ();
        @storms_missed = grep(!exists($storms_caught{$_}), @storms);
        print "data was missing for the following " . @storms_missed . " storms:\n";
        print "@storms_missed\n";

        # now generate some tex to build the images into a table.
        
        if (1) {
        my $numberPerTable = $pre + $post - 1;
        my $startRowNumber = 0;
        print "simple tex table:";
        print "-----------------";
        foreach my $stormDate (sort keys %outImages) {
            print "\\tiny \\begin{sideways} $stormDate \\end{sideways} &\n";
            $startRowNumber = 1;
            foreach my $imageFile (@{$outImages{$stormDate}}) {
                print "\\includegraphics[scale=\\imgScale]{$imageFile}";
                if ($startRowNumber % ($numberPerTable + 1) == 0) {
                    print " \\\\ \n";
                }
                else {
                    print " &\n";
                }
                $startRowNumber++;
                if ($startRowNumber == $numberPerTable + 2) {
                    print "%";
                }
            }
        }
        }
        exit 0; 
    } 
}

# this code loads sunspot data from the faculae dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot_and_Faculae {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot_and_faculae;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}
# this code loads sunspot data from the greenwich dataset. It is more complicated
# due to the dataset which contains more types of data.
sub Load_Sunspot {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDateTime}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}
# this code loads sun image availability from the MDI archive
sub Load_SunImages {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
#        my $test_spot = new sunspot;
        my $test_spot = "The image is available at Big Bear";
#        $test_spot->parse_data_into_object($line);
        my ($dateTime, $filename, $month, $day, $year, $size) = split(' ', $line);
        my $time = substr($filename,23,6);
        my $minutes = substr($time,0,2);
        my $seconds = substr($time, 2,2);
        #     print "date = $dateTime , time = $minutes:$seconds size = $size\n";
        $test_spot = $filename;
       push(@{$sunspot_array{$dateTime . " $minutes:$seconds"}{$archiveName}}, $test_spot);
    }
    return %sunspot_array;
}

sub numeric {
    $a <=> $b;
}

# this is a list of davids aurora dates, for testing at the moment.
sub get_storm_dates {
    my @epochs = qw(
        1957-03-02
        1957-07-05
        1957-09-13
        1957-09-21
        1958-02-11
        1958-12-13
        1960-03-30
        1960-04-30
        1960-11-13
    );
    return \@epochs;
}

#davids japaniese aurora dates.
sub get_storm_dates_complete {
    my @epochs = qw( 
        1957-03-02_12:00
        1957-07-05_11:20
        1957-09-13_09:30
        1957-09-21_13:50
        1958-02-11_09:55
        1958-12-13_09:10
        1960-03-30_12:00
        1960-04-30_13:35
        1960-11-13_10:06
        1989-10-21_11:35
        1992-02-26_18:35
        1992-02-27_11:00
        1992-02-29_15:58
        1992-05-10_12:09
        1993-09-13_10:22
        1999-02-18_13:00
        1999-05-13_15:00
        2000-04-06_17:00
        2000-04-07_12:00
        2000-11-06_16:00
        2000-11-29_11:20
        2001-03-31_16:00 
        2001-03-31_10:00 
        2001-03-31_16:00 
        2001-04-28_14:30
        2001-10-21_18:00
        2001-11-06_12:00
        2001-11-24_12:00
        2001-11-24_12:00
        2001-11-24_16:00
        2002-04-17_15:00
        2003-05-29_16:00
        2003-10-24_15:40
        2003-10-29_10:20
        2003-10-29_08:30
        2003-10-30_17:00
        2003-10-30_11:00 
        2003-10-30_18:00
        2003-10-31_08:30
        2003-10-31_08:30 
        2003-11-20_18:00
        2003-11-21_13:30 
        2004-11-08_08:30
    );
    my @epochsParsed = ();
    foreach my $dateStr (@epochs) {
        $dateStr =~ s/_/ /;
        push (@epochsParsed, $dateStr);
    }
    return \@epochsParsed;
}
        
        

# this is a list of all the times when there is a storm - measured by greenwich.
sub get_epoch_dates {
    my @epochs = qw(
        1874-10-03
        1880-08-12
        1881-01-30
        1881-09-12
        1882-04-17
        1882-04-20
        1882-06-24
        1882-08-04
        1882-11-17
        1882-11-20
        1883-04-03
        1883-09-16
        1884-07-02
        1885-03-15
        1885-05-25
        1886-03-30
        1891-05-13
        1892-02-13
        1892-03-06
        1892-03-11
        1892-04-25
        1892-05-18
        1892-06-27
        1892-07-12
        1892-07-16
        1892-08-12
        1893-08-18
        1894-02-22
        1894-02-25
        1894-02-28
        1894-03-30
        1894-07-20
        1894-08-20
        1894-09-14
        1894-11-13
        1898-03-15
        1898-09-09
        1900-05-05
        1903-10-31
        1903-12-13
        1907-02-09
        1908-09-11
        1908-09-29
        1909-01-03
        1909-05-14
        1909-09-25
        1915-06-17
        1917-08-09
        1917-08-13
        1918-08-15
        1919-08-11
        1920-03-04
        1920-03-22
        1921-05-13
        1926-01-26
        1926-02-23
        1926-04-14
        1926-10-13
        1927-07-21
        1927-08-20
        1927-10-12
        1928-05-27
        1928-07-07
        1929-02-27
        1929-03-11
        1932-05-29
        1937-02-03
        1937-04-26
        1937-04-27
        1938-01-16
        1938-01-22
        1938-01-25
        1938-04-16
        1938-05-11
        1939-02-24
        1939-04-16
        1939-04-24
        1939-08-16
        1939-08-22
        1939-10-13
        1940-03-24
        1940-03-29
        1940-03-31
        1940-06-25
        1941-03-01
        1941-07-04
        1941-09-18
        1942-03-01
        1943-08-28
        1944-04-01
        1944-12-15
        1946-02-07
        1946-03-23
        1946-03-28
        1946-04-23
        1946-07-26
        1946-09-21
        1947-03-02
        1947-04-17
        1947-07-17
        1947-08-22
        1947-09-23
        1948-08-08
        1948-08-09
        1948-10-17
        1949-01-24
        1949-01-25
        1949-05-12
        1949-10-15
        1950-02-20
        1950-08-18
        1951-09-25
        1951-10-28
        1952-04-21
        1952-06-29
    );
    return \@epochs;
}

