load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

	print("=============== in plot_MultiModel_RainHovs_2col_plusOne.ncl =================")
	
	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabelStrt")
	print("nCases = " + nCases)
	;if (varName.eq."PW_GradLonEq_AnnCyc".or.varName.eq."PW_GradLonS_AnnCyc".or.varName.eq."PW_GradLatN_AnnCyc".or.varName.eq."PW_GradLatS_AnnCyc") then
	;	searchName= "PWgrad"
	;	factor	= 1E6
	;end if
	;if (varName.eq."PW_AnnCyc_lon") then
	;	searchName= "PW_AnnCyc_lon"
	;	factor	= 1.
	;end if


	;------------- set up plot panels, contours, labels, units
	plot 		= new(nCases+1,graphic)   	; double the number to utilize left-column only
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

	;----------- set up plot file
	wksType = "pdf"
	wksName	= dirp + "MultiModel_RainHovs_2col_plusONE." + varName 
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
		;print(dNames)
		;lonName			= "lon"
		tdata			= rm_single_dims(f->$varName$)
		data			= rm_single_dims(tdata(0,:,:))
		;printVarSummary(data)
	
		;------------ turn on longitude labels for bottom panels
		if (n.eq.nCases-2) then
			res@tmXBLabelsOn			= True
		end if
		
		printMinMax(data,True)

		;------------ panel counter
		if (n.eq.0) then
			pnum	= 0
		end if
		if (n.eq.1) then
			pnum	= 2
		end if
		if (n.ge.2) then
			pnum	= pnum + 1
		end if
		print("pnum = " + pnum)

		;------------ make panel plots
		data@long_name			= caseName
		;data@units				= units(varID)
		pdata					= smth9_Wrap(data,0.5,0.25,True)
		if ((pnum/2)*2.eq.pnum) then
			res@tmYLLabelsOn			= True
			res@tiYAxisString			= "lag (days)"
		else
			res@tmYLLabelsOn			= False
			res@tiYAxisString			= ""
		end if

		plot(pnum)				= gsn_csm_contour(wks,pdata({-20:20},{60:180}),res)
		delete(tdata)
		delete(pdata)
		delete(data)
		delete(dNames)

		
	end do
		
		;------------- create plot page
		pStr		= (/"a","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" /)
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
		resP@gsnPanelFigureStringsFontHeightF	= 0.015
		resP@gsnPanelFigureStringsPerimOn		= True
		resP@amJust								= "TopLeft"
		resP@gsnPanelLabelBar					= True
		resP@lbLabelFontHeightF					= .009
		resP@lbAutoManage          				= False             ; we control label bar
		resP@lbOrientation         				= "Horizontal"      ; ncl default is vertical
		resP@pmLabelBarWidthF     				= 0.6               ; default is shorter
		resP@pmLabelBarHeightF     				= 0.04              ; default is taller
		resP@lbLabelFontHeightF    				= .01               ; default is HUGE
		gsn_panel(wks,plot,(/(nCases+1)/2,2/),resP)                		; now draw as one plot


		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		

end