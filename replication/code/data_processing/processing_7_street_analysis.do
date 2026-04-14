/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_7_street_analyss.do
*	Script purpose: create street-level data for Table 4
*	Author: Maya Moritz
*	Input: ${data_folder_temp}/streets/ content
*	Output: ${data_folder_processed}/adjacent_nonadjacent_street_sample.dta
*******************************************************************************/
clear
eststo clear
********************************************************************************
********************************************************************************
************************* 1. LIGHT-STREET DATA *********************************
********************************************************************************
********************************************************************************

********************************************************************************
************************* A. LINK LIGHTS AND STREETS ***************************
********************************************************************************

import delimited "${data_folder_temp}/streets/lights_streets.csv", clear 

*date variables*
gen eventdate=date(installcompleteddatetime, "YMD####")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
tab year
gen ym=ym(year, month)
format ym %tm 
drop if ym==.

encode uniqueidentifier, gen(id)
rename in57blocksquartermile top57
rename intop10nightimecrime top10crime 
rename intop10nighttimecollisions top10crash

foreach var of varlist top57* top10* {
	replace `var'="0" if `var'=="NA"
	replace `var'="1" if `var'=="Yes"
	destring `var', replace
}

collapse (count) id, by (ym seg_id) 

drop if seg_id==.
sort seg_id ym
*there are duplicates so need to create a running count*
by seg_id,: gen lights=sum(id)

*now save lights and then same thing for crime
save "${data_folder_temp}/streets/street_lightcount.dta", replace
keep seg_id 
gen treated = 1
duplicates drop
save "${data_folder_temp}/streets/treated_street_list.dta", replace


********************************************************************************
**************** B. ADD PRIORITY STATUS TO STREET_LIGHTCOUNT.DTA ***************
********************************************************************************

import delimited "${data_folder_temp}/streets/lights_streets.csv", clear 

*date variables*
gen eventdate=date(installcompleteddatetime, "YMD####")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
tab year
gen ym=ym(year, month)
format ym %tm 
drop if ym==.

encode uniqueidentifier, gen(id)
rename in57blocksquartermile top57
rename intop10nightimecrime top10crime 
rename intop10nighttimecollisions top10crash

foreach var of varlist top57* top10* {
	replace `var'="0" if `var'=="NA"
	replace `var'="1" if `var'=="Yes"
	destring `var', replace
}

collapse (first) top57 top10crime top10crash, by (seg_id) 

save "${data_folder_temp}/streets/priority_lights.dta", replace

use "${data_folder_temp}/streets/street_lightcount.dta", clear
merge m:1 seg_id using "${data_folder_temp}/streets/priority_lights.dta"
drop if _merge==2
drop _merge

save "${data_folder_temp}/streets/street_lightcount.dta", replace


********************************************************************************
********************************************************************************
*************************** 2. MAKE INTO TIME SERIES ***************************
********************************************************************************
********************************************************************************

use "${data_folder_temp}/streets/street_lightcount.dta", clear

tsset seg_id ym
tsfill, full

foreach var of varlist top57 top10crash top10crime lights {
 bysort seg_id,: egen m`var'=max(`var')
 }

*date of first install seems wrong- choosing later date ????
gen ym_first=ym if id~=.
format ym_first %tm
bysort seg_id,: egen ym_install=max(ym_first)
*should this be min not max? Changing to min until we can discuss
bysort seg_id,: egen ym_install_min=min(ym_first)

format ym_install %tm
format ym_install_min %tm

drop ym_first top57 top10crime top10crash 

rename mtop* top*

save "${data_folder_temp}/streets/street_lightcount.dta", replace


********************************************************************************
********************************************************************************
****************************** 3. SHOOTINGS DATA *******************************
********************************************************************************
********************************************************************************
*first want to extract dc_key to use to weed out multiples in shootings
*Get unique dc_keys for crimes
import delimited "${data_folder_temp}/streets/crime_streets.csv", clear 

keep dc_key
duplicates report dc_key
duplicates drop
save "${data_folder_temp}/streets/crime_dckeys.dta", replace

