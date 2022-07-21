\set MYSQL_HOST			`echo \'"$MYSQL_HOST"\'`
\set MYSQL_PORT			`echo \'"$MYSQL_PORT"\'`
\set MYSQL_USER_NAME	`echo \'"$MYSQL_USER_NAME"\'`
\set MYSQL_PASS			`echo \'"$MYSQL_PWD"\'`

-- Before running this file User must create database mysql_fdw_regress on
-- MySQL with all permission for MYSQL_USER_NAME user with MYSQL_PWD password
-- and ran mysql_init.sh file to create tables.

\c contrib_regression
CREATE EXTENSION IF NOT EXISTS mysql_fdw;
CREATE SERVER mysql_svr FOREIGN DATA WRAPPER mysql_fdw
  OPTIONS (host :MYSQL_HOST, port :MYSQL_PORT);
CREATE USER MAPPING FOR public SERVER mysql_svr
  OPTIONS (username :MYSQL_USER_NAME, password :MYSQL_PASS);
CREATE SERVER mysql_svr1 FOREIGN DATA WRAPPER mysql_fdw
  OPTIONS (host :MYSQL_HOST, port :MYSQL_PORT);
CREATE USER MAPPING FOR public SERVER mysql_svr1
  OPTIONS (username :MYSQL_USER_NAME, password :MYSQL_PASS);

-- Create foreign tables and insert data.
CREATE FOREIGN TABLE fdw519_ft1(stu_id int, stu_name varchar(255), stu_dept int)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress1', table_name 'student');
CREATE FOREIGN TABLE fdw519_ft2(c1 INTEGER, c2 VARCHAR(14), c3 VARCHAR(13))
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress', table_name 'test_tbl2');
CREATE FOREIGN TABLE fdw519_ft3 (c1 INTEGER, c2 VARCHAR(10), c3 CHAR(9), c4 BIGINT, c5 pg_catalog.Date, c6 DECIMAL, c7 INTEGER, c8 SMALLINT)
  SERVER mysql_svr1 OPTIONS (dbname 'mysql_fdw_regress', table_name 'test_tbl1');
INSERT INTO fdw519_ft1 VALUES(1, 'One', 101);
INSERT INTO fdw519_ft2 VALUES(10, 'DEVELOPMENT', 'PUNE');
INSERT INTO fdw519_ft2 VALUES(20, 'ADMINISTRATION', 'BANGLORE');
INSERT INTO fdw519_ft3 VALUES (100, 'EMP1', 'ADMIN', 1300, '1980-12-17', 800.23, NULL, 20);
INSERT INTO fdw519_ft3 VALUES (200, 'EMP2', 'SALESMAN', 600, '1981-02-20', 1600.00, 300, 30);

-- Check truncatable option with invalid values.
-- Since truncatable option is available since v14, this gives an error on v13
-- and previous versions.
ALTER SERVER mysql_svr OPTIONS (ADD truncatable 'abc');
ALTER FOREIGN TABLE fdw519_ft1 OPTIONS (ADD truncatable 'abc');

-- Default behavior, should truncate.
TRUNCATE fdw519_ft1;
SELECT * FROM fdw519_ft1 ORDER BY 1;

INSERT INTO fdw519_ft1 VALUES(1, 'One', 101);

-- Set truncatable to false
-- Since truncatable option is available since v14, this gives an error on v13
-- and previous versions.
ALTER SERVER mysql_svr OPTIONS (ADD truncatable 'false');

-- Truncate the table.
TRUNCATE fdw519_ft1;
SELECT * FROM fdw519_ft1 ORDER BY 1;

-- Set truncatable to true
-- Since truncatable option is available since v14, this gives an error on v13
-- and previous versions.
ALTER SERVER mysql_svr OPTIONS (SET truncatable 'true');
TRUNCATE fdw519_ft1;
SELECT * FROM fdw519_ft1 ORDER BY 1;

