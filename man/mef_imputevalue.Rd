% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mef_imputevalue.R
\name{mef_imputevalue}
\alias{mef_imputevalue}
\title{Imputes missing values in times series}
\usage{
mef_imputevalue(df, var_id, var_tmp, var_imp)
}
\arguments{
\item{df}{data frame}

\item{var_id}{variable name with sampling location identifiers}

\item{var_tmp}{variable name with continuous sampling times}

\item{var_imp}{variable name with missing values to be imputed}
}
\details{
\code{mef_imputevalue} imputes missing values of a variable from observed values in order to
get complete time series. At the location scale, the missing values are substituted by the
previous time value or, failing that, by the following time value.
}
\value{
\code{mef_imputevalue} returns the data frame \code{df} after imputing the missing values.
}
\description{
Imputes missing values of a variable from observed values.
}
\examples{
data(riverfish)
n <- sample(2010:2022, 4)
riverfish[riverfish$year \%in\% n,"surface"] <- NA

# Imputation of surface missing values
df <- mef_imputevalue(riverfish, var_id=pop_id, var_tmp=year, var_imp=surface)
}
