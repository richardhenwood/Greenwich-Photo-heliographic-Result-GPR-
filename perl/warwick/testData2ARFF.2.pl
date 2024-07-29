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
use Date::Calc qw( Days_in_Year Add_Delta_Days Delta_DHMS);
use List::Util qw(sum);
use Getopt::Std;

# this program compiles our training datafile from greenwich data and training associations
# which are stored in another file.
#

my %opts = ();
getopts("f:t:d", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{t})) { usage(); }

my %sunspots = ();
my %linkedSpots = ();
%linkedSpots = &Load_Link_Tests($opts{t});

&ARFFheader;
if (defined($opts{d})) {
    %sunspots = &Load_Sunspot_DateCentric($opts{f});
    &printDateCentricSpots();
}
else { 
    %sunspots = &Load_Sunspot_SpotCentric($opts{f});
    &printLinkedSpotsARFF();
}

sub Load_Link_Tests {
    my $filename = shift;
    my %linkspot_array = ();
    my $startingSpot = "";
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        #print "line = $line";
        chop($line);
        if ($line =~ m/for spot:/) {
            $line =~ s/.* (\d+),.*/$1/;
            $startingSpot = $line;
            #print "starting spot = $startingSpot\n";
        }
        elsif ($line =~ m/^\d+/) {
            push(@{$linkspot_array{$startingSpot}}, $line);
        }
    }
    return %linkspot_array;
}

