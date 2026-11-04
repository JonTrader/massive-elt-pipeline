-- Snowflake identity for CI dbt unit tests.
-- Run this file by hand as a user who can assume ACCOUNTADMIN.
-- Run snowflake/bootstrap.sql first. The grants below target MARKET.RAW,
-- MARKET.STAGING, and MARKET.MARTS, and those schemas must already exist.
--
-- The script does not print or store a private key, a passphrase, or an
-- account identifier. Leave the <public-key> placeholder in the committed
-- file. Paste the real public key only into the worksheet for that one
-- statement. The key pair must be a different pair from the loader key.
--
-- IF NOT EXISTS will not repair an object that was created with the wrong
-- settings. The ALTER statements below re-apply the settings that are safe
-- to repeat. CREATE OR REPLACE is not used: replacing the resource monitor
-- resets its used-credit counter, and replacing the user would drop the key.

-- Fail here when this user cannot administer the account. SYSADMIN creates
-- the warehouse. ACCOUNTADMIN creates the resource monitor and assigns it.
USE ROLE ACCOUNTADMIN;

USE ROLE SYSADMIN;

-- XSMALL is the SQL name for X-Small. One credit per hour while running.
-- Created suspended so this script does not start the warehouse.
-- AUTO_RESUME wakes it on the next query. AUTO_SUSPEND = 60 suspends it
-- after 60 seconds with no queries. A resume also has a 60-second minimum
-- bill, so a short unit-test run costs about one minute of X-Small time.
CREATE WAREHOUSE IF NOT EXISTS CI_WH
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'CI dbt unit tests. X-Small. Suspends after 60 seconds idle.';

-- Resource monitors are account-level objects. ACCOUNTADMIN creates them.
-- This monitor is assigned only to CI_WH. It is not an account monitor, so
-- it cannot suspend the loader warehouse, and loader usage does not consume
-- this quota. An account-level monitor, if the account already has one,
-- still applies to CI_WH as well. This file does not change that monitor.
--
-- 2 credits per month is two hours of X-Small time. A unit-test run holds
-- the warehouse for about a minute, so the quota covers on the order of
-- 100 runs. At 100 percent the warehouse suspends after running queries
-- finish. AUTO_RESUME does not override that suspension. A query already
-- running at the threshold can finish and push usage slightly past 2.
USE ROLE ACCOUNTADMIN;

CREATE RESOURCE MONITOR IF NOT EXISTS CI_WH_MONITOR WITH
  CREDIT_QUOTA = 2
  FREQUENCY = MONTHLY
  START_TIMESTAMP = IMMEDIATELY
  TRIGGERS ON 100 PERCENT DO SUSPEND;

-- IF NOT EXISTS does not update a monitor that already exists. Re-apply the
-- quota and the suspend trigger. Leave FREQUENCY and START_TIMESTAMP alone:
-- changing either one resets used credits to zero.
ALTER RESOURCE MONITOR CI_WH_MONITOR SET
  CREDIT_QUOTA = 2
  TRIGGERS ON 100 PERCENT DO SUSPEND;

-- CREATE WAREHOUSE IF NOT EXISTS does not attach a monitor created later
-- in this file, and it does not repair size or suspend settings.
-- INITIALLY_SUSPENDED is create-time only. This ALTER does not suspend a
-- warehouse that is already running.
ALTER WAREHOUSE CI_WH SET
  WAREHOUSE_SIZE = XSMALL
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  RESOURCE_MONITOR = CI_WH_MONITOR
  COMMENT = 'CI dbt unit tests. X-Small. Suspends after 60 seconds idle.';

-- SECURITYADMIN holds MANAGE GRANTS, so it can grant on the warehouse and
-- on the schemas SYSADMIN owns.
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS CI_READER
  COMMENT = 'CI role for dbt unit tests. SELECT on RAW/STAGING/MARTS; CREATE TABLE only in STAGING and MARTS for unit-test temp tables.';

ALTER ROLE IF EXISTS CI_READER SET
  COMMENT = 'CI role for dbt unit tests. SELECT on RAW/STAGING/MARTS; CREATE TABLE only in STAGING and MARTS for unit-test temp tables.';

-- USAGE lets a query run and lets AUTO_RESUME wake the warehouse.
-- OPERATE is not granted, so this role cannot suspend, resume, or abort.
-- MODIFY is not granted, so it cannot change the warehouse size.
GRANT USAGE ON WAREHOUSE CI_WH TO ROLE CI_READER;

-- Schema USAGE is required before a table privilege in that schema applies.
-- CREATE SCHEMA is not granted.
GRANT USAGE ON DATABASE MARKET TO ROLE CI_READER;
GRANT USAGE ON SCHEMA MARKET.RAW TO ROLE CI_READER;
GRANT USAGE ON SCHEMA MARKET.STAGING TO ROLE CI_READER;
GRANT USAGE ON SCHEMA MARKET.MARTS TO ROLE CI_READER;

