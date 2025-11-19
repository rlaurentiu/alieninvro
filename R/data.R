Species occurrence data for alien invertebrates in Romania

#'

A dataset containing occurrence records of alien invertebrate species in Romania, including geographic coordinates, taxonomy, and metadata.

#'

@format A data frame with the following columns:

\describe{

  \item{ID}{Unique identifier for each record}

  \item{ScientificName}{Scientific name of the species}

  \item{Family}{Taxonomic family}

  \item{Order}{Taxonomic order}

  \item{realm}{Habitat realm (terrestrial, freshwater, or marine)}

  \item{decimalLatitude}{Latitude in decimal degrees}

  \item{decimalLongitude}{Longitude in decimal degrees}

  \item{CountyCode}{Romanian county code}

  \item{Locality}{Description of the location}

  \item{year}{Year of observation}

  \item{recordedBy}{Name of observer or data source}

  \item{basisOfRecord}{Type of record (e.g., citizen science, published literature)}

  \item{ias_eu}{EU invasive alien species status ("Yes" or "No")}

  \item{popup_text}{HTML formatted text for map popups}

}

@source Preda, C. et al. (submitted). From soil to stream and sea: species richness and distribution of alien invertebrates in Romania. Neobiota.

"species_data"


Pathway and origin data for alien invertebrate species

#'

A dataset containing information about introduction pathways and native origins of alien invertebrate species in Romania.

#'

@format A data frame with columns including:

\describe{

  \item{ScientificName}{Scientific name of the species}

  \item{realm}{Habitat realm (terrestrial, freshwater, or marine)}

  \item{pathway_1}{Primary introduction pathway}

  \item{native_in_1}{Primary native region or origin}

}

@source Preda, C. et al. (submitted). From soil to stream and sea: species richness and distribution of alien invertebrates in Romania. Neobiota.

"species_chord"


Species list with data source information

#'

A dataset indicating which data sources document each alien invertebrate pecies in Romania.

#'

@format A data frame with columns:

\describe{

  \item{ScientificName}{Scientific name of the species}

  \item{realm}{Habitat realm (terrestrial, freshwater, or marine)}

  \item{CS}{Logical indicating presence in Citizen Science data}

  \item{PL}{Logical indicating presence in Published Literature}

  \item{AO}{Logical indicating presence in Author's Observations}

}

@source Preda, C. et al. (submitted). From soil to stream and sea: species richness and distribution of alien invertebrates in Romania. Neobiota.

"species_list"
