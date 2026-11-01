# Campus Lost-and-Found Record Matching System
## B.Tech Computer Science & Engineering — DBMS Minor Project

[![Database: MySQL 8.0](https://img.shields.io/badge/Database-MySQL%208.0-blue.svg)](https://www.mysql.com/)
[![Frontend: HTML5/CSS3/Vanilla JS](https://img.shields.io/badge/Frontend-HTML5%20%7C%20CSS3%20%7C%20JS-orange.svg)](#frontend-quickstart)
[![Architecture: Decoupled Simulation](https://img.shields.io/badge/Architecture-Decoupled%20Simulation-success.svg)](#architecture-note)

A complete, production-grade B.Tech DBMS minor project demonstrating a campus lost and found record matching system using **HTML5, Vanilla CSS3, Vanilla JavaScript**, and **MySQL 8.0 SQL scripts**.

---

## ⚠️ Important Architectural Note
This project strictly complies with the academic requirement that **no backend server, middleware, or REST APIs (Node.js, Express, PHP, Python, Java, etc.) be used**. 

Accordingly, the system operates as two decoupled, independently functional components:
1. **Interactive Frontend Demonstration (`index.html`, `style.css`, `app.js`, `data.js`):** A standalone web application running purely in the browser with in-memory demonstration records simulating the relational database experience.
2. **Complete MySQL 8.0 Database Implementation (`sql/`):** Six modular SQL scripts containing the normalized schema, sample data, CRUD queries, joins, multi-factor matching algorithms, views, and ACID transaction workflows executed in MySQL Workbench.

---

## 📁 Project Directory Structure

```
campus-lost-found/
├── index.html                   # Main responsive web application dashboard
├── style.css                    # Modern CSS3 styling (vanilla CSS, clean UI)
├── app.js                       # Frontend interactive logic, filters, and match engine
├── data.js                      # In-memory mock records mirroring the MySQL database
│
├── sql/
│   ├── 01_create_database.sql   # Creates schema, 5 tables, constraints & indexes
│   ├── 02_insert_sample_data.sql# 12 users, 10 locations, 22 lost, 22 found, 6 claims
│   ├── 03_basic_queries.sql     # CRUD, WHERE, LIKE, JOINs, GROUP BY, Subqueries
│   ├── 04_matching_queries.sql  # Strict, flexible, keyword & weighted matching queries
│   ├── 05_views_and_reports.sql # Views: unresolved lost, unclaimed found, possible matches
│   └── 06_claim_processing.sql  # ACID transaction workflows (Commit, Rollback, Lock)
│
└── docs/
    ├── README.md                # Quickstart and overview documentation (this file)
    ├── PROJECT_REPORT.md        # Comprehensive academic minor project report
    ├── ER_DIAGRAM.md            # Visual Mermaid diagram, ASCII diagram, and normalization
    └── VIVA_QUESTIONS.md        # 30 high-scoring viva questions with concise answers
```

---

## 🚀 Frontend Quickstart

No web server, package installation, or command-line build steps are required.

1. Navigate to the `campus-lost-found/` directory on your computer.
2. Double-click **`index.html`** or right-click $\rightarrow$ **Open with Google Chrome / Microsoft Edge / Firefox**.
3. Explore the interactive tabs:
   - **📊 Dashboard:** View real-time metric cards, category distribution bars, and live activity streams.
   - **🔍 Browse Items:** Search by keyword, filter by category, location, or status, and sort by date.
   - **🚨 Report Lost:** Submit a new lost item report and see the in-memory state update instantly.
   - **📦 Report Found:** Log a discovered item deposited at a campus security custody desk.
   - **⚡ Possible Matches:** Inspect side-by-side comparison cards with match scores, criteria chips, and MySQL query equivalents.
   - **📋 Manage & Claims:** Test claim approvals, rejections, and status transitions.
   - **🗄️ SQL & Docs:** Review database schema details and script documentation.

---

## 🗄️ MySQL Workbench Execution Guide

### Prerequisites
- MySQL Community Server 8.0+ installed and running.
- MySQL Workbench 8.0+ installed.

### Step-by-Step Script Execution Order
Open MySQL Workbench, connect to your local MySQL instance (e.g., `localhost:3306`), and execute the scripts in order:

1. **`sql/01_create_database.sql`**
   - Click **File > Open SQL Script...** and select `01_create_database.sql`.
   - Click the ⚡ **Execute** icon (Ctrl + Shift + Enter).
   - Creates the `campus_lost_found` database, 5 normalized tables (`Users`, `Locations`, `Lost_Items`, `Found_Items`, `Claims`), foreign keys, CHECK constraints, and B-Tree indexes.

2. **`sql/02_insert_sample_data.sql`**
   - Populates the database with 12 campus users, 10 locations, 22 lost items, 22 found items, and 6 claims.
   - Returns a confirmation count table verifying all rows were loaded.

3. **`sql/03_basic_queries.sql`**
   - Demonstrates CRUD operations, pattern matching with `LIKE`, `INNER JOIN`, `LEFT JOIN`, `GROUP BY`, `HAVING`, and correlated subqueries.

4. **`sql/04_matching_queries.sql`**
   - Executes the core matching algorithms:
     - Strict Match (exact category, exact location, date $\le 7$ days).
     - Flexible Match (cross-campus movement allowed, date $\le 14$ days).
     - Keyword Search Match (pattern matching on descriptions).
     - Weighted Multi-Factor Score Query (calculates 0-100% confidence score).

5. **`sql/05_views_and_reports.sql`**
   - Creates the required views: `vw_unresolved_lost_items`, `vw_unclaimed_found_items`, and `vw_possible_matches`.
   - Runs analytical reports summarizing campus lost-and-found hotspots.

6. **`sql/06_claim_processing.sql`**
   - Demonstrates ACID transaction processing: `START TRANSACTION`, row-level locking via `FOR UPDATE`, atomic updates across `Claims`, `Found_Items`, and `Lost_Items`, `COMMIT`, and error simulation with `ROLLBACK`.

---

## 🔍 Most Important SQL Queries to Demonstrate

During your practical viva or project demonstration, highlight these three key queries:

### 1. Multi-Factor Match Scoring Query (`sql/04_matching_queries.sql`)
Demonstrates how category, location, date proximity, and keyword matching are combined into a single weighted score using `CASE WHEN`:
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
    ) AS calculated_match_score,
    'POSSIBLE MATCH - PENDING VERIFICATION' AS match_status_label
FROM Lost_Items l
CROSS JOIN Found_Items f
WHERE l.category = f.category
  AND f.found_date >= l.lost_date
  AND DATEDIFF(f.found_date, l.lost_date) <= 14
HAVING calculated_match_score >= 50
ORDER BY calculated_match_score DESC;
```

### 2. The Possible Matches View (`sql/05_views_and_reports.sql`)
Demonstrates relational encapsulation of candidate matching:
```sql
SELECT * FROM vw_possible_matches WHERE match_confidence_score >= 70;
```

### 3. ACID Transaction for Claim Approval (`sql/06_claim_processing.sql`)
Demonstrates atomicity and state transition consistency:
```sql
START TRANSACTION;
UPDATE Claims SET claim_status = 'APPROVED', resolved_by_staff_id = 8, resolved_at = CURRENT_TIMESTAMP WHERE claim_id = 2;
UPDATE Found_Items SET status = 'CLAIMED' WHERE found_id = 1;
UPDATE Lost_Items SET status = 'RETURNED' WHERE lost_id = 1;
COMMIT;
```

---

## ⏱️ 3-Minute Project Demonstration Plan

1. **Minute 1 — Problem & Frontend Overview:**
   - Open `index.html`. Show the clean academic dashboard and counter cards.
   - Explain the decoupled architecture: client-side in-memory demo + native MySQL 8.0 database.
   - Demonstrate the **Browse Items** tab: search for "calculator" or filter by "Electronics".
2. **Minute 2 — Match Recommendation Engine:**
   - Switch to the **Possible Matches** tab.
   - Show how Lost Item #1 (Casio Calculator) matches Found Item #1 with high confidence (95%).
   - Click "View MySQL Query Equivalent" to showcase the SQL query that drives this logic.
   - Click "Simulate Claim Verification" to show state transitions.
3. **Minute 3 — Database & SQL Execution:**
   - Switch to MySQL Workbench.
   - Run `SELECT * FROM vw_possible_matches;` to show live view results.
   - Run Workflow 2 in `06_claim_processing.sql` to show transaction `COMMIT` and referential integrity across the tables.
