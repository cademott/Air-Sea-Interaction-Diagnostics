load "./Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("============== in plot_L1.5_RH_byWindSST_PDF.ncl =============")   

	;------------- set dynamic variable names
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
	sstName		= getenv("SSTVARNAME")
	diri		= getenv("FILEDIR") + "/proc/"
	dirp		= getenv("FILEDIR") + "/plots/"
	caseName	= getenv("caseName")
	timeName	= getenv("TIMEVAR")
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

	seasonName		= (/ "Nov-Apr","May-Oct" /)
	
	do s=0,1		; season loop

		fili		= diri + caseName + ".make_L1.7_RH_byWindSST_PDF." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
		f			= addfile(fili,"r")
		WindSpeed	= f->wind_speed
		SST			= f->SST
		
		;------------make the plot
		wksType = pType
		wksName	= dirp + caseName + ".plot_L1.5_RH_byWindSST_PDF."+twStrt + "-" + twLast + "." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_BrBG")
		plotRH = new(2,graphic)                 	; create a plot array

		pdf		= (/ "PDF_DYN", 	"PDF_TGC" /)
		rh		= (/ "meanRH_DYN",	"meanRH_TGC" /)

		do loc=0,1 		; location loop

			; read in the data for the given location
			PDF			= f->$pdf(loc)$
			RH			= f->$rh(loc)$
			;printVarSummary(PDF&wind_speed)
			;printVarSummary(PDF&SST)
			PDF&wind_speed@units		= "m s~S2~-1"
			PDF&SST@units				= "~F34~0~F21~C"

			res							= True
			res@gsnDraw					= False			; don't draw
			res@gsnFrame 				= False			; don't advance frame
			res@cnInfoLabelOn			= False 		; turn off cn info label
			res@cnFillOn				= True			; turn on color
			res@cnFillMode				= "RasterFill"
			res@cnLinesOn				= False			; turn off contour lines
			res@gsnSpreadColors			= True			; spread out color table
			res@gsnSpreadColorStart		= 2 
			res@gsnSpreadColorEnd		= -3 
			res@lbOrientation			= "Vertical"	; vertical label bar
			res@lbTitleOn				= True
			res@lbTitleString			= "%"
			res@lbTopMarginF			= 0.001
			res@tmXBLabelFontHeightF	= 0.0175       ; change maj lat tm spacing
			res@tmYLLabelFontHeightF	= 0.0175       ; change maj lat tm spacing
			res@cnLevelSelectionMode	= "ExplicitLevels"
			res@cnLevels				= fspan(70,90,21)
			res@pmLabelBarOrthogonalPosF= -0.005
			res@gsnSpreadColorStart 	=  2 
			res@gsnSpreadColorEnd		= -3 
			res@tiMainOn				= True
			res@tiMainString			= "SST-|~F22~V~F21~| PDF; mean RH"
			res@tiXAxisString			= WindSpeed@units
			res@tiYAxisString			= SST@units
			res@trYMaxF					= 32.
			RH@long_name				= " "
			plotRH(loc) 				= gsn_csm_contour(wks,RH(SST|:,wind_speed|:),res)
			delete(res@cnLevels)

			; turn stuff off for overlay plot
			res@cnFillOn				= False			; turn off color
			res@cnLinesOn				= True			; turn on contour lines
			res@cnLineColor				= "Black"
			if (pType.eq."png") then
				res@cnLineThicknessF	= 8
			else
				res@cnLineThicknessF	= 2
			end if
			res@cnLevelSelectionMode	= "ExplicitLevels"
			res@cnLevels				= (/ .001, .01, .1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 /)
			res@tiMainOn				= False
			res@cnLineLabelDensityF		= 1.9
			res@cnLineLabelFontHeightF	= 0.015
			res@cnLineLabelInterval		= 1
			res@cnMonoLevelFlag			= False
			PDF@long_name				= " "
			plotPDF 					= gsn_csm_contour(wks,PDF(SST|:,wind_speed|:),res)
			delete(res@cnLevels)
	
			overlay(plotRH(loc),plotPDF)

			;------------- create plot page
			resP					= True                   	; modify the panel plot
			resP@gsnFrame			= False                  	; don't advance panel plot
			resP@gsnPanelLabelBar	= False                  	; add common colorbar
			resP@txString			= caseName+" " + seasonName(s); add common title
			resP@gsnPanelBottom		= 0.05                   	; add space at bottom
			resP@gsnPanelXWhiteSpacePercent = 3.0
			gsn_panel(wks,plotRH,(/1,2/),resP)                	; now draw as one plot

			;------------- label columns
			txres               	= True                     	; text mods desired
			txres@txFontHeightF		= 0.013                    	; font smaller. default big
			gsn_text_ndc(wks,"DYNAMO:  5S-5N, 70E-80E",0.2,0.655,txres) 
			gsn_text_ndc(wks,"TOGA COARE:  10S-0N, 155E-165E" ,0.735,0.655,txres) 

		end do ; location loop
	
		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do ; season loop		

end
	





