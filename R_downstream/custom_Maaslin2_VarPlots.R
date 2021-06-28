# Define a function to generate a .pdf file with plotted raw data for significant values
custom_Maaslin2_VarPlots <- function(input_data, input_metadata, custom_Maaslin2, output,
                                     x_factor, x_label){
  # Function to rotate a data.frame and maintain names
  rotate_df <- function(data){
    names_row <- rownames(data)
    names_col <- colnames(data)
    
    data_rotated <- data.frame(t(data))
    rownames(data_rotated) <- names_col
    colnames(data_rotated) <- names_row
    
    data_rotated
  }
  
  # Create a data.frame with only the significant findings from MaAsLin2
  indiv_data <- input_data[rownames(input_data) %in% custom_Maaslin2[[1]]$kegg_name, ]
  indiv_data <- rotate_df(indiv_data)
  
  # Create a vector containing the names of the significant findings
  sig_vars <- colnames(indiv_data)
  
  # Assert that the sample IDs (rownames) match between this new data.frame and the input_metadata
  names_match <- identical(rownames(indiv_data), rownames(input_metadata))
  
  # Join the metadata to the indiv_data
  if(names_match){
    indiv_data <- cbind(indiv_data, input_metadata)
  } else {
    ('Error matching significant variable data.frame to input metadata.')
    break
  }
  
  # Multi-page plotting
  x_factor <- x_factor
  x_label <- x_label
  plot_list <- list()
  
  for (i in sig_vars) {
    var <- i
    var_string <- paste0('`', var, '`')
    fit_res_plot <- ggplot(indiv_data, aes_string(x = x_factor, y = var_string)) +
      geom_boxplot(aes_string(fill = x_factor)) +
      geom_point() +
      scale_fill_jama(name = x_label, alpha = 0.5) +
      labs(title = var,
           x = x_label,
           y = 'Normalised Abundance')
    plot_list[[i]] <- fit_res_plot
  }
  
  multi.page <- ggarrange(plotlist = plot_list, nrow = 2, ncol = 1)
  
  ggexport(multi.page, filename = output)
  
  multi.page
}
