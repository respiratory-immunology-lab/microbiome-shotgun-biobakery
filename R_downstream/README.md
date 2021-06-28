# Downstream analysis in R

## PCoA

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


## Differential abundance testing with MaAsLin2

The `MaAsLin2` package for R is an extremely useful package for differential abundance testing. 

Here we can use the custom function call in the `custom_Maaslin2.R` file to quickly process the data and produce a graph of the significant features. The fit results and the graph are stored in a list object, and can be accessed accordingly.

The input requires two data.frames:

- `input_data`: this should be a data.frame where columns are samples and rows are variables.
- `input_metadata`: this should be a data.frame where columns are variables and rows are samples.

Importantly, the column names of `input_data` must match the rownames of `input_metadata` (a requirement for `MaAsLin2`.

#### Formatting names

If you are working with Gene Family data output from `HUMAnN` with KEGG Orthology names, there is an option in the custom function to process the standard 'Gene Family' names provided by `HUMAnN` into something that will look better when graphed (shorter, and without the KO and EC identifiers). These names will look something like: K00001: alcohol dehydrogenase [EC:1.1.1.1] or K00241: succinate dehydrogenase / fumarate reductase, cytochrome b subunit (the latter lacks the EC identifier). The `handle_humann_KO` argument handles both of these cases, and creates new columns in the fit results data.frame for `kegg_id`, `kegg_description`, and `ec_id` (where available).

In the example genes above, the `kegg_description` values would be "alcohol dehydrogenase" and "succinate dehydrogenase / fumarate reductase, cytochrome b subunit" respectively.

There will be a similar option coming that will allow processing of the standard HUMAnN pathway abundance/coverage names and gene names of UniRef90 origin (yet to be added).

### Running the function and looking at the output

Running the function is very similar to running `maaslin2()`, however some of the additional arguments are set by default, including the `min_abundance`, `min_prevalence`, `normalization` and `transform` arguments. These can however all be modified as needed within the call to the `custom_Maaslin2()` function.

By default, the output folder is simply `'maaslin2'`, but again this can be customised so that the MaAsLin2 output files are directed elsewhere.

Here is an example of running the code:

```r
genefamilies_KO_maaslin <- custom_Maaslin2(input_data = bact_genefamilies_KO_unstrat,
                                           input_metadata = input_metadata,
                                           fixed_effects = c('timeframe'),
                                           random_effects = c('Patient'),
                                           output = here::here('output', 'maaslin2', 'genefamilies_KO_unstrat'),
                                           handle_humann_KO = TRUE)
```
You can then view the fit results (for the example) using `genefamilies_KO_maaslin[[1]]` and the plot using `genefamilies_KO_maaslin[[2]]`.

The plot for the above example looks like this:

<img src="https://github.com/mmac0026/microbiome-shotgun-biobakery/blob/main/R_downstream/assets/genefamilies_KO_unstrat_maaslin_plot.png" width="700" height="420">
