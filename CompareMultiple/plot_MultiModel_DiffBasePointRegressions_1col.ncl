load "/Users/demott/Dropbox/ncl/contrib_CAD.ncl"
begin

	print("=============== in plot_MultiModel_Means_1col.ncl =================")

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	nRows		= toint(getenv("nRows"))
	dirp		= getenv("dirp")	
	baseVar		= getenv("BaseVar")
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabStrt")
	ColumnTitle	= getenv("ColumnTitle")
	wksType		= getenv("wksType")
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)
	print("ColumnTitle = " + ColumnTitle)

	;------------- set up plot panels, contours, labels, units
	;plot 		= new(nCases*2,graphic)   	; double the number to utilize left-column only
	plot 		= new(nCases,graphic)   	; double the number to utilize left-column only
	metafile	= "contours_BasePointRegression_Maps.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	smooth		= str_left_strip(systemfunc("cut -d , -f8 "+metafile))
	varID		= ind(vName.eq.varName)
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
	
	baselon		= (/ 70, 90, 110, 130, 150 /)

	do s = 0,1 				; do for each season

		do b = 0,4 			; do for each base point

			;----------- set up plot file
			;wksType = "pdf"
			wksName	= dirp + "MultiModel_DiffBasePointRegressions_1col." + varName + "." + baselon(b) + "E." + seasonName(s)
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
				fili		= diri + caseName + ".make_L2.5_regression_basepoint." + baseVar + "." + varName + "." + seasonName(s) + ".nc"
				;print("fili = " + fili)
				f			= addfile(fili,"r")
				tName		= varName + "_reg"
				data_mean	= f->$tName$(b,:,:)
				;printVarSummary(data_mean)
		
				;------------ turn on longitude labels for bottom panels
				if (n.eq.nCases-1) then
					res@tmXBLabelsOn			= True
				end if

				;------------ define color table
				if (varName.eq."PRECT".or.varName.eq."PW".or.varName.eq."omegadqdp850") then
					res@cnFillPalette			= "precip_diff_12lev"
					res@cnFillColors			= (/ 2,3,4,5,6,8,8,10,11,12,13,14 /) - 2
				else
					res@cnFillPalette			= "BlueWhiteOrangeRed"
					res@cnFillColors			= tointeger(fspan(20,234,12))
				end if

				;------------ make panel plots
				res@cnMinLevelValF		= cnMin(varID) * 0.25
				res@cnMaxLevelValF		= cnMax(varID) * 0.25
				res@cnLevelSpacingF		= cnInt(varID) * 0.25
				;printVarSummary(data_mean)
				;printVarSummary(varID)
				;printVarSummary(smooth)
				data_mean@long_name		= panelLabel
				data_mean@units			= units(varID)
				if (smooth(varID).eq."smooth") then
					data_mean	= smth9_Wrap(data_mean,0.5,0.25,True)
				end if
				plot(n)	= gsn_csm_contour_map_ce(wks,data_mean,res)

				delete(data_mean)
			
			end do
		
			;------------- create plot page
			pStr		= (/"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
	;		nPanels		= nCases*2
	;		pID			= new(nPanels,"string")
	;		print("nPanels = "+nPanels)
	;		do i=0,nPanels/2-1
	;			pID(i*2)	= pStr(i)
	;			pID(i*2+1)	= pStr(i+nPanels/2)
	;		end do

			pID										= pStr(tointeger(PanelStrt)::)
			resP									= True                   	; modify the panel plot
			resP@gsnFrame							= False                  	; don't advance panel plot
			if (ColumnTitle.eq."False") then
				resP@gsnPanelMainString				= " "
			else
				resP@gsnPanelMainString				= label(varID) + ", " + seasonName(s); add common title
			end if
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
			gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot

			if (wksType.eq."png") then
				frame(wks)
				trimPNG(wksName)
			end if


			res@tmXBLabelsOn	= False ; turn off longitude labels for next season
			
		end do 			; base longitude llop
		
	end do				; season loop

end