-- =============================================================================
-- Aviation Analytics Platform — Snowflake Infrastructure Setup
-- =============================================================================
-- Run this script as ACCOUNTADMIN (or a role with equivalent privileges) on a
-- fresh Snowflake account to recreate the full infrastructure.
--
-- Sections:
--   1. Warehouses
--   2. Databases & schemas
--   3. Roles
--   4. Users          ← placeholders: fill in before running
--   5. Grants
-- =============================================================================


-- =============================================================================
-- 1. WAREHOUSES
-- =============================================================================

CREATE WAREHOUSE IF NOT EXISTS AVIATION_DBT_DEV_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Development warehouse for dbt and dlt runs';

CREATE WAREHOUSE IF NOT EXISTS AVIATION_DBT_PROD_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Production warehouse for dbt and dlt runs';


-- =============================================================================
-- 2. DATABASES & SCHEMAS
-- =============================================================================

-- DEV database
CREATE DATABASE IF NOT EXISTS AVIATION_ANALYTICS_DEV
    COMMENT = 'Aviation Analytics — development environment';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_DEV.RAW
    COMMENT = 'Raw flight records loaded daily by dlt';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_DEV.STAGING
    COMMENT = 'Cleaned and typed staging models (dbt views)';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_DEV.MARTS
    COMMENT = 'Fact, dimension, and mart models (dbt tables)';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_DEV.SNAPSHOTS
    COMMENT = 'SCD Type 2 snapshots — aircraft operator history';

-- PROD database
CREATE DATABASE IF NOT EXISTS AVIATION_ANALYTICS_PROD
    COMMENT = 'Aviation Analytics — production environment';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_PROD.RAW
    COMMENT = 'Raw flight records loaded daily by dlt';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_PROD.STAGING
    COMMENT = 'Cleaned and typed staging models (dbt views)';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_PROD.MARTS
    COMMENT = 'Fact, dimension, and mart models (dbt tables)';

CREATE SCHEMA IF NOT EXISTS AVIATION_ANALYTICS_PROD.SNAPSHOTS
    COMMENT = 'SCD Type 2 snapshots — aircraft operator history';


-- =============================================================================
-- 3. ROLES
-- =============================================================================

CREATE ROLE IF NOT EXISTS AVIATION_DBT_DEV_ROLE
    COMMENT = 'Role for dbt/dlt development operations against AVIATION_ANALYTICS_DEV';

CREATE ROLE IF NOT EXISTS AVIATION_DBT_PROD_ROLE
    COMMENT = 'Role for dbt/dlt production operations against AVIATION_ANALYTICS_PROD';

-- Grant roles up to SYSADMIN so they appear in the role hierarchy
GRANT ROLE AVIATION_DBT_DEV_ROLE  TO ROLE SYSADMIN;
GRANT ROLE AVIATION_DBT_PROD_ROLE TO ROLE SYSADMIN;


-- =============================================================================
-- 4. USERS  (fill in before running)
-- =============================================================================

-- CREATE USER IF NOT EXISTS <DEV_USER>
--     PASSWORD          = '<strong-password>'
--     DEFAULT_ROLE      = AVIATION_DBT_DEV_ROLE
--     DEFAULT_WAREHOUSE = AVIATION_DBT_DEV_WH
--     DEFAULT_NAMESPACE  = AVIATION_ANALYTICS_DEV.RAW
--     MUST_CHANGE_PASSWORD = FALSE
--     COMMENT = 'Service account for dbt/dlt development';

-- CREATE USER IF NOT EXISTS <PROD_USER>
--     PASSWORD          = '<strong-password>'
--     DEFAULT_ROLE      = AVIATION_DBT_PROD_ROLE
--     DEFAULT_WAREHOUSE = AVIATION_DBT_PROD_WH
--     DEFAULT_NAMESPACE  = AVIATION_ANALYTICS_PROD.RAW
--     MUST_CHANGE_PASSWORD = FALSE
--     COMMENT = 'Service account for dbt/dlt production (CI/CD)';

-- GRANT ROLE AVIATION_DBT_DEV_ROLE  TO USER <DEV_USER>;
-- GRANT ROLE AVIATION_DBT_PROD_ROLE TO USER <PROD_USER>;


-- =============================================================================
-- 5. GRANTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- DEV role — warehouse
-- -----------------------------------------------------------------------------
GRANT USAGE            ON WAREHOUSE AVIATION_DBT_DEV_WH TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT OPERATE          ON WAREHOUSE AVIATION_DBT_DEV_WH TO ROLE AVIATION_DBT_DEV_ROLE;

