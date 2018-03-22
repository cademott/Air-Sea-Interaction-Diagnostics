load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("=============== in plot_L1.6_U850_WesterlyPct.ncl =================")

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
	res@cnMinLevelValF			=   0.
	res@cnMaxLevelValF			= 100.
	res@cnLevelSpacingF			=  10. 

	;----------- set up plot file
	wksType 	= pType
	wksName		= dirp + caseName + ".plot_L1.6_U850_WesterlyPct."+ twStrt + "-" + twLast + ".TwoSeasons"
	wks 		= gsn_open_wks(wksType,wksName)		; open a ps file
	gsn_define_colormap(wks,"ncl_default")
	plot		= new(10,graphic)                 	

	do s = 0,1 					; do for each season
		;------------ read in the data
		fili			= diri + caseName + ".make_L1.6_U850_WesterlyPct." + twStrt + "-" + twLast + ".U850_WestPct." + seasonName(s) + ".nc"
		f				= addfile(fili,"r")
		data			= f->U850_WestPct

		;----------- create the panel
		plot1		= gsn_csm_contour_map_ce(wks,data,res)
		plot(s)		= plot1
		delete(plot1)
		
	end do

	;------------- create plot page
	resP					= True                   	; modify the panel plot
	resP@gsnFrame			= False                  	; don't advance panel plot
	resP@gsnPanelLabelBar	= False                  	; add common colorbar
	resP@txString			= caseName					; add common title
	resP@gsnPanelBottom		= 0.05                   	; add space at bottom
	gsn_panel(wks,plot,(/5,2/),resP)                	; now draw as one plot

	;------------- label columns
	txres               	= True                     	; text mods desired
	txres@txFontHeightF		= 0.013                    	; font smaller. default big
	gsn_text_ndc(wks,seasonName(0),0.23,0.88,txres) 
	gsn_text_ndc(wks,seasonName(1),0.73,0.88,txres) 

	if (wksType.eq."png") then
		frame(wks)
		trimPNG(wksName)
	end if

end





