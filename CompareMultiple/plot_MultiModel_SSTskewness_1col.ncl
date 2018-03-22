load "../Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_MultiModel_SSTskewness_1col.ncl =================")

	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	fPrefix			= getenv("FilePrefix")
	nCases			= toint(getenv("nCases"))
	nRows			= toint(getenv("nRows"))
	pType			= getenv("PTYPE")
	dirp			= getenv("dirp")	
	varName			= getenv("varName")	
	PanelStrt		= getenv("panelLabStrt")
	AxisFontHt		= tofloat(getenv("AxisFontHt"))
	TitleFontHt		= tofloat(getenv("TitleFontHt"))
	PanelFontHt		= tofloat(getenv("PanelFontHt"))
	LabelBarFontHt	= tofloat(getenv("LabelBarFontHt"))
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)

	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnLineLabelsOn			= False			; don't label contours
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= False			; turn off contour lines
	res@cnFillMode				= "RasterFill"	; use RasterFill
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelFontHeightF	= AxisFontHt        ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= AxisFontHt        ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@cnMinLevelValF			=  -1.5
	res@cnMaxLevelValF			=   1.5
	res@cnLevelSpacingF			=  0.3
	res@lbLabelBarOn			= False
	res@tmXBLabelsOn			= False ; turn off longitude labels for next season

	;------------- plot resources for median SST overlay
	resM                     	= True
	resM@gsnDraw				= False
	resM@gsnFrame				= False
	resM@cnFillOn				= False			; turn off color
	resM@cnLinesOn				= True			; turn on contour lines
	resM@cnLineColor			= "Black"
	if (pType.eq."png") then
		resM@cnLineThicknessF	= 3
	else
		resM@cnLineThicknessF	= 2
	end if
	resM@cnInfoLabelOn			= False
	resM@cnLineLabelsOn			= False
	resM@cnLevels				= fspan(-0.2,0.2,11)
	resM@cnLevelSelectionMode	= "ExplicitLevels"   
	resM@tiXAxisOn				= False
	resM@tiYAxisOn				= False
	resM@tiMainOn				= False
	resM@gsnContourNegLineDashPattern	= 1
	if (pType.eq."png") then
		resM@gsnContourZeroLineThicknessF	= 6
	else
		resM@gsnContourZeroLineThicknessF	= 4
	end if	
	
	;------------- set up plot panels, contours, labels, units
	plot 		= new(nCases,graphic)   	; double the number to utilize left-column only
	units		= ""
		              	
	do s = 0,1 				; do for each season

		;----------- set up plot file
		wksType = pType
		if (fPrefix.eq."") then
			wksName	= dirp + "MultiModel_SSTskewness_1col." + seasonName(s)
		else
			wksName	= dirp + fPrefix + ".MultiModel_SSTskewness_1col." + seasonName(s)
		end if
		print("plot file = " + wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"ncl_default")

		do n=0,nCases-1
				
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR) + "/proc/"
			dateRange	= getenv(MODDATES)	
			;print("caseName = " + caseName)	
			
			;----------- read in seasonal SST skewness
			fili		= diri + caseName + ".make_L1.8_SST_skewness." + dateRange + "." + seasonName(s) + ".nc"
			print("fili = " + fili)
			f			= addfile(fili,"r")
			skew		= f->SST_skewness
			med			= f->SST_median
		
			;------------ turn on longitude labels for bottom panels
			if (n.eq.nCases-1) then
				res@tmXBLabelsOn			= True
			end if

			;------------ make panel plots
			skew@long_name		= caseName
			skew@units			= ""
			med@long_name		= ""
			med@units			= ""
			plot(n)				= gsn_csm_contour_map_overlay(wks,skew,smth9_Wrap(med,0.5,0.25,True),res,resM)
	
			delete(skew)
			delete(med)			
		end do
		;print("finished generating all panels...")
		
		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		pID										= pStr(tointeger(PanelStrt)::)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= "SST skewness, " + seasonName(s); add common title
		resP@gsnPanelMainFontHeightF			= TitleFontHt
		resP@gsnPanelRight						= 0.995
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= PanelFontHt
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= LabelBarFontHt
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.28               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.02              ; default is taller
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	end do				; season loop

end