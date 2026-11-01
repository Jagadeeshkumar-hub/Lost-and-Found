# Comprehensive DBMS Viva Examination Questions & Answers
**Project:** Campus Lost-and-Found Record Matching System  
**Target:** B.Tech Computer Science & Engineering — DBMS Practical & Project Viva  
**Database:** MySQL 8.0 (`campus_lost_found`) | **Frontend:** HTML5, CSS3, Vanilla JavaScript

---

### Category 1: Project Overview & Architecture

#### Q1: What is the primary objective of this project?
**Answer:**  
The objective is to manage campus-wide lost and found property records and automate candidate matching between reported lost belongings and turned-in items using a multi-factor comparison of category, location, date proximity, and description keywords.

#### Q2: Why is the frontend decoupled from the MySQL database without a backend server?
**Answer:**  
This project was strictly designed as a DBMS minor project focusing on database fundamentals (schema design, SQL queries, normalization, transactions, views) and standalone UI demonstration. In accordance with the academic guidelines, server-side backends (Node.js, Python, PHP) and REST APIs were excluded. The frontend runs a client-side in-memory simulation, while the actual database engine runs natively in MySQL 8.0.

#### Q3: What happens to records created on the frontend website? Are they saved into MySQL?
**Answer:**  
No. Because there is no backend server connector or REST API, records added in the web browser are stored temporarily in browser memory for demonstration purposes and reset on reload. The permanent database records are created and manipulated directly via SQL scripts in MySQL Workbench.

#### Q4: How does the system prevent false matches from being treated as confirmed ownership?
**Answer:**  
The system treats query outputs strictly as **Possible Matches** rather than confirmed ownership. A claimant must undergo physical evidence inspection (submitting invoices, describing hidden serial numbers or internal contents) logged in the `Claims` table before security staff approves the release of property.

---

### Category 2: Database Design, Schema & Normalization

#### Q5: What are the core tables in the `campus_lost_found` database?
**Answer:**  
There are five relational tables:
1. `Users`: Campus students, faculty, staff, and security personnel.
2. `Locations`: Specific rooms, laboratories, library zones, and grounds.
3. `Lost_Items`: Reports of misplaced or lost property.
4. `Found_Items`: Turned-in property and secure custody storage desk details.
5. `Claims`: Associative entity tracking ownership verification and staff approval.

#### Q6: What is a Primary Key, and which attributes serve as Primary Keys in your tables?
**Answer:**  
A Primary Key is an attribute or set of attributes that uniquely identifies each tuple (row) in a relation and cannot contain NULL values. In our schema:
- `user_id` in `Users`
- `location_id` in `Locations`
- `lost_id` in `Lost_Items`
- `found_id` in `Found_Items`
- `claim_id` in `Claims`

#### Q7: What are Alternate / Candidate Keys, and are there any in your schema?
**Answer:**  
A Candidate Key is any minimal superkey capable of uniquely identifying a tuple. The primary key is chosen from candidate keys, and the remaining ones are Alternate Keys. In `Users`, `student_or_staff_id` and `email` are alternate candidate keys enforced via `UNIQUE` constraints. In `Locations`, `location_name` is an alternate key.

#### Q8: What is Normalization, and what normal forms does this database achieve?
**Answer:**  
Normalization is the systematic process of organizing database relations to minimize data redundancy and eliminate update, insertion, and deletion anomalies. This database achieves **Boyce-Codd Normal Form (BCNF)**:
- **1NF:** All column values are atomic (no multi-valued or composite values).
- **2NF:** In 1NF and no non-prime attribute is partially dependent on any candidate key (all keys are single attributes).
- **3NF:** In 2NF and no transitive dependency exists ($X \rightarrow Y \rightarrow Z$).
- **BCNF:** For every functional dependency $X \rightarrow Y$, $X$ is a superkey.

#### Q9: Why was `Locations` created as a separate table instead of storing location names as strings inside `Lost_Items` and `Found_Items`?
**Answer:**  
If location names and building details were stored directly as plain text in the items tables, it would cause data redundancy, inconsistent spellings (e.g., "Library Room 1" vs "Lib Rm 1"), and transitive dependency ($\text{lost\_id} \rightarrow \text{location\_name} \rightarrow \text{building}$). Normalizing into `Locations` avoids update anomalies and enforces foreign key referential integrity.

---

### Category 3: Constraints & Referential Integrity

#### Q10: What is a Foreign Key, and how is referential integrity enforced in your project?
**Answer:**  
A Foreign Key is an attribute in one relation that references the Primary Key of another relation, ensuring that invalid references cannot be created. In our database, foreign keys link `Lost_Items` and `Found_Items` to `Users` and `Locations`, and link `Claims` to `Found_Items`, `Users`, and `Lost_Items`.

