/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_5_integration_hexagons.do
*	Script purpose: Integrate hexagons, lights, and crime
*	Author: Maya Moritz, amended script from John MacDonald
*	Input: all final files creates in 3.2.1-3.2.3
*	Output: ${data_folder_processed}/buffer/`i'`j'.dta
*		${data_folder_processed}/`i'`j'.dta
*	Organization:
*	1. Integrate crime and lights data
*	2. Hexagon counts of crimes
*	3. Hexagon counts of crimes
*	4. Merge crimes and lights
*	5. Repeat for 2-hour day buffer
*******************************************************************************/
clear
cd ${data_folder_temp}
*set locals
local crimetypes total gun violent property nuisance placebo

local crimetypesno gun violent property nuisance placebo

*and for later lambda function
// Create a local macro to hold the transformed variable names
local lambdatypes

// Loop through each variable and transform it
foreach var in `crimetypes' cumulative {
    local lambdatypes "`lambdatypes' lambda_`var'"
}
*To check: di "`lambdatypes'"
di "`crimetypes'"
// Save the transformed variable names into a local macro
local lambdatypes "`lambdatypes'"

// Display the local macro to verify
display "`lambdatypes'"
display "`crimetypes'"
display "`crimetypesno'"

********************************************************************************	
***********************1. Integrate crime and lights data***********************
********************************************************************************

cap mkdir kde/merged

foreach j in all outside inside {
    foreach i in all day night {
        use "kde/stacked/`i'/`j'/Kde_total`i'`j'.dta", clear

        foreach var of varlist ndp edgecorrect A c lambda p counter {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                rename `var' `var'_total
            } 
			else {
                display "Variable `var' not found in kde_total`i'`j'.dta"
            }
        }

        foreach x of local crimetypesno {
            // Check if the file exists
            capture confirm file "kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
            if _rc == 0 {
                merge 1:1 spgrid_id ym using "kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
                
                if _rc != 0 {
                    display "Merge failed for kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
                }

                foreach var of varlist ndp edgecorrect A c lambda p counter {
                    // Check if the variable exists
                    capture confirm variable `var'
                    if _rc == 0 {
                        rename `var' `var'_`x'
                    } 
					else {
                        display "Variable `var' not found in kde_`x'`i'`j'.dta"
                    }
                }
                drop _merge
            } 
			else {
                display "File kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta not found"
            }
        }

        merge 1:1 spgrid_id ym using "kde/lights/Kde_lights.dta"

        if _rc != 0 {
            display "Merge failed for kde/lights/Kde_lights.dta"
        }

        foreach var of varlist ndp edgecorrect A c lambda p counter {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                rename `var' `var'_lights
            } 
			else {
                display "Variable `var' not found in kde_lights.dta"
            }
        }

        // Fill in the values for lights going down the list
        by spgrid_id: gen lambda_cum = sum(lambda_lights)
        by spgrid_id: gen lights_cum = sum(ndp_lights)

        // Convert kde into square meters 649519 = (3*sqrt(3))/2*(500^2)
        foreach var of local lambdatypes {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                gen `var'r = `var' * 649519
            } 
			else {
                display "Variable `var' not found for conversion to square meters"
            }
        }
		//now for additional variables lambda_cum and lights_cum
		// Convert kde into square meters 649519 = (3*sqrt(3))/2*(500^2)
        foreach var of varlist lambda_cum lambda_lights {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                gen `var'r = `var' * 649519
            } 
			else {
                display "Variable `var' not found for conversion to square meters"
            }
        }

        save "kde/merged/kde_merged_`i'`j'.dta", replace
    }
}

********************************************************************************
*************************2. Hexagon counts of crimes ***************************
***************************'****************************************************
cap mkdir counts
set varabbrev on

// Loop through each combination of outside/inside and day/night
foreach j in all outside inside {
    foreach i in all day night {
        use "allcrimes.dta", clear
		drop _merge
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylight == 1
        }
        else if "`i'" == "night" {
            keep if daylight == 0
        }
		else if "`i'" == "all" {
        
        }
        
        // Filter data based on inside/outside
        if "`j'" == "outside" {
            keep if outside == 1
        }
        else if "`j'" == "inside" {
            keep if outside == 0
        }
		 else if "`j'" == "all" {

		 }

        // Run geoinpoly and merge
        geoinpoly _Y _X using "${data_folder_raw}/mapping/PHL-GridCells.dta", noproject
        rename _ID spgrid_id
        merge m:1 spgrid_id using "${data_folder_raw}/mapping/PHL-GridPoints.dta"
        keep if _merge == 3
        
        // Drop missing values in 'ym'
        drop if ym == .
        
        // Collapse data and set time series
        collapse (sum) `crimetypes', by(spgrid_id ym)
        tsset spgrid_id ym
        tsfill, full
        
        // Recode missing values
        foreach var of local crimetypes {
            recode `var' (. = 0)
        }
        
        // Save the dataset
        save "counts/hex_crime_`i'`j'.dta", replace
    }
}


