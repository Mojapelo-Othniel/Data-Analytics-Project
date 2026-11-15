DROP TABLE IF EXISTS books;
CREATE TABLE books (
    book_id     INTEGER PRIMARY KEY,
    title       TEXT NOT NULL,
    category    TEXT,
    price       NUMERIC(6,2),
    rating      INTEGER CHECK (rating BETWEEN 1 AND 5),
    stock       INTEGER,
    description TEXT,
    desc_words  INTEGER
);


copy books FROM 'books_clean.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')



SELECT COUNT(*) AS rows_loaded FROM books;
SELECT * FROM books LIMIT 5;

-- ANALYSIS 1: Do higher-rated books cost more?
SELECT rating,
       COUNT(*)              AS number_of_books,
       ROUND(AVG(price), 2)  AS average_price,
       MIN(price)            AS cheapest,
       MAX(price)            AS most_expensive
FROM books
GROUP BY rating
ORDER BY rating;

-- ANALYSIS 2: Which categories are the most expensive, and how much stock do they hold?
SELECT category,
       COUNT(*)              AS number_of_books,
       ROUND(AVG(price), 2)  AS average_price,
       SUM(stock)            AS total_stock,
       ROUND(AVG(desc_words), 1) AS avg_description_words
FROM books
GROUP BY category
ORDER BY average_price DESC;