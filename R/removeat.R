#' \code{RemoveAt}
#'
#' @description Removes one or more elements from an object. Dimensions are never
#' If all elements are removed from a vector, then a 0-length vector is returned.
#' @param x The object from which the elements are to be removed.
#' @param at A \code{\link{vector}} or indicating which elements are to be removed.
#' When \code{at} is \code{\link{character}} elements with this name are removed. When \code{at}
#' is \code{\link{integer}}, elements with this position are removed. If \code{MARGIN} contains two
#' or more values, \code{at} may be a list, where each element of the list contains a vector.
#' @param MARGIN An \code{\link{vector}} of integers giving the dimensions from which elements should be removed.
#' @param split Character delimiter to split \code{at} when \code{at} is a
#' \code{\link{character}}. Default is NULL which means that no splitting
#' occurs. See \code{\link{strsplit}}.
#' @param ignore.case Ignores case if and when removing elements based on their names.
#' @return An object of the same class as \code{x}.
#' @export
RemoveAt <- function(x, at = NULL, MARGIN = NULL, ignore.case = TRUE, split = NULL)
{
    UseMethod("RemoveAt")
}

#' @inherit RemoveAt
#' @export
RemoveAt.default <- function(x, at = NULL, MARGIN = NULL, ignore.case = TRUE, split = NULL)
{
    if (is.null(at))
        return(x)
    at <- unlist(at)
    if (is.character(at) && (is.null(names(x)) || all(!nzchar(at))))
        return(x)
    out <- x[indicesToRetain(names(x), at, length(x), ignore.case = ignore.case, split = split)]
    CopyAttributes(out, x)
}



#' @describeIn RemoveAt Where only a \code{at} is provided, it is assumed
#' to be the variables of a data frame. Otherwise, the first \code{MARGIN}
#' is assumed the rows and the second the columns.
#' @inherit RemoveAt
#' @export
RemoveAt.data.frame <- function(x, at = NULL, MARGIN = NULL, ignore.case = TRUE, split = NULL)
{
    if (!is.list(at) && is.null(MARGIN))
        return(RemoveAt.default(x, at, MARGIN, ignore.case, split))
    RemoveAt.array(x, at, MARGIN, ignore.case, split)
}

#' @inherit RemoveAt
#' @export
RemoveAt.array <- function(x, at = NULL, MARGIN = NULL, ignore.case = TRUE, split = NULL)
{
    if (is.null(MARGIN))
         MARGIN <- 1:length(dim(x))
    if (removeArrayInputsBad(x, at, MARGIN))
        return(x)
    out <- x
    for (m in seq_along(MARGIN))
    {
        a <- if(is.list(at)) at[[m]] else at
        out <- removeFromDimension(out, a, MARGIN[m], ignore.case, split)
    }
    CopyAttributes(out, x)
}

#' @inherit RemoveAt
#' @export
RemoveAt.matrix <- function(x, at = NULL, MARGIN = NULL, ignore.case = TRUE, split = NULL)
{
    RemoveAt.array(x, at, MARGIN, ignore.case, split)
}

removeArrayInputsBad <- function(x, at, MARGIN)
{
    if (is.null(at))
        return(TRUE)
    dimnames <- dimnames(x)
    if (is.list(at) && length(MARGIN) != length(at))
        stop("If 'at' is a list, it must have the same number of elements as MARGIN.")
    if (is.character(at))
        if (all(is.null(dimnames[MARGIN])))
            return(TRUE)
    FALSE
}


#' @inherit RemoveAt
removeFromDimension <- function(x, at = NULL, MARGIN = 1L, ignore.case = TRUE, split = NULL)
{
    names <- dimnames(x)[[MARGIN]]
    if (!is.character(at) || is.null(names))
        return(x)
    dims <- dim(x)
    i <- indicesToRetain(names, at, dims[MARGIN], ignore.case, split) # Indices or Logical
    # Updating 'x'
    i.string <- paste0("c(", paste0(i, collapse = ","), ")")
    len <- length(dims)
    pre.i <- if (MARGIN <= 1) "" else paste0(rep(",", MARGIN - 1), collapse = "")
    post.i <- if (MARGIN >= len) "" else paste0(rep(",", len - MARGIN), collapse = "")
    #print(class(x))
    #print(MARGIN)
    #drop <- if(is.data.frame(x) && MARGIN == 1) "" else ", drop = FALSE"
    drop <- ", drop = FALSE"
    cmnd <- paste0("x[", pre.i, i.string, post.i, drop, "]")
    eval(parse(text = cmnd))
}

#' indicesToRetain
#'
#' Worker function for \code{RemoveAt}.
#' @inherit RemoveAt
#' @param length.x The length of the object that is to be subscripted.
#' @param names The names of the elements.
indicesToRetain <- function(names, at, length.x, ignore.case = TRUE, split = NULL)
{
    names <- trimws(names)
    if (is.null(names))
        return(1:length.x)
    # 'at' is character and able to represent a variable
    if (is.character(at))
    {
        at <- TrimWhitespace(at)
        if (ignore.case)
        {
            at <- tolower(at)
            names <- tolower(names)
        }
        if (!is.null(split))
            at <- ConvertCommaSeparatedStringToVector(at, split)
        return(!names %in% at)
    }
    # 'at' is numeric
    if (AllIntegers(at))
    {
        if (any(is.na(at) | at < 1))
            stop("'at' must contain integers.")
        if (max(at) > length.x)
            stop("'at' contains a value of ", max(at), " which is bigger than the length of 'x'." )
        return(-at)
    }
    stop("'at' must contain character (string) or integer values.")
}


