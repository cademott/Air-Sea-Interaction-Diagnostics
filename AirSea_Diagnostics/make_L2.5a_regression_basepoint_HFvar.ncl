load "./Resources/contrib_AirSea.ncl"

begin
  
	print("")
	print("============== in make_L2.5a_regression_basepoint_HFvar.ncl ==============")

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
	if (inName1.eq."DPI") then
		inFile1	= diri + caseName + "." + "OMEGA.MC.700-200hPa.day.anom.nc"
		inName1	= "DPI"
		Name1	= "DPI"
	else
		inFile1	= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
		inName1	= inName1+"_anom_sm"
		Name1	= substring(inName1,0,str_index_of_substr(inName1,"_anom_sm",0)-1)
	end if
	inFile2		= diri + caseName + "." + inName2 + ".HiPass_filtered."+ dateStr + "." + latbandStr + ".nc"
	inName2		= inName2+"_runvar_anom"

	Name2	= substring(inName2,0,str_index_of_substr(inName2,"_runvar_anom",0)-1)
	print("base point variable = "+Name1)
	print("regressed variable  = "+Name2)

	;------------- seasons
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	; ---------------------------------------------------------
	; open the data file
	f2 = addfile (inFile2 , "r")       ; regressed variable
	lat		= f2->$latName$
	lon		= f2->$lonName$
	time	= f2->$timeName$
	date	= cd_calendar(f2->$timeName$, -2)				; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	time	= f2->$timeName$(iStrt:iLast)	
	delete(date)

	nlon = dimsizes(lon)
	nlat = dimsizes(lat)
	ntim = dimsizes(time)

	dataIn = f2->$inName2$($timeName$|iStrt:iLast,$latName$|:,$lonName$|:)
	
	if (Name2.eq.pName) then
		rainfact		=stringtofloat(rainFstr)
		;print("rain factor = " + rainfact)
		;dataIn			= dataIn * rainfact
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

	nhar	= 3                                  ; # Fourier harmonics to keep
											 ;   3 = 0th(mean), 1st, 2nd, and 3rd harmonics of
											 ;   seasonal cycle
  
  
	;------------- read in precip data and make MJO time series index
	;----------------------- modified by C. DeMott 09-24-2015
	f1 = addfile (inFile1 , "r")       ; PRECT	;print("inFile1 = " + inFile1)
	time	= f1->time
	if (caseName.eq."MetUM-GOML".or.caseName.eq."MetUM-ACM") then
		time	= time - 1.
	end if
	date	= cd_calendar(time,-2)	; entire file
	iStrt 	= ind(date.eq.twStrt)				; desired dates
	iLast 	= ind(date.eq.twLast)
	delete(time)
	delete(date)
	time	= f1->time(iStrt:iLast)
	indBeg	= iStrt
	indEnd	= iLast	

	if (inName1.eq."DPI") then
		bpts= f1->$inName1$(indBeg:indEnd)
	else
		bpts= f1->$inName1$($timeName$|indBeg:indEnd,{$latName$|latS(i):latN(i)},{$lonName$|lonW(i):lonE(i)})
	end if
	
	ndays	= dimsizes(bpts)
          
	;-------------------- added by C. DeMott 09-24-2015
	do s=0,1		; season loop
	
		data_reg	= new( (/lagdays,dimsizes(dataIn&$latName$),dimsizes(dataIn&$lonName$)/) , "float")
		data_sig	= new( (/lagdays,dimsizes(dataIn&$latName$),dimsizes(dataIn&$lonName$)/) , "float")
	
		if (s.eq.0) then
			range 	= n2a
			hide	= m2o
		else
			range	= m2o
			hide	= n2a
		end if
		bpseason	= bpts
		bpseason(hide)	= bpseason@_FillValue
		
		do i=0,dimsizes(lag)-1 ; lag loop
		
			;print("lag = " + lag(i))
			nshift		= lag(i)
			if (nshift.lt.0) then
				x1		= ndays-1+nshift
				x2		= -1*nshift
				x3		= ndays-1
				tdata	= dataIn(0:ndays-1+nshift,:,:)
				rdata	= bpseason(-1*nshift:ndays-1)
			else if (nshift.eq.0) then
				tdata	= dataIn
				rdata	= bpseason
			else if (nshift.gt.0) then
				x1		= ndays-1-nshift
				x2		= nshift
				x3		= ndays-1
				tdata	= dataIn(x2:x3,:,:)
				rdata	= bpseason(0:x1)
			end if
			end if
			end if				

			;----- calculate regressions for Nov-Apr
			N				= num(.not.ismissing(rdata))
			reg				= regCoef_n(rdata,tdata,0,0)
			data_reg(i,:,:)	= (/ reg /)

			;===== significance testing
			ac				= esacr(rdata,1)
			RIO_ac1			= ac(1)
			ac1				= esacr(tdata($latName$|:,$lonName$|:,$timeName$|:),1)
			data_ac1		= rm_single_dims(ac1(:,:,1))
			;----- lag-0 correlation
			data_cc			= escorc_n(rdata,tdata,0,0)

			;----- effective sample size (Bretherton et al. (1999, J. Climate))
			data_dof		= round( N * (1. - data_ac1 * conform_dims(dimsizes(data_ac1),RIO_ac1,-1)) / \
									 (1. + data_ac1 * conform_dims(dimsizes(data_ac1),RIO_ac1,-1)), 3 ) -2

			;----- significance level (a returned value of 0.02 = 98% significance; i.e., p-value)
			data_sig(i,:,:)	= (/ 1. - rtest(data_cc,data_dof,0) /)
			
			delete(rdata)
			delete(tdata)

		end do ; lag loop
		;printVarSummary(reg_bp)
		printMinMax(data_reg,True)

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
		outname				= outvarName2 + "_HFvar"
		print("outvarName2	= "+outname)


		outFile1	= diro+caseName+".make_L2.5a_regression_basepoint." + twStrt + "-" + twLast + "."+outvarName1+"."+outname+"."+seasonNm(s)+".nc"
		system("/bin/rm -f " + outFile1)                  ; remove old file if exists
		fout = addfile(outFile1,"c")                      ; "pointer" to output file is fout
		print("output file = " + outFile1)

		data_reg!0			= "lag"
		data_reg&lag			= lag
		data_reg!1			= "lat"
		data_reg&lat			= dataIn&$latName$
		data_reg!2			= "lon"
		data_reg&lon			= dataIn&$lonName$
		data_reg@units		= "[mm/day]/[Pa/s]"

		copy_VarCoords(data_reg,data_sig)
		data_sig@long_name	= "p-value"

		fout->$outname$ 	= data_reg
		outname				= outvarName2 + "_sig"
		fout->$outname$		= data_sig
		fout->bp_stdev		= stddev(bpts)

		delete(range)
		delete(bpseason)
		delete(hide)
		delete(data_reg)
		delete(data_sig)
		delete(data_dof)

	end do 	; season loop
	;-----------------------------------------------------
  

end













