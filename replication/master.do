********************************************************************************
*                           MASTER DO-FILE                            		   *
********************************************************************************
*                                                                              *
*   PURPOSE:     Reproduce all results in final paper			               *
*                                                                              *
*   OUTLINE:     PART 1:  Set standard settings and install packages           *
*                PART 2:  Prepare folder paths and define programs             *
*                PART 3:  Run do-files                                         *
*                                                 qw                             *
********************************************************************************
*    PART 1:  Install packages and harmonize settings			   			   *
********************************************************************************

    local user_commands carryforward tabout shp2dta spmap spgrid geo2xy spkde geoinpoly gtools ftools matsort avar xtevent did_multiplegt_dyn reghdfe coefplot estout ietoolkit unique 
    foreach command of local user_commands {
        cap which `command'
        if _rc == 111 ssc install `command'
    }

	*Harmonize settings across users as much as possible
    ieboilstart, versionnumber(18.0)
    `r(version)'

/*******************************************************************************
    PART 2:  Prepare folder paths and define programs
*******************************************************************************/
 	/*Uncomment and set own path here:
	 if "`c(username)'" == "your username" {
        global main_folder "/Users/yourpath/Replication"
	}*/
	
	* Example Path for Maya 
    if "`c(username)'" == "mayar" {
        global main_folder "/Users/mayar/Downloads/Lighting_Replication"
	}
	/*Set up file structure
	*Replication package should include:
	*master.do (this file)
	*code folder with 2 folders, analysis (8 do files) and data_processing (6 do files)
	*data folder containing raw data
	*/
	
	*Add empty folders to fill over data build if buillding from scratch /*
	cap mkdir data/temp
	cap mkdir data/temp/streets
	cap mkdir data/processed
	cap mkdir output
	cap mkdir output/figures
	cap mkdir output/tables */
	
	
	* Set other file paths for globals
	global data_folder_raw				"${main_folder}/data/raw"
	global data_folder_raw_mapping		"${main_folder}/data/raw/mapping"
	global data_folder_processed		"${main_folder}/data/processed"
	global data_folder_temp				"${main_folder}/data/temp"
    global analysis_folder				"${main_folder}/code/analysis"
	global data_cleaning_folder			"${main_folder}/code/data_processing"
	global data_cleaning_folder_2yrpre	"${main_folder}/code/data_processing/2yrpre" 
    global output_tables_folder			"${main_folder}/output/tables"
	global output_figures_folder		"${main_folder}/output/figures"
    global appendix_folder				"${main_folder}/code/appendix"


	*globals for the analysis:
	global outcomes lambda_totalr lambda_gunr lambda_violentr lambda_propertyr lambda_nuisancer lambda_placebor
	global countoutcomes total gun violent property nuisance placebo
/*******************************************************************************
    PART 3: Run do-files
*******************************************************************************/


********************************************************************************
*    PRIVACY NOTE
*	 Due to restricted data access, the following files have been removed.
*	1. outsode_crime.dta: a file with Philadelphia Police Department-specific 
*	2. PSIP Fixture Export May 6 2024.xlsx: Energy authority raw installation data
*	3. files in temp for both main analysis and 2yrpre labelled all_crimes.dta or crimes.dta
*		as these files contain information from outside_crime.dta

********************************************************************************
/* These files will therefore not run due to the privacy restrictions listed above
* but are included for clarity:
/*------------------------------------------------------------------------------
    PART 3.1:	Creates mapping files and daylight classifications
    REQUIRES:	3.1.1: no files 
				3.1.2: 7 files stored in data_folder_raw_mapping:
				City_Limits.shp/dbf
				City_Limits_coord.dta
				Phila_Region_wgs84.shp/dbf
				Region_coord.dta
				Region.dta
    CREATES:    3.1.1: ${data_folder_raw}/suntimes.dta
				3.1.2: 
				${data_folder_raw_mapping}/PHL-GridCells.dta
				${data_folder_raw}/Region_mercator.dta
				${data_folder_raw}/PHL-GridPoints.dta"
				${data_folder_raw_mapping}/City_Limits_mercator.dta
	TIME: 		~9 minutes without scraping
----------------------------------------------------------------------------- */
    *Change the 0 to 1 to run. Files set at 0 because resulting files are already provided.
	*3.1.1: creates sunlight and civil twilight times for data processing
	*Note: website is now blocking scrapes so resulting data is provided
	if (0) do "${data_cleaning_folder}/processing_0_time_classification_scrape.do"
	*3.1.2: creates maps for use in data processing
    if (1) do "${data_cleaning_folder}/processing_1_map_creation.do"	
	
