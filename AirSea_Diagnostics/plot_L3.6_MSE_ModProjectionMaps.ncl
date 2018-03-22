load "./Resources/contrib_AirSea.ncl"
;load "contrib_JJB.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin

	print("=============== in plot_L3.6_MSE_ModProjectionMaps.ncl =================")

	;----------- Retrieve required environment variables
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

	;------------- plot resources for modified projections
	res							= True
	res@gsnDraw            		= False			; don't draw
	res@gsnFrame           		= False			; don't advance frame
	res@mpGridLonSpacingF		= 30.
	res@cnInfoLabelOn      		= False 		; turn off cn info label
	res@cnLinesOn       		= False			; turn off contour lines
	res@cnFillOn            	= True			; turn on color
	res@gsnSpreadColors     	= True			; spread out color table
	res@tmXBLabelsOn			= False
	res@gsnSpreadColorStart 	= 2 
	res@gsnSpreadColorEnd   	= -3 
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.017			; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017			; change maj lat tm spacing
	res@gsnPaperMargin			= 0.1
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode =  "ExplicitLevels"   
	res@cnLevels			 	= fspan(-2.5,2.5,11)
			
	;------------- plot resources for overlaid significance
	resS						= True
	resS@gsnDraw				= False				; don't draw
	resS@gsnFrame				= False				; don't advance frame
	resS@cnInfoLabelOn			= False				; turn off cn info label
	resS@cnLinesOn				= False				; turn off contour lines
	resS@cnLineColor			= "grey61"			; turn off contour lines
	resS@tiXAxisString			= ""
		if (pType.eq."png") then
			resS@cnLineThicknessF	= 4						; thicker contours
		else
			resS@cnLineThicknessF	= 1.5					; thicker contours
		end if
	resS@cnLineLabelsOn			= False				; no line labels
	resS@cnLevelSelectionMode	= "ExplicitLevels"	; manually specify contour levels
	resS@cnLevels				= (/ -20.,0.,20. /)
	resS@cnInfoLabelOn			= False				; turn off info label box
	resS@cnLineLabelsOn			= False				; no lables on line
	resS@cnFillOn				= True				; fill contour intervals
	resS@cnMonoFillColor		= True				; default color is fground [black]
	resS@cnMonoFillPattern		= False				; want multiple patterns 
	resS@cnMonoFillScale		= False				; want patterns w/ diff densities 
	resS@cnMonoFillPattern		= False        		; Use multiple fill patterns
	resS@cnFillPatterns			= (/ -1, 3, -1, -1 /); 3=slant lines
	resS@cnFillScales     	 	= (/0.55,0.55/)		; line density
	resS@cnFillColor			= "grey61"
	resS@tiXAxisOn				= False
	resS@tiYAxisOn				= False
	resS@tiMainOn				= False

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;----------- read in variable labels and units
	metafile	= "./Resources/variable_labels_units.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	label		= str_left_strip(systemfunc("cut -d , -f2 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f3 "+metafile))
	mseID		= label(ind(vName.eq."Vmse"))
	dmdtID		= label(ind(vName.eq."Vdmdt"))
	
	do s=0,1
		fili			= caseName + ".make_L3.3_MSE_ModProjectionMaps." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		f				= addfile(diri+fili,"r")
		nprog_TOTmse	= f->TOT_SSTeffect_mse_nprog
		nprog_TOTdmdt	= f->TOT_SSTeffect_dmdt_nprog
		sig_mse			= f->sig_mse
		sig_dmdt		= f->sig_dmdt
		sig_diff		= f->sig_diff
		sig_diff 		= 1. - sig_diff

		;------------ mask land
		lon		= f->$lonName$
		lat		= f->$latName$			
		a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
		lsdata	= a->LSMASK
		lsm		= landsea_mask(lsdata,lat,lon)

		;------------set up the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L3.6_MSE_ModProjectionMaps." + twStrt + "-" + twLast + "." + seasonName(s)
		print("--------- making "+wksName)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"cmp_b2r")
		plot = new(10,graphic)		; 2 columns


		nprog_TOTmse@long_name		= "normalized SST effect on " + mseID
		nprog_TOTmse@units			= "W m~S~-2~N"
		plot(0)						= gsn_csm_contour_map_overlay(wks,nprog_TOTmse,sig_mse,res,resS)
		nprog_TOTdmdt@long_name		= "normalized SST effect on " + dmdtID
		nprog_TOTdmdt@units			= "W m~S~-2~N"
		res@tmXBLabelsOn			= True
		plot(2)						= gsn_csm_contour_map_overlay(wks,nprog_TOTdmdt,sig_dmdt,res,resS)
		diff						= abs(nprog_TOTmse) - abs(nprog_TOTdmdt)
		copy_VarMeta(nprog_TOTmse,diff)
		diff@long_name				= "amplitude difference,  ~F18~Q~F21~(~F10~F~S1~~F35~2~B1~~F10~m~N~  ~F21~)~F18~Q~F21~ - ~F18~Q~F21~(~F10~F~S1~~F35~2~B5~~F34~6~F10~m~F21~/~F34~6~F10~t~N~    ~F21~)~F18~Q~F21~~H-215~~V20~~~~H100~~~"
		resS@cnLevels				= (/ 0.,0.05,20. /)

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nVars		= 3
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		resP					= True                   	; modify the panel plot
		resP@gsnFrame			= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar	= False                  	; add common colorbar
		resP@gsnPanelBottom		= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent = 6
		resP@gsnPanelFigureStrings = pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)               ; now draw as one plot
	
		res@tmXBLabelsOn			= False
		delete(sig_mse)
		delete(sig_dmdt)
	
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do ; season loop

end
