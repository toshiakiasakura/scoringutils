% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/documentation-templates.R
\name{forecast_types}
\alias{forecast_types}
\title{Documentation template for forecast types}
\description{
Documentation template for forecast types
}
\section{Forecast types and input format}{
Various different forecast types / forecast formats are supported. At the
moment, those are
\itemize{
\item point forecasts
\item binary forecasts ("soft binary classification")
\item Probabilistic forecasts in a quantile-based format (a forecast is
represented as a set of predictive quantiles)
\item Probabilistic forecasts in a sample-based format (a forecast is represented
as a set of predictive samples)
}

Forecast types are determined based on the columns present in the input data.

\emph{Point forecasts} require a column \code{observed} of type numeric and a column
\code{predicted} of type numeric.

\emph{Binary forecasts} require a column \code{observed} of type factor with exactly
two levels and a column \code{predicted} of type numeric with probabilities,
corresponding to the probability that \code{observed} is equal to the second
factor level. See details \link[=brier_score]{here} for more information.

\emph{Quantile-based forecasts} require a column \code{observed} of type numeric,
a column \code{predicted} of type numeric, and a column \code{quantile_level} of type
numeric with quantile-levels (between 0 and 1).

\emph{Sample-based forecasts} require a column \code{observed} of type numeric,
a column \code{predicted} of type numeric, and a column \code{sample_id} of type
numeric with sample indices.

For more information see the vignettes and the example data
(\link{example_quantile}, \link{example_continuous}, \link{example_integer},
\code{\link[=example_point]{example_point()}}, and \link{example_binary}).
}

\section{Forecast unit}{
In order to score forecasts, \code{scoringutils} needs to know which of the rows
of the data belong together and jointly form a single forecasts. This is
easy e.g. for point forecast, where there is one row per forecast. For
quantile or sample-based forecasts, however, there are multiple rows that
belong to single forecast.

The \emph{forecast unit} or \emph{unit of a single forecast} is then described by the
combination of columns that uniquely identify a single forecast.
For example, we could have forecasts made by different models in various
locations at different time points, each for several weeks into the future.
The forecast unit could then be described as
\code{forecast_unit = c("model", "location", "forecast_date", "forecast_horizon")}.
\code{scoringutils} automatically tries to determine the unit of a single
forecast. It uses all existing columns for this, which means that no columns
must be present that are unrelated to the forecast unit. As a very simplistic
example, if you had an additional row, "even", that is one if the row number
is even and zero otherwise, then this would mess up scoring as \code{scoringutils}
then thinks that this column was relevant in defining the forecast unit.

In order to avoid issues, we recommend using the function
\code{\link[=set_forecast_unit]{set_forecast_unit()}} to determine the forecast unit manually.
The function simply drops unneeded columns, while making sure that all
necessary, 'protected columns' like "predicted" or "observed" are retained.
}

\keyword{internal}
