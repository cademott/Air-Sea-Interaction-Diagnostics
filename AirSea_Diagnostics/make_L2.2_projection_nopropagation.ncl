;***********************************************************
; Compute : fixme
;***********************************************************

; INPUTS
; (1) 

; OUTPUTS
; (1) Derived data file

; Auhtor:  Jim Benedict jjbenedict@lbl.gov
; Origin:  22 Feb 2014

load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin
  
	print("")
	print("============== in make_L2.2_regression_nopropagation.ncl ==============")


	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	; CONSTANTS:
	grav    = 9.81
	r_earth = 6378388.    ; [m]
	deg2rad = 0.0174533

	min_lon_map = 30.
	max_lon_map = 270.


	; Retrieve required environment variables
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	inName1		= getenv("inName1")
	inName2		= getenv("inName2")
	caseName	= getenv("caseName")
	dateSt		= getenv("YMDSTRT")
	dateNd		= getenv("YMDLAST")
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
	
	diri		= getenv("FILEDIR") + "/"
	diro		= diri + "proc/"		
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
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
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	inName1		= inName1+"_anom_sm"
	inFile2		= diri + caseName + "." + inName2 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	inName2		= inName2+"_anom_sm"

	Name1	= substring(inName1,0,str_index_of_substr(inName1,"_anom_sm",0)-1)
	Name2	= substring(inName2,0,str_index_of_substr(inName2,"_anom_sm",0)-1)
		
	print("base point variable = "+Name1)
	print("regressed variable  = "+Name2)

	;------------- seasons
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- latitude band for averaging
	latAvgS		= -10.
	latAvgN		=  10.
	
	;------------- open file data
	f1 = addfile (inFile1 , "r")       ; PRECT
	f2 = addfile (inFile2 , "r")       ; regressed variable

	lat			= f2->$latName$
	lon  		= f2->$lonName$
	time		= f2->$timeName$
	date		= cd_calendar(f2->$timeName$, -2)
	iStrt 		= ind(date.eq.twStrt)				; desired dates
	iLast 		= ind(date.eq.twLast)
	delete(time)
	delete(date)
	time		= f1->$timeName$(iStrt:iLast)	
	nlon		= dimsizes(lon)
	nlat		= dimsizes(lat)
	ntim		= dimsizes(time)
	tropics		= ind(lat.ge.latAvgS.and.lat.le.latAvgN)

	ti 			= calendar_decode2(time, -5)   ; time info for MSE ANOM
	indBeg		= iStrt
	indEnd		= iLast
			 
	;---------------------- added by C. DeMott 09-24-2015
	month     	= ti(:,1)
	month		= rm_single_dims(month)
	n2a			= ind(month.ge.11.or.month.le.4)	; Nov-Apr
	m2o			= ind(month.ge.5.and.month.le.10)	; May-Oct
	seasonid	= (/"n2a","m2o"/)
	seasonNm	= (/"Nov-Apr","May-Oct"/)
	;------------------------------------------------------------------
	
	; ---------------------------------------------------------
	; settings for lagged linear regression
	maxLag		= 30
	lagdays		= 2*maxLag+1
	lag 		= ispan(-1*maxLag,maxLag,1)

	; ---------------------------------------------------------
	; create BandPass Filter
	ihp      	= 2                             ; bpf=>band pass filter
	nWgt     	= 201
	sigma    	= 1.0                           ; Lanczos sigma
	fca      	= 1./100.
	fcb      	= 1./20.
	wgt      	= filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )

	; for area averaging first, then BPF
	spd    		= 1               ; samples per day
	bpf    		= (/20,100,201/)  ; input for band pass

	nhar  		= 3                              ; # Fourier harmonics to keep
												 ;   3 = 0th(mean), 1st, 2nd, and 3rd harmonics of
												 ;   seasonal cycle
	delete(time)  
  
	;--------------------- define output variables
	xBPF_STD		= new( (/2,nlon/),		  "float",default_fillvalue("float")) 	; season x longitude
	rcProfFixAnn    = new( (/2,lagdays,nlon/),"float",default_fillvalue("float")) ; season x lag x longitude
	;sigProfFixAnn   = new( (/2,lagdays,nlon/),"float",default_fillvalue("float"))
	;essProfFixAnn   = new( (/2,lagdays,nlon/),"integer",-999)  
  

	indBeg2	= iStrt
	indEnd2	= iLast
	; redefine iStrt, iLast for f1 time series
	time	= f1->$timeName$
	date	= cd_calendar(f1->$timeName$, -2)	; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	delete(date)
	time	= f1->$timeName$(iStrt:iLast)
	indBeg1	= iStrt
	indEnd1	= iLast	

	;************************************************
	; read in precip data and make MJO time series index
	;************************************************
	do i=0,nlon-1
		;print("lon = "+lon(i))
	
		;--------------- read in the base point data and filter
		x				= f1->$inName1$($timeName$|indBeg1:indEnd1,{$latName$|latAvgS:latAvgN},$lonName$|i)
		;x				= f1->$inName1$($timeName$|indBeg:indEnd,$latName$|tropics,$lonName$|i)
		if (Name1.eq.pName) then
			rainfact	=stringtofloat(rainFstr)
			;print("rain factor = " + rainfact)
			x			= x * rainfact
			x@units 	= "mm/day"
		end if			
		bpunits			= x@units
		xBPF_ts			= wgt_runave_leftdim( dim_avg_n_Wrap(x,1), wgt, 0 )	; apply filter
		delete(x)

		;--------------- read in the data to be regressed
		aatemp				= f2->$inName2$($timeName$|indBeg2:indEnd2,{$latName$|latAvgS:latAvgN},$lonName$|i)
		;aatemp				= f2->$inName2$($timeName$|indBeg:indEnd,$latName$|tropics,$lonName$|i)
		if (Name2.eq.pName) then
			rainfact		=stringtofloat(rainFstr)
			;print("rain factor = " + rainfact)
			aatemp			= aatemp * rainfact
			aatemp@units 	= "mm/day"
		end if			
		
		;--------------- mask out land points; C. DeMott 09-25-2015
		OceanOnly	= True	; fixme:  make this a user-specified option.  For net surface energy budget
							;		  and some surface flux applications, we only want to consider ocean points
		;if (OceanOnly) then 
		;	a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
		;	lsdata=a->LSMASK
		;	lsm=landsea_mask(lsdata,aatemp&lat,lon(i))
		;	aatemp = mask(aatemp,conform(aatemp,rm_single_dims(lsm),(/1/)).ge.1,False)
		;end if
		;-----------------------------------------------------------------------------
		aa			= dim_avg_n_Wrap(aatemp,1)
		;printVarSummary(aatemp)
		;printVarSummary(aa)
		delete(aatemp)	
	
		;-------------------- added by C. DeMott 09-24-2015
		do s=0,1		; season loop
			xseason	= xBPF_ts
			yseason	= aa
			if (s.eq.0) then
				range 	= n2a
				hide	= m2o
			else
				range	= m2o
				hide	= n2a
			end if
			;print("processing "+seasonNm(s))
			xseason(hide) 		= xBPF_ts@_FillValue 			; set "other season" values to missing so not included
			xseason@Fill_Value	= xBPF_ts@_FillValue
			xBPF_STD(s,i)		= dim_stddev(xBPF_ts)
			;--------------------------------------------------

			;========================== positive lags
			;print( "Positive lags, lon profile..." )
			; ZERO AND POSITIVE LAGS (regressed variable FOLLOWS index... index "leads")
			m = maxLag        ; index counter
			do nlag = 0,maxLag                                  	; lag 0 to maxLag
				varArr               = yseason(0+nlag:ntim-1)		; variable (y) (ntim)
				if(.not. all(ismissing(varArr)) ) then
					;print("loc: " + lonC(i) + ", nlag: " + nlag)
					idxArr               = xseason(0:ntim-1-nlag)		; index (x) (ntim)

					l1                   = esacr(idxArr,1)
					lag1acIdx2           = l1(1)                        ; lag-1 auto corr of INDEX (single number)
					delete(l1)

					; reg coef (slope) @ current lag and lon pt
					;rcProfFixAnn(s,m,i)  = regline(idxArr(:), varArr(:))       ;   (lagdays,lev,lon)
					rcProfFixAnn(s,m,i)  = sum(idxArr(:)*varArr(:)) / sum(idxArr(:)^2.)      ;   (lagdays,lev,lon)
				
					; corr coef of regression @ current lag and lon pt
