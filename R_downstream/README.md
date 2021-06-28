# Downstream analysis in R

### PCoA

Here we can use the functions provided in the `custom_PCoA.R` file to generate PCoA data and plot the resulting information.

Using the functions are simple, as shown in the example below. By default, the `scale` argument in the `custom_PCoA` function is set to `FALSE`, but this should typically be set to `TRUE`.

```r
# Run PCoA
PCoA_data_genes_KO_unstrat <- custom_PCoA(bact_genefamilies_KO_unstrat, metadata_stool_shotgun, scale = TRUE)

# Plot PCoA
(PCoA_genes_KO_unstrat_plot <- custom_PCoA_plot(PCA_data_genes_KO_unstrat,
                                                group = 'Patient',
                                                fill = 'timeframe',
                                                fill_name = 'Time Frame',
                                                title = 'PCoA - Stool Gene Family Abundances')
)
```

The first part of the code above will process the gene families data (`bact_genefamilies_KO_unstrat`; processed via `HUMAnN` and `MetaPhlAn`) and associated metadata (`metadata_stool_shotgun`), and output an object of type `list`, containing firstly the PCoA data.frame and secondly a vector with the explained variance.

These individual elements can be accessed using standard list notation: `object[[1]]` for example.

The second part of the code will return a `ggplot` graph object. 

- The `group` element will tell `ggplot2` which samples should have lines drawn between them.
- The `fill` element will inform which samples should be considered when drawing the ellipses, and also what colours the points should be.
- The `fill_name` element replaces the standard name for the legend.
- The `title` element will become the title.

The output plot for the code above looks like this:

<img src="https://github.com/mmac0026/microbiome-shotgun-biobakery/blob/main/R_downstream/assets/genefam_PCoA_timeframe.png" width="595" height="525">
