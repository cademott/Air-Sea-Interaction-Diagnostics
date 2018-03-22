load "./Resources/contrib_AirSea.ncl"
;load "contrib_JJB.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"

begin
  
print("")
print("============= in plot_L3.5_MSE_PDF_lineplots.ncl =============")   

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
	wksType = pType
	wksName	= dirp + caseName + ".plot_L3.5_MSE_PDF_lineplots." + twStrt + "-" + twLast + "." + seasonName(s)
	print("--------- making "+wksName)
	wks 	= gsn_open_wks(wksType,wksName)		; open a ps file
	gsn_define_colormap(wks,"cmp_b2r")
	plot 	= new(4,graphic)					; create a plot array
	vLine	= new(4,graphic)
	hLine	= new(4,graphic)

	res					= True 				; plot mods desired
	res@gsnDraw			= False			; don't draw
	res@gsnFrame		= False			; don't advance frame
	;res@gsClipOn		= False			; don't clip lines
	res@tiXAxisString	= "MSE anomaly (1E7)"	; x axis title
	res@xyLineColors      = (/"red","blue","blue","blue","magenta","pink","green","gold"/)  ; line colors
	if (pType.eq."png") then
		thk		= 8.0
	else
		thk		= 2.0
	end if
	res@xyLineThicknesses = (/thk, thk, thk, thk, thk, thk, thk, thk /)        ; line thicknesses
	res@xyDashPatterns    = (/0.0, 0.0, 1.0, 2.0, 0,0, 0,0, 0.0, 0.0 /)        ; line patterns

	res@xyMarkLineModes   = (/"MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines","MarkLines"/) ; markers?
	res@xyMarkerColors    = res@xyLineColors    ; color
	res@xyMarkers         = (/16,16,16,16,16,16,16,16/)          ; style

	; resources for "PDF" variable
	resR                        = True                      
	resR@xyMarkLineModes        = "MarkLines"                   ; dashed line for 2nd
	resR@trYMinF				= 0
	resR@trYMaxF				= 40
	resR@xyMarkers        		= 16                   ; dashed line for 2nd
	resR@xyLineThicknesses      = thk                   ; thicker line
	resR@tiYAxisString 			= "%"   ; axis string
	resR@xyMarkerColors			= "gray"
	resR@xyLineColors			= "gray"

	;------------- plot resources for reference polylines
	PLres                  = True
	PLres@gsLineColor      = "black"
	if (pType.eq."png") then
		PLres@gsLineThicknessF = 2.0
	else
		PLres@gsLineThicknessF = 0.5
	end if

	;------------- read in the MSE binned data
	fili			= diri + caseName + ".make_L3.2_MSE_PDF_lineplots." + "10S-10N.60E-160E." + twStrt + "-" + twLast + "." + seasonName(s) + ".nc"