********************************************************************************
*************************3. Hexagon counts of lights****************************
********************************************************************************

**lights** measures locations of two lights when they are multiple on the same pole*
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




*join blocks
geoinpoly _Y _X using "${data_folder_raw}/mapping/PHL-GridCells.dta", noproject

rename _ID spgrid_id

merge m:1 spgrid_id using  "${data_folder_raw}/mapping/PHL-GridPoints.dta"

keep if _merge==3

gen lights=1

drop if ym==.

collapse (sum) lights, by(spgrid_id ym)

tsset spgrid_id ym

tsfill, full

recode lights (.=0)
sort spgrid_id ym
by spgrid_id,: gen lights_sum=sum(lights)

save "counts/hex_lights.dta", replace


********************************************************************************
*************************4. Merge crime and lights****************************
********************************************************************************

foreach j in all outside inside {
    foreach i in all day night {
**merge hexagon counts
use "kde/merged/kde_merged_`i'`j'.dta", clear
merge 1:1 spgrid_id ym using "counts/hex_crime_`i'`j'.dta", generate(hex_crime)
merge 1:1 spgrid_id ym using "counts/hex_lights.dta", generate(hex_light)
replace lights_sum=0 if hex_light==1
*recode non-linked to equal zero for total
recode total (.=0)

*link to region
geoinpoly spgrid_ycoord spgrid_xcoord using "${data_folder_raw}/mapping/Region_mercator.dta", noproject
rename _ID region

save "${data_folder_processed}/`i'`j'.dta", replace
}
}


********************************************************************************
****************************5. CATEGORY TABLES to check**********************************
********************************************************************************
cap mkdir tables
use "counts/hex_crime_allall.dta", clear
* to check: total part1, over(ym)
collapse (sum) `crimetypes', by(ym)
export excel using "tables/monthcounts.xlsx", sheet("All Times") first(variables) replace

foreach j in all outside inside {
    foreach i in all day night {
use "counts/hex_crime_`i'`j'.dta", clear
collapse (sum) `crimetypes', by(ym)
export excel using "tables/monthcounts.xlsx", sheet("`i' `j'") first(variables) sheetreplace
	}
}


********************************************************************************	
***********************5. Repeat for 2-hour day buffer**************************
********************************************************************************
clear

local crimetypes total gun violent property nuisance placebo

local crimetypesno gun violent property nuisance placebo

*and for later lambda function
// Create a local macro to hold the transformed variable names
local lambdatypes

// Loop through each variable and transform it
foreach var in `crimetypes' cumulative {
    local lambdatypes "`lambdatypes' lambda_`var'"
}
*To check: di "`lambdatypes'"
di "`crimetypes'"
// Save the transformed variable names into a local macro
local lambdatypes "`lambdatypes'"

// Display the local macro to verify
display "`lambdatypes'"
display "`crimetypes'"
display "`crimetypesno'"

