# Campus Lost-and-Found Record Matching System
## B.Tech Computer Science & Engineering — DBMS Minor Project Report

---

### Academic Information
- **Project Title:** Campus Lost-and-Found Record Matching System
- **Database Engine:** MySQL 8.0+
- **Frontend Stack:** HTML5, Vanilla CSS3, Vanilla JavaScript (Decoupled In-Memory Simulation)
- **Target DBMS Tool:** MySQL Workbench 8.0+
- **Project Paradigm:** Decoupled Architecture (No Server-Side Middleware / No REST APIs)

---

## 1. Project Abstract
Campus environments frequently witness misplaced or forgotten personal items such as identity cards, calculators, electronics, backpacks, keys, and books. Conventional physical lost-and-found registers managed by security desks suffer from poor visibility, manual record inspection delays, duplicate entries, and lack of systematic matching algorithms. 

This project presents a database-driven **Campus Lost-and-Found Record Matching System** designed to bridge this gap. The system captures structured reports of lost and turned-in belongings, associates them with campus members and physical locations, and executes multi-criteria matching queries to compute match confidence scores based on item category, physical location proximity, temporal date constraints, and keyword overlaps. In strict compliance with the DBMS minor project guidelines, the system incorporates a standalone, highly responsive web dashboard for frontend demonstration and an enterprise-grade MySQL 8.0 relational schema featuring primary/foreign key constraints, CHECK constraints, performance indexes, analytical views, and ACID-compliant transaction workflows.

---

## 2. Problem Statement & Motivation
In large academic institutions with thousands of daily visitors, recovering lost property is hindered by several operational problems:
1. **Dispersed Registries:** Different departments, campus libraries, hostels, and cafeteria counters maintain disconnected, handwritten logbooks.
2. **Inconsistent Descriptions:** A student reporting a lost "Casio FX-991EX ClassWiz" may not find it if the finder logs it simply as "Scientific Calculator".
3. **Absence of Temporal & Spatial Filtering:** Manual searches fail to check whether an item was found in the same or adjacent building shortly after loss.
4. **Weak Verification & Risk of Misappropriation:** Handing over items without formal proof of ownership or audit logging creates security vulnerabilities.
5. **Lack of Lifecycle Tracking:** Items sit indefinitely in storage cabinets without status updates (unclaimed vs. claimed vs. disposed).

A relational database system with structured candidate matching queries and transactional state enforcement resolves these operational bottlenecks.

---

## 3. Project Objectives
- Design a normalized, BCNF-compliant relational database schema named `campus_lost_found`.
- Implement constraints (Primary Keys, Foreign Keys, Unique Keys, NOT NULL, CHECK constraints) to guarantee referential integrity.
- Populate the database with realistic campus test data (12 users, 10 locations, 22 lost reports, 22 found records, and 6 claims).
- Develop multi-factor matching algorithms in SQL comparing categories, campus zones, date windows, and keywords.
- Create modular database views (`vw_unresolved_lost_items`, `vw_unclaimed_found_items`, `vw_possible_matches`).
- Construct ACID transaction scripts simulating claim verification, approval, rollback on error, and rejection.
- Build an interactive, client-side frontend demonstration with zero backend dependencies to illustrate the user experience, search, filtering, and scoring logic.

---

## 4. System Architecture (Decoupled Design)

Following project constraints, backend server frameworks (Node.js, Express, PHP, Python, Java) and server-side database connectors were excluded. The system employs a clean **decoupled architecture**:

```
+-------------------------------------------------------------+
|                     PRESENTATION TIER                       |
|   HTML5 + Vanilla CSS3 + Vanilla JavaScript (app.js)        |
|  - Real-time client-side search, filtering, and sorting     |
|  - Dynamic dashboard counters & category progress bars      |
|  - Client-side matching scoring simulation (0-100%)         |
|  - In-memory demonstration mock state (data.js)             |
+-------------------------------------------------------------+
                              ||
                    [DECOUPLED BOUNDARY]
    (No HTTP REST APIs / No Server-Side Connectors Used)
                              ||
+-------------------------------------------------------------+
|                     DATABASE TIER                           |
|               MySQL 8.0 Engine / InnoDB                     |
|  - Database: campus_lost_found                              |
|  - 5 Normalized Relations (Users, Locations, Lost, Found,   |
|    Claims) with Referential Integrity & CHECK Constraints   |
|  - Multi-Criteria Matching Queries & Scoring CASE WHEN      |
|  - Database Views & ACID Transaction Workflows              |
|  - Executed natively via MySQL Workbench                    |
+-------------------------------------------------------------+
```

