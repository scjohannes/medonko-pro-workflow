table1_data_frame <- function(x) {
  table_data <- as.data.frame(x)
  table_data <- as.data.frame(
    lapply(table_data, as.character),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  table_data[[1]] <- trimws(table_data[[1]])
  table_data
}

table1_structure <- function(table_data) {
  label_column <- names(table_data)[1]
  value_columns <- setdiff(names(table_data), label_column)
  has_empty_values <- Reduce(
    `&`,
    lapply(table_data[value_columns], function(column) trimws(column) == "")
  )
  has_label <- nzchar(trimws(table_data[[label_column]]))
  header_rows <- which(has_label & has_empty_values)
  subrows <- setdiff(seq_len(nrow(table_data)), c(1, header_rows))

  list(
    label_column = label_column,
    value_columns = value_columns,
    header_rows = header_rows,
    subrows = subrows
  )
}

table1_tinytable <- function(x, width = NULL) {
  table_data <- table1_data_frame(x)
  table_structure <- table1_structure(table_data)

  if (is.null(width)) {
    first_column_width <- if (ncol(table_data) == 2) 0.72 else 0.54
    width <- c(
      first_column_width,
      rep((1 - first_column_width) / (ncol(table_data) - 1), ncol(table_data) - 1)
    )
  }

  out <- tt(table_data, width = width)
  out <- style_tt(out, j = 1, align = "l")
  out <- style_tt(out, i = table_structure$header_rows, j = 1, bold = TRUE)
  out <- style_tt(out, i = table_structure$subrows, j = 1, indent = 1.5)
  out <- style_tt(out, j = seq(2, ncol(table_data)), align = "r")
  out <- theme_typst(out, multipage = TRUE)
  out
}

table1_flextable <- function(x, caption = NULL) {
  if (!requireNamespace("table1", quietly = TRUE)) {
    stop("Package 'table1' is required.", call. = FALSE)
  }
  if (!requireNamespace("flextable", quietly = TRUE)) {
    stop("Package 'flextable' is required.", call. = FALSE)
  }

  x_word <- x
  table_obj <- attr(x_word, "obj", exact = TRUE)
  if (is.null(caption)) {
    table_obj$caption <- ""
  } else {
    table_obj$caption <- caption
  }
  attr(x_word, "obj") <- table_obj

  out <- table1::t1flex(x_word)
  out <- flextable::fontsize(out, size = 9, part = "all")
  out <- flextable::padding(out, padding.top = 2, padding.bottom = 2, part = "all")
  out <- flextable::padding(out, padding.left = 4, padding.right = 4, part = "all")
  out <- flextable::align(out, j = 1, align = "left", part = "all")
  out <- flextable::align(
    out,
    j = seq(2, ncol(table1_data_frame(x_word))),
    align = "right",
    part = "all"
  )
  out <- flextable::width(out, j = 1, width = 3.6)
  out <- flextable::width(
    out,
    j = seq(2, ncol(table1_data_frame(x_word))),
    width = 1.35
  )
  out <- flextable::set_table_properties(out, align = "left", layout = "fixed")
  out
}

typst_escape_text <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub("([\\[\\]#$])", "\\\\\\1", x, perl = TRUE)
  x
}

typst_table_cell <- function(
  value,
  fill = "none",
  align = "left",
  bold = FALSE,
  indent = FALSE,
  colspan = 1
) {
  value <- typst_escape_text(value)
  if (indent && nzchar(value)) {
    value <- paste0("#h(0.9em)", value)
  }
  if (bold && nzchar(value)) {
    value <- paste0("#strong[", value, "]")
  }
  cell_arguments <- c(
    paste0("fill: ", fill),
    paste0("align: ", align)
  )
  if (colspan > 1) {
    cell_arguments <- c(cell_arguments, paste0("colspan: ", colspan))
  }
  paste0(
    "table.cell(", paste(cell_arguments, collapse = ", "), ")[",
    "#set par(justify: false)\n",
    value,
    "]"
  )
}

