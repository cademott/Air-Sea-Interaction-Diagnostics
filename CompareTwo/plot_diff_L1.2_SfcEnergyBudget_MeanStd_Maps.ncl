load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_diff_L1.2_SfcEnergyBudget_MeanStd_Maps.ncl =================")
	
	
	progGenU850		= ".make_L1.3a_mean_u850."
	progGenVar	 	= ".make_L1.4_mean_stdev_map."

	;------------- set dynamic variable names
	debug			= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	figcap			= getenv("FIGCAP")
	CTRLNAME		= getenv("CTRLCASE")
	CTRLDIR			= getenv("CTRLDIR")
	EXPNAME			= getenv("EXPCASE")
	EXPDIR			= getenv("EXPDIR")
	dirp			= getenv("PLOTDIR")
	pType			= getenv("PTYPE")
	u850_overlay	= getenv("u850_overlay")	
	diri			= EXPDIR + "proc/" + EXPNAME + "_minus_" + CTRLNAME + "/" 
	print("dirp = " + dirp)
	
	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- note:  input variables and metadata for plotting
		;					routines use standard naming conventions
	varName		= (/ "Qnet", 						"SWsfc", 					"LHFLX", 					"SHFLX",						"LWsfc" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName_label	= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	;----------- read in the contour intervals for mean fields
	metafile			= "./CompareMultiple/contours_Season_DiffMean_Maps.txt"
	vName_ciMean		= systemfunc("cut -d , -f1 "+metafile)
	cnMin_ciMean		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax_ciMean		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt_ciMean		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	landmask			= str_left_strip(systemfunc("cut -d , -f5 "+metafile))

	;----------- read in the contour intervals for stdev fields
	metafile			= "./CompareMultiple/contours_Season_DiffStDev_Maps.txt"
	vName_ciStDev		= systemfunc("cut -d , -f1 "+metafile)
	cnMin_ciStDev		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax_ciStDev		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt_ciStDev		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	
	;------------- plot resources for base plot
	resS                     	= True
	resS@gsnDraw 				= False			; don't draw
	resS@gsnFrame				= False			; don't advance frame
	resS@cnInfoLabelOn			= False 		; turn off cn info label
	resS@cnFillOn				= True			; turn on color
	resS@cnLinesOn				= True			; turn off contour lines
	resS@cnLineColor			= "grey60"
	resS@tmXBLabelsOn			= False
	resS@lbOrientation			= "Vertical"	; vertical label bar
	resS@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resS@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	resS@mpMinLatF				= -30.
	resS@mpMaxLatF				=  30.
	resS@mpMinLonF 				=  30.
	resS@mpMaxLonF				= 240.
	resS@mpCenterLonF			= 135. 
	resS@cnLevelSelectionMode	= "ManualLevels"
	resS@gsnContourZeroLineThicknessF	= 0
	resS@cnFillPalette			= "BlueWhiteOrangeRed"
	resS@cnFillColors			= tointeger(fspan(20,234,12))
	
	;------------- plot resources for u850 overlay plot
	resC                     	= True
	resC@gsnDraw				= False
	resC@gsnFrame				= False
	resC@cnFillOn				= False			; turn off color
	resC@cnLinesOn				= True			; turn on contour lines
	resC@cnLineColor			= "Black"
	if (pType.eq."png") then
		resC@cnLineThicknessF	= 6
	else
		resC@cnLineThicknessF	= 2
	end if
	resC@cnInfoLabelOn			= False
	resC@cnLevels				= (/ -4., -2., 2., 4. /)
	resC@cnLevelSelectionMode	= "ExplicitLevels"   
	resC@tiXAxisOn				= False
	resC@tiYAxisOn				= False
	resC@tiMainOn				= False
	resC@gsnContourNegLineDashPattern = 1

	do s = 0,1 				; do for each season
		
		;----------- set up plot file -- CTRL MINUS EXPERIMENT
		wksType = pType
		wksName	= dirp + EXPNAME + "_minus_" + CTRLNAME + ".plot_diff_L1.2_SfcEnergyBudget_MeanStd_Maps." + seasonName(s)
		;print("wksName = " + wksName)
		
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		plot = new(10,graphic)                 	

		;----------- read in seasonal mean u850 wind
		fili	= diri + EXPNAME + "_minus_" + CTRLNAME + progGenU850  + "u850_SeasonMean." + seasonName(s) + ".nc"
		f		= addfile(fili,"r")
		ubar	= f->u850_SeasonMean
		ubar@long_name	= " "
		ubar@units		= " "
				
		do v = 0,4			; do for each variable
					
			;-------------read in the data -- created with CDO
			fili_prefix 	= diri + EXPNAME + "_minus_" + CTRLNAME + progGenVar
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName(v) + fili_suffix

			f				= addfile(fili,"r")
			tName			= varName(v) + "_mean"
			data_mean		= f->$tName$
			tName			= varName(v) + "_stdev"
			data_stdev		= f->$tName$

			;------------ define land mask
			if (s.eq.0.and.v.eq.0) then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
			end if

			;------------ mask fluxes, SST
			if (v.ge.2) then
				data_mean	= mask(data_mean,lsm.ge.1,False)
				data_stdev	= mask(data_stdev,lsm.ge.1,False)
			end if
			
			;------------ turn on longitude labels for bottom panels
			if (v.eq.4) then
				resS@tmXBLabelsOn			= True
			end if

			;------------ make panel plots
			resS@cnMinLevelValF		= cnMin_ciMean(ind(vName_ciMean.eq.varName(v)))
			resS@cnMaxLevelValF		= cnMax_ciMean(ind(vName_ciMean.eq.varName(v)))
			resS@cnLevelSpacingF	= cnInt_ciMean(ind(vName_ciMean.eq.varName(v))) 
			data_mean@long_name		= label(ind(vName_label.eq.varName(v)))  
			data_mean@units			= units(ind(vName_label.eq.varName(v))) 
			plot1					= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_mean, 0.50, 0.25, True),resS)

			;------------ reset color table anomaly fields
			resS@cnMinLevelValF		= cnMin_ciStDev(ind(vName_ciStDev.eq.varName(v)))
			resS@cnMaxLevelValF		= cnMax_ciStDev(ind(vName_ciStDev.eq.varName(v)))
			resS@cnLevelSpacingF	= cnInt_ciStDev(ind(vName_ciStDev.eq.varName(v))) 
			data_stdev@long_name	= label(ind(vName_label.eq.varName(v)))
			data_stdev@units		= units(ind(vName_label.eq.varName(v)))
			plot2					= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_stdev, 0.50, 0.25, True),resS)
		
			;;----------- create the overlay plot
			uplot1	= gsn_csm_contour(wks,smth9_Wrap(ubar, 0.50, 0.25, True),resC)
			uplot2	= gsn_csm_contour(wks,smth9_Wrap(ubar, 0.50, 0.25, True),resC)
			if (u850_overlay.eq."true") then
				overlay(plot1,uplot1)
			end if
			plot(v*2)	= plot1

			if (u850_overlay.eq."true") then
				overlay(plot2,uplot2)
			end if
			plot(v*2+1)	= plot2
			
			delete(plot1)
			delete(plot2)
			delete(uplot1)
			delete(uplot2)
			
			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		print("nPanels = "+nPanels)
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		;print(pID)
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= EXPNAME + " - " + CTRLNAME + "," + " "+ seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)                	; now draw as one plot
		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		gsn_text_ndc(wks,"mean",0.23,0.855,txres) 
		gsn_text_ndc(wks,"~F33~s ~F21~(20-100 day filtered)",0.73,0.855,txres) 
		if (figcap.eq."true") then
			gsn_text_ndc(wks,"[positive (negative) flux warms(cools) the ocean]",0.5,0.09,txres) 
			if (u850_overlay.eq."true") then
				gsn_text_ndc(wks,"overlay:  u850 [c.i. = every 2 m/s; negative dashed, zero omitted]",0.5,0.07,txres) 
			end if
		end if

		resS@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do				; season loop

end