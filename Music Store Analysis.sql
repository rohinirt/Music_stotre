
-- Question Set 1 - Easy

-- 1. Who is the senior most employee based on job title?
SELECT first_name, last_name,title
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT billing_country,count(*) AS Invoices
FROM invoice
GROUP BY billing_country
ORDER BY Invoices DESC; 

-- 3. What are the top 3 values of total invoice?
SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4.Which city has the best customers? We would like to throw a promotional 
-- Music Festival in the city we made the most money. 
-- Write a query that returns one city that has the highest sum of 
-- invoice totals.
-- Return both the city name & sum of all invoice totals.
SELECT billing_city,ROUND(sum(total),0) as totalinvoice 
FROM invoice
GROUP BY billing_city
ORDER BY total_cost DESC
LIMIT 1;

-- 5. Who is the best customer? The customer who has spent the most money 
-- will be declared the best customer.
-- Write a query that returns the person who has spent the most money.
SELECT customer.customer_id, first_name, last_name, ROUND(SUM(total),0) AS total_spending
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id,first_name,last_name
ORDER BY total_spending DESC
LIMIT 1;

-- 6. Which employee has the highest total sales based on their invoices?
SELECT first_name,last_name,ROUND(SUM(total),2) AS total_sales
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY first_name,last_name
ORDER BY  total_sales DESC
LIMIT 1;

-- 7. What is the average invoice total for each country?
SELECT billing_country,ROUND(AVG(total),2) AS invoic_total
FROM invoice
GROUP BY billing_country
ORDER BY billing_country;

-- Question Set 2 - Moderate --

/* 1. Write a query to return the email, first name, last name, & 
Genre of all Rock Music listeners.Return your list ordered alphabetically 
by email starting with A.*/
SELECT c.customer_id, first_name, last_name, email,genre_name
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line l ON i.invoice_id = l.invoice_id
JOIN track t ON l.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE genre_name LIKE "rock"
GROUP BY c.customer_id, first_name, last_name, email,genre_name
ORDER BY email ASC;

-- 2.Let's invite the artists who have written the most rock music in our 
-- dataset. Write a query that returns the Artist name and total track 
-- count of the top 10 rock bands.
SELECT artist.artist_id,artist_name,COUNT(DISTINCT track_id) as total_tracks
FROM artist 
JOIN album  ON artist.artist_id = album.artist_id
JOIN track ON album.album_id  = track.album_id
JOIN genre ON track.genre_id = genre.genre_id
WHERE genre_name like "rock"
GROUP BY artist.artist_id,artist_name
ORDER BY total_tracks DESC
LIMIT 10;



-- 3.Return all the track names that have a song length longer than the 
-- average song length. Return the Name and Milliseconds for each track.
-- Order by the song length with the longest songs listed first.
SELECT track_name,milliseconds AS length
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY length DESC;

-- 4. List all the artists who have tracks longer than the average track 
-- length in the dataset,along with the total count of such tracks for each 
-- artist.
WITH Longer_track AS
(SELECT artist_name,track_name,milliseconds,COUNT(track_id) AS length
FROM artist ar
JOIN album a ON ar.artist_id = a.artist_id
JOIN track t ON a.album_id = t.album_id
WHERE milliseconds >(SELECT AVG(milliseconds) FROM track)
GROUP BY artist_name,track_name,milliseconds)
SELECT artist_name,count(track_name) AS total_tracks
FROM Longer_track
GROUP BY artist_name
ORDER BY total_tracks DESC;

SELECT AVG(milliseconds) FROM track;

-- Question Set 3 - Advanced --

-- 1. Find how much amount spent by each customer on artists?
-- Write a query to return customer name, artist name and total spent.
 WITH best_selling_artist AS (
	SELECT artist.artist_id AS artist_id, artist.artist_name AS artist_name, SUM(invoice_line.unit_price*invoice_line.quantity) AS total_sales
	FROM invoice_line
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN album ON album.album_id = track.album_id
	JOIN artist ON artist.artist_id = album.artist_id
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, ROUND(SUM(il.unit_price*il.quantity),2) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3,4
ORDER BY 5 DESC;

-- 2. We want to find out the most popular music Genre for each country.
-- We determine the most popular genre as the genre with the highest amount of purchases.
-- Write a query that returns each country along with the top Genre.
-- For countries where the maximum number of purchases is shared return all Genres.
WITH Most_Popular_Genre AS (
	SELECT g.genre_id,c.country,g.genre_name,SUM(il.quantity) AS Purchases,
		ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY SUM(il.quantity) DESC) AS  Row_No
    FROM genre g
    JOIN track t ON g.genre_id = t.genre_id
    JOIN invoice_line il ON t.track_id = il.track_id
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
	GROUP BY 1,2,3
	ORDER BY 3 ASC, 4 DESC
)
SELECT genre_id, country, genre_name, Purchases
FROM Most_Popular_Genre
WHERE Row_No = 1
ORDER BY country;

/*3. Write a query that determines the customer that has spent the most on music for each country.
   Write a query that returns the country along with the top customer and how much they spent.
   For countries where the top amount spent is shared, provide all customers who spent this amount.*/
WITH Customer_by_Country AS (
SELECT c.customer_id,c.first_name,c.last_name,c.country,ROUND(SUM(total),2) AS total_spending
,ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY SUM(total)) AS Row_No
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY 1 ASC, 5 DESC
)
SELECT * FROM Customer_by_Country
WHERE Row_no <=1;

-- 4. Identify the top-selling album in terms of total revenue generated 
-- across all invoices. Return the album name, artist, and total revenue.
SELECT 
    a.album_id,
    a.title AS album_name,
    ar.artist_name AS artist,
    ROUND(SUM(il.unit_price * il.quantity),2) AS total_revenue
FROM 
    album a
JOIN 
    track t ON a.album_id = t.album_id
JOIN 
    invoice_line il ON t.track_id = il.track_id
JOIN 
    artist ar ON a.artist_id = ar.artist_id
GROUP BY 
    a.album_id, a.title, ar.artist_name
ORDER BY 
    total_revenue DESC
LIMIT 1;





