load "./Resources/contrib_AirSea.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
  
begin
                           
	print("")
	print("============= in plot_L3.4_SSTeffectSummary.ncl =============")   

	;----------- retrieve required environment variables	
	debug		= getenv("DEBUG")
	if (debug.eq."false") then
		err = NhlGetErrorObjectId()
		setvalues err
			"errLevel" : "Fatal"          ; only report Fatal errors
		end setvalues
	end if

	;----------- retrieve required environment variables
	caseName	= getenv("caseName")
	diri		= getenv("FILEDIR")+"/proc/"
	diro		= diri
	twStrt		= getenv("YMDSTRT")
	twLast		= getenv("YMDLAST")
	dateStr		= getenv("FILESUFFSTR")

	;------------- seasons
	seasonName	= (/ "Nov-Apr", "May-Oct" /)

	do s = 0,1 						; do for each season
	
		;============ MSE ===============
			Name1			= "Vmse"	

			;------------ LH flux -----------
			Name2			= "comptotLH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData

			;---------------- first time through, define land maks
			lon		= f->lon
			lat		= f->lat			
			a    	= addfile("$NCARG_ROOT/lib/ncarg/data/cdf/landsea.nc","r")
			lsdata	= a->LSMASK
			lsm		= landsea_mask(lsdata,lat,lon)

			;------------ make nice units, compute difference
			reg_full		= reg_full * 86400. * 100.
			;reg_full@units	= "% ~F18~O~F14~m~F18~P~F21~ day~S2~-1"
			reg_full@units	= "% MSE/day"
			reg_sm			= reg_sm * 86400. * 100.
			mse_lh_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,mse_lh_diff)
			mse_lh_diff@long_name	= "LH SST effect"
			mse_lh_diff		= mask(mse_lh_diff,lsm.ge.1,False)

			;----- write to output file
			filo					= caseName + ".make_L3.4_SSTeffect." + twStrt + "-" + twLast + "." + Name1 + ".SSTeffect_LH." + seasonName(s) + ".nc"
			print("output file = " + diro+filo)
			system("rm -f " + diro+filo)
			fo						= addfile(diro+filo,"c")
			fo->MSE_SSTeffect_LH	= mse_lh_diff

			;------------ SH flux -----------
			Name2			= "comptotSH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 86400. * 100.
			reg_full@units	= "% ~F18~O~F14~m~F18~P~F21~ day~S2~-1"
			reg_sm			= reg_sm * 86400. * 100.
			mse_sh_diff		= reg_full - reg_sm
			copy_VarMeta(reg_full,mse_sh_diff)
			mse_sh_diff@long_name	= "SH SST effect"
			mse_sh_diff		= mask(mse_sh_diff,lsm.ge.1,False)

			;------------ MSE LH+SH SST effect
			mse_tot_diff	= mse_lh_diff + mse_sh_diff
			copy_VarMeta(mse_lh_diff,mse_tot_diff)
			mse_tot_diff@long_name	= "LH+SH SST effect"
			mse_tot_diff		= mask(mse_tot_diff,lsm.ge.1,False)
		
		;============ dMSE/dt ===============
			Name1			= "Vdmdt"	

			;------------ LH flux -----------
			Name2			= "comptotLH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 100.
			;reg_full@units	= "% ~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F10~t"
			reg_full@units	= "% dMSE/dt"
			reg_sm			= reg_sm * 100.
			dmdt_lh_diff	= reg_full - reg_sm
			copy_VarMeta(reg_full,dmdt_lh_diff)
			dmdt_lh_diff@long_name	= "LH SST effect"
			dmdt_lh_diff		= mask(dmdt_lh_diff,lsm.ge.1,False)

			;------------ SH flux -----------
			Name2			= "comptotSH"
			;------------ read in the data for full SST and smoothed SST regressions
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_full		= f->regData
			fili			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + "." + Name2 + "_smSST." + seasonName(s) + ".nc"
			f				= addfile(diri + fili, "r")
			reg_sm			= f->regData
			;------------ make nice units, compute difference
			reg_full		= reg_full * 100.
			reg_full@units	= "% ~F34~6~F18~O~F14~m~F18~P~F21~/~F34~6~F10~t"
			reg_sm			= reg_sm * 100.
			dmdt_sh_diff	= reg_full - reg_sm
			copy_VarMeta(reg_full,dmdt_sh_diff)
			dmdt_sh_diff@long_name	= "SH SST effect"
			dmdt_sh_diff		= mask(dmdt_sh_diff,lsm.ge.1,False)

			;------------ dMSE/dt LH+SH SST effect
			dmdt_tot_diff	= dmdt_lh_diff + dmdt_sh_diff
			copy_VarMeta(dmdt_sh_diff,dmdt_tot_diff)
			dmdt_tot_diff@long_name	= "LH+SH SST effect"
			dmdt_tot_diff	= mask(dmdt_tot_diff,lsm.ge.1,False)

			;----- write to output file
			filo			= caseName + ".make_L3.1_regression_map." + twStrt + "-" + twLast + "." + Name1 + ".SSTeffect." + seasonName(s) + ".nc"
			print("output file = " + diro+filo)
			system("rm -f " + diro+filo)
			fo				= addfile(diro+filo,"c")
			fo->dMSEdt_SSTeffect	= dmdt_tot_diff

		
	end	do		; for each season

end
	





