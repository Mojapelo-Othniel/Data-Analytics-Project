# Othniel Fetang Katlego Mojapelo EDUV4819259 ITDBA4-14 Question 3: Scrape a web page, clean the text, and summarise it

library(rvest)      # scraping
library(dplyr)
library(stringr)    # text cleaning
library(tidytext)   # split text into sentences / words
library(ggplot2)
library(wordcloud)

# ---------------------------------------------------------------
# 3.1  Extract text from a website
# ---------------------------------------------------------------
url  <- "https://en.wikipedia.org/wiki/Climate_change_in_South_Africa"
page <- read_html(url)

paragraphs <- page %>%
  html_elements("p") %>%      # all paragraphs <p>
  html_text2()                # keep the text, drop the HTML tags
paragraphs <- paragraphs[nchar(paragraphs) > 0]

# R data structure: a data frame with one row per paragraph
web_df <- data.frame(paragraph_id = 1:length(paragraphs), text = paragraphs)
head(web_df)

# ---------------------------------------------------------------
# 3.2  Pre-processing
# ---------------------------------------------------------------
# Remove Wikipedia citation marks like [12] and extra spaces
web_df$text <- str_remove_all(web_df$text, "\\[[^\\]]*\\]")
web_df$text <- str_squish(web_df$text)

# Split into sentences (needed for summarising)
sentences <- web_df %>%
  unnest_tokens(sentence, text, token = "sentences", to_lower = FALSE) %>%
  filter(str_count(sentence, "\\w+") >= 6) %>%     # drop very short sentences
  mutate(sentence_id = row_number())

# Split into words, then clean them
my_stopwords <- c("south", "africa", "african", "climate", "change")  # in almost every sentence
words <- sentences %>%
  unnest_tokens(word, sentence) %>%                # lower case, no punctuation
  filter(str_detect(word, "^[a-z]+$")) %>%         # remove numbers and symbols
  filter(nchar(word) > 2) %>%                      # remove very short words
  anti_join(stop_words, by = "word") %>%           # remove stop-words (the, and, of ...)
  filter(!word %in% my_stopwords)

cat("Sentences:", nrow(sentences), "\n")
cat("Words left after cleaning:", nrow(words), "\n")

# ---------------------------------------------------------------
# 3.3  Summarisation (two methods, 5 sentences each)
# ---------------------------------------------------------------
# Method 1: WORD FREQUENCY
# Sentences containing many frequent words are important.
word_freq <- words %>% count(word, sort = TRUE)

score1 <- words %>%
  left_join(word_freq, by = "word") %>%
  group_by(sentence_id) %>%
  summarise(score = sum(n) / n(), n_words = n()) %>%    # average frequency of its words
  filter(n_words >= 5)

summary1 <- score1 %>%
  slice_max(score, n = 5, with_ties = FALSE) %>%
  left_join(sentences, by = "sentence_id") %>%
  arrange(sentence_id)

cat("\n--- Summary 1: word frequency ---\n")
for (s in summary1$sentence) cat("-", s, "\n")

# Method 2: TF-IDF
# Sentences containing words that are special to that sentence (not used everywhere) are important.
score2 <- words %>%
  count(sentence_id, word) %>%
  bind_tf_idf(word, sentence_id, n) %>%
  group_by(sentence_id) %>%
  summarise(score = sum(tf_idf), n_words = n()) %>%
  filter(n_words >= 5)

summary2 <- score2 %>%
  slice_max(score, n = 5, with_ties = FALSE) %>%
  left_join(sentences, by = "sentence_id") %>%
  arrange(sentence_id)

cat("\n--- Summary 2: TF-IDF ---\n")
for (s in summary2$sentence) cat("-", s, "\n")

cat("\nSentences chosen by both methods:",
    length(intersect(summary1$sentence_id, summary2$sentence_id)), "\n")

# ---------------------------------------------------------------
# Visualisations
# ---------------------------------------------------------------
# Graph 1: bar chart of the 15 most frequent words
top15 <- head(word_freq, 15)
ggplot(top15, aes(x = reorder(word, n), y = n)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "15 most frequent words in the article",
       subtitle = "Wikipedia: Climate change in South Africa (after cleaning)",
       x = "Word", y = "Number of times used")

# Graph 2: word cloud (bigger word = used more often)
set.seed(42)
wordcloud(word_freq$word, word_freq$n, max.words = 50, random.order = FALSE,
          colors = brewer.pal(8, "Dark2"))
title("Word cloud of the cleaned article")