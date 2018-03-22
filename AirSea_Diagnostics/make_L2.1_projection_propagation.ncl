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
	print("============== in make_L2.1_projection_propagation.ncl ==============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

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

	viPressTop 	= stringtofloat(getenv("viPressTop"))
	viPresTopName = getenv("viPresTopName")

	diri		= getenv("FILEDIR") + "/"
	diro		= diri + "proc/"		
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
	latName		= getenv("LATNAME")
	lonName		= getenv("LONNAME")
	rainFstr	= getenv("RAINFACTOR")
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

	; ---------------------------------------------------------
	; spatial domains for MJO index
	hw   = 5.                                        ; "half-width" of lon span for MJO index domain
	sss = -10.
	nnn = 10.
	;latS = (/sss,sss,sss,sss,sss/)               ; south edge for MJO index domain
	;latN = (/nnn,nnn,nnn,nnn,nnn/)               ; north edge for MJO index domain
	;latSfixAnn = (/sss,sss,sss,sss,sss/)         ; south edge for reg prof lat domain, annual
	;latNfixAnn = (/nnn,nnn,nnn,nnn,nnn/)         ; north edge for reg prof lat domain, annual
	;lonC = (/60.,90.,120.,150.,180./)            ; central lon
	;lonW = (/lonC(0)-hw,lonC(1)-hw,lonC(2)-hw,lonC(3)-hw,lonC(4)-hw/)       ; west edge, for index lon avging
	;lonE = (/lonC(0)+hw,lonC(1)+hw,lonC(2)+hw,lonC(3)+hw,lonC(4)+hw/)       ; east edge, for index lon avging
	latS = (/sss,sss/)               ; south edge for MJO index domain
	latN = (/nnn,nnn/)               ; north edge for MJO index domain
	latSfixAnn = (/sss,sss/)         ; south edge for reg prof lat domain, annual
	latNfixAnn = (/nnn,nnn/)         ; north edge for reg prof lat domain, annual
	lonC = (/90.,150./)            ; central lon
	lonW = (/lonC(0)-hw,lonC(1)-hw/)       ; west edge, for index lon avging
	lonE = (/lonC(0)+hw,lonC(1)+hw/)       ; east edge, for index lon avging
	ngp  = dimsizes(lonC)                             ; # index points


	; ---------------------------------------------------------
	; open file data
	f1 = addfile (inFile1 , "r")       ; PRECT
	f2 = addfile (inFile2 , "r")       ; regressed variable

	; ---------------------------------
	; Query to see if "lev" is a dimension
	if(isdim(f2->$inName2$,"lev")) then
		ndim = 4
	else
		ndim = 3
	end if
	;dNames	= getfilevardims(f,"t")
	;ndim	= dimsizes(dNames)
	
	lat   = f2->$latName$
	lon   = f2->$lonName$
	time   = f2->$timeName$
	date	= cd_calendar(f2->$timeName$, -2)				; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	time	= f1->$timeName$(iStrt:iLast)	
	;printMinMax(date,True)
	delete(date)
	if(ndim .eq. 4) then
		lev   = f2->$levName$
	else
		lev = new(1,"float",-999.)
		lev = -999.
	end if
	lev@long_name = "Pressure (hPa)"


	nlon = dimsizes(lon)
	nlat = dimsizes(lat)
	ntim = dimsizes(time)
	if(ndim .eq. 4) then
		nlev = dimsizes(lev)
	else
		nlev = 1
	end if

	if (ndim.eq.3) then
		dataIn = f2->$inName2$($timeName$|iStrt:iLast,$latName$|:,$lonName$|:)
	else if (ndim.eq.4) then
		dataIn = f2->$inName2$($timeName$|iStrt:iLast,$levName$|:,$latName$|:,$lonName$|:)
	end if
	;end if
	
	if (Name2.eq.pName) then
		rainfact		=stringtofloat(rainFstr)
		;print("rain factor = " + rainfact)
		dataIn			= dataIn * rainfact
		dataIn@units 	= "mm/day"
	end if			
		

	ti = calendar_decode2(time, -5)   ; time info for MSE ANOM
    indBeg	= iStrt
    indEnd	= iLast 
                 
	;---------------------- added by C. DeMott 09-24-2015
	month		= ti(:,1)
	month		= rm_single_dims(month)
	n2a			= ind(month.ge.11.or.month.le.4)	; Nov-Apr
	m2o			= ind(month.ge.5.and.month.le.10)	; May-Oct
	seasonid	= (/"n2a","m2o"/)
	seasonNm	= (/"Nov-Apr","May-Oct"/)
	delete(time)
	;------------------------------------------------------------------

	; ---------------------------------------------------------
	; settings for lagged linear regression
	maxLag		= 30
	lagdays		= 2*maxLag+1
	lag			= ispan(-1*maxLag,maxLag,1)

	; ---------------------------------------------------------
	; create BandPass Filter
	ihp		= 2                             ; bpf=>band pass filter
	nWgt	= 201
	sigma	= 1.0                           ; Lanczos sigma
	fca		= 1./100.
	fcb		= 1./20.
	wgt		= filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )
  
	; for area averaging first, then BPF
	spd		= 1               ; samples per day
	bpf		= (/20,100,201/)  ; input for band pass

	nhar	= 3                                  ; # Fourier harmonics to keep
											 ;   3 = 0th(mean), 1st, 2nd, and 3rd harmonics of
											 ;   seasonal cycle
  
  
	;------------- read in precip data and make MJO time series index
	;----------------------- modified by C. DeMott 09-24-2015
	; redefine iStrt, iLast for 2nd time series
	time	= f1->$timeName$
	date	= cd_calendar(f1->$timeName$, -2)	; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	delete(date)
	time	= f1->$timeName$(iStrt:iLast)
	indBeg	= iStrt
	indEnd	= iLast	

	;------------- define precipitation index array
	pidx      = new((/ngp,dimsizes(time)/),"float",default_fillvalue("float")) ; full, annual index time series
	

	xBPF_ts				= new((/ngp,dimsizes(time)/),"float",default_fillvalue("float"))
	xBPF_ts!0			= "gridp"
	xBPF_ts!1			= "time"
	xBPF_ts&$timeName$	=time
	do i = 0,ngp-1
		x 			= f1->$inName1$($timeName$|indBeg:indEnd,{$latName$|latS(i):latN(i)},{$lonName$|lonW(i):lonE(i)})
		if (Name1.eq.pName) then
			rainfact=stringtofloat(rainFstr)
			;print("rain factor = " + rainfact)
			x		= x * rainfact
			x@units = "mm/day"
		end if			
		bpunits		= x@units
		wgty		= latRegWgt(x&$latName$, "double", 0)
		xBPF		= band_pass_area_time(x, spd, bpf, wgty, False)   ; must be (time,lat,lon)
		;printVarSummary(xBPF)
		;pidx(i,:)  = doubletofloat(xBPF_STD)                        ; pidx(ngp,time)
		xBPF_ts(i,:)= doubletofloat(rm_single_dims(xBPF(0,:)))
		if (i.eq.1) then 
			copy_VarAtts(xBPF,xBPF_ts)
		end if
		pidx(i,:)	= doubletofloat(rm_single_dims(xBPF(0,:)))    ; pidx(ngp,time)

		delete(x)
		delete(wgty)
		delete(xBPF)
		;delete(xBPF_STD)
	end do
	;printVarSummary(xBPF_ts)
	;----------------------------------------------------------
  
  ; compute lon profiles
  if(ndim .eq. 3) then
	aa = new((/ntim,1,nlon,nlat/),typeof(dataIn),default_fillvalue(typeof(dataIn)))
	aa(:,0,:,:) = dataIn($timeName$|:,$lonName$|:,$latName$|:)
	aa!1 = "lev"
	aa&lev = lev
  else
    aa = dataIn($timeName$|:,$levName$|:,$lonName$|:,$latName$|:)
  end if
  ;-------------------- if dataIn is SST or SKT, mask out land points; C. DeMott 09-25-2015
  ;if (Name2.eq."SST".or.Name2.eq."SKT") then ; fixme:  this needs to allow for multiple SST varnames
  if (Name2.eq.sstName.or.Name2.eq.lhName.or.Name2.eq.shName) then ; fixme:  do for all sfc flux variables?
  ;if (Name2.eq.sstName) then ; fixme:  do for all sfc flux variables?
	a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
	lsdata=a->LSMASK
	;printVarSummary(aa)
	lsm=landsea_mask(lsdata,aa&lat,aa&lon)
	;printVarSummary(lsm)
	;printMinMax(aa,True)
	aa = mask(aa,conform(aa,lsm($lonName$|:,$latName$|:),(/2,3/)).ge.1,False)
	;printMinMax(aa,True)
  end if
  ;-----------------------------------------------------------------------------
	
  yfixAnn = dim_avg_Wrap(aa(:,:,:,{latSfixAnn(0):latNfixAnn(0)}))     ; (time,lev,lon)
  
  ;printVarSummary(yfixAnn)
          
  ;-------------------- added by C. DeMott 09-24-2015
  do s=0,1		; season loop
    if (s.eq.0) then
    	range 	= n2a
    	hide	= m2o
    else
    	range	= m2o
    	hide	= n2a
    end if
    print("processing "+seasonNm(s))
	pidx(:,hide)	= xBPF_ts@_FillValue 	; set "other season" values to missing so not included
	pidx@_FillValue = xBPF_ts@_FillValue
	xBPF_STD  = new((/ngp/),"float")
  ;--------------------------------------------------

	rcProfFixAnn    = new((/ngp,lagdays,nlev,nlon/),"float",default_fillvalue("float"))
	sigProfFixAnn   = new((/ngp,lagdays,nlev,nlon/),"float",default_fillvalue("float"))
	essProfFixAnn   = new((/ngp,lagdays,nlev,nlon/),"integer",-999)  
  

  do i = 0,ngp-1
  
  ;-------------------- added by C. DeMott 09-24-2015
	xBPF_STD(i)	= dim_stddev(pidx(i,:))	; this array now just contains the
										; base point time series st dev
  ;--------------------------------------------------
    ; ZERO AND POSITIVE LAGS (regressed variable FOLLOWS index... index "leads")
    m = maxLag        ; index counter
    do nlag = 0,maxLag                                    ; lag 0 to maxLag
      ;print("loc: " + lonC(i) + ", nlag: " + nlag)
      idxArr               = pidx(i,0:ntim-1-nlag)        ; index (x) (ntim)
      varArr               = yfixAnn(lev|:,lon|:,time|0+nlag:ntim-1)  ; variable (y) (lev,lon,time*)
          
      l1                   = esacr(idxArr,1)
      lag1acIdx2           = l1(1)                        ; lag-1 auto corr of INDEX (single number)
      delete(l1)
          
      l1                   = esacr(varArr,1)
      lag1acVarLL          = l1(:,:,1)                      ; lag-1 auto corr of VARIABLE (lev,lon)
      delete(l1)
          
      do z = 0,nlev-1
        do u = 0,nlon-1
          if(.not. all(ismissing(varArr(z,u,:))) ) then
            ; reg coef (slope) @ current lag and lon pt
            ;rcProfFixAnn(i,m,z,u)  = regline(idxArr(:), varArr(z,u,:))       ;   (ngp,lagdays,lev,lon)

