load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
load "/Users/demott/Dropbox/ncl/AirSeaDiagnostics/DeMott_Benedict/contrib_JJB.ncl"
load "/Users/demott/Dropbox/ncl/AirSeaDiagnostics/DeMott_Benedict/substring.ncl"

begin
  
print("")
print("============= in plot_L3.6_FluxTerms_PDF_lineplots.ncl =============")   

;----------- Retrieve required environment variables
debug		= getenv("DEBUG")
if (debug.eq."false") then
	err = NhlGetErrorObjectId()
	setvalues err
		"errLevel" : "Fatal"          ; only report Fatal errors
	end setvalues
end if
figcap		= getenv("FIGCAP")
diri		= getenv("FILEDIR")+"/proc/"
dirp		= getenv("FILEDIR")+"/plots/"
caseName	= getenv("caseName")
twStrt		= getenv("YMDSTRT")
twLast		= getenv("YMDLAST")
dateStr		= getenv("FILESUFFSTR")
lonName		= getenv("LONNAME")
latName		= getenv("LATNAME")
timeName	= getenv("TIMEVAR")

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

;------------- seasons
seasonName	= (/ "Nov-Apr", "May-Oct" /)

do s=0,1	; season loop
	;------------set up the plot
	wksType = "pdf"
	wksName	= dirp + caseName + ".plot_L3.6_FluxTerm_PDF_lineplots." + twStrt + "-" + twLast + "." + seasonName(s)
	print("--------- making "+wksName)
	wks = gsn_open_wks(wksType,wksName)		; open a ps file
	gsn_define_colormap(wks,"cmp_b2r")
	plot = new(4,graphic)					; create a plot array

	res					= True 				; plot mods desired
	res@gsnDraw			= False			; don't draw
	res@gsnFrame		= False			; don't advance frame
	;res@gsClipOn		= False			; don't clip lines
	res@tiXAxisString	= "MSE anomaly (1E7)"	; x axis title
	res@xyLineColors      = (/ "green","green","green","gold","gold","gold" /)  ; line colors
	res@xyLineThicknesses = (/2.0, 2.0, 2.0, 2.0, 2.0, 2.0 /)        ; line thicknesses
	res@xyDashPatterns    = (/0.0, 1.0, 2.0, 0.0, 1.0, 2.0 /)        ; line patterns

	res@xyMarkLineModes   = (/"MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines"/) ; markers?
	res@xyMarkerColors    = res@xyLineColors    	; color
	res@xyMarkers         = (/16,16,16,16,16,16/)   ; style

	; resources for "PDF" variable
	resR                        = True                      
	resR@xyMarkLineModes        = "MarkLines"                   ; dashed line for 2nd
	resR@trYMinF				= 0
	resR@trYMaxF				= 40
	resR@xyMarkers        		= 16                   ; dashed line for 2nd
	resR@xyLineThicknesses      = 2                   ; thicker line
	resR@tiYAxisString 			= "%"   ; axis string
	resR@xyMarkerColors			= "gray"
	resR@xyLineColors			= "gray"

	;------------- read in the MSE binned data
	fili			= diri + caseName + ".make_L3.2_MSE_PDF_lineplots." + "10S-10N.60E-160E." + dateStr + "." + seasonName(s) + ".nc"