sub ARFFheader {
    print <<ARFFHEADER;
%
% 1. Title: Linked spots of the Greenwich dataset for solar cycle 15.
%
\@RELATION Cycle15ReoccurantSpots

\@ATTRIBUTE pairnumber  NUMERIC

\@ATTRIBUTE latitude_pre_01 NUMERIC
\@ATTRIBUTE longitude_pre_01 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_01 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_01 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_01 NUMERIC
\@ATTRIBUTE wholespot_pre_01 NUMERIC

\@ATTRIBUTE latitude_pre_02 NUMERIC
\@ATTRIBUTE longitude_pre_02 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_02 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_02 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_02 NUMERIC
\@ATTRIBUTE wholespot_pre_02 NUMERIC

\@ATTRIBUTE latitude_pre_03 NUMERIC
\@ATTRIBUTE longitude_pre_03 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_03 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_03 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_03 NUMERIC
\@ATTRIBUTE wholespot_pre_03 NUMERIC

\@ATTRIBUTE latitude_pre_04 NUMERIC
\@ATTRIBUTE longitude_pre_04 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_04 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_04 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_04 NUMERIC
\@ATTRIBUTE wholespot_pre_04 NUMERIC

\@ATTRIBUTE latitude_pre_05 NUMERIC
\@ATTRIBUTE longitude_pre_05 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_05 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_05 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_05 NUMERIC
\@ATTRIBUTE wholespot_pre_05 NUMERIC

\@ATTRIBUTE latitude_pre_06 NUMERIC
\@ATTRIBUTE longitude_pre_06 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_06 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_06 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_06 NUMERIC
\@ATTRIBUTE wholespot_pre_06 NUMERIC

\@ATTRIBUTE latitude_pre_07 NUMERIC
\@ATTRIBUTE longitude_pre_07 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_07 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_07 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_07 NUMERIC
\@ATTRIBUTE wholespot_pre_07 NUMERIC

\@ATTRIBUTE latitude_pre_08 NUMERIC
\@ATTRIBUTE longitude_pre_08 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_08 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_08 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_08 NUMERIC
\@ATTRIBUTE wholespot_pre_08 NUMERIC

\@ATTRIBUTE latitude_pre_09 NUMERIC
\@ATTRIBUTE longitude_pre_09 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_09 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_09 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_09 NUMERIC
\@ATTRIBUTE wholespot_pre_09 NUMERIC

\@ATTRIBUTE latitude_pre_10 NUMERIC
\@ATTRIBUTE longitude_pre_10 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_10 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_10 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_10 NUMERIC
\@ATTRIBUTE wholespot_pre_10 NUMERIC

\@ATTRIBUTE latitude_pre_11 NUMERIC
\@ATTRIBUTE longitude_pre_11 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_11 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_11 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_11 NUMERIC
\@ATTRIBUTE wholespot_pre_11 NUMERIC

\@ATTRIBUTE latitude_pre_12 NUMERIC
\@ATTRIBUTE longitude_pre_12 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_12 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_12 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_12 NUMERIC
\@ATTRIBUTE wholespot_pre_12 NUMERIC

\@ATTRIBUTE latitude_pre_13 NUMERIC
\@ATTRIBUTE longitude_pre_13 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_13 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_13 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_13 NUMERIC
\@ATTRIBUTE wholespot_pre_13 NUMERIC

\@ATTRIBUTE latitude_pre_14 NUMERIC
\@ATTRIBUTE longitude_pre_14 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_14 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_14 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_14 NUMERIC
\@ATTRIBUTE wholespot_pre_14 NUMERIC

\@ATTRIBUTE latitude_pre_15 NUMERIC
\@ATTRIBUTE longitude_pre_15 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_15 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_15 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_15 NUMERIC
\@ATTRIBUTE wholespot_pre_15 NUMERIC

\@ATTRIBUTE latitude_pre_16 NUMERIC
\@ATTRIBUTE longitude_pre_16 NUMERIC
\@ATTRIBUTE longitudeSTR_pre_16 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_pre_16 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_pre_16 NUMERIC
\@ATTRIBUTE wholespot_pre_16 NUMERIC

\@ATTRIBUTE latitude_post_17 NUMERIC
\@ATTRIBUTE longitude_post_17 NUMERIC
\@ATTRIBUTE longitudeSTR_post_17 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_17 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_17 NUMERIC
\@ATTRIBUTE wholespot_post_17 NUMERIC

\@ATTRIBUTE latitude_post_18 NUMERIC
\@ATTRIBUTE longitude_post_18 NUMERIC
\@ATTRIBUTE longitudeSTR_post_18 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_18 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_18 NUMERIC
\@ATTRIBUTE wholespot_post_18 NUMERIC

\@ATTRIBUTE latitude_post_19 NUMERIC
\@ATTRIBUTE longitude_post_19 NUMERIC
\@ATTRIBUTE longitudeSTR_post_19 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_19 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_19 NUMERIC
\@ATTRIBUTE wholespot_post_19 NUMERIC

\@ATTRIBUTE latitude_post_20 NUMERIC
\@ATTRIBUTE longitude_post_20 NUMERIC
\@ATTRIBUTE longitudeSTR_post_20 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_20 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_20 NUMERIC
\@ATTRIBUTE wholespot_post_20 NUMERIC

\@ATTRIBUTE latitude_post_21 NUMERIC
\@ATTRIBUTE longitude_post_21 NUMERIC
\@ATTRIBUTE longitudeSTR_post_21 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_21 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_21 NUMERIC
\@ATTRIBUTE wholespot_post_21 NUMERIC

\@ATTRIBUTE latitude_post_22 NUMERIC
\@ATTRIBUTE longitude_post_22 NUMERIC
\@ATTRIBUTE longitudeSTR_post_22 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_22 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_22 NUMERIC
\@ATTRIBUTE wholespot_post_22 NUMERIC

\@ATTRIBUTE latitude_post_23 NUMERIC
\@ATTRIBUTE longitude_post_23 NUMERIC
\@ATTRIBUTE longitudeSTR_post_23 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_23 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_23 NUMERIC
\@ATTRIBUTE wholespot_post_23 NUMERIC

\@ATTRIBUTE latitude_post_24 NUMERIC
\@ATTRIBUTE longitude_post_24 NUMERIC
\@ATTRIBUTE longitudeSTR_post_24 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_24 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_24 NUMERIC
\@ATTRIBUTE wholespot_post_24 NUMERIC

\@ATTRIBUTE latitude_post_25 NUMERIC
\@ATTRIBUTE longitude_post_25 NUMERIC
\@ATTRIBUTE longitudeSTR_post_25 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_25 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_25 NUMERIC
\@ATTRIBUTE wholespot_post_25 NUMERIC

\@ATTRIBUTE latitude_post_26 NUMERIC
\@ATTRIBUTE longitude_post_26 NUMERIC
\@ATTRIBUTE longitudeSTR_post_26 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_26 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_26 NUMERIC
\@ATTRIBUTE wholespot_post_26 NUMERIC

\@ATTRIBUTE latitude_post_27 NUMERIC
\@ATTRIBUTE longitude_post_27 NUMERIC
\@ATTRIBUTE longitudeSTR_post_27 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_27 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_27 NUMERIC
\@ATTRIBUTE wholespot_post_27 NUMERIC

\@ATTRIBUTE latitude_post_28 NUMERIC
\@ATTRIBUTE longitude_post_28 NUMERIC
\@ATTRIBUTE longitudeSTR_post_28 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_28 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_28 NUMERIC
\@ATTRIBUTE wholespot_post_28 NUMERIC

\@ATTRIBUTE latitude_post_29 NUMERIC
\@ATTRIBUTE longitude_post_29 NUMERIC
\@ATTRIBUTE longitudeSTR_post_29 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_29 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_29 NUMERIC
\@ATTRIBUTE wholespot_post_29 NUMERIC

\@ATTRIBUTE latitude_post_30 NUMERIC
\@ATTRIBUTE longitude_post_30 NUMERIC
\@ATTRIBUTE longitudeSTR_post_30 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_30 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_30 NUMERIC
\@ATTRIBUTE wholespot_post_30 NUMERIC

\@ATTRIBUTE latitude_post_31 NUMERIC
\@ATTRIBUTE longitude_post_31 NUMERIC
\@ATTRIBUTE longitudeSTR_post_31 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_31 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_31 NUMERIC
\@ATTRIBUTE wholespot_post_31 NUMERIC

\@ATTRIBUTE latitude_post_32 NUMERIC
\@ATTRIBUTE longitude_post_32 NUMERIC
\@ATTRIBUTE longitudeSTR_post_32 {longitude_010, longitude_020, longitude_030, longitude_040, longitude_050, longitude_060, longitude_070, longitude_080, longitude_090, longitude_100, longitude_110, longitude_120, longitude_130, longitude_140, longitude_150, longitude_160, longitude_170, longitude_180, longitude_190, longitude_200, longitude_210, longitude_220, longitude_230, longitude_240, longitude_250, longitude_260, longitude_270, longitude_280, longitude_290, longitude_300, longitude_310, longitude_320, longitude_330, longitude_340, longitude_350, longitude_360}
\@ATTRIBUTE timestamp_post_32 DATE "yyyy-MM-dd HH:mm"
\@ATTRIBUTE umbral_post_32 NUMERIC
\@ATTRIBUTE wholespot_post_32 NUMERIC

\@ATTRIBUTE pre_greenwichNumber      NUMERIC
\@ATTRIBUTE post_greenwichNumber      NUMERIC

\@ATTRIBUTE classification  {linked, notlinked}

\@DATA
ARFFHEADER
}

