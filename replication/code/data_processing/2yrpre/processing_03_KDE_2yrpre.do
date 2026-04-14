/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_03_KDE_2yrpre.do
*	Script purpose: Create KDE crime & shooting categories for Appendix Table 5
*	Author: Maya Moritz, amended script from John MacDonald
*	Organization:
*	1. Calculate KDEs
*	2. Stack KDEs
*	4. Repeat process for 2-hour day buffer
*******************************************************************************/
cap mkdir ${data_folder_temp}/2yrpre/kde
cap mkdir ${data_folder_temp}/2yrpre/stacked
cap mkdir ${data_folder_temp}/2yrpre/buffer

********************************************************************************
****************************1. Calculate KDEs***********************************
********************************************************************************
*make kde for each major offense category and each year-month*
*create file paths
cd ${data_folder_raw}

cap mkdir kde
    foreach i in all day night {
cap mkdir kde/`i'
	}

local crimetypes total gun violent property nuisance placebo

    foreach i in all day night {
        use "${data_folder_temp}/2yrpre/allcrimes.dta", clear
        
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylight == 1
        }
        else if "`i'" == "night" {
            keep if daylight == 0
        }
        
        // Loop over crimetypes
        foreach x of local crimetypes {
            display "`i' `x'"
            
            // Loop over year-month combinations
            forval t = 720/772 {
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
                    noverbose saving("${data_folder_temp}/2yrpre/kde/Kde_`x'`i'`t'.dta", replace)
            }
        }
    }



********************************************************************************
*******************************2. Stack KDEs************************************
********************************************************************************
local crimetypes total gun violent property nuisance placebo

cap mkdir kde/stacked

foreach i in all day night{
		cap mkdir kde/stacked/`i'


foreach x of local crimetypes {
        local basefile "${data_folder_temp}/2yrpre/kde/Kde_`x'`i'720.dta"
        
        // Check if the base file exists
        if !fileexists("`basefile'") {
            display "`basefile' does not exist. Skipping to the next."
            continue
        }

        use "`basefile'", clear
        
        foreach num of numlist 721/772 {
            local appendfile "${data_folder_temp}/2yrpre/kde/Kde_`x'`i'`num'.dta"
            
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

by spgrid_id,: gen ym=[_n]+719

save "${data_folder_temp}/2yrpre/stacked/Kde_`x'`i'.dta", replace
}
}



********************************************************************************
********************4. Repeat Process for 2-hour day buffer*********************
********************************************************************************
cap mkdir buffer
cap mkdir buffer/kde
    foreach i in all day night {
cap mkdir buffer/kde/`i'
}

local crimetypes total gun violent property nuisance placebo

    foreach i in all day night {
        use "${data_folder_temp}/2yrpre/allcrimes.dta", clear
        
        // Filter data based on time of day
        if "`i'" == "day" {
            keep if daylightbuffer == 1
        }
        else if "`i'" == "night" {
            keep if daylightbuffer == 0
        }
        
        // Loop over crimetypes
        foreach x of local crimetypes {
            display "`i' `x'"
            
            // Loop over year-month combinations
            forval t = 720/772 {
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
                    noverbose saving("${data_folder_temp}/2yrpre/buffer/Kde_`x'`i'`t'.dta", replace)
            }
        }
    }



*Stack
cap mkdir buffer/kde/stacked

foreach i in all day night{
		cap mkdir buffer/kde/stacked/`i'

foreach x of local crimetypes {
        local basefile "${data_folder_temp}/2yrpre/buffer/Kde_`x'`i'720.dta"
        
        // Check if the base file exists
        if !fileexists("`basefile'") {
            display "`basefile' does not exist. Skipping to the next."
            continue
        }

        use "`basefile'", clear
        
        foreach num of numlist 721/772 {
            local appendfile "${data_folder_temp}/2yrpre/buffer/Kde_`x'`i'`num'.dta"
            
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

by spgrid_id,: gen ym=[_n]+719

save "${data_folder_temp}/2yrpre/buffer/Kde_`x'`i'.dta", replace
}
}
