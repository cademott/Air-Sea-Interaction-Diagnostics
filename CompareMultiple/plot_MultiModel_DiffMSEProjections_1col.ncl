load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	print("=============== in plot_MultiModel_Means_1col.ncl =================")

	;------------- define season names
	seasonName 	= (/ "Nov-Apr", "May-Oct" /)

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	nRows		= toint(getenv("nRows"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabStrt")
	u850_overlay= getenv("u850_overlay")
	ColumnTitle	= getenv("ColumnTitle")
	print("PanelStrt="+PanelStrt)	
	print("nCases = " + nCases)
	print("varName = " + varName)
	print("u850_overlay = " + u850_overlay)
	print("ColumnTitle = " + ColumnTitle)

	;------------- set up plot panels, contours, labels, units
	;plot 		= new(nCases*2,graphic)   	; double the number to utilize left-column only
	plot 		= new(nCases+1,graphic)   	; double the number to utilize left-column only
	metafile	= "contours_Season_DiffMSEProjections_Maps.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	varID		= ind(vName.eq.varName)
	;print(vName)
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
	res@cnFillPalette			= "BlueWhiteOrangeRed"
	res@cnFillColors			= tointeger(fspan(20,234,12))
	res@gsnContourZeroLineThicknessF	= 0


	baseVar		= (/ "Vmse","Vdmdt" /)
	
	do b = 0,1

	do s = 0,1 				; do for each season

		;----------- set up plot file
		wksType = "pdf"
		wksName	= dirp + "MultiModel_DiffMSEProjections_1col." + baseVar(b) + "." + varName + "." + seasonName(s)
		wks = gsn_open_wks(wksType,wksName)		; open a ps file

		do n=0,nCases-1
				
			;------------- get case-specific environmental variables
			MODNAME		= "MODNAME"	+ tostring(n)
			MODDIR		= "MODDIR" + tostring(n)
			MODDATES	= "MODDATES"+ tostring(n)
			caseName	= getenv(MODNAME)
			diri		= getenv(MODDIR)
			dateRange	= getenv(MODDATES)		
			panelLabel	= str_sub_str(caseName,"_minus_"," - ")
			;print("panelLabel = " + panelLabel)
							
			;------------ read in the data
			fili			= diri + caseName + ".make_L3.1_regression_map." +  baseVar(b) + "." + varName + "." + seasonName(s) +".nc"
			f				= addfile(fili,"r")
			tName			= "regData"
			data_mean		= f->$tName$
			
			;------------ convert to familiar units
			if (baseVar(b).eq."Vmse") then
				data_mean		= data_mean * 100. * 86400.	; convert to % MSE per day
				data_mean@units	= "% ~F18~O~F14~m~F18~P~F21~ day~S2~-1"
				baseLabel		= "~F18~O~F14~m~F18~P~F21~"
			else
				data_mean		= data_mean * 100.			; convert to % dMSE/dt
				data_mean@units	= "% ~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F14~t"
				baseLabel		= "~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F14~t~F21~"
			end if

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

			;------------ make panel plots
			if (baseVar(b).eq."Vmse") then
				res@cnMinLevelValF		= cnMin(varID) * 0.5
				res@cnMaxLevelValF		= cnMax(varID) * 0.5
				res@cnLevelSpacingF		= cnInt(varID) * 0.5
			else
				res@cnMinLevelValF		= cnMin(varID)
				res@cnMaxLevelValF		= cnMax(varID)
				res@cnLevelSpacingF		= cnInt(varID) 
			end if			
			data_mean@long_name			= panelLabel
			;data_mean@units			= units(varID)
			plot(n)						= gsn_csm_contour_map_ce(wks,smth9_Wrap(data_mean,0.5,0.25,True),res)
	
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
		pID										= pStr(0:nCases-1)
		resP									= True
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
		resP@gsnPanelMainString					= label(varID) + " projection onto " + baseLabel + ", " + seasonName(s); add common title
		resP@gsnPanelMainFontHeightF			= 0.015
		gsn_panel(wks,plot,(/nRows,1/),resP)                		; now draw as one plot


		res@tmXBLabelsOn	= False ; turn off longitude labels for next season
		
	end do				; season loop
	
	end do				; base variable loop

end