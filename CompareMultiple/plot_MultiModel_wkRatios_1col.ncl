load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_MultiModel_wkRatios_1col.ncl =================")

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	;nRows		= toint(getenv("nRows"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabStrt")
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)

		              	
	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnFillMode 				= "RasterFill"
	res@cnLinesOn				= False			; turn off contour lines
	res@cnSpanFillPalette		= True
	res@tmXBLabelsOn			= True
	res@lbOrientation			= "Vertical"	; vertical label bar
	res@tmXBLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@cnLevelSelectionMode	= "ExplicitLevels"   
	res@cnFillPalette			= "BlueWhiteOrangeRed"
	res@cnLevels				= (/ 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1., 1.1, 1.2, 1.4, 1.7, 2.0, 2.4, 2.8 /) ; ratios
	;res@cnLevels				= fspan(-.3,.3,11)
	;res@cnLevels				= fspan(-50,50,11) ; percent differences

	;------------- plot resources for dispersion curves
	dcres 					= True
	dcres@gsLineThicknessF	= 1.0
	dcres@gsLineDashPattern	= 0
	dumS = new( (/9,nCases/),graphic)
	dumA = new( (/9,nCases/),graphic)
	
	;----------- set up plot file
	wksType = "pdf"
	wksName	= dirp + "MultiModel_wkRatio_SYM_1col_ratio." + varName
	wksSYM	= gsn_open_wks(wksType,wksName)		; open a ps file
	plotSYM = new(2*(nCases-1),graphic)                 	
	print("plot file = " + wksName)

	wksName	= dirp + "MultiModel_wkRatio_ASYM_1col_ratio." + varName
	wksASYM	= gsn_open_wks(wksType,wksName)		; open a ps file
	plotASYM= new(2*(nCases-1),graphic)                 	
	print("plot file = " + wksName)

	n=0
	;------------- read in FIRST (CTRL or OBS) wk data
	MODNAME		= "MODNAME"	+ tostring(n)
	MODDIR		= "MODDIR" + tostring(n)
	MODDATES	= "MODDATES"+ tostring(n)
	SHORTNAME	= "SHORTNAME" + tostring(n)
	ctrlName	= getenv(MODNAME)
	diri		= getenv(MODDIR) + "/proc/"
	dateRange	= getenv(MODDATES)
	ctrlSNAME	= getenv(SHORTNAME)
	f			= addfile(diri + ctrlName + "." + varName + "." + dateRange + ".wkSpaceTime.nc","r")
	ctrlPWR_sym	= f->FIG_3_SYM ; log10(symmetric power)	
	ctrlPWR_asym= f->FIG_3_ASYM ; log10(symmetric power)	
	printMinMax(ctrlPWR_sym,True)
	printMinMax(ctrlPWR_asym,True)
	;printVarSummary(ctrlPWR_sym)
	
	;------------- get the dispersion curves
  	fillVal			= 1e20           ; miscellaneous
	rlat			= 0.0
	Ahe				= (/50.,25.,12./)
	nWaveType		= 6
	nPlanetaryWave	= 50
	nEquivDepth		= dimsizes(Ahe)
	Apzwn			= new((/nWaveType,nEquivDepth,nPlanetaryWave/),"double",fillVal)
	Afreq			= Apzwn
	genDispersionCurves(nWaveType, nEquivDepth, nPlanetaryWave, rlat, Ahe, Afreq, Apzwn )
;	print("nWaveType = " + nWaveType)
;	print("nEquivDepth = " + nEquivDepth)
;	print("nPlanetaryWave = " + nPlanetaryWave)
;	
;	printVarSummary(ctrlPWR_sym)
;	printVarSummary(Apzwn)
;	printVarSummary(Afreq)

	do n=1,nCases-1
	;do n=1,2
			
		;------------- read in experiment wk data
		MODNAME		= "MODNAME"	+ tostring(n)
		MODDIR		= "MODDIR" + tostring(n)
		MODDATES	= "MODDATES"+ tostring(n)
		SHORTNAME	= "SHORTNAME" + tostring(n)
		expName		= getenv(MODNAME)
		expSNAME	= getenv(SHORTNAME)
		diri		= getenv(MODDIR) + "/proc/"
		dateRange	= getenv(MODDATES)		
		f			= addfile(diri + expName + "." + varName + "." + dateRange + ".wkSpaceTime.nc","r")
		expPWR_sym	= f->FIG_3_SYM ; log10(symmetric power)	
		expPWR_asym	= f->FIG_3_ASYM ; log10(symmetric power)

		;------------- compute power ratio
		ratio_sym		= 10.^(expPWR_sym) / 10.^(ctrlPWR_sym)
		ratio_sym@long_name	= expName + " / " + ctrlName + " rainfall"
		;ratio_sym		= 100. * (smth9_Wrap(10.^(expPWR_sym),0.5,0.25,True) - smth9_Wrap(10.^(ctrlPWR_sym),0.5,0.25,True)) / smth9_Wrap(10.^(ctrlPWR_sym),0.5,0.25,True)
		;ratio_sym@long_name	= expSNAME + " - " + ctrlSNAME + ":  " + varName + " % change"
		copy_VarCoords(ctrlPWR_sym,ratio_sym)
		ratio_sym		= smth9_Wrap(ratio_sym,0.5,0,True)
		printMinMax(expPWR_sym,True)
	
		ratio_asym		= 10.^(expPWR_asym) / 10.^(ctrlPWR_asym)
		ratio_asym@long_name	= expName + " / " + ctrlName + " rainfall"
		;ratio_asym		= 100. * (smth9_Wrap(10.^(expPWR_asym),0.5,0.25,True) - smth9_Wrap(10.^(ctrlPWR_asym),0.5,0.25,True)) / smth9_Wrap(10.^(ctrlPWR_asym),0.5,0.25,True)
		;ratio_asym@long_name	= expSNAME + " - " + ctrlSNAME + ":  " + varName + " % change"
		copy_VarCoords(ctrlPWR_asym,ratio_asym)
		ratio_asym		= smth9_Wrap(ratio_asym,0.5,0,True)
		printMinMax(expPWR_asym,True)

		plot		= gsn_csm_contour(wksSYM,ratio_sym,res)
		dumS(0,n)=gsn_add_polyline(wksSYM,plot,Apzwn(3,0,:),Afreq(3,0,:),dcres)
		dumS(1,n)=gsn_add_polyline(wksSYM,plot,Apzwn(3,1,:),Afreq(3,1,:),dcres)
		dumS(2,n)=gsn_add_polyline(wksSYM,plot,Apzwn(3,2,:),Afreq(3,2,:),dcres)
		dumS(3,n)=gsn_add_polyline(wksSYM,plot,Apzwn(4,0,:),Afreq(4,0,:),dcres)
		dumS(4,n)=gsn_add_polyline(wksSYM,plot,Apzwn(4,1,:),Afreq(4,1,:),dcres)
		dumS(5,n)=gsn_add_polyline(wksSYM,plot,Apzwn(4,2,:),Afreq(4,2,:),dcres)
		dumS(6,n)=gsn_add_polyline(wksSYM,plot,Apzwn(5,0,:),Afreq(5,0,:),dcres)
		dumS(7,n)=gsn_add_polyline(wksSYM,plot,Apzwn(5,1,:),Afreq(5,1,:),dcres)
		dumS(8,n)=gsn_add_polyline(wksSYM,plot,Apzwn(5,2,:),Afreq(5,2,:),dcres)
		plotSYM(2*(n-1))		=	plot

		plotASYM(2*(n-1))		= gsn_csm_contour(wksASYM,ratio_asym,res)
		dumA(0,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(0,0,:),Afreq(0,0,:),dcres)
		dumA(1,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(0,1,:),Afreq(0,1,:),dcres)
		dumA(2,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(0,2,:),Afreq(0,2,:),dcres)
		dumA(3,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(1,0,:),Afreq(1,0,:),dcres)
		dumA(4,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(1,1,:),Afreq(1,1,:),dcres)
		dumA(5,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(1,2,:),Afreq(1,2,:),dcres)
		dumA(6,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(2,0,:),Afreq(2,0,:),dcres)
		dumA(7,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(2,1,:),Afreq(2,1,:),dcres)
		dumA(8,n)=gsn_add_polyline(wksASYM,plotASYM(2*(n-1)),Apzwn(2,2,:),Afreq(2,2,:),dcres)
		
		print(" ")
		print("-------------------------")
	
		;;------------ turn on longitude labels for bottom panels
		if (n.eq.nCases-1) then
		res@tmXBLabelsOn			= True
		end if

	end do
			
	;------------- create plot page
	pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
	resP					= True                   	; modify the panel plot
	resP@gsnFrame			= False                  	; don't advance panel plot
	resP@gsnPanelLabelBar	= False                  	; add common colorbar
	resP@gsnPanelBottom		= 0.05                   	; add space at bottom
	resP@gsnPanelYWhiteSpacePercent = 5
	;resP@gsnPanelFigureStrings = pStr(PanelStrt,PanelStrt+nCases-1)     ; add letter labels to panels (# letters can be > # panels)
	resP@gsnPanelFigureStringsFontHeightF	= 0.012
	resP@gsnPanelFigureStringsPerimOn		= True
	resP@amJust								= "TopLeft"
	gsn_panel(wksSYM,plotSYM,(/nCases-1,2/),resP)                	; now draw as one plot
	gsn_panel(wksASYM,plotASYM,(/nCases-1,2/),resP)                	; now draw as one plot



end