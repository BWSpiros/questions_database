CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(1023) NOT NULL,
  author INTEGER NOT NULL,

  FOREIGN KEY (author) REFERENCES users(id)
);


--#######################
CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id) REFERENCES users(id),
  FOREIGN KEY (user_id) REFERENCES questions(id)
);
--#######################

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body VARCHAR(1023) NOT NULL,
  parent INTEGER,
  question INTEGER NOT NULL,
  user INTEGER NOT NULL,

  FOREIGN KEY (user) REFERENCES user(id),
  FOREIGN KEY (question) REFERENCES questions(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);


INSERT INTO
  users(fname, lname)
VALUES
  ('Charleton', 'Broughtwerst'),
  ('Destiny', 'Candelabra'),
  ('Skippy', 'McPregnant');

INSERT INTO
  questions (title, body, author)
VALUES
  ('How to tell if pregnant?', 'I heard there is an app for that.', (SELECT id FROM users WHERE fname = 'Destiny')),
  ('Why are there pregnancy tests in my bathroom trash?', 'All of my roommates are dudes.', (SELECT id FROM users WHERE fname = 'Skippy')),
  ('Who ate all the mayonnaise?', 'I bought the biggest size at Costco THREE HOURS AGO!!!', (SELECT id FROM users WHERE fname = 'Charleton'));

INSERT INTO
  question_followers (question_id, user_id)
VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (2, 1),
  (2, 2),
  (3, 2),
  (3, 3);

INSERT INTO
  replies (body, parent, question, user)
VALUES
("I have some tests in my bathroom ;) ", NULL, 1, 1),
("Was somebody asking for me?", 1, 1, 3),
("What's a pregnancy test?", NULL, 2, 2);

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (1, 1),
  (1, 2),
  (1, 3),
  (2, 1),
  (2, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 2),
  (3, 3);