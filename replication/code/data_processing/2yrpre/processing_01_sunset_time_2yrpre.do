/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_01_sunset_time_2yrpre.do
*	Script purpose: Create dataset of daily sunrise, sunset, civil twilight times
*	Output: suntimes.dta for use in processing_2_crime_data_creation.do
*	Author: Maya Moritz
*******************************************************************************/
cap mkdir ${data_folder_temp}/2yrpre/
cap mkdir ${data_folder_raw}/2yrpre/
cap mkdir ${data_folder_processed}/2yrpre/
cd ${data_folder_raw}
clear
set obs `=date("2024-05-31", "YMD") - date("2020-01-01", "YMD") + 1'
gen date = date("2020-01-01", "YMD") + _n - 1
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
	*display s[`i']
replace ctb = regexs(4) if regexm(s[_n], "(<th>Civil Twilight Begins<br>)(.*)(<td>)([0-9]:[0-9][0-9] A.M.)(</td>)")
    replace cte = regexs(4) if regexm(s[_n], "(<th>Civil Twilight Ends<br>)(.*)(<td>)([0-9]:[0-9][0-9] P.M.)(</td>)(.*)(<th>Nautical Twilight Ends)") in `i'
    replace sunrise = regexs(4) if regexm(s[_n], "(<th class='rise_highlight'>Sunrise</th>)(.*)(<td class='rise_highlight'>)([0-9]:[0-9][0-9] A.M.)(</td>)") in `i'
    replace sunset = regexs(4) if regexm(s[_n], "(<th class='rise_highlight'>Sunset</th>)(.*)(<td class='rise_highlight'>)([0-9]:[0-9][0-9] P.M.)(</td>)") in `i'
}

* Remove intermediate variable
drop s

*Clean up to match crimes
rename date eventdate
*time 


*classify daylight times according to civil twilight
gen ctb_time=ctb
gen double clock = clock(ctb_time, "hm")
format clock %tc
gen double hour = hhC(clock)
save "${data_folder_raw}/2yrpre/suntimes.dta", replace

