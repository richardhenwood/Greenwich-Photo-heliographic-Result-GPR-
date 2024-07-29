#!/usr/local/bin/gnuplot -persist
#
#    
#    	G N U P L O T
#    	Version 4.3 patchlevel 0
#    	last modified January 2007
#    	System: Linux 2.6.16.27-0.6-smp
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
#unset clip points
#set clip one
#unset clip two
#set bar 1.000000
#set border 31 front linetype -1 linewidth 1.000
#set xdata
#set ydata
#set zdata
#set x2data
#set y2data
#set timefmt x "%d/%m/%y,%H:%M"
#set timefmt y "%d/%m/%y,%H:%M"
#set timefmt z "%d/%m/%y,%H:%M"
#set timefmt x2 "%d/%m/%y,%H:%M"
#set timefmt y2 "%d/%m/%y,%H:%M"
#set timefmt cb "%d/%m/%y,%H:%M"
#set boxwidth
#set style fill  empty border
#set style rectangle back fc lt -3 fillstyle   solid 1.00 border -1
#set dummy x,y
#set format x "% g"
#set format y "% g"
#set format x2 "% g"
#set format y2 "% g"
#set format z "% g"
#set format cb "% g"
#set angles radians
#unset grid
#set key title ""
#set key inside right top vertical Right noreverse enhanced autotitles nobox
#set key noinvert samplen 4 spacing 1 width 0 height 0 
#unset label
#unset arrow
#set style increment default
#unset style line
#unset style arrow
#set style histogram clustered gap 2 title  offset character 0, 0, 0
#unset logscale
#set offsets 0, 0, 0, 0
#set pointsize 1
#set encoding default
#unset polar
#unset parametric
#unset decimalsign
#set view 60, 30, 1, 1
#set samples 100, 100
#set isosamples 10, 10
#set surface
#unset contour
#set clabel '%8.3g'
#set mapping cartesian
#set datafile separator whitespace
#unset hidden3d
#set cntrparam order 4
#set cntrparam linear
#set cntrparam levels auto 5
#set cntrparam points 5
#set size ratio 0 1,1
#set origin 0,0
#set style data points
#set style function lines
#set xzeroaxis linetype -2 linewidth 1.000
#set yzeroaxis linetype -2 linewidth 1.000
#set zzeroaxis linetype -2 linewidth 1.000
#set x2zeroaxis linetype -2 linewidth 1.000
#set y2zeroaxis linetype -2 linewidth 1.000
#set ticslevel 0.5
#set mxtics default
#set mytics default
#set mztics default
#set mx2tics default
#set my2tics default
#set mcbtics default
#set xtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autofreq 
#set ytics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autofreq 
#set ztics border in scale 1,0.5 nomirror norotate  offset character 0, 0, 0 autofreq 
#set nox2tics
#set noy2tics
#set cbtics border in scale 1,0.5 mirror norotate  offset character 0, 0, 0 autofreq 
#set title "" 
#set title  offset character 0, 0, 0 font "" norotate
#set timestamp bottom 
#set timestamp "" 
#set timestamp  offset character 0, 0, 0 font "" norotate
#set rrange [ * : * ] noreverse nowriteback  # (currently [0.00000:10.0000] )
#set trange [ * : * ] noreverse nowriteback  # (currently [-5.00000:5.00000] )
#set urange [ * : * ] noreverse nowriteback  # (currently [-5.00000:5.00000] )
#set vrange [ * : * ] noreverse nowriteback  # (currently [-5.00000:5.00000] )
#set xlabel "" 
#set xlabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
#set x2label "" 
#set x2label  offset character 0, 0, 0 font "" textcolor lt -1 norotate
#set xrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set x2range [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set ylabel "" 
#set ylabel  offset character 0, 0, 0 font "" textcolor lt -1 rotate by 90
#set y2label "" 
#set y2label  offset character 0, 0, 0 font "" textcolor lt -1 rotate by 90
#set yrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set y2range [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set zlabel "" 
#set zlabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
#set zrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set cblabel "" 
#set cblabel  offset character 0, 0, 0 font "" textcolor lt -1 norotate
#set cbrange [ * : * ] noreverse nowriteback  # (currently [-10.0000:10.0000] )
#set zero 1e-08
#set lmargin  -1
#set bmargin  -1
#set rmargin  -1
#set tmargin  -1
#set locale "C"
#set pm3d explicit at s
#set pm3d scansautomatic
#set pm3d interpolate 1,1 flush begin noftriangles nohidden3d corners2color mean
#set palette positive nops_allcF maxcolors 0 gamma 1.5 color model RGB 
#set palette rgbformulae 7, 5, 15
#set colorbox default
#set colorbox vertical origin screen 0.9, 0.2, 0 size screen 0.05, 0.6, 0 bdefault
#set loadpath 
#set fontpath 
#set fit noerrorvariables
#GNUTERM = "x11"


