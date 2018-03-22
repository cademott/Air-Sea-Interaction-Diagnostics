#!/bin/csh

#=========== This block should point to the COUPLED simulation, or an EXPERIMENT
setenv modelname "CNRM-CM"
source ./airsea_definitions_DB.sh # handle model-specific logic
setenv 	CDIR	$FILEDIR"/proc/"
setenv 	CNAME	$modelname
setenv	CDATES	$YMDSTRT"-"$YMDLAST

#=========== This block should point to the UNCOUPLED simulation, or the CONTROL, or the OBS
setenv modelname "CNRM-ACM"
source ./airsea_definitions_DB.sh # handle model-specific logic
setenv 	ADIR	$FILEDIR"/proc/"
setenv 	ANAME	$modelname
setenv	ADATES	$YMDSTRT"-"$YMDLAST

echo	$CDATES
echo	$ADATES

setenv	DIRO	$CDIR$CNAME"_minus_"$ANAME"/"
mkdir -p $DIRO
rm -f attr.sh

#============= Level 1 difference files ==================
foreach pName ("make_L1.3a_mean_u850" "make_L1.4_mean_stdev_map" "make_L1.5_stdev_map" "make_L1.6_U850_WesterlyPct" )
	echo "Processing output generated by "$pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
		#echo $cFile
		# parse variable name and season from coupled model input file
		set var=`echo $cFile | cut -d . -f5`
		set season=`echo $cFile | cut -d . -f6`
	
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$var.$season.nc
	
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$var.$season.nc
		#echo $dFile
	
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
	end
end

foreach pName ("make_L1.10_WaveType_stdev_map" )
	echo "Processing output generated by "$pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*_filtered.*.nc)
		#echo $cFile
		# parse variable name and season from coupled model input file
		set var=`echo $cFile | cut -d . -f5`
		set waveType=`echo $cFile | cut -d . -f6`
		#echo $waveType
		set waveName=`echo $waveType | rev | cut -c 10- | rev`
		#echo $waveName
		set season=`echo $cFile | cut -d . -f7`
		
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$var.$waveType.$season.nc
		
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$var.$waveType.$season.nc
		
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		#echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
		
		# create % difference file using cdo operators
		setenv pdFile $DIRO$CNAME"_minus_"$ANAME"_PctDiff."$pName.$var.$waveType.$season.nc
		#echo $pdFile
		cdo -s sqr $cFile cvar.nc
		cdo -s sqr $aFile avar.nc
		cdo -s sub cvar.nc avar.nc diff.nc
		cdo -s mulc,100 diff.nc diff100.nc
		cdo -s div diff100.nc avar.nc $pdFile
		setenv vName $waveName"_stdev"
		#echo $vName
		setenv newName $waveName"_VarPctDiff"
		#echo $newName
		ncrename -v $vName,$newName $pdFile 
		ncatted -O -a units,$newName,o,c,"%" $pdFile
		ncatted -O -a long_name,$newName,o,c,"variance percent difference" $pdFile
		rm cvar.nc
		rm avar.nc
		rm diff.nc
		rm diff100.nc
		
	end
end

foreach pName ("make_L1.7_RH_byWindSST_PDF")
	echo "Processing output generated by "$pName
	foreach cFile ($CDIR$CNAME.$pName.*.nc)
		#echo $cFile
		# parse variable name and season from coupled model input file
		set season=`echo $cFile | cut -d . -f5`
		
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$season.nc
		
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$season.nc
		
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr $CNAME" minus "$ANAME
		#echo $attr
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
		
	end
end

#============= Level 2 difference files ==================
foreach pName ("make_L2.1_regression_propagation" "make_L2.2_regression_nopropagation" "make_L2.5_regression_basepoint" )
	echo "Processing output generated by " $pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
		#echo $cFile
		# parse variable name and season from coupled model input file
		set var1=`echo $cFile | cut -d . -f5`
		set var2=`echo $cFile | cut -d . -f6`
		set season=`echo $cFile | cut -d . -f7`
	
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$var1.$var2.$season.nc
	
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$var1.$var2.$season.nc
		#echo $dFile
	
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
	end
