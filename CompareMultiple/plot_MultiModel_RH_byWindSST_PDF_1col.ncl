load "../Resources/contrib_AirSea.ncl"
  
;------------------------------------------------------------------------
begin
                           
	print("============== in plot_MultiModel_RH_byWindSST_PDF_1col.ncl =============")   

	;------------- set dynamic variable names
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if
	FNPrefix		= getenv("FilePrefix")
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
	
	res							= True
	res@gsnDraw					= False			; don't draw
	res@gsnFrame 				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@tmXBLabelFontHeightF	= 0.03			
	res@tmYLLabelFontHeightF	= 0.03		
	res@tmYLMode				= "Manual"
	res@tmYLTickStartF  		= 25
	res@tmYLTickEndF    		= 32
	res@tmYLTickSpacingF		= 1
	res@tmYLFormat				= "f"
	res@cnLevelSelectionMode	= "ExplicitLevels"
	res@vpWidthF				= 0.9
	res@vpHeightF				= 0.45
	res@trYMaxF					= 32.
	res@trYMinF					= 25.
	res@cnFillOn				= True			; turn on color
	res@cnFillMode				= "RasterFill"
	res@cnLinesOn				= False			; turn off contour lines
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@cnLevels				= fspan(70,90,21)
	res@lbLabelBarOn			= False
	res@tmXBLabelsOn			= False
	res@tiXAxisFontHeightF		= 0.03
	res@tiYAxisFontHeightF		= 0.03
	res@gsnLeftStringFontHeightF= 0.035
	res@gsnRightStringFontHeightF= 0.035

	resC						= True
	resC@gsnDraw 				= False			; don't draw
	resC@gsnFrame				= False			; don't advance frame
	resC@cnFillOn				= False			; turn off color
	resC@cnLinesOn				= True			; turn on contour lines
	resC@cnLineColor				= "Black"
	if (pType.eq."png") then
		resC@cnLineThicknessF	= 4
	else
		resC@cnLineThicknessF	= 2
	end if
	resC@cnInfoLabelOn			= False 		; turn off cn info label
	resC@cnLevelSelectionMode	= "ExplicitLevels"
	resC@cnLevels				= (/ .001, .01, .1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 /)
	resC@tiMainOn				= False
	resC@cnLineLabelDensityF	= 1.9
	resC@cnLineLabelFontHeightF	= 0.02
	resC@cnLineLabelInterval	= 1
	resC@cnMonoLevelFlag		= False
	

	seasonName		= (/ "Nov-Apr","May-Oct" /)
	locName			= (/ "EIO", "WPac" /)
	
	do s=0,1		; season loop

		;----------- set up plot file
		wksType = pType
		wksName	= dirp + FNPrefix + ".MultiModel_RH_byWindSST_PDF_1col." + seasonName(s)
		wks 	= gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_BrBG")
		plot 	= new(16,graphic)                 	; create a plot array
		print(seasonName(s) + " plotfile = " + wksName)

		do n=0,nCases-1

			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR) + "/proc/"
			dateRange	= getenv(MODDATES)	
			print("caseName = " + caseName)	

			fili		= diri + caseName + ".make_L1.7_RH_byWindSST_PDF." + dateRange + "." + seasonName(s) + ".nc"
			f			= addfile(fili,"r")
			WindSpeed	= f->wind_speed
			SST			= f->SST
		
			pdf		= (/ "PDF_DYN", 	"PDF_TGC" /)
			rh		= (/ "meanRH_DYN",	"meanRH_TGC" /)

			do loc=0,1 		; location loop

				; read in the data for the given location
				PDF							= f->$pdf(loc)$
				RH							= f->$rh(loc)$
				RH@long_name				= caseName
				RH@units					= locName(loc)
				RH&wind_speed@units			= ""
				RH&SST@units				= ""

				; shaded RH raster plot
				if (loc.eq.0) then
					res@tmYLLabelsOn		= True
					resC@tmYLLabelsOn		= True
					res@tiYAxisString		= "SST, ~F34~0~F21~C"
					resC@tiYAxisString		= "SST, ~F34~0~F21~C"
				else
					;res@tmYLLabelsOn		= False
					;resC@tmYLLabelsOn		= False
					res@tiYAxisString		= ""
					resC@tiYAxisString		= ""
				end if

				if (n.eq.nCases-1) then
					res@tmXBLabelsOn		= True
					resC@tmXBLabelsOn		= True
					res@tiXAxisString		= "wind speed, m s~S2~-1"
					resC@tiXAxisString		= "wind speed, m s~S2~-1"
				else
					res@tmXBLabelsOn		= False
					resC@tmXBLabelsOn		= False
					res@tiXAxisString		= ""
					resC@tiXAxisString		= ""
				end if
				plotRH		 				= gsn_csm_contour(wks,RH(SST|:,wind_speed|:),res)

				; contoured wind speed-SST plot
				PDF@long_name				= ""
				plotPDF 					= gsn_csm_contour(wks,PDF(SST|:,wind_speed|:),resC)
	
				overlay(plotRH,plotPDF)
				plot(2*n+loc)	= plotRH

				delete(plotRH)
				delete(plotPDF)

			end do ; location loop
	
			delete(WindSpeed)
			delete(SST)
			delete(PDF)
			delete(RH)

		end do ; case loop
					
		;------------- create plot page
		print("paneling plots...")
		resP							= True                   	; modify the panel plot
		resP@gsnFrame					= False                  	; don't advance panel plot
		resP@gsnPanelMainString			= "RH by SST-|~F22~V~F21~|, PDF; " + seasonName(s); add common title
		resP@gsnPanelMainFontHeightF	= TitleFontHt
		resP@gsnPanelBottom				= 0.05                   	; add space at bottom
		resP@gsnPanelXWhiteSpacePercent = 0.0
		resP@gsnPanelYWhiteSpacePercent	= 2.0
		resP@gsnPanelLabelBar			= True
		resP@lbLabelFontHeightF			= LabelBarFontHt
		resP@lbAutoManage          		= False             ; we control label bar
		resP@lbOrientation         		= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     		= 0.28              ; default is shorter
		resP@pmLabelBarHeightF     		= 0.02              ; default is taller
		gsn_panel(wks,plot,(/8,2/),resP)                	; now draw as one plot
		delete(plot)

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if

	end do ; season loop		

end
	





