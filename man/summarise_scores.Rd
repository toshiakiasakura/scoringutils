% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summarise_scores.R
\name{summarise_scores}
\alias{summarise_scores}
\alias{summarize_scores}
\title{Summarise scores as produced by \code{\link[=score]{score()}}}
\usage{
summarise_scores(scores, by = NULL, across = NULL, fun = mean, ...)

summarize_scores(scores, by = NULL, across = NULL, fun = mean, ...)
}
\arguments{
\item{scores}{A data.table of scores as produced by \code{\link[=score]{score()}}.}

\item{by}{character vector with column names to summarise scores by. Default
is \code{NULL}, meaning that the only summary that takes is place is summarising
over samples or quantiles (in case of quantile-based forecasts), such that
there is one score per forecast as defined by the \emph{unit of a single forecast}
(rather than one score for every sample or quantile).
The \emph{unit of a single forecast} is determined by the columns present in the
input data that do not correspond to a metric produced by \code{\link[=score]{score()}}, which
indicate indicate a grouping of forecasts (for example there may be one
forecast per day, location and model). Adding additional, unrelated, columns
may alter results in an unpredictable way.}

\item{across}{character vector with column names from the vector of variables
that define the \emph{unit of a single forecast} (see above) to summarise scores
across (meaning that the specified columns will be dropped). This is an
alternative to specifying \code{by} directly. If \code{NULL} (default), then \code{by} will
be used or inferred internally if also not specified. Only  one of \code{across}
and \code{by}  may be used at a time.}

\item{fun}{a function used for summarising scores. Default is \code{mean}.}

\item{...}{additional parameters that can be passed to the summary function
provided to \code{fun}. For more information see the documentation of the
respective function.}
}
\value{
a data.table with summarised scores. Scores are summarised according
to the names of the columns of the original data specified in \code{by} or
\code{across} using the \code{fun} passed to \code{summarise_scores()}.
}
\description{
Summarise scores as produced by \code{\link[=score]{score()}}
}
\examples{
\dontshow{
  data.table::setDTthreads(2) # restricts number of cores used on CRAN
}
library(magrittr) # pipe operator
\dontrun{
scores <- score(example_continuous)
summarise_scores(scores)
}

# summarise over samples or quantiles to get one score per forecast
scores <- score(example_quantile)
summarise_scores(scores)

# get scores by model
summarise_scores(scores,by = "model")

# get scores by model and target type
summarise_scores(scores, by = c("model", "target_type"))

# Get scores summarised across horizon, forecast date, and target end date
summarise_scores(
 scores, across = c("horizon", "forecast_date", "target_end_date")
)

# get standard deviation
summarise_scores(scores, by = "model", fun = sd)

# round digits
summarise_scores(scores,by = "model") \%>\%
  summarise_scores(fun = signif, digits = 2)

# get quantiles of scores
# make sure to aggregate over interval ranges first
summarise_scores(scores,
  by = "model", fun = quantile,
  probs = c(0.25, 0.5, 0.75)
)

# get ranges
# summarise_scores(scores, by = "range")
}
\keyword{scoring}
