C     THIS PROGRAM COMPUTES THE SOLAR LONGITUDE, RADIUS VECTOR AND SOLAR
C     SEMI-DIAMETER (IN ARCSEC) USING THE PRINCIPAL TERMS IN NEWCOMB'S
C     SOLAR THEORY.  PURELY ELLIPTICAL MOTION IS ASSUMED; NO ALLOWANCE
C     IS MADE FOR PLANETARY TERMS. A FIGURE FOR THE SEMI-DIAMETER AT
C     UNIT DISTANCE OF 961.18 ARCSEC (959.63 + 1.55: INCLUDING IRRADIATION)
C     IS ASSUMED. NOTE, PRIOR TO 1960 THE AMERICAN EPHEMERIS ADOPTED A
c     VALUE OF 961.50 SINCE A DIFFERENT INCREMENT WAS MADE FOR
c     IRRADIATION (SEE EXPLANATORY SUPPLEMENT TO THE ASTRONOMICAL
C     EPHEMERIS, P. 101). A CHECK AGAINST THE DATA IN A RECENT COPY OF THE 
C     ASTRONOMICAL ALMANAC INDICATES THAT WHEN COMPUTATIONS ARE MADE 
C     USING THIS PROGRAM THERE IS A TYPICAL ERROR OF 0.05 ARCSEC (I.E.
C     1 PART IN 20,000) IN THE SOLAR SEMI-DIAMETER. N.B. DUE TO THE 
C     ELLIPTICITY OF THE EARTH'S ORBIT, THE SOLAR SEMI-DIAMETER CAN
c     CHANGE IN 24 HOURS BY UP TO 0.27 ARCSEC (NOTABLY IN THE SPRING AND
c     AUTUMN. IT IS THUS IMPORTANT TO INPUT THE APPROXIMATE UT WHEN
c     KNOWN.

      IMPLICIT REAL*8(A-H,O-Z)
      REAL*8 NUM, JD, LOG
      CHARACTER*80 buffer
      INTEGER fdrain
5     CONTINUE

      CALL getarg( 1, buffer)
      READ(buffer, *) IYEAR
      CALL getarg( 2, buffer)
      READ(buffer, *) MONTH
      CALL getarg( 3, buffer)
      READ(buffer, *) IDAY
C      WRITE(6,*) ' TYPE IN CIVIL DATE, YEAR, MONTH, DAY ( All INTEGER)' 
C      READ(5,*) IYEAR,MONTH,IDAY
C      WRITE(6,100) IYEAR, MONTH, IDAY
100   FORMAT(' CIVIL DATE =',I5,'/',I4,'/',I4)
      CALL TOJD(IYEAR,MONTH,IDAY,12.0,JD)
C      WRITE(6,*) ' TYPE IN UT IN HOURS'
      CALL getarg( 4, buffer)
      READ(buffer, *) H
C      READ(5,*) H
      JD=JD+H/24.-0.5
      E=(JD-2415020.D0)/36525.
      PI=3.141592653589D0
      NUM=PI/648000.
      CIR=1296000.
      SL=1006908.04D0+129602768.13D0*E+1.089*E**2
C     THIS IS THE MEAN LONGITUDE
      SS=1290513.0D0+129596579.10D0*E-0.54*E**2-0.012*E**3
C     THIS IS THE MEAN ANOMALY 

      SS=CON(SS)
      SS=SS*NUM
      
C     LET=-8.72-26.74*E-11.22*E**2
C     LET=LET-1.94+3.43*E-1.78*E**2
C     RL=973571.71D0 + 1732564406.06D0*E +7.14*E**2+ 0.0068*E**3+ LET
C     DA=RL-SL
C     D=CON(DA)
C     D=NUM*D

      S=SS
      SOLIN = DSIN(S)*(6910.057-17.240*E-0.052*E**2)
     * + DSIN(2.*S)*(72.338 - 0.361*E) 
     * + DSIN(3.*S)*(1.054)
C    * + 6.454*DSIN(D)
C     TERMS ARISING FORM ELLIPTICITY OF EARTH'S ORBIT
C     E.G. 6910 = 2*e *206265 
      SOLIN=SOLIN-20.5
C     20.5 ARCSEC = APPARENT SOLAR MOVEMENT IN LIGHT TIME       
      SSOL=SOLIN+SL      
      SOL=CON(SSOL)
      SUN = SOL/3600.
      
      LOG = 0.00003057 - 0.000000015*E
     * + DCOS(S)*(-0.00727412 + 0.00001814 *E)
     * + DCOS(2.*S)*(-0.00009138 + 0.00000046*E)
     * + DCOS(3.*S)*(-0.00000145)
     * + 0.00001336*DCOS(D)
      SRV = 10**LOG
      SSD = 961.18/SRV
C      WRITE (6, 4) H
4     FORMAT (' TT =', F10.3)
      WRITE (6, 99) IYEAR, MONTH, IDAY, H, SUN, SRV, SSD
99    FORMAT ('CIVIL DATE =',I5,'/',I4,'/',I4,' TT = ', F10.3, 
     * ' LONG, SRV, SSD=', F10.2, F10.5, F10.5)
C//,79(1H=))
C      GO TO 5
      END
      SUBROUTINE TOJD(IYEAR,MONTH,IDAY,HOUR,JDATE)
      REAL*8 JDATE
      INTEGER Y , D
C** CONVERTS YEAR/MONTH/DAY/HOUR TO JULIAN DATE
C** ALGORITHM OF PAUL MULLER 1975 THESIS
      Y=IYEAR
      M=MONTH
      D=IDAY
      IF(IYEAR.GT.1582) GOTO 1
      IF(IYEAR.EQ.1582.AND.MONTH.GT.9) GOTO 1
      IF(IDAY.GT.5.AND.IYEAR.EQ.1582.AND.MONTH.EQ.9) GOTO 1
C** DATE BEFORE 1582 SEPT 15.... GREGORIAN CALENDAR
      JDATE=367*Y-7*(Y+5001+(M-9)/7)/4+275*M/9+D+1729777
      JDATE=JDATE+(HOUR-12.0)/24.0
      RETURN
1      CONTINUE
      JDATE=367*Y-7*(Y+(M+9)/12)/4-3*((Y+(M-9)/7)/100+1)/4
     *  +275*M/9+D+1721029
      JDATE=JDATE+(HOUR-12.0)/24.0
      RETURN
      END
      FUNCTION CON(A)
      REAL*8 CON,A
      N=A/1296000.D0
      CON=A-N*1296000.D0
      IF(CON.LT.0.0D0) CON=CON+1296000.D0
      RETURN
      END
      SUBROUTINE DEBUG(ANAME,RVAL)
      IMPLICIT REAL*8(A-H,O-Z)
      DATA BLANK,XMINUS/1H ,1H-/
      VAL=DABS(RVAL)
C** ANGLE , NAME ANAME , IS IN SECS OF ARC
      IVAL=VAL
      SEC=VAL-IVAL
      IDEG=VAL/3600.
      XMIN=(VAL-3600.*IDEG)/60.
      MIN=XMIN
      ISEC=(VAL-3600.*IDEG-60.*MIN)
      SEC=SEC+ISEC
      IF(RVAL.GT.0) SIGN=BLANK
      IF(RVAL.LT.0) SIGN=XMINUS
      WRITE(6,100) ANAME,RVAL,SIGN,IDEG,MIN, SEC
100   FORMAT(' ANGLE NAME =  ',A4,' VALUE = ',F15.3,'  DEG/MIN/SEC = ',
     * A1,2(I5,2X),F6.3)
      RETURN
      END
