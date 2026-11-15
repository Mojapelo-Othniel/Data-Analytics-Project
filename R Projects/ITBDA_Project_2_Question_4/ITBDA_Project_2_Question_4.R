#Othniel Fetang Katlego Mojapelo EDUV4819259 ITDBA4-14 Question 4: ETL - scrape books -> clean -> export CSV (then load into PostgreSQL, see books_analysis.sql)

library(rvest)
library(dplyr)
library(stringr)

# ---------------------------------------------------------------
# USE CASE: A small online bookshop wants to know how book prices,
# ratings and stock levels differ across categories.
# Website: books.toscrape.com - a practice site built for web-scraping
# (legal to scrape). We pause between requests to be polite.
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 4.1  EXTRACT: scrape 40 books (2 listing pages x 20 books)
# ---------------------------------------------------------------
base <- "https://books.toscrape.com/catalogue/"

# Step 1: collect the link of every book from the first 2 listing pages
links <- c()
for (p in 1:2) {
  listing <- read_html(paste0(base, "page-", p, ".html"), encoding = "UTF-8")
  hrefs   <- listing %>% html_elements("article.product_pod h3 a") %>% html_attr("href")
  links   <- c(links, paste0(base, hrefs))
  Sys.sleep(1)
}
length(links)     # should be 40

# Step 2: a function that scrapes ONE book page
get_book <- function(link) {
  page <- read_html(link, encoding = "UTF-8")
  data.frame(
    title           = page %>% html_element("h1") %>% html_text2(),
    category        = page %>% html_element("ul.breadcrumb li:nth-child(3) a") %>% html_text2(),
    price_raw       = page %>% html_element("p.price_color") %>% html_text2(),
    rating_raw      = page %>% html_element("p.star-rating") %>% html_attr("class"),
    stock_raw       = page %>% html_element("p.availability") %>% html_text2(),
    description_raw = page %>% html_element("#product_description + p") %>% html_text2(),
    stringsAsFactors = FALSE
  )
}

# Step 3: loop over all the links and stack the results into one data frame
books <- list()
for (i in 1:length(links)) {
  books[[i]] <- get_book(links[i])
  Sys.sleep(0.5)                     # wait half a second between requests
}
raw_df <- bind_rows(books)

write.csv(raw_df, "books_raw.csv", row.names = FALSE)   # keep the raw data as evidence

# Look at the RAW data: messy text, currency symbols, missing values
View(raw_df)
str(raw_df)
colSums(is.na(raw_df))               # missing values per column

# ---------------------------------------------------------------
# 4.2  TRANSFORM: clean the data with regular expressions
# ---------------------------------------------------------------
clean_df <- raw_df

# Title: remove extra spaces
clean_df$title <- str_squish(clean_df$title)

# Price: "£51.77" (or "Â£51.77" if the encoding is wrong) -> number 51.77
clean_df$price <- as.numeric(str_extract(clean_df$price_raw, "[0-9]+\\.[0-9]+"))

# Rating: the page gives a WORD ("star-rating Three") -> number 3
rating_word    <- str_extract(clean_df$rating_raw, "One|Two|Three|Four|Five")
clean_df$rating <- match(rating_word, c("One", "Two", "Three", "Four", "Five"))

# Stock: "In stock (22 available)" -> 22
clean_df$stock <- as.numeric(str_extract(clean_df$stock_raw, "[0-9]+"))

# Description: remove "...more", strange characters and extra spaces
desc <- clean_df$description_raw
desc <- str_remove(desc, "\\.\\.\\.more$")
desc <- str_replace_all(desc, "[^\\x20-\\x7E]", " ")     # keep only normal keyboard characters
desc <- str_squish(desc)

# New numeric column (inferred): number of words in the description
clean_df$desc_words <- ifelse(is.na(desc), 0, str_count(desc, "\\w+"))

# ---- Missing values ----
cat("Missing values BEFORE imputation:\n")
print(colSums(is.na(clean_df[, c("price", "rating", "stock")])))
cat("Books with no description:", sum(is.na(desc)), "\n")

desc[is.na(desc)] <- "No description available"          # text: fill with a label
clean_df$description <- desc

fill_median <- function(x) { x[is.na(x)] <- median(x, na.rm = TRUE); x }   # numbers: fill with median
clean_df$price  <- fill_median(clean_df$price)
clean_df$rating <- fill_median(clean_df$rating)
clean_df$stock  <- fill_median(clean_df$stock)

# ---- Duplicates ----
clean_df <- distinct(clean_df, title, .keep_all = TRUE)

# ---- Final tidy table ----
clean_df$book_id <- 1:nrow(clean_df)
final_df <- clean_df[, c("book_id", "title", "category", "price", "rating",
                         "stock", "description", "desc_words")]

cat("Missing values AFTER cleaning:", sum(is.na(final_df)), "\n")
summary(final_df)
head(final_df)

# ---------------------------------------------------------------
# LOAD (step 1): export the clean data as CSV
# ---------------------------------------------------------------
write.csv(final_df, file = "books_clean.csv", row.names = FALSE, fileEncoding = "UTF-8")