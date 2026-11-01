-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 03_basic_queries.sql
-- Target DBMS: MySQL 8.0+
-- Description: Demonstrates core DBMS query capabilities:
-- 1. CRUD Operations (INSERT, SELECT, UPDATE, DELETE)
-- 2. Filtering & Pattern Matching (WHERE, LIKE, BETWEEN, IN, ORDER BY, LIMIT)
-- 3. Relational Joins (INNER JOIN, LEFT OUTER JOIN, Multi-table Joins)
-- 4. Aggregations & Grouping (COUNT, GROUP BY, HAVING, MIN, MAX)
-- 5. Subqueries (Scalar, Correlated, IN / NOT IN, EXISTS)
-- =====================================================================

USE campus_lost_found;

-- =====================================================================
-- SECTION 1: CRUD OPERATIONS (Create, Read, Update, Delete)
-- =====================================================================

-- 1.1 INSERT: Record a new lost report
INSERT INTO Lost_Items (user_id, item_name, category, description, location_id, lost_date, status)
VALUES (1, 'OnePlus Type-C Dash Cable Red', 'ELECTRONICS', 'Flat red fast charging wire with white USB-A tip.', 3, '2026-10-31', 'REPORTED');

-- Verify inserted row
SELECT * FROM Lost_Items WHERE item_name LIKE 'OnePlus%';

-- 1.2 UPDATE: Modify the status and location when an item is transferred
UPDATE Lost_Items 
SET status = 'POSSIBLE_MATCH'
WHERE lost_id = 6;

-- 1.3 DELETE: Delete the temporary test record inserted in 1.1
DELETE FROM Lost_Items 
WHERE item_name = 'OnePlus Type-C Dash Cable Red' AND user_id = 1;


-- =====================================================================
-- SECTION 2: FILTERING, SORTING & PATTERN MATCHING
-- =====================================================================

-- 2.1 Pattern Matching with LIKE: Search for electronic calculators or devices
SELECT 
    lost_id, 
    item_name, 
    category, 
    lost_date, 
    status
FROM Lost_Items
WHERE item_name LIKE '%Calculator%' OR description LIKE '%casio%'
ORDER BY lost_date DESC;

-- 2.2 Range filtering using BETWEEN: Belongings lost in late October 2026
SELECT 
    item_name, 
    category, 
    lost_date, 
    status 
FROM Lost_Items
WHERE lost_date BETWEEN '2026-10-25' AND '2026-10-31'
ORDER BY lost_date ASC;

-- 2.3 Multiple values using IN: Query specific priority categories
SELECT 
    found_id, 
    item_name, 
    category, 
    storage_place, 
    found_date
FROM Found_Items
WHERE category IN ('ELECTRONICS', 'CARDS_ID', 'DOCUMENTS')
ORDER BY found_date DESC
LIMIT 10;


-- =====================================================================
-- SECTION 3: RELATIONAL JOINS
-- =====================================================================

-- 3.1 INNER JOIN: Combine Lost Items with User (Reporter) and Location details
-- Concept: Returns only rows where matching keys exist in all three tables.
SELECT 
    l.lost_id,
    l.item_name AS lost_item,
    l.category,
    l.lost_date,
    l.status AS item_status,
    u.student_or_staff_id AS reporter_roll,
    u.full_name AS reporter_name,
    u.department AS reporter_dept,
    u.phone AS reporter_phone,
    loc.location_name AS last_seen_location,
    loc.building,
    loc.zone_type
FROM Lost_Items l
INNER JOIN Users u ON l.user_id = u.user_id
INNER JOIN Locations loc ON l.location_id = loc.location_id
ORDER BY l.lost_date DESC;

-- 3.2 LEFT OUTER JOIN: Retrieve Found Items along with any Claims filed
-- Concept: Shows all found items even if no claim has ever been filed for them.
SELECT 
    f.found_id,
    f.item_name AS found_item,
    f.category,
    f.found_date,
    f.status AS found_status,
    f.storage_place,
    c.claim_id,
    c.claim_status,
    c.claim_date,
    u_claimant.full_name AS claimant_name,
    u_claimant.student_or_staff_id AS claimant_id
