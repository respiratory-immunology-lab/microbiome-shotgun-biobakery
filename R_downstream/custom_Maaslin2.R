# Define a function to handle calls to MaAsLin2 and produce a graph
custom_Maaslin2 <- function(input_data, input_metadata, fixed_effects = '', random_effects = '',
                            min_abundance = 0, min_prevalence = 0.2, output = 'maaslin2',
                            normalization = 'NONE', transform = 'NONE', qval_cutoff = 0.05,
                            handle_humann_KO = FALSE){
  # Fit data using the MaAsLin2 function
  fit_data <- Maaslin2(input_data = input_data,
                       input_metadata = input_metadata,
                       min_abundance = 0,
                       min_prevalence = 0.2,
                       fixed_effects = fixed_effects,
                       random_effects = random_effects,
                       output = here::here('output', 'maaslin2', 'genefamilies_KO_unstrat'),
                       normalization = 'NONE',
                       transform = 'NONE')
  
  # Filter output data
  fit_res <- fit_data$results %>%
    filter(qval < qval_cutoff) %>%
    arrange(qval)
  fit_res$feature <- factor(fit_res$feature, levels = rev(make.unique(fit_res$feature)))
  
  if(handle_humann_KO) {
    # Separate out the KEGG id from the fit_res table feature column
    fit_res$kegg_id <- gsub('(K\\d*).*', '\\1', fit_res$feature)
    
    # Get a table with the KEGG and EC IDs + names separated
    kegg_names_df <- data.frame('kegg_name' = rownames(input_data))
    kegg_names_df$kegg_id <- gsub('(K\\d*).*', '\\1', kegg_names_df$kegg_name)
    kegg_names_df$kegg_description <- ifelse(str_detect(kegg_names_df$kegg_name, '\\['),
                                             gsub('K\\d*: (.*) \\[.*', '\\1', kegg_names_df$kegg_name),
                                             gsub('K\\d*: (.*)', '\\1', kegg_names_df$kegg_name))
    kegg_names_df$ec_id <- ifelse(str_detect(kegg_names_df$kegg_name, '\\['),
                                  gsub('.*\\[EC\\:(.*)\\]', '\\1', kegg_names_df$kegg_name),
                                  NA)
    kegg_names_df$kegg_name <- NULL
    
    # Add the nicer descriptions to the fit_res table
    fit_res <- fit_res %>%
      left_join(kegg_names_df, by = c('kegg_id' = 'kegg_id')) %>%
      arrange(qval)
    fit_res$kegg_description <- factor(fit_res$kegg_description, 
                                       levels = rev(make.unique(fit_res$kegg_description)))
  }
  
  # Plot the graph
  if(handle_humann_KO){
    # Plot MaAsLin2 fit results
    maaslin_plot <- ggplot(fit_res, aes(x = -log10(qval), y = kegg_description)) +
      geom_col(aes(fill = value)) +
      scale_fill_jama(name = 'Group') +
      labs(title = 'MaAsLin2 Results',
           y = 'KEGG Description')
  } else {
    # Plot MaAsLin2 fit results
    maaslin_plot <- ggplot(fit_res, aes(x = -log10(qval), y = feature)) +
      geom_col(aes(fill = value)) +
      scale_fill_jama(name = 'Group') +
      labs(title = 'MaAsLin2 Results',
           y = 'KEGG Description')
  }
  
  output_list <- list(fit_res, maaslin_plot)
  
  output_list
}