;					cc                   = escorc(idxArr(:), varArr(:))       
				
					; tot # pairs of data in regression
					;   NOTE: SINCE IDX IS LIMITING FACTOR FOR NPTXY (EVEN IF SEASONS ARE USED), NPTXY WILL BE
					;         SAME FOR ALL LAGS!  (JIM TESTED THIS)
;					nptxy                = rcProfFixAnn@nptxy
;					yint                 = rcProfFixAnn@yintercept
				
					; effective sample size, from Bretherton et al. (1999, JC) ; note: no longer have lon-dependence
					;essProfFixAnn(m)  = round( nptxy * (1.-(lag1acIdx2*lag1acVarLL(z,u))) / \
					;							        (1.+(lag1acIdx2*lag1acVarLL(z,u))), 3 )
;					essProfFixAnn(s,m,i)  = round( nptxy * (1.-(lag1acIdx2)^2.) / \
;													   (1.+(lag1acIdx2)^2.), 3 )
				
					; degrees of freedom
;					df = essProfFixAnn(s,m,i) - 2
				
					; determine statistical significance of the linear relationship
					;   (rtest receives cc and ess, computes Student t test, and returns significance
					;   value based on two-tailed test assuming normal distribution of both variables
					;   in regression...note that a returned value of 0.02 = 98% significance level)
