#!/bin/csh

	#===============================================================
	#============= USER INPUT REQUIRED HERE ========================
	#setenv	CASES 	"( CFSv2RAS )"	# list of cases for analysis
	#setenv	CASES 	"( ERAI SPCCSM SPCAM3_mon CNRM-CM CNRM-ACM MetUM-GOML MetUM-ACM ECHAM-CPL ECHAM-A31 )"	# list of cases for analysis
	#setenv	CASES 	"( ECHAM-CPL )"	# list of cases for analysis
	setenv	CASES 	"( ERAI )"	# list of cases for analysis
	setenv	PTYPE 	"png"			# png or pdf plots
	setenv	DEBUG 	"false"		# "false" suppresses non-fatal NCL warning messages
	setenv	FIGCAP	"false"		# "true" includes plotting details at bottom of figures
								#  (suggest "true" for first-look, web display, or sharing results;
								#	suggest "true" for publication figures).
	#setenv	WEBDISP	"false"		#	creat web display page
	#setenv	PUBLIC	"/Users/demott/public/"	# required for sharing web results

	#--- additional 2D fields for background_anomaly, regression_propagation, and 
	#	 basepoint_regression routines.
	#	 If extra variables are listed, they must follow the same file naming convention as
	#	 required input files:
	#	 	caseName.varName.dateRange.latRange.day.mean.nc
	set	ExtraVars	= "false"
	if ($ExtraVars == "true") then
		setenv ExtraVarList	"( V850 PW )" # for example
	endif
	#============= END OF REQUIRED INPUT SECTION ===================
	#===============================================================

	date # start time


	#--- PRECONDITIONING STEPS:  make additional variables, anomaly time series
	#--- ========= > THESE STEPS SHOULD BE DONE ONLY ONCE!!! <=================
	#--- Once run, set the switch to "true."  
	#--- Other time spans can be analyzed or new analyses performed 
	#--- without regenerating these fields.

	set Make_AirSea_Vars			= "false"	# make_L1.1_airsea_vars.ncl
	set Make_Anomaly_Timeseries		= "false"	# make_L1.2a_background_anomaly_2Dfield.ncl
	set Make_SfcFlux_Components		= "false"	# make_L1.3_flux_components.ncl
	#set Make_SSTEffect_Timeseries	= "false"	# make_L1.4_SSTeffect_timeseries.ncl

	#============= LEVEL 1 DIAGNOSTICS:  MEAN, STDEV, RH-SST-WIND PDFs
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions.sh.  

	set Make_SeasonMean_u850		= "false"	# make_L1.3a_mean_u850.ncl
	set Make_Mean_Stdev_Maps		= "false"	# make_L1.4_mean_stdev_map.ncl
	set Make_FluxComp_Stdev_Maps	= "false"	# make_L1.5_stdev_map.ncl
	set Make_u850_PctWesterly_Maps	= "false"	# make_L1.6_U850_WesterlyPct.ncl
	set Make_RH_Wind_SST_PDF		= "false"	# make_L1.7_RH_byWindSST_PDF.ncl
	set Make_SST_Skewness			= "false"	# make_L1.8_SST_skewness.ncl
	
	#--- Plotting steps:  plot fields computed above
	set Plot_Surface_Variables		= "false"	# plot_L1.1_SfcVariables_MeanStd.ncl
	set Plot_SfcEnergyBal_MeanStd	= "false"	# plot_L1.2_SfcEnergyBudget_MeanStd.ncl
	set Plot_LHFluxComponent_Diff	= "false"	# plot_L1.3_LHFluxComponent_Std_diff.ncl
	set Plot_SHFluxComponent_Diff	= "false"	# plot_L1.3_SHFluxComponent_Std_diff.ncl
	set Plot_LHComponent_Ratios		= "false"	# plot_L1.4_LHFluxComponent_StdevRatio.ncl
	set Plot_SHComponent_Ratios		= "false"	# plot_L1.4_SHFluxComponent_StdevRatio.ncl
	set Plot_RH_byWindSST_PDFs		= "false"	# plot_L1.5_RH_byWindSST_PDF.ncl
	set Plot_u850_PctWesterly		= "false"	# plot_L1.6_U850_WesterlyPct.ncl
	set Plot_MSE_dMSEdt_Mean_Std	= "false"	# plot_L1.7_MSE_dMSEdt_MeanStd.ncl
	set Plot_SST_Skewness			= "false"	# plot_L1.8_SST_skewness.ncl
	
	#============= LEVEL 2 DIAGNOSTICS:  LAG REGRESSIONS, WHEELER-KILADIS PLOTS
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions.sh.  

	set Make_LagRegression_Prop		= "false"	# make_L2.1_regression_propagation.ncl
	set Make_LagRegression_NoProp	= "false"	# make_L2.2_regression_nopropagation.ncl
	set Make_WaveNumber_Frequency	= "false"	# make_L2.3_wkSpaceTime_AirSea.ncl
	set Make_WaveNumber_Ratio		= "false"	# make_L2.4_wkSpaceTime_Ratio.ncl
	set Make_BasePoint_Regression	= "false"	# make_L2.5_regression_basepoint.ncl

	#--- Plotting steps:  plot fields computed above
	set Plot_LHFluxComp_Prop		= "false"	# plot_L2.1_LHFluxComponent_propagation.ncl
	set Plot_SHFluxComp_Prop		= "false"	# plot_L2.1_SHFluxComponent_propagation.ncl
	set Plot_SfcEnergyBal_Prop		= "false"	# plot_L2.1_SfcEnergyBalance_propagation.ncl
	set Plot_MSEbudget_Prop			= "false"	# plot_L2.1_MSEbudget_propagation.ncl
	set Plot_LHFluxComp_NoProp		= "false"	# plot_L2.2_LHFluxComponent_nopropagation.ncl
	set Plot_SHFluxComp_NoProp		= "false"	# plot_L2.2_SHFluxComponent_nopropagation.ncl
	set Plot_SfcEnergyBal_NoProp	= "false"	# plot_L2.2_SfcEnergyBalance_nopropagation.ncl
	set Plot_MSEbudget_NoProp		= "false"	# plot_L2.2_MSEbudget_nopropagation.ncl
	set Plot_SSTEffect_NoProp		= "false"	# plot_L2.2_SSTEffect_nopropagation.ncl
	set Plot_SfcEnergyBal_IO		= "false"	# plot_L2.3_SfcEnergy_lags.ncl
	set Plot_SSTEffectLags_IO		= "false"	# plot_L2.4_SSTEffect_lags.ncl
	
	#============= LEVEL 3 DIAGNOSTICS:  LAG=0 MSE, dMSE/dT, dSST/dt REGRESSION MAPS
	#--- Analysis steps:  perform analyses over user-specified time range
	#--- Select starting and ending date for analysis in airsea_definitions.sh.  
	set Make_MSERegress_AllPhases	= "false"	# make_L3.1_regressionMaps.ncl
	set Make_RainRegress_AllPhases	= "false"	# make_L3.1_regressionMaps.ncl
	set Make_MiscRegress_AllPhases	= "false"	# make_L3.1_regression_map.ncl
	set Make_MSE_PDFs				= "false"	# make_L3.2_MSE_PDF_lineplots.ncl
	set Make_Modified_Projection	= "false"	# make_L3.3_MSE_ModProjectionMaps.ncl
	set Make_SSTeffect_SingleFile	= "false"	# make_L3.4_SSTeffect_SingleFile.ncl

	#--- Plotting steps:  plot fields computed above
	set Plot_MSEBudget_RegMaps		= "false"	# plot_L3.1_MSEbudget_regressionMaps.ncl
	set Plot_FluxComp_RegMaps		= "false"	# plot_L3.2_MSE(dMSEdt)_LH(SH)FluxComp_regressions.ncl
	set Plot_dSSTdt_Qnet_RegMaps	= "true"	# plot_L3.3_QnetdSSTdt_regressionMaps.ncl
	set SSTeffect_RegMaps			= "false"	# plot_L3.4_SSTeffectSummary.ncl
	set Plot_MSE_PDFs				= "false"	# plot_L3.5_MSE_PDF_lineplots.ncl
	set Plot_MSE_ModProjectionMaps	= "false"	# plot_L3.6_MSE_ModProjectionMaps.ncl

	#=============== WEB DISPLAY ===================
	#set Web_Display					= $WEBDISP	# create html directories and files

