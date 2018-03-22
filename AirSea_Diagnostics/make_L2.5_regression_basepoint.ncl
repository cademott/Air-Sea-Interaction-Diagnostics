load "./Resources/contrib_AirSea.ncl"

begin
  
	print("")
	print("============== in make_L2.5_regression_basepoint.ncl ==============")

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

	;viPressTop 	= stringtofloat(getenv("viPressTop"))
	;viPresTopName = getenv("viPresTopName")

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
	if (inName1.eq."DPI") then
		inFile1	= diri + caseName + "." + "OMEGA.MC.700-200hPa.day.anom.nc"
		inName1	= "DPI"
		Name1	= "DPI"
	else
		inFile1	= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
		inName1	= inName1+"_anom_sm"
		Name1	= substring(inName1,0,str_index_of_substr(inName1,"_anom_sm",0)-1)
	end if
	inFile2		= diri + caseName + "." + inName2 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	inName2		= inName2+"_anom_sm"

	Name2	= substring(inName2,0,str_index_of_substr(inName2,"_anom_sm",0)-1)
	;print("base point variable = "+Name1)
	;print("regressed variable  = "+Name2)

	;------------- seasons
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	; ---------------------------------------------------------
	; open the data file
	f2 = addfile (inFile2 , "r")       ; regressed variable
	lat		= f2->$latName$
	lon		= f2->$lonName$
	time	= f2->$timeName$
	date	= cd_calendar(f2->$timeName$, -2)				; entire file
	;print("2D data file:")
	;printMinMax(date,True)
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	time	= f2->$timeName$(iStrt:iLast)	
	delete(date)

	nlon = dimsizes(lon)
	nlat = dimsizes(lat)
	ntim = dimsizes(time)

	dataIn = f2->$inName2$($timeName$|iStrt:iLast,$latName$|:,$lonName$|:)
	;printVarSummary(dataIn)
	
	if (Name2.eq.pName) then
		rainfact		=stringtofloat(rainFstr)
		dataIn			= dataIn * rainfact
		dataIn@units 	= "mm/day"
	end if			
		

	;---------------------- added by C. DeMott 09-24-2015
	ti			= cd_calendar(time,0)				; entire file
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
	wgty	= latRegWgt(lat({-15:15}), "double", 0)
	;printVarSummary(wgty)
  
  
	;------------- read in precip data and make MJO time series index
	;----------------------- modified by C. DeMott 09-24-2015
	; redefine iStrt, iLast for 2nd time series
	f1 = addfile (inFile1 , "r")       ; PRECT
	;print("inFile1 = " + inFile1)
	time	= f1->$timeName$
	;if (caseName.eq."MetUM-GOML".or.caseName.eq."MetUM-ACM") then
	;	time	= time - 1.
	;end if
	date	= cd_calendar(time,-2)	; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	;print("basepoint file:")
	;printMinMax(date,True)
	;print("twStrt = " + twStrt)
	;print("twLast = " + twLast)
	delete(time)
	delete(date)
	;print("iStrt = " + iStrt)
	;print("iLast = " + iLast)
	time	= f1->$timeName$(iStrt:iLast)
	indBeg	= iStrt
	indEnd	= iLast	
	
	baselon	= (/ 70, 90, 110, 130, 150 /)
	hw		= 10

	;if (inName1.eq."DPI") then
	;	bpts= f1->$inName1$(indBeg:indEnd)
	;else
	;	temp= f1->$inName1$($timeName$|indBeg:indEnd,{$latName$|-15:15},$lonName$|:)
	;	;printVarSummary(temp)
	;	tempf= band_pass_area_time(temp, spd, bpf, wgty, False)   ; must be (time,lat,lon)
	;	;printVarSummary(tempf)
	;	bpts= dim_avg_n_Wrap(tempf(0,:,:),1)
	;	delete(temp)
	;	delete(tempf)
	;end if
	
	; filter entire rainfall array
	temp	= dim_avg_n_Wrap(f1->$inName1$($timeName$|indBeg:indEnd,{$latName$|-15:15},$lonName$|:),1)
	bpts	= wgt_runave_n_Wrap(temp,wgt,1,0)
	;printVarSummary(bpts)
	
	if (Name1.eq.pName) then
		rainfact		=stringtofloat(rainFstr)
		;print("rain factor = " + rainfact)
		bpts			= bpts * rainfact
		bpts@units 		= "mm/day"
	end if	

	;printVarSummary(bpts)		
          
	;-------------------- added by C. DeMott 09-24-2015
	do s=0,0		; season loop
	
		reg_bp		= new( (/dimsizes(baselon),nlat,nlon/), "float")
		sig			= new( (/dimsizes(baselon),nlat,nlon/), "float")
		bp_stdev	= new( dimsizes(baselon), "float")
	
		if (s.eq.0) then
			range 	= n2a
			hide	= m2o
		else
			range	= m2o
			hide	= n2a
		end if
		print("processing "+seasonNm(s))

		do n=0,dimsizes(baselon)-1
			bpW				= baselon(n) - hw
			bpE				= baselon(n) + hw
			bpseason		= dim_avg_n_Wrap(bpts(:,{bpW:bpE}),1)
			bpseason(hide)	= bpts@_FillValue
			reg_bp(n,:,:)	= regCoef(bpseason,dataIn($latName$|:,$lonName$|:,$timeName$|:))
			bp_stdev(n)		= (/ stddev(bpseason) /)

			;======= build in significance testing ===========
			l1				= esacr(bpseason,1)  ; lag-1 auto corr of BASEPOINT (single number)
			lag1acBP		= new ( (/dimsizes(lat),dimsizes(lon)/),typeof(l1))
			lag1acBP		= (/ l1(1) /)
			delete(l1)
			l1				= esacr(dataIn($latName$|:,$lonName$|:,$timeName$|:),1)
			lag1acDATA		= l1(:,:,1)                    ; lag-1 auto corr of DATAIN (lat,lon)
			delete(l1)

			; npts of basepoint
			npts			= dimsizes(range)

			; local correlation of basepoint and data
			cc				= escorc(bpseason,dataIn($latName$|:,$lonName$|:,$timeName$|:))

			; effective sample size, from Bretherton et al. (1999, JC)
			ess				= round( npts * (1.-(lag1acBP*lag1acDATA)) / (1.+(lag1acBP*lag1acDATA)),3)

			; two-tailed p-value (95% confidence means p<=0.05)
			sig(n,:,:)		= 1. - rtest(cc,ess-2,0)
		end do ; base point loop
	 
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

  
		outFile1	= diro+caseName+".make_L2.5_regression_basepoint." + twStrt + "-" + twLast + "."+outvarName1+"."+outvarName2+"." + seasonName(s)+".nc"
		system("/bin/rm -f " + outFile1)                  ; remove old file if exists
		fout = addfile(outFile1,"c")                      ; "pointer" to output file is fout
		print("output file = " + outFile1)

		
		reg_out				= (/ reg_bp /)
		reg_out!0 			= "basepoint"
		reg_out@basepoint	= baselon
		reg_out!1			= "lat"
		reg_out&lat			= dataIn&$latName$
		reg_out!2			= "lon"
		reg_out&lon			= dataIn&$lonName$
		reg_out@units		= dataIn@units + "/[mm/day]"
		
		bp_stdev!0			= "basepoint"
		bp_stdev&basepoint	= baselon
		bp_stdev@long_name	= "base point standard deviation"
		
		copy_VarCoords(reg_out,sig)
		sig@long_name		= "two-tailed significance"
		sig@units			= "p-value"
		sig@method			= "effective sample size as in Bretherton et al. (1999, JC)"

		sdName				= outvarName2 + "_stddev"
		fout->$sdName$		= bp_stdev
		regName				= outvarName2 + "_reg"
		fout->$regName$ 	= reg_out
		sigName				= outvarName2 + "_sig"
		fout->$sigName$		= sig
		
		delete(range)
		delete(reg_bp)
		delete(bpseason)
		delete(hide)
		delete(reg_out)
		delete(sig)
		delete(bp_stdev)

	end do 	; season loop

end













