-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 04_matching_queries.sql
-- Target DBMS: MySQL 8.0+
-- Description: Core Matching Engine queries:
-- 1. Strict Match Query (Exact Category + Exact Location + Date Window)
-- 2. Location-Flexible Match Query (Exact Category + Cross-Campus Transit Window)
-- 3. Keyword Search Match Query (Pattern matching on Item Names / Descriptions)
-- 4. Dynamic Weighted Multi-Factor Score Query (0-100% Score with Reason Badges)
-- =====================================================================

USE campus_lost_found;

-- =====================================================================
-- QUERY 1: STRICT MATCHING
-- Criteria:
-- - Exact Category Match (l.category = f.category)
-- - Exact Campus Location Match (l.location_id = f.location_id)
-- - Found Date is ON or AFTER Lost Date, within 7 calendar days
-- - Items are not already resolved (Lost != 'RETURNED', Found != 'CLAIMED')
-- =====================================================================
SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.category,
    l.lost_date,
    u_lost.full_name AS student_name,
    u_lost.student_or_staff_id AS student_roll,
    u_lost.phone AS student_phone,
    f.found_id,
    f.item_name AS found_item,
    f.found_date,
    loc.location_name AS incident_location,
    DATEDIFF(f.found_date, l.lost_date) AS days_elapsed_between_events,
    f.storage_place AS custody_location,
    'HIGH CONFIDENCE STRICT MATCH' AS match_confidence_tier,
    'Exact Category, Exact Location, and Found within 7 days of loss' AS matching_reasons
FROM Lost_Items l
INNER JOIN Users u_lost 
    ON l.user_id = u_lost.user_id
INNER JOIN Found_Items f 
    ON l.category = f.category 
    AND l.location_id = f.location_id
INNER JOIN Locations loc 
    ON l.location_id = loc.location_id
WHERE f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 7
  AND l.status != 'RETURNED'
  AND f.status != 'CLAIMED'
ORDER BY days_elapsed_between_events ASC;


-- =====================================================================
-- QUERY 2: LOCATION-FLEXIBLE MATCHING
-- Rationale: Students frequently carry lost items across buildings before
-- realizing they are lost, or good samaritans hand items to security.
-- Criteria:
-- - Exact Category Match
-- - Found Date >= Lost Date within 14 calendar days
-- - Items can be in different locations
-- =====================================================================
SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.category,
    l.lost_date,
    u_lost.full_name AS student_name,
    u_lost.phone AS student_phone,
    loc_lost.location_name AS last_seen_at,
    f.found_id,
    f.item_name AS found_item,
    f.found_date,
    loc_found.location_name AS recovered_at,
    f.storage_place,
    DATEDIFF(f.found_date, l.lost_date) AS days_elapsed,
    CASE 
        WHEN l.location_id = f.location_id THEN 'Same Campus Zone'
        ELSE 'Cross-Campus Movement'
    END AS location_correlation,
    'FLEXIBLE MATCH (MANUAL INSPECTION RECOMMENDED)' AS match_confidence_tier
FROM Lost_Items l
INNER JOIN Users u_lost 
    ON l.user_id = u_lost.user_id
INNER JOIN Found_Items f 
    ON l.category = f.category
INNER JOIN Locations loc_lost 
    ON l.location_id = loc_lost.location_id
INNER JOIN Locations loc_found 
    ON f.location_id = loc_found.location_id
WHERE f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 14
  AND l.status != 'RETURNED'
  AND f.status != 'CLAIMED'
ORDER BY 
    CASE WHEN l.location_id = f.location_id THEN 0 ELSE 1 END,
    days_elapsed ASC;


-- =====================================================================
-- QUERY 3: KEYWORD SEARCH SIMILARITY MATCHING
-- Rationale: Matches items that share key tokens in item_name or description
-- (e.g. 'casio', 'calculator', 'wallet', 'titan', 'sanDisk', 'keys', 'nike')
-- =====================================================================
SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.description AS lost_details,
    f.found_id,
    f.item_name AS found_item,
    f.description AS found_details,
    l.category,
    f.storage_place,
    'KEYWORD PATTERN OVERLAP' AS match_reason