end

#============= Level 2 difference files ==================
foreach pName ("make_L2.5_regression_basepoint" )
	echo "Processing output generated by " $pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
		echo " "
		echo " "
		echo $cFile
		# parse variable name and season from coupled model input file
		set var1=`echo $cFile | cut -d . -f5`
		set var2=`echo $cFile | cut -d . -f6`
		set season=`echo $cFile | cut -d . -f7`
		
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$var1.$var2.$season.nc
		echo $aFile
		
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$var1.$var2.$season.nc
		echo $dFile
		rm -f $dFile
		
		# create difference file using cdo operators
		#cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		ncdiff -O $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
	end
end

#============= Level 3 difference files ==================
foreach pName ("make_L3.1_regression_map" )
	echo "Processing output generated by " $pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
		#echo $cFile
		# parse variable name and season from coupled model input file
		set var1=`echo $cFile | cut -d . -f5`
		set var2=`echo $cFile | cut -d . -f6`
		set season=`echo $cFile | cut -d . -f7`
	
		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$var1.$var2.$season.nc
	
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$var1.$var2.$season.nc
		#echo $dFile
	
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
	end
end

# foreach pName ("make_L3.2_MSE_PDF_lineplots" )
# end

foreach pName ( "make_L3.3_MSE_ModProjectionMaps" )
	echo "Processing output generated by " $pName
	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
		# parse variable name and season from coupled model input file
		set season=`echo $cFile | cut -d . -f5`

		# define corresponding uncoupled filename
		setenv aFile $ADIR$ANAME.$pName.$ADATES.$season.nc
		
		# define output file, to be written to newly created directory under $CDIR
		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$season.nc
		#echo $dFile
		
		# create difference file using cdo operators
		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
		setenv attr '"'$CNAME' - '$ANAME'"'
		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
	end
end

# foreach pName ( "make_PWgradients_SeasonMean.ERAI_grid" )
# 	echo "Processing output generated by " $pName
# 	foreach cFile ($CDIR$CNAME.$pName.$CDATES.*.nc)
# 		#echo $cFile
# 		# parse variable name and season from coupled model input file
# 		set season=`echo $cFile | cut -d . -f5`
# 
# 		# define corresponding uncoupled filename
# 		setenv aFile $ADIR$ANAME.$pName.$ADATES.$season.nc
# 		
# 		# define output file, to be written to newly created directory under $CDIR
# 		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.$season.nc
# 		#echo $dFile
# 		
# 		# create difference file using cdo operators
# 		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
# 		setenv attr '"'$CNAME' - '$ANAME'"'
# 		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
# 	end
# end
# 
# #foreach pName ( "make_2D_SeasonMeanMaps" )
# 	echo "Processing output generated by " $pName
# 	#echo $CDIR$CNAME.$pName.$CDATES.PW.*.nc
# 	echo $CDIR
# 	echo $CNAME
# 	echo $CDATES
# 	foreach cFile ($CDIR$CNAME.$pName.$CDATES.PW.*.nc)
# 		#echo $cFile
# 		# parse variable name and season from coupled model input file
# 		set season=`echo $cFile | cut -d . -f5`
# 
# 		# define corresponding uncoupled filename
# 		setenv aFile $ADIR$ANAME.$pName.$ADATES.PW.$season.nc
# 		
# 		# define output file, to be written to newly created directory under $CDIR
# 		setenv dFile $DIRO$CNAME"_minus_"$ANAME.$pName.PW.$season.nc
# 		echo $dFile
# 		
# 		# create difference file using cdo operators
# 		cdo -s sub $cFile $aFile $dFile	# -s is for "silent mode" (less output to screen)
# 		setenv attr '"'$CNAME' - '$ANAME'"'
# 		echo "ncatted -O -a difference_definition,global,c,c,"$attr" "$dFile >> attr.sh
# 	end
# end

#============== add global attribute with short file description ==============
 chmod +x attr.sh
 attr.sh




