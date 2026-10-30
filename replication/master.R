# master.R
#

###################
# Load libraries. #
###################
# ----
if( !"pacman" %in% installed.packages() ){ install.packages( "pacman" ) }
pacman::p_load(
  DIDmultiplegtDYN
  ,fixest
  ,gt
  ,haven
  ,polars
  ,tidyverse
)
# ----

###########
# Set up. #
###########
# Uncomment and set own path of working directory. This should be the parent
# folder that contains the `code`, `data`, and `output` folders.
#setwd( )
  
# Set up file structure.
v_folder <-
  c(
    'data/temp/streets'
    ,'data/processed/2ypre'
    ,'data/processed/buffer'
    ,'output/figures'
    ,'output/tables'
    ,'data/raw/mapping'
    ,'data/raw/crime'
    ,'data/raw/kde'
    ,'data/raw/2yrpre'
    ,'code/analysis'
    ,'code/data_processing/2yrpre'
    ,'code/appendix'
    )
for( i_folder in v_folder )
  {
    dir.create( file.path( getwd(), i_folder ), recursive = FALSE) %>%
      suppressWarnings()
}

# Set output directory.
output_tables_folder <- "output/tables"

# Set a directory to pull data from.
data_folder_processed <- "data/processed"

# Set vector of the names of the outcome variables of interest.
# # NOTE: The last outcome is called placebo but is reported as "financial". This
# #       is because the authors did not expect lighting to affect financial crimes.
# #       Placebo is not the correct term. "Control" is more appropriate.
outcomes <-
  c(
    "lambda_totalr", "lambda_gunr", "lambda_violentr"
    ,"lambda_propertyr", "lambda_nuisancer", "lambda_placebor"
  )
countoutcomes <-
  c( "total", "gun", "violent", "property", "nuisance", "placebo" )
labels <-
  c(
    lambda_totalr    = "Total Crimes",
    lambda_gunr      = "Gun Crimes",
    lambda_violentr  = "Violent Crimes",
    lambda_propertyr = "Property Crimes",
    lambda_nuisancer = "Nuisance Crimes",
    lambda_placebor  = "Financial Crimes"
  )

# Set names of datasets
datasets_1 <- c( "all" = "All times", "day" = "Day", "night" = "Night" )
datasets_2 <- c( "all" = "All areas", "inside" = "Indoor", "outside" = "Outdoor" )
#----

###########################################################################
#     PART 3:  Run files                                                  #
###########################################################################
#    PRIVACY NOTE
#	 Due to restricted data access, the following files have been removed.
#	1. outsode_crime.dta: a file with Philadelphia Police Department-specific 
#	2. PSIP Fixture Export May 6 2024.xlsx: Energy authority raw installation data
#	3. files in temp for both main analysis and 2yrpre labelled all_crimes.dta or crimes.dta ## Why not just exclude the sensitive data items?
#	   as these files contain information from outside_crime.dta


# PART 3.1:	Creates mapping files and daylight classifications.
# ----
# REQUIRES:
#   3.1.1: no files 
#   3.1.2: 7 files stored in data_folder_raw_mapping:
#             City_Limits.shp/dbf
#             City_Limits_coord.dta
#             Phila_Region_wgs84.shp/dbf
#             Region_coord.dta
#             Region.dta
# CREATES:
#   3.1.1: ${data_folder_raw}/suntimes.dta
#   3.1.2: ${data_folder_raw_mapping}/PHL-GridCells.dta
#          ${data_folder_raw}/Region_mercator.dta
#          ${data_folder_raw}/PHL-GridPoints.dta"
# 				 ${data_folder_raw_mapping}/City_Limits_mercator.dta
# TIME:
#   ~9 minutes without scraping
#
# Change the FALSE to FALSE to run. Files set at FALSE because resulting files are already
# provided.
# 3.1.1: creates sunlight and civil twilight times for data processing
# Note: website is now blocking scrapes so resulting data is provided.
if ( FALSE ) source( "${data_cleaning_folder}/processing_0_time_classification_scrape.R" ) # R VERSION NOT YET CREATED.
#3.1.2: creates maps for use in data processing
if ( FALSE ) source( "${data_cleaning_folder}/processing_1_map_creation.R" )                # R VERSION NOT YET CREATED.
# ----

# PART 3.2: Creates ready-to-analyze processed data files from raw data files.
# ----
# REQUIRES:
#   7 files stored in data_folder_raw:
#     Crime files: incidents_part1_part2.csv, outside_crime.dta, shootings.csv
#     Map files: PHL-GridCells.dta, PHL-GridPoints.dta, Region_mercator.dta
#     Lighting file: PSIP Fixture Export May 6 2024.xlsx
#     Daytime file: suntimes.dta
# 
# CREATES:
#   ${data_folder_processed}/`i'`j'.dta. i and j represent time (all, day, night)
#   and location (all, outside, inside)
#
# TIME:
#   ~70 minutes

