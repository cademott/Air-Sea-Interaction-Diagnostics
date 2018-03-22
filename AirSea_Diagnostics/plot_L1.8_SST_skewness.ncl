load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("=============== in plot_L1.8_SST_skewness.ncl =================")

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

	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= False			; turn off contour lines
	res@cnFillMode				= "RasterFill"	; use RasterFill
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@cnMinLevelValF			=  -1.
	res@cnMaxLevelValF			=   1.
	res@cnLevelSpacingF			=  0.2 

	;------------- plot resources for median SST overlay
	resM                     	= True
	resM@gsnDraw				= False
	resM@gsnFrame				= False
	resM@cnFillOn				= False			; turn off color
	resM@cnLinesOn				= True			; turn on contour lines
	resM@cnLineColor			= "Black"
	if (pType.eq."png") then
		resM@cnLineThicknessF	= 6
	else
		resM@cnLineThicknessF	= 2
	end if
	resM@cnInfoLabelOn			= False
	resM@cnLineLabelsOn			= False
	resM@cnLevels				= fspan(-0.1,0.1,11)
	resM@cnLevelSelectionMode	= "ExplicitLevels"   
	resM@tiXAxisOn				= False
	resM@tiYAxisOn				= False
	resM@tiMainOn				= False
	resM@gsnContourNegLineDashPattern	= 1
	if (pType.eq."png") then
		resM@gsnContourZeroLineThicknessF	= 12
	else
		resM@gsnContourZeroLineThicknessF	= 4
	end if	
	
	do s = 0,1 					; do for each season
		;----------- set up plot file
		wksType 	= pType
		wksName		= dirp + caseName + ".plot_L1.8_SST_skewness."+ twStrt + "-" + twLast + "." + seasonName(s)
		wks 		= gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"ncl_default")
		plot		= new(10,graphic)                 	

		;------------ read in the data
		fili			= diri + caseName + ".make_L1.8_SST_skewness." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		f				= addfile(fili,"r")
		data			= f->SST_skewness
		data@units		= ""
		med				= f->SST_median
		med@long_name	= ""
		med@units		= ""

		;----------- create the panel
		plot			= gsn_csm_contour_map_overlay(wks,data,smth9_Wrap(med,0.5,0.25,True),res,resM)
		
		;------------- create plot page
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= caseName + " " + seasonName(s)	; add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		gsn_panel(wks,plot,(/1,1/),resP)                	; now draw as one plot


		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do

end





