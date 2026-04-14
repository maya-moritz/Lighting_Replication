/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_4_create_lights_data.do
*	Script purpose: Create lighting data
*	Author: Maya Moritz, amended script from John MacDonald
*	Input: ${data_folder_raw}/PSIP Fixture Export May 6 2024.xlsx
*			${data_folder_raw}/mapping/PHL-GridPoints.dta
*	Output: ${data_folder_temp}/buffer/kde/lights/Kde_lights.dta
			${data_folder_temp}/kde/lights/Kde_lights.dta
*******************************************************************************/

********************************************************************************
********************************Light KDEs**************************************
********************************************************************************
*make kde for each major offense category and each year-month*
*create file paths
cd ${data_folder_temp}

import excel "${data_folder_raw}/PSIP Fixture Export May 6 2024.xlsx", sheet("PSIP Fixture Export May 6 2024") firstrow clear

destring Lat Lon, replace

geo2xy Lat Lon, gen (_Y _X) project(mercator)

*date variables*
gen eventdate=date(InstallCompletedDateTime, "YMD####")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
tab year
gen ym=ym(year, month)
format ym %tm 

*make kde for year month based on when lights were installed*
cap mkdir kde/lights

forval i=763/772 {		
spkde using "${data_folder_raw}/mapping/PHL-GridPoints.dta" if ym==`i', /// 
	xcoord(_X) ycoord(_Y) 			///
	bandwidth (fbw) fbw(1000) dots   ///
	edgecorrection 					///
	noverbose saving ("kde/lights/Kde_lights`i'.dta", replace) 
}

*open a kde files and stack them. Then generate total cumulative count
use "kde/lights/Kde_lights763.dta", clear
        foreach num of numlist 764/772 {
                append using "kde/lights/Kde_lights`num'.dta"
        }
		
gen counter=_n
sort spgrid_id counter

by spgrid_id,: gen ym=[_n]+762
save "kde/lights/Kde_lights.dta", replace
*save for buffer as well
cap mkdir buffer/kde/lights
save "buffer/kde/lights/Kde_lights.dta", replace