isint(x)=(int(x)==x)
negbin(x,r,p)=r<=0||!isint(r)||p<=0||p>1?1/0:\
  !isint(x)?1/0:x<0?0.0:p==1?(x==0?1.0:0.0):exp(lgamma(r+x)-lgamma(r)-lgamma(x+1)+\
    r*log(p)+x*log(1.0-p))

r = 1.781; 
p = 0.0157;
r = 2; p = 0.0157

mu = r * (1.0 - p) / p
sigma = sqrt(mu / p)
xmin = int(mu - 4.0 * sigma)
xmin = xmin < 0 ? 0 : xmin
xmax = int(mu + 4.0 * sigma)
ymax = 1.1 * negbin(int(mu - (1.0-p)/p), r, p) #mode of gamma PDF used
unset key
unset zeroaxis
set xrange [xmin-1 : xmax]
set yrange [0 : ymax]
set xlabel "k ->"
set ylabel "probability density ->"
set ytics 0, ymax / 10, ymax
set format x "%2.0f"
set format y "%3.2f"
set sample (xmax - xmin+1) + 1
set title "negative binomial (or pascal or polya) PDF with r = 8, p = 0.4"
plot negbin(x, r, p) with lines, \
'< cat /users/rhenwood/ihr/data/grnAge/age6.txt /users/rhenwood/ihr/data/grnAge/age7.txt /users/rhenwood/ihr/data/grnAge/age8.txt | /users/rhenwood/ihr/sunspots/perl/warwick/distTest/myBinningCode.pl -f - -n 50 -x' u 3:($6/4501) w boxes title 'sunspot observations age 6,7,8'




#set sample 101;
#set xrange [0:100]
#plot negbin(x, r, p) w lines


#
#
#set xrange [-2:8]
#
#mu = 1
#r = 1;
#p = 1;
#
#negbin(x,r,p)=r<=0||!isint(r)||p<=0||p>1?1/0:\
#  !isint(x)?1/0:x<0?0.0:p==1?(x==0?1.0:0.0):exp(lgamma(r+x)-lgamma(r)-lgamma(x+1)+\
#    r*log(p)+x*log(1.0-p))
#r = 8; p = 0.4
#
#plot negbin(x, r, p) w lines

#mu = 170;
#sigma = 120;
#plot \
#'< cat /users/rhenwood/ihr/data/grnAge/age6.txt /users/rhenwood/ihr/data/grnAge/age7.txt /users/rhenwood/ihr/data/grnAge/age8.txt | /users/rhenwood/ihr/sunspots/perl/warwick/distTest/myBinningCode.pl -f - -h' u 3:6:9:12:15 with candlesticks title 'sunspot observations age 6,7,8', \
#'/users/rhenwood/ihr/data/testData/nbinpdf.txt' using (($1-mu)/sigma):($2*sigma) with lines
#


#'< cat /users/rhenwood/ihr/data/testData/nbinpdfDATA.txt | /users/rhenwood/ihr/sunspots/perl/warwick/distTest/myBinningCode.pl -f - ' using 3:6 with lines



#'< /users/rhenwood/ihr/sunspots/perl/warwick/distTest/genPoisson.pl -n 20 -l 0.5    -v' using 9:12 smooth csplines title "$\lamda = 0.5$", \
#'< /users/rhenwood/ihr/sunspots/perl/warwick/distTest/genPoisson.pl -n 20 -l 0.7 -v' using 9:12 smooth csplines title "$\lamda = 0.7$", \
#'< /users/rhenwood/ihr/sunspots/perl/warwick/distTest/genPoisson.pl -n 20 -l 1 -v' using 9:12 smooth csplines title "$\lamda = 1$"
#
#'< /users/rhenwood/ihr/sunspots/perl/warwick/distTest/genPoisson.pl -n 500 -a 2 -v' using 9:12 with lines title "$a = 2$", \
#'< /users/rhenwood/ihr/sunspots/perl/warwick/distTest/genPoisson.pl -n 500 -a 3    -v' using 9:12 with lines title "a = 3"




#    EOF
