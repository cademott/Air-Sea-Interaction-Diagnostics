load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "../Resources/contrib_AirSea.ncl"

begin

	print("=============== in plot_MultiModel_RainHovs_1col.ncl =================")
	
	;----------- suppress warnings?
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;------------- get global environmental variables
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
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)


	;------------- set up plot panels, contours, labels, units
	plot 		= new(nCases+1,graphic)   	; double the number to utilize left-column only
	dum			= new(nCases+1,graphic)
	;metafile	= "contours_Season_Mean_Maps.txt"
	;vName		= systemfunc("cut -d , -f1 "+metafile)
	;cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	;cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	;cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	;label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	;units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	;landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	;varID		= ind(vName.eq.searchName)

	;----------- set up plot file
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnLineLabelsOn			= False
	res@cnLineColor				= "grey60"
	res@gsnContourZeroLineThicknessF	= 0
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelsOn			= False
	res@tmXBLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.017         ; change maj lat tm spacing
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@cnFillPalette			= "BlueWhiteOrangeRed"
	res@cnFillColors			= tointeger(fspan(20,234,12))
	res@cnMinLevelValF			= -0.5
	res@cnMaxLevelValF			=  0.5
	res@cnLevelSpacingF			=  0.1
	res@vpWidthF				= 0.8
	res@vpHeightF				= 0.4
	res@tmXBLabelFontHeightF 	= 0.025		
	res@tmYLLabelFontHeightF 	= 0.025		
	res@lbLabelBarOn			= False
	res@gsnStringFontHeightF	= 0.03

	;------------- plot resources for map marker
	polyres						= True
	polyres@gsMarkerIndex		= 16
	polyres@gsMarkerSizeF		=  5.
	polyres@gsMarkerColor		= "chartreuse2"	

	;----------- set up plot file
	wksType = pType
	wksName	= dirp + FNPrefix + ".MultiModel_RainHovs_1col." + varName + "." + "Nov-Apr"
	wks = gsn_open_wks(wksType,wksName)		; open a ps file

	do n=0,nCases-1
			
		if (n.eq.0) then
			seasonID	= "Nov-Apr"
		else
			seasonID	= "Nov-Apr"
		end if

		;------------- get case-specific environmental variables
		MODNAME		= "MODNAME"	+ tostring(n)
		MODDIR		= "MODDIR" + tostring(n)
		MODDATES	= "MODDATES"+ tostring(n)
		caseName	= getenv(MODNAME)
		diri		= getenv(MODDIR) + "/proc/"
		dateRange	= getenv(MODDATES)		
		;print("caseName = " + caseName)
		;print("dateRange = " + dateRange)
						
		;------------ read in the data
		fili			= diri + caseName + ".make_L2.1_regression_propagation." + dateRange + ".PRECT." + varName + "." + seasonID + ".nc"
		f				= addfile(fili,"r")
		dNames			= getfilevardims(f,varName) 
		tdata			= rm_single_dims(f->$varName$)
		data			= rm_single_dims(tdata(0,:,:))
		;printVarSummary(data)
	
		;------------ turn on longitude labels for bottom panels
		if (n.eq.nCases-1) then
			res@tmXBLabelsOn			= True
		end if
		
		;printMinMax(data,True)

		;------------ panel counter
		if (n.eq.0) then
			pnum	= 0
		end if
		;if (n.eq.1) then
		;	pnum	= 2
		;end if
		if (n.ge.1) then
			pnum	= pnum + 1
		end if
		;print("pnum = " + pnum)

		;------------ make panel plots
		data@long_name			= caseName
		;data@units				= units(varID)
		pdata					= smth9_Wrap(data,0.5,0.25,True)
		;if ((pnum/2)*2.eq.pnum) then
			res@tmYLLabelsOn			= True
			res@tiYAxisString			= "lag (days)"
		;else
		;	res@tmYLLabelsOn			= False
		;	res@tiYAxisString			= ""
		;end if

		plot1				= gsn_csm_contour(wks,pdata({-20:20},{60:180}),res)
		dum(n)				= gsn_add_polymarker(wks,plot1,90,0,polyres)
		plot(pnum)			= plot1
		delete(tdata)
		delete(pdata)
		delete(data)
		delete(dNames)
		delete(plot1)

		
	end do
		
		;------------- create plot page
		;pStr		= (/"a","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
		pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
;		nPanels		= nCases*2
;		pID			= new(nPanels,"string")
;		print("nPanels = "+nPanels)
;		do i=0,nPanels/2-1
;			pID(i*2)	= pStr(i)
;			pID(i*2+1)	= pStr(i+nPanels/2)
;		end do
		pID										= pStr(0:nCases-1)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		;resP@gsnPanelMainString					= "; add common title
		resP@gsnPanelRight						= 0.995
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= PanelFontHt
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= LabelBarFontHt
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.25               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.02              ; default is taller
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)
			trimPNG(wksName)
		end if
		
		print("plot file = " + wksName)

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		

end