;					sigProfFixAnn(s,m,i) = 1. - rtest( cc, essProfFixAnn(s,m,i), 0 )
				
					; statistical signficance level (alternative to look-up table)
					;            studentt = ( cc * sqrt(int2flt(df)) ) / ( sqrt(1.-cc^2) )        ; test... WORKS.
		  
					delete(idxArr)
					delete(lag1acIdx2)
;					delete(cc)
;					delete(df)
;					delete(nptxy)
				end if
				delete(varArr)

				; if(i.eq.1.and.u.eq.33) then
				;   print(idxArr + "   " + varArr(u,:))
				;   print(nlag + "   " + lag1acIdx2 + "   " + lag1acVarLL(u) + "   " + rcProfFixAnn(ns,nv,i,m,u) + \
				;         "   " + cc + "   " + nptxy + "   " + yint + "   " + essProfFixAnn(ns,nv,i,m,u) + \
				;         "   " + df + "   " + sigProfFixAnn(ns,nv,i,m,u) + "   " + rcProfTotFixAnn(ns,nv,i,m,u))
				;   if(u.eq.60) then
				;     exit
				;   end if
				; end if
				m = m + 1
			end do             ; end nlag loop (POSITIVE LAGS)
	
			;========================== negative lags
			; NEGATIVE LAGS (regressed variable PRECEDES index... index "follow")
			m = maxLag-1
			n = 1
			do nlag = 0,maxLag-1                     ; lag -1 to -1*maxLag
				varArr				= yseason(0:ntim-1-n)		; variable (y) (lev,lon,time*)

				if(.not. all(ismissing(varArr)) ) then
					;print("loc: " + lonC(i) + ", nlag: " + (-1*n))
					idxArr				= xseason(0+n:ntim-1)		; index (x) (ntim)

					l1					= esacr(idxArr,1)
					lag1acIdx2			= l1(1)						; lag-1 auto corr of INDEX (single number)
					delete(l1)

					; reg coef (slope) @ current lag and lon pt
;					rcProfFixAnn(s,m,i)  = regline(idxArr(:), varArr(:))       ;   (ngp,lagdays,lev,lon)
					rcProfFixAnn(s,m,i)  = sum(idxArr(:)*varArr(:)) / sum(idxArr(:)^2.)      ;   (lagdays,lev,lon)
				
					; corr coef of regression @ current lag and lon pt
;					cc                   = escorc(idxArr(:), varArr(:))       
				
					; tot # pairs of data in regression
					;   NOTE: SINCE IDX IS LIMITING FACTOR FOR NPTXY (EVEN IF SEASONS ARE USED), NPTXY WILL BE
					;         SAME FOR ALL LAGS!  (I TESTED THIS)
;					nptxy                = rcProfFixAnn@nptxy
;					yint                 = rcProfFixAnn@yintercept
				
					; effective sample size, from Bretherton et al. (1999, JC)
					;essProfFixAnn(i,m,z,u)  = round( nptxy * (1.-(lag1acIdx2*lag1acVarLL(z,u))) / \
					;						   (1.+(lag1acIdx2*lag1acVarLL(z,u))), 3 )
;					essProfFixAnn(s,m,i)  = round( nptxy * (1.-(lag1acIdx2)^2.) / \
;													   (1.+(lag1acIdx2)^2.), 3 )

					; degrees of freedom
;					df = essProfFixAnn(s,m,i) - 2
				
					; determine statistical significance of the linear relationship
					;   (rtest receives cc and ess, computes Student t test, and returns significance
					;   value based on two-tailed test assuming normal distribution of both variables
					;   in regression...note that a returned value of 0.02 = 98% significance level)
;					sigProfFixAnn(s,m,i) = 1. - rtest( cc, essProfFixAnn(s,m,i), 0 )
				
					; statistical signficance level (alternative to look-up table)
					;            studentt = ( cc * sqrt(int2flt(df)) ) / ( sqrt(1.-cc^2) )        ; test... WORKS.
					delete(idxArr)
					delete(lag1acIdx2)
