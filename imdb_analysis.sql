-- Segment 1: Database - Tables, Columns, Relationships

-- What are the different tables in the database and how are they connected to each other in the database?

-- Find the total number of rows in each table of the schema.

select table_name,table_rows from information_schema.tables
where table_schema = 'imdb';

select count(*) from director_mapping;
select count(*) from genre;


-- Identify which columns in the movie table have null values.
select column_name from information_schema.columns
where table_name = 'movies'
and table_schema = 'imdb'
and is_nullable ='yes';




-- Segment 2: Movie Release Trends

-- Determine the total number of movies released each year and analyse the month-wise trend.
select * from movies limit 10;

select year,month(date_published) as month_no ,count(id) as movies
from movies
group by year,month(date_published)
order by year,month_no;


-- Calculate the number of movies produced in the USA or India in the year 2019
select * from movies limit 10;

select count(*) number_of_movies from movies
where year = 2019
and (country like '%usa%'
or country like '%india%');




-- Segment 3: Production Statistics and Genre Analysis

-- Retrieve the unique list of genres present in the dataset.
select * from genre limit 10;


-- Identify the genre with the highest number of movies produced overall.
select genre,count(movie_id) as movies
from genre
group by genre
order by movies desc
limit 1;

select * from genre order by movie_id limit 100;
-- Determine the count of movies that belong to only one genre.
select count(movie_id) from
(select movie_id,count(distinct genre) as genres
from genre
group by movie_id)t
where genres = 1;


-- Calculate the average duration of movies in each genre.
select a.*,b.genre from movies a
join genre b
on a.id = b.movie_id;


-- Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
with genre_cte as
(select genre,count(movie_id) as movies
from genre
group by genre)

select * from
(select *,rank() over (order by movies desc) as rk
from genre_cte)t
where genre = 'thriller'
;



-- Segment 4: Ratings Analysis and Crew Members

-- Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).
select * from ratings limit 10;

select min(avg_rating) as min_avg_rating,
max(avg_rating) as max_avg_rating,

min(total_votes) as min_total_votes,
max(total_votes) as max_total_votes,

min(median_rating) as min_median_rating,
max(median_rating) as max_median_rating
from ratings;

-- Identify the top 10 movies based on average rating.
with top_movies as
(select title,avg_rating,
row_number() over (order by avg_rating desc)  as rk
from movies a
left join ratings b
on a.id = b.movie_id)

select * from top_movies where rk<=10
order by rk;



-- Summarise the ratings table based on movie counts by median ratings.
select median_rating,count(movie_id) as movie_count
from ratings
group by median_rating
order by movie_count desc;

-- Identify the production house that has produced the most number of hit movies (average rating > 8).
select * from movies limit 10;

select m.production_house,count(*) as num_hit_movies
from movies.m
inner join ratings r on m.movie_id = r.movie_id
group by m.production_house
having avg(r.rating) > 8
order by num_hit_movies desc
limit 1;

select production_company,count(id) as movie_count
from movies
where id in(select movie_id from ratings where avg_rating > 8)
and production_company is not null
group by production_company
order by movie_count desc
limit 1;

-- Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
SELECT genre, count(*) AS num_movies
FROM  movies
WHERE release_date BETWEEN '2017-03-01' AND '2017-03-31'
AND votes > 1000
GROUP BY genre
ORDER BY num_movies desc;

SELECT GENRE,COUNT(A.MOVIE_ID) AS MOVIES_COUNT
FROM GENRE A
JOIN MOVIES B
ON A.MOVIE_ID = B.ID
JOIN RATINGS C
ON A.MOVIE_ID = C.MOVIE_ID
WHERE YEAR = 2017
AND MONTH(DATE_PUBLISHED) = 3
AND COUNTRY LIKE '%USA%'
AND TOTAL_VOTES > 1000
GROUP BY GENRE
;

-- Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
select title,avg_rating,genre
from movies a
join genre b
on a.id = b.movie_id
join ratings c
on A.ID = C.MOVIE_ID
WHERE TITLE LIKE 'THE%'
AND AVG_RATING > 8;

with cte as
(select title,avg_rating,genre
from movies a
join genre b
on a.id = b.movie_id
join ratings c
on a.id = c. movie_id
where title like 'the%'
and avg_rating > 8)

select title,avg_rating, group_concat(distinct genre) as genres
from cte group by title,avg_rating
order by title;



-- Segment 5: Crew Analysis

-- Identify the columns in the names table that have null values.
select * from names limit 100;

select sum(case when id is null then 1 else 0 end) as id_null_count,
sum(case when name is null then 1 else 0 end) as name_null_count,
sum(case when height is null then 1 else 0 end) as height_null_count,
sum(case when date_of_birth is null then 1 else 0 end) as dob_null_count,
sum(case when known_for_movies is null then 1 else 0 end) as known_for_movies_null_count
from names;



-- Determine the top three directors in the top three genres with movies having an average rating > 8.
select * from genre;

select * from director_mapping;

select * from ratings;

with genre_top_3 as 
(select genre,count(movie_id) as num_movies
from genre
where movie_id in (select movie_id from ratings where avg_rating > 8)
group by genre
order by num_movies desc
limit 3),

director_genre_movies as
(select b.movie_id,b.genre,c.name_id,d.name
from genre b
join director_mapping c
on b.movie_id = c.movie_id
join names d on c.name_id = d.id
where b.movie_id in (select movie_id from ratings where avg_rating > 8))  


select * from
(select genre,name as director_name,count(movie_id) as num_movies,
row_number() over (partition by genre order by (movie_id) desc) as director_rk
from director_genre_movies
where genre in (select distinct genre from genre_top_3)
group by genre,name)t
where director_rk <=3
order by genre,director_rk;