foreach modelname $CASES # must match $modelname in $FILEDIR
	setenv caseName $modelname
	source ./AirSea_definitions.sh # handle model-specific logic
	mkdir -p $FILEDIR"/proc"
	mkdir -p $FILEDIR"/plots"
	#if ($Web_Display == "true") then
	#	mkdir -r
	#echo $modelname

	####-------------- LEVEL 1 PROCESSING:  MAKE ANOMALIES, FLUX COMPONENT TERMS
	#==========================================================================
	#--------------------------------------------------------------------------
	#  # make L1.1: -------------- make Qnet, dSST/dt, SPD, delta-q, delta-T, Qsat, RH, seasonal mean u850 
	if ($Make_AirSea_Vars == "true") then
		ncl -Q  ./AirSea_Diagnostics/make_L1.1_airsea_vars.ncl
	endif

	#--------------------------------------------------------------------------
	#  # L1.2: -------------- make anomaly time series of all input variables
	if ($Make_Anomaly_Timeseries == "true") then
		
 		foreach varName ( $RAINVARNAME $LHVARNAME $SHVARNAME $LWVARNAME $SWVARNAME $QVARNAME $TKVARNAME $SSTVARNAME $SFCPVARNAME )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.2a_background_anomaly_2Dfield.ncl
		end 	# loop over all variables
		
		foreach varName ( Qnet dSSTdt SPD Qsat $SSTVARNAME"_smSST" Qsat_smSST delQ delQ_smSST delT delT_smSST RHsfc )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.2a_background_anomaly_2Dfield.ncl
		end 	# loop over all variables

		foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.2a_background_anomaly_2Dfield.ncl
		end 	# loop over all variables
		
		foreach varName ( $U850VARNAME )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.2a_background_anomaly_2Dfield.ncl
		end
		
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName $varName
				ncl -Q ./AirSea_Diagnostics/make_L1.2a_background_anomaly_2Dfield.ncl
			end
		endif
				
		
	endif

	#--------------------------------------------------------------------------
	#  # make L1.3: -------------- make surface flux component time series (full and smoothed SST) 
	if ($Make_SfcFlux_Components == "true") then
		ncl -Q  ./AirSea_Diagnostics/make_L1.3_flux_components.ncl
	endif

	#--------------------------------------------------------------------------
	#	# make L1.4:-------------- make SST effect time series
	#if ($Make_SSTEffect_Timeseries == "true") then
	#	ncl -Q ./AirSea_Diagnostics/make_L1.4_SSTeffect_timeseries.ncl
	#endif

	#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	#|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	#=================== RUN THE ABOVE SCRIPTS ONLY ONCE ======================

