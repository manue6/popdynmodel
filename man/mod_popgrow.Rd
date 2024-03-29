% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mod_popgrow.R
\name{mod_popgrow}
\alias{mod_popgrow}
\title{Population growth modelling in a Bayesian hierarchical framework}
\usage{
mod_popgrow(
  df,
  var_id,
  var_tmp,
  var_tax = NULL,
  var_cnt = NULL,
  var_wei = NULL,
  var_surf = NULL,
  var_reg = NULL,
  var_guild = NULL,
  period = NULL,
  timestep = 1,
  save_parameters = NULL,
  n_chain = 3,
  n_iter = 10000,
  n_thin = ceiling(n_iter/100),
  n_burnin = floor(n_iter/4)
)
}
\arguments{
\item{df}{data frame with variables used in the model}

\item{var_id}{[character] variable name with sampling location identifiers (must not contain missing values)}

\item{var_tmp}{[character] variable name with continuous sampling times (must be numeric without missing values)}

\item{var_tax}{[optional, character] variable name with taxa identifiers to be specified for the multi-taxa models (must not contain missing values)}

\item{var_cnt}{[optional, character] variable name with taxa abundances (must be numeric)}

\item{var_wei}{[optional, character] variable name with taxa biomasses (must be numeric)}

\item{var_surf}{[optional, character] variable name with quantitative sampling effort (e.g. sampling surfaces). If supplied, the model takes into account variabilities in sampling effort from one time to the next (must be numeric without missing values)}

\item{var_reg}{[optional, character] variable name(s) with spatial level identifiers. If supplied, estimates of occupancy changes rates at intermediate spatial levels are added to the model. Otherwise, occupancy change rates are only estimated across all locations}

\item{var_guild}{[optional, character] variable name(s) with taxa guilds identifiers. If supplied, estimates of guild occupancy changes rates are added to the model}

\item{period}{[optional, numeric] list with start and end times for estimating intermediate average growth rates}

\item{timestep}{[optional, numeric] interval between two consecutive times to account for regular gaps in time series in the rate estimates}

\item{save_parameters}{[optional, character] name(s) of the parameter(s) to save (by default, all model parametes are saved)}

\item{n_chain}{[optional, numeric] number of MCMC chains}

\item{n_iter}{[optional, numeric] number of iterations per MCMC chain}

\item{n_thin}{[optional, numeric] backup interval for MCMC samples}

\item{n_burnin}{[optional, numeric] number of initial iterations to discard per Markov chain}
}
\details{
\code{mod_popgrow} relies on Bayesian hierarchical state-space models that include two or three main components. The first component describes the occupancy dynamics of taxa at locations defined by \code{var_id} from taxon- and location-specific probabilities of persistence and colonisation. Two other independent components describe the population growth of taxa on successively occupied locations, one based on abundance (if \code{var_cnt} is supplied) and other based on biomass (if \code{var_wei} is supplied). These two components are based on an autoregressive growth model. At location, global (i.e. across all locations) and intermediate spatial levels defined by \code{var_reg}, the finite population growth rates are estimated as the changes in population size from one time to the next. Their geometric means are used as average growth rates over the whole time modelling period and over intermediate time periods defined by \code{period}. If \code{var_guild} is supplied, the guild occupancy growth rates are assessed from the geometric means of taxa growth rates.

The models are run using the \code{runMCMC} function of \code{nimble} package.
}
\value{
\code{mod_popgrow} returns a list with the summaries of main statistics associated with the estimation of the requested parameters \code{(mcmc_summary}), the MCMC chains (\code{mcmc_chain}) and the list of parameters subscripts (\code{subscript}).
}
\seealso{
\code{\link{mod_popgrowRS}} and \code{\link{get_modparameters}}
}
\description{
Fits Bayesian hierarchical single or multi-species population growth models to abundance and/or biomass time series. The modelling framework not accounts for detection biases of taxa and individuals.
}
\examples{
\dontrun{
data(riverfish)
df <- riverfish[riverfish$pass == 1,]

# Pike population growth from abundance
mcmc.out <- mod_popgrow(df[df$taxa == "pike",],
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_cnt = "headcount")

# Multi-taxa population growth from biomass
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_wei = "biomass")

# Multi-taxa population growth from abundance and biomass
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_cnt = "headcount",
                        var_wei = "biomass")

# Account for variabilities in annual sampling surfaces
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_cnt = "headcount",
                        var_wei = "biomass",
                        var_surf = "surface")

# Add growth rates for gudgeon guild
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_cnt = "headcount",
                        var_wei = "biomass",
                        var_surf = "surface",
                        var_guild = "gudgeon")

# Add growth rates at basin level
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_cnt = "headcount",
                        var_wei = "biomass",
                        var_surf = "surface",
                        var_guild = "gudgeon",
                        var_reg = "hydro_basin")

# Add intermediate growth rates
mcmc.out <- mod_popgrow(df,
                        var_id = "pop_id",
                        var_tmp = "year",
                        var_tax = "taxa",
                        var_cnt = "headcount",
                        var_wei = "biomass",
                        var_surf = "surface",
                        var_guild = "gudgeon",
                        var_reg = "hydro_basin",
                        period = list(c(2010,2015),c(2015,2020)))
}
}