---

## 5. Relational Database Design

### 5.1 Tables & Schema Specifications

#### 1. `Users`
Stores students, faculty, administrative staff, and security personnel.
- `user_id` (INT, AUTO_INCREMENT, PK)
- `student_or_staff_id` (VARCHAR(30), UNIQUE, NOT NULL)
- `full_name` (VARCHAR(100), NOT NULL)
- `email` (VARCHAR(100), UNIQUE, NOT NULL)
- `phone` (VARCHAR(15), NOT NULL)
- `department` (VARCHAR(50), NOT NULL)
- `user_type` (VARCHAR(20), NOT NULL, `CHECK (user_type IN ('STUDENT', 'FACULTY', 'STAFF', 'SECURITY'))`)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

#### 2. `Locations`
Standardizes campus locations, buildings, and zones.
- `location_id` (INT, AUTO_INCREMENT, PK)
- `location_name` (VARCHAR(100), UNIQUE, NOT NULL)
- `building` (VARCHAR(100), NOT NULL)
- `floor_number` (VARCHAR(20), DEFAULT 'Ground Floor')
- `zone_type` (VARCHAR(30), NOT NULL, `CHECK (zone_type IN ('ACADEMIC', 'LIBRARY', 'SPORTS', 'CANTEEN', 'HOSTEL', 'ADMIN', 'LABORATORY'))`)
- `custodian_contact` (VARCHAR(50))
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

#### 3. `Lost_Items`
Maintains user-reported lost items.
- `lost_id` (INT, AUTO_INCREMENT, PK)
- `user_id` (INT, NOT NULL, FK $\rightarrow$ `Users.user_id` ON DELETE CASCADE)
- `item_name` (VARCHAR(100), NOT NULL)
- `category` (VARCHAR(30), NOT NULL, `CHECK (category IN ('ELECTRONICS', 'CARDS_ID', 'BAGS_WALLETS', 'KEYS', 'BOOKS_STATIONERY', 'ACCESSORIES', 'DOCUMENTS', 'OTHER'))`)
- `description` (TEXT, NOT NULL)
- `location_id` (INT, NOT NULL, FK $\rightarrow$ `Locations.location_id` ON DELETE RESTRICT)
- `lost_date` (DATE, NOT NULL)
- `status` (VARCHAR(20), NOT NULL DEFAULT 'REPORTED', `CHECK (status IN ('REPORTED', 'POSSIBLE_MATCH', 'RETURNED', 'CLOSED'))`)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

#### 4. `Found_Items`
Maintains recovered items and official custody details.
- `found_id` (INT, AUTO_INCREMENT, PK)
- `finder_id` (INT, NOT NULL, FK $\rightarrow$ `Users.user_id` ON DELETE CASCADE)
- `item_name` (VARCHAR(100), NOT NULL)
- `category` (VARCHAR(30), NOT NULL, `CHECK (category IN ('ELECTRONICS', 'CARDS_ID', 'BAGS_WALLETS', 'KEYS', 'BOOKS_STATIONERY', 'ACCESSORIES', 'DOCUMENTS', 'OTHER'))`)
- `description` (TEXT, NOT NULL)
- `location_id` (INT, NOT NULL, FK $\rightarrow$ `Locations.location_id` ON DELETE RESTRICT)
- `found_date` (DATE, NOT NULL)
- `storage_place` (VARCHAR(120), NOT NULL DEFAULT 'Campus Security Lost & Found Desk')
- `status` (VARCHAR(20), NOT NULL DEFAULT 'UNCLAIMED', `CHECK (status IN ('UNCLAIMED', 'CLAIM_PENDING', 'CLAIMED', 'DISPOSED'))`)
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