sub printLinkedSpotsARFF {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    my $daysFromLimb = 1;
    my $pairNumber = 1;

    foreach my $initialSpot (keys (%linkedSpots)) {
        #print "initial spot = $initialSpot\n";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
        my $classification = "notlinked";
        my $preGreenwichNumber = "";
        my $postGreenwichNumber = "";
        foreach my $linkCandidate (@{$linkedSpots{$initialSpot}}) {
            my $initialSpotARFF = "";
            my $linkedSpotARFF = "";
            my $outputValues = 0;
            if ($linkCandidate =~ m/y/) {
                $classification = "linked";
            }
            else { $classification = "notlinked";}
            $linkCandidate =~ s/(\d+).*/$1/;
            #         print "link = $initialSpot -> $linkCandidate = $classification\n";
            my $daysFromLimb = 1;
            foreach my $obsTime (reverse sort keys %{$sunspots{$initialSpot}}) {
                foreach my $spot (@{$sunspots{$initialSpot}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $initialSpotARFF .= ", ?";
                        $initialSpotARFF .= ", ?";
                        $initialSpotARFF .= ", ?";
                        $initialSpotARFF .= ", ?";
                        $initialSpotARFF .= ", ?";
                        $initialSpotARFF .= ", ?";

                        $daysFromLimb++;
                        $foundStart = 1;
                        $outputValues++;
                    }

                    $initialSpotARFF .= ", " . $spot->getLatitude;
                    $initialSpotARFF .= ", " . $spot->getCarringtonLongitude;
                    $initialSpotARFF .= sprintf (", longitude_%02d0", 1 + $spot->getCarringtonLongitude/10);
                    $initialSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    $initialSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $initialSpotARFF .= ", " . $spot->getCorrectedWholeSpotArea;

                    $preGreenwichNumber = $spot->getGroupNumber;

                    $daysFromLimb++;
                    $outputValues++;
                }
            }
            while ($daysFromLimb <= 16) {
                $initialSpotARFF .= ", ?";
                $initialSpotARFF .= ", ?";
                $initialSpotARFF .= ", ?";
                $initialSpotARFF .= ", ?";
                $initialSpotARFF .= ", ?";
                $initialSpotARFF .= ", ?";

                $daysFromLimb++;
                $outputValues++;
            }
            
            foreach my $obsTime (reverse sort keys %{$sunspots{$linkCandidate}}) {
                foreach my $spot (@{$sunspots{$linkCandidate}{$obsTime}}) {
                    my $thisSpotDateTime = $spot->getDateTime;
                    if (!defined($firstGroupTime)) {
                        $firstGroupTime = $thisSpotDateTime;
                    }
                    my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                    while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                        $linkedSpotARFF .= ", ?";
                        $linkedSpotARFF .= ", ?";
                        $linkedSpotARFF .= ", ?";
                        $linkedSpotARFF .= ", ?";
                        $linkedSpotARFF .= ", ?";
                        $linkedSpotARFF .= ", ?";

                        $daysFromLimb++;
                        $foundStart = 1;
                        #print "days = $daysFromLimb ";
                        $outputValues++;
                    }

                    $linkedSpotARFF .= ", " . $spot->getLatitude;
                    $linkedSpotARFF .= ", " . $spot->getCarringtonLongitude;
                    $linkedSpotARFF .= sprintf (", longitude_%02d0", 1 + $spot->getCarringtonLongitude/10);
                    $linkedSpotARFF .= ", \"". $spot->getDateTime . "\"";
                    $linkedSpotARFF .= ", " . $spot->getCorrectedUmbralArea;
                    $linkedSpotARFF .= ", " . $spot->getCorrectedWholeSpotArea;

                    $postGreenwichNumber = $spot->getGroupNumber;

                    $daysFromLimb++;
                    $outputValues++;
                }
            }
            while ($daysFromLimb <= 32) {
                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= ", ?";
                $linkedSpotARFF .= ", ?";

                $daysFromLimb++;
                $outputValues++;
            }

            print $pairNumber;
            print "$initialSpotARFF";
            print "$linkedSpotARFF";
            
            print ", " . $preGreenwichNumber;
            print ", " . $postGreenwichNumber;
            print ", " . $classification;
            print "\n";
            #print " - values = $outputValues\n\n";
            $pairNumber++;
        }
    }
    if (0) {
    foreach my $spotNumber (keys (%sunspots)) {
        #print $spotNumber;
        print "spot group\n";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
       
        # we want to write out data with position_1 being closet to the time
        # when the spot is obscured by solar rotation.
        # this means that we need to order the spots before and after 
        # obscuring opposite cronologically.
        foreach my $obsTime (reverse sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                my $thisSpotDateTime = $spot->getDateTime;
                if (!defined($firstGroupTime)) {
                    $firstGroupTime = $thisSpotDateTime;
                }
                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                    $daysFromLimb++;
                    $foundStart = 1;
                }

                print "position_$daysFromLimb ";
                print $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCarringtonLongitude;
                print " ";
                print $spot->getSun_West_Limb;
                print " ";

#                print $spot->getSun_West_Limb - $spot->getCarringtonLongitude;
#                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
#                print " degrees from limb = $degreesFromLimb ";
#                print "within degrees: ". $dayDegrees * $daysFromLimb;
#                if ($degreesFromLimb < $dayDegrees * $daysFromLimb) {
#                    print " days from limb = $daysFromLimb ";
#                }
                #my $westLimb = $spot->getSun_West_Limb;
                #my $position = ($westLimb - $dayDegrees) % 360;
                #print $position;
                $daysFromLimb++;
                
                print "\n";
            }
        }
    }
    }
}

