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