table1_typst <- function(
  x,
  caption = NULL,
  label = NULL,
  width = NULL,
  text_size = "8.2pt",
  header_fill = 'rgb("#E8EEF7")',
  group_fill = 'rgb("#F7F8FA")',
  text_color = 'rgb("#1F2933")',
  rule_color = 'rgb("#C7CDD7")',
  indent_subrows = TRUE,
  header_align = NULL,
  span_group_rows = FALSE,
  return_output = FALSE
) {
  table_data <- table1_data_frame(x)
  table_structure <- table1_structure(table_data)
  n_rows <- nrow(table_data)
  n_cols <- ncol(table_data)

  if (is.null(width)) {
    first_column_width <- if (n_cols == 2) 0.68 else 0.48
    width <- c(
      first_column_width,
      rep((1 - first_column_width) / (n_cols - 1), n_cols - 1)
    )
  }

  column_widths <- paste0(round(width * 100, 2), "%")
  column_widths <- paste(column_widths, collapse = ", ")

  if (is.null(header_align)) {
    header_align <- c("left", rep("right", n_cols - 1))
  }
  if (length(header_align) == 1) {
    header_align <- rep(header_align, n_cols)
  }
  if (length(header_align) != n_cols) {
    stop("'header_align' must have length 1 or match the number of columns.", call. = FALSE)
  }

  header_cells <- vapply(seq_len(n_cols), function(column_index) {
    typst_table_cell(
      names(table_data)[column_index],
      fill = header_fill,
      align = header_align[column_index],
      bold = TRUE
    )
  }, character(1))

  body_cells <- character()
  for (row_index in seq_len(n_rows)) {
    is_group <- row_index %in% table_structure$header_rows
    is_subrow <- row_index %in% table_structure$subrows
    fill <- if (is_group) group_fill else "none"
    if (is_group && span_group_rows) {
      body_cells <- c(
        body_cells,
        typst_table_cell(
          table_data[row_index, 1],
          fill = fill,
          align = "left",
          bold = TRUE,
          colspan = n_cols
        )
      )
      next
    }
    for (column_index in seq_len(n_cols)) {
      align <- if (column_index == 1) "left" else "right"
      body_cells <- c(
        body_cells,
        typst_table_cell(
          table_data[row_index, column_index],
          fill = fill,
          align = align,
          bold = is_group && column_index == 1,
          indent = indent_subrows && is_subrow && column_index == 1
        )
      )
    }
  }

  table_output <- if (is.null(caption)) {
    "#table1-table"
  } else {
    caption <- typst_escape_text(caption)
    figure_lines <- c(
      "#figure(",
      "  table1-table,",
      "  caption: figure.caption(",
      "    position: top,",
      paste0("    [", caption, "]"),
      "  ),",
      "  kind: table,",
      ")"
    )
    if (!is.null(label)) {
      figure_lines[length(figure_lines)] <- paste0(figure_lines[length(figure_lines)], " <", label, ">")
    }
    paste(figure_lines, collapse = "\n")
  }

  lines <- c(
    "```{=typst}",
    "#let table1-rule = rgb(\"#C7CDD7\")",
    "#let table1-strong-rule = rgb(\"#1F2933\")",
    "#let table1-table = {",
    paste0("  set text(size: ", text_size, ", fill: ", text_color, ")"),
    "  table(",
    paste0("    columns: (", column_widths, "),"),
    "    inset: (x: 4pt, y: 2.8pt),",
    "    stroke: (x, y) => {",
    "      if y == 0 {",
    "        (top: 0.95pt + table1-strong-rule, bottom: 0.65pt + table1-strong-rule)",
    paste0("      } else if y == ", n_rows, " {"),
    "        (bottom: 0.95pt + table1-strong-rule)",
    "      } else {",
    "        (bottom: 0.35pt + table1-rule)",
    "      }",
    "    },",
    "    table.header(",
    paste0("      ", paste(header_cells, collapse = ",\n      "), ","),
    "    ),",
    paste0("    ", paste(body_cells, collapse = ",\n    "), ","),
    "  )",
    "}",
    table_output,
    "```"
  )

  output <- paste(lines, collapse = "\n")
  if (return_output) {
    return(output)
  }

  cat(output)
  invisible(output)
}
