#!/usr/bin/env Rscript
KEYWORD    <- Sys.getenv("SEARCH_KEYWORD", "africa")
WHOLE_WORD <- Sys.getenv("WHOLE_WORD", "false") == "true"

path <- Sys.getenv("mapreduce_map_input_file", Sys.getenv("map_input_file", "unknown"))
doc  <- basename(path)
pattern <- if (WHOLE_WORD) paste0("\\b", KEYWORD, "\\b") else KEYWORD

con <- file("stdin", open = "r", encoding = "UTF-8")
row <- 0L
while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
  row <- row + 1L
  hits <- gregexpr(pattern, line, ignore.case = TRUE, perl = TRUE)[[1]]
  if (hits[1] != -1) {
    for (col in as.integer(hits)) cat(doc, "\t", row, ":", col, "\n", sep = "")
  }
}
close(con)
