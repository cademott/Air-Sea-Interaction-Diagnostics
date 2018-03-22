load "./Resources/contrib_AirSea.ncl"

begin
  
	print("")
	print("============= in plot_L2.3_SfcEnergy_lags.ncl =============")   

	;----------- retrieve required environment variables
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap		= getenv("FIGCAP")
	pType		= getenv("PTYPE")
	diri		= getenv("FILEDIR")+"/proc/"
	dirp		= getenv("FILEDIR")+"/plots/"
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

	;------------- define seasons
	seasonName	= (/"Nov-Apr","May-Oct"/)

	;------------- filename prefix
	progGen		= ".make_L2.2_regression_nopropagation."

	do s=0,1 
		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L2.3_SfcEnergy_lags." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(1,graphic)					; create a plot array

		;------------ flux line resources
		res							= True 				; plot mods desired
		res@gsnDraw					= False				; don't draw
		res@gsnFrame				= False				; don't advance frame
		res@tiXAxisString			= "lag (day)"		; x axis title
		;									lh   	 	sh     				sw    	 lw      qnet   zero   sst   
		res@xyLineColors      		= (/"chartreuse4","darkolivegreen2","coral2","magenta","black","black","blue"/)  ; line colors
		if (pType.eq."png") then
			thk		= 8.0
		else
			thk		= 2.0
		end if
		res@xyLineThicknesses		= (/thk, thk, thk, thk, thk, thk, thk, thk /)        ; line thicknesses
		res@xyDashPatterns    		= (/0.0, 0.0, 0.0, 0.0, 0,0, 0,0, 0.0, 0.0 /)        ; line patterns
		res@gsnXRefLine       		= 0.
		if (pType.eq."png") then
			rthick					= 2.0
		else
			rthick					= 0.5
		end if
		res@gsnXRefLineColor       	= "grey37"
		res@gsnXRefLineDashPattern 	= 0
		res@gsnXRefLineThicknessF  	= rthick
		res@gsnYRefLine            	= 0.
		res@gsnYRefLineColor       	= "grey37"
		res@gsnYRefLineDashPattern 	= 0
		res@gsnYRefLineThicknessF  	= rthick


		;------------ SST line resources
		resR                        = True                      
		resR@trYMinF				= -0.25
		resR@trYMaxF				= 0.25
		resR@xyLineThicknesses      = thk                   ; thicker line
		resR@tiYAxisString 			= "K"   ; axis string
		resR@xyLineColors			= "blue"

		;------------- read in composite surface variables from "nopropagation" files 
		inName1		= "LHFLX"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		lh			= f1->$inName1$(:,{80:90})

		inName1		= "SHFLX"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		sh			= f1->$inName1$(:,{80:90})

		inName1		= "LWsfc"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		lw			= f1->$inName1$(:,{80:90})

		inName1		= "SWsfc"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		sw			= f1->$inName1$(:,{80:90})

		inName1		= "Qnet"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		qnet		= f1->$inName1$(:,{80:90})

		inName1		= "SST"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		sst			= f1->$inName1$(:,{80:90})
		rainsd		= f1->gridp_stdev({80:90})
		lag			= f1->lag
	
	
		zeros			= new(61,"integer",0)
		data_all 		= new((/6,dimsizes(lag)/),"float")
		;data_all(0,:)	= -2*dim_avg_n_Wrap(lh*conform_dims(dimsizes(lh),rainsd,1),1)
		;data_all(1,:)	= -2*dim_avg_n_Wrap(sh*conform_dims(dimsizes(lh),rainsd,1),1)
		;data_all(2,:)	=  2*dim_avg_n_Wrap(sw*conform_dims(dimsizes(lh),rainsd,1),1)
		;data_all(3,:)	= -2*dim_avg_n_Wrap(lw*conform_dims(dimsizes(lh),rainsd,1),1)
		;data_all(4,:)	=  2*dim_avg_n_Wrap(qnet*conform_dims(dimsizes(lh),rainsd,1),1)
		;data_all(5,:)	=  zeros
		;sst_lag		 	=  2*dim_avg_n_Wrap(sst*conform_dims(dimsizes(lh),rainsd,1),1)
		data_all(0,:)	= -3*dim_avg_n_Wrap(lh,1)
		data_all(1,:)	= -3*dim_avg_n_Wrap(sh,1)
		data_all(2,:)	=  3*dim_avg_n_Wrap(sw,1)
		data_all(3,:)	= -3*dim_avg_n_Wrap(lw,1)
		data_all(4,:)	=  3*dim_avg_n_Wrap(qnet,1)
		data_all(5,:)	=  zeros
		sst_lag		 	=  3*dim_avg_n_Wrap(sst,1)
		res@tiMainString	= "Surface Energy Budget" ; title
		res@tiYAxisString	= "W m~S2~-2"			; y axis title
		res@trYMinF			= -40
		res@trYMaxF			= 40
		res@trXMinF			= -30
		res@trXMaxF			= 30
		plot(0) = gsn_csm_xy2(wks,lag,data_all,sst_lag,res,resR)          ; Draw an XY plot with 1 curve.
		delete(data_all)

		;------------- create plot page
		resP					= True                   ; modify the panel plot
		resP@gsnFrame			= False                  ; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  ; add common colorbar
		resP@txString			= caseName+" "+seasonName(s)	       ; add common title
		resP@gsnPanelBottom		= 0.1                   ; add space at bottom
		gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

		labels					= (/ "LH","SH","SW" /)
		labels					= labels(::-1)
		colors					= (/"chartreuse4","darkolivegreen2","coral2"/)
		colors					= colors(::-1)
		dashes					= (/ 0.0, 0.0, 0.0, 0.0 /)
		lgres					= True
		lgres@vpWidthF			= 0.1
		lgres@vpHeightF			= 0.07
		lgres@lgPerimOn			= False
		lgres@lgMonoLineColor	= False
		lgres@lgLineColors		= colors
		lgres@lgDashIndexes		= dashes 
		lgres@lgLineThicknessF	= thk
		gsn_legend_ndc(wks,3,labels,0.34,0.655,lgres)

		labels					= (/ "LW","Qnet","SST" /)
		labels					= labels(::-1)
		colors					= (/"magenta","black","blue"/)
		colors					= colors(::-1)
		lgres					= True
		lgres@vpWidthF			= 0.1
		lgres@vpHeightF			= 0.07
		lgres@lgPerimOn			= False
		lgres@lgMonoLineColor	= False
		lgres@lgLineColors		= colors
		lgres@lgDashIndexes		= dashes 
		lgres@lgLineThicknessF	= thk
		gsn_legend_ndc(wks,3,labels,0.55,0.655,lgres)

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do		; season loop

end













