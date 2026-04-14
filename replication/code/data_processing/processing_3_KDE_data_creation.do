/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_3_KDE_data_creation.do
*	Script purpose: Create crime and shooting categories
*	Author: Maya Moritz, amended script from John MacDonald
*	Input: ${data_folder_temp}/allcrimes.dta
*	Output: ${data_folder_temp}/buffer/kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta
*	Organization: 
*	1. Calculate KDEs
*	2. Stack KDEs
*	3. Make maps- commented out to save time
*	4. Repeat process for 2-hour day buffer
*******************************************************************************/

********************************************************************************
****************************1. Calculate KDEs***********************************
********************************************************************************
*make kde for each major offense category and each year-month*
*create file paths
cd ${data_folder_temp}

cap mkdir kde
foreach j in all outside inside {
    foreach i in all day night {
cap mkdir kde/`i'
cap mkdir kde/`i'/`j'
	}
}

local crimetypes total gun violent property nuisance placebo

foreach j in all outside inside {
    foreach i in all day night {
        use "allcrimes.dta", clear
        
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylight == 1
        }
        else if "`i'" == "night" {
            keep if daylight == 0
        }
        
        // Filter data based on inside/outside
        if "`j'" == "outside" {
            keep if outside == 1
        }
        else if "`j'" == "inside" {
            keep if outside == 0
        }
        // Loop over crimetypes
        foreach x of local crimetypes {
            display "`i' `j' `x'"
            
            // Loop over year-month combinations
            forval t = 750/772 {
                // Count the number of observations that satisfy the condition
                count if ym == `t' & `x' == 1
                
                // If no observations, skip to the next iteration
                if r(N) == 0 {
                    continue
                }
                
                // Run spkde if observations exist
                spkde using "${data_folder_raw}/mapping/PHL-GridPoints.dta" if ym == `t' & `x' == 1, /// 
                    xcoord(_X) ycoord(_Y) /// 
                    bandwidth (fbw) fbw(1000) dots /// 
                    edgecorrection /// 
                    noverbose saving("kde/`i'/`j'/Kde_`x'`i'`j'`t'.dta", replace)
            }
        }
    }
}


********************************************************************************
*******************************2. Stack KDEs************************************
********************************************************************************
local crimetypes total gun violent property nuisance placebo

cap mkdir kde/stacked

foreach j in all outside inside{
foreach i in all day night{
		cap mkdir kde/stacked/`i'
		cap mkdir kde/stacked/`i'/`j'

foreach x of local crimetypes {
        local basefile "kde/`i'/`j'/Kde_`x'`i'`j'750.dta"
        
        // Check if the base file exists
        if !fileexists("`basefile'") {
            display "`basefile' does not exist. Skipping to the next."
            continue
        }

        use "`basefile'", clear
        
        foreach num of numlist 751/772 {
            local appendfile "kde/`i'/`j'/Kde_`x'`i'`j'`num'.dta"
            
            // Check if the file to be appended exists
            if fileexists("`appendfile'") {
                append using "`appendfile'"
            } 
			else {
                display "`appendfile' does not exist. Skipping."
            }
        }
gen counter=_n
sort spgrid_id counter

by spgrid_id,: gen ym=[_n]+749

save "kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta", replace
}
}
}



********************************************************************************
******************************3. Make Maps**************************************
********************************************************************************
/*
cap mkdir kde/maps

*now for day and night by outside or inside:
foreach j in all outside inside{
foreach i in all day night{
		cap mkdir kde/maps/`i'
		cap mkdir kde/maps/`i'/`j'
		cap mkdir kde/maps/`i'/`j'/lambda
foreach x of local crimetypes {
use "kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta", clear

collapse (mean) ndp lambda, by(spgrid_id)

spmap lambda using "PHL-GridCells.dta",  /// 
	id(spgrid_id) clnum(10) fcolor(Rainbow) ocolor(none ..) legend(size(medium) position(4)) ///
	title ("Density of `j' `x' Crimes at time `i'", size(*1.0))  ///
	note ("Per 1000 meters", size(medium) position(6))
	graph export "kde/maps/`i'/`j'/lambda/Kdelambda_`x'`i'`j'.png", replace
	cap mkdir kde/maps/`i'/`j'/ndp
spmap ndp using "PHL-GridCells.dta",  /// 
	id(spgrid_id) clnum(10) fcolor(Rainbow) ocolor(none ..) legend(size(medium) position(4)) ///
	title ("Number of `j' `x' Crimes at time `i'", size(*1.0))  ///
	note ("Per Hexagon", size(medium) position(6))
	graph export "kde/maps/`i'/`j'/ndp/Kdendp_`x'`i'`j'.png", replace
}
}
}
*/

********************************************************************************
********************4. Repeat Process for 2-hour day buffer*********************
********************************************************************************
cap mkdir buffer
cap mkdir buffer/kde
foreach j in all outside inside {
    foreach i in all day night {
cap mkdir buffer/kde/`i'
cap mkdir buffer/kde/`i'/`j'
	}
}

local crimetypes total gun violent property nuisance placebo

foreach j in all outside inside {
    foreach i in all day night {
        use "allcrimes.dta", clear
        
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylightbuffer == 1
        }
        else if "`i'" == "night" {
            keep if daylightbuffer == 0
        }
        
        // Filter data based on inside/outside
        if "`j'" == "outside" {
            keep if outside == 1
        }
        else if "`j'" == "inside" {
            keep if outside == 0
        }
        // Loop over crimetypes
        foreach x of local crimetypes {
            display "`i' `j' `x'"
            
            // Loop over year-month combinations
            forval t = 750/772 {
                // Count the number of observations that satisfy the condition
                count if ym == `t' & `x' == 1
                
                // If no observations, skip to the next iteration
                if r(N) == 0 {
                    continue
                }
                
                // Run spkde if observations exist
                spkde using "${data_folder_raw}/mapping/PHL-GridPoints.dta" if ym == `t' & `x' == 1, /// 
                    xcoord(_X) ycoord(_Y) /// 
                    bandwidth (fbw) fbw(1000) dots /// 
                    edgecorrection /// 
                    noverbose saving("buffer/kde/`i'/`j'/Kde_`x'`i'`j'`t'.dta", replace)
            }
        }
    }
}


*Stack
cap mkdir buffer/kde/stacked

foreach j in all outside inside{
foreach i in all day night{
		cap mkdir buffer/kde/stacked/`i'
		cap mkdir buffer/kde/stacked/`i'/`j'

foreach x of local crimetypes {
        local basefile "buffer/kde/`i'/`j'/Kde_`x'`i'`j'750.dta"
        
        // Check if the base file exists
        if !fileexists("`basefile'") {
            display "`basefile' does not exist. Skipping to the next."
            continue
        }

        use "`basefile'", clear
        
        foreach num of numlist 751/772 {
            local appendfile "buffer/kde/`i'/`j'/Kde_`x'`i'`j'`num'.dta"
            
            // Check if the file to be appended exists
            if fileexists("`appendfile'") {
                append using "`appendfile'"
            } 
			else {
                display "`appendfile' does not exist. Skipping."
            }
        }
gen counter=_n
sort spgrid_id counter

by spgrid_id,: gen ym=[_n]+749

save "buffer/kde/stacked/`i'/`j'/Kde_`x'`i'`j'.dta", replace
}
}
}
