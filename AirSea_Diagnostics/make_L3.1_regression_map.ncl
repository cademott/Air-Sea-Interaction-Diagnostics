;***********************************************************
; Compute : fixme
;***********************************************************

; INPUTS
; (1) Any anomaly time series [time, lat, lon]
; (2) Any other field, to be regressed onto the first.
;
; This routine performs three sets of regressions per input variable:
;	1) filters the data (20-100 day bandpass)
;	2) regresses 2nd variable onto the first at lag=0 at each grid point
;	3) computes the correlation of the two fields
;	4) writes output data

; OUTPUTS
; (1) Regression coefficient 
; (2) Correlation coefficient 

; Author:  	Jim Benedict jjbenedict@lbl.gov
; Origin:  	22 Feb 2014
; modified:	by C. DeMott 2 Oct 2015

load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin
  
	print("")
	print("============= in make_L3.1_regression_map.ncl =============")   

	min_lon_map	= 30.
	max_lon_map	= 270.

	;----------- retrieve required environment variables	
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;----------- retrieve required environment variables
	diri		= getenv("FILEDIR")+"/"
	diro		= getenv("FILEDIR")+"/proc/"
	inName1		= getenv("inName1")
	inName2		= getenv("inName2")
	caseName	= getenv("caseName")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")
	timeName	= getenv("TIMEVAR")
	sstName		= getenv("SSTVARNAME")
	lhName		= getenv("LHVARNAME")
	shName		= getenv("SHVARNAME")
	lwName		= getenv("LWVARNAME")
	swName		= getenv("SWVARNAME")
	qName		= getenv("QVARNAME")
	tName		= getenv("TKVARNAME")
	sstName		= getenv("SSTVARNAME")
	sfcpName	= getenv("SFCPVARNAME")
	pName		= getenv("RAINVARNAME")
	rainFstr	= getenv("RAINFACTOR")

	RainWm2		= getenv("RAIN2WM2") ; if True then convert rain in mm/day to W/m**2.

	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)




	;----------- define latitude string
	if (latS_globe.lt.0) then
		southStr	= "S"
	else
		southStr	= "N"
	end if
	if (latN_globe.ge.0) then
		northStr	= "N"
	else
		northStr	= "S"
	end if	
	latbandStr	= abs(latS_globe) + southStr + "-" + abs(latN_globe) + northStr

	;------------- define input files and variable names 
	Name1		= inName1
	Name2		= inName2
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	inName1		= inName1+"_anom_sm"
	inFile2		= diri + caseName + "." + inName2 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	inName2		= inName2+"_anom_sm"

	print("independent variable = "+Name1)
	print("  dependent variable = "+Name2)

	; ---------------------------------------------------------
	; open file data for the independent variable
	f1 			= addfile (inFile1 , "r")       	; independent variable
	date		= cd_calendar(f1->$timeName$, -2)	; entire file
	iStrt 		= ind(date.eq.twStrt)				; desired dates
	iLast 		= ind(date.eq.twLast)
	delete(date)
	time		= f1->$timeName$(iStrt:iLast)
	lat			= f1->$latName$({latS_globe:latN_globe})
	lon  		= f1->$lonName$
	nlon		= dimsizes(lon)
	nlat		= dimsizes(lat)
	ntim		= dimsizes(time)
	x			= f1->$inName1$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)
	if (Name1.eq.pName) then
		rainfact	=stringtofloat(rainFstr)
		x			= x * rainfact
		x@units 	= "mm/day"
	end if
	;--------------- define conversion factor for mm/day to W/m**2.
	if (.not.ismissing(RainWm2).and.RainWm2.eq."True") then
		print("converting mm/day to W/m**2...")
		Efactor	= 28.9	; there are 28.9 W/m**2 per mm/day of rainfall
		x		= x * Efactor
		x@units	= "W/m**2"
	end if



	; ---------------------------------------------------------
	; open file data for the dependent variable
	f2 			= addfile (inFile2 , "r")       	; dependent variable
	date		= cd_calendar(f1->$timeName$, -2)	; entire file
	iStrt 		= ind(date.eq.twStrt)				; desired dates
	iLast 		= ind(date.eq.twLast)
	delete(date)
	aa			= f2->$inName2$($timeName$|iStrt:iLast,{$latName$|latS_globe:latN_globe},$lonName$|:)

	


	;-------------- set up time variables
	ti = calendar_decode2(time, -5)   ; time info for MSE ANOM
	month     	= ti(:,1)
	month		= rm_single_dims(month)
	n2a			= ind(month.ge.11.or.month.le.4)	; Nov-Apr
	m2o			= ind(month.ge.5.and.month.le.10)	; May-Oct
	seasonid	= (/"n2a","m2o"/)
	seasonName	= (/"Nov-Apr","May-Oct"/)
	
	; ---------------------------------------------------------
	; create BandPass Filter
	ihp      	= 2                             ; bpf=>band pass filter
	nWgt     	= 201
	sigma    	= 1.0                           ; Lanczos sigma
	; fixme:	allow for user-specified cutoff frequencies
	fca      	= 1./100.
	fcb      	= 1./20.
	wgt      	= filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )
	
	
	; ---------------------------------------------------------
	; create HiPass Filter
	ihp_hp     	= 1                             ; bpf=>band pass filter
	nWgt_hp    	= 201
	sigma    	= 1.0                           ; Lanczos sigma
	; fixme:	allow for user-specified cutoff frequencies
	fca_hp     	= 1./150.
	wgt_hp     	= filwgts_lanczos (nWgt, ihp_hp, fca_hp, -999., sigma )
	

	;--------------------- define output variables
	rcProfFix    			= new( (/2,nlat,nlon/),"float",default_fillvalue("float"))  
	rcProfFix!0				= "season"
	rcProfFix&season		= seasonName
	rcProfFix!1				= "lat"
	rcProfFix&lat			= lat
	rcProfFix!2				= "lon"
	rcProfFix&lon			= lon
	rcoeffProfFix  			= new( (/2,nlat,nlon/),"float",default_fillvalue("float"))
	rcoeffProfFix!0			= "season"
	rcoeffProfFix&season	= seasonName
	rcoeffProfFix!1			= "lat"
	rcoeffProfFix&lat		= lat
	rcoeffProfFix!2			= "lon"
	rcoeffProfFix&lon		= lon
	sigProfFix   			= new( (/2,nlat,nlon/),"float",default_fillvalue("float"))
	sigProfFix!0			= "season"
	sigProfFix&season		= seasonName
	sigProfFix!1			= "lat"
	sigProfFix&lat			= lat
	sigProfFix!2			= "lon"
	sigProfFix&lon			= lon
	essProfFix  			= new( (/2,nlat,nlon/),"integer",-999)
	essProfFix!0			= "season"
	essProfFix&season		= seasonName
	essProfFix!1			= "lat"
	essProfFix&lat			= lat
	essProfFix!2			= "lon"
	essProfFix&lon			= lon
	rstdProfFix  			= new( (/2,nlat,nlon/),"float",default_fillvalue("float"))
	rstdProfFix!0			= "season"
	rstdProfFix&season		= seasonName
	rstdProfFix!1			= "lat"
	rstdProfFix&lat			= lat
	rstdProfFix!2			= "lon"
	rstdProfFix&lon			= lon
  
	;-------------------- added by C. DeMott 09-24-2015
	do s=0,1		; season loop
		print("Processing " + seasonName(s) + "...")
		if (s.eq.0) then
			range 	= n2a
			hide	= m2o
		else
			range	= m2o
			hide	= n2a
		end if

		;printVarSummary(x)
		;printVarSummary(aa)

		do i=0,nlon-1
			do j=0,nlat-1
				;-------------- filter the time series 
				xtemp				= x(:,j,i)
				xtemp				= wgt_runave_leftdim( xtemp, wgt, 0 )	; 20-100 day
				;printMinMax(xtemp,True)
				;if (i.eq.0.and.j.eq.0) then
				;	printVarSummary(xtemp)
				;end if
				
				;=============== test code for increasing, decreasing trends
				;xtend				= xtemp
				;xtend(1:dimsizes(xtemp)-1)	= xtemp(1:dimsizes(xtemp)-1) - xtemp(0:dimsizes(xtemp)-2)
				;xtend(0)			= default_fillvalue(typeof(xtend))
				;pos					= ind(xtend.gt.0)
				;neg					= ind(xtend.lt.0)
								
				aatemp				= aa(:,j,i)
				aatemp				= wgt_runave_leftdim( aatemp, wgt_hp, 0 ); hipass filter

				;-------------- mask out "other" season
				xtemp(hide)			= x@_FillValue		; set "other season" values to missing so not included
				xtemp@Fill_Value	= x@_FillValue		; this may be redundant, since x has to have a _FillValue
				;xtemp(neg)			= x@_FillValue
				;printMinMax(xtemp,True)

				;-------------- compute lag-1 autocorrelations
				l1					= esacr(xtemp,1)
				lag1acX				= l1(1)                        ; lag-1 auto corr of INDEPENDENT variable
				delete(l1)
				l1					= esacr(aatemp,1)
				lag1acAA			= l1(1)                        ; lag-1 auto corr of DEPENDENT variable
				delete(l1)
				
				regTemp				= regline(xtemp,aatemp)
				;rcProfFix(s,j,i)	= regline(xtemp,aatemp)	; regression  (season,lat,lon)
				rcProfFix(s,j,i)	= (/ regTemp /)			; regression  (season,lat,lon)
				rcoeffProfFix(s,j,i)= escorc(xtemp,aatemp)	; correlation (season,lat,lon)

				;-------------- corr coef of regression @ current lat and lon pt
				cc					= escorc(xtemp,aatemp)       

				;-------------- tot # pairs of data in regression
				;   NOTE: SINCE IDX IS LIMITING FACTOR FOR NPTXY (EVEN IF SEASONS ARE USED), NPTXY WILL BE
				;         SAME FOR ALL LAGS!  (JIM TESTED THIS)
				nptxy				= dimsizes(xtemp)

				;-------------- effective sample size, from Bretherton et al. (1999, JC) ; note: no longer have lon-dependence
				essProfFix(s,j,i)	= round( nptxy * (1.-lag1acX*lag1acAA) / \
													 (1.+(lag1acX*lag1acAA)), 3 )

				;-------------- determine statistical significance of the linear relationship
				;   (rtest receives cc and ess, computes Student t test, and returns significance
				;   value based on two-tailed test assuming normal distribution of both variables
				;   in regression...note that a returned value of 0.02 = 98% significance level)
				sigProfFix(s,j,i) 	= 1. - rtest( cc, essProfFix(s,j,i), 0 )
				
				;-------------- record standard error of the regression coefficient
				;				for later significance testing (added by C. DeMott 16 Mar 2018)
				rstdProfFix(s,j,i)	= regTemp@rstd

				;printVarSummary(rcProfFix)
				delete(lag1acX)
				delete(lag1acAA)
				delete(cc)
				delete(nptxy)
				delete(xtemp)
				delete(aatemp)
				delete(regTemp)
				;delete(big)
			
			end do			; end latitude (j) loop
		end do				; end longitude (i) loop
	
	
	
		; -----------------------------------
		; Test print
		ln = ind(lon.eq.90)
		if(i.eq.1) then
		  ;print("")
		  ;print("LON Test, 90E regression values for " + inName2 + " at lev=" + lev(lv) + "hPa:")
		  ;print( sprintf("%8.1f",lon(:)) + sprintf("%12.4f",rcProfFix(1,maxLag,lv,:)) + \
		  ;       sprintf("%12.4f",sigProfFix(1,maxLag,lv,:)) )
		  ;print("")
		end if

		if(i.eq.1) then
		  ;print("")
		  ;print("LAG Test, 90E regression values for " + inName2 + " at lev=" + lev(lv) + "hPa:")
		  ;print( sprintf("%8.1f",lag(:)) + sprintf("%12.4f",rcProfFix(1,:,lv,ln)) + \
		  ;       sprintf("%12.4f",sigProfFix(1,:,lv,ln)) )
		  ;print("")
		end if

		delete(range)
		delete(hide)

	end do  ; end do the season loop
  
	;----------- apply uniform variable naming conventions
	outvarName1		= Name1
	if (Name1.eq.swName) then
		outvarName1	= "SWsfc"
	end if
	if (Name1.eq.lwName) then
		outvarName1	= "LWsfc"
	end if	
	if (Name1.eq.lhName) then
		outvarName1	= "LHFLX"
	end if	
	if (Name1.eq.shName) then
		outvarName1	= "SHFLX"
	end if	
	if (Name1.eq.pName) then
		outvarName1	= "PRECT"
	end if	
	if (Name1.eq.qName) then
		outvarName1	= "Qair"
	end if	
	if (Name1.eq.tName) then
		outvarName1	= "Tair"
	end if	
	if (Name1.eq.sstName) then
		outvarName1	= "SST"
	end if	
	if (Name1.eq.sstName+"_smSST") then
		outvarName1	= "SST_smSST"
	end if		
	if (Name1.eq.sfcpName) then
		outvarName1	= "SFCP"
	end if		
	print("outvarName1	= "+outvarName1)

	outvarName2		= Name2
	if (Name2.eq.swName) then
		outvarName2	= "SWsfc"
	end if
	if (Name2.eq.lwName) then
		outvarName2	= "LWsfc"
	end if	
	if (Name2.eq.lhName) then
		outvarName2	= "LHFLX"
	end if	
	if (Name2.eq.shName) then
		outvarName2	= "SHFLX"
	end if	
	if (Name2.eq.pName) then
		outvarName2	= "PRECT"
	end if	
	if (Name2.eq.qName) then
		outvarName2	= "Qair"
	end if	
	if (Name2.eq.tName) then
		outvarName2	= "Tair"
	end if	
	if (Name2.eq.sstName) then
		outvarName2	= "SST"
	end if	
	if (Name2.eq.sstName+"_smSST") then
		outvarName2	= "SST_smSST"
	end if		
	if (Name2.eq.sfcpName) then
		outvarName2	= "SFCP"
	end if		
	print("outvarName2	= "+outvarName2)

	; ------------- write data to file
	do s=0,1			; write a file for each season

		;-------------- output file definitions
		outFile1			= diro + caseName + ".make_L3.1_regression_map."+ twStrt + "-" + twLast + "." + outvarName1 + "." + outvarName2 + "." + seasonName(s) + ".nc"
		system("/bin/rm -f " + outFile1)                  ; remove old file if exists
		fout 				= addfile(outFile1,"c")       ; "pointer" to output file is fout
		setfileoption(fout,"DefineMode",True)
		fAtt				= True
		fAtt@title			= Name2 + " regressed onto filtered " + Name1
		fAtt@author			= "Charlotte DeMott (demott@atmos.colostate.edu)"
		fAtt@source_file1	= inFile1
		fAtt@source_file2	= inFile2
		fAtt@created		= systemfunc("date")
		fAtt@case			= getenv("simName")
		fAtt@simulation		= getenv("caseName")
		fileattdef( fout, fAtt )            ; copy file attributes

		dimNames = (/"lat", "lon" /)       
		dimSizes = (/ dimsizes(lat),  dimsizes(lon) /) 
		dimUnlim = (/ False, False /)
		filedimdef(fout,dimNames,dimSizes,dimUnlim)
		setfileoption(fout,"DefineMode",False)

		;-------------- metadata for output fields (ALL rainrates)
		rcdata			= rcProfFix(s,:,:)
		rcdata!0			= "lat"
		rcdata!1			= "lon"
		rcdata&lat			= lat
		rcdata&lon			= lon
		rcdata@units		= "["+aa@units+"]/["+x@units+"]"
		rcdata@long_name	= aa@long_name
		rcdata@calculation	= outvarName2 + " regressed onto " + outvarName1
		rcdata@orig_varnames= Name1 + ", " + Name2
		rcdata@season		= seasonName(s)
		rcdata@method		= "NCL regline"
	
		ccdata			= rcoeffProfFix(s,:,:)
		ccdata!0		= "lat"
		ccdata!1		= "lon"
		ccdata&lat		= lat
		ccdata&lon		= lon
		ccdata@units	= " "
		ccdata@long_name= aa@long_name
		ccdata@calculation="correlation["+outvarName1 + "," + outvarName2 + "]"
		ccdata@season	= seasonName(s)
		ccdata@method	= "NCL escorc"
	
		essdata			= essProfFix(s,:,:)
		essdata!0		= "lat"
		essdata!1		= "lon"
		essdata&lat		= lat
		essdata&lon		= lon
		essdata@units	= " "
		essdata@long_name= aa@long_name
		essdata@calculation="equivalent sample size of "+outvarName1 + "," + outvarName2 + " regression"
		essdata@season	= seasonName(s)
		essdata@method	= "Bretherton et al. (1999, JC)"
	
		stderrdata			= rstdProfFix(s,:,:)
		stderrdata!0		= "lat"
		stderrdata!1		= "lon"
		stderrdata&lat		= lat
		stderrdata&lon		= lon
		stderrdata@units	= " "
		stderrdata@long_name= aa@long_name
		stderrdata@calculation="standard error of "+outvarName1 + "," + outvarName2 + " regression coefficient"
		stderrdata@season	= seasonName(s)
		stderrdata@method	= "NCL regline@rstd"
	
		sigdata			= sigProfFix(s,:,:)
		sigdata!0		= "lat"
		sigdata!1		= "lon"
		sigdata&lat		= lat
		sigdata&lon		= lon
		sigdata@units	= "%"
		sigdata@long_name="95% confidence value"
		sigdata@season	= seasonName(s)
		sigdata@method	= "1. - (NCL rtest)"

		fout->regData	= rcdata
		fout->statSig	= sigdata
		fout->corrData	= ccdata
		fout->essData	= essdata
		fout->stderrData= stderrdata

		delete(rcdata)
		delete(ccdata)
		delete(sigdata)
		delete(essdata)
		delete(stderrdata)
		delete(dimNames)
		delete(dimSizes)
		delete(dimUnlim)
	end do ; season output loop

end