cap mkdir buffer/kde/merged
*Integrate
foreach j in all outside inside {
    foreach i in all day night {
        use "buffer/kde/stacked/`i'/`j'/Kde_total`i'`j'.dta", clear

        foreach var of varlist ndp edgecorrect A c lambda p counter {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                rename `var' `var'_total
            } 
			else {
                display "Variable `var' not found in kde_total`i'`j'.dta"
            }
        }

        foreach x of local crimetypesno {
            // Check if the file exists
            capture confirm file "buffer/kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
            if _rc == 0 {
                merge 1:1 spgrid_id ym using "buffer/kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
                
                if _rc != 0 {
                    display "Merge failed for buffer/kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta"
                }

                foreach var of varlist ndp edgecorrect A c lambda p counter {
                    // Check if the variable exists
                    capture confirm variable `var'
                    if _rc == 0 {
                        rename `var' `var'_`x'
                    } 
					else {
                        display "Variable `var' not found in kde_`x'`i'`j'.dta"
                    }
                }
                drop _merge
            } 
			else {
                display "File kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta not found"
            }
        }

        merge 1:1 spgrid_id ym using "buffer/kde/lights/Kde_lights.dta"

        if _rc != 0 {
            display "Merge failed for buffer/kde/lights/Kde_lights.dta"
        }

        foreach var of varlist ndp edgecorrect A c lambda p counter {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                rename `var' `var'_lights
            } 
			else {
                display "Variable `var' not found in kde_lights.dta"
            }
        }

        // Fill in the values for lights going down the list
        by spgrid_id: gen lambda_cum = sum(lambda_lights)
        by spgrid_id: gen lights_cum = sum(ndp_lights)

        // Convert kde into square meters 649519 = (3*sqrt(3))/2*(500^2)
        foreach var of local lambdatypes {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                gen `var'r = `var' * 649519
            } 
			else {
                display "Variable `var' not found for conversion to square meters"
            }
        }
		//now for additional variables lambda_cum and lights_cum
		// Convert kde into square meters 649519 = (3*sqrt(3))/2*(500^2)
        foreach var of varlist lambda_cum lambda_lights {
            // Check if the variable exists
            capture confirm variable `var'
            if _rc == 0 {
                gen `var'r = `var' * 649519
            } 
			else {
                display "Variable `var' not found for conversion to square meters"
            }
        }

        save "buffer/kde/merged/kde_merged_`i'`j'.dta", replace
    }
}

*2. hexagon counts
cap mkdir buffer/counts
set varabbrev on

// Loop through each combination of outside/inside and day/night
foreach j in all outside inside {
    foreach i in all day night {
        use "allcrimes.dta", clear
		drop _merge
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylight == 1
        }
        else if "`i'" == "night" {
            keep if daylight == 0
        }
		else if "`i'" == "all" {
        
        }
        
        // Filter data based on inside/outside
        if "`j'" == "outside" {
            keep if outside == 1
        }
        else if "`j'" == "inside" {
            keep if outside == 0
        }
		 else if "`j'" == "all" {

		 }

        // Run geoinpoly and merge
        geoinpoly _Y _X using "${data_folder_raw}/mapping/PHL-GridCells.dta", noproject
        rename _ID spgrid_id
        merge m:1 spgrid_id using "${data_folder_raw}/mapping/PHL-GridPoints.dta"
        keep if _merge == 3
        
        // Drop missing values in 'ym'
        drop if ym == .
        
        // Collapse data and set time series
        collapse (sum) `crimetypes', by(spgrid_id ym)
        tsset spgrid_id ym
        tsfill, full
        
        // Recode missing values
        foreach var of local crimetypes {
            recode `var' (. = 0)
        }
        
        // Save the dataset
        save "buffer/counts/hex_crime_`i'`j'.dta", replace
    }
}

*hexagon light counts

**lights** measures locations of two lights when they are multiple on the same pole*
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




*join blocks
geoinpoly _Y _X using "${data_folder_raw}/mapping/PHL-GridCells.dta", noproject

rename _ID spgrid_id

merge m:1 spgrid_id using  "${data_folder_raw}/mapping/PHL-GridPoints.dta"

keep if _merge==3

gen lights=1

drop if ym==.

collapse (sum) lights, by(spgrid_id ym)

tsset spgrid_id ym

tsfill, full

recode lights (.=0)
sort spgrid_id ym
by spgrid_id,: gen lights_sum=sum(lights)

save "buffer/counts/hex_lights.dta", replace


*Merge crime and lights, kde and hexagons 
cap mkdir ${data_folder_processed}/buffer

foreach j in all outside inside {
    foreach i in all day night {
**merge hexagon counts
use "buffer/kde/merged/kde_merged_`i'`j'.dta", clear
merge 1:1 spgrid_id ym using "buffer/counts/hex_crime_`i'`j'.dta", generate(hex_crime)
merge 1:1 spgrid_id ym using "buffer/counts/hex_lights.dta", generate(hex_light)
replace lights_sum=0 if hex_light==1
*recode non-linked to equal zero for total
recode total (.=0)

*link to region
geoinpoly spgrid_ycoord spgrid_xcoord using "${data_folder_raw}/mapping/Region_mercator.dta", noproject
rename _ID region

save "${data_folder_processed}/buffer/`i'`j'.dta", replace
}
}
