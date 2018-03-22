load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/diagnostics_cam.ncl"    
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

begin

	print("=============== in plot_MultiModel_AnnCyc_2col_plusOne.ncl =================")
	
	AnnAnom		= True

	;------------- get global environmental variables
	nCases		= toint(getenv("nCases"))
	dirp		= getenv("dirp")	
	varName		= getenv("varName")	
	PanelStrt	= getenv("panelLabelStrt")
	print("nCases = " + nCases)
	if (varName.eq."PW_GradLonEq_AnnCyc".or.varName.eq."PW_GradLonS_AnnCyc".or.varName.eq."PW_GradLatN_AnnCyc".or.varName.eq."PW_GradLatS_AnnCyc") then
		searchName= "PWgrad"
		factor	= 1E6
	end if
	if (varName.eq."PW_AnnCyc_lon") then
		searchName= "PW_AnnCyc_lon"
		factor	= 1.
	end if


	;------------- set up plot panels, contours, labels, units
	plot 		= new(nCases+1,graphic)   	; double the number to utilize left-column only
	metafile	= "contours_Season_Mean_Maps.txt"
	vName		= systemfunc("cut -d , -f1 "+metafile)
	cnMin		= tofloat(systemfunc("cut -d , -f2 "+metafile)) 
	cnMax		= tofloat(systemfunc("cut -d , -f3 "+metafile)) 
	cnInt		= tofloat(systemfunc("cut -d , -f4 "+metafile)) 
	label		= str_left_strip(systemfunc("cut -d , -f5 "+metafile))
	units		= str_left_strip(systemfunc("cut -d , -f6 "+metafile))
	landmask	= str_left_strip(systemfunc("cut -d , -f7 "+metafile))
	varID		= ind(vName.eq.searchName)

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
	res@cnLevelSelectionMode	= "ManualLevels"   
	res@lbLabelBarOn			= False
	res@vpWidthF				= 0.8
	res@vpHeightF				= 0.4
	res@gsnContourZeroLineThicknessF	= 0

	;------------- plot resources for MJO_amp overlay plot
	Mres                     	= True
	Mres@gsnDraw				= False
	Mres@gsnFrame				= False
	Mres@cnLineLabelsOn			= True
	Mres@cnInfoLabelOn			= False
	Mres@cnFillOn				= False			; turn off color
	Mres@cnLinesOn				= True			; turn on contour lines
	Mres@cnLineColor			= "Black"
	Mres@cnLineThicknessF		= 2.
	Mres@cnLevels				= fspan(2.,10.,9)
	Mres@cnLevelSelectionMode	= "ExplicitLevels"   
	Mres@tiXAxisOn				= False
	Mres@tiYAxisOn				= False
	Mres@tiMainOn				= False
	Mres@vpWidthF				= 0.8
	Mres@vpHeightF				= 0.4

	;----------- set up plot file
	wksType = "pdf"
	wksName	= dirp + "MultiModel_AnnCyc_2col_plusONE." + varName 
	if (AnnAnom) then
		wksName	= wksName + "_AnnAnom"
	end if
	wks = gsn_open_wks(wksType,wksName)		; open a ps file
	if (varName.eq."PW_AnnCyc_lon") then
		gsn_define_colormap(wks,"MPL_rainbow")
	else
		gsn_define_colormap(wks,"BlueWhiteOrangeRed")
	end if

	do n=0,nCases-1
			
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
		fili			= diri + caseName + ".PW." + dateRange + ".AnnCyc.nc"
		f				= addfile(fili,"r")
		dNames			= getfilevardims(f,varName) 
		;print(dNames)
		lonName			= dNames(1)
		tName			= varName
		data			= f->$tName$
		data			= data * factor
		MJOamp			= f->MJO_amp
	
		;------------ turn on longitude labels for bottom panels
		if (n.eq.nCases-2) then
			res@tmXBLabelsOn			= True
		end if
		
		copy_VarCoords(data,MJOamp)
		printMinMax(data,True)
		;printMinMax(MJOamp,True)

		datap				= new( (/ dimsizes(data&year_day),dimsizes(data&$lonName$) /),typeof(data))
		datap				= (/ data /)
		datap!0				= "time"
		datap&time			= tofloat(data&year_day)-1
		datap&time@units	= "days since 1998-01-01"
		datap!1				= "lon"
		datap&lon			= data&$lonName$
		TIME				= cd_calendar(datap&time,0)
		YEAR				= TIME(:,0)
		MONTH				= TIME(:,1)
		DAY					= TIME(:,2)
		latter				= ind(MONTH.ge.7)
		nLatter				= dimsizes(latter)
		;printMinMax(latter,True)
		YEARs				= YEAR
		YEAR(latter)		= YEAR(latter) - 1.

		MJOampp				= new( (/ dimsizes(MJOamp&year_day),dimsizes(MJOamp&$lonName$) /),typeof(MJOamp))
		MJOampp				= (/ MJOamp /)
		MJOampp!0			= "time"
		MJOampp&time		= tofloat(MJOamp&year_day)-1
		MJOampp&time@units	= "days since 1998-01-01"
		MJOampp!1			= "lon"
		MJOampp&lon			= MJOamp&$lonName$

		;----- shift day of year so starts on June 1
		ndays				= dimsizes(YEAR)		
		temp							= datap
		temp(0:nLatter-1,:)				= datap(latter,:)
		temp(nLatter:ndays-1,:)			= datap(0:latter(0),:)
		datap							= temp
		delete(temp)
		datap&time						= ispan(0,ndays-1,1)
		datap&time@units				= "days since 1997-07-01"
		datap@long_name					= caseName
		datap@units						= units(varID)

		temp							= MJOampp
		temp(0:nLatter-1,:)				= MJOampp(latter,:)
		temp(nLatter:ndays-1,:)			= MJOampp(0:latter(0),:)
		MJOampp							= temp
		delete(temp)
		MJOampp&time					= ispan(0,ndays-1,1)			
		MJOampp&time@units				= "days since 1997-07-01"

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
		if (n.eq.0.and.(varName.eq."PW_GradLatN_AnnCyc".or.varName.eq."PW_GradLatS_AnnCyc")) then
			cnMin(varID)		= cnMin(varID)*5.
			cnMax(varID)		= cnMax(varID)*5.
			cnInt(varID)		= cnInt(varID)*5.
		end if
		res@cnMinLevelValF		= cnMin(varID)
		res@cnMaxLevelValF		= cnMax(varID)
		res@cnLevelSpacingF		= cnInt(varID) 
		print("contour min = "+cnMin(varID))
		print("contour max = "+cnMax(varID))
		data@long_name			= caseName
		data@units				= units(varID)
		restick 				= True
		restick@ttmFormat 		= "%c"
		restick@ttmAxis = "YL"
		;restick@ttmMajorStride = 31
		time_axis_labels(datap&time,res,restick) ; call the formatting procedure
		datap					= runave_n_Wrap(datap,21,-1,0)
		if (AnnAnom) then
			datap				= datap - conform(datap,dim_avg_n_Wrap(datap,0),1)
			res@cnMinLevelValF		= -10.
			res@cnMaxLevelValF		=  10.
			res@cnLevelSpacingF		=   2.
		end if
		printMinMax(datap(:,{30:240}),True)
		plot1					= gsn_csm_contour(wks,smth9_Wrap(datap(:,{30:240}),0.5,0.25,True),res)
		time_axis_labels(MJOampp&time,Mres,restick) ; call the formatting procedure
		MJOampp					= runave_n_Wrap(MJOampp,21,-1,0)
		if (AnnAnom) then
			MJOampp				= MJOampp - conform(MJOampp,dim_avg_n_Wrap(MJOampp,0),1)
			Mres@cnLevels		= fspan(5.,5.,9)
			Mres@gsnContourZeroLineThicknessF	= 0
			Mres@gsnContourNegLineDashPattern = 1
		end if
		printMinMax(MJOampp(:,{30:240}),True)
		Mplot					= gsn_csm_contour(wks,smth9_Wrap(MJOampp(:,{30:240}),0.5,0.25,True),Mres)
		overlay(plot1,Mplot)
		plot(pnum)					= plot1
		delete(plot1)
		delete(Mplot)
		delete(data)
		delete(MJOamp)
		delete(datap)
		delete(MJOampp)
		
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
		resP@gsnPanelMainString					= label(varID) + ", MJO ampliutde mean annual cycle"; add common title
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