#### Q11: What is the difference between `ON DELETE CASCADE`, `ON DELETE SET NULL`, and `ON DELETE RESTRICT`? How did you use them?
**Answer:**  
- `CASCADE`: Deleting a parent row automatically deletes all corresponding child rows. Used on `Users(user_id)` for `Lost_Items` and `Found_Items`.
- `RESTRICT`: Prevents deletion of a parent row if matching child records exist. Used on `Locations(location_id)` so campus locations cannot be deleted if active items reference them.
- `SET NULL`: Sets the foreign key column to NULL when the parent row is deleted. Used on `Claims(lost_id)` and `Claims(resolved_by_staff_id)` so audit history remains intact even if a referenced report is archived.

#### Q12: What is a CHECK constraint? Give two examples from your schema.
**Answer:**  
A `CHECK` constraint specifies a boolean condition that every inserted or updated row must satisfy.
1. `CHECK (user_type IN ('STUDENT', 'FACULTY', 'STAFF', 'SECURITY'))` in `Users`.
2. `CHECK (status IN ('REPORTED', 'POSSIBLE_MATCH', 'RETURNED', 'CLOSED'))` in `Lost_Items`.

#### Q13: What happens if a user tries to insert a duplicate email or student roll number into `Users`?
**Answer:**  
MySQL rejects the statement and throws error `1062 (23000): Duplicate entry for key 'uq_users_email'` or `'uq_users_id'`, preventing duplicate records.

---

### Category 4: SQL Queries, Joins & Aggregations

#### Q14: What is the difference between an `INNER JOIN` and a `LEFT OUTER JOIN`?
**Answer:**  
- `INNER JOIN`: Returns only rows where there is a match in both joined tables.
- `LEFT OUTER JOIN`: Returns all rows from the left table, and the matched rows from the right table; if no match exists, NULL values are returned for the right table's columns.
- **Example in project:** Querying `Found_Items LEFT JOIN Claims` displays all found items in custody, even those that have never had a claim filed yet.

#### Q15: What is the purpose of the `GROUP BY` and `HAVING` clauses?
**Answer:**  
- `GROUP BY`: Groups rows sharing the same values in specified columns into summary rows (e.g., counting items per category).
- `HAVING`: Filters aggregated groups based on a aggregate condition, whereas `WHERE` filters individual rows *before* aggregation.
- **Example in project:** In `03_basic_queries.sql`, we group by `location_id` and use `HAVING COUNT(lost_id) >= 2` to identify high-loss campus zones.

#### Q16: What is the difference between a Correlated Subquery and an Uncorrelated (Independent) Subquery?
**Answer:**  
- **Independent Subquery:** Evaluated once before the outer query runs. Its result is passed to the outer query (e.g., `WHERE location_id NOT IN (SELECT location_id FROM Lost_Items)`).
- **Correlated Subquery:** References an attribute from the outer query table (e.g., `WHERE l.user_id = u.user_id`). It is evaluated repeatedly, once for every candidate row evaluated by the outer query.

#### Q17: How did you perform pattern matching in SQL?
**Answer:**  
Using the `LIKE` operator with wildcard characters:
- `%` represents zero or more characters (e.g., `item_name LIKE '%calculator%'`).
- `_` represents exactly one character.
We also used `LOWER()` to perform case-insensitive keyword comparisons.

---

### Category 5: Matching Logic & Recommendation Algorithm

#### Q18: Explain the matching algorithm implemented in your SQL queries.
**Answer:**  
The algorithm uses a dynamic multi-factor evaluation scoring model (0 to 100 points):
1. **Category Match (35 pts):** Exact match required between `l.category` and `f.category`.
2. **Location Proximity (25 pts):** Exact match on `location_id` awards 25 points; different location awards 5 points partial credit for cross-campus transit.
3. **Date Consistency (20 pts):** Found Date must be $\ge$ Lost Date. Proximity within 3 days awards 20 pts; within 7 days awards 15 pts; within 14 days awards 10 pts.
4. **Keyword Overlap (20 pts):** Overlapping distinctive keywords between names and descriptions (e.g., "Casio", "Titan", "Dell", "Keys") awards up to 20 points.
Pairs scoring $\ge 50$ points are classified as Possible Matches.

#### Q19: Why can't a simple equality join (`l.item_name = f.item_name`) be used for matching?
**Answer:**  
Because students and finders use different terminology for the same object. For example, a student reports "Casio Scientific Calculator FX-991EX", while a librarian turns in "Casio ClassWiz fx991 calculator". Exact string equality would yield zero matches, requiring category joins, date ranges, and tokenized keyword pattern searches instead.

#### Q20: How does the system handle date anomalies where Found Date is before Lost Date?
**Answer:**  
In SQL, we use `WHERE f.found_date >= l.lost_date`. If a found date precedes a lost date, the pair is disqualified or awarded 0 date points because an item cannot be found before it was lost.

---

### Category 6: Views & Performance Indexing

