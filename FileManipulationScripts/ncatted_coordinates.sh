#!/bin/csh

#----- changes lat/lon units to be compatible with cdo remap routines

setenv 	modelname 	"ERAI"
echo	$modelname
source 	../AirSea_Definitions.sh

setenv	diri	$FILEDIR"/proc"

#foreach i ( PRECT LHFLX SHFLX SNSW SNLW q2m T2m SKT PS PS U850 Vlw Vsw Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp )
foreach fili ( $diri/ERAI.make*.nc )
	#setenv fili /volumes/disk3/Data/ecmwf/ERA-Interim/daily/DBtest/ERAI.$i.19860101-20131231.30S-30N.day.mean.nc
	echo $fili
	ncatted -a units,lon,m,c,"degrees_east" $fili
	ncatted -a units,lat,m,c,"degrees_north" $fili
end