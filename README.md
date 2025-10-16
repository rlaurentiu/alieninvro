# Alien invertebrates of Romania [alieninvro]

<!-- badges: start -->
[![R-CMD-check](https://github.com/rlaurentiu/alieninvro/workflows/R-CMD-check/badge.svg)](https://github.com/rlaurentiu/alieninvro/actions)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/rlaurentiu/alieninvro)](https://github.com/rlaurentiu/alieninvro/releases)
[![GitHub issues](https://img.shields.io/github/issues/rlaurentiu/alieninvro)](https://github.com/rlaurentiu/alieninvro/issues)
[![GitHub stars](https://img.shields.io/github/stars/rlaurentiu/alieninvro)](https://github.com/rlaurentiu/alieninvro/stargazers)
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

### Prerequisites
- **R**: Version 4.0.0 or higher is required
  - Download from: https://cran.r-project.org/
  - Check your version: `R.version.string`
  
- **RStudio** (optional but recommended): 
  - Download from: https://posit.co/downloads/

### Install Package
```r
# 1. Install devtools (if not already installed)
install.packages("devtools")

# 2. Install alieninvro from GitHub
devtools::install_github("rlaurentiu/alieninvro")

# 3. Load the package
library(alieninvro)

# 4. Launch the dashboard
run_alieninvro_app()
```

### Installing a Specific Version
```r
# Install version 1.0.0
devtools::install_github("rlaurentiu/alieninvro@v1.0.0")

# Install the latest development version
devtools::install_github("rlaurentiu/alieninvro@main")
```

### Troubleshooting

If you encounter installation issues:
```r
# Update all dependencies
update.packages(ask = FALSE)

# Install with dependencies
devtools::install_github("rlaurentiu/alieninvro", dependencies = TRUE)

# Install with build vignettes (if available)
devtools::install_github("rlaurentiu/alieninvro", build_vignettes = TRUE)
```

## Citation

If you use this dashboard or data, please cite:

Preda et al. (submitted). From soil to stream and sea: species richness and distribution of alien invertebrates in Romania. *Neobiota*.

## Acknowledgments

This package was developed with assistance from Claude AI (Anthropic) for:
- R/Shiny application code development
- Package structure and organization  
- Data visualization and interactive features
- User interface design

Human contributions: Data curation, scientific analysis, conceptualization, and validation.

## License

MIT License

## Contact

For questions or issues, please open an issue on [GitHub](https://github.com/rlaurentiu/alieninvro/issues).
