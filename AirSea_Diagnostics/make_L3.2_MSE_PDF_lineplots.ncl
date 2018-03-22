load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin
  
	print("")
	print("============= in make_L3.2_MSE_PDF_lineplots.ncl =============")   

	;----------- retrieve required environment variables	
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

	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")


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

	;------------- define lat/lon limits of analysis
	latS		= -10
	latN		= 10
	lonW		= 60
	lonE		= 160

	;------------- read in metadata from MSE anomaly file 
	Name1		= "Vmse"
	inFile1		= diri + caseName + "." + Name1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")

	;------------- land mask
	lon		= f1->$lonName$({lonW:lonE})
	lat		= f1->$latName$({latS:latN})
	a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
	lsdata	= a->LSMASK
	lsm		= landsea_mask(lsdata,lat,lon)

	;------------- start, end dates
	date		= cd_calendar(f1->$timeName$, -2)	; entire file
	iStrt 		= ind(date.eq.twStrt)				; desired dates
	iLast 		= ind(date.eq.twLast)
	delete(date)
	time		= f1->$timeName$(iStrt:iLast)

	;------------- define seasons
	ti 			= calendar_decode2(time, -5)   
	month     	= ti(:,1)
	month		= rm_single_dims(month)
	n2a			= ind(month.ge.11.or.month.le.4)	; Nov-Apr
	m2o			= ind(month.ge.5.and.month.le.10)	; May-Oct
	seasonid	= (/"n2a","m2o"/)
	seasonName	= (/"Nov-Apr","May-Oct"/)
	seasonMask	= (/"m2o","s2a"/)

	;------------- read in MSE anomaly time series 
	inName1		= "Vmse"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	tName		= inName1+"_anom_sm"
	mse_anom	= f1->$tName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	;------------- read in MSE budget term daily mean time series 
	inName1		= "Vomegadmdp"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	vadv_mean	= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vomegadmdp_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	vadv_anom	= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= "Vm_hadv"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	hadv_mean	= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vm_hadv_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	hadv_anom	= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= "Vudmdx"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	udmdx_mean	= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vudmdx_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	udmdx_anom	= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= "Vvdmdy"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	vdmdy_mean	= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vvdmdy_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	vdmdy_anom	= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= "Vlw"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	lw_mean		= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vlw_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	lw_anom		= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= "Vsw"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	sw_mean		= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= "Vsw_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	sw_anom		= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= lhName
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	lh_mean		= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= lhName + "_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	lh_anom		= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	inName1		= shName
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
	f1			= addfile(inFile1,"r")
	sh_mean		= f1->$inName1$(iStrt:iLast,{latS:latN},{lonW:lonE})
	vName		= shName + "_anom_sm"
	inFile1		= diri + caseName + "." + inName1 + "."+ dateStr + "." + latbandStr + ".day.background.anom.nc"
	f1			= addfile(inFile1,"r")
	sh_anom		= f1->$vName$(iStrt:iLast,{latS:latN},{lonW:lonE})

	;------------- define bin sizes
	delta		= 1E07
	nbins		= 10
	bins		= fspan(-4.5E07,4.5E07,nbins)

	do s=0,1	; season loop

		;------------- define bin average arrays
		pct_ocn_bin			= new(nbins,float,default_fillvalue("float"))
		vadv_mean_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		hadv_mean_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		udmdx_mean_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		vdmdy_mean_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		lw_mean_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		sw_mean_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		lh_mean_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		sh_mean_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		vadv_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		hadv_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		udmdx_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		vdmdy_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		lw_anom_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		sw_anom_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		lh_anom_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		sh_anom_ocn_bin		= new(nbins,float,default_fillvalue("float"))
		wdLH_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		tdLH_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		wdSH_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))
		tdSH_anom_ocn_bin	= new(nbins,float,default_fillvalue("float"))

		pct_land_bin		= new(nbins,float,default_fillvalue("float"))
		vadv_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		hadv_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		udmdx_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		vdmdy_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		lw_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		sw_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		lh_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		sh_mean_land_bin	= new(nbins,float,default_fillvalue("float"))
		vadv_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		hadv_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		udmdx_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		vdmdy_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		lw_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		sw_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		lh_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		sh_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		wdLH_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		tdLH_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		wdSH_anom_land_bin	= new(nbins,float,default_fillvalue("float"))
		tdSH_anom_land_bin	= new(nbins,float,default_fillvalue("float"))

		;------------- mask land/ocean from all time series 
		mse_anom_ocn	= mask(mse_anom,lsm.ge.1,False)
		vadv_mean_ocn	= mask(vadv_mean,lsm.ge.1,False)
		hadv_mean_ocn	= mask(hadv_mean,lsm.ge.1,False)
		udmdx_mean_ocn	= mask(udmdx_mean,lsm.ge.1,False)
		vdmdy_mean_ocn	= mask(vdmdy_mean,lsm.ge.1,False)
		lw_mean_ocn		= mask(lw_mean,lsm.ge.1,False)
		sw_mean_ocn		= mask(sw_mean,lsm.ge.1,False)
		lh_mean_ocn		= mask(lh_mean,lsm.ge.1,False)
		sh_mean_ocn		= mask(sh_mean,lsm.ge.1,False)
		vadv_anom_ocn	= mask(vadv_anom,lsm.ge.1,False)
		hadv_anom_ocn	= mask(hadv_anom,lsm.ge.1,False)
		udmdx_anom_ocn	= mask(udmdx_anom,lsm.ge.1,False)
		vdmdy_anom_ocn	= mask(vdmdy_anom,lsm.ge.1,False)
		lw_anom_ocn		= mask(lw_anom,lsm.ge.1,False)
		sw_anom_ocn		= mask(sw_anom,lsm.ge.1,False)
		lh_anom_ocn		= mask(lh_anom,lsm.ge.1,False)
		sh_anom_ocn		= mask(sh_anom,lsm.ge.1,False)

		mse_anom_land	= mask(mse_anom,lsm.eq.0,False)
		vadv_mean_land	= mask(vadv_mean,lsm.eq.0,False)
		hadv_mean_land	= mask(hadv_mean,lsm.eq.0,False)
		udmdx_mean_land	= mask(udmdx_mean,lsm.eq.0,False)
		vdmdy_mean_land	= mask(vdmdy_mean,lsm.eq.0,False)
		lw_mean_land	= mask(lw_mean,lsm.eq.0,False)
		sw_mean_land	= mask(sw_mean,lsm.eq.0,False)
		lh_mean_land	= mask(lh_mean,lsm.eq.0,False)
		sh_mean_land	= mask(sh_mean,lsm.eq.0,False)
		vadv_anom_land	= mask(vadv_anom,lsm.eq.0,False)
		hadv_anom_land	= mask(hadv_anom,lsm.eq.0,False)
		udmdx_anom_land	= mask(udmdx_anom,lsm.eq.0,False)
		vdmdy_anom_land	= mask(vdmdy_anom,lsm.eq.0,False)
		lw_anom_land	= mask(lw_anom,lsm.eq.0,False)
		sw_anom_land	= mask(sw_anom,lsm.eq.0,False)
		lh_anom_land	= mask(lh_anom,lsm.eq.0,False)
		sh_anom_land	= mask(sh_anom,lsm.eq.0,False)

		;------------- mask out the "other" season
		if (s.eq.0) then 
			sMask	= m2o
		else
			sMask	= n2a
		end if
	
		mse_anom_ocn(sMask,:,:)		= mse_anom@_FillValue
		vadv_mean_ocn(sMask,:,:)	= vadv_mean@_FillValue
		hadv_mean_ocn(sMask,:,:)	= hadv_mean@_FillValue
		udmdx_mean_ocn(sMask,:,:)	= udmdx_mean@_FillValue
		vdmdy_mean_ocn(sMask,:,:)	= vdmdy_mean@_FillValue
		lw_mean_ocn(sMask,:,:)		= lw_mean@_FillValue
		sw_mean_ocn(sMask,:,:)		= sw_mean@_FillValue
		lh_mean_ocn(sMask,:,:)		= lh_mean@_FillValue
		sh_mean_ocn(sMask,:,:)		= sh_mean@_FillValue
		vadv_anom_ocn(sMask,:,:)	= vadv_anom@_FillValue
		hadv_anom_ocn(sMask,:,:)	= hadv_anom@_FillValue
		udmdx_anom_ocn(sMask,:,:)	= udmdx_anom@_FillValue
		vdmdy_anom_ocn(sMask,:,:)	= vdmdy_anom@_FillValue
		lw_anom_ocn(sMask,:,:)		= lw_anom@_FillValue
		sw_anom_ocn(sMask,:,:)		= sw_anom@_FillValue
		lh_anom_ocn(sMask,:,:)		= lh_anom@_FillValue
		sh_anom_ocn(sMask,:,:)		= sh_anom@_FillValue

		mse_anom_land(sMask,:,:)	= mse_anom@_FillValue
		vadv_mean_land(sMask,:,:)	= vadv_mean@_FillValue
		hadv_mean_land(sMask,:,:)	= hadv_mean@_FillValue
		udmdx_mean_land(sMask,:,:)	= udmdx_mean@_FillValue
		vdmdy_mean_land(sMask,:,:)	= vdmdy_mean@_FillValue
		lw_mean_land(sMask,:,:)		= lw_mean@_FillValue
		sw_mean_land(sMask,:,:)		= sw_mean@_FillValue
		lh_mean_land(sMask,:,:)		= lh_mean@_FillValue
		sh_mean_land(sMask,:,:)		= sh_mean@_FillValue
		vadv_anom_land(sMask,:,:)	= vadv_anom@_FillValue
		hadv_anom_land(sMask,:,:)	= hadv_anom@_FillValue
		udmdx_anom_land(sMask,:,:)	= udmdx_anom@_FillValue
		vdmdy_anom_land(sMask,:,:)	= vdmdy_anom@_FillValue
		lw_anom_land(sMask,:,:)		= lw_anom@_FillValue
		sw_anom_land(sMask,:,:)		= sw_anom@_FillValue
		lh_anom_land(sMask,:,:)		= lh_anom@_FillValue
		sh_anom_land(sMask,:,:)		= sh_anom@_FillValue
	
		;------------- convert to 1D arrays
		mse1d_anom_ocn		= ndtooned(mse_anom_ocn)
		vadv1d_mean_ocn		= ndtooned(vadv_mean_ocn)
		hadv1d_mean_ocn		= ndtooned(hadv_mean_ocn)
		udmdx1d_mean_ocn	= ndtooned(udmdx_mean_ocn)
		vdmdy1d_mean_ocn	= ndtooned(vdmdy_mean_ocn)
		lw1d_mean_ocn		= ndtooned(lw_mean_ocn)
		sw1d_mean_ocn		= ndtooned(sw_mean_ocn)
		lh1d_mean_ocn		= ndtooned(lh_mean_ocn)
		sh1d_mean_ocn		= ndtooned(sh_mean_ocn)
		vadv1d_anom_ocn		= ndtooned(vadv_anom_ocn)
		hadv1d_anom_ocn		= ndtooned(hadv_anom_ocn)
		udmdx1d_anom_ocn	= ndtooned(udmdx_anom_ocn)
		vdmdy1d_anom_ocn	= ndtooned(vdmdy_anom_ocn)
		lw1d_anom_ocn		= ndtooned(lw_anom_ocn)
		sw1d_anom_ocn		= ndtooned(sw_anom_ocn)
		lh1d_anom_ocn		= ndtooned(lh_anom_ocn)
		sh1d_anom_ocn		= ndtooned(sh_anom_ocn)

		mse1d_anom_land		= ndtooned(mse_anom_land)
		vadv1d_mean_land	= ndtooned(vadv_mean_land)
		hadv1d_mean_land	= ndtooned(hadv_mean_land)
		udmdx1d_mean_land	= ndtooned(udmdx_mean_land)
		vdmdy1d_mean_land	= ndtooned(vdmdy_mean_land)
		lw1d_mean_land		= ndtooned(lw_mean_land)
		sw1d_mean_land		= ndtooned(sw_mean_land)
		lh1d_mean_land		= ndtooned(lh_mean_land)
		sh1d_mean_land		= ndtooned(sh_mean_land)
		vadv1d_anom_land	= ndtooned(vadv_anom_land)
		hadv1d_anom_land	= ndtooned(hadv_anom_land)
		udmdx1d_anom_land	= ndtooned(udmdx_anom_land)
		vdmdy1d_anom_land	= ndtooned(vdmdy_anom_land)
		lw1d_anom_land		= ndtooned(lw_anom_land)
		sw1d_anom_land		= ndtooned(sw_anom_land)
		lh1d_anom_land		= ndtooned(lh_anom_land)
		sh1d_anom_land		= ndtooned(sh_anom_land)

		Nmse_ocn	= dimsizes(ind(.not.ismissing(mse1d_anom_ocn)))
		Nmse_land	= dimsizes(ind(.not.ismissing(mse1d_anom_land)))
		;print("Nmse_ocn = "+Nmse_ocn)
		;print("Nmse_land = "+Nmse_land)
	;	printVarSummary(lw1d_mean_ocn)
	;	printVarSummary(lw_mean_ocn_bin)
	;	printVarSummary(sw1d_mean_ocn)
	;	printVarSummary(sw_mean_ocn_bin)
		do b = 0,nbins-1
			;print("b = " + b)
			if (b.eq.0) then
				minval	= -1e50
			else
				minval	= bins(b) - delta/2.
			end if
		
			if (b.eq.nbins-1) then
				maxval	= 1e50
			else
				maxval	= bins(b) + delta/2.
			end if
		
			range		= ind(mse1d_anom_ocn.gt.minval.and.mse1d_anom_ocn.le.maxval)
			npts		= dimsizes(range)
			if (npts.ge.1) then
				pct_ocn_bin(b)	= 100. * int2flt(npts(0)) / int2flt(Nmse_ocn)
				vadv_mean_ocn_bin(b)	= avg(vadv1d_mean_ocn(range))
				hadv_mean_ocn_bin(b)	= avg(hadv1d_mean_ocn(range))
				udmdx_mean_ocn_bin(b)	= avg(udmdx1d_mean_ocn(range))
				vdmdy_mean_ocn_bin(b)	= avg(vdmdy1d_mean_ocn(range))
				lw_mean_ocn_bin(b)		= avg(lw1d_mean_ocn(range))
				sw_mean_ocn_bin(b)		= avg(sw1d_mean_ocn(range))
				lh_mean_ocn_bin(b)		= avg(lh1d_mean_ocn(range))
				sh_mean_ocn_bin(b)		= avg(sh1d_mean_ocn(range))
				vadv_anom_ocn_bin(b)	= avg(vadv1d_anom_ocn(range))
				hadv_anom_ocn_bin(b)	= avg(hadv1d_anom_ocn(range))
				udmdx_anom_ocn_bin(b)	= avg(udmdx1d_anom_ocn(range))
				vdmdy_anom_ocn_bin(b)	= avg(vdmdy1d_anom_ocn(range))
				lw_anom_ocn_bin(b)		= avg(lw1d_anom_ocn(range))
				sw_anom_ocn_bin(b)		= avg(sw1d_anom_ocn(range))
				lh_anom_ocn_bin(b)		= avg(lh1d_anom_ocn(range))
				sh_anom_ocn_bin(b)		= avg(sh1d_anom_ocn(range))
			end if
			delete(range)

			range		= ind(mse1d_anom_land.gt.minval.and.mse1d_anom_land.le.maxval)
			;printVarSummary(range)
			npts		= dimsizes(range)
			;print("npts = " + npts)
			if (npts.gt.1) then
				pct_land_bin(b)	= 100. * int2flt((/npts/)) / int2flt(Nmse_land)
				;pct_land_bin(b)	= 100. * int2flt(npts(0)) / int2flt(Nmse_land)
				vadv_mean_land_bin(b)	= avg(vadv1d_mean_land(range))
				hadv_mean_land_bin(b)	= avg(hadv1d_mean_land(range))
				udmdx_mean_land_bin(b)	= avg(udmdx1d_mean_land(range))
				vdmdy_mean_land_bin(b)	= avg(vdmdy1d_mean_land(range))
				lw_mean_land_bin(b)		= avg(lw1d_mean_land(range))
				sw_mean_land_bin(b)		= avg(sw1d_mean_land(range))
				lh_mean_land_bin(b)		= avg(lh1d_mean_land(range))
				sh_mean_land_bin(b)		= avg(sh1d_mean_land(range))
				vadv_anom_land_bin(b)	= avg(vadv1d_anom_land(range))
				hadv_anom_land_bin(b)	= avg(hadv1d_anom_land(range))
				udmdx_anom_land_bin(b)	= avg(udmdx1d_anom_land(range))
				vdmdy_anom_land_bin(b)	= avg(vdmdy1d_anom_land(range))
				lw_anom_land_bin(b)		= avg(lw1d_anom_land(range))
				sw_anom_land_bin(b)		= avg(sw1d_anom_land(range))
				lh_anom_land_bin(b)		= avg(lh1d_anom_land(range))
				sh_anom_land_bin(b)		= avg(sh1d_anom_land(range))
			end if
			delete(range)

		end do	; bin loop

		;------------- add metadata to variables
		bins@long_name					= "MSE anomaly"
		pct_ocn_bin!0					= "bins"
		pct_land_bin!0					= "bins"

		;------------- ocean points
		pct_ocn_bin&bins				= bins
		pct_ocn_bin@long_name			= "probability"
		pct_ocn_bin@units				= "%"
		pct_ocn_bin@_FillValue			= default_fillvalue(typeof(pct_ocn_bin))

		vadv_mean_ocn_bin!0				= "bins"
		vadv_mean_ocn_bin&bins			= bins
		vadv_mean_ocn_bin@long_name		= vadv_mean@long_name
		vadv_mean_ocn_bin@units			= vadv_mean@units
		vadv_mean_ocn_bin@_FillValue	= default_fillvalue(typeof(vadv_mean_ocn_bin))	

		hadv_mean_ocn_bin!0				= "bins"
		hadv_mean_ocn_bin&bins			= bins
		hadv_mean_ocn_bin@long_name		= hadv_mean@long_name
		hadv_mean_ocn_bin@units			= hadv_mean@units
		hadv_mean_ocn_bin@_FillValue	= default_fillvalue(typeof(hadv_mean_ocn_bin))	

		udmdx_mean_ocn_bin!0			= "bins"
		udmdx_mean_ocn_bin&bins			= bins
		udmdx_mean_ocn_bin@long_name	= udmdx_mean@long_name
		udmdx_mean_ocn_bin@units		= udmdx_mean@units
		udmdx_mean_ocn_bin@_FillValue	= default_fillvalue(typeof(udmdx_mean_ocn_bin))	

		vdmdy_mean_ocn_bin!0			= "bins"
		vdmdy_mean_ocn_bin&bins			= bins
		vdmdy_mean_ocn_bin@long_name	= vdmdy_mean@long_name
		vdmdy_mean_ocn_bin@units		= vdmdy_mean@units
		vdmdy_mean_ocn_bin@_FillValue	= default_fillvalue(typeof(vdmdy_mean_ocn_bin))	

		lw_mean_ocn_bin!0				= "bins"
		lw_mean_ocn_bin&bins			= bins
		lw_mean_ocn_bin@long_name		= lw_mean@long_name
		lw_mean_ocn_bin@units			= lw_mean@units
		lw_mean_ocn_bin@_FillValue		= default_fillvalue(typeof(lw_mean_ocn_bin))	

		sw_mean_ocn_bin!0				= "bins"
		sw_mean_ocn_bin&bins			= bins
		sw_mean_ocn_bin@long_name		= sw_mean@long_name
		sw_mean_ocn_bin@units			= sw_mean@units
		sw_mean_ocn_bin@_FillValue		= default_fillvalue(typeof(sw_mean_ocn_bin))	

		lh_mean_ocn_bin!0				= "bins"
		lh_mean_ocn_bin&bins			= bins
		lh_mean_ocn_bin@long_name		= lh_mean@long_name
		lh_mean_ocn_bin@units			= lh_mean@units
		lh_mean_ocn_bin@_FillValue		= default_fillvalue(typeof(lh_mean_ocn_bin))	

		sh_mean_ocn_bin!0				= "bins"
		sh_mean_ocn_bin&bins			= bins
		sh_mean_ocn_bin@long_name		= sh_mean@long_name
		sh_mean_ocn_bin@units			= sh_mean@units
		sh_mean_ocn_bin@_FillValue		= default_fillvalue(typeof(sh_mean_ocn_bin))	

		vadv_anom_ocn_bin!0				= "bins"
		vadv_anom_ocn_bin&bins			= bins
		vadv_anom_ocn_bin@long_name		= vadv_anom@long_name
		vadv_anom_ocn_bin@units			= vadv_anom@units
		vadv_anom_ocn_bin@_FillValue	= default_fillvalue(typeof(vadv_anom_ocn_bin))	

		hadv_anom_ocn_bin!0				= "bins"
		hadv_anom_ocn_bin&bins			= bins
		hadv_anom_ocn_bin@long_name		= hadv_anom@long_name
		hadv_anom_ocn_bin@units			= hadv_anom@units
		hadv_anom_ocn_bin@_FillValue	= default_fillvalue(typeof(hadv_anom_ocn_bin))	

		udmdx_anom_ocn_bin!0			= "bins"
		udmdx_anom_ocn_bin&bins			= bins
		udmdx_anom_ocn_bin@long_name	= udmdx_anom@long_name
		udmdx_anom_ocn_bin@units		= udmdx_anom@units
		udmdx_anom_ocn_bin@_FillValue	= default_fillvalue(typeof(udmdx_anom_ocn_bin))	

		vdmdy_anom_ocn_bin!0			= "bins"
		vdmdy_anom_ocn_bin&bins			= bins
		vdmdy_anom_ocn_bin@long_name	= vdmdy_anom@long_name
		vdmdy_anom_ocn_bin@units		= vdmdy_anom@units
		vdmdy_anom_ocn_bin@_FillValue	= default_fillvalue(typeof(vdmdy_anom_ocn_bin))	

		lw_anom_ocn_bin!0				= "bins"
		lw_anom_ocn_bin&bins			= bins
		lw_anom_ocn_bin@long_name		= lw_anom@long_name
		lw_anom_ocn_bin@units			= lw_anom@units
		lw_anom_ocn_bin@_FillValue		= default_fillvalue(typeof(lw_anom_ocn_bin))	

		sw_anom_ocn_bin!0				= "bins"
		sw_anom_ocn_bin&bins			= bins
		sw_anom_ocn_bin@long_name		= sw_anom@long_name
		sw_anom_ocn_bin@units			= sw_anom@units
		sw_anom_ocn_bin@_FillValue		= default_fillvalue(typeof(sw_anom_ocn_bin))	

		lh_anom_ocn_bin!0				= "bins"
		lh_anom_ocn_bin&bins			= bins
		lh_anom_ocn_bin@long_name		= lh_anom@long_name
		lh_anom_ocn_bin@units			= lh_anom@units
		lh_anom_ocn_bin@_FillValue		= default_fillvalue(typeof(lh_anom_ocn_bin))	

		sh_anom_ocn_bin!0				= "bins"
		sh_anom_ocn_bin&bins			= bins
		sh_anom_ocn_bin@long_name		= sh_anom@long_name
		sh_anom_ocn_bin@units			= sh_anom@units
		sh_anom_ocn_bin@_FillValue		= default_fillvalue(typeof(sh_anom_ocn_bin))	


		;------------- land points
		pct_land_bin&bins				= bins
		pct_land_bin@long_name			= "probability"
		pct_land_bin@units				= "%"
		pct_land_bin@_FillValue			= default_fillvalue(typeof(pct_land_bin))

		vadv_mean_land_bin!0			= "bins"
		vadv_mean_land_bin&bins			= bins
		vadv_mean_land_bin@long_name	= vadv_mean@long_name
		vadv_mean_land_bin@units		= vadv_mean@units
		vadv_mean_land_bin@_FillValue	= default_fillvalue(typeof(vadv_mean_land_bin))	

		hadv_mean_land_bin!0			= "bins"
		hadv_mean_land_bin&bins			= bins
		hadv_mean_land_bin@long_name	= hadv_mean@long_name
		hadv_mean_land_bin@units		= hadv_mean@units
		hadv_mean_land_bin@_FillValue	= default_fillvalue(typeof(hadv_mean_land_bin))	

		udmdx_mean_land_bin!0			= "bins"
		udmdx_mean_land_bin&bins		= bins
		udmdx_mean_land_bin@long_name	= udmdx_mean@long_name
		udmdx_mean_land_bin@units		= udmdx_mean@units
		udmdx_mean_land_bin@_FillValue	= default_fillvalue(typeof(udmdx_mean_land_bin))	

		vdmdy_mean_land_bin!0			= "bins"
		vdmdy_mean_land_bin&bins		= bins
		vdmdy_mean_land_bin@long_name	= vdmdy_mean@long_name
		vdmdy_mean_land_bin@units		= vdmdy_mean@units
		vdmdy_mean_land_bin@_FillValue	= default_fillvalue(typeof(vdmdy_mean_land_bin))	

		lw_mean_land_bin!0				= "bins"
		lw_mean_land_bin&bins			= bins
		lw_mean_land_bin@long_name		= lw_mean@long_name
		lw_mean_land_bin@units			= lw_mean@units
		lw_mean_land_bin@_FillValue		= default_fillvalue(typeof(lw_mean_land_bin))	

		sw_mean_land_bin!0				= "bins"
		sw_mean_land_bin&bins			= bins
		sw_mean_land_bin@long_name		= sw_mean@long_name
		sw_mean_land_bin@units			= sw_mean@units
		sw_mean_land_bin@_FillValue		= default_fillvalue(typeof(sw_mean_land_bin))	

		lh_mean_land_bin!0				= "bins"
		lh_mean_land_bin&bins			= bins
		lh_mean_land_bin@long_name		= lh_mean@long_name
		lh_mean_land_bin@units			= lh_mean@units
		lh_mean_land_bin@_FillValue		= default_fillvalue(typeof(lh_mean_land_bin))	

		sh_mean_land_bin!0				= "bins"
		sh_mean_land_bin&bins			= bins
		sh_mean_land_bin@long_name		= sh_mean@long_name
		sh_mean_land_bin@units			= sh_mean@units
		sh_mean_land_bin@_FillValue		= default_fillvalue(typeof(sh_mean_land_bin))	

		vadv_anom_land_bin!0			= "bins"
		vadv_anom_land_bin&bins			= bins
		vadv_anom_land_bin@long_name	= vadv_anom@long_name
		vadv_anom_land_bin@units		= vadv_anom@units
		vadv_anom_land_bin@_FillValue	= default_fillvalue(typeof(vadv_anom_land_bin))	

		hadv_anom_land_bin!0			= "bins"
		hadv_anom_land_bin&bins			= bins
		hadv_anom_land_bin@long_name	= hadv_anom@long_name
		hadv_anom_land_bin@units		= hadv_anom@units
		hadv_anom_land_bin@_FillValue	= default_fillvalue(typeof(hadv_anom_land_bin))	

		udmdx_anom_land_bin!0			= "bins"
		udmdx_anom_land_bin&bins		= bins
		udmdx_anom_land_bin@long_name	= udmdx_anom@long_name
		udmdx_anom_land_bin@units		= udmdx_anom@units
		udmdx_anom_land_bin@_FillValue	= default_fillvalue(typeof(udmdx_anom_land_bin))	

		vdmdy_anom_land_bin!0			= "bins"
		vdmdy_anom_land_bin&bins		= bins
		vdmdy_anom_land_bin@long_name	= vdmdy_anom@long_name
		vdmdy_anom_land_bin@units		= vdmdy_anom@units
		vdmdy_anom_land_bin@_FillValue	= default_fillvalue(typeof(vdmdy_anom_land_bin))	

		lw_anom_land_bin!0				= "bins"
		lw_anom_land_bin&bins			= bins
		lw_anom_land_bin@long_name		= lw_anom@long_name
		lw_anom_land_bin@units			= lw_anom@units
		lw_anom_land_bin@_FillValue		= default_fillvalue(typeof(lw_anom_land_bin))	

		sw_anom_land_bin!0				= "bins"
		sw_anom_land_bin&bins			= bins
		sw_anom_land_bin@long_name		= sw_anom@long_name
		sw_anom_land_bin@units			= sw_anom@units
		sw_anom_land_bin@_FillValue		= default_fillvalue(typeof(sw_anom_land_bin))	

		lh_anom_land_bin!0				= "bins"
		lh_anom_land_bin&bins			= bins
		lh_anom_land_bin@long_name		= lh_anom@long_name
		lh_anom_land_bin@units			= lh_anom@units
		lh_anom_land_bin@_FillValue		= default_fillvalue(typeof(lh_anom_land_bin))	

		sh_anom_land_bin!0				= "bins"
		sh_anom_land_bin&bins			= bins
		sh_anom_land_bin@long_name		= sh_anom@long_name
		sh_anom_land_bin@units			= sh_anom@units
		sh_anom_land_bin@_FillValue		= default_fillvalue(typeof(sh_anom_land_bin))	

		;------------- open file and write data
		filo	= diro + caseName + ".make_L3.2_MSE_PDF_lineplots." + "10S-10N.60E-160E." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		system("/bin/rm -f "+filo)
		ncdf	= addfile(filo,"c")
		;------------- ocean arrays
		ncdf->MSE_PDF_ocn			= pct_ocn_bin
		ncdf->Vomegadmdp_mean_ocn	= vadv_mean_ocn_bin
		ncdf->Vm_hadv_mean_ocn		= hadv_mean_ocn_bin
		ncdf->Vudmdx_mean_ocn		= udmdx_mean_ocn_bin
		ncdf->Vvdmdy_mean_ocn		= vdmdy_mean_ocn_bin
		ncdf->Vlw_mean_ocn			= lw_mean_ocn_bin
		ncdf->Vsw_mean_ocn			= sw_mean_ocn_bin
		ncdf->LHFLX_mean_ocn		= lh_mean_ocn_bin
		ncdf->SHFLX_mean_ocn		= sh_mean_ocn_bin
		ncdf->Vomegadmdp_anom_ocn	= vadv_anom_ocn_bin
		ncdf->Vm_hadv_anom_ocn		= hadv_anom_ocn_bin
		ncdf->Vudmdx_anom_ocn		= udmdx_anom_ocn_bin
		ncdf->Vvdmdy_anom_ocn		= vdmdy_anom_ocn_bin
		ncdf->Vlw_anom_ocn			= lw_anom_ocn_bin
		ncdf->Vsw_anom_ocn			= sw_anom_ocn_bin
		ncdf->LHFLX_anom_ocn		= lh_anom_ocn_bin
		ncdf->SHFLX_anom_ocn		= sh_anom_ocn_bin

		;------------- land arrays
		ncdf->MSE_PDF_land			= pct_land_bin
		ncdf->Vomegadmdp_mean_land	= vadv_mean_land_bin
		ncdf->Vm_hadv_mean_land		= hadv_mean_land_bin
		ncdf->Vudmdx_mean_land		= udmdx_mean_land_bin
		ncdf->Vvdmdy_mean_land		= vdmdy_mean_land_bin
		ncdf->Vlw_mean_land			= lw_mean_land_bin
		ncdf->Vsw_mean_land			= sw_mean_land_bin
		ncdf->LHFLX_mean_land		= lh_mean_land_bin
		ncdf->SHFLX_mean_land		= sh_mean_land_bin
		ncdf->Vomegadmdp_anom_land	= vadv_anom_land_bin
		ncdf->Vm_hadv_anom_land		= hadv_anom_land_bin
		ncdf->Vudmdx_anom_land		= udmdx_anom_land_bin
		ncdf->Vvdmdy_anom_land		= vdmdy_anom_land_bin
		ncdf->Vlw_anom_land			= lw_anom_land_bin
		ncdf->Vsw_anom_land			= sw_anom_land_bin
		ncdf->LHFLX_anom_land		= lh_anom_land_bin
		ncdf->SHFLX_anom_land		= sh_anom_land_bin

	
		delete(pct_ocn_bin)
		delete(vadv_mean_ocn_bin)
		delete(hadv_mean_ocn_bin)
		delete(udmdx_mean_ocn_bin)
		delete(vdmdy_mean_ocn_bin)
		delete(lw_mean_ocn_bin)
		delete(sw_mean_ocn_bin)
		delete(lh_mean_ocn_bin)
		delete(sh_mean_ocn_bin)
		delete(vadv_anom_ocn_bin)
		delete(hadv_anom_ocn_bin)
		delete(udmdx_anom_ocn_bin)
		delete(vdmdy_anom_ocn_bin)
		delete(lw_anom_ocn_bin)
		delete(sw_anom_ocn_bin)
		delete(lh_anom_ocn_bin)
		delete(sh_anom_ocn_bin)

		delete(pct_land_bin)
		delete(vadv_mean_land_bin)
		delete(hadv_mean_land_bin)
		delete(udmdx_mean_land_bin)
		delete(vdmdy_mean_land_bin)
		delete(lw_mean_land_bin)
		delete(sw_mean_land_bin)
		delete(lh_mean_land_bin)
		delete(sh_mean_land_bin)
		delete(vadv_anom_land_bin)
		delete(hadv_anom_land_bin)
		delete(udmdx_anom_land_bin)
		delete(vdmdy_anom_land_bin)
		delete(lw_anom_land_bin)
		delete(sw_anom_land_bin)
		delete(lh_anom_land_bin)
		delete(sh_anom_land_bin)
	
		delete(sMask)

	end do		; season loop

end













