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


# thisis a template file which provides a spot centric has of
# sunspot data - presented in Greenwich format.
#
sub usage {
    print STDERR << "EOF";

This program loads a Greenwich format data into a spot centric hash.
http://www.ukssdc.ac.uk/wdcc1/greenwich/grnwich.fmt for Greenwich format.
See the code example to illustrate what a spot centric hash is.

usage: $0 -f file

-f      : file containing data, in Greenwich format.

example: $0 -f /users/rhenwood/ihr/data/greenwich/1938.grp -o output.tex
EOF
    exit;
}

my %opts = ();
getopts("f:o:", \%opts) ;
if (!defined($opts{f})) { usage(); }
if (!defined($opts{o})) { usage(); }

my %sunspots = ();
#print $opts{f};
%sunspots = &Load_Sunspot_DateCentric($opts{f});
    
my $latex = &printDateCentricSpots();
open (LATEX, '>>'.$opts{o});
print LATEX $latex;
close (LATEX);

sub printSpotCentricSpots {
    foreach my $spotNumber (sort numeric keys (%sunspots)) {
        foreach my $obsTime (sort keys %{$sunspots{$spotNumber}}) {
            foreach my $spot (@{$sunspots{$spotNumber}{$obsTime}}) {
                print $spot->getDateTime;
                print " ";
                print $spot->getGroupNumber;
                print " ";
                print $spot->getCorrectedWholeSpotArea;
                print " ";
                print $spot->getCorrectedUmbralArea;
                print "\n";
            }
        }
    }
}
sub printDateCentricSpots {
    my $latex = "";
    $latex = <<EOF;
\\documentclass[11pt,a4paper,twoside]{report}      %% LaTeX2e document.
\\usepackage{graphicx}                %% Preamble.
\\usepackage{array}
\\usepackage{fullpage}
\\usepackage{longtable}
\\renewcommand{\\familydefault}{cmss}

\\newcommand{\\tablewidth}{100}

\\begin{document}

\\thispagestyle{empty}

\\begin{longtable}{c c c c c}
EOF

    my %figures;


    foreach my $obsTime (sort keys (%sunspots)) {
        #print "obstime = $obsTime";
        my $date = $obsTime;
        $date =~ s/\-//g;
        my $outdir = "/tmp/500_bigger/";
        my $figCMD = "java -jar /users/rhenwood/workspace/sunspot.jar -dout $outdir -d $date -dsn /users/rhenwood/ihr/sunspots/perl/david_500/spot_500_or_bigger.txt -canvas planarradial";
        print "$figCMD\n"; 
        #print `$figCMD`; 
        $figures{$obsTime} = $outdir . $date . ".eps";
        foreach my $spotNumber (sort keys %{$sunspots{$obsTime}}) {
            foreach my $spot (@{$sunspots{$obsTime}{$spotNumber}}) {
            }
        }
    }
    my $count = 0;
    my $figstr = "";
    my $labelstr = "";
    #while ( my ($date, $file) = each (%figures)) {
    foreach  my $date (sort keys %figures) {
        my $file = $figures{$date};
        $figstr .= "\\includegraphics[width=\\tablewidth\\unitlength]{$file}&\n";
        $labelstr .= "{\\tiny{$date}} &\n";
        #print "date $date file $file\n";
        if ($count % 4 == 3) {
            $latex .= "$figstr\\\\\n\n$labelstr\\\\\n\n";
            $figstr = "";
            $labelstr = "";
            #print "a batch of four is complete!";
        }
        $count++;
    }
    $latex .= <<EOF;

\\end{longtable}

\\end{document}
EOF
    return $latex;
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
                push(@{$sunspot_array{$test_spot->getGroupNumber()}{$test_spot->getDateTime}},
                $test_spot);
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
        my $test_spot = new sunspot;
        $test_spot->parse_data_into_object($line);
        if ($test_spot->is_spot()) {
            push(@{$sunspot_array{$test_spot->getDate}{$test_spot->getGroupNumber()}},
            $test_spot);
        }
        elsif ($test_spot->is_group_total()) {
            push(@{$sunspot_array{$test_spot->getDate}{'group_total'}}, $test_spot);
        }
    }
    return %sunspot_array;
}

                                                                                                                        


# this function always comes in handy:
sub numeric {
    $a <=> $b;
}





#%  \end{tabular}
#\end{longtable}
#
#\end{document}

