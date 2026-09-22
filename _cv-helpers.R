# ===========================================================================
# _cv-helpers.R — turns the CSV files in data/ into the CV sections.
#
# You should not need to touch this file.
# To update the CV, edit the spreadsheets in data/ :
#
#   data/events.csv        entries with a date on the right
#                          (jobs, education, training, skills, ...)
#   data/publications.csv  papers, preprints, preregistrations, abstracts
#   data/conferences.csv   talks and posters at conferences
#   data/bullets.csv       plain lists (teaching, awards, invited talks, ...)
#
# data/README.md explains every column.
#
# Two rules that apply to all the files:
#   * inside a cell you can use markdown: **bold**, *italic*, [text](link)
#   * in the "details" column, separate several bullet points with |
# ===========================================================================

cv_data_dir <- "data"


# --- reading the files ------------------------------------------------------

# Read one CSV; every cell comes back as text, empty cells as "".
cv_read <- function(file) {
  path <- file.path(cv_data_dir, file)
  if (!file.exists(path)) {
    stop("Cannot find the data file '", path, "'.", call. = FALSE)
  }
  d <- utils::read.csv(
    path,
    colClasses  = "character",
    check.names = FALSE,
    na.strings  = character(0),
    encoding    = "UTF-8"
  )
  d[] <- lapply(d, trimws)
  d
}

# Value of one column for one row; "" if the column does not exist.
cv_get <- function(row, name) {
  value <- row[[name]]
  if (is.null(value) || length(value) == 0 || is.na(value)) "" else value
}

# The rows of `file` that belong to `section`.
cv_rows <- function(file, section) {
  d <- cv_read(file)
  if (is.null(d$section)) return(d)
  keep <- d$section == section
  if (!any(keep)) {
    stop("No rows with section = '", section, "' in ", file, ".\n",
         "Sections found in that file: ",
         paste(unique(d$section), collapse = ", "), call. = FALSE)
  }
  d[keep, , drop = FALSE]
}

# "a | b | c" -> c("a", "b", "c")
cv_items <- function(x) {
  if (!nzchar(x)) return(character(0))
  items <- trimws(unlist(strsplit(x, "|", fixed = TRUE)))
  items[nzchar(items)]
}


# --- links ------------------------------------------------------------------
#
# Long addresses like "https://doi.org/10.1016/j.neuropsychologia.2025.109210"
# are ugly on the page and break badly across lines in the PDF. So the link
# still points at the full address, but what you read is a short version:
#
#   https://doi.org/10.1016/j.xxx   ->  doi:10.1016/j.xxx
#   https://osf.io/8hefb/           ->  osf.io/8hefb
#
CV_URL_PATTERN <- '(?<!\\]\\()(?<!<)https?://[^\\s<>]*[^\\s<>(),.;:!?\\]]'

# The short text shown instead of the full address.
cv_url_text <- function(url) {
  short <- sub("^https?://", "", url)
  short <- sub("^www\\.", "", short)
  if (grepl("^doi\\.org/", short)) {
    short <- paste0("doi:", sub("^doi\\.org/", "", short))
  } else {
    short <- sub("/$", "", short)
  }
  short
}

# Replace every address in `x` using the function `make(url)`.
cv_replace_urls <- function(x, make) {
  found <- gregexpr(CV_URL_PATTERN, x, perl = TRUE)
  regmatches(x, found) <- lapply(
    regmatches(x, found),
    function(urls) if (length(urls)) vapply(urls, make, character(1)) else urls
  )
  x
}

# Characters that would be read as formatting inside a markdown link text.
cv_escape_md <- function(x) gsub("([][_*])", "\\\\\\1", x)

# Clickable address, short text (raw-HTML sections).
cv_link_html <- function(x) {
  cv_replace_urls(x, function(url) {
    paste0("<a href='", url, "' target='_blank' rel='noopener noreferrer'>",
           cv_url_text(url), "</a>")
  })
}

# Clickable address, short text (markdown sections: the web page and the PDF).
cv_link_md <- function(x) {
  cv_replace_urls(x, function(url) {
    paste0("[", cv_escape_md(cv_url_text(url)), "](", url, ")")
  })
}

# Add a full stop at the end, unless there already is some punctuation.
cv_stop <- function(x) {
  if (!nzchar(x) || grepl("[.!?]$", x)) x else paste0(x, ".")
}

# Glue the non-empty pieces together with `sep`.
cv_join <- function(..., sep = " ") {
  pieces <- c(...)
  paste(pieces[nzchar(pieces)], collapse = sep)
}


# ===========================================================================
# events.csv — entries with a date on the right
# ===========================================================================
cv_events <- function(section) {
  d <- cv_rows("events.csv", section)
  out <- ""

  for (i in seq_len(nrow(d))) {
    row     <- d[i, , drop = FALSE]
    what    <- cv_get(row, "what")
    where   <- cv_get(row, "where")
    when    <- cv_get(row, "when")
    icon    <- cv_get(row, "icon")
    details <- cv_items(cv_get(row, "details"))

    # What goes on the right-hand side: the date, or - for entries that have
    # no date, such as languages and software - the level.
    right <- when
    sub   <- where
    if (!nzchar(right)) {
      right <- where
      sub   <- ""
    }

    if (knitr::is_html_output()) {
      heading <- cv_join(icon, what)
      block <- paste0('<div class="cvevent">\n',
                      '  <div class="cvevent-left">\n',
                      '    <strong>', heading, '</strong>\n')
      if (nzchar(sub)) {
        block <- paste0(block, '    <div class="cvevent-where">', sub, '</div>\n')
      }
      if (length(details)) {
        block <- paste0(block, '    <ul>\n')
        for (item in details) {
          block <- paste0(block, '      <li>', cv_link_html(item), '</li>\n')
        }
        block <- paste0(block, '    </ul>\n')
      }
      block <- paste0(block, '  </div>\n',
                      '  <div class="cvevent-right">', right, '</div>\n',
                      '</div>\n\n')
    } else {
      # \cvdate is defined in cv.qmd: it pushes the text to the right margin
      header <- paste0("**", what, "**")
      if (nzchar(right)) header <- paste0(header, " \\cvdate{", right, "}")
      lines <- header
      if (nzchar(sub)) lines <- c(lines, paste0("_", sub, "_"))
      block <- paste0(paste(lines, collapse = "  \n"), "\n")
      if (length(details)) {
        block <- paste0(block, "\n")
        for (item in details) {
          block <- paste0(block, "  - ", cv_link_md(item), "\n")
        }
      }
      block <- paste0(block, "\n")
    }

    out <- paste0(out, block)
  }

  knitr::asis_output(out)
}