# Change the 1 to 0 to not run
# 3.2.1: creates all crimes file ${data_folder_temp}/allcrimes.dta,
if ( FALSE ) source("${data_cleaning_folder}/processing_2_crime_data_creation.R" )# R VERSION NOT YET CREATED.
# 3.2.2: create crime KDE data and stack for civil twilight and buffer
if ( FALSE ) source("${data_cleaning_folder}/processing_3_KDE_data_creation.R" )# R VERSION NOT YET CREATED.
# 3.2.3: create light KDE data and stack
if ( FALSE ) source("${data_cleaning_folder}/processing_4_create_lights_data.R" )# R VERSION NOT YET CREATED.
# 3.2.4: integrate light and crime data for kde, also add hexagons
if ( FALSE ) source("${data_cleaning_folder}/processing_5_integration_hexagons.R" )# R VERSION NOT YET CREATED.
# 3.2.5: R creation of street-level variables available in the following file:
if ( FALSE ) source( "processing_6_street_level.R" )# R VERSION NOT YET CREATED.
# 3.2.6: Turns R code into usable Stata data. NO LONGER NEEDED.
if ( FALSE ) source("${data_cleaning_folder}/processing_7_street_analysis.R" )# R VERSION NOT YET CREATED.
# 3.2.7: The following files rerun the same data build, but with a 2-year period
# for Appendix Table 5.
if ( FALSE ) source( "${data_cleaning_folder_2yrpre}/processing_01_sunset_time_2yrpre.R" )# R VERSION NOT YET CREATED.
if ( FALSE ) source( "${data_cleaning_folder_2yrpre}/processing_02_crime_data_creation_2yrpre.R" )# R VERSION NOT YET CREATED.
if ( FALSE ) source( "${data_cleaning_folder_2yrpre}/processing_03_KDE_2yrpre.R" )# R VERSION NOT YET CREATED.
if ( FALSE ) source( "${data_cleaning_folder_2yrpre}/processing_04_integration_2yrpre.R" )# R VERSION NOT YET CREATED.
# ----

# PART 3.3: Runs main analyses (Paper tables 1-7).
# ----
# REQUIRES:
#   ${data_folder_processed} as created from 3.2
#
# CREATES:
#   ${output_tables_folder}
#   ${output_figures_folder}
#
# TIME:
#   ~40 mins

# Change the FALSE to FALSE to not run.
# 3.3.1: creates summary statistics
if ( FALSE ) source( "${analysis_folder}/Table_1_summary_stats.R" )
# 3.3.2: creates Tables 2 and 3 (KDE analysis)
if ( FALSE ) source( "${analysis_folder}/Table_2_3_KDE.R" )
# 3.3.3: creates table 4 (street analysis)
if ( FALSE ) source( "${analysis_folder}/Table_4_street_analysis.R" )
# 3.3.4: Table 5 (Chaisemartin estimates)
if ( FALSE ) source( "${analysis_folder}/Table_5_chaisemartin.R" )
# 3.3.5: Table 6 (3-month lagged effects)
if ( FALSE ) source( "${analysis_folder}/Table_6_lags.R" )# R VERSION NOT YET CREATED.
# 3.3.6: Table 7 (2-hour buffers)
if ( FALSE ) source( "${analysis_folder}/Table_7_buffer.R" )# R VERSION NOT YET CREATED.
# ----

# PART 3.4: Runs appendix tables.
# ----
# REQUIRES: 
#   ${data_folder_processed} as created from 3.2
# CREATES:
#   counts and buffer folders in ${output_tables_folder} and ${output_figures_folder}
# TIME:
#   ~25 mins

# Change the FALSE to FALSE to not run.
# 3.4.1: Appendix Table 1 (hexagon counts)
if ( FALSE ) source("${appendix_folder}/Appendix_Table_1_counts.R" )# R VERSION NOT YET CREATED.
# 3.4.2: Appendix Table 2 (street-level per light added)
if ( FALSE ) source("${appendix_folder}/Appendix_Table_2_per_light.R" )# R VERSION NOT YET CREATED.
# 3.4.3: Appendix Table 3 (region-time fixed effects)
if ( FALSE ) source("${appendix_folder}/Appendix_Table_3_region.R" )# R VERSION NOT YET CREATED.
# 3.4.4: Appendix Table 4 (hexagon linear time trends)
if ( FALSE ) source("${appendix_folder}/Appendix_Table_4_hex_trends.R" )# R VERSION NOT YET CREATED.
# 3.4.5: Appendix Table 5 (2 year pre-period)
if ( FALSE ) source("${appendix_folder}/Appendix_Table_5_2yrpre.R" )# R VERSION NOT YET CREATED.
# ----

# PART 3.5: Creates figures.
# ----
# REQUIRES:
#   ${data_folder_processed} as created from 3.2
# CREATES:
#   counts and buffer folders in ${output_tables_folder} and ${output_figures_folder}
# TIME:
#   ~5 mins

# Change the FALSE to FALSE to not run.
# 3.4.1: Figure 2 (lights density map)
if ( FALSE ) source( "${analysis_folder}/Figure_2_monthly_density.R" )# R VERSION NOT YET CREATED.
# 3.4.2: Figure 3 (treated and adjacent streets)
if ( FALSE ) source( "${analysis_folder}/Figure_3_adjacent_streets.R" )# R VERSION NOT YET CREATED.
# ----




