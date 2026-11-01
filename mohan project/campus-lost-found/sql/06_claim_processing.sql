-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 06_claim_processing.sql
-- Target DBMS: MySQL 8.0+
-- Description: ACID-compliant Transaction workflows demonstrating:
-- 1. Transaction 1: Filing a new ownership claim for an unclaimed found item
-- 2. Transaction 2: Approving a verified claim and closing the lifecycle
-- 3. Transaction 3: Error handling & simulated ROLLBACK on invalid claim state
-- 4. Transaction 4: Rejecting a fraudulent or mismatched claim
-- =====================================================================

USE campus_lost_found;

-- =====================================================================
-- ACID PROPERTIES THEORETICAL SUMMARY (VIVA DEFENSE):
-- - ATOMICITY: All state changes (insert claim, update found status, update lost status)
--   execute as a single atomic unit. If any statement fails, all changes revert.
-- - CONSISTENCY: Enforces foreign key constraints and CHECK constraints before commit.
-- - ISOLATION: Locks modified rows to prevent concurrent conflicting claims.
-- - DURABILITY: Once committed, changes are written to redo logs and persist permanently.
-- =====================================================================


-- =====================================================================
-- WORKFLOW 1: SUBMITTING A NEW CLAIM
-- Scenario: Student Vikram Singh (user_id = 5) files a claim for the bicycle key
-- found at Football Ground (found_id = 5), linking his lost report (lost_id = 5).
-- =====================================================================

START TRANSACTION;

-- Step 1: Ensure found item is available (UNCLAIMED)
SELECT found_id, item_name, status, storage_place 
FROM Found_Items 
WHERE found_id = 5 AND status = 'UNCLAIMED'
FOR UPDATE; -- Row-level exclusive lock for concurrency safety

-- Step 2: Insert into Claims table
INSERT INTO Claims (found_id, claimant_id, lost_id, verification_proof, claim_status)
VALUES (
    5, 
    5, 
    5, 
    'Physical key matches my Hero Sprint cycle lock. Lock was tested at hostel cycle stand.', 
    'PENDING'
);

-- Step 3: Transition Found_Items status to CLAIM_PENDING
UPDATE Found_Items 
SET status = 'CLAIM_PENDING'
WHERE found_id = 5;

-- Step 4: Transition Lost_Items status to POSSIBLE_MATCH
UPDATE Lost_Items 
SET status = 'POSSIBLE_MATCH'
WHERE lost_id = 5;

-- Commit transaction
COMMIT;

-- Verify results of Workflow 1
SELECT 
    c.claim_id, 
    c.claim_status, 
    f.item_name AS found_item, 
    f.status AS found_status, 
    l.status AS lost_status
FROM Claims c
INNER JOIN Found_Items f ON c.found_id = f.found_id
INNER JOIN Lost_Items l ON c.lost_id = l.lost_id
WHERE c.found_id = 5;


-- =====================================================================
-- WORKFLOW 2: APPROVING A CLAIM & RETURNING PROPERTY
-- Scenario: Security Officer Ramesh Yadav (user_id = 8) verifies claimant proof
-- for Found Item #1 (Casio FX-991EX Calculator) claimed by Aarav Sharma (claim_id = 2).
-- =====================================================================

START TRANSACTION;

-- Step 1: Lock the claim record for resolution
SELECT claim_id, found_id, lost_id, claim_status 
FROM Claims 
WHERE claim_id = 2 
FOR UPDATE;

-- Step 2: Update Claim record to APPROVED with resolution audit details
UPDATE Claims 
SET 
    claim_status = 'APPROVED',
    resolved_by_staff_id = 8,
    resolution_notes = 'Original retail invoice inspected. Serial number matches calculator battery compartment stamp. Item released.',
    resolved_at = CURRENT_TIMESTAMP
WHERE claim_id = 2;

-- Step 3: Mark Found Item as CLAIMED
UPDATE Found_Items 
SET status = 'CLAIMED'
WHERE found_id = 1;

-- Step 4: Mark corresponding Lost Item as RETURNED
UPDATE Lost_Items 
SET status = 'RETURNED'
WHERE lost_id = 1;

-- Commit all changes together
COMMIT;

-- Verify results of Workflow 2
SELECT 
    c.claim_id, 
    c.claim_status, 
    c.resolved_at,
    f.status AS found_item_status, 
    l.status AS lost_item_status
FROM Claims c
INNER JOIN Found_Items f ON c.found_id = f.found_id
LEFT JOIN Lost_Items l ON c.lost_id = l.lost_id
WHERE c.claim_id = 2;


-- =====================================================================
-- WORKFLOW 3: ERROR SIMULATION & ROLLBACK DEMONSTRATION
-- Scenario: Attempting to file a claim on an item that has ALREADY been claimed.
-- When the condition check detects invalid state, we ROLLBACK to leave the database clean.
-- =====================================================================

START TRANSACTION;

-- 1. Inspect found item status
SET @target_found_id = 4; -- Found Item #4 is already CLAIMED
SELECT status INTO @current_status FROM Found_Items WHERE found_id = @target_found_id;

-- 2. Attempt invalid insert
INSERT INTO Claims (found_id, claimant_id, lost_id, verification_proof, claim_status)
VALUES (@target_found_id, 3, NULL, 'Duplicate conflicting claim attempt', 'PENDING');

-- 3. Check business rule: If status was already CLAIMED, abort!
-- In production application logic or stored procedures:
SELECT 
    CASE 
        WHEN @current_status = 'CLAIMED' THEN 'ERROR: Item is already claimed! Aborting transaction.'
        ELSE 'OK: Proceeding'
    END AS transaction_validation_check;

-- Execute ROLLBACK to cancel changes
ROLLBACK;

-- Verify that no orphan claim row was created for found_id = 4
SELECT COUNT(*) AS total_claims_for_item_4 
FROM Claims 
WHERE found_id = 4 AND verification_proof = 'Duplicate conflicting claim attempt';


-- =====================================================================
-- WORKFLOW 4: REJECTING A CLAIM
-- Scenario: A claim is reviewed and fails verification (e.g., incorrect description).
-- The Claim is updated to REJECTED, and the Found Item is returned to UNCLAIMED.
-- =====================================================================

START TRANSACTION;

-- Update claim status to REJECTED
UPDATE Claims 
SET 
    claim_status = 'REJECTED',
    resolved_by_staff_id = 8,
    resolution_notes = 'Claimant failed to identify color of interior wallet lining. Ownership rejected.',
    resolved_at = CURRENT_TIMESTAMP
WHERE claim_id = 3;

-- Revert Found Item status back to UNCLAIMED so others can claim or match
UPDATE Found_Items 
SET status = 'UNCLAIMED'
WHERE found_id = 2;

-- Revert Lost Item status back to REPORTED
UPDATE Lost_Items 
SET status = 'REPORTED'
WHERE lost_id = 2;

COMMIT;

-- Verify final status of Workflow 4
SELECT 
    claim_id, 
    claim_status, 
    resolution_notes 
FROM Claims 
WHERE claim_id = 3;