;							ERAI.Nov-Apr.make_L3.2_MSE_PDF_lineplots.19860101-20131231.10S-10N.60E-160E.nc
	;fili			= "/Users/demott/Dropbox/Work/AirSeaDiagPlots/ERAI.Nov-Apr.make_L3.2_MSE_PDF_lineplots.19860101-20131231.10S-10N.60E-160E.nc"
	f				= addfile(fili,"r")
	bins			= f->bins
	mse_pdf_ocn		= f->MSE_PDF_ocn
	lh_anom_ocn		= f->LHFLX_anom_ocn
	sh_anom_ocn		= f->SHFLX_anom_ocn
	wdLH_anom_ocn	= f->wdLH_anom_ocn
	tdLH_anom_ocn	= f->tdLH_anom_ocn
	wdSH_anom_ocn	= f->wdSH_anom_ocn
	tdSH_anom_ocn	= f->tdSH_anom_ocn

	mse_pdf_land	= f->MSE_PDF_land
	lh_anom_land	= f->LHFLX_anom_land
	sh_anom_land	= f->SHFLX_anom_land
	wdLH_anom_land	= f->wdLH_anom_land
	tdLH_anom_land	= f->tdLH_anom_land
	wdSH_anom_land	= f->wdSH_anom_land
	tdSH_anom_land	= f->tdSH_anom_land


	data_all 		= new((/6,dimsizes(bins)/),"float")
	data_all(0,:)	= lh_anom_ocn
	data_all(1,:)	= wdLH_anom_ocn
	data_all(2,:)	= tdLH_anom_ocn
	data_all(3,:)	= sh_anom_ocn
	data_all(4,:)	= wdSH_anom_ocn
	data_all(5,:)	= tdSH_anom_ocn
	res@tiMainString	= "10S-10N; 60E-160E MSE budget (ocean)" ; title
	res@tiYAxisString	= "anomaly [W/m**2]"			; y axis title
	res@trYMinF			= -50
	res@trYMaxF			= 50
	plot(0) = gsn_csm_xy2(wks,bins/1E7,data_all,mse_pdf_land,res,resR)          ; Draw an XY plot with 1 curve.
	delete(data_all)

	data_all 		= new((/6,dimsizes(bins)/),"float")
	data_all(0,:)	= lh_anom_land
	data_all(1,:)	= wdLH_anom_land
	data_all(2,:)	= tdLH_anom_land
	data_all(3,:)	= sh_anom_land
	data_all(4,:)	= wdSH_anom_land
	data_all(5,:)	= tdSH_anom_land
	res@tiMainString	= "10S-10N; 60E-160E MSE budget (land)" ; title
	res@tiYAxisString	= "anomaly [W/m**2]"			; y axis title
	res@trYMinF			= -50
	res@trYMaxF			= 50
	plot(1) = gsn_csm_xy2(wks,bins/1E7,data_all,mse_pdf_land,res,resR)          ; Draw an XY plot with 1 curve.
	delete(data_all)

	;------------- create plot page
	resP					= True					; modify the panel plot
	resP@gsnFrame			= False					; don't advance panel plot
	resP@gsnPanelLabelBar	= False					; add common colorbar
	resP@txString			= caseName+" "+seasonName(s)	; add common title
	resP@gsnPanelBottom		= 0.1					; add space at bottom
	gsn_panel(wks,plot,(/2,2/),resP)				; now draw as one plot

	labels					= (/ "LH","wind-driven LH","thermodynamic LH" /)
	labels					= labels(::-1)
	colors					= (/"green","green","green"/)
	dashes					= (/0.0, 1.0, 2.0 /)
	dashes					= dashes(::-1)
	lgres					= True
	lgres@vpWidthF			= 0.15
	lgres@vpHeightF			= 0.1
	;lgres@lbLabelJust		= "CenterLeft"
	lgres@lgPerimOn			= False
	lgres@lgMonoLineColor	= False
	lgres@lgLineColors		= colors
	lgres@lgMonoDashIndex	= False
	lgres@lgDashIndexes		= dashes
	lgres@lgLineThicknessF	= 2.0
	gsn_legend_ndc(wks,4,labels,0.35,0.4,lgres)

	labels					= (/ "SH","wind-driven SH","thermodynamic SH" /)
	labels					= labels(::-1)
	colors					= (/"gold","gold","gold"/)
	dashes					= (/0.0, 1.0, 2.0 /)
	dashes					= dashes(::-1)
	lgres					= True
	lgres@vpWidthF			= 0.15
	lgres@vpHeightF			= 0.1
	;lgres@lbLabelJust		= "CenterLeft"
	lgres@lgPerimOn			= False
	lgres@lgMonoLineColor	= False
	lgres@lgLineColors		= colors
	lgres@lgMonoDashIndex	= False
	lgres@lgDashIndexes		= dashes 
	lgres@lgLineThicknessF	= 2.0
	gsn_legend_ndc(wks,4,labels,0.55,0.4,lgres)

end do 	; season loop

end
