load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_diff_L1.7_RH_byWindSST_PDF.ncl =================")
	
	
	progGenU850		= ".make_L1.3a_mean_u850."
	progGenVar	 	= ".make_L1.5_stdev_map."

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
	dirp			= getenv("PLOTDIR") + "/"
	pType			= getenv("PTYPE")
	u850_overlay	= getenv("u850_overlay")	
	diri			= EXPDIR + "proc/" + EXPNAME + "_minus_" + CTRLNAME + "/" 
	print("dirp = " + dirp)
	
	maxSST			= 32.0
	
	
	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	do s = 0,1 
		fili		= diri + EXPNAME + "_minus_" + CTRLNAME + ".make_L1.7_RH_byWindSST_PDF." + seasonName(s) + ".nc"
		f			= addfile(fili,"r")
		WindSpeed	= f->wind_speed
		SST			= f->SST
		;minSST		= min(SST)
		;maxSST		= 32.0
		
					; do for each SST type (full or smoothed)
		;------------make the plot
		wksType = pType
		wksName= dirp + EXPNAME + "_minus_"+ CTRLNAME + ".plot_diff_L1.7_RH_byWindSST_PDF." + seasonName(s)
	
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		;gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
		gsn_define_colormap(wks,"MPL_BrBG")
		plotRH = new(2,graphic)                 	; create a plot array

		pdf		= (/ "PDF_DYN", 	"PDF_TGC" /)
		rh		= (/ "meanRH_DYN",	"meanRH_TGC" /)

		do loc=0,1 		; location loop

			; read in the data for the given location
			PDF			= f->$pdf(loc)$
			RH			= f->$rh(loc)$

			res                     = True
			res@gsnDraw             = False			; don't draw
			res@gsnFrame            = False			; don't advance frame
			res@cnInfoLabelOn       = False 		; turn off cn info label
			res@cnFillOn            = True			; turn on color
			res@cnFillMode			= "RasterFill"
			res@cnLinesOn			= False			; turn off contour lines
			res@gsnSpreadColors     = True			; spread out color table
			res@gsnSpreadColorStart = 2 
			res@gsnSpreadColorEnd   = -3 
			res@lbOrientation		= "Vertical"	; vertical label bar
			res@lbTitleOn			= True
			res@lbTitleString		= "%"
			res@lbTopMarginF		= 0.001
			res@tmXBLabelFontHeightF= 0.0175       ; change maj lat tm spacing
			res@tmYLLabelFontHeightF= 0.0175       ; change maj lat tm spacing
			res@cnLevelSelectionMode= "ExplicitLevels"
			res@cnLevels			= ispan(-10,10,2)
			res@pmLabelBarOrthogonalPosF = -0.005
			res@gsnSpreadColorStart =  2 
			res@gsnSpreadColorEnd	= -3 
			res@tiMainOn			= True
			res@tiMainString		= "mean RH; SST-|~F14~V~F21~| PDF"
			res@tiXAxisString		= WindSpeed@units
			res@tiYAxisString		= SST@units
			res@trYMaxF				= 32.
			RH@long_name			= " "
			plotRH(loc) = gsn_csm_contour(wks,RH(SST|:,wind_speed|:),res)
			delete(res@cnLevels)

			; turn stuff off for overlay plot
			res@cnFillOn			= False			; turn off color
			res@cnLinesOn			= True			; turn on contour lines
			res@gsnContourNegLineDashPattern	= 1
			res@gsnContourZeroLineThicknessF	= 0
			res@cnLineColor			= "Black"
			res@cnLineThicknessF	= 2.
			res@cnLevelSelectionMode= "ExplicitLevels"
			res@cnLevels			= fspan(-2.5,2.5,11)
			res@tiMainOn			= False
			res@cnLineLabelDensityF		= 1.9
			res@cnLineLabelFontHeightF	= 0.015
			res@cnLineLabelInterval		= 1
			res@cnMonoLevelFlag			= False
			PDF@long_name			= " "
			plotPDF = gsn_csm_contour(wks,PDF(SST|:,wind_speed|:),res)
			;plotPDF = gsn_csm_contour(wks,PDF({SST|minSST:maxSST},wind_speed|:),res)
			delete(res@cnLevels)
	
			overlay(plotRH(loc),plotPDF)
		
			;------------- create plot page
			resP					= True                   	; modify the panel plot
			resP@gsnFrame			= False                  	; don't advance panel plot
			resP@gsnPanelLabelBar	= False                  	; add common colorbar
			resP@txString			= EXPNAME + " - " + CTRLNAME + "," + " "+ seasonName(s); add common title
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
	
		print("output file = " + wksName)

	end do ; season loop		

end