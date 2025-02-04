% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/score.R
\name{validate_scores}
\alias{validate_scores}
\title{Validate An Object Of Class \code{scores}}
\usage{
validate_scores(scores)
}
\arguments{
\item{scores}{A data.table or similar with scores as produced by \code{\link[=score]{score()}}}
}
\value{
Returns \code{NULL} invisibly
}
\description{
This function validates an object of class \code{scores}, checking
that it has the correct class and that it has a \code{score_names} attribute.
}
\keyword{internal}
