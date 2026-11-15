# Big Data Text Analytics and ETL Project

## Project Overview
This project develops a prototype for processing and analysing text data. It uses MapReduce, natural language processing and machine learning techniques to search documents, find topics, summarise web content and build a structured database from scraped data.

## Project Objectives
- Search a news corpus for a keyword using Hadoop MapReduce and return its row and column positions.
- Load and preprocess news articles into a data frame.
- Identify topics in news articles using Latent Dirichlet Allocation (LDA).
- Scrape web content and summarise it using two text summarisation techniques.
- Apply an ETL workflow: scrape, clean with regular expressions, and load into PostgreSQL.
- Visualise results using bar charts and word clouds.

## Technologies Used
- R
- Hadoop Streaming (MapReduce)
- tm, tidytext and topicmodels
- rvest, dplyr and stringr
- ggplot2 and wordcloud
- PostgreSQL and pgAdmin
- GitHub


## Project Questions
- **Question 1:** MapReduce keyword search for "africa" with row and column locations.
- **Question 2:** Data frame creation, text preprocessing and LDA topic modelling.
- **Question 3:** Web scraping, text preprocessing and text summarisation.
- **Question 4:** ETL workflow with PostgreSQL analysis, and this GitHub repository.

## How to Run
1. Clone or download this repository.
2. Install the R packages listed at the top of each script.
3. Change the file path in each script to where the data is on your computer.
4. Run the scripts in order, from Question 1 to Question 4.
5. For Question 4, run `etl_books.R` first, then load `books_clean.csv` using `books_analysis.sql`.

## Author
Othniel Fetang Katlego Mojapelo
