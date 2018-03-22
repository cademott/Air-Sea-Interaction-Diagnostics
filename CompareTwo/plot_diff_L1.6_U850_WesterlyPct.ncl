load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("=============== in plot_diff_L1.6_U850_WesterlyPct.ncl =================")
	progGenVar	 	= ".make_L1.6_U850_WesterlyPct."

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

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName_label	= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))

	;----------- read in the contour intervals for stdev fields
	metafile			= "./CompareMultiple/contours_Season_DiffStDev_Maps.txt"
	vName_ciStDev		= systemfunc("cut -d , -f1 "+metafile)
	cnMin_ciStDev		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax_ciStDev		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt_ciStDev		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 

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
	res@cnMinLevelValF			= -40.
	res@cnMaxLevelValF			=  40.
	res@cnLevelSpacingF			=  10. 


	do s = 0,1 				; do for each season
		
		;----------- set up plot file -- CTRL MINUS EXPERIMENT
		wksType = pType
		wksName= dirp + EXPNAME + "_minus_"+ CTRLNAME + ".plot_diff_L1.6_U850_WesterlyPct." + seasonName(s)
		
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"BlueWhiteOrangeRed")
		plot = new(2,graphic)                 	


		;------------ read in the data
		fili	= diri + EXPNAME + "_minus_" + CTRLNAME + progGenVar  + "U850_WestPct." + seasonName(s) + ".nc"
		f		= addfile(fili,"r")
		data	= f->U850_WestPct
		data@long_name	= vName_label(ind(vName_label.eq."U850"))
	

		;----------- create the plot
		plot(s)		= gsn_csm_contour_map_ce(wks,data(:,:),res)
		

		;------------- create plot page
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@txString			= EXPNAME + " - " + CTRLNAME + "," + " "+ seasonName(s); add common title
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		gsn_panel(wks,plot(s),(/1,1/),resP)                	; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if
	
		print("output file = " + wksName)

end do
end





