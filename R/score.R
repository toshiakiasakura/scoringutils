#' @title Evaluate forecasts in a data.frame format
#' @description `score()` applies a selection of scoring metrics to a data.frame
#' of forecasts. It is the workhorse of the `scoringutils` package.
#' `score()` is a generic that dispatches to different methods depending on the
#' class of the input data.
#'
#' We recommend that users call [as_forecast()] prior to calling `score()` to
#' validate the input data and convert it to a forecast object (though
#' `score.default()` will do this if it hasn't happened before).
#' See below for more information on forecast types and input formats.
#' For additional help and examples, check out the [Getting Started
#' Vignette](https://epiforecasts.io/scoringutils/articles/scoringutils.html) as
#' well as the paper [Evaluating Forecasts with scoringutils in
#' R](https://arxiv.org/abs/2205.07090).
#' @inheritSection forecast_types Forecast types and input format
#' @inheritSection forecast_types Forecast unit
#' @param data A data.frame or data.table with predicted and observed values.
#' @param metrics A named list of scoring functions. Names will be used as
#' column names in the output. See [rules_point()], [rules_binary()],
#' [rules_quantile()], and [rules_sample()] for more information on the
#' default metrics used.
#' @param ... additional arguments
#' @return A data.table with unsummarised scores. This will generally be
#' one score per forecast (as defined by the unit of a single forecast).
#'
#' For quantile-based forecasts, one score per quantile will be returned
#' instead. This is done as scores can be computed and may be of interest
#' for individual quantiles. You can call [summarise_scores()]) on the
#' unsummarised scores to obtain one score per forecast unit for quantile-based
#' forecasts.
#' @importFrom data.table ':=' as.data.table
#' @importFrom stats na.omit
#' @examples
#' library(magrittr) # pipe operator
#' \dontshow{
#'   data.table::setDTthreads(2) # restricts number of cores used on CRAN
#' }
#'
#' validated <- as_forecast(example_quantile)
#' score(validated) %>%
#'   summarise_scores(by = c("model", "target_type"))
#'
#' # set forecast unit manually (to avoid issues with scoringutils trying to
#' # determine the forecast unit automatically), check forecasts before scoring
#' example_quantile %>%
#'   set_forecast_unit(
#'     c("location", "target_end_date", "target_type", "horizon", "model")
#'   ) %>%
#'   as_forecast() %>%
#'   score()
#'
#' # forecast formats with different metrics
#' \dontrun{
#' score(example_binary)
#' score(example_quantile)
#' score(example_point)
#' score(example_integer)
#' score(example_continuous)
#' }
#' @author Nikos Bosse \email{nikosbosse@@gmail.com}
#' @references
#' Bosse NI, Gruson H, Cori A, van Leeuwen E, Funk S, Abbott S
#' (2022) Evaluating Forecasts with scoringutils in R.
#' \doi{10.48550/arXiv.2205.07090}
#' @export

score <- function(data, ...) {
  UseMethod("score")
}

#' @rdname score
#' @export
score.default <- function(data, ...) {
  assert(check_data_columns(data))
  forecast_type <- get_forecast_type(data)
  data <- new_forecast(data, paste0("forecast_", forecast_type))
  score(data, ...)
}

#' @importFrom stats na.omit
#' @importFrom data.table setattr
#' @rdname score
#' @export
score.forecast_binary <- function(data, metrics = rules_binary(), ...) {
  data <- validate_forecast(data)
  data <- na.omit(data)
  metrics <- validate_metrics(metrics)

  scores <- apply_rules(
    data, metrics,
    data$observed, data$predicted, ...
  )

  scores <- as_scores(scores, score_names = names(metrics))
  return(scores[])
}


#' @importFrom Metrics se ae ape
#' @importFrom stats na.omit
#' @importFrom data.table setattr
#' @rdname score
#' @export
score.forecast_point <- function(data, metrics = rules_point(), ...) {
  data <- validate_forecast(data)
  data <- na.omit(data)
  metrics <- validate_metrics(metrics)

  scores <- apply_rules(
    data, metrics,
    data$observed, data$predicted, ...
  )

  scores <- as_scores(scores, score_names = names(metrics))
  return(scores[])
}

#' @importFrom stats na.omit
#' @importFrom data.table setattr
#' @rdname score
#' @export
score.forecast_sample <- function(data, metrics = rules_sample(), ...) {
  data <- validate_forecast(data)
  data <- na.omit(data)
  forecast_unit <- get_forecast_unit(data)
  metrics <- validate_metrics(metrics)

  # transpose the forecasts that belong to the same forecast unit
  d_transposed <- data[, .(predicted = list(predicted),
                           observed = unique(observed),
                           scoringutils_N = length(list(sample_id))),
                       by = forecast_unit]

  # split according to number of samples and do calculations for different
  # sample lengths separately
  d_split <- split(d_transposed, d_transposed$scoringutils_N)

  split_result <- lapply(d_split, function(data) {
    # create a matrix
    observed <- data$observed
    predicted <- do.call(rbind, data$predicted)
    data[, c("observed", "predicted", "scoringutils_N") := NULL]

    data <- apply_rules(
      data, metrics,
      observed, predicted, ...
    )
    return(data)
  })
  scores <- rbindlist(split_result)
  scores <- as_scores(scores, score_names = names(metrics))
  return(scores[])
}


