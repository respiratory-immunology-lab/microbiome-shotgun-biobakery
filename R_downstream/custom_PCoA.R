# Define a function to prepare PCA data from a given data.frame
# where samples are columns and variables are rows
custom_PCoA <- function(df, metadata, center = TRUE, scale = FALSE) {
  data <- t(df)
  PCoA <- prcomp(data, center = center, scale. = scale)
  var_exp <- c(summary(PCoA)$importance[2,1]*100, summary(PCoA)$importance[2,2]*100)
  PCoA_data <- cbind(data.frame(Samples = rownames(PCoA$x),
                                PC1 = PCoA$x[,1],
                                PC2 = PCoA$x[,2]),
                     metadata)
  list(PCoA_data, var_exp)
}

# Define a function to plot the custom PCoA
custom_PCoA_plot <- function(custom_PCoA, group, fill = NULL, fill_name = 'Fill', shape = 21,
                             color = NULL, title = NULL) {
  plot_data <- custom_PCoA[[1]]
  plot_varexp <- custom_PCoA[[2]]
  group_var <- plot_data[, group]
  fill_var <- plot_data[, fill]
  
  PCoA_plot <- ggplot(plot_data, aes(x = PC1, y = PC2)) +
    labs(title = title,
         x = paste0('PC1 ', round(plot_varexp[1], 2), '%'),
         y = paste0('PC2 ', round(plot_varexp[2], 2), '%')) +
    stat_ellipse(aes(fill = fill_var), geom = 'polygon', type = 't', level = 0.9, alpha = 0.2) +
    geom_path(aes(group = group_var), col = 'grey70') +
    geom_point(aes(fill = fill_var, color = color), shape = shape, size = 2) +
    scale_fill_jama(name = fill_name) +
    scale_shape_identity()
  
  PCoA_plot
}
