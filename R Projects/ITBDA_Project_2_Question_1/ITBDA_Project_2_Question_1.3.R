flush_doc <- function(doc, positions) {
  if (is.null(doc)) return(invisible())
  rc <- do.call(rbind, strsplit(positions, ":", fixed = TRUE))
  r <- as.integer(rc[, 1]); c <- as.integer(rc[, 2])
  o <- order(r, c)
  cat(doc, "\t", length(o), "\t",
      paste0("(", r[o], ",", c[o], ")", collapse = " "), "\n", sep = "")
}

con <- file("stdin", open = "r")
cur <- NULL; buf <- character(0)
while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
  parts <- strsplit(line, "\t", fixed = TRUE)[[1]]
  if (length(parts) < 2) next
  if (!identical(parts[1], cur)) { flush_doc(cur, buf); cur <- parts[1]; buf <- character(0) }
  buf <- c(buf, parts[2])
}
flush_doc(cur, buf)
close(con)