# ===========================================================================
# publications.csv — one numbered list per "status"
# ===========================================================================

# Authors (year). Title. *Journal*. **Label:** <link>. Note
cv_reference <- function(row) {
  authors <- sub("[,;]\\s*$", "", cv_get(row, "authors"))
  year    <- cv_get(row, "year")
  title   <- sub("\\.\\s*$", "", cv_get(row, "title"))
  journal <- cv_get(row, "journal")
  volume  <- cv_get(row, "volume")
  url     <- cv_get(row, "url")
  label   <- cv_get(row, "url_label")
  note    <- cv_get(row, "note")

  ref <- authors
  if (nzchar(year)) {
    ref <- cv_join(ref, paste0("(", year, ")."))
  } else if (nzchar(ref) && nzchar(title)) {
    ref <- paste0(ref, ",")
  }
  if (nzchar(title)) ref <- cv_join(ref, paste0(title, "."))
  if (nzchar(journal) || nzchar(volume)) {
    source <- if (nzchar(journal)) paste0("*", journal, "*") else ""
    source <- cv_join(source, volume, sep = ", ")
    ref <- cv_join(ref, paste0(source, "."))
  }
  if (nzchar(url)) {
    link <- paste0("[", cv_escape_md(cv_url_text(url)), "](", url, ").")
    if (nzchar(label)) link <- paste0("**", label, ":** ", link)
    ref <- cv_join(ref, link)
  }
  if (nzchar(note)) ref <- cv_join(ref, cv_stop(note))
  ref
}

cv_publications <- function(status) {
  d <- cv_read("publications.csv")
  keep <- d$status == status
  if (!any(keep)) {
    stop("No rows with status = '", status, "' in publications.csv.\n",
         "Values found in that file: ",
         paste(unique(d$status), collapse = ", "), call. = FALSE)
  }
  d <- d[keep, , drop = FALSE]

  out <- ""
  for (i in seq_len(nrow(d))) {
    out <- paste0(out, i, ". ", cv_reference(d[i, , drop = FALSE]), "\n\n")
  }
  knitr::asis_output(out)
}


# ===========================================================================
# conferences.csv — numbered list of talks and posters
# ===========================================================================
cv_conferences <- function() {
  d <- cv_read("conferences.csv")

  out <- ""
  for (i in seq_len(nrow(d))) {
    row <- d[i, , drop = FALSE]

    presented <- cv_join(
      if (nzchar(cv_get(row, "type"))) paste0("**", cv_get(row, "type"), "**") else "",
      cv_get(row, "verb")
    )
    where_when <- cv_join(
      cv_get(row, "event"), cv_get(row, "location"), cv_get(row, "date"),
      sep = ", "
    )

    entry <- cv_join(
      cv_stop(cv_get(row, "authors")),
      cv_stop(cv_get(row, "title")),
      cv_stop(cv_join(presented, where_when))
    )
    if (nzchar(cv_get(row, "url"))) {
      entry <- cv_join(entry, paste0(cv_link_md(cv_get(row, "url")), "."))
    }

    out <- paste0(out, i, ". ", entry, "\n\n")
  }
  knitr::asis_output(out)
}


# ===========================================================================
# bullets.csv — plain lists, with optional sub-headings
#
#   kind = "text"   -> the row becomes a normal paragraph
#   kind = anything else (or empty) -> the row becomes a bullet point
#   subsection      -> starts a new sub-heading (leave empty if not needed)
# ===========================================================================
cv_bullets <- function(section, heading = "###") {
  d <- cv_rows("bullets.csv", section)

  out     <- ""
  current <- NULL
  in_list <- FALSE

  for (i in seq_len(nrow(d))) {
    row     <- d[i, , drop = FALSE]
    sub     <- cv_get(row, "subsection")
    text    <- cv_link_md(cv_get(row, "text"))
    details <- cv_items(cv_get(row, "details"))
    is_text <- identical(cv_get(row, "kind"), "text")

    if (nzchar(sub) && !identical(sub, current)) {
      if (in_list) { out <- paste0(out, "\n"); in_list <- FALSE }
      out <- paste0(out, heading, " ", sub, "\n\n")
      current <- sub
    }

    if (is_text) {
      if (in_list) { out <- paste0(out, "\n"); in_list <- FALSE }
      out <- paste0(out, text, "\n\n")
      for (item in details) {
        out <- paste0(out, "- ", cv_link_md(item), "\n")
        in_list <- TRUE
      }
    } else {
      out <- paste0(out, "- ", text, "\n")
      for (item in details) {
        out <- paste0(out, "    - ", cv_link_md(item), "\n")
      }
      in_list <- TRUE
    }
  }

  knitr::asis_output(paste0(out, "\n"))
}
