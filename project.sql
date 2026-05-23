
-- Questions:
-- 1.	What is the total revenue generated from all rentals in the database?
select sum(amount) as total_revenue from payment;
select sum(p.amount) as total_revenue from rental r join payment p on r.rental_id = p.rental_id;
-- 2.	How many rentals were made in each month_name? 
select year(rental_date) as years,monthname(rental_date) as month_name,count(rental_date) as total from rental group by monthname(rental_date) ,year(rental_date);
-- 3.	What is the rental rate of the film with the longest title in the database? 
select title,rental_rate,length(title) as length_size from film order by length_size desc limit 1;
-- 4.	What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")? 
select AVG(f.rental_rate) AS avg_rental_rate from rental r join inventory i on r.inventory_id = i.inventory_id join film f on f.film_id = i.film_id where r.rental_date BETWEEN 
DATE_SUB('2005-05-05 22:04:30', INTERVAL 30 DAY)
AND '2005-05-05 22:04:30';
-- select avg(f.rental_rate) as average from film f join inventory i on f.film_id =  rental_date between date_sub("2005-05-05 22:04:30",interval 30 day) and "2005-05-05 22:04:30";
 -- 5.	What is the most popular category of films in terms of the number of rentals?
 SELECT c.name AS category_name,
       COUNT(r.rental_id) AS total_rentals
FROM category c
JOIN film_category fc
ON c.category_id = fc.category_id
JOIN film f
ON fc.film_id = f.film_id
JOIN inventory i
ON f.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY total_rentals DESC
LIMIT 1;
-- 6.	Find the longest movie duration from the list of films that have not been rented by any customer. 
SELECT 
    f.title,    
    f.length AS movie_duration
FROM film f
LEFT JOIN inventory i
ON f.film_id = i.film_id
LEFT JOIN rental r
ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
ORDER BY f.length DESC
LIMIT 1;
-- 7.	What is the average rental rate for films, broken down by category? 
SELECT 
    c.name AS category_name,    
    ROUND(AVG(f.rental_rate), 2) AS avg_rental_rate
FROM category c
JOIN film_category fc
ON c.category_id = fc.category_id
JOIN film f
ON fc.film_id = f.film_id
GROUP BY c.name
ORDER BY avg_rental_rate DESC;
-- 8.	What is the total revenue generated from rentals for each actor in the database? 
SELECT a.actor_id,
       CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
       SUM(p.amount) AS total_revenue
FROM actor a
JOIN film_actor fa
ON a.actor_id = fa.actor_id
JOIN inventory i
ON fa.film_id = i.film_id
JOIN rental r
ON i.inventory_id = r.inventory_id
JOIN payment p
ON r.rental_id = p.rental_id
GROUP BY a.actor_id, actor_name
ORDER BY total_revenue DESC;
-- 9.	Show all the actresses who worked in a film having a "Wrestler" in the description. 
SELECT DISTINCT 
       a.actor_id,
       CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
       f.title,
       f.description
FROM actor a
JOIN film_actor fa
ON a.actor_id = fa.actor_id
JOIN film f
ON fa.film_id = f.film_id
WHERE f.description LIKE '%Wrestler%';
-- 10.	Which customers have rented the same film more than once? 
SELECT 
    c.customer_id,    
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,    
    f.title,    
    COUNT(*) AS rental_count
FROM customer c
JOIN rental r
ON c.customer_id = r.customer_id
JOIN inventory i
ON r.inventory_id = i.inventory_id
JOIN film f
ON i.film_id = f.film_id
GROUP BY 
    c.customer_id,
    customer_name,
    f.title
HAVING COUNT(*) > 1
ORDER BY rental_count DESC;
-- 11.	How many films in the comedy category have a rental rate higher than the average rental rate?
SELECT 
    COUNT(*) AS total_films
FROM film f
JOIN film_category fc
ON f.film_id = fc.film_id
JOIN category c
ON fc.category_id = c.category_id
WHERE c.name = 'Comedy'
AND f.rental_rate > (
    SELECT AVG(rental_rate)
    FROM film
);
-- 12.	Which films have been rented the most by customers living in each city? 
WITH city_film_rentals AS (
    SELECT 
        ci.city,
        f.title,
        COUNT(r.rental_id) AS total_rentals,        
        RANK() OVER (
            PARTITION BY ci.city
            ORDER BY COUNT(r.rental_id) DESC
        ) AS rnk
    FROM city ci
    JOIN address a
    ON ci.city_id = a.city_id
    JOIN customer c
    ON a.address_id = c.address_id
    JOIN rental r
    ON c.customer_id = r.customer_id
    JOIN inventory i
    ON r.inventory_id = i.inventory_id
    JOIN film f
    ON i.film_id = f.film_id
    GROUP BY ci.city, f.title
)
SELECT city,
       title,
       total_rentals
FROM city_film_rentals
WHERE rnk = 1;
-- 13.	What is the total amount spent by customers whose rental payments exceed $200? 
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       SUM(p.amount) AS total_amount_spent
FROM customer c
JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY c.customer_id, customer_name
HAVING SUM(p.amount) > 200;
-- 14.	Create a View for the total revenue generated by each staff member, broken down by store city with the country name.
CREATE VIEW staff_store_revenue_view AS
SELECT 
    s.staff_id,    
    CONCAT(s.first_name, ' ', s.last_name) AS staff_name,    
    ci.city AS store_city,    
    co.country AS country_name,    
    SUM(p.amount) AS total_revenue
FROM staff s
JOIN payment p
ON s.staff_id = p.staff_id
JOIN store st
ON s.store_id = st.store_id
JOIN address a
ON st.address_id = a.address_id
JOIN city ci
ON a.city_id = ci.city_id
JOIN country co
ON ci.country_id = co.country_id
GROUP BY 
    s.staff_id,
    staff_name,
    ci.city,
    co.country; 
-- 15.	Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,  no_of_rental_days, the amount paid by the customer along with the percentage of customer spending. 
CREATE VIEW customer_rental_view AS
SELECT 
    DAYNAME(r.rental_date) AS visiting_day,    
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,    
    f.title AS film_title,    
    DATEDIFF(r.return_date, r.rental_date) AS no_of_rental_days,    
    p.amount AS amount_paid,    
    ROUND(
        (p.amount / SUM(p.amount) OVER(PARTITION BY c.customer_id)) * 100,
        2
    ) AS percentage_of_customer_spending
FROM customer c
JOIN rental r
ON c.customer_id = r.customer_id
JOIN payment p
ON r.rental_id = p.rental_id
JOIN inventory i
ON r.inventory_id = i.inventory_id
JOIN film f
ON i.film_id = f.film_id;