*same for shootings
*read in shooting data*
import delimited "${data_folder_temp}/streets/shooting_streets.csv", clear 
*merge shooting data to crime dc keys
merge m:1 dc_key using "${data_folder_temp}/streets/crime_dckeys.dta"
*just keep the shootings that don't match to crime dc_keys
keep if _merge == 1
drop _merge

tab year
drop year
gen eventdate=date(date_, "YMD####")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
tab year
gen ym=ym(year, month)
format ym %tm  
gen shooting=1
drop if ym<750

*change format of crime times
gen double crime_time = clock(time, "hms")
format crime_time %tc
*collapse (sum) shooting, by (ym seg_id) 
drop if seg_id==.
sort seg_id ym
save "${data_folder_temp}/streets/shooting_streets.dta", replace

********************************************************************************
********************************************************************************
***************************** 4. CATEGORIZE CRIME DATA *************************
********************************************************************************
********************************************************************************

*crime data for streets

import delimited "${data_folder_temp}/streets/crime_streets.csv", clear
gen eventdate=date(dispatch_date, "YMD")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
gen ym=ym(year, month)
format ym %tm  
drop if ym<750 
*change format of crime times
gen double crime_time = clock(dispatch_time, "hms")
format crime_time %tc
tab text_general, gen(crimes)
count if missing(crime_time)

append using "${data_folder_temp}/streets/shooting_streets.dta"
*append shootings
replace shooting = 0 if shooting == .
count if missing(crime_time)

*Crime Categories
*note: these numbers were changed because they oddly did not correspond to the categories in the kde analysis files, e.g. one crime category is missing but it is not a needed one
*2. GUN CRIMES- shooting, gun robbery, gun assault, weapons violation NOT MURDER
gen gun = shooting + crimes25 + crimes1 + crimes31

*3. VIOLENT STREET CRIMES: RAPES, ASSAULT (AGG + SIMPLE + OTHER), MURDER (JUST CRIMINAL), ROBBERY (FIREARM + NO FIREARM), SHOOTINGS THAT ARE NOT MURDERS (DC KEY REMOVAL PROCESS)
gen violent = crimes23 + crimes1 + crimes2 + crimes19 + crimes13 + crimes25 + crimes26 + shooting

*4. STREET PROPERTY CRIME: BURGLARY (BOTH), THEFT (MOTOR VEHICLE + THEFT FROM VEHICLE + THEFTS), VANDALISM/CRIMINAL MISCHIEF
gen property = crimes5 + crimes6 + crimes16 + crimes27 + crimes28 + crimes30

*5. NUISANCE CRIMES: DISORDERLY CONDUCT, PUBLIC DRUNKENNESS, LIQUOR LAW VIOLATIONS, NARCOTICES/DRUG LAW VIOLATIONS
gen nuisance = crimes8 + crimes22 + crimes15 + crimes17

*6. PLACEBO: FRAUD, FORGERY, EMBEZZLEMENT
gen financial = crimes9 + crimes10 + crimes11

gen total_crime=1

*merge to sunlight times generated in processing_0_time_classification.do
*many crimes can occur on the same date so m:1
merge m:1 eventdate using "${data_folder_raw}/suntimes.dta"
 drop if _merge == 1
 drop _merge
*change format of suntimes to match crime times
gen double ctb_time = clock(ctb, "hm")
format ctb_time %tc

gen double cte_time = clock(cte, "hm")
format cte_time %tc

*create a variable to check, deleting the original hour variable as it is not always correct
drop hour
gen double hour = hhC(crime_time)

drop if missing(crime_time)

*classify daylight times according to civil twilight
gen daylight = 0 if crime_time != .
replace daylight = 1 if crime_time >= ctb_time & crime_time < cte_time

*create 2 hour buffer for crimes that likely occured during the day but were classified as night
gen double cte_time_plus2 = cte_time + 7200000
format cte_time_plus2 %tc

gen daylightbuffer = 0 if crime_time != .
replace daylightbuffer = 1 if crime_time >= ctb_time & crime_time < cte_time_plus2

*set up categories for day/night and day/night buffers
* Define the variables that need to be summed
local vars total_crime gun violent property nuisance financial

