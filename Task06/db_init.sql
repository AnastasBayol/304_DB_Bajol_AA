PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS study_groups;
DROP TABLE IF EXISTS curriculum;
DROP TABLE IF EXISTS disciplines;
DROP TABLE IF EXISTS directions;

-- Направления подготовки
CREATE TABLE directions (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    code           TEXT    NOT NULL UNIQUE,                 -- код направления
    name           TEXT    NOT NULL UNIQUE,
    degree_level   TEXT    NOT NULL DEFAULT 'бакалавриат'
                   CHECK (degree_level IN ('бакалавриат', 'магистратура', 'специалитет')),
    duration_years INTEGER NOT NULL DEFAULT 4 CHECK (duration_years BETWEEN 1 AND 6)
);

-- Справочник дисциплин
CREATE TABLE disciplines (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

-- Учебный план: какая дисциплина, на каком направлении, в каком семестре, сколько часов, какая аттестация
CREATE TABLE curriculum (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    direction_id     INTEGER NOT NULL REFERENCES directions(id)
                     ON UPDATE CASCADE ON DELETE RESTRICT,
    discipline_id    INTEGER NOT NULL REFERENCES disciplines(id)
                     ON UPDATE CASCADE ON DELETE RESTRICT,
    semester         INTEGER NOT NULL CHECK (semester BETWEEN 1 AND 12),
    lecture_hours    INTEGER NOT NULL DEFAULT 0 CHECK (lecture_hours >= 0),
    practice_hours   INTEGER NOT NULL DEFAULT 0 CHECK (practice_hours >= 0),
    attestation_type TEXT    NOT NULL DEFAULT 'экзамен'
                     CHECK (attestation_type IN ('зачет', 'экзамен')),
    CHECK (lecture_hours + practice_hours > 0),
    UNIQUE (direction_id, discipline_id, semester)
);

-- Учебные группы. Год поступления хранится навсегда, номер группы вычисляется
CREATE TABLE study_groups (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    direction_id   INTEGER NOT NULL REFERENCES directions(id)
                   ON UPDATE CASCADE ON DELETE RESTRICT,
    admission_year INTEGER NOT NULL CHECK (admission_year BETWEEN 1990 AND 2100),
    group_index    INTEGER NOT NULL CHECK (group_index BETWEEN 1 AND 99),  -- последние две цифры номера
    UNIQUE (direction_id, admission_year, group_index)
);

-- Студенты
CREATE TABLE students (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    last_name   TEXT NOT NULL,
    first_name  TEXT NOT NULL,
    middle_name TEXT,
    birth_date  TEXT NOT NULL CHECK (birth_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
    gender      TEXT NOT NULL CHECK (gender IN ('М', 'Ж')),
    group_id    INTEGER NOT NULL REFERENCES study_groups(id)
                ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Результаты экзаменов и зачетов
CREATE TABLE results (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id    INTEGER NOT NULL REFERENCES students(id)
                  ON UPDATE CASCADE ON DELETE CASCADE,
    curriculum_id INTEGER NOT NULL REFERENCES curriculum(id)
                  ON UPDATE CASCADE ON DELETE RESTRICT,
    exam_date     TEXT    NOT NULL CHECK (exam_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
    points        INTEGER NOT NULL DEFAULT 0 CHECK (points BETWEEN 0 AND 100),
    grade         INTEGER CHECK (grade IS NULL OR grade BETWEEN 2 AND 5),  -- только для экзаменов
    passed        INTEGER NOT NULL DEFAULT 1 CHECK (passed IN (0, 1)),
    UNIQUE (student_id, curriculum_id)
);

-- Текущий номер группы вычисляется из года поступления (данные не нужно менять каждый год)
DROP VIEW IF EXISTS v_groups;
CREATE VIEW v_groups AS
SELECT g.id AS group_id,
       d.name AS direction,
       g.admission_year,
       MIN(
         CAST(strftime('%Y','now') AS INTEGER) - g.admission_year
           + (CASE WHEN CAST(strftime('%m','now') AS INTEGER) >= 9 THEN 1 ELSE 0 END),
         d.duration_years
       ) * 100 + g.group_index AS group_number
FROM study_groups g JOIN directions d ON d.id = g.direction_id;


-- ===== Тестовые данные =====

INSERT INTO directions (code, name, degree_level, duration_years) VALUES
  ('01.03.02', 'Прикладная математика и информатика', 'бакалавриат', 4),
  ('02.03.02', 'Фундаментальная информатика и информационные технологии', 'бакалавриат', 4);

INSERT INTO disciplines (name) VALUES
  ('Базы данных'),
  ('Теория вероятностей'),
  ('Операционные системы'),
  ('Численные методы'),
  ('Английский язык'),
  ('Алгоритмы и структуры данных'),
  ('Физика');

INSERT INTO curriculum (direction_id, discipline_id, semester, lecture_hours, practice_hours, attestation_type) VALUES
  (1, 1, 4, 32, 32, 'экзамен'),
  (1, 2, 3, 34, 34, 'экзамен'),
  (1, 3, 4, 32, 16, 'экзамен'),
  (1, 4, 4, 16, 32, 'зачет'),
  (1, 5, 3, 0, 34, 'зачет'),
  (2, 1, 4, 32, 32, 'экзамен'),
  (2, 6, 3, 34, 34, 'экзамен'),
  (2, 7, 3, 32, 16, 'зачет');

-- Группа 304 в 2026/2027 уч. году: поступили в 2024, группа №4 (3 курс -> 304). Группа 303 - ФИИТ, тоже 2024.
INSERT INTO study_groups (direction_id, admission_year, group_index) VALUES
  (1, 2024, 4),
  (2, 2024, 3);

-- Строки студентов
INSERT INTO students (last_name, first_name, middle_name, birth_date, gender, group_id) VALUES
  ('Арискин', 'Илья', 'Витальевич', '2005-03-14', 'М', 1),
  ('Байол', 'Анастасия', 'Андреевна', '2007-01-17', 'Ж', 1),
  ('Башмаков', 'Максим', 'Игоревич', '2005-01-09', 'М', 1),
  ('Берман', 'Илья', 'Александрович', '2005-11-30', 'М', 1),
  ('Вельдяскин', 'Глеб', 'Витальевич', '2004-12-05', 'М', 1),
  ('Воронин', 'Алексей', 'Сергеевич', '2005-05-17', 'М', 1),
  ('Денисов', 'Максим', 'Сергеевич', '2005-09-02', 'М', 1),
  ('Ефимкин', 'Кирилл', 'Дмитриевич', '2005-02-25', 'М', 1),
  ('Зюзин', 'Виталий', 'Витальевич', '2004-10-19', 'М', 1),
  ('Игушкин', 'Евгений', 'Викторович', '2005-06-08', 'М', 1),
  ('Кочкарова', 'Шахиста', NULL, '2005-04-12', 'Ж', 1),
  ('Кряжев', 'Иван', 'Олегович', '2005-08-27', 'М', 1),
  ('Ксенофонтов', 'Сергей', 'Сергеевич', '2005-03-03', 'М', 1),
  ('Петров', 'Пётр', 'Петрович', '2005-05-05', 'М', 2),
  ('Сидорова', 'Мария', 'Ивановна', '2005-10-10', 'Ж', 2);

INSERT INTO results (student_id, curriculum_id, exam_date, points, grade, passed) VALUES
  (1, 1, '2026-06-15', 40, 2, 0),
  (1, 2, '2026-01-14', 92, 5, 1),
  (1, 4, '2026-06-05', 63, NULL, 1),
  (2, 1, '2026-06-15', 73, 4, 1),
  (2, 2, '2026-01-14', 72, 4, 1),
  (2, 4, '2026-06-05', 76, NULL, 1),
  (3, 1, '2026-06-15', 93, 5, 1),
  (3, 2, '2026-01-14', 90, 5, 1),
  (3, 4, '2026-06-05', 87, NULL, 1),
  (4, 1, '2026-06-15', 77, 4, 1),
  (4, 2, '2026-01-14', 70, 4, 1),
  (4, 4, '2026-06-05', 32, NULL, 0),
  (5, 1, '2026-06-15', 64, 3, 1),
  (5, 2, '2026-01-14', 92, 5, 1),
  (5, 4, '2026-06-05', 55, NULL, 1),
  (6, 1, '2026-06-15', 82, 4, 1),
  (6, 2, '2026-01-14', 98, 5, 1),
  (6, 4, '2026-06-05', 42, NULL, 0),
  (7, 1, '2026-06-15', 54, 2, 0),
  (7, 2, '2026-01-14', 63, 3, 1),
  (7, 4, '2026-06-05', 41, NULL, 0),
  (8, 1, '2026-06-15', 85, 5, 1),
  (8, 2, '2026-01-14', 82, 4, 1),
  (8, 4, '2026-06-05', 74, NULL, 1),
  (9, 1, '2026-06-15', 76, 4, 1),
  (9, 2, '2026-01-14', 82, 4, 1),
  (9, 4, '2026-06-05', 62, NULL, 1),
  (10, 1, '2026-06-15', 86, 5, 1),
  (10, 2, '2026-01-14', 42, 2, 0),
  (10, 4, '2026-06-05', 55, NULL, 1),
  (11, 1, '2026-06-15', 67, 3, 1),
  (11, 2, '2026-01-14', 42, 2, 0),
  (11, 4, '2026-06-05', 35, NULL, 0),
  (12, 1, '2026-06-15', 55, 3, 1),
  (12, 2, '2026-01-14', 76, 4, 1),
  (12, 4, '2026-06-05', 92, NULL, 1),
  (13, 1, '2026-06-15', 54, 2, 0),
  (13, 2, '2026-01-14', 95, 5, 1),
  (13, 4, '2026-06-05', 94, NULL, 1),
  (14, 6, '2026-06-16', 33, 2, 0),
  (14, 7, '2026-01-16', 76, 4, 1),
  (14, 8, '2026-01-12', 61, NULL, 1),
  (15, 6, '2026-06-16', 85, 5, 1),
  (15, 7, '2026-01-16', 68, 3, 1),
  (15, 8, '2026-01-12', 75, NULL, 1);
