-- 1. Добавление 5 новых пользователей (я + 4 соседа по списку)
INSERT INTO users (first_name, last_name, email, gender, occupation_id) VALUES 
('Ilya', 'Ariskin', 'ilya.ariskin@uni.edu', 'male', (SELECT id FROM occupations WHERE name = 'student')),
('Anastasia', 'Bajol', 'anastasia.bajol@uni.edu', 'female', (SELECT id FROM occupations WHERE name = 'student')),
('Maxim', 'Bashmakov', 'maxim.bashmakov@uni.edu', 'male', (SELECT id FROM occupations WHERE name = 'student')),
('Ilya', 'Berman', 'ilya.berman@uni.edu', 'male', (SELECT id FROM occupations WHERE name = 'student')),
('Gleb', 'Veldyaskin', 'gleb.veldyaskin@uni.edu', 'male', (SELECT id FROM occupations WHERE name = 'student'));

-- 2. Добавление 3 новых фильмов разных жанров
INSERT OR IGNORE INTO movies (title, year) VALUES 
('The Matrix', 1999),
('Inception', 2010),
('The Grand Budapest Hotel', 2014);

-- Связываем фильмы с жанрами 
INSERT OR IGNORE INTO movie_genres (movie_id, genre_id) VALUES 
((SELECT id FROM movies WHERE title = 'The Matrix'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
((SELECT id FROM movies WHERE title = 'The Matrix'), (SELECT id FROM genres WHERE name = 'Action')),
((SELECT id FROM movies WHERE title = 'Inception'), (SELECT id FROM genres WHERE name = 'Sci-Fi')),
((SELECT id FROM movies WHERE title = 'Inception'), (SELECT id FROM genres WHERE name = 'Thriller')),
((SELECT id FROM movies WHERE title = 'The Grand Budapest Hotel'), (SELECT id FROM genres WHERE name = 'Comedy'));

-- 3. Добавление 3 новых отзывов от меня (Anastasia Bajol)
INSERT INTO ratings (user_id, movie_id, rating) VALUES 
((SELECT id FROM users WHERE email = 'anastasia.bajol@uni.edu'), (SELECT id FROM movies WHERE title = 'The Matrix'), 5.0),
((SELECT id FROM users WHERE email = 'anastasia.bajol@uni.edu'), (SELECT id FROM movies WHERE title = 'Inception'), 4.5),
((SELECT id FROM users WHERE email = 'anastasia.bajol@uni.edu'), (SELECT id FROM movies WHERE title = 'The Grand Budapest Hotel'), 5.0);