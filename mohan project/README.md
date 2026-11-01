# Campus Lost-and-Found Record Matching System
## B.Tech Computer Science & Engineering — DBMS Minor Project

Welcome to the **Campus Lost-and-Found Record Matching System** workspace!

The complete project is located inside the [`campus-lost-found/`](campus-lost-found/) directory.

### Project Layout
- **Frontend Demonstration:** [`campus-lost-found/index.html`](campus-lost-found/index.html)
  - Styling: [`campus-lost-found/style.css`](campus-lost-found/style.css)
  - Interactive Engine: [`campus-lost-found/app.js`](campus-lost-found/app.js)
  - Mock Demonstration Dataset: [`campus-lost-found/data.js`](campus-lost-found/data.js)
- **MySQL 8.0 Database Scripts:**
  - [`campus-lost-found/sql/01_create_database.sql`](campus-lost-found/sql/01_create_database.sql) — Database, Tables, Constraints & Indexes
  - [`campus-lost-found/sql/02_insert_sample_data.sql`](campus-lost-found/sql/02_insert_sample_data.sql) — Sample Data (12 users, 10 locations, 22 lost, 22 found, 6 claims)
  - [`campus-lost-found/sql/03_basic_queries.sql`](campus-lost-found/sql/03_basic_queries.sql) — CRUD, Joins, Aggregations & Subqueries
  - [`campus-lost-found/sql/04_matching_queries.sql`](campus-lost-found/sql/04_matching_queries.sql) — Strict, Flexible & Weighted Matching Algorithms
  - [`campus-lost-found/sql/05_views_and_reports.sql`](campus-lost-found/sql/05_views_and_reports.sql) — Views (`vw_possible_matches`, etc.)
  - [`campus-lost-found/sql/06_claim_processing.sql`](campus-lost-found/sql/06_claim_processing.sql) — ACID Transaction Workflows
- **Comprehensive Documentation:**
  - [`campus-lost-found/docs/README.md`](campus-lost-found/docs/README.md) — Quickstart & Workbench Instructions
  - [`campus-lost-found/docs/PROJECT_REPORT.md`](campus-lost-found/docs/PROJECT_REPORT.md) — Complete University Minor Project Report
  - [`campus-lost-found/docs/ER_DIAGRAM.md`](campus-lost-found/docs/ER_DIAGRAM.md) — Mermaid ER Diagram & BCNF Normalization Proofs
  - [`campus-lost-found/docs/VIVA_QUESTIONS.md`](campus-lost-found/docs/VIVA_QUESTIONS.md) — 30 Comprehensive Viva Questions & Answers

### How to Run
1. **Frontend:** Open [`campus-lost-found/index.html`](campus-lost-found/index.html) directly in any modern browser.
2. **Database:** Open MySQL Workbench and execute the scripts in [`campus-lost-found/sql/`](campus-lost-found/sql/) sequentially from 01 to 06.
