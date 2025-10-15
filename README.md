# Alien invertebrates of Romania [alieninvro]

<!-- badges: start -->
<!-- badges: end -->

An interactive Shiny dashboard for exploring alien invertebrate species data included in the paper "From soil to stream and sea: species richness and distribution of alien invertebrates in Romania" by Cristina Preda et al. (submitted to Neobiota).



## Features

- **Interactive Map**: Alien species distribution across Romania, color-coded by realm
- **Advanced Filtering**: Filter by realm, species, family, EU status, county, and year
- **Statistical Visualizations**: Top species, counties, families, and temporal trends
- **Pathway Analysis**: Chord diagrams showing introduction pathways and origins
- **Data Source Analysis**: Venn diagrams comparing citizen science, published literature, and author observations
- **Data Export**: Download filtered species lists and full datasets

## Installation

You can install the development version of alieninvro from GitHub:
```r
# Install devtools if you haven't already
install.packages("devtools")

# Install alieninvro
devtools::install_github("rlaurentiu/alieninvro")
```

## Usage

After installation, launch the app with:
```r
library(alieninvro)
run_alieninvro_app()
```

## Data

The package includes three datasets:
- `species_data`: Main occurrence records
- `species_chord`: Pathway and origin data
- `species_list`: Data source classifications

## Citation

If you use this dashboard or data, please cite:

Preda et al. (submitted). From soil to stream and sea: species richness and distribution of alien invertebrates in Romania. *Neobiota*.

### Development Tools

Dashboard development: Claude AI (Anthropic). Claude Opus 4.1 and Claude Sonnet 4.5. https://claude.ai

## License

MIT License

## Contact

For questions or issues, please open an issue on [GitHub](https://github.com/rlaurentiu/alieninvro/issues).
