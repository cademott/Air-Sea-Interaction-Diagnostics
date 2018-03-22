load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("")
	print("============== in make_L1.7_RH_byWindSST_PDF.ncl ==============")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- set dynamic variable names
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	sstName		= getenv("SSTVARNAME")
	diri		= getenv("FILEDIR") + "/"
	diro		= diri + "/proc/"
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

	;----------- define analysis domains (roughly DYNAMO and TOGA COARE)
	latS_DYN	= -5
	latN_DYN	= 5
	lonW_DYN	= 70
	lonE_DYN	= 80
	
	latS_TGC	= -10
	latN_TGC	= 0
	lonW_TGC	= 155
	lonE_TGC	= 165

	seasonName	= (/ "Nov-Apr","May-Oct" /)
	
	do s = 0,1 						; do for each season

		;---------- read in RH, SST, wind speed for DYNAMO, COARE domains
		print("read SST...")
		filsst	= diri + caseName + "." + sstName + "."+ dateStr + "." + latbandStr + ".day.mean.nc"
		f		= addfile(filsst,"r")
		date	= cd_calendar(f->$timeName$, -2)   ; entire file
		iStrt 	= ind(date.eq.twStrt)      ; desired dates
		iLast 	= ind(date.eq.twLast)
		delete(date)
		time	= f->$timeName$(iStrt:iLast)
		TIME    = cd_calendar(time, 0)    	; type float 
		year    = floattointeger( TIME(:,0) )
		month   = floattointeger( TIME(:,1) )
		day     = floattointeger( TIME(:,2) ) 
		if (s.eq.0) then
			season		= ind(month.ge.11.or.month.le.4)	; Nov-Apr
		else
			season		= ind(month.ge.5.and.month.le.10)	; May-Oct
		end if

		SST_DYN	= f->$sstName$(season,{latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN})
		SST_TGC	= f->$sstName$(season,{latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC})
		
		fili	= diri + caseName + ".SPD."+ dateStr +"." + latbandStr + ".day.mean.nc"
		f		= addfile(fili,"r")
		SPD_DYN	= f->SPD(season,{latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN})
		SPD_TGC	= f->SPD(season,{latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC})
		
		fili	= diri + caseName + ".RHsfc."+ dateStr +"." + latbandStr + ".day.mean.nc"
		f		= addfile(fili,"r")
		RH_DYN	= f->RHsfc(season,{latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN})
		RH_TGC	= f->RHsfc(season,{latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC})
		
		;printVarSummary(SST_DYN)
		;printVarSummary(SPD_DYN)
		;printVarSummary( RH_DYN)

		;---------- mask out land points (small islands OK)
		if (s.eq.0) then
			lon			= f->$lonName$
			lat			= f->$latName$			
			a    = addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
			lsdata=a->LSMASK
			lsm=landsea_mask(lsdata,lat,lon)
		end if
		SST_DYN1d	= ndtooned(mask(SST_DYN,conform(SST_DYN,lsm({latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN}),(/1,2/)).eq.1,False))
		SPD_DYN1d	= ndtooned(mask(SPD_DYN,conform(SPD_DYN,lsm({latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN}),(/1,2/)).eq.1,False))
		RH_DYN1d	= ndtooned(mask( RH_DYN,conform( RH_DYN,lsm({latS_DYN:latN_DYN},{lonW_DYN:lonE_DYN}),(/1,2/)).eq.1,False))
		SST_TGC1d	= ndtooned(mask(SST_TGC,conform(SST_TGC,lsm({latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC}),(/1,2/)).eq.1,False))
		SPD_TGC1d	= ndtooned(mask(SPD_TGC,conform(SPD_TGC,lsm({latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC}),(/1,2/)).eq.1,False))
		RH_TGC1d	= ndtooned(mask( RH_TGC,conform( RH_TGC,lsm({latS_TGC:latN_TGC},{lonW_TGC:lonE_TGC}),(/1,2/)).eq.1,False))
		;printVarSummary(RH_DYN1d)
		;printMinMax(RH_DYN1d,True)
		
		;---------- set SST to Celcius
		if (avg(SST_DYN1d).gt.200) then
			;print("*********** converting SST to Celcius")
			SST_DYN1d	= SST_DYN1d - 273.15
			SST_TGC1d	= SST_TGC1d - 273.15
		end if

		;---------- set up 2D histogram arrays
		;SST_bins	= fspan(26,32,13)
		SST_bins	= fspan(25,35,21)
		SPD_bins	= fspan(0,20,21)
		PDF_DYN		= new( (/dimsizes(SPD_bins)-1,dimsizes(SST_bins)-1/),"float" )
		meanRH_DYN	= new( (/dimsizes(SPD_bins)-1,dimsizes(SST_bins)-1/),"float" )
		PDF_TGC		= new( (/dimsizes(SPD_bins)-1,dimsizes(SST_bins)-1/),"float" )
		meanRH_TGC	= new( (/dimsizes(SPD_bins)-1,dimsizes(SST_bins)-1/),"float" )
		do i=0,dimsizes(SPD_bins)-2
			do j=0,dimsizes(SST_bins)-2
				; DYNAMO
				range			= ind(SPD_DYN1d.ge.SPD_bins(i).and.SPD_DYN1d.lt.SPD_bins(i+1).and.SST_DYN1d.ge.SST_bins(j).and.SST_DYN1d.lt.SST_bins(j+1))
				if (all(ismissing(range))) then
					PDF_DYN(i,j) 	= default_fillvalue("float")
					meanRH_DYN(i,j)	= default_fillvalue("float")
				else
					;print(dimsizes(range))
					;printMinMax(range,True)
					PDF_DYN(i,j)	= dimsizes(range)
					meanRH_DYN(i,j)	= avg(RH_DYN1d(range))
				end if
				delete(range)
				
				; TOGA COARE
				range			= ind(SPD_TGC1d.ge.SPD_bins(i).and.SPD_TGC1d.lt.SPD_bins(i+1).and.SST_TGC1d.ge.SST_bins(j).and.SST_TGC1d.lt.SST_bins(j+1))
				if (all(ismissing(range))) then
					PDF_TGC(i,j) 	= default_fillvalue("float")
					meanRH_TGC(i,j)	= default_fillvalue("float")
				else
					;print(dimsizes(range))
					;printMinMax(range,True)
					PDF_TGC(i,j)	= dimsizes(range)
					meanRH_TGC(i,j)	= avg(RH_TGC1d(range))
				end if
				delete(range)
			end do
		end do
		PDF_DYN	= 100.*PDF_DYN / sum(PDF_DYN)
		PDF_TGC	= 100.*PDF_TGC / sum(PDF_TGC)
		print("minPDF_DYN= " + min(PDF_DYN) +"   maxPDF_DYN = " + max(PDF_DYN))
		print("minPDF_TGC= " + min(PDF_TGC) +"   maxPDF_TGC = " + max(PDF_TGC))
		print("minRH_DYN= " + min(meanRH_DYN) +"   maxRH_DYN = " + max(meanRH_DYN))
		print("minRH_TGC= " + min(meanRH_TGC) +"   maxRH_TGC = " + max(meanRH_TGC))
		
		;---------- add meta data to PDF arrays
		PDF_DYN@long_name		= "DYNAMO SST-wind speed PDF"
		PDF_DYN!0				= "wind_speed"
		PDF_DYN&wind_speed		= 0.5*(SPD_bins(1:dimsizes(SPD_bins)-1) + SPD_bins(0:dimsizes(SPD_bins)-2))
		PDF_DYN&wind_speed@units= "m/s"
		PDF_DYN!1				= "SST"
		PDF_DYN&SST				= 0.5*(SST_bins(1:dimsizes(SST_bins)-1) + SST_bins(0:dimsizes(SST_bins)-2))
		PDF_DYN&SST@units		= "deg C"
		PDF_DYN@lon_west		= lonW_DYN
		PDF_DYN@lon_east		= lonE_DYN
		PDF_DYN@lat_south		= latS_DYN
		PDF_DYN@lat_north		= latN_DYN
		meanRH_DYN@long_name	= "DYNAMO SST-wind speed mean RH"
		meanRH_DYN!0			= "wind_speed"
		meanRH_DYN&wind_speed	= 0.5*(SPD_bins(1:dimsizes(SPD_bins)-1) + SPD_bins(0:dimsizes(SPD_bins)-2))
		meanRH_DYN&wind_speed@units= "m/s"
		meanRH_DYN!1			= "SST"
		meanRH_DYN&SST			= 0.5*(SST_bins(1:dimsizes(SST_bins)-1) + SST_bins(0:dimsizes(SST_bins)-2))
		meanRH_DYN&SST@units	= "deg C"
		meanRH_DYN@lon_west		= lonW_DYN
		meanRH_DYN@lon_east		= lonE_DYN
		meanRH_DYN@lat_south	= latS_DYN
		meanRH_DYN@lat_north	= latN_DYN
		PDF_TGC@long_name		= "TOGA COARE SST-wind speed PDF"
		PDF_TGC!0				= "wind_speed"
		PDF_TGC&wind_speed		= 0.5*(SPD_bins(1:dimsizes(SPD_bins)-1) + SPD_bins(0:dimsizes(SPD_bins)-2))
		PDF_TGC&wind_speed@units= "m/s"
		PDF_TGC!1				= "SST"
		PDF_TGC&SST				= 0.5*(SST_bins(1:dimsizes(SST_bins)-1) + SST_bins(0:dimsizes(SST_bins)-2))
		PDF_TGC&SST@units		= "deg C"
		PDF_TGC@lon_west		= lonW_TGC
		PDF_TGC@lon_east		= lonE_TGC
		PDF_TGC@lat_south		= latS_TGC
		PDF_TGC@lat_north		= latN_TGC
		meanRH_TGC@long_name	= "TOGA COARE SST-wind speed mean RH"
		meanRH_TGC!0			= "wind_speed"
		meanRH_TGC&wind_speed	= 0.5*(SPD_bins(1:dimsizes(SPD_bins)-1) + SPD_bins(0:dimsizes(SPD_bins)-2))
		meanRH_TGC&wind_speed@units= "m/s"
		meanRH_TGC!1			= "SST"
		meanRH_TGC&SST			= 0.5*(SST_bins(1:dimsizes(SST_bins)-1) + SST_bins(0:dimsizes(SST_bins)-2))
		meanRH_TGC&SST@units	= "deg C"
		meanRH_TGC@lon_west		= lonW_TGC
		meanRH_TGC@lon_east		= lonE_TGC
		meanRH_TGC@lat_south	= latS_TGC
		meanRH_TGC@lat_north	= latN_TGC
		
		;----------- create the output file
		filo		= diro + caseName + ".make_L1.7_RH_byWindSST_PDF." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		;filo		= diro + case + ".FIG05." + nameSeason(s) + "." + twStrt + "-" + twLast + ".RH_by_SST_SPD.nc"
		system("/bin/rm -f "+filo)      ; rm any pre-exist file, if any
		ncdf	= addfile(filo,"c")
		xName	= "PDF_DYN"
		ncdf->$xName$	= PDF_DYN
		xName	= "meanRH_DYN"
		ncdf->$xName$	= meanRH_DYN
		xName	= "PDF_TGC"
		ncdf->$xName$	= PDF_TGC
		xName	= "meanRH_TGC"
		ncdf->$xName$	= meanRH_TGC

		delete(season)
		delete(SST_DYN)
		delete(SPD_DYN)
		delete(RH_DYN)
		delete(SST_DYN1d)
		delete(SPD_DYN1d)
		delete(RH_DYN1d)
		delete(SST_TGC)
		delete(SPD_TGC)
		delete(RH_TGC)
		delete(SST_TGC1d)
		delete(SPD_TGC1d)
		delete(RH_TGC1d)

	end do ; season loop		

end
	