/*------------------------------------------------------------------------------
    PART 3.2:  	Creates ready-to-analyze processed data files from raw data files
    REQUIRES:   7 files stored in data_folder_raw:
		Crime files: incidents_part1_part2.csv, outside_crime.dta, shootings.csv
		Map files: PHL-GridCells.dta, PHL-GridPoints.dta, Region_mercator.dta
		Lighting file: PSIP Fixture Export May 6 2024.xlsx
		Daytime file: suntimes.dta
    CREATES:  	${data_folder_processed}/`i'`j'.dta
			i and j represent time (all, day, night) and location (all, outside, inside)
	TIME: 	~70 minutes
----------------------------------------------------------------------------- */
    *Change the 1 to 0 to not run
	*3.2.1: creates all crimes file ${data_folder_temp}/allcrimes.dta,
	if (1) do "${data_cleaning_folder}/processing_2_crime_data_creation.do"
	*3.2.2: create crime KDE data and stack for civil twilight and buffer
	if (1) do "${data_cleaning_folder}/processing_3_KDE_data_creation.do"
	*3.2.3: create light KDE data and stack
	if (1) do "${data_cleaning_folder}/processing_4_create_lights_data.do"
	*3.2.4: integrate light and crime data for kde, also add hexagons
	if (1) do "${data_cleaning_folder}/processing_5_integration_hexagons.do"
	*3.2.5: R creation of street-level variables available in the following file:
	*processing_6_street_level.R
	*3.2.6: Turns R code into usable Stata data
	if (1) do "${data_cleaning_folder}/processing_7_street_analysis.do"
	*3.2.7: The following files rerun the same data build, but with a 2-year 
	*		period for Appendix Table 5
	if (0) do "${data_cleaning_folder_2yrpre}/processing_01_sunset_time_2yrpre.do"
	if (1) do "${data_cleaning_folder_2yrpre}/processing_02_crime_data_creation_2yrpre.do"
	if (1) do "${data_cleaning_folder_2yrpre}/processing_03_KDE_2yrpre.do"
	if (1) do "${data_cleaning_folder_2yrpre}/processing_04_integration_2yrpre.do"
	
*/
/*------------------------------------------------------------------------------
    PART 3.3:  	Runs main analyses (Paper tables 1-7)
    REQUIRES:   ${data_folder_processed} as created from 3.2
    CREATES:    ${output_tables_folder} and ${output_figures_folder}
	TIME: 		~40 mins
----------------------------------------------------------------------------- */
    *Change the 1 to 0 to not run
	*3.3.1: creates summary statistics
	if (1) do "${analysis_folder}/Table_1_summary_stats.do"
	*3.3.2: creates Tables 2 and 3 (KDE analysis)
	if (1) do "${analysis_folder}/Table_2_3_KDE.do"
	*3.3.3: creates table 4 (street analysis)
	if (1) do "${analysis_folder}/Table_4_street_analysis.do"
	*3.3.4: Table 5 (Chaisemartin estimates)
	if (1) do "${analysis_folder}/Table_5_chaisemartin.do" 
	*3.3.5: Table 6 (3-month lagged effects)
	if (1) do "${analysis_folder}/Table_6_lags.do"
	*3.3.6: Table 7 (2-hour buffers)
	if (1) do "${analysis_folder}/Table_7_buffer.do"

/*------------------------------------------------------------------------------
    PART 3.4:  	Runs appendix tables
    REQUIRES:   ${data_folder_processed} as created from 3.2
    CREATES:    counts and buffer folders in ${output_tables_folder} and ${output_figures_folder}
	TIME: 		~25 mins
----------------------------------------------------------------------------- */
    *Change the 1 to 0 to not run
	*3.4.1: Appendix Table 1 (hexagon counts)
	if (1) do "${appendix_folder}/Appendix_Table_1_counts.do" 
	*3.4.2: Appendix Table 2 (street-level per light added)
	if (1) do "${appendix_folder}/Appendix_Table_2_per_light.do"
	*3.4.3: Appendix Table 3 (region-time fixed effects)
	if (1) do "${appendix_folder}/Appendix_Table_3_region.do"
	*3.4.4: Appendix Table 4 (hexagon linear time trends)
	if (1) do "${appendix_folder}/Appendix_Table_4_hex_trends.do"
	*3.4.5: Appendix Table 5 (2 year pre-period)
	if (1) do "${appendix_folder}/Appendix_Table_5_2yrpre.do"
	
/*------------------------------------------------------------------------------
    PART 3.5:  	Creates figures
    REQUIRES:   ${data_folder_processed} as created from 3.2
    CREATES:    counts and buffer folders in ${output_tables_folder} and ${output_figures_folder}
	TIME: 		~5 mins
----------------------------------------------------------------------------- */
    *Change the 1 to 0 to not run
	*3.4.1: Figure 2 (lights density map)
	if (1) do "${analysis_folder}/Figure_2_monthly_density.do"
	*3.4.2: Figure 3 (treated and adjacent streets)
	if (1) do "${analysis_folder}/Figure_3_adjacent_streets.do"