-- truncatable to true on Server but false on table level.
-- Since truncatable option is available since v14, this gives an error on v13
-- and previous versions.
ALTER SERVER mysql_svr OPTIONS (SET truncatable 'false');
ALTER TABLE fdw519_ft2 OPTIONS (ADD truncatable 'true');
SELECT * FROM fdw519_ft2 ORDER BY 1;
TRUNCATE fdw519_ft2;
SELECT * FROM fdw519_ft2 ORDER BY 1;

INSERT INTO fdw519_ft1 VALUES(1, 'One', 101);
INSERT INTO fdw519_ft2 VALUES(10, 'DEVELOPMENT', 'PUNE');
INSERT INTO fdw519_ft2 VALUES(20, 'ADMINISTRATION', 'BANGLORE');

-- truncatable to true on Server but false on one table and true for other
-- table.
ALTER SERVER mysql_svr OPTIONS (SET truncatable 'true');
ALTER TABLE fdw519_ft1 OPTIONS (ADD truncatable 'false');
ALTER TABLE fdw519_ft2 OPTIONS (SET truncatable 'true');
TRUNCATE fdw519_ft1, fdw519_ft2;
SELECT * FROM fdw519_ft1 ORDER BY 1;
SELECT * FROM fdw519_ft2 ORDER BY 1;

-- truncatable to false on Server but false on one table and true for other
-- table.
ALTER SERVER mysql_svr OPTIONS (SET truncatable 'false');
ALTER TABLE fdw519_ft1 OPTIONS (SET truncatable 'false');
ALTER TABLE fdw519_ft2 OPTIONS (SET truncatable 'true');
TRUNCATE fdw519_ft1, fdw519_ft2;
SELECT * FROM fdw519_ft1 ORDER BY 1;
SELECT * FROM fdw519_ft2 ORDER BY 1;

-- Truncate from different servers.
ALTER SERVER mysql_svr OPTIONS (SET truncatable 'true');
ALTER SERVER mysql_svr1 OPTIONS (ADD truncatable 'true');
ALTER TABLE fdw519_ft1 OPTIONS (SET truncatable 'true');
TRUNCATE fdw519_ft1, fdw519_ft2, fdw519_ft3;
SELECT * FROM fdw519_ft1 ORDER BY 1;
SELECT * FROM fdw519_ft2 ORDER BY 1;
SELECT * FROM fdw519_ft3 ORDER BY 1;

INSERT INTO fdw519_ft1 VALUES(1, 'One', 101);
SELECT * FROM fdw519_ft1 ORDER BY 1;
-- Truncate with CASCADE is not supported.
TRUNCATE fdw519_ft1 CASCADE;
SELECT * FROM fdw519_ft1 ORDER BY 1;
-- Default is RESTRICT, so it is allowed.
TRUNCATE fdw519_ft1 RESTRICT;
SELECT * FROM fdw519_ft1 ORDER BY 1;

-- Should throw an error if primary key is referenced by foreign key.
CREATE FOREIGN TABLE fdw519_ft4(stu_id varchar(10), stu_name varchar(255), stu_dept int)
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress1', table_name 'student1');
CREATE FOREIGN TABLE fdw519_ft5(dept_id int, stu_id varchar(10))
  SERVER mysql_svr OPTIONS (dbname 'mysql_fdw_regress1', table_name 'dept');
TRUNCATE fdw519_ft4;

-- Cleanup
DELETE FROM fdw519_ft1;
DELETE FROM fdw519_ft2;
DELETE FROM fdw519_ft3;
DROP FOREIGN TABLE fdw519_ft1;
DROP FOREIGN TABLE fdw519_ft2;
DROP FOREIGN TABLE fdw519_ft3;
DROP FOREIGN TABLE fdw519_ft4;
DROP FOREIGN TABLE fdw519_ft5;
DROP USER MAPPING FOR public SERVER mysql_svr;
DROP SERVER mysql_svr;
DROP USER MAPPING FOR public SERVER mysql_svr1;
DROP SERVER mysql_svr1;
DROP EXTENSION mysql_fdw;