-- ALL covers tables that already exist. FUTURE covers tables the loader or
-- dbt creates later. Staging and marts are tables (transform/dbt_project.yml),
-- so views are not granted.
-- No INSERT, UPDATE, DELETE, or TRUNCATE on production tables.
-- No CREATE VIEW. No CREATE TABLE on MARKET.RAW.
-- No USAGE on stage MARKET.RAW.BRONZE_DAILY_BARS, file format
-- MARKET.RAW.DAILY_BARS_PARQUET, or storage integration MARKET_LAKE.
--
-- dbt 1.12 unit tests run CREATE OR REPLACE TEMPORARY TABLE in the model
-- schema (STAGING or MARTS) to read column types, then drop it. Snowflake
-- has no temporary-only privilege, so CREATE TABLE is required there. That
-- also allows a permanent table in those schemas. CI_READER still cannot
-- write MARKET.RAW and cannot use the bronze stage. The role owns any table
-- it creates, so it can DROP its own temp tables without a separate grant.
GRANT SELECT ON ALL TABLES IN SCHEMA MARKET.RAW TO ROLE CI_READER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MARKET.RAW TO ROLE CI_READER;
GRANT SELECT ON ALL TABLES IN SCHEMA MARKET.STAGING TO ROLE CI_READER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MARKET.STAGING TO ROLE CI_READER;
GRANT SELECT ON ALL TABLES IN SCHEMA MARKET.MARTS TO ROLE CI_READER;
GRANT SELECT ON FUTURE TABLES IN SCHEMA MARKET.MARTS TO ROLE CI_READER;

GRANT CREATE TABLE ON SCHEMA MARKET.STAGING TO ROLE CI_READER;
GRANT CREATE TABLE ON SCHEMA MARKET.MARTS TO ROLE CI_READER;

-- TYPE = SERVICE cannot log in with a password and cannot enroll in MFA.
-- The loader user is a different user. Do not grant CI_READER to that user,
-- and do not grant LOADER to CI_USER.
CREATE USER IF NOT EXISTS CI_USER
  TYPE = SERVICE
  COMMENT = 'CI dbt unit tests. Key-pair only. Separate key from the loader.';

GRANT ROLE CI_READER TO USER CI_USER;

-- IF NOT EXISTS does not update an existing user. Re-apply type and defaults.
-- Empty secondary roles keep the session on CI_READER alone.
-- DEFAULT_ROLE does not grant the role. The GRANT above does that.
ALTER USER CI_USER SET
  TYPE = SERVICE
  DEFAULT_ROLE = CI_READER
  DEFAULT_WAREHOUSE = CI_WH
  DEFAULT_SECONDARY_ROLES = ()
  COMMENT = 'CI dbt unit tests. Key-pair only. Separate key from the loader.';

-- Current grants, future grants, and roles granted to the user.
-- SHOW GRANTS TO ROLE does not list FUTURE grants. That needs its own command.
SHOW GRANTS TO ROLE CI_READER;
SHOW FUTURE GRANTS TO ROLE CI_READER;
SHOW GRANTS TO USER CI_USER;

-- Replace <public-key> in this statement before you run it.
-- The value is the base64 body only, without the PEM header or footer.
-- This key pair must be different from the loader key. Do not commit the
-- filled-in statement. If this still contains <public-key>, Snowflake
-- rejects it and the previous public key, if any, stays as it is.
ALTER USER CI_USER SET RSA_PUBLIC_KEY = '<public-key>';

-- Verification. Run these statements as CI_USER after the public key is set.
-- Do not run them in this ACCOUNTADMIN session: CREATE and INSERT would
-- succeed here and would change the database.
-- A SERVICE user has no password, so use SnowSQL or another key-pair client.
--
-- Expected:
--   CURRENT_USER() = CI_USER
--   CURRENT_ROLE() = CI_READER
--   CURRENT_WAREHOUSE() = CI_WH
--   SELECT returns a count. Zero rows is a successful read.
--   CREATE TABLE in MARKET.RAW fails (no CREATE there).
--   CREATE TEMPORARY TABLE in MARKET.STAGING succeeds; DROP it afterward.
--   INSERT into RAW and LIST on the stage fail with insufficient privileges.
--   Snowflake hides objects the role cannot use, so a missing privilege can
--   also surface as "does not exist". A numeric COUNT is the success check.
--
-- The INSERT lists extracted_at because that column is NOT NULL. A short
-- insert that fails the constraint would look like a denied write even if
-- the role had INSERT. BEGIN/ROLLBACK means a wrongly granted INSERT does
-- not leave a row: if the INSERT succeeds, run ROLLBACK before anything else.
-- If the INSERT fails, ROLLBACK may say there is no active transaction. That is fine.
-- If the CREATE in RAW succeeds, drop MARKET.RAW.CI_READER_SHOULD_FAIL as an admin.
/*
ALTER SESSION SET QUOTED_IDENTIFIERS_IGNORE_CASE = FALSE;

SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE();

SELECT COUNT(*) FROM MARKET.RAW.DAILY_BARS;

CREATE TABLE MARKET.RAW.CI_READER_SHOULD_FAIL (ID NUMBER);

CREATE OR REPLACE TEMPORARY TABLE MARKET.STAGING.CI_READER_TEMP_OK (ID NUMBER);
DROP TABLE IF EXISTS MARKET.STAGING.CI_READER_TEMP_OK;

BEGIN;
INSERT INTO MARKET.RAW.DAILY_BARS ("T", extracted_at)
VALUES ('CI_READER_SHOULD_FAIL', '1970-01-01 00:00:00'::TIMESTAMP_NTZ);
ROLLBACK;

LIST @MARKET.RAW.BRONZE_DAILY_BARS;
*/
