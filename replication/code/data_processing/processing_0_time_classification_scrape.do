/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_0_time_classification_scrape.d0
*	Script purpose: Create dataset of daily sunrise, sunset, civil twilight times
*	Input: None
*	Output: suntimes.dta for use in processing_2_crime_data_creation.do
*	Author: Maya Moritz
*   Note: This code no longer works for the webscrape as the website html has 
			changed and continues to do so routinely. 
			We suggest using the suntimes.dta file directly.
*******************************************************************************/

clear
set obs `=date("2024-05-31", "YMD") - date("2022-07-01", "YMD") + 1'
gen date = date("2022-07-01", "YMD") + _n - 1
format date %td

* Create variables to store results
gen s = ""
gen ctb = ""
gen cte = ""
gen sunrise = ""
gen sunset = ""

* Loop through dates
forvalues i = 1/`=_N' {
    local current_date = date[`i']
    local formatted_date : display %tdCCYY-NN-DD `current_date'
    di "Processing `formatted_date'"

    * Download and extract data for the current date
    replace s = fileread("https://www.almanac.com/astronomy/sun-rise-and-set/PA/Philadelphia/`formatted_date'") in `i'
    replace ctb = regexs(4) if regexm(s[_n], "(<th>Civil Twilight Begins<br><span class='rise_definition'>the sun’s center is 6&deg; below the horizon</span></th>)(.*)(<td>)([0-9]:[0-9][0-9] A.M.)(</td>)") in `i'
    replace cte = regexs(4) if regexm(s[_n], "(<th>Civil Twilight Ends<br><span class='rise_definition'>the sun’s center is 6&deg; below the horizon</span></th>)(.*)(<td>)([0-9]:[0-9][0-9] P.M.)(</td>)(.*)(<th>Nautical Twilight Ends<br>)") in `i'
    replace sunrise = regexs(4) if regexm(s[_n], "(<th class='rise_highlight'>Sunrise</th>)(.*)(<td class='rise_highlight'>)([0-9]:[0-9][0-9] A.M.)(</td>)") in `i'
    replace sunset = regexs(4) if regexm(s[_n], "(<th class='rise_highlight'>Sunset</th>)(.*)(<td class='rise_highlight'>)([0-9]:[0-9][0-9] P.M.)(</td>)") in `i'
}

* Remove intermediate variable
drop s

*Clean up to match crime name variables
rename date eventdate

*classify daylight times according to civil twilight
gen ctb_time=ctb
gen double clock = clock(ctb_time, "hm")
format clock %tc
gen double hour = hhC(clock)

save "${data_folder_raw}/suntimes.dta", replace