FROM Lost_Items l
CROSS JOIN Found_Items f
WHERE l.category = f.category
  AND (
      -- Calculator / Casio keyword overlap
      (LOWER(l.item_name) LIKE '%calculator%' AND LOWER(f.item_name) LIKE '%calculator%')
      OR (LOWER(l.description) LIKE '%casio%' AND LOWER(f.description) LIKE '%casio%')
      -- Wallet / Titan keyword overlap
      OR (LOWER(l.item_name) LIKE '%wallet%' AND LOWER(f.item_name) LIKE '%wallet%')
      OR (LOWER(l.description) LIKE '%titan%' AND LOWER(f.item_name) LIKE '%titan%')
      -- ID Card keyword overlap
      OR (LOWER(l.item_name) LIKE '%id card%' AND LOWER(f.item_name) LIKE '%id card%')
      -- Adapter / USB / Cable keyword overlap
      OR (LOWER(l.item_name) LIKE '%usb%' AND LOWER(f.item_name) LIKE '%usb%')
      OR (LOWER(l.item_name) LIKE '%keys%' AND LOWER(f.item_name) LIKE '%keys%')
  )
  AND f.found_date >= l.lost_date
  AND l.status != 'RETURNED'
  AND f.status != 'CLAIMED';


-- =====================================================================
-- QUERY 4: DYNAMIC WEIGHTED MULTI-FACTOR MATCH SCORING (HIGH-PRECISION)
-- Enforces:
--   1. Category Consistency: 25 points (mandatory prerequisite)
--   2. Keyword & Title Similarity: up to 40 points (requires >= 1 keyword match)
--   3. Location Proximity: 20 points (exact), 10 pts (adjacent/building), 3 pts (campus transit)
--   4. Date Proximity & Order: 15 points (Found Date >= Lost Date within 30 days)
-- Filters out physically impossible dates and items sharing zero descriptive keywords.
-- Returns verified candidate pairs with score >= 45 points, sorted by confidence.
-- =====================================================================
SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.category,
    l.lost_date,
    u_lost.full_name AS student_name,
    u_lost.phone AS student_phone,
    loc_lost.location_name AS lost_location,
    f.found_id,
    f.item_name AS found_item,
    f.found_date,
    loc_found.location_name AS found_location,
    f.storage_place,
    DATEDIFF(f.found_date, l.lost_date) AS date_difference_days,
    
    -- Calculated Multi-Factor Score (0 - 100 points):
    (
        -- Factor 1: Category Match (25 pts)
        (CASE WHEN l.category = f.category THEN 25 ELSE 0 END) +
        
        -- Factor 2: Keyword & Title Similarity (up to 40 pts)
        (CASE 
            WHEN LOWER(l.item_name) = LOWER(f.item_name) THEN 40
            WHEN LOWER(f.item_name) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 30
            WHEN LOWER(f.description) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 22
            WHEN LOWER(f.item_name) LIKE '%casio%' OR LOWER(f.item_name) LIKE '%wallet%' 
              OR LOWER(f.item_name) LIKE '%earbuds%' OR LOWER(f.item_name) LIKE '%id card%'
              OR LOWER(f.item_name) LIKE '%key%' OR LOWER(f.item_name) LIKE '%adapter%' THEN 20
            ELSE 14 
         END) +
         
        -- Factor 3: Location Proximity (up to 20 pts)
        (CASE 
            WHEN l.location_id = f.location_id THEN 20 
            WHEN loc_lost.building = loc_found.building THEN 10
            ELSE 3 
         END) +
        
        -- Factor 4: Date Proximity & Order (up to 15 pts)
        (CASE 
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 1 THEN 15
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 4 THEN 11
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 7 THEN 8
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 14 THEN 5
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 30 THEN 2
            ELSE 0 
         END)
    ) AS total_match_score,
    
    -- Confidence Label
    CASE 
        WHEN (
            (CASE WHEN l.category = f.category THEN 25 ELSE 0 END) +
            (CASE WHEN LOWER(l.item_name) = LOWER(f.item_name) THEN 40 ELSE 22 END) +
            (CASE WHEN l.location_id = f.location_id THEN 20 ELSE 3 END) +
            (CASE WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 4 THEN 11 ELSE 0 END)
        ) >= 75 THEN 'HIGH CONFIDENCE (VERIFIED CANDIDATE)'
        ELSE 'MODERATE CONFIDENCE (INSPECTION RECOMMENDED)'
    END AS matching_confidence_tier,
    
    'POSSIBLE MATCH CANDIDATE — PENDING PHYSICAL VERIFICATION' AS legal_disclaimer
    
