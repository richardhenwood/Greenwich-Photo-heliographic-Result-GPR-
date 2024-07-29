#!/usr/local/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 4.3 patchlevel 0
#    	last modified June 2007
#    	System: Linux 2.6.18.8-0.7-default
#    
#    	Copyright (C) 1986 - 1993, 1998, 2004, 2007
#    	Thomas Williams, Colin Kelley and many others
#    
#    	Type `help` to access the on-line reference manual.
#    	The gnuplot FAQ is available from
#    		http://www.gnuplot.info/faq/
#    
#    	Send comments and help requests to  <gnuplot-beta@lists.sourceforge.net>
#    	Send bug reports and suggestions to <gnuplot-beta@lists.sourceforge.net>
#    
# set terminal x11 
# set output

reset

outputFilename = "yearCats.tex"
if ("$0" eq "latex") set term epslatex color dashed; set output outputFilename






unset clip points
set clip one
set clip two
set bar 1.000000
set border 31 front linetype -1 linewidth 1.000
set xdata
set ydata
set zdata
set x2data
set y2data
set timefmt x "%d/%m/%y,%H:%M"
set timefmt y "%d/%m/%y,%H:%M"
set timefmt z "%d/%m/%y,%H:%M"
set timefmt x2 "%d/%m/%y,%H:%M"
set timefmt y2 "%d/%m/%y,%H:%M"
set timefmt cb "%d/%m/%y,%H:%M"
set boxwidth 1 absolute
set style fill  empty border
set style rectangle back fc lt -3 fillstyle   solid 1.00 border -1
set dummy x,y
set format x "% g"
set format y "% g"
set format x2 "% g"
set format y2 "% g"
set format z "% g"
set format cb "% g"
set angles radians
unset grid
#set key title ""
#set key inside right top vertical Right noreverse enhanced autotitles nobox
#set key noinvert samplen 4 spacing 1 width 0 height 0 
unset label
unset arrow
set style increment default
unset style line
unset style arrow
set style histogram clustered gap 2 title  offset character 0, 0, 0
unset logscale
set offsets 0, 0, 0, 0
set pointsize 1
set encoding default
unset polar
unset parametric
unset decimalsign
set view 60, 30, 1, 1
set samples 100, 100
set isosamples 10, 10
set surface
unset contour
set clabel '%8.3g'
set mapping cartesian
set datafile separator whitespace
unset hidden3d
set cntrparam order 4
set cntrparam linear
set cntrparam levels auto 5
set cntrparam points 5
set size ratio 0 1,1
set origin 0,0
set style function lines
set xzeroaxis linetype -2 linewidth 1.000
set yzeroaxis linetype -2 linewidth 1.000
set zzeroaxis linetype -2 linewidth 1.000
set x2zeroaxis linetype -2 linewidth 1.000
set y2zeroaxis linetype -2 linewidth 1.000
set ticslevel 0.5
set mxtics default
set mytics default
set mztics default
set mx2tics default
set my2tics default
set mcbtics default
set xtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0
set xtics 
#set xtics   ("Jan" 0.00000, "Feb" 1.00000, "Mar" 2.00000, "Apr" 3.00000, "May" 4.00000, "Jun" 5.00000, "Jul" 6.00000, "Aug" 7.00000, "Sep" 8.00000, "Oct" 9.00000, "Nov" 10.0000, "Dec" 11.0000) scale 0
set ytics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0
set ytics autofreq 
set ztics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0
set ztics autofreq 
set nox2tics
set noy2tics
set cbtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0
set cbtics autofreq 
set title "" 
set title  offset character 0, 0, 0 font "" norotate
set timestamp bottom 
set timestamp "" 
set timestamp  offset character 0, 0, 0 font "" norotate
set rrange [ * : * ] noreverse nowriteback  # (currently [8.98847e+307:-8.98847e+307] )
set trange [ * : * ] noreverse nowriteback  # (currently [-5.00000:5.00000] )
set urange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set vrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set xlabel "" 
set xlabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
set x2label "" 
set x2label  offset character 0, 0, 0 font "" textcolor lt -1 norotate
set xrange [ * : * ] noreverse nowriteback  # (currently [-1.00000:12.0000] )
set x2range [ * : * ] noreverse nowriteback  # (currently [-1.00000:12.0000] )
set ylabel "" 
set ylabel  offset character 0, 0, 0 font "" textcolor lt -1 rotate by 90
set y2label "" 
set y2label  offset character 0, 0, 0 font "" textcolor lt -1 rotate by 90
set yrange [ * : * ] noreverse nowriteback  # (currently [0.00000:16.0000] )
set y2range [ * : * ] noreverse nowriteback  # (currently [0.00000:15.0000] )
set zlabel "" 
set zlabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
set zrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set cblabel "" 
set cblabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
set cbrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
set zero 1e-08
set lmargin  -1
set bmargin  -1
set rmargin  -1
set tmargin  -1
set locale "C"
set pm3d explicit at s
set pm3d scansautomatic
set pm3d interpolate 1,1 flush begin noftriangles nohidden3d corners2color mean
set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
set palette rgbformulae 7, 5, 15
set colorbox default
set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 bdefault
set loadpath 
set fontpath 
set fit noerrorvariables
GNUTERM = "x11"



