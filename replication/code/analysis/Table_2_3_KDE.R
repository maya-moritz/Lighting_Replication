# Table_2_3_KDE.r
#
#
# An R translation for Table_2_3_KDE.do.
#


##########
# Setup. #
##########
# ----

source( "master.R" )

# Set storage for outputs.
models <- list()
percchange_list <- list()
ci_list <- list()
table2 <-
  data.frame(
    dataset_1 = factor( levels = datasets_1 )
    ,dataset_2 = factor( levels = datasets_2 )
    ,term = character()
    ,Total = numeric()
    ,Gun = numeric()
    ,Violent = numeric()
    ,Property = numeric()
    ,Nuisance = numeric()
    ,Financial = numeric()
    )
colnames( table2 ) <- c( colnames( table2 )[1:3], labels )
# ----

###############
# Fit models. #
###############
# ----
# Loop through the datasets, which are specified with two-part names.
for ( j in c( "all", "day", "night" ) )
  {
    for ( i in c( "all", "inside", "outside" ) )
      {
        # Load data.
        df <-
          # readr::read_csv(
          haven::read_dta(
            file.path(
              data_folder_processed
              # ,paste0( j, i, ".csv")
              ,paste0( j, i, ".dta")
            )
          )
        
        # Calculate the arithmetic mean value of `lambda_cumr` using only values
        # > 0.
        mean_lights <-
          df %>%
          dplyr::filter( lambda_cumr > 0 ) %>%
          dplyr::summarise( mean_lights = mean( lambda_cumr, na.rm = TRUE ) ) %>%
          dplyr::pull( mean_lights )
        
        # Fit two-way fixed-effect regression model using OLS.
        for ( x in outcomes )
          {
            
            # Calculate the arithmetic mean value of variate using only values where
            # `lambda_cumr` > 0.
            ypost <- df %>%
              dplyr::filter( lambda_cumr > 0 ) %>%
              dplyr::summarise( mean_y = mean( .data[[x]], na.rm = TRUE ) ) %>%
              dplyr::pull( mean_y )
            
            # Fit the model.
            model <-
              fixest::feols(
                fml = as.formula(
                  paste0(x, " ~ lambda_cumr | spgrid_id + ym")
                )
                ,data = df
                # # Cluster the standard errors within areas.
                ,cluster = ~spgrid_id
              )
            # Extract outputs for the summary table.
            beta <- coef( model )[ "lambda_cumr" ]
            se   <- sqrt( vcov( model )[ "lambda_cumr", "lambda_cumr" ] )
            
            # Calculate the "Percentage change" variable.
            adjcoeff <- ( beta * mean_lights ) / ( abs( beta ) + ypost ) * 100
            adjCIlower <-
              ( ( beta - 1.96 * se ) * mean_lights ) /
              ( abs( beta - 1.96 * se ) + ypost ) * 100
            adjCIupper <-
              ( ( beta + 1.96 * se ) * mean_lights ) /
              ( abs( beta + 1.96 * se ) + ypost ) * 100
            
            # Store extra statistics as attributes in the model
            attr(model, "ypost") <- ypost
            attr(model, "lightchangemean") <- mean_lights
            attr(model, "adjcoeff") <- adjcoeff
            attr(model, "adjCIlower") <- adjCIlower
            attr(model, "adjCIupper") <- adjCIupper
            
            # Store outputs for this iteration.
            models[[ x ]] <- model
            percchange_list[[ x ]] <-
              matrix(
                adjcoeff,
                nrow = 1,
                dimnames = list(NULL, x)
              )
            ci_list[[ x ]] <- 
              matrix(
                c( adjCIlower, adjCIupper ),
                nrow = 2,
                dimnames = list( c(" ll95", "ul95" ), x )
              )
          }
        
        # Create output table for this model.
        table2_temp <-
          data.frame(
            dataset_1 = j
            ,dataset_2 = i
            ,term = c(
              "Coeff"
              ,"SE"
              ,"Ave. Post."
              ,"N"
              ,"Lower 5%"
              ,"% Change"
              ,"Upper 95%"
            )
        )
        # Append attributes to the model object. 
        for ( k in names( models ) )
          {
            m <- models[[ k ]]
              
            table2_temp[[ k ]] <-
              c(
                round( m$coefficients[[1]], 4 )
                ,round( m$se[[1]], 5 )
                ,attr( m, "ypost" )
                ,m$nobs
                ,round( attr( m, "adjCIlower" ), 3 )[[1]]
                ,round( attr( m, "adjcoeff" ), 3 )[[1]]
                ,round( attr( m, "adjCIupper" ), 3 )[[1]]
              )
          }
        
        # Set column headers.
        colnames( table2_temp ) <- c( "dataset_1", "dataset_2", "term", labels )
        
        # Store table.
        table2 <-
          dplyr::bind_rows( table2, table2_temp )
    }
}
rm( table2_temp )
# ----