#' @importFrom stats na.omit
#' @importFrom data.table `:=` as.data.table rbindlist %like% setattr
#' @rdname score
#' @export
score.forecast_quantile <- function(data, metrics = rules_quantile(), ...) {
  data <- validate_forecast(data)
  data <- na.omit(data)
  forecast_unit <- get_forecast_unit(data)
  metrics <- validate_metrics(metrics)

  # transpose the forecasts that belong to the same forecast unit
  # make sure the quantiles and predictions are ordered in the same way
  d_transposed <- data[, .(
    predicted = list(predicted[order(quantile_level)]),
    observed = unique(observed),
    quantile_level = list(sort(quantile_level, na.last = TRUE)),
    scoringutils_quantile_level = toString(sort(quantile_level, na.last = TRUE))
  ), by = forecast_unit]

  # split according to quantile_level lengths and do calculations for different
  # quantile_level lengths separately. The function `wis()` assumes that all
  # forecasts have the same quantile_levels
  d_split <- split(d_transposed, d_transposed$scoringutils_quantile_level)

  split_result <- lapply(d_split, function(data) {
    # create a matrix out of the list of predicted values and quantile_levels
    observed <- data$observed
    predicted <- do.call(rbind, data$predicted)
    quantile_level <- unlist(unique(data$quantile_level))
    data[, c(
      "observed", "predicted", "quantile_level", "scoringutils_quantile_level"
    ) := NULL]

    data <- apply_rules(
      data, metrics,
      observed, predicted, quantile_level, ...
    )
    return(data)
  })
  scores <- rbindlist(split_result)

  # this can have existing scores, e.g. from `add_coverage()`
  existing_scores <- get_score_names(data)
  scores <- as_scores(scores, score_names = c(existing_scores, names(metrics)))

  return(scores[])
}


#' @title Apply A List Of Functions To A Data Table Of Forecasts
#' @description This helper function applies scoring rules (stored as a list of
#' functions) to a data table of forecasts. `apply_rules` is used within
#' `score()` to apply all scoring rules to the data.
#' Scoring rules are wrapped in [run_safely()] to catch errors and to make
#' sure that only arguments are passed to the scoring rule that are actually
#' accepted by it.
#' @inheritParams score
#' @return A data table with the forecasts and the calculated metrics
#' @keywords internal
apply_rules <- function(data, metrics, ...) {
  expr <- expression(
    data[, (metric_name) := do.call(run_safely, list(..., fun = fun))]
  )
  lapply(seq_along(metrics), function(i, data, ...) {
    metric_name <- names(metrics[i]) # nolint
    fun <- metrics[[i]] # nolint
    eval(expr)
  }, data, ...)
  return(data)
}


#' Construct An Object Of Class `scores`
#' @description This function creates an object of class `scores` based on a
#' data.table or similar.
#' @param scores A data.table or similar with scores as produced by [score()]
#' @param score_names A character vector with the names of the scores
#' (i.e. the names of the scoring rules used for scoring)
#' @keywords internal
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   model = "A",
#'   wis = "0.1"
#' )
#' new_scores(df, "wis")
#' }
new_scores <- function(scores, score_names) {
  scores <- as.data.table(scores)
  class(scores) <- c("scores", class(scores))
  setattr(scores, "score_names", score_names)
  return(scores[])
}


#' Create An Object Of Class `scores` From Data
#' @description This convenience function wraps [new_scores()] and validates
#' the `scores` object.
#' @inheritParams new_scores
#' @returns Returns an object of class 1scores`
#' @importFrom checkmate assert_data_frame
#' @keywords internal
as_scores <- function(scores, score_names) {
  assert_data_frame(scores)
  scores <- new_scores(scores, score_names)
  validate_scores(scores)
  return(scores[])
}


#' Validate An Object Of Class `scores`
#' @description This function validates an object of class `scores`, checking
#' that it has the correct class and that it has a `score_names` attribute.
#' @inheritParams new_scores
#' @returns Returns `NULL` invisibly
#' @importFrom checkmate assert_class assert_data_frame
#' @keywords internal
validate_scores <- function(scores) {
  assert_data_frame(scores)
  assert_class(scores, "scores")
  # error if no score_names exists +
  # throw warning if any of the score_names is not in the data
  get_score_names(scores, error = TRUE)
  return(invisible(NULL))
}
