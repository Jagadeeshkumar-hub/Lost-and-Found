-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 01_create_database.sql
-- Target DBMS: MySQL 8.0+
-- Description: Creates the database schema, normalized tables,
-- primary keys, foreign keys, CHECK constraints, and performance indexes.
-- =====================================================================

-- Step 1: Drop existing database if re-running
DROP DATABASE IF EXISTS campus_lost_found;

-- Step 2: Create new database with utf8mb4 character set for multi-language support
CREATE DATABASE campus_lost_found
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE campus_lost_found;

-- =====================================================================
-- TABLE 1: Users
-- Represents campus students, faculty members, administrative staff,
-- and campus security officers involved in reporting, finding, or verifying items.
-- =====================================================================
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT,
    student_or_staff_id VARCHAR(30) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    department VARCHAR(50) NOT NULL,
    user_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_id UNIQUE (student_or_staff_id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT chk_user_type CHECK (user_type IN ('STUDENT', 'FACULTY', 'STAFF', 'SECURITY'))
) ENGINE=InnoDB;

-- =====================================================================
-- TABLE 2: Locations
-- Represents campus physical zones, buildings, reading halls, and labs
-- where items are lost or discovered.
-- =====================================================================
CREATE TABLE Locations (
    location_id INT AUTO_INCREMENT,
    location_name VARCHAR(100) NOT NULL,
    building VARCHAR(100) NOT NULL,
    floor_number VARCHAR(20) DEFAULT 'Ground Floor',
    zone_type VARCHAR(30) NOT NULL,
    custodian_contact VARCHAR(50) DEFAULT 'Campus Facilities Desk',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_location_name UNIQUE (location_name),
    CONSTRAINT chk_zone_type CHECK (zone_type IN ('ACADEMIC', 'LIBRARY', 'SPORTS', 'CANTEEN', 'HOSTEL', 'ADMIN', 'LABORATORY'))
) ENGINE=InnoDB;

-- =====================================================================
-- TABLE 3: Lost_Items
-- Records details of items lost by users, last-seen campus location,
-- date, category, and lifecycle state.
-- =====================================================================
CREATE TABLE Lost_Items (
    lost_id INT AUTO_INCREMENT,
    user_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    description TEXT NOT NULL,
    location_id INT NOT NULL,
    lost_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'REPORTED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT pk_lost_items PRIMARY KEY (lost_id),
    CONSTRAINT fk_lost_user FOREIGN KEY (user_id) 
        REFERENCES Users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_lost_location FOREIGN KEY (location_id) 
        REFERENCES Locations(location_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_lost_category CHECK (category IN (
        'ELECTRONICS', 'CARDS_ID', 'BAGS_WALLETS', 'KEYS', 
        'BOOKS_STATIONERY', 'ACCESSORIES', 'DOCUMENTS', 'OTHER'
    )),
    CONSTRAINT chk_lost_status CHECK (status IN (
        'REPORTED', 'POSSIBLE_MATCH', 'RETURNED', 'CLOSED'
    ))
) ENGINE=InnoDB;

-- =====================================================================
-- TABLE 4: Found_Items
-- Records details of items picked up on campus, turned in by good
-- samaritans or staff, along with safe storage desk info and status.
-- =====================================================================
CREATE TABLE Found_Items (
    found_id INT AUTO_INCREMENT,
    finder_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(30) NOT NULL,
    description TEXT NOT NULL,
    location_id INT NOT NULL,
    found_date DATE NOT NULL,
    storage_place VARCHAR(120) NOT NULL DEFAULT 'Campus Security Lost & Found Desk',
    status VARCHAR(20) NOT NULL DEFAULT 'UNCLAIMED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT pk_found_items PRIMARY KEY (found_id),
    CONSTRAINT fk_found_finder FOREIGN KEY (finder_id) 
        REFERENCES Users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_found_location FOREIGN KEY (location_id) 
        REFERENCES Locations(location_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_found_category CHECK (category IN (
        'ELECTRONICS', 'CARDS_ID', 'BAGS_WALLETS', 'KEYS', 
        'BOOKS_STATIONERY', 'ACCESSORIES', 'DOCUMENTS', 'OTHER'
    )),
    CONSTRAINT chk_found_status CHECK (status IN (
        'UNCLAIMED', 'CLAIM_PENDING', 'CLAIMED', 'DISPOSED'
    ))
) ENGINE=InnoDB;

-- =====================================================================
-- TABLE 5: Claims
-- Associative relationship tracking ownership verification claims
-- filed for found items. Links found item to claimant user and optional
-- lost item report.
-- =====================================================================
CREATE TABLE Claims (
    claim_id INT AUTO_INCREMENT,
    found_id INT NOT NULL,
    claimant_id INT NOT NULL,
    lost_id INT NULL,
    claim_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verification_proof TEXT NOT NULL,
    claim_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    resolved_by_staff_id INT NULL,
    resolution_notes TEXT,
    resolved_at TIMESTAMP NULL,
    
    -- Constraints
    CONSTRAINT pk_claims PRIMARY KEY (claim_id),
    CONSTRAINT fk_claims_found FOREIGN KEY (found_id) 
        REFERENCES Found_Items(found_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_claims_claimant FOREIGN KEY (claimant_id) 
        REFERENCES Users(user_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_claims_lost FOREIGN KEY (lost_id) 
        REFERENCES Lost_Items(lost_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    CONSTRAINT fk_claims_resolver FOREIGN KEY (resolved_by_staff_id) 
        REFERENCES Users(user_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    CONSTRAINT chk_claim_status CHECK (claim_status IN (
        'PENDING', 'VERIFIED', 'APPROVED', 'REJECTED'
    ))
) ENGINE=InnoDB;

-- =====================================================================
-- PERFORMANCE INDEXES
-- Optimize lookup performance for category matching, date range queries,
-- location filters, and status queries.
-- =====================================================================
CREATE INDEX idx_lost_category ON Lost_Items (category);
CREATE INDEX idx_lost_date ON Lost_Items (lost_date);
CREATE INDEX idx_lost_location ON Lost_Items (location_id);
CREATE INDEX idx_lost_status ON Lost_Items (status);

CREATE INDEX idx_found_category ON Found_Items (category);
CREATE INDEX idx_found_date ON Found_Items (found_date);
CREATE INDEX idx_found_location ON Found_Items (location_id);
CREATE INDEX idx_found_status ON Found_Items (status);

CREATE INDEX idx_claims_status ON Claims (claim_status);
CREATE INDEX idx_claims_found ON Claims (found_id);
CREATE INDEX idx_claims_claimant ON Claims (claimant_id);

-- Display confirmation of tables created
SHOW TABLES;