#############################################################################################
#############################################################################################
	
	#=================== RUN BELOW SCRIPTS MULTIPLE TIMES ======================
	#=================== IF DIFFERENT TIME SPANS DESIRED  ======================
	#|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
	#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv



	#--------------------------------------------------------------------------
	#  # L1.3a: -------------- make seasonal mean u850 for specified time range
	if ($Make_SeasonMean_u850 == "true") then
		ncl -Q ./AirSea_Diagnostics/make_L1.3a_mean_u850.ncl
	endif

	#--------------------------------------------------------------------------
	#  # make L1.4: -------------- make mean and bandpass filtered standard deviation maps
	#  #	   -------------- input variables
	if ($Make_Mean_Stdev_Maps == "true") then
		foreach varName ( $RAINVARNAME $LHVARNAME $SHVARNAME $LWVARNAME $SWVARNAME $QVARNAME $TKVARNAME $SSTVARNAME $SFCPVARNAME   )
		#foreach varName ( $RAINVARNAME  )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.4_mean_stdev_map.ncl
		end
		
		#  #	   -------------- derived variables
		foreach varName ( Qnet $SSTVARNAME"_smSST" SPD Qsat Qsat_smSST delQ delQ_smSST delT delT_smSST RHsfc )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.4_mean_stdev_map.ncl
		end
	
	 	#	#	   -------------- MSE budget terms 
		foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.4_mean_stdev_map.ncl
		end
		
		foreach varName ( $U850VARNAME )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.4_mean_stdev_map.ncl
		end
	endif
		
	#--------------------------------------------------------------------------
	#  # make L1.5: -------------- make bandpass filtered standard deviation maps
	if ($Make_FluxComp_Stdev_Maps == "true") then
		#-------------- component latent heat flux variables (no daily means for these)
		foreach varName ( wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST comptotLH comptotLH_smSST )
		#foreach varName ( wdLH  )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.5_stdev_map.ncl
		end
		
		#-------------- component sensible heat flux variables (no daily means for these)
		foreach varName ( wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST comptotSH comptotSH_smSST )
			setenv inName $varName
			ncl -Q ./AirSea_Diagnostics/make_L1.5_stdev_map.ncl
		end
	
		#-------------- any extra variables provided
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName $varName
				ncl -Q ./AirSea_Diagnostics/make_L1.5_stdev_map.ncl
			end
		endif
		
	endif

	#--------------------------------------------------------------------------
	#  # make L1.6: -------------- calculate % of days with U850 > 0
	if ($Make_u850_PctWesterly_Maps == "true") then
	  	ncl -Q ./AirSea_Diagnostics/make_L1.6_U850_WesterlyPct.ncl
	endif

	#--------------------------------------------------------------------------
	#  # make L1.7: -------------- RH by wind speed, SST
	if ($Make_RH_Wind_SST_PDF == "true") then
	  	ncl -Q ./AirSea_Diagnostics/make_L1.7_RH_byWindSST_PDF.ncl
	endif

	#--------------------------------------------------------------------------
	#  # make L1.8: -------------- SST skewness
	if ($Make_SST_Skewness == "true") then
	  	ncl -Q ./AirSea_Diagnostics/make_L1.8_SST_skewness.ncl
	endif


	#--------------------------------------------------------------------------
	#  # plot L1.1: -------------- rainfall, wind speed, LH, SH, SST maps
	if ($Plot_Surface_Variables == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.1_SfcVariables_MeanStd.ncl
	endif

	#  # plot L1.2: -------------- Surface energy budget term maps
	if ($Plot_SfcEnergyBal_MeanStd == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.2_SfcEnergyBudget_MeanStd.ncl
	endif

	#  # plot L1.3: -------------- Latent heat flux component difference maps 
	if ($Plot_LHFluxComponent_Diff == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.3_LHFluxComponent_Std_diff.ncl
	endif

	#  # plot L1.3: -------------- Sensible heat flux component difference maps
	if ($Plot_SHFluxComponent_Diff == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.3_SHFluxComponent_Std_diff.ncl
	endif

	#  # plot L1.4: -------------- Sensible heat flux component maps
	if ($Plot_LHComponent_Ratios == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.4_LHFluxComponent_StdevRatio.ncl
	endif

	#  # plot L1.4: -------------- Sensible heat flux component maps
	if ($Plot_SHComponent_Ratios == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.4_SHFluxComponent_StdevRatio.ncl
	endif

	#  # plot L1.5: -------------- RH_byWindSST_PDF
	if ($Plot_RH_byWindSST_PDFs == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.5_RH_byWindSST_PDF.ncl
	endif

	#  # plot L1.6: -------------- Sensible heat flux component maps
	if ($Plot_u850_PctWesterly == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.6_U850_WesterlyPct.ncl
	endif

	#	# plot L1.7: ------------- mean MSE, stdev MSE, stdev dMSE/dt
	if ($Plot_MSE_dMSEdt_Mean_Std == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.7_MSE_dMSEdt_MeanStd.ncl
	endif

	#	# plot L1.8: ------------- SST skewness
	if ($Plot_SST_Skewness == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L1.8_SST_skewness.ncl
	endif

	####-------------- LEVEL 2 PROCESSING:  LAG REGRESSIONS, WHEELER-KILADIS PLOTS
	#=============================================================================
	
	#--------------------------------------------------------------------------
	#  # make L2.1: -------------- Lag-regression @ specific base point (shows propagation) 
	#  # NOTE:  "warning:esacr:" message occur for LHFLX and SHFLX variables for longitudes
	#  #		where 10S-10N contains all land points since land points are set to "missing."
	#  #        This has no impact on result.

	if ($Make_LagRegression_Prop == "true") then
		#	#  -------------- input variables
#  		foreach varName ( PRECT )
#  			setenv inName1 $RAINVARNAME
#  			setenv inName2 $varName
#  			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
#  		end 	# loop over all variables

		foreach varName ( $RAINVARNAME $LHVARNAME $SHVARNAME $LWVARNAME $SWVARNAME $QVARNAME $TKVARNAME $SSTVARNAME $SFCPVARNAME )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
		end 	# loop over all variables
	
		#	#  -------------- derived variables
		foreach varName ( Qnet $SSTVARNAME"_smSST" SPD Qsat Qsat_smSST delQ delQ_smSST delT delT_smSST RHsfc )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
		end
	
		#	#  -------------- LHFLX component terms
		foreach varName ( comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
		end
	
		#	#  -------------- SHFLX component terms
		foreach varName ( comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
		end
	
	 	#	#  -------------- MSE budget terms 
		foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
		end

		#-------------- any extra variables provided
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName $varName
				ncl -Q ./AirSea_Diagnostics/make_L2.1_regression_propagation.ncl
			end
		endif
	endif


	#  # make L2.2: -------------- Lag-regression @ each longitude (no propagation) 
	if ($Make_LagRegression_NoProp == "true") then
	
		#	#  ------------- regression onto RAINFALL
		#	#  ------------- input variables
 		setenv OCEANONLY true
		foreach varName ( $RAINVARNAME $LHVARNAME $SHVARNAME $LWVARNAME $SWVARNAME $QVARNAME $TKVARNAME $SFCPVARNAME )
		#foreach varName ( $SFCPVARNAME )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end 	# loop over all variables
	
		#	#  -------------- derived variables
		setenv OCEANONLY true
		foreach varName ( Qnet $SSTVARNAME $SSTVARNAME"_smSST" SPD Qsat Qsat_smSST delQ delQ_smSST delT delT_smSST RHsfc )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end
	
		#	#  -------------- LHFLX component terms
		setenv OCEANONLY true
		foreach varName ( comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end
	
		#	#  -------------- SHFLX component terms
		setenv OCEANONLY true
		foreach varName ( comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end
	 	#	#  -------------- MSE budget terms 
		setenv OCEANONLY true
		foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
			setenv inName1 $RAINVARNAME
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end

		#	#  ------------- regression onto Vmse
		#	#  ------------- MSE budget terms
		foreach varName ( Vmse Vdmdt Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw )
			setenv inName1 Vmse
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end

		#	#  ------------- LHFLX component terms
		foreach varName ( comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName1 Vmse
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end

		#	#  ------------- SHFLX component terms
		foreach varName ( comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName1 Vmse
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
		end

		#-------------- any extra variables provided
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName1 $RAINVARNAME
				setenv inName2 $varName
				ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
				
				setenv inName1 Vmse
				setenv inName2 $varName
				ncl -Q ./AirSea_Diagnostics/make_L2.2_regression_nopropagation.ncl
			end
		endif
	endif


	if ($Make_WaveNumber_Frequency == "true") then
		#  # make L2.3: -------------- Wheeler-Kiladis (wave number vs frequency) plots
		#  #	   -------------- select input variables
		foreach varName ( $RAINVARNAME $LHVARNAME $SHVARNAME $QVARNAME SSTeffect_LH SSTeffect_SH )
		#foreach varName ( $RAINVARNAME )
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
		end 	# loop over all variables
	
		#  #	   -------------- select derived variables
		foreach varName ( Qsat delQ delQ_smSST delT delT_smSST )
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
		end
	
		#	#  -------------- select LHFLX component terms
		foreach varName ( comptotLH comptotLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
		end
	
		#	#  -------------- select SHFLX component terms
		foreach varName ( comptotSH comptotSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
		end
	 	#	#  -------------- select MSE budget terms 
		foreach varName ( Vmse Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw )
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
		end

		#-------------- any extra variables provided
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName $varName
				ncl -Q ./AirSea_Diagnostics/make_L2.3_wkSpaceTime_AirSea.ncl
			end
		endif
	endif


	if ($Make_WaveNumber_Ratio == "true") then
		#  # make L2.4: -------------- Wheeler-Kiladis (wave number vs frequency) ratio plots
		#-------------- input variables
		foreach varName ( comptotLH  tdLH  ecLH comptotSH tdSH ecSH delQ delT)
			setenv inName1 $varName
			ncl -Q ./AirSea_Diagnostics/make_L2.4_wkSpaceTime_Ratio.ncl
		end 	# loop over all variables
	endif

	if ($Make_BasePoint_Regression == "true") then
		#  # make L2.5: -------------- regress anomalies onto filtered base point time series
		#-------------- input variables
 		foreach varName ( $SSTVARNAME $RAINVARNAME $LHVARNAME $U850VARNAME $QVARNAME $TKVARNAME $SFCPVARNAME SSTeffect_LH SSTeffect_SH )
 			setenv inName1	$RAINVARNAME
 			setenv inName2	$varName
 			ncl -Q ./AirSea_Diagnostics/make_L2.5_regression_basepoint.ncl
 		end 	# loop over all variables

		#-------------- derived and additional variables
		foreach varName ( Vdmdt Vlw Vm_hadv Vomegadmdp Vudmdx Vvdmdy U850 delQ delT SSTeffect_LH SSTeffect_SH )
 			setenv inName1	$RAINVARNAME
 			setenv inName2	$varName
 			ncl -Q ./AirSea_Diagnostics/make_L2.5_regression_basepoint.ncl
 		end 	# loop over all variables

		#-------------- any extra variables provided
		if ($ExtraVars == "true") then
			foreach varName $ExtraVarList
				setenv inName1 $RAINVARNAME
				setenv inName2 $varName
				ncl -Q ./AirSea_Diagnostics/make_L2.5_regression_basepoint.ncl
			end
		endif
	endif

	#--------------------------------------------------------------------------
	#  # plot L2.1: -------------- LHFLX components (propagation)
	if ($Plot_LHFluxComp_Prop == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.1_LHFluxComponent_propagation.ncl
	endif

	#  # plot L2.1: -------------- SHFLX components (propagation)
	if ($Plot_SHFluxComp_Prop == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.1_SHFluxComponent_propagation.ncl
	endif

	#  # plot L2.1: -------------- SST, surface energy budget lag regressions (propagation)
	if ($Plot_SfcEnergyBal_Prop == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.1_SfcEnergyBalance_propagation.ncl
	endif

	#  # plot L2.2: -------------- MSE budget lag regressions (propagation)
	if ($Plot_MSEbudget_Prop == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.1_MSEbudget_propagation.ncl
	endif


	#--------------------------------------------------------------------------
	#  # plot L2.2: -------------- LHFLX components (nopropagation)
	if ($Plot_LHFluxComp_NoProp == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.2_LHFluxComponent_nopropagation.ncl
	endif

	#  # plot L2.2: -------------- SHFLX components (nopropagation)
	if ($Plot_SHFluxComp_NoProp == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.2_SHFluxComponent_nopropagation.ncl
	endif

	#  # plot L2.2: -------------- SST, surface energy budget lag regressions (nopropagation)
	if ($Plot_SfcEnergyBal_NoProp == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.2_SfcEnergyBalance_nopropagation.ncl
	endif

	#  # plot L2.2: -------------- MSE budget lag regressions (nopropagation)
	if ($Plot_MSEbudget_NoProp == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.2_MSEbudget_nopropagation.ncl
	endif

	#  # plot L2.2: -------------- MSE budget lag regressions (nopropagation)
	if ($Plot_SSTEffect_NoProp == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.2_SSTEffect_nopropagation.ncl
	endif

	#	# plot L2.3:-------------- Surface Energy budget for Indian Ocean
	if ($Plot_SfcEnergyBal_IO == "true") then
		ncl -Q ./AirSea_Diagnostics/plot_L2.3_SfcEnergy_lags.ncl
	endif
	
	#	# plot L2.4:-------------- SST Effect for Indian Ocean
	#		multiple plots to illustrate LH vs SH and Rain vs MSE differences.
	if ($Plot_SSTEffectLags_IO == "true") then
		setenv LONWEST	60	# SST effect is larger in the western IO
		setenv LONEAST	70
		ncl -Q ./AirSea_Diagnostics/plot_L2.4_SSTEffect_Rain_LH_lags.ncl
		ncl -Q ./AirSea_Diagnostics/plot_L2.4_SSTEffect_Rain_SH_lags.ncl
		#ncl -Q ./AirSea_Diagnostics/plot_L2.4_SSTEffect_MSE_LH_lags.ncl
		#ncl -Q ./AirSea_Diagnostics/plot_L2.4_SSTEffect_MSE_SH_lags.ncl
	endif
	
	####-------------- LEVEL 3 PROCESSING:  LAG=0 MSE REGRESSION MAPS
	#=============================================================================
	
	#	#  -------------- regress onto MSE 
	if ($Make_MSERegress_AllPhases == "true") then
	#------------ MSE budget terms onto MSE
		setenv inName1 Vmse
		foreach varName ( Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw $LHVARNAME $SHVARNAME SSTeffect_LH SSTeffect_SH )
		#foreach varName ( SSTeffect_LH SSTeffect_SH)
		#foreach varName ( $LHVARNAME )
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end

		#------------ LHFLX component terms (full and smoothed SST) onto MSE
		setenv inName1 Vmse
		foreach varName ( comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end

		#------------ SHFLX component terms (full and smoothed SST) onto MSE
		setenv inName1 Vmse
		foreach varName ( comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end

		#------------ MSE budget terms onto dMSE/dt
		setenv inName1 Vdmdt
		foreach varName ( Vm_hadv Vudmdx Vvdmdy Vomegadmdp Vlw Vsw $LHVARNAME $SHVARNAME SSTeffect_LH SSTeffect_SH )
		#foreach varName ( SSTeffect_LH SSTeffect_SH)
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end

		#------------ LHFLX component terms (full and smoothed SST) onto dMSE/dt
		setenv inName1 Vdmdt
		foreach varName ( comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end

		#------------ SHFLX component terms (full and smoothed SST)
		setenv inName1 Vdmdt
		foreach varName ( comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
			setenv inName2 $varName
			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		end
	endif
	
	if ($Make_RainRegress_AllPhases == "true") then	
		#	#  -------------- regress onto Rainfall (in W/m**2 units) 
 		setenv inName1 $RAINVARNAME
 		setenv RAIN2WM2 "True"

		#------------ LHFLX component terms (full and smoothed SST)
 		foreach varName (  $LHVARNAME comptotLH comptotLH_smSST wdLH wdLH_smSST tdLH tdLH_smSST ecLH ecLH_smSST )
 		#foreach varName (  $LHVARNAME )
 			setenv inName2 $varName
 			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
 		end

		#------------ SHFLX component terms (full and smoothed SST)
  		foreach varName (  $SHVARNAME comptotSH comptotSH_smSST wdSH wdSH_smSST tdSH tdSH_smSST ecSH ecSH_smSST )
  			setenv inName2 $varName
  			ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
  		end
	endif

 	#  -------------- other regressions 
	if ($Make_MiscRegress_AllPhases == "true") then	
		setenv RAIN2WM2 "true"
		setenv inName1 PRECT
		setenv inName2 Vmse
		ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
		
		setenv inName1 Qnet
		setenv inName2 dSSTdt
 		ncl -Q ./AirSea_Diagnostics/make_L3.1_regression_map.ncl
 	endif

	# --------------- MSE PDFs:  "Walter" plots
	if ($Make_MSE_PDFs == "true") then
		ncl -Q ./AirSea_Diagnostics/make_L3.2_MSE_PDF_lineplots.ncl		
	endif
	
	# --------------- modified projections of source terms onto MSE, dMSE/dt
	if ($Make_Modified_Projection == "true") then
		ncl -Q ./AirSea_Diagnostics/make_L3.3_MSE_ModProjectionMaps.ncl
	endif	
		
	# --------------- modified projections of source terms onto MSE, dMSE/dt
	#					this output is needed for multi-plot comparisons
	if ($Make_SSTeffect_SingleFile == "true") then
		ncl -Q ./AirSea_Diagnostics/make_L3.4_SSTeffect_SingleFile.ncl
	endif	
		

	#set Make_Modified_Projection	= "true"	# make_L3.3_MSE_ModProjectionMaps.ncl
	#--------------------------------------------------------------------------
	#  # plot L3.1: -------------- MSE budget term regressions onto MSE, dMSE/dt
	if ($Plot_MSEBudget_RegMaps == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.1_MSEbudget_regressionMaps.ncl
	endif

	#  # plot L3.2: -------------- Flux Components regressed onto MSE
	if ($Plot_FluxComp_RegMaps == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.2_MSE_LHFluxComp_regressions_diff.ncl
		ncl -Q ./AirSea_Diagnostics/plot_L3.2_MSE_SHFluxComp_regressions_diff.ncl
		ncl -Q ./AirSea_Diagnostics/plot_L3.2_dMSEdt_LHFluxComp_regressions_diff.ncl
		ncl -Q ./AirSea_Diagnostics/plot_L3.2_dMSEdt_SHFluxComp_regressions_diff.ncl
	endif

	#  # plot L3.3: -------------- dSST/dt regressed onto Qnet
	if ($Plot_dSSTdt_Qnet_RegMaps == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.3_QnetdSSTdt_regressionMaps.ncl
	endif

	#  # plot L3.4: -------------- SST effect on MSE, dMSE/dt
	if ($SSTeffect_RegMaps == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.4_SSTeffectSummary.ncl
	endif

	#  # plot L3.5: -------------- MSE binned averages (MSE tendency terms)
	#				"Walter" plots
	if ($Plot_MSE_PDFs == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.5_MSE_PDF_lineplots.ncl
	endif

	#  # plot L3.5: -------------- MSE binned averages (MSE tendency terms)
	if ($Plot_MSE_ModProjectionMaps == "true") then	
		ncl -Q ./AirSea_Diagnostics/plot_L3.6_MSE_ModProjectionMaps.ncl
	endif

	date # end time

	####-------------- WEB DISPLAY
	#=============================================================================
	
# 	if ($Web_display == "true") then
# 		foreach $i ($FILEDIR"/"plots/*plot_L1.*.png)
# 			set pnum 	= `cut $i -d . -f2`
# 			set pname	= `cut $i -d . -f3`
# 			set season	= `cut $i =d . -f-2`
# 			cp $i $PUBLIC/$modelname_html/$pnum.$pname.$season.png
# 		end
# 	endif


end # end loop over models