* Loop over each variable to create the conditional versions for daylight and daylight_buffer
foreach var of local vars {
    * Create conditional variables based on daylight
    gen `var'_day = `var' if daylight == 1
    replace `var'_day = 0 if missing(`var'_day)

    gen `var'_night = `var' if daylight == 0
    replace `var'_night = 0 if missing(`var'_night)

    * Create conditional variables based on daylight_buffer
    gen `var'_day_buffer = `var' if daylightbuffer == 1
    replace `var'_day_buffer = 0 if missing(`var'_day_buffer)

    gen `var'_night_buffer = `var' if daylightbuffer == 0
    replace `var'_night_buffer = 0 if missing(`var'_night_buffer)
}

collapse (sum) total_crime gun violent property nuisance financial ///
        total_crime_day gun_day violent_day property_day nuisance_day financial_day ///
        total_crime_night gun_night violent_night property_night nuisance_night financial_night ///
        total_crime_day_buffer gun_day_buffer violent_day_buffer property_day_buffer nuisance_day_buffer financial_day_buffer ///
        total_crime_night_buffer gun_night_buffer violent_night_buffer property_night_buffer nuisance_night_buffer financial_night_buffer, ///
        by(ym seg_id)
		
local vars total_crime gun violent property nuisance financial


save "${data_folder_temp}/streets/crime_streets.dta", replace

********************************************************************************
********************************************************************************
*********************** 5. COMBINE SHOOTINGS, CRIME, LIGHTS ********************
********************************************************************************
********************************************************************************

*now merge crime with lights with entire street segments*
use "${data_folder_temp}/streets/crime_streets.dta", clear
tsset seg_id ym
tsfill, full

*fill in the zero values
foreach var of varlist total_crime gun violent property nuisance financial {
	recode `var' (.=0)
	}

*merge with streets - ignore this code because if there is always zero crime it contributes nothing to the analysis
*merge m:1 seg_id using "streets.dta", generate(m_street)
*keep only streets that have some crime at some point in the time series
merge m:1 seg_id ym using "${data_folder_temp}/streets/street_lightcount.dta", generate(m_lights)
*check total number of unique streets with either crime or lights
codebook seg_id


tsset seg_id ym
tsfill, full

*this is to get the panel completely rectangular*
foreach var of varlist lights top57 top10crash top10crime mlights ym_install_min ym_install {
	bysort seg_id: carryforward `var', gen(`var'n)
	}

foreach var of varlist top57n top10crashn top10crimen mlightsn ym_install_minn ym_installn {
	bysort seg_id,: egen `var'min=min(`var')
	}
	
replace top57n=top57nmin if top57n==.
replace top10crashn=top10crashnmin if top10crashn==.
replace top10crimen=top10crimenmin if top10crimen==.
replace mlightsn=mlightsnmin if mlightsn==.
replace ym_installn=ym_installnmin if ym_installn==.
replace ym_install_minn=ym_install_minnmin if ym_install_minn==.

drop top57nmin top10crashnmin top10crimenmin ym_install_minnmin ym_installnmin mlightsnmin
recode lightsn (.=0)
save "${data_folder_temp}/streets/crime_lights_streets_panel.dta", replace

********************************************************************************
********************************************************************************
***************************** 6. ADJACENT BLOCKS *******************************
********************************************************************************
********************************************************************************

********************************************************************************
******************* A. IDENTIFY TREATMENT, ADJ, AND NON-ADJ ********************
********************************************************************************
*get list of treated street segments
use "${data_folder_temp}/streets/street_lightcount.dta", clear
keep seg_id 
duplicates drop
save "${data_folder_temp}/streets/treated_street_list", replace


*drop streets adjacent to themselves from adjacent segments file
import delimited "${data_folder_temp}/streets/joined_segments.csv", clear

rename seg_idx seg_id
rename seg_idy seg_idn

gen SEG_ID=seg_id

gen diff=seg_id-seg_idn

keep seg_id seg_idn diff
drop if diff==0
drop diff

*1. Identify treated segments
*merge on the seg_id of the reference street segment
*now we have many versions of seg_id and 1 each of the treated for light count so m:1
merge m:1 seg_id using "${data_folder_temp}/streets/treated_street_list.dta"