set style histogram rowstacked title offset character 0, 0, 0
set boxwidth 0.9 relative
set datafile missing '-'
set datafile separator whitespace
set style data histograms
set style fill pattern 0
#set key reverse invert autotitles columnhead
#set xtics ("Jan" 0.5, "Feb" 1.5, "Mar" 2.5, "Apr" 3.5, "May" 4.5, "Jun" 5.5, "Jul" 6.5, "Aug" 7.5, "Sep" 8.5, "Oct" 9.5, "Nov" 10.5, "Dec" 11.5)

set ylabel "frequency"
set xlabel "lunar bin"
#set title "Catalogue of 'red firelike' with lunar cycle"
set key   samplen 2 autotitles columnhead

set multiplot layout 2,1 
#set size square
#plot '< /usr/bin/convert day17.jpg  avs:-' binary filetype=avs center=(0,0) dx=0.0025 dy=0.0025 with rgbimage notitle
#
#set size nosquare

imgDy = 0.006
imgDx = 0.0025

set yrange [0:*]

#unset xlabel
#unset xtics
set xlabel "lunar age"

set size 1,0.8
set origin 0,0.0
plot '< cat ./RSdata.txt | ./genLunarHistogram.pl' using 2:xtic(1) fs solid lc rgb "dark-red" lt 1, \
'' u 3  fs solid lc rgb "red" lt 1, \
'' u 4  fs solid lc rgb "pink" lt 1


set yrange [-1:1]
set ytics 1
unset ylabel
unset border 
unset ytics
set xtics

imgDy = 0.0053
imgDx = 0.0022
set size 1,0.13
set origin -0.005,0.780
set lmargin 5
set xtics offset 0,-25
set bmargin 0
unset xtics
unset xlabel
plot '< cat ./RSdata.txt | ./genLunarHistogram.pl' using (0):xtic(1) fs solid lc rgb "dark-red" lt 1 notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(-0.1,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(0.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(1.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(2.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(3.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(4.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(5.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(6.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(7.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(8.5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day2.jpg  avs:-' binary filetype=avs center=(0,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day5.jpg  avs:-' binary filetype=avs center=(1,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day8.jpg  avs:-' binary filetype=avs center=(2,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day11.jpg  avs:-' binary filetype=avs center=(3,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day14.jpg  avs:-' binary filetype=avs center=(4,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day17.jpg  avs:-' binary filetype=avs center=(5,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day20.jpg  avs:-' binary filetype=avs center=(6,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day23.jpg  avs:-' binary filetype=avs center=(7,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day26.jpg  avs:-' binary filetype=avs center=(8,0) dx=imgDx dy=imgDy with rgbimage notitle, \
'< /usr/bin/convert day29.jpg  avs:-' binary filetype=avs center=(9,0) dx=imgDx dy=imgDy with rgbimage notitle


print "images from http://www.mikeoates.org/mavica/lunar.htm"

unset multiplot










if ("$0" eq "latex") set output; set term x11; print outputFilename

#'< cat ./RSdata.txt | ./genHistogram.pl' u (column(i)) fill style 1, \

#plot \
#'< cat ./RSdata.txt | ./genHistogram.pl' u 4 title "both catalogues", \
#'' u 6  title "ILGI only", \
#'' u 8 title "SILLOK only"


#    EOF
