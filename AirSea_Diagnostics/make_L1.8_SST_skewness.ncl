load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin

  
	print("")
	print("============= in make_L1.8_SST_skewness.ncl =============")   

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	min_lon_map	= 30.
	max_lon_map	= 270.

	;----------- retrieve required environment variables
	diri		= getenv("FILEDIR")+"/"
	diro		= getenv("FILEDIR")+"/proc/"
	mseName		= getenv("mseName")
	dmdtName	= getenv("dmdtName")
	caseName	= getenv("caseName")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")
	timeName	= getenv("TIMEVAR")
	sstName		= getenv("SSTVARNAME")

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

	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;--------------- read data
	fili		= caseName + "." + sstName + "." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	time		= f->$timeName$
	ti 			= calendar_decode2(time, -5)   ; time info for MSE ANOM
	date		= cd_calendar(f->$timeName$, -2)	; entire file
	iStrt  		= ind(date.eq.twStrt)      			; desired dates
	iLast  		= ind(date.eq.twLast)
	delete(time)
	delete(ti)

	time		= f->$timeName$(iStrt:iLast)
	ti 			= calendar_decode2(time, -5)   ; time info for MSE ANOM
	month     	= ti(:,1)
	month		= rm_single_dims(month)
	n2a			= ind(month.ge.11.or.month.le.4)	; Nov-Apr
	m2o			= ind(month.ge.5.and.month.le.10)	; May-Oct

	tName		= sstName + "_anom_sm"
	sst			= f->$tName$(iStrt:iLast,:,:)
	sst_full	= sst

	;--------------- apply land mask
	a    		= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
	lsdata		= a->LSMASK
	lsm			= landsea_mask(lsdata,sst_full&$latName$,sst_full&$lonName$)
	sst_full	= mask(sst_full,conform(sst_full,rm_single_dims(lsm),(/1,2/)).ge.1,False)

	do s=0,1

		;--------------- mask out other season
		sst							= sst_full
		if (s.eq.0) then
			sst(m2o,:,:)			= sst@_FillValue
		else
			sst(n2a,:,:)			= sst@_FillValue
		end if		

		;--------------- compute sst, skewness
		moments				= dim_stat4_n(sst,0)
		skew_sst			= rm_single_dims(moments(2,:,:))
		copy_VarCoords_1(sst($latName$|:,$lonName$|:,$timeName$|:),skew_sst)
		skew_sst@long_name	= "SST skewness"
		skew_sst@units		= "K"
		printMinMax(skew_sst,True)

		;--------------- compute median SST anomaly
		median_sst		= dim_median_n(sst,0)
		copy_VarCoords(skew_sst,median_sst)
		median_sst@long_name	= "median SST"
		median_sst@units		= "K"
		printMinMax(median_sst,True)

		filo			= caseName + ".make_L1.8_SST_skewness." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		;print(diro+filo)
		system("/bin/rm -f "+diro+filo)      ; rm any pre-exist file, if any
		ncdf			= addfile(diro+filo,"c")
		tName			= "SST_skewness"
		ncdf->$tName$	= skew_sst
		tName			= "SST_median"
		ncdf->$tName$	= median_sst
		

		delete(sst)
		delete(skew_sst)
		delete(median_sst)

	end do ; season loop

end

