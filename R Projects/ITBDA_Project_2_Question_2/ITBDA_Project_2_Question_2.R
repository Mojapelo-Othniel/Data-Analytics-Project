#Othniel Fetang Katlego Mojapelo EDUV4819259 ITDBA4-14 Question 2: LDA topic modelling of news articles 

library(tm)           # used for text cleaning and document-term matrix
library(topicmodels)  # LDA process
library(tidytext)     # tidy() for topic word probabilities
library(dplyr)
library(ggplot2)
library(wordcloud)

# ---------------------------------------------------------------
# 2.1  Load the files into a data frame and clean the text
# ---------------------------------------------------------------
folder <- "sa_news"     # Folder location for the txt files

files <- list.files(folder, pattern = "\\.txt$", full.names = TRUE)
files <- files[order(as.numeric(gsub("\\D", "", basename(files))))]   # news_1, news_2, ... in order

news_df <- data.frame(
  file_name = basename(files),                                        # col_1
  content   = sapply(files, function(f) paste(readLines(f, warn = FALSE), collapse = " ")),  # col_2
  stringsAsFactors = FALSE
)
rownames(news_df) <- NULL
View(news_df)

# Cleaning (denoising) steps
my_stopwords <- c(stopwords("en"),
                  "said", "also", "will", "would", "could", "can", "one", "two", "new",
                  "south", "africa", "african")      # words that appear in every article

clean <- news_df$content
clean <- tolower(clean)                              # 1. lower case
clean <- gsub("https?://\\S+", " ", clean)           # 2. remove web links
clean <- gsub("[^a-z ]", " ", clean)                 # 3. remove punctuation, numbers, symbols
clean <- removeWords(clean, my_stopwords)            # 4. remove stop-words 
clean <- gsub("\\b[a-z]{1,2}\\b", " ", clean)        # 5. remove very short words
clean <- stripWhitespace(trimws(clean))              # 6. tidy up spaces
news_df$clean <- clean

head(news_df$clean, 2)                               # display the results of the cleaned data

# ---------------------------------------------------------------
# 2.2  Document-term matrix and LDA
# ---------------------------------------------------------------
corpus <- VCorpus(VectorSource(news_df$clean))
dtm    <- DocumentTermMatrix(corpus)
dtm    <- dtm[, colSums(as.matrix(dtm) > 0) >= 2]    # keep words found in articles

k <- 3                                               # number of topics 
lda_model <- LDA(dtm, k = k, method = "Gibbs",
                 control = list(seed = 42, burnin = 500, iter = 2000))

# Top 10 words per topic with their probability P(word | topic)
top_words <- tidy(lda_model, matrix = "beta") %>%
  group_by(topic) %>%
  slice_max(beta, n = 10, with_ties = FALSE) %>%
  ungroup()
print(as.data.frame(top_words))

# Which topic does each article belong to?  P(topic | article)
doc_topics <- as.data.frame(round(posterior(lda_model)$topics, 3))
doc_topics <- cbind(file_name = news_df$file_name, doc_topics)
print(doc_topics)

# ---------------------------------------------------------------
# 2.3  Visualisations
# ---------------------------------------------------------------
# Method 1: bar charts of the top words in each topic
ggplot(top_words, aes(x = reorder_within(term, beta, topic), y = beta, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free_y", labeller = label_both) +
  scale_x_reordered() +
  coord_flip() +
  labs(title = "Top 10 words per topic", x = "Word", y = "Probability of word in topic")

# Method 2: word clouds (bigger word = higher probability)
par(mfrow = c(1, k))
for (i in 1:k) {
  t <- top_words[top_words$topic == i, ]
  wordcloud(t$term, t$beta, scale = c(3, 0.8), random.order = FALSE,
            colors = i + 1)
  title(paste("Topic", i))
}
par(mfrow = c(1, 1))