sub printSpotCentricSpots {
    my $dayDegrees = 180 / 15; # 15 is the maximum number of times a spot may be observed
    my $preSunspot = 1;
    my $daysFromLimb = 1;
    foreach my $spotNumber (keys (%sunspots)) {
        #print $spotNumber;
        print "spot group\n";
        my $foundStart = 0;
        my $firstGroupTime;
        my $secondGroupTime;
       
        # we want to write out data with position_1 being closet to the time
        # when the spot is obscured by solar rotation.
        # this means that we need to order the spots before and after 
        # obscuring opposite cronologically.
        foreach my $obsTime (reverse sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                my $thisSpotDateTime = $spot->getDateTime;
                if (!defined($firstGroupTime)) {
                    $firstGroupTime = $thisSpotDateTime;
                }
                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
                while ($degreesFromLimb < $dayDegrees * $daysFromLimb && !$foundStart) {
                    $daysFromLimb++;
                    $foundStart = 1;
                }

                print "position_$daysFromLimb ";
                print $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCarringtonLongitude;
                print " ";
                print $spot->getSun_West_Limb;
                print " ";

#                print $spot->getSun_West_Limb - $spot->getCarringtonLongitude;
#                my $degreesFromLimb = abs($spot->getSun_West_Limb - $spot->getCarringtonLongitude);
#                print " degrees from limb = $degreesFromLimb ";
#                print "within degrees: ". $dayDegrees * $daysFromLimb;
#                if ($degreesFromLimb < $dayDegrees * $daysFromLimb) {
#                    print " days from limb = $daysFromLimb ";
#                }
                #my $westLimb = $spot->getSun_West_Limb;
                #my $position = ($westLimb - $dayDegrees) % 360;
                #print $position;
                $daysFromLimb++;
                
                print "\n";
            }
        }
    }
}

