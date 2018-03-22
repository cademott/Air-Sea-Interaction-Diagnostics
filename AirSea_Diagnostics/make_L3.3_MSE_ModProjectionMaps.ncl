load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin

  
	print("")
	print("============= in make_L3.3_MSE_ModProjectionMaps.ncl =============")   

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
	mseName		= getenv("mseName")
	dmdtName	= getenv("dmdtName")
	caseName	= getenv("caseName")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")
	timeName	= getenv("TIMEVAR")

	latSstr		= getenv("latSouth")
	latNstr		= getenv("latNorth")
	latS_globe	= stringtofloat(latSstr)
	latN_globe	= stringtofloat(latNstr)
	
	mseName		= "Vmse"
	dmdtName	= "Vdmdt"

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
	fili		= caseName + "." + mseName + "." + dateStr + "." + latbandStr + ".day.background.anom.nc"
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

	tName		= mseName + "_anom_sm"
	Vmse_full	= f->$tName$(iStrt:iLast,:,:)

	fili		= caseName + "." + dmdtName + "." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	tName		= dmdtName + "_anom_sm"
	Vdmdt_full	= f->$tName$(iStrt:iLast,:,:)

	fili		= caseName + ".comptotLH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	ctLH		= f->comptotLH_anom_sm(iStrt:iLast,:,:)

	fili		= caseName + ".comptotLH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	ctLH_smSST	= f->comptotLH_smSST_anom_sm(iStrt:iLast,:,:)

	fili		= caseName + ".comptotSH." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	ctSH		= f->comptotSH_anom_sm(iStrt:iLast,:,:)

	fili		= caseName + ".comptotSH_smSST." + dateStr + "." + latbandStr + ".day.background.anom.nc"
	f			= addfile(diri+fili,"r")
	ctSH_smSST	= f->comptotSH_smSST_anom_sm(iStrt:iLast,:,:)

	;--------------- compute SST effect time series
	LH_SSTeffect_full	= ctLH - ctLH_smSST
	copy_VarMeta(ctLH,LH_SSTeffect_full)
	LH_SSTeffect_full@long_name	= "LH SST effect"
	delete(ctLH)
	delete(ctLH_smSST)

	SH_SSTeffect_full	= ctSH - ctSH_smSST
	copy_VarMeta(ctSH,SH_SSTeffect_full)
	SH_SSTeffect_full@long_name	= "SH SST effect"
	delete(ctSH)
	delete(ctSH_smSST)

	;--------------- filter MSE, dMSE/dt data
	print("filtering mse, dmdt...")
	ihp      	= 2                             ; bpf=>band pass filter
	nWgt     	= 201
	sigma    	= 1.0                           ; Lanczos sigma
	fca      	= 1./100.
	fcb      	= 1./20.
	wgt      	= filwgts_lanczos (nWgt, ihp, fca, fcb, sigma )
	Vmse_full	= wgt_runave_leftdim( Vmse_full, wgt, 0 )
	Vdmdt_full	= wgt_runave_leftdim( Vdmdt_full, wgt, 0 )

	;--------------- apply land mask
	a    		= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
	lsdata		= a->LSMASK
	lsm			= landsea_mask(lsdata,Vmse_full&$latName$,Vmse_full&$lonName$)
	Vmse_full	= mask(Vmse_full,conform(Vmse_full,rm_single_dims(lsm),(/1,2/)).ge.1,False)
	Vdmdt_full	= mask(Vdmdt_full,conform(Vdmdt_full,rm_single_dims(lsm),(/1,2/)).ge.1,False)

	do s=0,1

		;--------------- mask out other season
		Vmse						= Vmse_full
		Vdmdt						= Vdmdt_full
		LH_SSTeffect				= LH_SSTeffect_full
		SH_SSTeffect				= SH_SSTeffect_full
		if (s.eq.0) then
			Vmse(m2o,:,:)			= Vmse@_FillValue
			Vdmdt(m2o,:,:)			= Vdmdt@_FillValue
			LH_SSTeffect(m2o,:,:)	= LH_SSTeffect_full@_FillValue
			SH_SSTeffect(m2o,:,:)	= SH_SSTeffect_full@_FillValue
		else
			Vmse(n2a,:,:)			= Vmse@_FillValue
			Vdmdt(n2a,:,:)			= Vdmdt@_FillValue
			LH_SSTeffect(n2a,:,:)	= LH_SSTeffect_full@_FillValue
			SH_SSTeffect(n2a,:,:)	= SH_SSTeffect_full@_FillValue
		end if		

		;--------------- compute mse, dmdt standard deviations for modified projections
		sd_mse		= dim_stddev_n_Wrap(Vmse,0)
		sd_dmdt		= dim_stddev_n_Wrap(Vdmdt,0)

		;---------------- compute the normalized projections
		print("computing normalized projections...")
		nprog_TOTmse	= dim_avg_n_Wrap((LH_SSTeffect+SH_SSTeffect) * Vmse,0) / sd_mse
		nprog_TOTdmdt	= dim_avg_n_Wrap((LH_SSTeffect+SH_SSTeffect) * Vdmdt,0) / sd_dmdt

		copy_VarCoords(sd_mse,nprog_TOTmse)
		copy_VarCoords(sd_dmdt,nprog_TOTdmdt)
		nprog_TOTmse@units	= "W/m**2"
		nprog_TOTdmdt@units	= "W/m**2"

		;-------------- compute difference of means test
		SSTmse			= (LH_SSTeffect + SH_SSTeffect) * Vmse / conform(Vmse,sd_mse,(/1,2/))
		copy_VarMeta(LH_SSTeffect,SSTmse)
		sd_SSTmse		= dim_stddev_n_Wrap(SSTmse,0)
		SSTdmdt			= (LH_SSTeffect + SH_SSTeffect) * Vdmdt / conform(Vdmdt,sd_mse,(/1,2/))
		copy_VarMeta(LH_SSTeffect,SSTdmdt)
		sd_SSTdmdt		= dim_stddev_n_Wrap(SSTdmdt,0)
		lag1			= esacr(SSTmse($latName$|:,$lonName$|:,$timeName$|:),1)
		lag1_SSTmse		= rm_single_dims(lag1(:,:,1))
		;printVarSummary(lag1_SSTmse)
		;printMinMax(lag1_SSTmse,True)
		dof_SSTmse		= round( 5000. * (1.-(lag1_SSTmse)^2.) / (1.+(lag1_SSTmse)^2.), 1 ) - 2.
		;printVarSummary(dof_SSTmse)
		lag1		= esacr(SSTdmdt($latName$|:,$lonName$|:,$timeName$|:),1)
		lag1_SSTdmdt	= rm_single_dims(lag1(:,:,1))
		;printVarSummary(lag1_SSTdmdt)
		;printMinMax(lag1_SSTdmdt,True)
		dof_SSTdmdt		= round( 5000. * (1.-(lag1_SSTdmdt)^2.) / (1.+(lag1_SSTdmdt)^2.), 1 ) - 2.

		SEpooled		= sqrt(sd_SSTmse^2./dof_SSTmse + sd_SSTdmdt^2./dof_SSTdmdt)
		dof				= SEpooled^2. / [ (sd_SSTmse^2./dof_SSTmse)^2./(dof_SSTmse) + (sd_SSTdmdt^2./dof_SSTdmdt)^2./(dof_SSTdmdt) ]
		tval_diff		= (nprog_TOTmse - nprog_TOTdmdt) / SEpooled
		sig_diff		= 1.-student_t(tval_diff,dof)
		copy_VarCoords(sd_SSTmse,sig_diff)
		sig_diff@long_name	= "probability of significance"
		sig_diff@units		= "p"
		;printMinMax(sig_diff,True)


		;------------ mask out areas where SST effect is greater for either MSE or dMSE/dt 
		;------------ (note:  we use "sig", but this is not really a significance test)
		sig_mse			= new ( dimsizes(nprog_TOTmse), "float" )
		sig_mse			= -1.		; initialize array
		copy_VarCoords(nprog_TOTmse,sig_mse)
		sig_mse1d		= ndtooned(sig_mse)
		TOTmse1d		= ndtooned(nprog_TOTmse)
		TOTdmdt1d		= ndtooned(nprog_TOTdmdt)
		sig				= ind(abs(TOTmse1d) .ge. abs(TOTdmdt1d))
		sig_mse1d(sig)	= 1.		; set to "1" for regions where nprog_mse > nprog_dmdt
		sig_mse			= onedtond(sig_mse1d,dimsizes(sig_mse))
		delete(sig)
		;printMinMax(sig_mse,True)

		sig_dmdt		= new ( dimsizes(nprog_TOTdmdt), "float" )
		sig_dmdt		= -1.		; initialize array
		copy_VarCoords(nprog_TOTdmdt,sig_dmdt)
		sig_dmdt1d		= ndtooned(sig_dmdt)
		sig				= ind(abs(TOTdmdt1d) .ge. abs(TOTmse1d))
		sig_dmdt1d(sig)	= 1.		; set to "1" for regions where nprog_dmdt > nprog_mse
		sig_dmdt		= onedtond(sig_dmdt1d,dimsizes(sig_dmdt))
		delete(sig)
		;printMinMax(sig_dmdt,True)
		sig_mse		= mask(sig_mse,lsm.ge.1,False)
		sig_dmdt	= mask(sig_dmdt,lsm.ge.1,False)


		filo			= caseName + ".make_L3.3_MSE_ModProjectionMaps." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		;print(diro+filo)
		system("/bin/rm -f "+diro+filo)      ; rm any pre-exist file, if any
		ncdf	= addfile(diro+filo,"c")
		tName			= "TOT_SSTeffect_mse_nprog"
		ncdf->$tName$	= nprog_TOTmse
		tName			= "TOT_SSTeffect_dmdt_nprog"
		ncdf->$tName$	= nprog_TOTdmdt
		tName			= "sig_mse"
		ncdf->$tName$	= sig_mse
		tName			= "sig_dmdt"
		ncdf->$tName$	= sig_dmdt
		tName			= "sig_diff"
		ncdf->$tName$	= sig_diff
		
		delete(Vmse)
		delete(Vdmdt)
		delete(LH_SSTeffect)
		delete(SH_SSTeffect)

	end do ; season loop

end