-- Find the top two actors whose movies have a median rating >= 8.
select * from role_mapping limit 100;

with top_actors as
(select name_id,count(movie_id) as num_movies
from role_mapping
where category = 'actor'
and movie_id in (select movie_id from ratings where median_rating >= 8)
group by name_id
order by num_movies desc
limit 2)

select b.name as actors,num_movies
from top_actors a
join names b
on a.name_id = b.id
order by num_movies desc;




-- Identify the top three production houses based on the number of votes received by their movies.
select production_company,sum(total_votes) as totalvotes
from movies a join ratings b on a.id = b.movie_id
group by production_company
order by totalvotes desc
limit 3;



-- Rank actors based on their average ratings in Indian movies released in India.
with actors_cte as
(select name_id,sum(total_votes) as total_votes,count(a.movie_id) as movie_count,
sum(avg_rating * total_votes) as actors_avg_rating
from role_mapping a
join ratings b
on a.movie_id =b.movie_id
where category = 'actor'
and a.movie_id in
(select distinct id from movies
where country like '%india%')
group by name_id)

select b.name as actors_names,total_votes,movie_count,actor_avg_rating,
dense_rank() over (order by actors_avg_rating desc) as actor_rank
from actors_cte a
join names b
on a.name_id = b.id
order by actor_avg_rating desc;






-- Identify the top five actresses in Hindi movies released in India based on their average ratings.
select distinct languages from movies;

with actors_cte as
(select name_id,sum(total_votes) as total_votes,
count(a.movie_id) as movie_count,
sum(avg_rating * total_votes)/sum(total_votes) as actress_avg_rating
from role_mapping a
join ratings b
on a.movie_id = b.movie_id
where ctegory = 'actress'
and a.movie_id in
(select distinct id from movies
where country like '%india%'
and language like '%hindi%'
group by name_id)


select b.name as actors_names,total_votes,movie_count,round(,actress_avg_rating, 2) as actress_avg_rating,
dense_rank() over (order by actress_avg_rating desc) as actress_rank
from actors_cte a
join names b
on a.name_id = b.id
order by actress_rank desc;





-- Segment 6: Broader Understanding of Data

-- Classify thriller movies based on average ratings into different categories.
select a.title, case when avg_rating > 8 then '1. superhit'
when avg_rating  between 7 and 8 then '2. hit'
when avg_rating  between 5 and 7 then  '3. one-time-watch'
else '4.  flop' end as movie_catagory
from movies a 
join ratings b
on a.id = b.movie_id
where a.id in (select movie_id from genre where genre = 'thriller')
order by movie_catagory;



-- analyse the genre-wise running total and moving average of the average movie duration.
with genre_avg_duration as
(select genre,avg(duration) as avg_duration
from genre a join movies b
on a.movie_id = b.id
group by genre)


select genre,round(avg_duration,2) avg_duration,
round (sum(avg_duration) over (order by genre),2) as running_total,
round (avg(avg_duration) over(order by genre),2) as moving_avg
from genre_avg_duration order by genre;


-- Identify the five highest-grossing movies of each year that belong to the top three genres.
with genre_top_3 as
(select genre,count(movie_id) as movie_count
from genre group by genre
order by movie_count desc
limit 3),

base_table as
(select a.*,b.genre, replace(worldwide_gross_income,'$','') as new_gross_income
from movies a
join genre b
on a.id = b.movie_id
where genre in(select genre from genre_top_3))

select * from
(select genre,year,title,worlwide_gross_income,
dense_rank() over (partition by genre,year order by new_gross_income desc) as movie_rank
from base_table)t
where movie_rank <= 5
order by genre,year,movie_rank;




-- Determine the top two production houses that have produced the highest number of hits among multilingual movies.
use imdb;
select languages,locate(',',languages) from movies limit 100;
 
select * from ratings; 
 
select production_company,count(id) as movie_count
from movies
where locate(',',languages)>0
and id in (select movie_id from ratings where average_rating > 8)
group by production_company
order by movie_count desc
limit 2;

-- Identify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
with actress_cte as
(select name_id,sum(total_votes) as total_votes,count(a.movie_id) as movie_count,
sum(avg_rating * total_votes)/sum(total_votes) actress_avg_rating
from role_mapping a
join ratings b
on a.movie_id =b.movie_id
where category = 'actress'
and a.movie_id in
(select distinct movie_id from genre
where genre = 'drama')
group by name_id
having sum(avg_rating + total_votes)/sum(total_votes) > 8)

select b.name as actors_names,total_votes,movie_count,actor_avg_rating,
dense_rank() over (order by actors_avg_rating desc) as actor_rank
from actors_cte a
join names b
on a.name_id = b.id
-- where movies_count > 1
order by actress_rank
limit 3;

-- Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.
use imdb;

select * from director_mapping limit 100;

with top_directors as
(select name_id as director_id,count(movie_id) as movie_count
from director_mapping group by name_id
order by movie_count desc
limit 9),

movie_summary as
(select b.name_id as director_id, a.*, avg_rating,total_votes
from movies a join director_mapping b
on a.id = b.movie_id
left join ratings c
on a.id = c.movie-id
where b.name_id in (select director_id from top_diretors)),


final as
(select *,lead(date_published) over (partition by director_id order by date_published) as nx_movie_date
from movies_summary)

select * from movies_summary order by director_id limit 1000;
select * from top_directors;
select id ,title,duration,lag(duration,1) over (order by date_published),duration-lag(duration,1) over (order by date_published) from movies;




-- Segment 7: Recommendations

-- Based on the analysis, provide recommendations for the types of content Bolly movies should focus on producing.
-- genre,actors,actress,directors month during the which they want to make  the release
select * from director_mapping limit 100;

select * from genre limit 10;