;			if (z.eq.0.and.u.eq.0) then
;				aa		= regline(idxArr(:), varArr(z,u,:))
;				printVarSummary(aa)
;			
;				printVarSummary(idxArr)
;				printVarSummary(rm_single_dims(varArr(z,u,:)))
;			
;				bb		= sum(idxArr(:)*rm_single_dims(varArr(z,u,:))) / sum(idxArr(:)^2.)
;				printVarSummary(bb)
;			end if
            rcProfFixAnn(i,m,z,u)  = sum(idxArr(:)*rm_single_dims(varArr(z,u,:))) / sum(idxArr(:)^2.)       ;   (ngp,lagdays,lev,lon)
            
            ; corr coef of regression @ current lag and lon pt
            cc                   = escorc(idxArr(:), varArr(z,u,:))       
            
            ; tot # pairs of data in regression
            ;   NOTE: SINCE IDX IS LIMITING FACTOR FOR NPTXY (EVEN IF SEASONS ARE USED), NPTXY WILL BE
            ;         SAME FOR ALL LAGS!  (I TESTED THIS)
;            nptxy                = rcProfFixAnn@nptxy
;            yint                 = rcProfFixAnn@yintercept
            
            ; effective sample size, from Bretherton et al. (1999, JC)
;            essProfFixAnn(i,m,z,u)  = round( nptxy * (1.-(lag1acIdx2*lag1acVarLL(z,u))) / \
;                                           (1.+(lag1acIdx2*lag1acVarLL(z,u))), 3 )
            ; degrees of freedom
