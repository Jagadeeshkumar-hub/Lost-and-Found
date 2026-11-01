-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 05_views_and_reports.sql
-- Target DBMS: MySQL 8.0+
-- Description: Defines reusable database views and analytical reports:
-- 1. vw_unresolved_lost_items (All pending lost reports with reporter info)
-- 2. vw_unclaimed_found_items (All unclaimed found property with custody desk)
-- 3. vw_possible_matches (Cross-entity view joining potential pairs)
-- 4. vw_campus_lost_found_summary (Executive dashboard statistics)
-- 5. vw_location_hotspots (Incident density by campus building and zone)
-- =====================================================================

USE campus_lost_found;

-- =====================================================================
-- VIEW 1: vw_unresolved_lost_items
-- Retrieves active lost reports that are either newly REPORTED or flagged
-- as POSSIBLE_MATCH, along with reporter student/staff details.
-- =====================================================================
DROP VIEW IF EXISTS vw_unresolved_lost_items;

CREATE VIEW vw_unresolved_lost_items AS
SELECT 
    l.lost_id,
    l.item_name,
    l.category,
    l.description,
    l.lost_date,
    l.status AS lost_status,
    l.created_at AS report_timestamp,
    u.user_id AS reporter_user_id,
    u.student_or_staff_id AS reporter_id,
    u.full_name AS reporter_name,
    u.email AS reporter_email,
    u.phone AS reporter_phone,
    u.department AS reporter_department,
    u.user_type AS reporter_role,
    loc.location_id,
    loc.location_name AS last_seen_location,
    loc.building,
    loc.zone_type
FROM Lost_Items l
INNER JOIN Users u ON l.user_id = u.user_id
INNER JOIN Locations loc ON l.location_id = loc.location_id
WHERE l.status IN ('REPORTED', 'POSSIBLE_MATCH');


-- =====================================================================
-- VIEW 2: vw_unclaimed_found_items
-- Retrieves all found items currently held in campus custody where
-- no claim has been approved or property disposed.
-- =====================================================================
DROP VIEW IF EXISTS vw_unclaimed_found_items;

CREATE VIEW vw_unclaimed_found_items AS
SELECT 
    f.found_id,
    f.item_name,
    f.category,
    f.description,
    f.found_date,
    f.storage_place AS custody_location,
    f.status AS found_status,
    f.created_at AS logged_timestamp,
    u.student_or_staff_id AS finder_id,
    u.full_name AS finder_name,
    u.user_type AS finder_role,
    loc.location_id,
    loc.location_name AS recovery_location,
    loc.building,
    loc.zone_type
FROM Found_Items f
INNER JOIN Users u ON f.finder_id = u.user_id
INNER JOIN Locations loc ON f.location_id = loc.location_id
WHERE f.status IN ('UNCLAIMED', 'CLAIM_PENDING');


-- =====================================================================
-- VIEW 3: vw_possible_matches
-- Joins unresolved lost items with unclaimed found items based on
-- matching category and temporally valid date window (Found >= Lost
-- within 14 days), computing match score and comparison reasons.
-- =====================================================================
DROP VIEW IF EXISTS vw_possible_matches;

CREATE VIEW vw_possible_matches AS
SELECT 
    l.lost_id,
    l.item_name AS lost_item_name,
    l.category,
    l.lost_date,
    u_lost.full_name AS owner_name,
    u_lost.student_or_staff_id AS owner_roll,
    u_lost.phone AS student_phone,
    u_lost.email AS student_email,
    loc_lost.location_name AS lost_location_name,
    f.found_id,
    f.item_name AS found_item_name,
    f.found_date,
    f.storage_place AS custody_location,
    u_found.full_name AS finder_name,
    loc_found.location_name AS found_location_name,
    DATEDIFF(f.found_date, l.lost_date) AS days_between_loss_and_recovery,
    -- High-Precision Multi-Factor Scoring (0-100 pts)
    (
        25 + -- Base category match (guaranteed by ON clause)
        (CASE 
            WHEN l.location_id = f.location_id THEN 20 
            WHEN loc_lost.building = loc_found.building THEN 10
            ELSE 3 
         END) +
        (CASE 
            WHEN DATEDIFF(f.found_date, l.lost_date) <= 1 THEN 15
            WHEN DATEDIFF(f.found_date, l.lost_date) <= 4 THEN 11
            WHEN DATEDIFF(f.found_date, l.lost_date) <= 7 THEN 8
            WHEN DATEDIFF(f.found_date, l.lost_date) <= 14 THEN 5
            WHEN DATEDIFF(f.found_date, l.lost_date) <= 30 THEN 2
            ELSE 0
         END) +
        (CASE 
            WHEN LOWER(l.item_name) = LOWER(f.item_name) THEN 40
            WHEN LOWER(f.item_name) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 30
            WHEN LOWER(f.description) LIKE CONCAT('%', SUBSTRING_INDEX(l.item_name, ' ', 1), '%') THEN 22
            ELSE 14
         END)
    ) AS match_confidence_score,
    'POSSIBLE MATCH (SUBJECT TO PHYSICAL VERIFICATION)' AS match_classification