;							ERAI.Nov-Apr.make_L3.2_MSE_PDF_lineplots.19860101-20131231.10S-10N.60E-160E.nc
	;fili			= "/Users/demott/Dropbox/Work/AirSeaDiagPlots/ERAI.Nov-Apr.make_L3.2_MSE_PDF_lineplots.19860101-20131231.10S-10N.60E-160E.nc"
	f				= addfile(fili,"r")
	bins			= f->bins
	mse_pdf_ocn		= f->MSE_PDF_ocn
	vadv_mean_ocn	= f->Vomegadmdp_mean_ocn
	hadv_mean_ocn	= f->Vm_hadv_mean_ocn
	udmdx_mean_ocn	= f->Vudmdx_mean_ocn
	vdmdy_mean_ocn	= f->Vvdmdy_mean_ocn
	lw_mean_ocn		= f->Vlw_mean_ocn
	sw_mean_ocn		= f->Vsw_mean_ocn
	lh_mean_ocn		= f->LHFLX_mean_ocn
	sh_mean_ocn		= f->SHFLX_mean_ocn
	vadv_anom_ocn	= f->Vomegadmdp_anom_ocn
	hadv_anom_ocn	= f->Vm_hadv_anom_ocn
	udmdx_anom_ocn	= f->Vudmdx_anom_ocn
	vdmdy_anom_ocn	= f->Vvdmdy_anom_ocn
	lw_anom_ocn		= f->Vlw_anom_ocn
	sw_anom_ocn		= f->Vsw_anom_ocn
	lh_anom_ocn		= f->LHFLX_anom_ocn
	sh_anom_ocn		= f->SHFLX_anom_ocn

	mse_pdf_land	= f->MSE_PDF_land
	vadv_mean_land	= f->Vomegadmdp_mean_land
	hadv_mean_land	= f->Vm_hadv_mean_land
	udmdx_mean_land	= f->Vudmdx_mean_land
	vdmdy_mean_land	= f->Vvdmdy_mean_land
	lw_mean_land	= f->Vlw_mean_land
	sw_mean_land	= f->Vsw_mean_land
	lh_mean_land	= f->LHFLX_mean_land
	sh_mean_land	= f->SHFLX_mean_land
	vadv_anom_land	= f->Vomegadmdp_anom_land
	hadv_anom_land	= f->Vm_hadv_anom_land
	udmdx_anom_land	= f->Vudmdx_anom_land
	vdmdy_anom_land	= f->Vvdmdy_anom_land
	lw_anom_land	= f->Vlw_anom_land
	sw_anom_land	= f->Vsw_anom_land
	lh_anom_land	= f->LHFLX_anom_land
	sh_anom_land	= f->SHFLX_anom_land


	data_all = new((/9,dimsizes(bins)/),"float")
	data_all(0,:)=vadv_mean_ocn
	data_all(1,:)=hadv_mean_ocn
	data_all(2,:)=udmdx_mean_ocn
	data_all(3,:)=vdmdy_mean_ocn
	data_all(4,:)=lw_mean_ocn
	data_all(5,:)=sw_mean_ocn
	data_all(6,:)=lh_mean_ocn
	data_all(7,:)=sh_mean_ocn
	res@tiMainString	= "10S-10N; 60E-160E MSE budget (ocean)" ; title
	res@tiYAxisString	= "total field [W/m**2]"			; y axis title
	res@trYMinF			= -300
	res@trYMaxF			= 300
	res@trXMinF			= -5
	res@trXMaxF			= 5
	plot(0) = gsn_csm_xy2(wks,bins/1E7,data_all,mse_pdf_ocn,res,resR)          ; Draw an XY plot with 1 curve.
	vLine(0)= gsn_add_polyline(wks,plot(0),(/0,0/),(/ -500,500 /),PLres)
	hLine(0)= gsn_add_polyline(wks,plot(0),(/-5,5/),(/ 0,0 /),PLres)
	delete(data_all)

	data_all = new((/8,dimsizes(bins)/),"float")
	data_all(0,:)=vadv_mean_land
	data_all(1,:)=hadv_mean_land
	data_all(2,:)=udmdx_mean_land
	data_all(3,:)=vdmdy_mean_land
	data_all(4,:)=lw_mean_land
	data_all(5,:)=sw_mean_land
	data_all(6,:)=lh_mean_land
	data_all(7,:)=sh_mean_land
	res@tiMainString  = "10S-10N; 60E-160E MSE budget (land)" ; title
	res@tiYAxisString = "total field [W/m**2]"			; y axis title
	plot(1) = gsn_csm_xy2(wks,bins/1E7,data_all,mse_pdf_land,res,resR)          ; Draw an XY plot with 1 curve.
	vLine(1)= gsn_add_polyline(wks,plot(1),(/0,0/),(/ -500,500 /),PLres)
	hLine(1)= gsn_add_polyline(wks,plot(1),(/-5,5/),(/ 0,0 /),PLres)
	delete(data_all)

	data_all = new((/8,dimsizes(bins)/),"float")
	data_all(0,:)=vadv_anom_ocn
	data_all(1,:)=hadv_anom_ocn
	data_all(2,:)=udmdx_anom_ocn
	data_all(3,:)=vdmdy_anom_ocn
	data_all(4,:)=lw_anom_ocn
	data_all(5,:)=sw_anom_ocn
	data_all(6,:)=lh_anom_ocn
	data_all(7,:)=sh_anom_ocn
	res@tiMainString  = "10S-10N; 60E-160E MSE budget (ocean)" ; title
	res@tiYAxisString = "anomaly [W/m**2]"			; y axis title
	res@trYMinF			= -50
	res@trYMaxF			= 50
	plot(2) = gsn_xy(wks,bins/1E7,data_all,res)          ; Draw an XY plot with 1 curve.
	vLine(2)= gsn_add_polyline(wks,plot(2),(/0,0/),(/ -500,500 /),PLres)
	hLine(2)= gsn_add_polyline(wks,plot(2),(/-5,5/),(/ 0,0 /),PLres)
	delete(data_all)

	data_all = new((/8,dimsizes(bins)/),"float")
	data_all(0,:)=vadv_anom_land
	data_all(1,:)=hadv_anom_land
	data_all(2,:)=udmdx_anom_land
	data_all(3,:)=vdmdy_anom_land
	data_all(4,:)=lw_anom_land
	data_all(5,:)=sw_anom_land
	data_all(6,:)=lh_anom_land
	data_all(7,:)=sh_anom_land
	res@tiMainString  = "10S-10N; 60E-160E MSE budget (land)" ; title
	res@tiYAxisString = "anomaly [W/m**2]"			; y axis title
	plot(3) = gsn_xy(wks,bins/1E7,data_all,res)          ; Draw an XY plot with 1 curve.
	vLine(3)= gsn_add_polyline(wks,plot(3),(/0,0/),(/ -500,500 /),PLres)
	hLine(3)= gsn_add_polyline(wks,plot(3),(/-5,5/),(/ 0,0 /),PLres)
	delete(data_all)

	;------------- create plot page
	resP					= True                   ; modify the panel plot
	resP@gsnFrame			= False                  ; don't advance panel plot
	resP@gsnPanelLabelBar	= False                  ; add common colorbar
	resP@txString			= caseName+" "+seasonName(s)	       ; add common title
	resP@gsnPanelBottom		= 0.1                   ; add space at bottom
	resP@gsnPanelXWhiteSpacePercent = 5.0
	gsn_panel(wks,plot,(/2,2/),resP)               ; now draw as one plot

	labels					= (/ "VADV","HADV","uHADV","vHADV" /)
	labels					= labels(::-1)
	colors					= (/"red","blue","blue","blue"/)
	colors					= colors(::-1)
	dashes					= (/0.0, 0.0, 1.0, 2.0 /)
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
	lgres@lgLineThicknessF	= thk
	gsn_legend_ndc(wks,4,labels,0.35,0.1,lgres)

	labels					= (/ "LW","SW","LH","SH" /)
	labels					= labels(::-1)
	colors					= (/"magenta","pink","green","gold"/)
	colors					= colors(::-1)
	dashes					= (/ 0.0, 0.0, 0.0, 0.0 /)
	lgres					= True
	lgres@vpWidthF			= 0.15
	lgres@vpHeightF			= 0.1
	lgres@lgPerimOn			= False
	lgres@lgMonoLineColor	= False
	lgres@lgLineColors		= colors
	lgres@lgMonoDashIndex	= False
	lgres@lgDashIndexes		= dashes 
	lgres@lgLineThicknessF	= thk
	gsn_legend_ndc(wks,4,labels,0.55,0.1,lgres)

	if (wksType.eq."png") then
		frame(wks)
		trimPNG(wksName)
	end if

end do 	; season loop

end
