;            df = essProfFixAnn(i,m,z,u) - 2
            
            ; determine statistical significance of the linear relationship
            ;   (rtest receives cc and ess, computes Student t test, and returns significance
            ;   value based on two-tailed test assuming normal distribution of both variables
            ;   in regression...note that a returned value of 0.02 = 98% significance level)
;            sigProfFixAnn(i,m,z,u) = 1. - rtest( cc, essProfFixAnn(i,m,z,u), 0 )
            
            ; statistical signficance level (alternative to look-up table)
;            studentt = ( cc * sqrt(int2flt(df)) ) / ( sqrt(1.-cc^2) )        ; test... WORKS.
          end if
          
;          if(i.eq.1.and.u.eq.33) then
;            print(idxArr + "   " + varArr(u,:))
;            print(nlag + "   " + lag1acIdx2 + "   " + lag1acVarLL(u) + "   " + rcProfFixAnn(ns,nv,i,m,u) + \
;                  "   " + cc + "   " + nptxy + "   " + yint + "   " + essProfFixAnn(ns,nv,i,m,u) + \
;                  "   " + df + "   " + sigProfFixAnn(ns,nv,i,m,u) + "   " + rcProfTotFixAnn(ns,nv,i,m,u))
;            if(u.eq.60) then
;              exit
;            end if
;          end if
        end do       ; end u loop (nlon)
      end do         ; end z loop (nlev)
      delete(idxArr)
      delete(varArr)
      delete(lag1acIdx2)
