#' \code{Select}
#'
#'
#' @description Subscripts a range of elements (e.g., from a vector or list), based on the
#' name of the elements.
#' @param x The object to be subscripted.
#' @param from The name of the first element to be selected.
#' @param to The name of the last element to be selected.
#' @param MARGIN The margin of the object to select from. Only used with arrays and matrices.
#' @param drop Whether to drop the final dimension. This parameter is only used for arrays and matrices.
#' @export
Select <- function(x, from, to, MARGIN = NULL, drop = FALSE)
{
    UseMethod("Select")
}

#' @inherit Select
#' @export
Select.default <- function(x, from, to, MARGIN = NULL, drop = FALSE)
{
    out <- x[selectIndices(names(x), from, to)]
    CopyAttributes(out, x)
    out
}

selectIndices <- function(names, from, to)
{
    if (is.null(names))
        stop("There are no names to select from.")
    frm <- match(from, names)
    if (is.na(frm))
        stop("'", from, "' is not one of the names.")
    t <- match(to, names)
    if (is.na(t))
        stop(to, " is not one of the names.")
    frm:t
}

#' @inherit Select
#' @export
Select.data.frame <- function(x, from, to, MARGIN = NULL, drop = FALSE)
{
    out <- x[, selectIndices(names(x), from, to)]
    CopyAttributes(out, x)
    out
}

#' @inherit Select
#' @export
Select.matrix <- function(x, from, to, MARGIN = NULL, drop = FALSE)
{
    if (is.null(MARGIN))
        stop("'MARGIN needs to be specified. A 1 for rows and 2 for columns.")
    Select.array(x, from, to, MARGIN, drop)
}

#' @inherit Select
#' @export
Select.array <- function(x, from, to, MARGIN = NULL, drop = FALSE)
{
    if (is.null(MARGIN))
        stop("'MARGIN needs to be specified.")
    dims <- dim(x)
    if (!MARGIN %in% 1:length(dims))
        stop("'MARGIN' is invalid (not compatible with dimensions of the array).")

    names <- dimnames(x)[[MARGIN]]
    i <- selectIndices(names, from, to)
    # Updating 'x'
    i.string <- paste0("c(", paste0(i, collapse = ","), ")")
    len <- length(dims)
    pre.i <- if (MARGIN <= 1) "" else paste0(rep(",", MARGIN - 1), collapse = "")
    post.i <- if (MARGIN >= len) "" else paste0(rep(",", len - MARGIN), collapse = "")
    cmnd <- paste0("x[", pre.i, i.string, post.i, ", drop = ", drop, "]")
    out <- eval(parse(text = cmnd))
    CopyAttributes(out, x)
    out
}

