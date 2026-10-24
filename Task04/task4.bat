#!/bin/bash
chcp 65001

echo Создаем базу данных из скрипта
sqlite3 movies_rating.db < db_init.sql
echo База данных успешно создана!
echo.

echo "1. Найти все пары пользователей, оценивших один и тот же фильм. Устранить дубликаты, проверить отсутствие пар с самим собой. Для каждой пары должны быть указаны имена пользователей и название фильма, который они оценили. В списке оставить первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT u1.name AS user1, u2.name AS user2, m.title FROM ratings r1 JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id JOIN users u1 ON r1.user_id = u1.id JOIN users u2 ON r2.user_id = u2.id JOIN movies m ON r1.movie_id = m.id ORDER BY m.title, user1, user2 LIMIT 100;"
echo.

echo "2. Найти 10 самых свежих оценок от разных пользователей, вывести названия фильмов, имена пользователей, оценку, дату отзыва в формате ГГГГ-ММ-ДД."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH LatestRatings AS (SELECT r.user_id, r.movie_id, r.rating, r.timestamp, ROW_NUMBER() OVER(PARTITION BY r.user_id ORDER BY r.timestamp DESC) as rn FROM ratings r) SELECT m.title, u.name, lr.rating, date(lr.timestamp, 'unixepoch') as rating_date FROM LatestRatings lr JOIN users u ON lr.user_id = u.id JOIN movies m ON lr.movie_id = m.id WHERE lr.rn = 1 ORDER BY lr.timestamp DESC LIMIT 10;"
echo.

echo "3. Вывести в одном списке все фильмы с максимальным средним рейтингом и все фильмы с минимальным средним рейтингом. Общий список отсортировать по году выпуска и названию фильма. В зависимости от рейтинга в колонке 'Рекомендуем' для фильмов должно быть написано 'Да' или 'Нет'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH MovieAvg AS (SELECT m.id, m.title, m.year, AVG(r.rating) as avg_rating FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id), MinMax AS (SELECT MAX(avg_rating) as max_r, MIN(avg_rating) as min_r FROM MovieAvg) SELECT ma.title, ma.year, ROUND(ma.avg_rating, 2) as avg_rating, CASE WHEN ma.avg_rating = mm.max_r THEN 'Да' WHEN ma.avg_rating = mm.min_r THEN 'Нет' END as 'Рекомендуем' FROM MovieAvg ma CROSS JOIN MinMax mm WHERE ma.avg_rating = mm.max_r OR ma.avg_rating = mm.min_r ORDER BY ma.year ASC, ma.title ASC;"
echo.

echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT COUNT(r.id) as rating_count, ROUND(AVG(r.rating), 2) as avg_rating FROM ratings r JOIN users u ON r.user_id = u.id WHERE u.gender = 'female' AND strftime('%%Y', date(r.timestamp, 'unixepoch')) IN ('2010', '2011', '2012');"
echo.

echo "5. Составить список фильмов с указанием их средней оценки и места в рейтинге по средней оценке. Полученный список отсортировать по году выпуска и названиям фильмов. В списке оставить первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RankedMovies AS (SELECT m.title, m.year, ROUND(AVG(r.rating), 2) as avg_rating, RANK() OVER(ORDER BY AVG(r.rating) DESC) as rating_rank FROM movies m JOIN ratings r ON m.id = r.movie_id GROUP BY m.id) SELECT title, year, avg_rating, rating_rank FROM RankedMovies ORDER BY year ASC, title ASC LIMIT 20;"
echo.

echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT SUBSTR(name, INSTR(name, ' ') + 1) || ' ' || SUBSTR(name, 1, INSTR(name, ' ') - 1) || '|' || register_date as 'Фамилия Имя|Дата регистрации' FROM users ORDER BY register_date DESC LIMIT 10;"
echo.

echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE cnt(x) AS (SELECT 1 UNION ALL SELECT x + 1 FROM cnt WHERE x < 100) SELECT printf('%%dx%%d=%%d', ((x - 1) / 10) + 1, ((x - 1) %% 10) + 1, (((x - 1) / 10) + 1) * (((x - 1) %% 10) + 1)) as result FROM cnt;"
echo.

echo "8. С помощью рекурсивного CTE выделить все жанры фильмов, имеющиеся в таблице movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(movie_id, genre, rest) AS (SELECT id, CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END, CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END FROM movies UNION ALL SELECT movie_id, CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END, CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END FROM split WHERE rest != '') SELECT DISTINCT genre FROM split WHERE genre != '' ORDER BY genre;"
echo.

echo Выполнение завершено!
pause