sub printDateCentricSpots {
    foreach my $obsTime (sort keys (%sunspots)) {
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
                print $spot->getDateTime;
                my $thisSpotDateTime = $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print " ";
                print $spot->getSun_East_Limb;
                print " ";
                print $spot->getSun_West_Limb;

                print "\n";
            }
        }
    }
}

# this subroutine loads greenwich data into a hash with the spot number as the key.
sub Load_Sunspot_SpotCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        # ignore all lines which start with a '#' or are blank
        if (!($line =~ m/^</ || $line =~ m/^\s+/)) {
            my $test_spot = new sunspot;
            $test_spot->parse_data_into_object($line);
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}}, $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{'group_total'}{$test_spot->getDateTime}}, $test_spot);
            }
        }
    }
    return %sunspot_array;
}

# this subroutine loads the sunspot data with the sunspot number as the key.
# it is not currently used in this template - but may come in handy later!
sub Load_Sunspot_DateCentric {
    my $filename = shift;
    my %sunspot_array = ();
    open (FH, $filename);
    while (defined (my $line = <FH>)) {
        if (!($line =~ m/^</ || $line =~ m/^\s+/)) {
            my $test_spot = new sunspot;
            $test_spot->parse_data_into_object($line);
            if ($test_spot->is_spot()) {
                push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumber()}}, $test_spot);
            }
            elsif ($test_spot->is_group_total()) {
                push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
            }
        }
    }
    return %sunspot_array;
}

sub usage {
    print STDERR << "EOF";

This program creates ARFF format data from Greenwich format data.

See http://weka.sourceforge.net/wekadoc/index.php/en:ARFF_%283.4.6%29 for ARFF format.
See http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt or Greenwich format.
The link candidates format is self documenting.

usage: $0 -f file -t triningdata

-f      : file containing data, in Greenwich format.
-t      : file containing link candidates in our made up format

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -t ~sfell/sunspotData/cycle15latitudeFilteredMulti.txt
EOF
    exit;
}
                                                                                                                        


# this function always comes in handy:
#sub numeric {
#    $a <=> $b;
#}