################
# Save models. #
################
# ----

# Prepare tables
table2 <-
  table2 %>%
  dplyr::mutate(
    dataset_1 = datasets_1[ dataset_1 ]
    ,dataset_2 = datasets_2[ dataset_2 ]
    ) 
table3 <-
  dplyr::bind_rows(
    dplyr::filter( table2, dataset_1 == "Day", dataset_2 == "All areas" )
    ,dplyr::filter( table2, dataset_1 == "Day", dataset_2 == "Outdoor" )
    ,dplyr::filter( table2, dataset_1 == "Night", dataset_2 == "All areas" )
    ,dplyr::filter( table2, dataset_1 == "Night", dataset_2 == "Outdoor" )
  ) %>%
  dplyr::mutate(
    dataset_2 = dplyr::if_else( dataset_2 == "All areas", "Total", dataset_2 )
    ) %>%
  tidyr::unite( col = "dataset", sep = ": ", dataset_1, dataset_2 )

# Save table as CSV.
table2 %>%
  dplyr::filter( dataset_1 == "All times" ) %>%
  write.csv( file.path( output_tables_folder, "Table_2_effects.csv" ) )
write.csv( table3, file.path( output_tables_folder, "Table_3_effects.csv" ) )

# Format as gt table.
gt_table2 <-
  table2 %>%
  dplyr::filter( dataset_1 == "All times" ) %>%
  dplyr::select( -dataset_1 ) %>%
  gt::gt( groupname_col = "dataset_2" ) %>%
  gt::cols_align(
    align = "left"
    ,columns = term
  ) %>%
  gt::tab_header(
    title = "Table 2. Effects of changes in lights on crime."
  ) %>%
  gt::tab_source_note(
    source_note = "Hexagon and year-month fixed effects."
  )
my_rows <- c( 0, 7, 14, 21 )
gt_table3 <-
  table3 %>%
  gt::gt( groupname_col = "dataset" ) %>%
  gt::cols_align(
    align = "left"
    ,columns = term
  ) %>%
  gt::fmt( fns = function(x) { round( x, 7 ) } ,columns = where( is.numeric ) ,rows = 1+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 7 ) } ,columns = where( is.numeric ) ,rows = 2+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 2 ) } ,columns = where( is.numeric ) ,rows = 3+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 0 ) } ,columns = where( is.numeric ) ,rows = 4+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 3 ) } ,columns = where( is.numeric ) ,rows = 5+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 3 ) } ,columns = where( is.numeric ) ,rows = 6+my_rows ) %>%
  gt::fmt( fns = function(x) { round( x, 3 ) } ,columns = where( is.numeric ) ,rows = 7+my_rows ) %>%
  
  gt::tab_header(
    title = "Table 3: Effects of changes in lights on daytime versus nighttime crime."
    ) %>%
  gt::tab_source_note(
    source_note = "Hexagon and year-month fixed effects."
    )
rm(my_rows)
# Save table as HTML.
gt::gtsave( gt_table3, file.path( output_tables_folder ,"/Table_3_effects.html" ) )
# ----