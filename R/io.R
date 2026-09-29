ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

save_plot_dual <- function(
  plot,
  path_stem,
  width = 8,
  height = 5,
  dpi = 300,
  bg = "white"
) {
  ensure_dir(dirname(path_stem))
  ggplot2::ggsave(
    filename = paste0(path_stem, ".png"),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = bg
  )
  ggplot2::ggsave(
    filename = paste0(path_stem, ".svg"),
    plot = plot,
    width = width,
    height = height,
    bg = bg,
    device = grDevices::svg
  )
  invisible(path_stem)
}

write_lines_file <- function(lines, path) {
  ensure_dir(dirname(path))
  writeLines(lines, con = path)
  invisible(path)
}

save_base_plot_dual <- function(
  plot_fun,
  path_stem,
  width = 8,
  height = 5,
  dpi = 300,
  pointsize = 12,
  bg = "white"
) {
  ensure_dir(dirname(path_stem))

  grDevices::png(
    filename = paste0(path_stem, ".png"),
    width = width,
    height = height,
    units = "in",
    res = dpi,
    pointsize = pointsize,
    bg = bg
  )
  plot_fun()
  grDevices::dev.off()

  grDevices::svg(
    filename = paste0(path_stem, ".svg"),
    width = width,
    height = height,
    pointsize = pointsize,
    bg = bg
  )
  plot_fun()
  grDevices::dev.off()

  invisible(path_stem)
}