FROM Found_Items f
LEFT JOIN Claims c ON f.found_id = c.found_id
LEFT JOIN Users u_claimant ON c.claimant_id = u_claimant.user_id
ORDER BY f.found_id ASC;

-- 3.3 Multi-Way Join with Staff Resolver: Complete Claim Audit Trail
SELECT 
    c.claim_id,
    c.claim_status,
    c.claim_date,
    f.item_name AS claimed_item,
    u_claimant.full_name AS claimant_name,
    u_claimant.department AS claimant_dept,
    u_resolver.full_name AS verified_by_officer,
    u_resolver.department AS security_division,
    c.resolution_notes
FROM Claims c
INNER JOIN Found_Items f ON c.found_id = f.found_id
INNER JOIN Users u_claimant ON c.claimant_id = u_claimant.user_id
LEFT JOIN Users u_resolver ON c.resolved_by_staff_id = u_resolver.user_id
ORDER BY c.claim_date DESC;


-- =====================================================================
-- SECTION 4: AGGREGATIONS & GROUPING (GROUP BY, COUNT, HAVING)
-- =====================================================================

-- 4.1 Category Breakdown: Count of Lost vs Found items per category
SELECT 
    COALESCE(l.category, f.category) AS item_category,
    COUNT(DISTINCT l.lost_id) AS total_lost_reported,
    COUNT(DISTINCT f.found_id) AS total_found_logged
FROM Lost_Items l
LEFT JOIN Found_Items f ON l.category = f.category
GROUP BY item_category
ORDER BY total_lost_reported DESC;

-- 4.2 Location Hotspots: Locations having 2 or more lost item reports (HAVING clause)
SELECT 
    loc.location_id,
    loc.location_name,
    loc.building,
    loc.zone_type,
    COUNT(l.lost_id) AS total_lost_incidents
FROM Locations loc
INNER JOIN Lost_Items l ON loc.location_id = l.location_id
GROUP BY loc.location_id, loc.location_name, loc.building, loc.zone_type
HAVING COUNT(l.lost_id) >= 2
ORDER BY total_lost_incidents DESC;

-- 4.3 Custody Status Summary: Aggregating Found items by status
SELECT 
    status,
    COUNT(*) AS total_items,
    MIN(found_date) AS earliest_date,
    MAX(found_date) AS latest_date
FROM Found_Items
GROUP BY status;


-- =====================================================================
-- SECTION 5: SUBQUERIES (Scalar, Correlated, IN / NOT IN, EXISTS)
-- =====================================================================

-- 5.1 IN Subquery: Find all Users who have reported lost Electronics
SELECT 
    user_id, 
    student_or_staff_id, 
    full_name, 
    email, 
    department 
FROM Users
WHERE user_id IN (
    SELECT DISTINCT user_id 
    FROM Lost_Items 
    WHERE category = 'ELECTRONICS'
);

-- 5.2 NOT IN Subquery: Find all Campus Locations where NO items have been lost yet
SELECT 
    location_id, 
    location_name, 
    building, 
    zone_type 
FROM Locations
WHERE location_id NOT IN (
    SELECT DISTINCT location_id 
    FROM Lost_Items
);

-- 5.3 Correlated Subquery: For each user, count how many active lost items they have
SELECT 
    u.user_id,
    u.full_name,
    u.user_type,
    (
        SELECT COUNT(*) 
        FROM Lost_Items l 
        WHERE l.user_id = u.user_id AND l.status = 'REPORTED'
    ) AS active_unresolved_reports
FROM Users u
WHERE u.user_type = 'STUDENT'
ORDER BY active_unresolved_reports DESC;

-- 5.4 EXISTS Subquery: Find Found items that currently have an active PENDING claim
SELECT 
    f.found_id,
    f.item_name,
    f.category,
    f.storage_place,
    f.found_date
FROM Found_Items f
WHERE EXISTS (
    SELECT 1 
    FROM Claims c 
    WHERE c.found_id = f.found_id AND c.claim_status = 'PENDING'
);
