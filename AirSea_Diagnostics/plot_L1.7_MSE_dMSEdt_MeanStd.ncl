load "./Resources/contrib_AirSea.ncl"

begin
	print("=============== in plot_L1.7_MSE_dMSEdt_MeanStd.ncl =================")

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

	;------------- set up plot resources
	res							= True
	res@gsnDraw            		= False			; don't draw
	res@gsnFrame           		= False			; don't advance frame
	res@mpGridLonSpacingF		= 30.
	res@cnInfoLabelOn      		= False 		; turn off cn info label
	res@cnLinesOn       		= True			; turn off contour lines
	res@cnFillOn            	= True			; turn on color
	res@gsnSpreadColors     	= True			; spread out color table
	res@tmXBLabelsOn			= False			; turn off longitude labels
	res@gsnSpreadColorStart 	= 2 
	res@gsnSpreadColorEnd   	= -3 
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.017		; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017		; change maj lat tm spacing
	res@gsnPaperMargin			= 0.1
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode =  "ExplicitLevels"   
	res@gsnContourZeroLineThicknessF	= 0

	do s = 0,1 					; do for each season
		;----------- set up plot file
		wksType = pType
		wksName	= dirp + caseName + ".plot_L1.7_MSE_dMSEdt_MeanStd."+ twStrt + "-" + twLast +"."+seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		
		gsn_define_colormap(wks,"MPL_rainbow")
		plot = new(10,graphic)                 	

		fili_prefix		= caseName + ".make_L1.4_mean_stdev_map." + twStrt + "-" + twLast +"."
		fili_suffix		= "." + seasonName(s) + ".nc"
		fili			= fili_prefix + "Vmse" + fili_suffix
		f				= addfile(diri+fili,"r")
		mse_mean		= f->Vmse_mean
		mse_stdev		= f->Vmse_stdev
		printMinMax(mse_mean,True)

		fili			= fili_prefix + "Vdmdt" + fili_suffix
		f				= addfile(diri+fili,"r")
		dmdt_stdev		= f->Vdmdt_stdev

		x = mse_mean
		mse_mean = mse_mean * 1E-07
		copy_VarMeta(x,mse_mean)
		x = mse_stdev
		mse_stdev = mse_stdev * 1E-06
		copy_VarMeta(x,mse_stdev)
		mse_mean@units				= "10~S1~7~N~  J m~S2~-2"
		mse_mean@long_name			= "mean ~F34~a~F21~m~F34~q~F21~"
		mse_stdev@units				= "10~S1~6~N~  J m~S2~-2"
		mse_stdev@long_name			= "~F33~s~F21~(~F34~a~F21~m~F34~q~F21~)"
		dmdt_stdev@units			= "W m~S2~-2"
		dmdt_stdev@long_name		= "~F33~s~F21~(~F34~6~F34~a~F21~m~F34~q~F21~/~F34~6~F21~t~F21~)"
		;printMinMax(mse_mean,True)
		;printMinMax(mse_stdev,True)
		;printMinMax(dmdt_stdev,True)
		res@cnLevels			 	= fspan(320,340,11)
		plot(0)						= gsn_csm_contour_map(wks,mse_mean,res)
		res@cnLevels			 	= fspan(0,20,11)
		plot(2)						= gsn_csm_contour_map(wks,mse_stdev,res)
		res@tmXBLabelsOn			= True
		res@cnLevels			 	= fspan(0,40,11)
		plot(4)						= gsn_csm_contour_map(wks,dmdt_stdev,res)

		;------------- create plot page
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		nVars		= 3
		nPanels		= nVars*2
		pID			= new(nPanels,"string")
		do i=0,nPanels/2-1
			pID(i*2)	= pStr(i)
			pID(i*2+1)	= pStr(i+nPanels/2)
		end do
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelLabelBar					= False                  	; add common colorbar
		;resP@txString							= caseName+" " + seasonName(s); add common title
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 5
		resP@gsnPanelFigureStrings 				= pID      ; add letter labels to panels (# letters can be > # panels)
		resP@gsnPanelFigureStringsFontHeightF	= 0.012
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		gsn_panel(wks,plot,(/5,2/),resP)        ; now draw as one plot

		;------------- label columns
		txres               	= True                     	; text mods desired
		txres@txFontHeightF		= 0.016                    	; font smaller. default big
		gsn_text_ndc(wks,caseName+" " + seasonName(s),0.23,0.895,txres) 

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn			= False			; turn off longitude labels

	end do ; season loop
end