gen treated_seg = 1000
replace treated_seg = 1 if _merge == 3
replace treated_seg = 0 if _merge == 1
label var treated "Treated if ever receives lights, 1 if treated and 0 if not"
drop _merge

*2. Identify if adjacent street is treated
rename seg_id original_seg
rename seg_idn seg_id
*now merge on the seg_id of the neighboring street segment
merge m:1 seg_id using "${data_folder_temp}/streets/treated_street_list.dta"

gen treated_neighbor = 1000
replace treated_neighbor = 1 if _merge == 3
replace treated_neighbor = 0 if _merge == 1
drop _merge

*just keep ones that are not treated
drop if treated_seg == 1
drop treated_seg
*revert names
rename seg_id seg_idn
rename original_seg seg_id 

*3. reshape data so each street street has one row
bysort seg_id: gen n = _n
reshape wide seg_idn treated_neighbor, i(seg_id) j(n)

egen total_treated_neighbors = rowtotal(treated_neighbor*)
gen adjacent = 0
replace adjacent = 1 if total_treated_neighbors > 0
label var adjacent "Adjacent if adjacent to at least 1 treated street"
gen nonadjacent = 0
replace nonadjacent = 1 if total_treated_neighbors == 0
label var nonadjacent "Nonadjacent if not adjacent to at least 1 treated street"

*now: 27,919 total in sample, 11,635 adjacent and 16,284 non-adjacent
save "${data_folder_temp}/streets/streetline_adjacent.dta", replace

********************************************************************************
******************* B. IDENTIFY INTENSITY OF TREATMENT FOR ADJ *****************
********************************************************************************
use "${data_folder_temp}/streets/streetline_adjacent.dta", clear
*only need intensity for adjacent streets
keep if adjacent == 1
drop total_treated_neighbors adjacent nonadjacent
*reshape so street and neighbor with each pair as row
reshape long seg_idn treated_neighbor, i(seg_id) j(n)
*only using the neighbors that are treated to determine intensity of treatment
keep if treated_neighbor == 1
*now have a dataset of only adjacent streets and their neighboring treated street
rename seg_id reference_street
rename seg_idn seg_id

*each seg_id for the adjacent streets can appear multiple times and will match to multiple seg_ids in panel where we can get intensity of treatment
joinby seg_id using "${data_folder_temp}/streets/crime_lights_streets_panel.dta"
sort reference_street seg_id ym
keep reference_street seg_id ym lightsn

*add up lights for each reference street and period
collapse (sum) lightsn, by(reference_street ym)
rename reference_street seg_id
rename lightsn adj_lights
save "${data_folder_temp}/streets/adj_streets_with_intensity.dta", replace

********************************************************************************
******************* C. COMBINE ADJ, TREAT, NON INTO PANEL **********************
********************************************************************************
*create nonadjacent street file to append
*save just seg_id and nonadjacent for nonadjacent streets
use "${data_folder_temp}/streets/streetline_adjacent.dta", clear
keep seg_id nonadjacent
keep if nonadjacent == 1

save "${data_folder_temp}/streets/nonadjacent_streets.dta", replace


*append adj and nonadj into main panel
use "${data_folder_temp}/streets/crime_lights_streets_panel.dta", clear
merge m:1 seg_id using "${data_folder_temp}/streets/nonadjacent_streets.dta"
count if missing(violent)
drop if missing(violent)
*I think some rows with zero crime were somehow kept
drop if _merge == 2
drop _merge
replace nonadjacent = 0 if nonadjacent==.
*for adjoining streets have seg_id ym, adj_lights
merge 1:1 seg_id ym using "${data_folder_temp}/streets/adj_streets_with_intensity.dta"
drop if _merge ==2
gen adjacent = 0
*replace adjacent = 1 if adj_lights !=.
replace adjacent = 1 if _merge == 3

gen level_of_treat = 2
replace level_of_treat = 1 if adjacent == 1
replace level_of_treat = 0 if nonadjacent == 1
label var level_of_treat "2 for treated, 1 for adjacent, 0 for non-adjacent"

replace adj_lights = 0 if nonadjacent == 1
save "${data_folder_processed}/adjacent_nonadjacent_street_sample.dta", replace

	 