FROM Lost_Items l
CROSS JOIN Found_Items f
INNER JOIN Users u_lost ON l.user_id = u_lost.user_id
INNER JOIN Locations loc_lost ON l.location_id = loc_lost.location_id
INNER JOIN Locations loc_found ON f.location_id = loc_found.location_id
WHERE l.category = f.category
  AND f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 30
  AND l.status != 'RETURNED'
  AND f.status != 'CLAIMED'
  -- Mandatory keyword overlap condition (eliminates false matches between unrelated items)
  AND (
      LOWER(f.item_name) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%')
      OR LOWER(f.description) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%')
      OR (LOWER(l.item_name) LIKE '%calculator%' AND LOWER(f.item_name) LIKE '%calculator%')
      OR (LOWER(l.item_name) LIKE '%wallet%' AND LOWER(f.item_name) LIKE '%wallet%')
      OR (LOWER(l.item_name) LIKE '%earbuds%' AND LOWER(f.item_name) LIKE '%earbuds%')
      OR (LOWER(l.item_name) LIKE '%key%' AND LOWER(f.item_name) LIKE '%key%')
      OR (LOWER(l.item_name) LIKE '%adapter%' AND LOWER(f.item_name) LIKE '%adapter%')
      OR (LOWER(l.item_name) LIKE '%textbook%' AND LOWER(f.item_name) LIKE '%textbook%')
      OR (LOWER(l.item_name) LIKE '%bottle%' AND LOWER(f.item_name) LIKE '%bottle%')
      OR (LOWER(l.item_name) LIKE '%mouse%' AND LOWER(f.item_name) LIKE '%mouse%')
      OR (LOWER(l.item_name) LIKE '%sunglasses%' AND LOWER(f.item_name) LIKE '%sunglasses%')
      OR (LOWER(l.item_name) LIKE '%drive%' AND LOWER(f.item_name) LIKE '%drive%')
      OR (LOWER(l.item_name) LIKE '%bag%' AND LOWER(f.item_name) LIKE '%bag%')
      OR (LOWER(l.item_name) LIKE '%caliper%' AND LOWER(f.item_name) LIKE '%caliper%')
      OR (LOWER(l.item_name) LIKE '%keyboard%' AND LOWER(f.item_name) LIKE '%keyboard%')
      OR (LOWER(l.item_name) LIKE '%folder%' AND LOWER(f.item_name) LIKE '%folder%')
      OR (LOWER(l.item_name) LIKE '%smartwatch%' AND LOWER(f.item_name) LIKE '%smartwatch%')
      OR (LOWER(l.item_name) LIKE '%backpack%' AND LOWER(f.item_name) LIKE '%backpack%')
      OR (LOWER(l.item_name) LIKE '%wristwatch%' AND LOWER(f.item_name) LIKE '%wristwatch%')
      OR (LOWER(l.item_name) LIKE '%coat%' AND LOWER(f.item_name) LIKE '%coat%')
  )
HAVING total_match_score >= 45
ORDER BY total_match_score DESC, date_difference_days ASC;
