/*******************************************************************************
*	Project: Philadelphia Lighting
*	File: processing_02_crime_data_creation_2yrpre
*	Script purpose: Create 2-year pre-period for crime and shooting
*	Author: Maya Moritz, amended script from John MacDonald

*	Organization
*	1. Crime data
*	2. Shootings data
*	3. Merge
*	4. Daylight

*******************************************************************************/
cd ${data_folder_raw}
********************************************************************************
********************************1. Crime data***********************************
********************************************************************************
clear

*import crime data
* Start with the first file
import delimited "2yrpre/crimes_2020.csv", clear

* Save it to a temporary file to build on
tempfile combined
save `combined'

* Loop through the remaining years and append each one
forvalues y = 2021/2024 {
    import delimited "2yrpre/crimes_`y'.csv", clear
    append using `combined'
    save `combined', replace
}

*create dummy variables for each crime type
tab text_general_code, gen(crimes)

*Drop crimes with missing locations or those out of bounds
drop if lng==.
drop if point_x==0
drop if point_x<-75.28031

*reformat and rename date and location variables
rename location_block location
gen eventdate=date(dispatch_date, "YMD")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
gen ym=ym(year, month)
format ym %tm  

*change format of crime times
gen double crime_time = clock(dispatch_time, "hms")
format crime_time %tc

*generate usable geometry from current point data 
geo2xy point_y point_x, gen (_Y _X) project(mercator)


drop if ym<720 | ym > 772

/*skipping multiple dc key section bc decided that for the few crimes that have it (258 here), 
probably means multiple victims so no issue to keep them
also skipping inside/outside bc don't have it for earlier crimes
if want to restore it look at main processing folder in replication */
save "${data_folder_temp}/2yrpre/crimes.dta", replace


********************************************************************************
***************************2. shootings data ***********************************
********************************************************************************
*first want to extract dc_key to use to weed out multiples in shootings
*Get unique dc_keys for crimes
keep dc_key
duplicates report dc_key
duplicates drop
save "${data_folder_temp}/2yrpre/dckeys.dta", replace


*read in shooting data, these go back to 2015 so no need to add more data
import delimited "${data_folder_raw}/crime/shootings.csv", clear 
*merge shooting data to crime dc keys
merge m:1 dc_key using "${data_folder_temp}/2yrpre/dckeys.dta"
*7,297 shootings not in the dc keys for crime, 8,507 matched so are in crime and shootings data
*just keep the shootings that don't match to crime dc_keys
keep if _merge == 1
drop _merge

*create date variables
drop year
gen eventdate=date(date_, "YMD####")
format eventdate %td
gen year=year(eventdate)
gen month=month(eventdate)
tab year
gen ym=ym(year, month)
format ym %tm  

*change format of crime times
gen double crime_time = clock(time, "hms")
format crime_time %tc

*only keep full months
drop if ym<720 | ym > 772

*create geometry
geo2xy point_y point_x, gen (_Y _X) project(mercator)

*generate category
gen shooting=1
save "${data_folder_temp}/2yrpre/shootings.dta", replace


********************************************************************************
*********************************3. Merge***************************************
********************************************************************************
*now append crime data
append using "${data_folder_temp}/2yrpre/crimes.dta"

*all offenses
recode shooting (.=0)
gen total = 1
recode crimes1-crimes32 (.=0)

********************************************************************************
******************************3. Crime Categories*******************************
********************************************************************************

*Crime Categories
*1. TOTAL CRIME- created before as total, only representing crimes not shootings
*2. GUN CRIMES- shooting, gun robbery, gun assault, weapons violation NOT MURDER
gen gun = shooting + crimes26 + crimes1 + crimes32

*3. VIOLENT STREET CRIMES: RAPES, ASSAULT (AGG + SIMPLE + OTHER), MURDER (JUST CRIMINAL), ROBBERY (FIREARM + NO FIREARM), SHOOTINGS THAT ARE NOT MURDERS (DC KEY REMOVAL PROCESS)
gen violent = crimes24 + crimes1 + crimes2 + crimes20 + crimes13 + crimes26 + crimes27 + shooting

*4. STREET PROPERTY CRIME: BURGLARY (BOTH), THEFT (MOTOR VEHICLE + THEFT FROM VEHICLE + THEFTS), VANDALISM/CRIMINAL MISCHIEF
gen property = crimes5 + crimes6 + crimes17 + crimes28 + crimes29 + crimes31

*5. NUISANCE CRIMES: DISORDERLY CONDUCT, PUBLIC DRUNKENNESS, LIQUOR LAW VIOLATIONS, NARCOTICES/DRUG LAW VIOLATIONS
gen nuisance = crimes8 + crimes23 + crimes16 + crimes18

*6. PLACEBO: FRAUD, FORGERY, EMBEZZLEMENT
gen placebo = crimes9 + crimes10 + crimes11

********************************************************************************
*********************************4. Daylight************************************
********************************************************************************

*merge to sunlight times generated in processing_0_time_classification.do
*many crimes can occur on the same date so m:1
merge m:1 eventdate using "${data_folder_raw}/2yrpre/suntimes.dta"

drop ctb_time
*change format of suntimes to match crime times
gen double ctb_time = clock(ctb, "hm")
format ctb_time %tc

gen double cte_time = clock(cte, "hm")
format cte_time %tc

*create a variable to check, deleting the original hour variable as it is not always correct
drop hour
gen double hour = hhC(crime_time)

*classify daylight times according to civil twilight
*note: 11 shootings are missing a time so need to account for those
gen daylight = 0 if crime_time != .
replace daylight = 1 if crime_time > ctb_time & crime_time < cte_time

*checks
tab hour if daylight == 1
tab hour if daylight == 0

*create 2 hour buffer for crimes that likely occured during the day but were classified as night
gen double cte_time_plus2 = cte_time + 7200000
format cte_time_plus2 %tc

gen daylightbuffer = 0 if crime_time != .
replace daylightbuffer = 1 if crime_time > ctb_time & crime_time < cte_time_plus2

*checks
tab hour if daylightbuffer == 1
tab hour if daylightbuffer == 0

*save final crime file
save "${data_folder_temp}/2yrpre/allcrimes.dta", replace