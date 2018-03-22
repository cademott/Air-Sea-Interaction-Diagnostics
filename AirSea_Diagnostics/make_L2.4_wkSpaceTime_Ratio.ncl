load "./Resources/contrib_AirSea.ncl"

begin
  
	print("")
	print("============= in make_L2.4_wkSpaceTime_Ratio.ncl =============")   

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;----------- retrieve required environment variables
	diri		= getenv("FILEDIR")+"/proc/"
	diro		= getenv("FILEDIR")+"/proc/"
	caseName	= getenv("caseName")
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	lonName		= getenv("LONNAME")
	latName		= getenv("LATNAME")
	timeName	= getenv("TIMEVAR")
	varName		= getenv("inName1")

	;----------- read in spectra for full, smoothed SST fields
	fili1		= diri + caseName + "." + varName + "." + twStrt + "-" + twLast + ".wkSpaceTime.nc"
	fili2		= diri + caseName + "." + varName + "_smSST." + twStrt + "-" + twLast + ".wkSpaceTime.nc"
	;print("fili1 = " + fili1)
	;print("fili2 = " + fili2)


	f1			= addfile(fili1,"r")
	f2			= addfile(fili2,"r")
	
	s1_sym		= f1->FIG_1_SYM				; input data is log10(data)
	s1_asym		= f1->FIG_1_ASYM
	s2_sym		= f2->FIG_1_SYM
	s2_asym		= f2->FIG_1_ASYM

	;----------- calculate ratio
	ratio_sym	= 10.^s1_sym / 10.^s2_sym	; ratio of full SST to smoothed SST power
	ratio_asym	= 10.^s1_asym / 10.^s2_asym

	copy_VarMeta(s1_sym,ratio_sym)
	copy_VarMeta(s1_asym,ratio_asym)

	ratio_sym@long_name	= "Sym. " + varName + " full/smoothed power ratio"
	ratio_asym@long_name= "Asym. " + varName + " full/smoothed power ratio"

	;----------- write output to file
	filo				= diro + caseName + "." + varName + ".FullSmoothSST_ratio." + twStrt + "-" + twLast + ".wkSpaceTime.nc"
	system("/bin/rm -f "+filo)
	ncdf				= addfile(filo,"c")
	vNameOut			= varName + "_ratio_SYM"
	ncdf->$vNameOut$	= ratio_sym
	vNameOut			= varName + "_ratio_ASYM"
	ncdf->$vNameOut$	= ratio_asym

end