#### 5. `Claims`
Associative entity recording ownership verification claims.
- `claim_id` (INT, AUTO_INCREMENT, PK)
- `found_id` (INT, NOT NULL, FK $\rightarrow$ `Found_Items.found_id` ON DELETE CASCADE)
- `claimant_id` (INT, NOT NULL, FK $\rightarrow$ `Users.user_id` ON DELETE CASCADE)
- `lost_id` (INT, NULLABLE, FK $\rightarrow$ `Lost_Items.lost_id` ON DELETE SET NULL)
- `claim_date` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- `verification_proof` (TEXT, NOT NULL)
- `claim_status` (VARCHAR(20), NOT NULL DEFAULT 'PENDING', `CHECK (claim_status IN ('PENDING', 'VERIFIED', 'APPROVED', 'REJECTED'))`)
- `resolved_by_staff_id` (INT, NULLABLE, FK $\rightarrow$ `Users.user_id` ON DELETE SET NULL)
- `resolution_notes` (TEXT)
- `resolved_at` (TIMESTAMP, NULLABLE)

---

## 6. Normalization Analysis

### First Normal Form (1NF)
1. **Atomicity:** All attributes contain indivisible values. Phone numbers and names are atomic strings; dates and timestamps are discrete SQL date/time types.
2. **No Repeating Groups:** Each record contains a fixed number of columns.
3. **Primary Key Defined:** Every entity has an explicit integer primary key.
**Result:** 1NF is fully satisfied.

### Second Normal Form (2NF)
1. The schema is in 1NF.
2. **No Partial Functional Dependencies:** A partial dependency occurs only when a relation has a composite primary key and a non-prime attribute depends on a proper subset of that candidate key. Since all five tables in `campus_lost_found` use single-attribute surrogate primary keys (`user_id`, `location_id`, `lost_id`, `found_id`, `claim_id`), partial dependency cannot exist.
**Result:** 2NF is mathematically satisfied.

### Third Normal Form (3NF)
1. The schema is in 2NF.
2. **No Transitive Functional Dependencies:** In `Lost_Items` and `Found_Items`, building names and zones are not stored in the items tables; they are referenced through `location_id`.
   - Without normalization: $\text{lost\_id} \rightarrow \text{location\_name} \rightarrow \text{building}$ (Transitive Dependency).
   - Normalized: $\text{lost\_id} \rightarrow \text{location\_id}$ in `Lost_Items`, and $\text{location\_id} \rightarrow \text{building}$ in `Locations`.
3. Claimant and finder personal details are not stored in `Lost_Items` or `Claims`; they reside exclusively in `Users`.
**Result:** 3NF is strictly satisfied.

### Boyce-Codd Normal Form (BCNF)
A relation $R$ is in BCNF if for every functional dependency $X \rightarrow Y$, $X$ is a superkey.
- In `Users`: Non-trivial functional dependencies are $\text{user\_id} \rightarrow \text{attributes}$, $\text{student\_or\_staff\_id} \rightarrow \text{attributes}$, and $\text{email} \rightarrow \text{attributes}$. All determinants are candidate keys.
- In `Locations`: $\text{location\_id} \rightarrow \text{attributes}$ and $\text{location\_name} \rightarrow \text{attributes}$. All determinants are candidate keys.
- In `Lost_Items`, `Found_Items`, and `Claims`: All determinants are primary keys or candidate keys.
**Result:** The entire database schema satisfies BCNF.

---

## 7. Matching Queries & Algorithm Implementation

The core algorithm compares reported losses with turned-in property across four independent dimensions:

$$\text{Total Match Score} = S_{\text{Category}} + S_{\text{Location}} + S_{\text{Date}} + S_{\text{Keywords}}$$

1. **Category Score ($S_{\text{Category}}$, 35 pts):**
   - Exact category match is required: $\text{IF } l.category = f.category \text{ THEN } 35 \text{ ELSE } 0$.
