load "./Resources/contrib_AirSea.ncl"

begin
	print("")
	print("=============== in plot_L2.1_MSEbudget_propagation.ncl =================")

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
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")
	diri		= getenv("FILEDIR") + "/proc/"
	dirp		= getenv("FILEDIR") + "/plots/"
	caseName	= getenv("caseName")

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

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- define variables to plot
	varName		= (/ "Vmse",	"Vdmdt", "Vomegadmdp",	"Vlw",	"Vm_hadv", 	"LHFLX",	"Vudmdx",	"SHFLX",	"Vvdmdy",	"Vsw" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	
	progGen		= ".make_L2.1_regression_propagation."


	;------------- plot resources for shaded base plot
	res 						= True
	res@vpWidthF				= 0.8
	res@vpHeightF				= 0.4
	res@gsnDraw             	= False			; don't draw
	res@gsnFrame            	= False			; don't advance frame
	res@cnInfoLabelOn       	= False 		; turn off cn info label
	res@cnFillOn            	= True			; turn on color
	res@cnLinesOn				= False			; turn off contour lines
	res@tmXBLabelsOn			= False			; turn off longitude labels
	res@gsnSpreadColors     	= True			; spread out color table
	res@gsnSpreadColorStart 	= 2 
	res@gsnSpreadColorEnd   	= -3 
	res@lbOrientation        	= "Vertical"	; vertical label bar
	res@cnLevelSelectionMode 	=  "ExplicitLevels"   
	res@tmXBLabelFontHeightF 	= 0.025		
	res@tmYLLabelFontHeightF 	= 0.025		
	res@tmEqualizeXYSizes		= True
	res@txFontHeightF			= 0.03
	res@tiYAxisString			= "lag (day)"

	;------------- plot resources for overlaid precipitation
	resR								= True		; Precipitation resources
	resR@vpWidthF						= 0.8
	resR@vpHeightF						= 0.4
	resR@gsnDraw						= False		; don't draw
	resR@gsnFrame						= False		; don't advance frame
	resR@cnInfoLabelOn					= False		; turn off cn info label
	resR@gsnLeftString					= ""		; no titles
	resR@gsnRightString					= ""
	resR@tiXAxisString					= ""
	if (pType.eq."png") then
		resR@cnLineThicknessF			= 4
	else
		resR@cnLineThicknessF			= 1.5
	end if
	resR@cnLineLabelsOn					= False		; no line labels
	if (pType.eq."png") then
		resR@gsnContourZeroLineThicknessF	= 8		; doubles thickness of zero contour
	else
		resR@gsnContourZeroLineThicknessF	= 2
	end if
	resR@gsnContourNegLineDashPattern	= 1 		; sets negative contours to dash pattern 1
	resR@cnLevelSelectionMode 			=  "ExplicitLevels"   
	resR@tmXBLabelFontHeightF 			= 0.025		
	resR@tmYLLabelFontHeightF 			= 0.025		
	resR@tmEqualizeXYSizes				= True
	resR@cnLevels						= fspan(-1,1,11)

	do s = 0,1 						; do for each season
	
	;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L2.1_MSEbudget_propagation."+ twStrt + "-" + twLast +"."+seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)                 	; create a plot array

		do v = 0,9			; do for each variable
		
			;------------ read in the rainfall data
			tName			= "PRECT"
			fili			= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			rain			= rm_single_dims(f->$tName$)

			;------------ read metadata, set longitude range for plot
			if (s.eq.0.and.v.eq.0) then
				lag		= f->lag
				lon		= f->lon
				gridp	= f->gridp
				bpstdev	= f->gridp_stdev
				lonind	= ind(lon.ge.30.and.lon.le.240)
			end if

			;------------ assign label and units
			varID					= ind(vName.eq.varName(v))
			labelID					= label(varID)
			unitsID					= units(varID)

			;------------ read in the base plot data
			tName			= varName(v)
			fili			= diri + caseName + progGen + twStrt + "-" + twLast + ".PRECT." + tName + "." + seasonName(s) + ".nc"
			f				= addfile(fili,"r")
			data			= rm_single_dims(f->$tName$)
			data@long_name	= labelID
			if (v.eq.0) then
				data		= data * 1E-06
			end if

			;------------ reformat units
			if (v.eq.0) then
				data@units	= "[J m~S2~-2  ]/[mm day~S2~-1  ]"
			else
				data@units	= "[W m~S2~-2  ]/[mm day~S2~-1  ]"
			end if

			;------------ define contour interval for base plot
			;if (v.ge.0.and.v.le.7) then	; Qnet, SW, or LH
				;res@cnLevels = fspan(-10,10,11)
				res@cnLevels = fspan(-5,5,11)
			;end if
			;if (v.ge.8) then	; LW or SH
			;	res@cnLevels = fspan(-1,1,11)
			;end if

			;------------ turn on longitude labels for bottom panels
			if (v.eq.8) then
				res@tmXBLabelsOn			= True
			end if

			;------------ make plots
			;plotR	= gsn_csm_contour(wks, rain({90},:,0,lonind), resR )
			;plota	= gsn_csm_contour(wks, data({90},:,0,lonind), res )
			plotR	= gsn_csm_contour(wks, rain({90},:,lonind), resR )
			plota	= gsn_csm_contour(wks, data({90},:,lonind), res )
			overlay(plota,plotR)
			plot(v)=plota
			delete(plota)
			delete(plotR)
	
			nVars	= v+1 ; this keeps track of how total panels are being plotted

		end do			; variable loop

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nPanels		= nVars
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
		resP@txString			= caseName+" " + seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 4
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)               ; now draw as one plot

		;------------- print sign convention
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.013                    	; font smaller. default big
		
		if (figcap.eq."true") then
			gsn_text_ndc(wks,"[lowest four rows:  positive anomalies support positive MSE]",0.5,0.025,txres) 
			gsn_text_ndc(wks,"~F33~s~F21~(rain) = "+sprintf("%5.2f",bpstdev(1))+" mm/day.  Overlay:  rainfall [mm day~S2~-1  ]/[mm day~S2~-1  ]",0.5,0.007,txres) 
		end if

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn		= False ; turn off longitude labels for next season plots

	end do	; season loop

end
