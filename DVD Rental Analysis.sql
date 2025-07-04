select * from actor;
select * from film;
select * from customer;
select * from store;
select * from category;
select * from Rental;
select * from address;


/*
1. What is the total revenue generated from all rentals in the database?
2. How many rentals were made in each month_name?
3. What is the rental rate of the film with the longest title in the database?
4. What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?
5. What is the most popular category of films in terms of the number of rentals?
6. Find the longest movie duration from the list of films that have not been rented by any customer.
7. What is the average rental rate for films, broken down by category?
8. What is the total revenue generated from rentals for each actor in the database?
9. Show all the actresses who worked in a film having a "Wrestler" in the description.
10. Which customers have rented the same film more than once?
11. How many films in the comedy category have a rental rate higher than the average rental rate?
12. Which films have been rented the most by customers living in each city?
13. What is the total amount spent by customers whose rental payments exceed $200?
14. Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema]
15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name.
16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film, no of rental days, the amount paid by the customer along with the percentage of customer spending.
17. Display the customers who paid 50% of their total rental costs within one day.
*/

select * from actor;
select * from film;
select * from customer;
select * from store;
select * from category;
select * from Rental;
select * from address;


-- 1. What is the total revenue generated from all rentals in the database?
select sum(amount) as total from payment;

-- 2.How many rentals were made in each month_name?
select monthname(rental_date) as months,count(*) as rental_count from rental
group by monthname(rental_date),month(rental_date)
order by monthname(rental_date) desc;

-- 3. What is the rental rate of the film with the longest title in the database?
select rental_rate
from film
order by length(title) desc
limit 1;

-- 4.What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30")?
SELECT AVG(f.rental_rate)
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_date BETWEEN TIMESTAMP('2005-05-05 22:04:30') - INTERVAL 30 DAY
                         AND TIMESTAMP('2005-05-05 22:04:30');
                         
                         
--  5.What is the most popular category of films in terms of the number of rentals?
SELECT c.name, COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY rental_count DESC
LIMIT 1;


-- 6.Find the longest movie duration from the list of films that have not been rented by any customer.
SELECT f.title, f.length
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
ORDER BY f.length DESC
LIMIT 1;

-- 7. What is the average rental rate for films, broken down by category?
SELECT c.name, AVG(f.rental_rate) AS avg_rate
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name;


-- 8. What is the total revenue generated from rentals for each actor in the database?
SELECT a.first_name, a.last_name, SUM(p.amount) AS total_revenue
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY a.actor_id;

-- 9.Show all the actresses who worked in a film having a "Wrestler" in the description.
SELECT DISTINCT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE f.description LIKE '%Wrestler%'
  AND a.first_name NOT LIKE '%Mr%';  -- Modify condition as needed


-- 10.Which customers have rented the same film more than once?
SELECT customer_id, inventory_id, COUNT(*) AS rental_count
FROM rental
GROUP BY customer_id, inventory_id
HAVING rental_count > 1;


-- 11. How many films in the comedy category have a rental rate higher than the average rental rate?
SELECT f.title
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE c.name = 'Comedy' AND f.rental_rate > (
    SELECT AVG(rental_rate) FROM film
);

-- 12.Which films have been rented the most by customers living in each city?
SELECT ci.city, f.title, COUNT(*) AS rental_count
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN customer cu ON r.customer_id = cu.customer_id
JOIN address a ON cu.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
GROUP BY ci.city, f.title
HAVING rental_count = (
    SELECT MAX(cnt) FROM (
        SELECT COUNT(*) AS cnt
        FROM rental r2
        JOIN inventory i2 ON r2.inventory_id = i2.inventory_id
        JOIN film f2 ON i2.film_id = f2.film_id
        JOIN customer cu2 ON r2.customer_id = cu2.customer_id
        JOIN address a2 ON cu2.address_id = a2.address_id
        JOIN city ci2 ON a2.city_id = ci2.city_id
        WHERE ci2.city = ci.city
        GROUP BY f2.title
    ) AS sub
);


-- 13.What is the total amount spent by customers whose rental payments exceed $200?
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
GROUP BY customer_id
HAVING total_spent > 200;


-- 14.Display the fields which are having foreign key constraints related to the "rental" table. [Hint: using Information_schema]
SELECT table_name, column_name, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE referenced_table_name = 'rental';


-- 15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name.
CREATE VIEW staff_revenue_per_location AS
SELECT s.staff_id, s.first_name, s.last_name, c.city, co.country, SUM(p.amount) AS revenue
FROM staff s
JOIN store st ON s.store_id = st.store_id
JOIN address a ON st.address_id = a.address_id
JOIN city c ON a.city_id = c.city_id
JOIN country co ON c.country_id = co.country_id
JOIN payment p ON s.staff_id = p.staff_id
GROUP BY s.staff_id, c.city, co.country;

-- 16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film, no of rental days, the amount paid by the customer along with the percentage of customer spending.
CREATE VIEW rental_summary AS
SELECT DATE(r.rental_date) AS visiting_day,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       f.title,
       DATEDIFF(r.return_date, r.rental_date) AS no_of_rental_days,
       p.amount,
       ROUND(p.amount / SUM(p.amount) OVER (PARTITION BY p.customer_id) * 100, 2) AS percentage_spent
FROM rental r
JOIN payment p ON r.rental_id = p.rental_id
JOIN customer c ON r.customer_id = c.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id;

-- 17.Display the customers who paid 50% of their total rental costs within one day.
SELECT customer_id
FROM payment
GROUP BY customer_id
HAVING SUM(CASE WHEN DATEDIFF(payment_date, NOW()) <= 1 THEN amount ELSE 0 END)
       >= 0.5 * SUM(amount);