;      delete(lag1acIdx2Map)
      delete(lag1acVarLL)
      delete(cc)
;      delete(df)
;      delete(nptxy)
      m = m + 1
    end do             ; end nlag loop (POSITIVE LAGS)
    
    ; NEGATIVE LAGS (regressed variable PRECEDES index... index "follow")
    m = maxLag-1
    n = 1
    do nlag = 0,maxLag-1                     ; lag -1 to -1*maxLag
      ;print("loc: " + lonC(i) + ", nlag: " + (-1*n))
      idxArr = pidx(i,0+n:ntim-1)            ; index (x) (ntim)
      varArr               = yfixAnn(lev|:,lon|:,time|0:ntim-1-n)  ; variable (y) (lev,lon,time*)
          
      l1                   = esacr(idxArr,1)
      lag1acIdx2           = l1(1)                        ; lag-1 auto corr of INDEX (single number)
      delete(l1)
          
      l1                   = esacr(varArr,1)
      lag1acVarLL          = l1(:,:,1)                      ; lag-1 auto corr of VARIABLE (lev,lon)
      delete(l1)
          
      do z = 0,nlev-1
;        print("z: " + z + "   " + lev(z))
        do u = 0,nlon-1
          if(.not. all(ismissing(varArr(z,u,:))) ) then
            ; reg coef (slope) @ current lag and lon pt
            ;rcProfFixAnn(i,m,z,u)  = regline(idxArr(:), varArr(z,u,:))       ;   (ngp,lagdays,lev,lon)
            rcProfFixAnn(i,m,z,u)  = sum(idxArr(:)*rm_single_dims(varArr(z,u,:))) / sum(idxArr(:)^2.)       ;   (ngp,lagdays,lev,lon)
            ; corr coef of regression @ current lag and lon pt
            cc                   = escorc(idxArr(:), varArr(z,u,:))       
            ; tot # pairs of data in regression
            ;   NOTE: SINCE IDX IS LIMITING FACTOR FOR NPTXY (EVEN IF SEASONS ARE USED), NPTXY WILL BE
            ;         SAME FOR ALL LAGS!  (I TESTED THIS)
;            nptxy                = rcProfFixAnn@nptxy
;            yint                 = rcProfFixAnn@yintercept
            ; effective sample size, from Bretherton et al. (1999, JC)
;            essProfFixAnn(i,m,z,u)  = round( nptxy * (1.-(lag1acIdx2*lag1acVarLL(z,u))) / \
;                                           (1.+(lag1acIdx2*lag1acVarLL(z,u))), 3 )
            ; degrees of freedom
;            df = essProfFixAnn(i,m,z,u) - 2
            ; determine statistical significance of the linear relationship
            ;   (rtest receives cc and ess, computes Student t test, and returns significance
            ;   value based on two-tailed test assuming normal distribution of both variables
            ;   in regression...note that a returned value of 0.02 = 98% significance level)
;            sigProfFixAnn(i,m,z,u) = 1. - rtest( cc, essProfFixAnn(i,m,z,u), 0 )
            ; statistical signficance level (alternative to look-up table)
;            studentt = ( cc * sqrt(int2flt(df)) ) / ( sqrt(1.-cc^2) )        ; test... WORKS.
          end if