2. **Location Proximity ($S_{\text{Location}}$, 25 pts):**
   - Exact location match awards 25 points.
   - Cross-campus displacement awards 5 points partial credit (recognizing items can be moved by good samaritans).
3. **Date Consistency ($S_{\text{Date}}$, 20 pts):**
   - Requires $f.found\_date \ge l.lost\_date$.
   - $\le 3$ days difference: 20 points.
   - $\le 7$ days difference: 15 points.
   - $\le 14$ days difference: 10 points.
   - $> 14$ days difference: 5 points.
   - If found before lost date: 0 points (date anomaly).
4. **Keyword Similarity ($S_{\text{Keywords}}$, 20 pts):**
   - Evaluates tokenized brand names and distinguishing physical traits (e.g. `casio`, `calculator`, `airdopes`, `wallet`, `lanyard`, `keys`) using `LIKE` pattern matching.

### SQL Implementation Sample (`CASE WHEN` Multi-Factor Scoring)
```sql
SELECT 
    l.lost_id, l.item_name AS lost_item,
    f.found_id, f.item_name AS found_item,
    (
        (CASE WHEN l.category = f.category THEN 35 ELSE 0 END) +
        (CASE WHEN l.location_id = f.location_id THEN 25 ELSE 5 END) +
        (CASE 
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 3 THEN 20
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 7 THEN 15
            WHEN f.found_date >= l.lost_date AND DATEDIFF(f.found_date, l.lost_date) <= 14 THEN 10
            ELSE 5 
         END) +
        (CASE 
            WHEN LOWER(f.description) LIKE '%casio%' OR LOWER(f.description) LIKE '%wallet%' THEN 20
            ELSE 10 
         END)
    ) AS total_match_score,
    'POSSIBLE MATCH - PENDING VERIFICATION' AS match_status
FROM Lost_Items l
CROSS JOIN Found_Items f
WHERE l.category = f.category
  AND f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 14
HAVING total_match_score >= 50
ORDER BY total_match_score DESC;
```

---

## 8. Database Views

The database includes three required views and two administrative reporting views:

1. **`vw_unresolved_lost_items`**: Returns all lost reports with status `'REPORTED'` or `'POSSIBLE_MATCH'`, joined with reporter name, contact number, and last-seen building.
2. **`vw_unclaimed_found_items`**: Returns all found items with status `'UNCLAIMED'` or `'CLAIM_PENDING'`, joined with finder details, recovery spot, and physical custody desk.
3. **`vw_possible_matches`**: Encapsulates the multi-criteria matching query, returning prospective pairs with calculated match scores, elapsed days, and disclaimer labels.
4. **`vw_campus_lost_found_summary`**: High-level statistical aggregates (total lost, total found, active reports, returned items, approved claims) for executive dashboarding.
5. **`vw_location_hotspots`**: Ranks campus zones and buildings by lost/found incident frequency.

---

## 9. Transaction Processing & ACID Compliance

Script `06_claim_processing.sql` illustrates ACID properties in lifecycle transitions:

### Workflow: Approving a Verified Claim
```sql
START TRANSACTION;

-- Step 1: Lock the target claim record for modification
SELECT claim_id, found_id, lost_id, claim_status 
FROM Claims 
WHERE claim_id = 2 
FOR UPDATE;

-- Step 2: Update Claim record to APPROVED
UPDATE Claims 
SET claim_status = 'APPROVED',
    resolved_by_staff_id = 8,
    resolution_notes = 'Serial number verified against original invoice.',
    resolved_at = CURRENT_TIMESTAMP
WHERE claim_id = 2;

-- Step 3: Transition Found Item to CLAIMED
UPDATE Found_Items SET status = 'CLAIMED' WHERE found_id = 1;

-- Step 4: Transition Lost Item to RETURNED
UPDATE Lost_Items SET status = 'RETURNED' WHERE lost_id = 1;

COMMIT;
```

If an error or constraint violation occurs before `COMMIT`, the entire set of changes is rolled back with `ROLLBACK`, guaranteeing that no item is marked as claimed without an approved claim record.

---

## 10. How to Run & Test the Project

