load "./Resources/contrib_AirSea.ncl"

begin
  
	print("")
	print("============= in plot_L2.4_SSTEffect_MSE_LH_lags.ncl =============")  

	;---------- read in environmental variables
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
	lonW		= getenv("LONWEST")
	lonE		= getenv("LONEAST")

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	

	;------------- define seasons
	seasonName	= (/"Nov-Apr","May-Oct"/)

	;------------- filename prefix
	progGen		= ".make_L2.2_regression_nopropagation."

	do s=0,1 
		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L2.4_SSTEffect_MSE_LH_lags_10S-10N_" + lonW + "E-" + lonE + "E." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(4,graphic)					; create a plot array

		if (pType.eq."png") then
			thk		= 8.0
		else
			thk		= 2.0
		end if
		if (pType.eq."png") then
			rthick					= 2.0
		else
			rthick					= 0.5
		end if
		res							= True 				; plot mods desired
		res@gsnDraw					= False				; don't draw
		res@gsnFrame				= False				; don't advance frame
		res@gsnXRefLine            = 0.
		res@gsnXRefLineColor       = "grey37"
		res@gsnXRefLineDashPattern = 0
		res@gsnXRefLineThicknessF  	= rthick
		res@gsnLeftStringFontHeightF= 0.04
		res@gsnYRefLine            	= 0.
		res@gsnYRefLineColor       	= "grey37"
		res@gsnYRefLineDashPattern 	= 0
		res@gsnYRefLineThicknessF  	= rthick
		res@tiYAxisString			= "W m~S2~-2"			; y axis title
		res@trYMinF					= -15
		res@trYMaxF					= 15
		res@trXMinF					= -30
		res@trXMaxF					= 30
		res@vpHeightF				= 0.5
		res@vpWidthF				= 1.0
		res@tiXAxisString			= " "		; x axis title

		;------------- read in composite surface variables from "nopropagation" files 
		inName1		= "wdLH"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".Vmse." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		wdLH			= f1->$inName1$(:,{lonW:lonE})

		inName1		= "tdLH"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".Vmse." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		tdLH		= f1->$inName1$(:,{lonW:lonE})

		inName1		= "tdLH_smSST"
		inFile1		= diri + caseName + progGen + twStrt + "-" + twLast + ".Vmse." + inName1 + "."+ seasonName(s) + ".nc"
		f1			= addfile(inFile1,"r")
		tdLH_smSST	= f1->$inName1$(:,{lonW:lonE})

		rainsd		= f1->gridp_stdev({lonW:lonE})
		lag			= f1->lag
	
		ctLH		= wdLH + tdLH
		copy_VarMeta(wdLH,ctLH)
		ctLH_smSST	= wdLH + tdLH_smSST
		copy_VarMeta(wdLH,ctLH_smSST)
	
		;------------- set up plot array
		factor				= 5 * 6E+06
		data_all 			= new((/5,dimsizes(lag)/),"float")
		data_all(0,:)		= factor*dim_avg_n_Wrap(wdLH,1)
		data_all(1,:)		= factor*dim_avg_n_Wrap(tdLH,1)
		data_all(2,:)		= factor*dim_avg_n_Wrap(tdLH_smSST,1)
		data_all(3,:)		= factor*dim_avg_n_Wrap(ctLH,1)
		data_all(4,:)		= factor*dim_avg_n_Wrap(ctLH_smSST,1)

		;------------- plot first panel (flux components)
		p1					= data_all(0:2,:)
		p1@long_name		= caseName + " " + seasonName(s) + " LH flux component sum"
		data_all@units		= "W m~S2~-2"
		res@gsnLeftString	= caseName + " " + seasonName(s) + " LH flux components"
		res@xyLineColors    = (/"red",		"blue",		"blue",		"magenta","magenta"/)  ; line colors
		res@xyLineThicknesses= (/thk, 			thk, 		thk, 			thk, 	thk /)        ; line thicknesses
		res@xyDashPatterns  = (/0.0, 			0.0, 		1.0, 			0.0, 	1.0 /)        ; line patterns
		plot(0)				= gsn_csm_xy(wks,lag,p1,res)
		delete(res@xyLineColors)
		delete(res@xyLineThicknesses)
		delete(res@xyDashPatterns)

		;------------- plot first panel (component total)
		p2						= data_all((/3,4/),:)
		p2@long_name			= caseName + " " + seasonName(s) + ":  combined flux" ; title
		res@xyLineColors      	= (/"darkorchid2","darkorchid2"/)  ; line colors
		res@xyLineThicknesses 	= (/ thk, 	thk /)        ; line thicknesses
		res@xyDashPatterns    	= (/ 0.0, 	1.0 /)        ; line patterns
		res@tiXAxisString		= "lag about max MSE (day)"		; x axis title
		res@gsnLeftString		= caseName + " " + seasonName(s) + " LH flux component sum"
		plot(2)					= gsn_csm_xy(wks,lag,p2,res)
		delete(res@xyLineColors)
		delete(res@xyLineThicknesses)
		delete(res@xyDashPatterns)

		;------------- create plot page
		resP					= True                   ; modify the panel plot
		resP@gsnFrame			= False                  ; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  ; add common colorbar
		resP@gsnPanelBottom		= 0.1                   ; add space at bottom
		resP@gsnPanelFigureStrings = (/ "a","b","b","a" /)      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

		;------------- create panel 1 legend
		wdLHstr					= " (" + label(ind(vName.eq."wdLH")) + ")"
		tdLHstr					= " (" + label(ind(vName.eq."tdLH")) + ") ~H-5~~B3~SST~H-45~~V32~~F21~__"
		tdLH_smSSTstr			= " (" + label(ind(vName.eq."tdLH")) + ") ~H-5~~B3~SST~H-42~~V32~~F21~__~H10~~V-16~~F21~__"
		labels1					= (/ wdLHstr,tdLHstr,tdLH_smSSTstr /)
		labels1					= labels1(::-1)
		colors1					= (/"red","blue","blue"/)
		colors1					= colors1(::-1)
		dashes1					= (/ 0.0, 0.0, 1.0 /)
		dashes1					= dashes1(::-1)
		lgres					= True
		lgres@vpWidthF			= 0.14
		lgres@vpHeightF			= 0.09
		lgres@lgLabelFontHeightF	= 0.07
		lgres@lgPerimOn			= False
		lgres@lgMonoLineColor	= False
		lgres@lgLineColors		= colors1
		lgres@lgDashIndexes		= dashes1
		lgres@lgLineThicknessF	= thk
		gsn_legend_ndc(wks,3,labels1,0.34,0.69,lgres)
		delete(lgres@lgLineColors)
		delete(lgres@lgDashIndexes)

		;------------- create panel 2 legend
		lhstar_fullSST	= "~F21~ LH*~H-5~~B3~SST"
		lhstar_smSST	= "~F21~ LH*~H-5~~B3~SST~H1~~V14~~F21~__"
		labels2					= (/ " ",lhstar_fullSST,lhstar_smSST /)
		labels2					= labels2(::-1)
		colors2					= (/"white","darkorchid2","darkorchid2"/)
		colors2					= colors2(::-1)
		dashes2					= (/ 0.0, 1.0 /)
		dashes2					= dashes2(::-1)
		lgres@lgLineColors		= colors2
		lgres@lgDashIndexes		= dashes2
		lgres@vpWidthF			= 0.09
		gsn_legend_ndc(wks,3,labels2,0.38,0.392,lgres)

		;------------- clean up
		delete(colors2)
		delete(dashes2)
		delete(labels2)
		delete(lgres@lgLineColors)
		delete(lgres@lgDashIndexes)

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if


	end do		; season loop

end
