#' Runs multi-taxa environmental occupancy models in a Bayesian hierarchical framework
#'
#' @import magrittr
#' @import nimble
#' @importFrom rlang check_required enquo syms abort
#' @importFrom MCMCvis MCMCsummary
#'
#' @param df data frame
#' @param var_id character
#' @param var_tmp character
#' @param var_tax character
#' @param var_cnt character
#' @param var_envO character or character vector
#' @param var_envP character or character vector
#' @param var_envC character or character vector
#' @param var_reg character or character vector
#' @param var_guild character or character vector
#' @param period list
#' @param timestep numeric
#' @param save_parameters character or character vector
#' @param n_chain numeric
#' @param n_iter numeric
#' @param n_thin numeric
#' @param n_burnin numeric
#'
#' @return output list
#' @export
#'
#' @examples
#' \dontrun{
#' data(riverfish)
#' df <- riverfish[riverfish$pass == 1,]
#' mcmc.out <- modenv_popoccup(df[df$taxa == "eel",],
#' var_id = "pop_id",
#' var_tmp = "year",
#' var_cnt = "headcount",
#' var_envO = c("temperature","depth"),
#' n_chain=2,n_iter=10,n_thin=1,n_burnin=0)
#' mcmc.out <- modenv_popoccup(df[df$taxa == "eel",],
#' var_id = "pop_id",
#' var_tmp = "year",
#' var_cnt = "headcount",
#' var_envO = c("temperature","depth"),
#' var_reg = "hydro_basin",
#' period = list(c(2010,2016),c(2016,2022)),
#' n_chain=2,n_iter=10,n_thin=1,n_burnin=0)
#' mcmc.out <- modenv_popoccup(df,
#' var_id = "pop_id",
#' var_tmp = "year",
#' var_cnt = "headcount",
#' var_tax = "taxa",
#' var_envP = c("temperature","depth"),
#' n_chain=2,n_iter=10,n_thin=1,n_burnin=0)
#' mcmc.out <- modenv_popoccup(df,
#' var_id = "pop_id",
#' var_tmp = "year",
#' var_cnt = "headcount",
#' var_tax = "taxa",
#' var_envP = c("temperature","depth"),
#' var_envC = "temperature",
#' n_chain=2,n_iter=10,n_thin=1,n_burnin=0)
#' mcmc.out <- modenv_popoccup(df,
#' var_id = "pop_id",
#' var_tmp = "year",
#' var_cnt = "headcount",
#' var_tax = "taxa",
#' var_envP = c("temperature","depth"),
#' var_envC = "temperature",
#' var_guild = "family",
#' n_chain=2,n_iter=10,n_thin=1,n_burnin=0)
#' }
modenv_popoccup <- function(df, var_id, var_tmp, var_cnt, var_tax=NULL, var_envO=NULL, var_envP=NULL, var_envC=NULL, var_reg=NULL, var_guild=NULL, period=NULL, timestep=1, save_parameters=NULL, n_chain=3, n_iter=10000, n_thin=ceiling(n_iter/100), n_burnin=floor(n_iter/4)) {
  #-----------------------------------------------------------------------------
  # Check for missing required arguments
  check_required(var_id)
  check_required(var_tmp)
  check_required(var_cnt)
  if (quo_is_null(enquo(var_envO)) & quo_is_null(enquo(var_envP)) & quo_is_null(enquo(var_envC))) {
    abort("'var_envO', 'var_envP' or 'var_envC' must be supplied")
  }
  #-----------------------------------------------------------------------------
  # Check for mistakes, if failure return an error message and stop
  df <- do.call(int_checkvarenv, list(df, var_id=enquo(var_id), var_tmp=enquo(var_tmp), vars=syms(c(var_envO,var_envP,var_envC))))
  df <- do.call(int_checkfunction, list(df,
                                        vars_in_df=syms(c(var_id, var_tmp, var_tax, var_cnt, var_envO, var_envP, var_envC, var_reg, var_guild)),
                                        vars_na=syms(c(var_id, var_tmp, var_tax, var_envO, var_envP, var_envC)),
                                        vars_numeric=syms(c(var_tmp, var_cnt, var_envO, var_envP, var_envC)),
                                        vars_duplicate=syms(c(var_id, var_tmp, var_tax)),
                                        var_tmp=enquo(var_tmp), timestep, period,
                                        vars_pas=NULL))
  #-----------------------------------------------------------------------------
  var_id <- enquo(var_id)
  var_tmp <- enquo(var_tmp)
  var_tax <- enquo(var_tax)
  var_pres <- enquo(var_cnt)
  var_envO <- enquo(var_envO)
  var_envP <- enquo(var_envP)
  var_envC <- enquo(var_envC)
  var_reg <- enquo(var_reg)
  var_guild <- enquo(var_guild)
  #-----------------------------------------------------------------------------
  # Write model and model data
  datamodel <- do.call(int_datamodel, list(df, occup=TRUE, grow=FALSE, modenv=TRUE, modenvG=FALSE, alt=FALSE, timestep, period, var_id, var_tmp, var_tax, var_pres, var_reg, var_guild, var_cnt=NULL, var_wei=NULL, var_surf=NULL, var_pro=NULL, var_envO, var_envP, var_envC, var_grow=NULL))
  code <- do.call(int_popoccup, list(occup=TRUE,modenv=TRUE,var_envO,var_envP,var_envC,var_guild))
  popdyn_code <- as.call(c(as.symbol("{"), code))
  #-----------------------------------------------------------------------------
  # Define requested parameters
  if (is.null(save_parameters)) { save_parameters <- datamodel$popdyn_parameters } else {
    if (FALSE %in% is.element(save_parameters, datamodel$popdyn_parameters)) {
      para_name <- save_parameters[which(is.element(save_parameters, datamodel$popdyn_parameters) %in% FALSE)]
      abort(paste0("Some parameters are not in model: '", para_name, "'", collapse = " "))
    }
  }
  #-----------------------------------------------------------------------------
  # Fit model
  set.seed(123)
  popdyn <- nimbleModel(code = popdyn_code,
                        constants = datamodel$popdyn_const,
                        data = datamodel$popdyn_data,
                        inits = datamodel$popdyn_inits,
                        name = "popdyn", calculate = FALSE)
  popdynConf <- configureMCMC(popdyn, monitors = save_parameters)
  popdynMCMC <- buildMCMC(popdynConf)
  popdynComp <- compileNimble(popdyn)
  popdynModel <- compileNimble(popdynMCMC, project = popdyn, resetFunctions = TRUE)
  mcmc_chain <- runMCMC(popdynModel, nchains = n_chain, niter = n_iter, thin = n_thin, nburnin = n_burnin, setSeed = 123, samplesAsCodaMCMC = TRUE)
  if (n_chain == 1 & !is.null(dim(mcmc_chain))) {
    mcmc_na <- which(is.na(mcmc_chain[1,]))
    if (length(mcmc_na) > 0) { mcmc_chain <- mcmc_chain[,-mcmc_na] }
  }
  if (n_chain > 1 & !is.null(dim(mcmc_chain[[1]]))) { for (i in 1:n_chain) {
    mcmc_chain[[i]] <- mcmc_chain[[i]][,!colnames(mcmc_chain[[i]]) %in% names(which(is.na(mcmc_chain[[i]][1,])))]
  }}
  #-----------------------------------------------------------------------------
  # set summary data frame of taxa and guilds and list of subscripts
  mcmc_summary <- MCMCsummary(mcmc_chain, probs = c(0.025, 0.25, 0.5, 0.75, 0.975), Rhat = TRUE, n.eff = TRUE)
  list_summary <- do.call(int_transformsummary, list(mcmc_summary, datamodel, var_id, var_tmp, var_tax, period))
  output <- list(mcmc_summary = list_summary$mcmc_summary, mcmc_chain = mcmc_chain, subscript = list_summary$subscript)
  #-----------------------------------------------------------------------------
  return(output)
}