### 10.1 Running the Frontend
1. Open the project folder in your file explorer: `campus-lost-found/`.
2. Double-click `index.html` to open it in any modern browser (Google Chrome, Microsoft Edge, Mozilla Firefox).
3. Alternatively, right-click `index.html` and select **Open with Live Server** or standard browser.
4. Test features:
   - Navigate to **Browse Items** and test the search bar and category dropdown.
   - Navigate to **Report Lost** and submit a test record; verify toast alerts and updated counters.
   - Navigate to **Possible Matches** to inspect comparison cards and view corresponding SQL queries.
   - Navigate to **Manage & Claims** to test approving/rejecting claims.

### 10.2 Executing SQL in MySQL Workbench
1. Launch **MySQL Workbench** and establish a connection to your local MySQL 8.0 server (e.g., `localhost:3306`).
2. Execute the scripts in `sql/` in the following sequence:
   - `01_create_database.sql` $\rightarrow$ Creates database, tables, constraints, indexes.
   - `02_insert_sample_data.sql` $\rightarrow$ Inserts 12 users, 10 locations, 22 lost items, 22 found items, 6 claims.
   - `03_basic_queries.sql` $\rightarrow$ Tests CRUD, joins, GROUP BY, HAVING, and subqueries.
   - `04_matching_queries.sql` $\rightarrow$ Runs strict, flexible, and weighted multi-factor matching.
   - `05_views_and_reports.sql` $\rightarrow$ Creates views and generates summary reports.
   - `06_claim_processing.sql` $\rightarrow$ Demonstrates transaction commits and rollbacks.

---

## 11. Expected Query Results (Verification Benchmark)

| Script | Primary Operation | Expected Output |
| :--- | :--- | :--- |
| `01_create_database.sql` | `SHOW TABLES;` | 5 tables: `Claims`, `Found_Items`, `Locations`, `Lost_Items`, `Users` |
| `02_insert_sample_data.sql` | Verification Counts | Users: 12, Locations: 10, Lost_Items: 22, Found_Items: 22, Claims: 6 |
| `03_basic_queries.sql` | Category Summary | Grouped counts of items across 8 categories |
| `03_basic_queries.sql` | Location Hotspots | Top loss areas: Central Library, CS Lab 3, Cafeteria |
| `04_matching_queries.sql` | Strict Match Query | Exact matches: Lost #1 (Calculator) ↔ Found #1; Lost #2 (Wallet) ↔ Found #2 |
| `04_matching_queries.sql` | Weighted Scoring | Candidate pairs scored between 50% and 95% |
| `05_views_and_reports.sql` | `SELECT * FROM vw_possible_matches;` | Tabular prospective pairs with confidence scores and disclaimers |
| `06_claim_processing.sql` | Transaction Execution | Atomic update: Claim #2 marked APPROVED, Found #1 CLAIMED, Lost #1 RETURNED |

---

## 12. Limitations
- **Client-Side In-Memory Persistence:** Frontend demonstrations reside in browser memory and do not communicate directly with MySQL due to the exclusion of backend server languages.
- **Physical Verification Requirement:** System matches are probabilistic candidates; physical inspection remains necessary to confirm rightful ownership.
- **English Tokenization:** Keyword extraction is optimized for English descriptions; non-English terms are processed without linguistic stemming.

---

## 13. Future Enhancements
- **Backend API Gateway:** Developing a lightweight REST API (using Node.js Express or FastAPI) with JWT authentication and database connection pooling.
- **Image Recognition & Feature Embedding:** Integrating computer vision to compare photographs of turned-in items against reported losses.
- **Automated Campus Alerts:** Triggering automated email or SMS notifications when an item scoring $\ge 80\%$ is logged.
- **QR Code & RFID Integration:** Generating asset custody tags for campus security lockboxes.

---

## 14. Conclusion
The Campus Lost-and-Found Record Matching System successfully satisfies all academic and technical requirements for a B.Tech DBMS minor project. It demonstrates thorough database engineering principles—ranging from BCNF normalization and referential constraints to multi-factor candidate matching queries, views, and transaction controls—coupled with an intuitive, modern client-side frontend simulation.
