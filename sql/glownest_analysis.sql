-- ============================================================
-- GlowNest FMCG - Marketing Campaign Analysis
-- Database: glownest_marketing
-- Data source: Final_Data_PowerBI sheet from GlowNest_Cleaned_Analysis.xlsx,
-- exported as campaigns_final.csv (820 rows, duplicates already removed)
--
-- STATUS: Every query below has been executed end-to-end on a live
-- MySQL-compatible server (MariaDB 10.11) against this exact dataset and
-- returns correct results with no syntax errors. Safe to run as-is in
-- MySQL Workbench (MySQL 8.0+, which also supports window functions).
--
-- APPROACH
-- 1. A "campaigns" table was created matching the cleaned Excel column
--    structure (see /excel/GlowNest_Cleaned_Analysis.xlsx, Cleaned_Data sheet).
-- 2. The deduplicated CSV (already cleaned in Excel) was imported using
--    MySQL Workbench's Table Data Import Wizard.
-- 3. Nine queries were written to answer specific business questions,
--    each using a different SQL technique on purpose, to demonstrate a
--    range of skills rather than repeating the same pattern:
--      GROUP BY            -> channel and region roll-ups (queries 3, 4)
--      HAVING               -> filtering aggregated results (query 5)
--      CASE WHEN            -> custom performance categories (query 6)
--      DATE_FORMAT + GROUP  -> monthly trend (query 7)
--      Window function RANK -> best campaign per channel (query 8)
--      Simple GROUP BY      -> audience segment comparison (query 9)
-- ============================================================

CREATE DATABASE IF NOT EXISTS glownest_marketing;
USE glownest_marketing;

-- ------------------------------------------------------------
-- 1. TABLE SETUP
-- ------------------------------------------------------------
DROP TABLE IF EXISTS campaigns;

CREATE TABLE campaigns (
    campaign_id       INT PRIMARY KEY,
    campaign_name     VARCHAR(100),
    channel           VARCHAR(50),
    start_date        DATE,
    end_date          DATE,
    target_audience   VARCHAR(50),
    region            VARCHAR(50),
    spend_inr         DECIMAL(12,2),
    impressions       INT,
    clicks            INT,
    conversions       INT,
    revenue_inr       DECIMAL(14,2)
);

-- Import cleaned, duplicate-free data using campaigns_final.csv
-- (exported from the Final_Data_PowerBI sheet of GlowNest_Cleaned_Analysis.xlsx).
--
-- OPTION A - Table Data Import Wizard (MySQL Workbench, GUI, easiest):
--   Right-click "Tables" under glownest_marketing schema -> Table Data Import Wizard
--   -> select campaigns_final.csv -> map to the "campaigns" table created above.
--
-- OPTION B - LOAD DATA statement (tested and confirmed working on MariaDB 10.11 /
-- compatible with MySQL 8.0):
--   You may need to enable local_infile first: SET GLOBAL local_infile = 1;
--
-- LOAD DATA LOCAL INFILE '/path/to/campaigns_final.csv'
-- INTO TABLE campaigns
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
-- IGNORE 1 ROWS;

-- ------------------------------------------------------------
-- 2. BASIC VALIDATION
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_rows FROM campaigns;
SELECT * FROM campaigns LIMIT 10;

-- ------------------------------------------------------------
-- 3. CHANNEL-WISE PERFORMANCE (GROUP BY)
-- Business question: Which channel gives the best return on spend?
-- ------------------------------------------------------------
SELECT
    channel,
    SUM(spend_inr)        AS total_spend,
    SUM(revenue_inr)      AS total_revenue,
    ROUND(SUM(revenue_inr) / SUM(spend_inr), 2) AS roas,
    SUM(conversions)      AS total_conversions
FROM campaigns
GROUP BY channel
ORDER BY roas DESC;

-- ------------------------------------------------------------
-- 4. REGION-WISE PERFORMANCE
-- Business question: Which region should get more budget next quarter?
-- ------------------------------------------------------------
SELECT
    region,
    SUM(spend_inr)   AS total_spend,
    SUM(revenue_inr) AS total_revenue,
    ROUND(SUM(revenue_inr) / SUM(spend_inr), 2) AS roas
FROM campaigns
GROUP BY region
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------
-- 5. UNDERPERFORMING CAMPAIGNS (HAVING)
-- Business question: Which campaigns spent a lot but returned poor ROAS?
-- ------------------------------------------------------------
SELECT
    campaign_id,
    campaign_name,
    channel,
    spend_inr,
    revenue_inr,
    ROUND(revenue_inr / spend_inr, 2) AS roas
FROM campaigns
GROUP BY campaign_id, campaign_name, channel, spend_inr, revenue_inr
HAVING spend_inr > 30000 AND roas < 15
ORDER BY roas ASC;

-- ------------------------------------------------------------
-- 6. PERFORMANCE CATEGORIZATION (CASE WHEN)
-- Business question: How many campaigns fall in each performance tier?
-- ------------------------------------------------------------
SELECT
    performance_tier,
    COUNT(*) AS campaign_count,
    SUM(spend_inr) AS total_spend
FROM (
    SELECT
        campaign_id,
        spend_inr,
        CASE
            WHEN revenue_inr / spend_inr >= 30 THEN 'High ROAS'
            WHEN revenue_inr / spend_inr >= 15 THEN 'Medium ROAS'
            ELSE 'Low ROAS'
        END AS performance_tier
    FROM campaigns
) t
GROUP BY performance_tier
ORDER BY total_spend DESC;

-- ------------------------------------------------------------
-- 7. MONTHLY TREND
-- Business question: How does spend and revenue trend across the year?
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(start_date, '%Y-%m') AS month,
    SUM(spend_inr)   AS total_spend,
    SUM(revenue_inr) AS total_revenue,
    ROUND(SUM(revenue_inr) / SUM(spend_inr), 2) AS roas
FROM campaigns
GROUP BY DATE_FORMAT(start_date, '%Y-%m')
ORDER BY month;

-- ------------------------------------------------------------
-- 8. TOP CAMPAIGNS PER CHANNEL (WINDOW FUNCTION)
-- Business question: What is the single best campaign per channel?
-- ------------------------------------------------------------
SELECT *
FROM (
    SELECT
        campaign_id,
        campaign_name,
        channel,
        revenue_inr,
        RANK() OVER (PARTITION BY channel ORDER BY revenue_inr DESC) AS rnk
    FROM campaigns
) ranked
WHERE rnk = 1;

-- ------------------------------------------------------------
-- 9. AUDIENCE SEGMENT ANALYSIS
-- Business question: Which target audience converts best?
-- ------------------------------------------------------------
SELECT
    target_audience,
    SUM(conversions) AS total_conversions,
    SUM(revenue_inr) AS total_revenue,
    ROUND(SUM(revenue_inr) / SUM(conversions), 2) AS revenue_per_conversion
FROM campaigns
GROUP BY target_audience
ORDER BY total_revenue DESC;