;					delete(cc)
;					delete(df)
;					delete(nptxy)
				end if
				delete(varArr)
			
				; if(i.eq.1.and.u.eq.33) then
				;   print(idxArr + "   " + varArr(u,:))
				;   print(nlag + "   " + lag1acIdx2 + "   " + lag1acVarLL(u) + "   " + rcProfFixAnn(ns,nv,i,m,u) + \
				;         "   " + cc + "   " + nptxy + "   " + yint + "   " + essProfFixAnn(ns,nv,i,m,u) + \
				;         "   " + df + "   " + sigProfFixAnn(ns,nv,i,m,u) + "   " + rcProfTotFixAnn(ns,nv,i,m,u))
				;   if(u.eq.60) then
				;     exit
				;   end if
				; end if

				m = m - 1        ; increment counters  *** IMPORTANT CHANGES FROM + LAGS!!! ***
				n = n + 1

			end do             ; end nlag loop (POSITIVE LAGS)
	
	
			; -----------------------------------
			; Test print
			ln = ind(lon.eq.90)
			if(i.eq.1) then
			  ;print("")
			  ;print("LON Test, 90E regression values for " + inName2 + " at lev=" + lev(lv) + "hPa:")
			  ;print( sprintf("%8.1f",lon(:)) + sprintf("%12.4f",rcProfFixAnn(1,maxLag,lv,:)) + \
			  ;       sprintf("%12.4f",sigProfFixAnn(1,maxLag,lv,:)) )
			  ;print("")
			end if

			if(i.eq.1) then
			  ;print("")
			  ;print("LAG Test, 90E regression values for " + inName2 + " at lev=" + lev(lv) + "hPa:")
			  ;print( sprintf("%8.1f",lag(:)) + sprintf("%12.4f",rcProfFixAnn(1,:,lv,ln)) + \
			  ;       sprintf("%12.4f",sigProfFixAnn(1,:,lv,ln)) )
			  ;print("")
			end if
  
			delete(xseason)
			delete(yseason)
			delete(range)
			delete(hide)
  
		end do  ; end do the season loop


	end do		; end do the longitude loop

  
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

		;-------------- metadata for output fields
		rcdata			= rcProfFixAnn(s,:,:)
		;printVarSummary(rcProfFixAnn)
		;printVarSummary(rcdata)
		rcdata!0		= "lag"
		rcdata!1		= "lon"
		rcdata&lag		= lag
		rcdata&lon		= lon
		rcdata@units	= "["+aa@units + "]/[" + bpunits + "]"
		rcdata@long_name= aa@long_name
		rcdata@season	= seasonNm(s)
	
;		sigdata			= sigProfFixAnn(s,:,:)
;		sigdata!0		= "lag"
;		sigdata!1		= "lon"
;		sigdata&lag		= lag
;		sigdata&lon		= lon
;		sigdata@units	= aa@units
;		sigdata@long_name="95% confidence value"
;		sigdata@season	= seasonNm(s)

		xBPFdata		= xBPF_STD(s,:)
		xBPFdata!0		= "lon"
		xBPFdata&lon	= lon
		xBPFdata@units	= xBPF_ts@units
		xBPFdata@long_name="standard deviation (20-100 day filtered)"
		xBPFdata@season	= seasonNm(s)

		;-------------- output file definitions
		outFile1			= diro+caseName+".make_L2.2_projection_nopropagation." + twStrt + "-" + twLast + "."+outvarName1+"."+outvarName2+"."+seasonNm(s)+".nc"
		system("/bin/rm -f " + outFile1)                  ; remove old file if exists
		fout 				= addfile(outFile1,"c")       ; "pointer" to output file is fout
		setfileoption(fout,"DefineMode",True)
		fAtt				= True
		fAtt@title			= inName2 + " regressed onto filtered " + inName1
		fAtt@author			= "Jim Benedict (jjbenedict@lbl.gov)"
		fAtt@source_file1	= inFile1
		fAtt@source_file2	= inFile2
		fAtt@created		= systemfunc("date")
		fAtt@case			= getenv("simName")
		fAtt@simulation		= getenv("caseName")
		fileattdef( fout, fAtt )            ; copy file attributes

		dimNames = (/"lag", "lon" /)       
		dimSizes = (/ dimsizes(lag),  dimsizes(lon) /) 
		dimUnlim = (/ False, False /)
		filedimdef(fout,dimNames,dimSizes,dimUnlim)
		setfileoption(fout,"DefineMode",False)

		fout->$outvarName2$ = rcdata
;		fout->statSig = sigdata
		fout->gridp_stdev = xBPFdata
		delete(rcdata)
;		delete(sigdata)
		delete(xBPFdata)
		delete(dimNames)
		delete(dimSizes)
		delete(dimUnlim)
	end do ; season output loop



end