#### Q21: What is a View in SQL, and why did you use views in this project?
**Answer:**  
A View is a virtual table based on the result set of an underlying SQL query. It does not store physical data itself (unless materialized); it runs dynamically when referenced.
We created three key views:
1. `vw_unresolved_lost_items`: Pre-joins active lost items with user and location data.
2. `vw_unclaimed_found_items`: Pre-joins unclaimed found items with finder and location data.
3. `vw_possible_matches`: Encapsulates the multi-criteria matching query so administrative queries can be written simply as `SELECT * FROM vw_possible_matches WHERE match_confidence_score >= 75`.

#### Q22: What is an Index in MySQL, and which columns did you index?
**Answer:**  
An Index is an auxiliary B-Tree data structure that speeds up retrieval of rows by avoiding full table scans.
We created indexes on:
- Categories (`idx_lost_category`, `idx_found_category`) for candidate filtering.
- Dates (`idx_lost_date`, `idx_found_date`) for range searches.
- Locations (`idx_lost_location`, `idx_found_location`) for join operations.
- Statuses (`idx_lost_status`, `idx_found_status`, `idx_claims_status`) for active record filtering.

#### Q23: What is the drawback of creating too many indexes?
**Answer:**  
Indexes consume additional disk space and cause write overhead on `INSERT`, `UPDATE`, and `DELETE` operations, because every time a row is modified, all corresponding index B-Trees must be re-balanced.

---

### Category 7: Transactions & ACID Properties

#### Q24: What are the ACID properties in a Database Management System?
**Answer:**  
- **Atomicity:** All statements within a transaction execute successfully, or the entire transaction is rolled back (all-or-nothing).
- **Consistency:** The database transitions from one valid state to another, satisfying all constraints.
- **Isolation:** Concurrent transactions execute without interfering with each other.
- **Durability:** Once committed, changes persist permanently in non-volatile storage, surviving power failures or crashes.

#### Q25: Explain a transaction scenario demonstrated in `06_claim_processing.sql`.
**Answer:**  
When approving a claim (Workflow 2):
1. `START TRANSACTION;` begins the transaction.
2. `SELECT ... FOR UPDATE` acquires an exclusive row lock on the claim.
3. `UPDATE Claims SET claim_status = 'APPROVED'` updates the claim.
4. `UPDATE Found_Items SET status = 'CLAIMED'` updates the found item.
5. `UPDATE Lost_Items SET status = 'RETURNED'` updates the lost item.
6. `COMMIT;` commits all three updates atomically. If any statement fails, `ROLLBACK;` reverts all tables to their previous states.

#### Q26: What is the purpose of `SELECT ... FOR UPDATE`?
**Answer:**  
`SELECT ... FOR UPDATE` establishes an exclusive write lock on the selected rows until the current transaction commits or rolls back. This prevents concurrent transactions from reading or modifying the same item, eliminating race conditions such as two users claiming the same found item simultaneously.

---

### Category 8: Real-World Scenarios & Enhancements

#### Q27: How would you prevent a student from claiming an item that does not belong to them?
**Answer:**  
Through physical proof verification. When an item is logged, certain identifying attributes (e.g., serial numbers, stickers, internal wallpaper on phone, wallet contents) are held in secure notes. The claimant must accurately describe these unpublicized details before a security staff officer approves the claim.

#### Q28: If you were to expand this into a production web app, what technologies would you introduce?
**Answer:**  
1. A backend REST API server (e.g., Node.js/Express, Python/FastAPI, or Java/Spring Boot).
2. Database connection pooling (e.g., MySQL connection pool via `mysql2` or SQLAlchemy).
3. JWT-based authentication for students and Role-Based Access Control (RBAC) for security officers.
4. Automated email/SMS notifications when a high-confidence match ($\ge 80\%$) is identified.
5. Image storage using object storage (e.g., AWS S3 or MinIO) to store photos of turned-in items.

#### Q29: What is the difference between DDL, DML, and DCL commands? Give examples from your scripts.
**Answer:**  
- **DDL (Data Definition Language):** Defines structure (`CREATE DATABASE`, `CREATE TABLE`, `DROP VIEW`, `ALTER TABLE`).
- **DML (Data Manipulation Language):** Manipulates data (`INSERT`, `SELECT`, `UPDATE`, `DELETE`).
- **DCL (Data Control Language):** Controls permissions (`GRANT`, `REVOKE`) and transaction control (`COMMIT`, `ROLLBACK`).

#### Q30: How can this project be demonstrated in 3 minutes during an evaluation?
**Answer:**  
1. **Frontend Demo (1 min):** Open `index.html` in browser. Show dashboard counters. Submit a sample lost item and found item. Show how the Possible Matches engine instantly highlights the pair with score, reason chips, and criteria breakdown.
2. **Database Demo (1 min):** Open MySQL Workbench. Show the 5 tables in `campus_lost_found`. Execute `04_matching_queries.sql` to demonstrate the SQL weighted matching formula and `05_views_and_reports.sql` to show `vw_possible_matches`.
3. **Transaction Demo (1 min):** Execute `06_claim_processing.sql` to show atomicity and state transition from `UNCLAIMED` to `CLAIMED` via `COMMIT`.