-- -----------------------------------------------------------------------------
-- DEV role — database & schemas
-- -----------------------------------------------------------------------------
GRANT USAGE            ON DATABASE   AVIATION_ANALYTICS_DEV            TO ROLE AVIATION_DBT_DEV_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_DEV.RAW        TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_DEV.RAW        TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_DEV.RAW        TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE STAGE     ON SCHEMA     AVIATION_ANALYTICS_DEV.RAW        TO ROLE AVIATION_DBT_DEV_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_DEV.STAGING    TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_DEV.STAGING    TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_DEV.STAGING    TO ROLE AVIATION_DBT_DEV_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_DEV.MARTS      TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_DEV.MARTS      TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_DEV.MARTS      TO ROLE AVIATION_DBT_DEV_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_DEV.SNAPSHOTS  TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_DEV.SNAPSHOTS  TO ROLE AVIATION_DBT_DEV_ROLE;

-- Future grants — covers tables/views created after this script runs (e.g. by dlt)
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.RAW       TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.STAGING  TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.MARTS    TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.SNAPSHOTS TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON FUTURE VIEWS  IN SCHEMA AVIATION_ANALYTICS_DEV.STAGING  TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON FUTURE VIEWS  IN SCHEMA AVIATION_ANALYTICS_DEV.MARTS    TO ROLE AVIATION_DBT_DEV_ROLE;

-- Existing objects (run if re-applying to a non-empty account)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.RAW          TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.STAGING     TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.MARTS       TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_DEV.SNAPSHOTS   TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON ALL VIEWS  IN SCHEMA AVIATION_ANALYTICS_DEV.STAGING     TO ROLE AVIATION_DBT_DEV_ROLE;
GRANT SELECT                          ON ALL VIEWS  IN SCHEMA AVIATION_ANALYTICS_DEV.MARTS       TO ROLE AVIATION_DBT_DEV_ROLE;

-- -----------------------------------------------------------------------------
-- PROD role — warehouse
-- -----------------------------------------------------------------------------
GRANT USAGE            ON WAREHOUSE AVIATION_DBT_PROD_WH TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT OPERATE          ON WAREHOUSE AVIATION_DBT_PROD_WH TO ROLE AVIATION_DBT_PROD_ROLE;

-- -----------------------------------------------------------------------------
-- PROD role — database & schemas
-- -----------------------------------------------------------------------------
GRANT USAGE            ON DATABASE   AVIATION_ANALYTICS_PROD             TO ROLE AVIATION_DBT_PROD_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_PROD.RAW         TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_PROD.RAW         TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_PROD.RAW         TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE STAGE     ON SCHEMA     AVIATION_ANALYTICS_PROD.RAW         TO ROLE AVIATION_DBT_PROD_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_PROD.STAGING     TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_PROD.STAGING     TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_PROD.STAGING     TO ROLE AVIATION_DBT_PROD_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_PROD.MARTS       TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_PROD.MARTS       TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE VIEW      ON SCHEMA     AVIATION_ANALYTICS_PROD.MARTS       TO ROLE AVIATION_DBT_PROD_ROLE;

GRANT USAGE            ON SCHEMA     AVIATION_ANALYTICS_PROD.SNAPSHOTS   TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT CREATE TABLE     ON SCHEMA     AVIATION_ANALYTICS_PROD.SNAPSHOTS   TO ROLE AVIATION_DBT_PROD_ROLE;

-- Future grants
GRANT SELECT, INSERT, UPDATE, DELETE ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.RAW       TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.STAGING  TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.MARTS    TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON FUTURE TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.SNAPSHOTS TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON FUTURE VIEWS  IN SCHEMA AVIATION_ANALYTICS_PROD.STAGING  TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON FUTURE VIEWS  IN SCHEMA AVIATION_ANALYTICS_PROD.MARTS    TO ROLE AVIATION_DBT_PROD_ROLE;

-- Existing objects
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.RAW          TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.STAGING     TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.MARTS       TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON ALL TABLES IN SCHEMA AVIATION_ANALYTICS_PROD.SNAPSHOTS   TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON ALL VIEWS  IN SCHEMA AVIATION_ANALYTICS_PROD.STAGING     TO ROLE AVIATION_DBT_PROD_ROLE;
GRANT SELECT                          ON ALL VIEWS  IN SCHEMA AVIATION_ANALYTICS_PROD.MARTS       TO ROLE AVIATION_DBT_PROD_ROLE;
