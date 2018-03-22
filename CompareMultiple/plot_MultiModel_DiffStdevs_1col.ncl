load "/Users/demott/Dropbox/ncl/contrib_CAD.ncl"   

begin

	print("=============== in plot_MultiModel_Means_1col.ncl =================")

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabStrt")
	u850_overlay= getenv("u850_overlay")
	wksType		= getenv("wksType")
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)
	print("u850_overlay = " + u850_overlay)

	;------------- set up plot panels, contours, labels, units
	;plot 		= new(nCases*2,graphic)   	; double the number to utilize left-column only
	plot 		= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile	= "contours_Season_DiffStdev_Maps.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	varID		= ind(vName.eq.varName)
	print("cmin = " + cnMin(varID))
	print("cmax = " + cnMax(varID))
	print("cint = " + cnInt(varID))
	;print(label)
	;print(units)
	;print(strlen(label))
		              	
	;------------- plot resources for base plot
	res                     	= True
	res@gsnDraw 				= False			; don't draw
	res@gsnFrame				= False			; don't advance frame
	res@cnLineLabelsOn			= False
	res@cnInfoLabelOn			= False 		; turn off cn info label
	res@cnFillOn				= True			; turn on color
	res@cnLinesOn				= True			; turn off contour lines
	res@cnLineColor				= "grey60"
	res@gsnSpreadColors			= True			; spread out color table
	res@gsnSpreadColorStart		= 2 
	res@gsnSpreadColorEnd		= -3 
	res@tmXBLabelsOn			= False
	res@tmXBLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@tmYLLabelFontHeightF	= 0.019         ; change maj lat tm spacing
	res@mpMinLatF				= -30.
	res@mpMaxLatF				=  30.
	res@mpMinLonF 				=  30.
	res@mpMaxLonF				= 240.
	res@mpCenterLonF			= 135. 
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@lbLabelBarOn			= False
	res@gsnContourZeroLineThicknessF	= 0

	;------------- plot resources for u850 overlay plot
	ures                     	= True
	ures@gsnDraw				= False
	ures@gsnFrame				= False
	ures@cnFillOn				= False			; turn off color
	ures@cnLinesOn				= True			; turn on contour lines
	ures@cnLineColor			= "Black"
	ures@cnLineThicknessF		= 2.0
	ures@cnInfoLabelOn			= False
	ures@cnLineLabelsOn			= False
	ures@cnLevels				= (/ -2., -1., 1., 2. /)
	ures@cnLevelSelectionMode	= "ExplicitLevels"   
	ures@tiXAxisOn				= False
	ures@tiYAxisOn				= False
	ures@tiMainOn				= False
	ures@gsnContourNegLineDashPattern = 1

	do s = 0,1 				; do for each season

		;----------- set up plot file
		;wksType = "pdf"
		wksName	= dirp + "MultiModel_DiffStdDev_1col." + varName + "." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file
		gsn_define_colormap(wks,"MPL_rainbow")

		do n=0,nCases-1
				
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR)
			dateRange	= getenv(MODDATES)		
			;panelLabel	= getenv(PanelLabel)
			panelLabel	= str_sub_str(caseName,"_minus_"," - ")
			print("panelLabel = " + panelLabel)
			;print("caseName = " + caseName)
			
			;----------- read in seasonal mean u850 wind
			fili	= diri + caseName + ".make_L1.3a_mean_u850.u850_SeasonMean." + seasonName(s) + ".nc"
			f		= addfile(fili,"r")
			ubar	= f->u850_SeasonMean
			ubar@long_name	= " "
			ubar@units		= " "
				
			;------------ read in the data
			fili_prefix		= diri + caseName + ".make_L1.4_mean_stdev_map."
			if (varName.eq."PW") then
				fili_prefix	= diri + caseName + ".make_2D_SeasonMeanMaps."
			end if
			;fili_prefix		= diri + caseName + ".make_L1.4_mean_stdev_map."
			fili_suffix		= "." + seasonName(s) + ".nc"
			fili			= fili_prefix + varName + fili_suffix
			f				= addfile(fili,"r")
			tName			= varName + "_stdev"
			data_mean		= f->$tName$

			;------------ define land mask
			if (landmask(varID).eq."mask") then
				lon		= f->lon
				lat		= f->lat			
				a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
				lsdata	= a->LSMASK
				lsm		= landsea_mask(lsdata,lat,lon)
				data_mean	= mask(data_mean,lsm.ge.1,False)
				delete(lat)
				delete(lon)
				delete(lsm)
			end if
		
			;------------ turn on longitude labels for bottom panels
			if (n.eq.nCases-1) then
				res@tmXBLabelsOn			= True
			end if

			;------------ define color table
			if (varName.eq."PRECT") then
				res@cnFillPalette			= "precip_diff_12lev"
				res@cnFillColors			= (/ 2,3,4,5,6,8,8,10,11,12,13,14 /) - 2
			else
				res@cnFillPalette			= "BlueWhiteOrangeRed"
				res@cnFillColors			= tointeger(fspan(20,234,12))
			end if

			;------------ make panel plots
			res@cnMinLevelValF		= cnMin(varID)
			res@cnMaxLevelValF		= cnMax(varID)
			res@cnLevelSpacingF		= cnInt(varID) 
			data_mean@long_name		= panelLabel
			data_mean@units			= units(varID)
			plot1					= gsn_csm_contour_map_ce(wks,data_mean,res)
	
			;------------ overlay U850?
			if (u850_overlay.eq."True".or.u850_overlay.eq."true") then
				;----------- create the overlay plot
				plot1	= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_mean,0.5,0.25,True),res)
				uplot1	= gsn_csm_contour(wks,smth9_Wrap(ubar,0.5,0.25,True),ures)
				overlay(plot1,uplot1)
				plot(n)	= plot1
				delete(plot1)
				delete(uplot1)
			else
				plot(n)	= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_mean,0.5,0.25,True),res)
			end if

			delete(ubar)
			delete(data_mean)
			
		end do
		
		;------------- create plot page
		pID		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
;		nPanels		= nCases*2
;		pID			= new(nPanels,"string")
;		print("nPanels = "+nPanels)
;		do i=0,nPanels/2-1
;			pID(i*2)	= pStr(i)
;			pID(i*2+1)	= pStr(i+nPanels/2)
;		end do
		;pID										= pStr(PanelStrt::)
		resP									= True                   	; modify the panel plot
		resP@gsnFrame							= False                  	; don't advance panel plot
		resP@gsnPanelMainString					= "stdev " + label(varID) + ", " + seasonName(s); add common title
		resP@gsnPanelBottom						= 0.05                   	; add space at bottom
		resP@gsnPanelYWhiteSpacePercent 		= 4
		resP@gsnPanelFigureStrings 				= pID      
		resP@gsnPanelFigureStringsFontHeightF	= 0.015
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= .009
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.4               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.04              ; default is taller
		resP@lbLabelFontHeightF    				= .01               ; default is HUGE
		gsn_panel(wks,plot,(/nCases,1/),resP)                		; now draw as one plot

		if (wksType.eq."png") then
			frame(wks)   ; Advance the frame.
			trimPNG(wksName)
		end if

		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	end do				; season loop

end