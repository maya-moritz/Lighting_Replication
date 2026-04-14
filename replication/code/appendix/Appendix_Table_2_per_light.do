/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: Appendix_Table_2_per_light
*	Script purpose: create Appendix Table 2 (Street-level analysis by light count)
*	Author: Maya Moritz
*	Input: ${data_folder_temp}/streets/
*	Output: ${output_tables_folder}/Appendix/Table_A2/per_light.html
*******************************************************************************/
cap mkdir ${output_tables_folder}/Appendix/Table_A2/
clear
eststo clear

use "${data_folder_processed}/adjacent_nonadjacent_street_sample.dta", clear
keep if level_of_treat < 2
*get rid of segments with zero crime ever 
*bysort seg_id: egen crime_ever=max(total_crime)
*seems these are all streets with some amount of crime
*rows filled in by tsset that had 0 crime that month are missing all day and night variables, so replace with 0
local vars total_crime gun violent property nuisance financial
global countoutcomes_street total_crime gun violent property nuisance financial

* Loop over each variable to create the conditional versions for daylight and daylight_buffer
foreach var of local vars {
    * Create conditional variables based on daylight
    replace `var'_day = 0 if total_crime == 0
	replace `var'_day_buffer = 0 if total_crime == 0
    replace `var'_night = 0 if total_crime == 0
	replace `var'_night_buffer = 0 if total_crime == 0

}

* Top code streets with over 10 lights
gen adj_lights_top_coded = adj_lights
replace adj_lights_top_coded = 10 if adj_lights > 10


* Loop for original variables (total, gun, violent, property, nuisance, financial)
foreach y of global countoutcomes_street {
    eststo: xtpoisson `y' i.adj_lights_top_coded i.ym if level_of_treat~=. & ym<773, fe i(seg_id) irr robust
    estadd ysumm
}

* Loop for _day variables (total_day, gun_day, violent_day, etc.)
foreach y of global countoutcomes_street {
    eststo: xtpoisson `y'_day i.adj_lights_top_coded i.ym if level_of_treat~=. & ym<773, fe i(seg_id) irr robust
    estadd ysumm
}

* Loop for _night variables (total_night, gun_night, violent_night, etc.)
foreach y of global countoutcomes_street {
    eststo: xtpoisson `y'_night i.adj_lights_top_coded i.ym if level_of_treat~=. & ym<773, fe i(seg_id) irr robust
    estadd ysumm
}


*Make Table for all, day, and night without daylight buffers
esttab est1 est2 est3 est4 est5 est6 using "${output_tables_folder}/Appendix/Table_A2/per_light.html", replace ///
    keep(*.adj_lights_top_coded) depvar eform se stats(ymean N, labels ("Ave. Dep" "N")) nonumber ///
	mtitle("Total" "Gun" "Violent" "Property" "Nuisance" "Financial") ///
    title("Panel A: All Times") nonotes

esttab est7 est8 est9 est10 est11 est12 using "${output_tables_folder}/Appendix/Table_A2/per_light.html", append ///
    keep(*.adj_lights_top_coded) depvar eform se stats(ymean N, labels ("Ave. Dep" "N")) nonumber /// 
    title("Panel B: Day") nonotes ///
     nonumbers nomtitles    
	
	esttab est13 est14 est15 est16 est17 est18 using "${output_tables_folder}/Appendix/Table_A2/per_light.html", append  ///
    keep(*.adj_lights_top_coded) depvar eform se stats(ymean N, labels ("Ave. Dep" "N")) nonumber ///
    title("Panel C: Night") ///
    note("Streets with more than 10 adjacent lights are topcoded to 10. Robust standard errors in parentheses; block and year-month fixed effects") ///
    nonumbers nomtitles    
	
	
	
