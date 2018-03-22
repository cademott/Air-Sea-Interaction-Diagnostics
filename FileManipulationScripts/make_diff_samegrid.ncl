load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

	seasonName	= (/ "Nov-Apr","May-Oct" /)

	do s=0,1
		diri		= "/volumes/lava/Model_output/MetUM/GOML/AirSea/proc/"
		diro		= diri + "MetUM-GOML_minus_MetUM-ACM/"
		fili		= "MetUM-GOML.make_L1.4_mean_stdev_map.19820101-20061230.PRECT." + seasonName(s) + ".nc"
		f			= addfile(diri+fili,"r")
		rainc_mean	= f->PRECT_mean
		rainc_stdev	= f->PRECT_stdev
	
		diri		= "/volumes/lava/Model_output/MetUM/ACM/AirSea/proc/"
		fili		= "MetUM-ACM.make_L1.4_mean_stdev_map.19820101-20061230.PRECT." + seasonName(s) + ".nc"
		f			= addfile(diri+fili,"r")
		raina_mean	= f->PRECT_mean
		raina_stdev	= f->PRECT_stdev
	
		diff_mean	= rainc_mean - raina_mean
		diff_stdev	= rainc_stdev - rainc_stdev
		;printVarSummary(diff_mean)
		;printMinMax(diff_mean,True)
		copy_VarMeta(rainc_mean,diff_mean)
		copy_VarMeta(rainc_stdev,diff_stdev)
	
		filo		= diro + "MetUM-GOML_minus_MetUM-ACM.make_L1.4_mean_stdev_map.PRECT." + seasonName(s) + ".nc"
		system("/bin/rm -f "+filo)
		f			= addfile(filo,"c")
		f->PRECT_mean	= diff_mean
		f->PRECT_stdev	= diff_stdev
	end do
	
end