FROM Lost_Items l
INNER JOIN Found_Items f ON l.category = f.category
INNER JOIN Users u_lost ON l.user_id = u_lost.user_id
INNER JOIN Users u_found ON f.finder_id = u_found.user_id
INNER JOIN Locations loc_lost ON l.location_id = loc_lost.location_id
INNER JOIN Locations loc_found ON f.location_id = loc_found.location_id
WHERE l.status IN ('REPORTED', 'POSSIBLE_MATCH')
  AND f.status IN ('UNCLAIMED', 'CLAIM_PENDING')
  AND f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 30
  -- Enforce keyword/subject overlap so unrelated items are not falsely joined
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
  );


-- =====================================================================
-- VIEW 4: vw_campus_lost_found_summary
-- Generates aggregate metrics for executive dashboard reporting.
-- =====================================================================
DROP VIEW IF EXISTS vw_campus_lost_found_summary;

CREATE VIEW vw_campus_lost_found_summary AS
SELECT 
    (SELECT COUNT(*) FROM Lost_Items) AS total_lost_items_logged,
    (SELECT COUNT(*) FROM Found_Items) AS total_found_items_logged,
    (SELECT COUNT(*) FROM Lost_Items WHERE status = 'REPORTED') AS active_unresolved_lost,
    (SELECT COUNT(*) FROM Found_Items WHERE status = 'UNCLAIMED') AS active_unclaimed_found,
    (SELECT COUNT(*) FROM Lost_Items WHERE status = 'RETURNED') AS successfully_returned_items,
    (SELECT COUNT(*) FROM Claims WHERE claim_status = 'APPROVED') AS approved_claims_count,
    (SELECT COUNT(*) FROM Claims WHERE claim_status = 'PENDING') AS pending_claims_count;


-- =====================================================================
-- VIEW 5: vw_location_hotspots
-- Summarizes incident density across campus facilities.
-- =====================================================================
DROP VIEW IF EXISTS vw_location_hotspots;

CREATE VIEW vw_location_hotspots AS
SELECT 
    loc.location_id,
    loc.location_name,
    loc.building,
    loc.zone_type,
    COUNT(DISTINCT l.lost_id) AS lost_items_count,
    COUNT(DISTINCT f.found_id) AS found_items_count,
    (COUNT(DISTINCT l.lost_id) + COUNT(DISTINCT f.found_id)) AS total_incidents
FROM Locations loc
LEFT JOIN Lost_Items l ON loc.location_id = l.location_id
LEFT JOIN Found_Items f ON loc.location_id = f.location_id
GROUP BY loc.location_id, loc.location_name, loc.building, loc.zone_type
ORDER BY total_incidents DESC;


-- =====================================================================
-- VERIFICATION QUERIES ON CREATED VIEWS
-- =====================================================================

-- 1. Query unresolved lost items
SELECT * FROM vw_unresolved_lost_items LIMIT 5;

-- 2. Query unclaimed found items
SELECT * FROM vw_unclaimed_found_items LIMIT 5;

-- 3. Query calculated possible matches
SELECT 
    lost_id, 
    lost_item_name, 
    found_id, 
    found_item_name, 
    days_between_loss_and_recovery, 
    match_confidence_score, 
    match_classification
FROM vw_possible_matches
ORDER BY match_confidence_score DESC;

-- 4. Query executive summary dashboard
SELECT * FROM vw_campus_lost_found_summary;

-- 5. Query campus location hotspots
SELECT * FROM vw_location_hotspots;