;          if(i.eq.1.and.u.eq.33) then
;            print(idxArr + "   " + varArr(u,:))
;            print(nlag + "   " + lag1acIdx2 + "   " + lag1acVarLL(u) + "   " + rcProfFixAnn(ns,nv,i,m,u) + \
;                  "   " + cc + "   " + nptxy + "   " + yint + "   " + essProfFixAnn(ns,nv,i,m,u) + \
;                  "   " + df + "   " + sigProfFixAnn(ns,nv,i,m,u) + "   " + rcProfTotFixAnn(ns,nv,i,m,u))
;            if(u.eq.60) then
;              exit
;            end if
;          end if
        end do       ; end u loop (nlon)
      end do         ; end z loop (nlev)
      delete(idxArr)
      delete(varArr)
      delete(lag1acIdx2)
;      delete(lag1acIdx2Map)
      delete(lag1acVarLL)
      delete(cc)
;      delete(df)
;      delete(nptxy)
      
      m = m - 1        ; increment counters  *** IMPORTANT CHANGES FROM + LAGS!!! ***
      n = n + 1
      
    end do             ; end nlag loop (POSITIVE LAGS)
    
    
    ; -----------------------------------
    ; Test print
    if(ndim .eq. 3) then
      lv = 0
    else
      lv = ind(lev .eq. 850)
    end if
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
  
  
  end do   ; end do i loop (ngp)

  
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

	;------------ write data to file       
	rcProfFixAnn!0 = "gridp"
	rcProfFixAnn!1 = "lag"
	rcProfFixAnn!2 = "lev"
	rcProfFixAnn!3 = "lon"
	rcProfFixAnn&gridp = lonC
	rcProfFixAnn&lag   = lag
	rcProfFixAnn&lev   = lev
	rcProfFixAnn&lon   = lon
	rcProfFixAnn@units      = "["+dataIn@units + "]/[" + bpunits + "]"
	rcProfFixAnn@long_name  = dataIn@long_name
	if(Name2 .eq. "Q" .and. rcProfFixAnn@units .eq. "kg/kg") then
		rcProfFixAnn       = rcProfFixAnn * 1000.
		rcProfFixAnn@units = "g/kg"
	end if
	;printVarSummary(rcProfFixAnn)
;	sigProfFixAnn!0 = "gridp"
;	sigProfFixAnn!1 = "lag"
;	sigProfFixAnn!2 = "lev"
;	sigProfFixAnn!3 = "lon"
;	sigProfFixAnn&gridp = lonC
;	sigProfFixAnn&lag   = lag
;	sigProfFixAnn&lev   = lev
;	sigProfFixAnn&lon   = lon
;	sigProfFixAnn@units      = dataIn@units
;	sigProfFixAnn@long_name  = "95% confidence value"

	xBPF_STD!0	 = "gridp"
	xBPF_STD&gridp = lonC
	xBPF_STD@units = dataIn@units
  
	outFile1	= diro+caseName+".make_L2.1_projection_propagation." + twStrt + "-" + twLast + "."+outvarName1+"."+outvarName2+"."+seasonNm(s)+".nc"
	system("/bin/rm -f " + outFile1)                  ; remove old file if exists
	fout = addfile(outFile1,"c")                      ; "pointer" to output file is fout
	setfileoption(fout,"DefineMode",True)
	fAtt               = True
	fAtt@title         = Name2 + " projected onto MJO-filtered " + Name1
	fAtt@author        = "Jim Benedict (jjbenedict@lbl.gov)"
	fAtt@source_file1  = inFile1
	fAtt@source_file2  = inFile2
	fAtt@created       = systemfunc("date")
	fAtt@case          = getenv("simName")
	fAtt@simulation    = getenv("caseName")
	fileattdef( fout, fAtt )            ; copy file attributes

	dimNames 			= (/"time", "lev", "lat", "lon" /)       ; include "lev" dim even for 3D input vars
	dimSizes 			= (/ -1   ,  dimsizes(lev), dimsizes(lat),  dimsizes(lon) /) 
	dimUnlim 			= (/ True , False, False, False /)
	filedimdef(fout,dimNames,dimSizes,dimUnlim)
	setfileoption(fout,"DefineMode",False)

	fout->$outvarName2$ = rcProfFixAnn
;	fout->statSig = sigProfFixAnn
	fout->gridp_stdev = xBPF_STD
	delete(dimNames)
	delete(dimSizes)
	delete(dimUnlim)

	delete(xBPF_STD)
	;---------------------- added by C. DeMott 09-24-2015
	;delete(fout)
	delete(range)
	delete(hide)
	delete(rcProfFixAnn)
	delete(sigProfFixAnn)
	delete(essProfFixAnn)

	;printVarSummary(pidx)
	;printVarSummary(xBPF_ts)
	pidx	= xBPF_ts	; reset pdix for next season processing
	end do 	; season loop
	;-----------------------------------------------------
  

end













