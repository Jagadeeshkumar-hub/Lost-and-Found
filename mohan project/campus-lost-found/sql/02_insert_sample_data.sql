-- =====================================================================
-- Campus Lost-and-Found Record Matching System
-- Script: 02_insert_sample_data.sql
-- Target DBMS: MySQL 8.0+
-- Description: Populates realistic sample data:
-- - 12 Users (Students, Faculty, Staff, Security)
-- - 10 Locations across Campus
-- - 22 Lost Items across various categories
-- - 22 Found Items with storage tracking
-- - 6 Verification Claims with diverse statuses
-- =====================================================================

USE campus_lost_found;

-- Disable foreign key checks temporarily during bulk load
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE Claims;
TRUNCATE TABLE Lost_Items;
TRUNCATE TABLE Found_Items;
TRUNCATE TABLE Locations;
TRUNCATE TABLE Users;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- 1. INSERT USERS (12 Users)
-- =====================================================================
INSERT INTO Users (user_id, student_or_staff_id, full_name, email, phone, department, user_type) VALUES
(1, '2023CS101', 'Aarav Sharma', 'aarav.sharma@campus.edu', '9876543210', 'Computer Science', 'STUDENT'),
(2, '2023EC145', 'Priya Patel', 'priya.patel@campus.edu', '9876543211', 'Electronics', 'STUDENT'),
(3, '2022ME204', 'Rohan Verma', 'rohan.verma@campus.edu', '9876543212', 'Mechanical Engg', 'STUDENT'),
(4, '2024IT310', 'Ananya Iyer', 'ananya.iyer@campus.edu', '9876543213', 'Information Tech', 'STUDENT'),
(5, '2023EE089', 'Vikram Singh', 'vikram.singh@campus.edu', '9876543214', 'Electrical Engg', 'STUDENT'),
(6, 'FAC-CS-012', 'Dr. Meenakshi Sundaram', 'm.sundaram@campus.edu', '9876543215', 'Computer Science', 'FACULTY'),
(7, 'FAC-ME-007', 'Prof. Rajesh Kulkarni', 'r.kulkarni@campus.edu', '9876543216', 'Mechanical Engg', 'FACULTY'),
(8, 'SEC-MAIN-01', 'Inspector Ramesh Yadav', 'security.main@campus.edu', '9876543217', 'Campus Security', 'SECURITY'),
(9, 'STF-LIB-04', 'Sunita Deshmukh', 'sunita.lib@campus.edu', '9876543218', 'Central Library', 'STAFF'),
(10, '2024CE112', 'Kavita Reddy', 'kavita.reddy@campus.edu', '9876543219', 'Civil Engg', 'STUDENT'),
(11, '2023CS233', 'Mohit Agarwal', 'mohit.agarwal@campus.edu', '9876543220', 'Computer Science', 'STUDENT'),
(12, 'STF-ADM-02', 'Deepak Joshi', 'deepak.joshi@campus.edu', '9876543221', 'Admin Office', 'STAFF');

-- =====================================================================
-- 2. INSERT LOCATIONS (10 Campus Locations)
-- =====================================================================
INSERT INTO Locations (location_id, location_name, building, floor_number, zone_type, custodian_contact) VALUES
(1, 'Central Library 1st Floor Reading Room', 'Dr. APJ Abdul Kalam Library', '1st Floor', 'LIBRARY', 'Librarian Desk (Ext 401)'),
(2, 'Campus Food Court & Cafeteria', 'Student Activity Centre (SAC)', 'Ground Floor', 'CANTEEN', 'Cafeteria Manager (Ext 502)'),
(3, 'Computer Science Lab 3 (Advanced AI Lab)', 'IT & Computing Block', '2nd Floor', 'LABORATORY', 'System Admin Desk (Ext 312)'),
(4, 'Main Football Ground & Pavilion', 'Sports Complex', 'Ground Level', 'SPORTS', 'Sports Officer (Ext 701)'),
(5, 'Auditorium Main Hall', 'Sir CV Raman Auditorium', 'Ground Floor', 'ACADEMIC', 'Auditorium Incharge (Ext 220)'),
(6, 'Mechanical Workshop & CNC Lab', 'Mechanical Engineering Block', 'Ground Floor', 'LABORATORY', 'Workshop Superintendent (Ext 610)'),
(7, 'Boys Hostel Block-B Common Room', 'Hostel Complex B', 'Ground Floor', 'HOSTEL', 'Hostel B Warden (Ext 802)'),
(8, 'Girls Hostel Block-A Study Hall', 'Hostel Complex A', '1st Floor', 'HOSTEL', 'Hostel A Warden (Ext 801)'),
(9, 'Admin Block Student Affairs Section', 'Administrative Building', 'Ground Floor', 'ADMIN', 'Student Welfare Counter (Ext 105)'),
(10, 'Physics & Chemistry Undergraduate Lab', 'Basic Sciences Block', '3rd Floor', 'LABORATORY', 'Science Lab Incharge (Ext 450)');

-- =====================================================================
-- 3. INSERT LOST ITEMS (22 Lost Records)
-- =====================================================================
INSERT INTO Lost_Items (lost_id, user_id, item_name, category, description, location_id, lost_date, status, created_at) VALUES
(1, 1, 'Casio Scientific Calculator FX-991EX', 'ELECTRONICS', 'Black Casio fx-991EX ClassWiz scientific calculator with silver solar panel and small scratch on back cover.', 1, '2026-10-20', 'POSSIBLE_MATCH', '2026-10-20 14:30:00'),
(2, 2, 'Titan Brown Leather Bi-fold Wallet', 'BAGS_WALLETS', 'Brown leather wallet containing college RFID card, SBI debit card, and passport-size photo.', 2, '2026-10-22', 'POSSIBLE_MATCH', '2026-10-22 17:15:00'),
(3, 3, 'Boat Airdopes 141 Charging Case (Black)', 'ELECTRONICS', 'Matte black wireless earbuds charging case with slight scuff on the hinge. Left earbud inside.', 3, '2026-10-23', 'POSSIBLE_MATCH', '2026-10-23 11:20:00'),
(4, 4, 'College Student ID Card with Blue Lanyard', 'CARDS_ID', 'Student ID card for Ananya Iyer, Roll No 2024IT310, attached to blue campus IT department lanyard.', 1, '2026-10-24', 'RETURNED', '2026-10-24 16:00:00'),
(5, 5, 'Hero Sprint Bicycle Key with Red Keychain', 'KEYS', 'Silver bicycle key with red woven paracord keychain and brass ring.', 4, '2026-10-25', 'POSSIBLE_MATCH', '2026-10-25 09:10:00'),
(6, 1, 'Dell 65W USB Type-C Laptop Adapter', 'ELECTRONICS', 'Original Dell 65W black USB-C charger brick with rubber cable tie.', 3, '2026-10-25', 'REPORTED', '2026-10-25 18:00:00'),
(7, 10, 'Engineering Mechanics Textbook by Timoshenko', 'BOOKS_STATIONERY', 'Hardbound textbook with blue plastic book cover and yellow sticky notes on Chapter 4.', 1, '2026-10-26', 'REPORTED', '2026-10-26 12:45:00'),
(8, 11, 'Milton Stainless Steel Water Bottle 1000ml', 'ACCESSORIES', 'Matte silver steel water bottle with a small dent on the bottom rim and sticker of NASA.', 2, '2026-10-26', 'REPORTED', '2026-10-26 13:30:00'),
(9, 2, 'HP Wireless Optical Mouse (Black)', 'ELECTRONICS', 'Black HP 240 silent wireless mouse with USB nano receiver inside battery compartment.', 3, '2026-10-27', 'REPORTED', '2026-10-27 15:10:00'),
(10, 3, 'Set of 3 Dorm Room Keys with Yamaha Tag', 'KEYS', 'Three Godrej brass keys on a stainless steel ring with a black Yamaha rubber tag.', 7, '2026-10-27', 'REPORTED', '2026-10-27 21:00:00'),
(11, 4, 'Ray-Ban Wayfarer Matte Black Sunglasses Case', 'ACCESSORIES', 'Black textured leather case with gold Ray-Ban logo, containing polarized spectacles.', 5, '2026-10-28', 'REPORTED', '2026-10-28 17:40:00'),
(12, 6, 'SanDisk 64GB Dual USB Drive (Type C & A)', 'ELECTRONICS', 'Silver metallic swivel pen drive containing lecture notes and semester midterm question papers.', 5, '2026-10-28', 'POSSIBLE_MATCH', '2026-10-28 19:15:00'),
(13, 5, 'Nike Navy Blue Sports Gym Bag', 'BAGS_WALLETS', 'Navy blue duffel gym bag with white swoosh, containing Yonex badminton racket and wristbands.', 4, '2026-10-29', 'REPORTED', '2026-10-29 08:30:00'),
(14, 7, 'Mitutoyo Digital Vernier Caliper in Blue Box', 'BOOKS_STATIONERY', 'Precision Japanese vernier caliper 150mm inside original fitted dark blue plastic case.', 6, '2026-10-29', 'REPORTED', '2026-10-29 16:50:00'),
(15, 10, 'Faber-Castell Mathematical Drawing Instrument Box', 'BOOKS_STATIONERY', 'Green metal compass set box containing precision divider, bow compass, and set squares.', 1, '2026-10-30', 'REPORTED', '2026-10-30 11:15:00'),
(16, 11, 'Logitech K380 Bluetooth Keyboard (Dark Grey)', 'ELECTRONICS', 'Compact wireless keyboard with circular keys, yellow function key accents, and missing battery lid.', 1, '2026-10-30', 'REPORTED', '2026-10-30 14:00:00'),
(17, 2, 'Transparent A4 File Folder with Grade Sheets', 'DOCUMENTS', 'Clear plastic button folder containing original semester 1 to 4 grade transcripts and bonafide certificate.', 9, '2026-10-30', 'POSSIBLE_MATCH', '2026-10-30 15:30:00'),
(18, 1, 'Noise ColorFit Pulse Smartwatch (Teal Strap)', 'ELECTRONICS', 'Rectangular smartwatch with teal silicone strap and magnetic USB charging cable wound around dial.', 4, '2026-10-30', 'REPORTED', '2026-10-30 18:20:00'),
(19, 4, 'Wildcraft Maroon Backpack with Rain Cover', 'BAGS_WALLETS', 'Maroon 35L college backpack with neon yellow zipper pullers and integrated bottom rain flap.', 2, '2026-10-31', 'REPORTED', '2026-10-31 10:10:00'),
(20, 3, 'Fastrack Silver Analog Wristwatch', 'ACCESSORIES', 'Stainless steel mesh strap watch with blue dial and date aperture at 3 oclock.', 10, '2026-10-31', 'REPORTED', '2026-10-31 12:05:00'),
(21, 5, 'Laboratory Coat White Cotton with EE Badge', 'ACCESSORIES', 'Full sleeve white lab apron with embroidered Electrical Engineering logo and black ballpoint pen in pocket.', 10, '2026-10-31', 'REPORTED', '2026-10-31 13:40:00'),
(22, 10, 'Casio Scientific Calculator FX-82MS', 'ELECTRONICS', 'Dark grey 2-line display scientific calculator with hard slide-on case.', 5, '2026-10-31', 'REPORTED', '2026-10-31 14:15:00');

-- =====================================================================
-- 4. INSERT FOUND ITEMS (22 Found Records)
-- =====================================================================
INSERT INTO Found_Items (found_id, finder_id, item_name, category, description, location_id, found_date, storage_place, status, created_at) VALUES
(1, 9, 'Casio Scientific Calculator FX-991EX ClassWiz', 'ELECTRONICS', 'Scientific calculator found on Desk 14 in quiet study corner. Has small scratch on battery door.', 1, '2026-10-21', 'Central Library Circulation & Lost-Found Counter', 'CLAIM_PENDING', '2026-10-21 09:30:00'),
(2, 8, 'Brown Leather Bi-fold Wallet (Titan)', 'BAGS_WALLETS', 'Gents brown leather wallet deposited by cafeteria cleaner. Contains cards and currency notes.', 2, '2026-10-22', 'Campus Main Security Post Vault Lockbox', 'CLAIM_PENDING', '2026-10-22 19:40:00'),
(3, 11, 'Boat Wireless Earbuds Case Black', 'ELECTRONICS', 'Black earphone charging capsule picked up near Terminal 18. Indicator LED glows green.', 3, '2026-10-24', 'CS Lab 3 System Administrator Desk', 'UNCLAIMED', '2026-10-24 10:15:00'),
(4, 9, 'Campus Student ID Card (Ananya Iyer)', 'CARDS_ID', 'ID card for Roll No 2024IT310 with navy blue lanyard, turned in by reading room staff.', 1, '2026-10-24', 'Library Helpdesk Lost Register', 'CLAIMED', '2026-10-24 16:30:00'),
(5, 8, 'Single Bicycle Key with Red Fabric Tag', 'KEYS', 'Small nickel-plated key with braided red cord keychain found on running track bleachers.', 4, '2026-10-25', 'Sports Pavilion Guard Cabin', 'UNCLAIMED', '2026-10-25 11:30:00'),
(6, 6, 'SanDisk Dual USB Flash Drive 64GB', 'ELECTRONICS', 'Metal swivel USB thumb drive left plugged into the podium presentation laptop after guest lecture.', 5, '2026-10-28', 'Auditorium AV Control Room', 'CLAIM_PENDING', '2026-10-28 20:00:00'),
(7, 12, 'Transparent Button Folder with Academic Transcripts', 'DOCUMENTS', 'A4 clear file containing marksheets bearing Priya Patel name and branch seal.', 9, '2026-10-30', 'Admin Window Counter No 3', 'CLAIM_PENDING', '2026-10-30 16:15:00'),
(8, 8, 'Stainless Steel Sipper Bottle with Stickers', 'ACCESSORIES', 'Silver metal flask bottle left on cafeteria outdoor table bench.', 2, '2026-10-27', 'Campus Main Security Post Vault Lockbox', 'UNCLAIMED', '2026-10-27 14:00:00'),
(9, 9, 'Engineering Mechanics Textbook (Timoshenko 5th Ed)', 'BOOKS_STATIONERY', 'Blue covered reference book submitted to return shelf without borrower barcode scan.', 1, '2026-10-27', 'Library Staff Workroom Shelf 2', 'UNCLAIMED', '2026-10-27 10:45:00'),
(10, 1, 'HP Wireless Mouse 2.4GHz Black', 'ELECTRONICS', 'Optical mouse found resting beside workstation #12 in Computer Lab 3.', 3, '2026-10-28', 'CS Lab 3 Lab Technician Cupboard', 'UNCLAIMED', '2026-10-28 11:30:00'),
(11, 5, 'Godrej Keys Set with Yamaha Keychain', 'KEYS', 'Bunch of three brass cylinder keys with black rubber motorcycle logo tag on sofa cushion.', 7, '2026-10-28', 'Hostel Block B Warden Office', 'UNCLAIMED', '2026-10-28 22:15:00'),
(12, 7, 'Digital Vernier Caliper Stainless Steel (Mitutoyo)', 'BOOKS_STATIONERY', 'Precision electronic measuring gauge in blue plastic protective case left on lathe inspection bench.', 6, '2026-10-30', 'Workshop Superintendent Store', 'UNCLAIMED', '2026-10-30 09:30:00'),
(13, 8, 'Ray-Ban Sunglasses in Hard Black Leather Case', 'ACCESSORIES', 'Black folding sunglasses case recovered under auditorium seat row G.', 5, '2026-10-29', 'Campus Main Security Post Vault Lockbox', 'UNCLAIMED', '2026-10-29 11:00:00'),
(14, 10, 'Faber-Castell Mathematical Drawing Compass Set', 'BOOKS_STATIONERY', 'Green tin geometry instrument box discovered under table #7 in library reference section.', 1, '2026-10-30', 'Central Library Circulation & Lost-Found Counter', 'UNCLAIMED', '2026-10-30 16:30:00'),
(15, 12, 'Apple 20W USB-C Power Adapter (White)', 'ELECTRONICS', 'Authentic Apple white charger plug left plugged into visitor lounge wall socket.', 9, '2026-10-26', 'Admin Block Reception Desk', 'UNCLAIMED', '2026-10-26 15:00:00'),
(16, 8, 'Navy Blue Nike Gym Duffel Bag', 'BAGS_WALLETS', 'Blue sports bag containing sports shoes and badminton racket, left on team dugout bench.', 4, '2026-10-29', 'Campus Main Security Post Vault Lockbox', 'UNCLAIMED', '2026-10-29 18:30:00'),
(17, 9, 'Wireless Keyboard Logitech K380 Grey', 'ELECTRONICS', 'Bluetooth slim keyboard left at digital library carrel #4.', 1, '2026-10-31', 'Library Helpdesk Lost Register', 'UNCLAIMED', '2026-10-31 09:00:00'),
(18, 8, 'Fitness Smartwatch Teal Silicon Strap', 'ELECTRONICS', 'Digital activity tracker watch retrieved near the athletic track water cooler station.', 4, '2026-10-31', 'Sports Pavilion Guard Cabin', 'UNCLAIMED', '2026-10-31 09:45:00'),
(19, 3, 'Maroon College Backpack Wildcraft', 'BAGS_WALLETS', 'Sturdy maroon backpack with yellow zipper trims left beside juice counter stool.', 2, '2026-10-31', 'Cafeteria Supervisor Counter', 'UNCLAIMED', '2026-10-31 12:15:00'),
(20, 9, 'Men Fastrack Steel Strap Wristwatch', 'ACCESSORIES', 'Metallic analog watch handed over to librarian by lab assistant.', 10, '2026-10-31', 'Basic Sciences Department Office', 'UNCLAIMED', '2026-10-31 15:00:00'),
(21, 8, 'White Cotton Lab Coat with EE Department Crest', 'ACCESSORIES', 'Freshly laundered protective apron found draped on stool in Chemistry Lab.', 10, '2026-10-31', 'Main Security Post', 'UNCLAIMED', '2026-10-31 16:30:00'),
(22, 4, 'Dell 65W Laptop USB-C Adapter Cable', 'ELECTRONICS', 'Black power supply brick found under bench #3 in CS Lab.', 3, '2026-10-26', 'CS Lab 3 System Administrator Desk', 'UNCLAIMED', '2026-10-26 14:00:00');

-- =====================================================================
-- 5. INSERT CLAIMS (6 Verification Claims)
-- =====================================================================
INSERT INTO Claims (claim_id, found_id, claimant_id, lost_id, claim_date, verification_proof, claim_status, resolved_by_staff_id, resolution_notes, resolved_at) VALUES
(1, 4, 4, 4, '2026-10-24 17:30:00', 'Presented original fee receipt and government Aadhaar card matching student registration roll number 2024IT310.', 'APPROVED', 9, 'Physical identity verified on the spot. ID returned to rightful student. Case closed successfully.', '2026-10-24 18:00:00'),
(2, 1, 1, 1, '2026-10-21 16:00:00', 'Claimant correctly stated scratch location on battery lid and produced Amazon digital invoice with matching serial number snippet.', 'PENDING', NULL, 'Awaiting student to show original bill copy at Central Library desk.', NULL),
(3, 2, 2, 2, '2026-10-23 10:15:00', 'Accurately detailed internal contents: SBI global debit card ending in 4108 and specific passport photo inside left sleeve.', 'VERIFIED', 8, 'Claimant contents verified by security officer. Scheduled for biometric handover release.', '2026-10-23 11:30:00'),
(4, 6, 6, 12, '2026-10-29 09:00:00', 'Provided exact directory structure on drive: CS302_Midterm_Keys and Personal_Research_Papers.', 'PENDING', NULL, 'Verification in progress with Auditorium AV technician.', NULL),
(5, 7, 2, 17, '2026-10-30 17:00:00', 'Transcripts carry claimant exact name Priya Patel and Roll 2023EC145.', 'VERIFIED', 12, 'Identity confirmed by student affairs office records. Ready for handover.', '2026-10-30 17:30:00'),
(6, 8, 3, NULL, '2026-10-28 11:30:00', 'Claimant stated bottle had an Apple logo sticker, but physical item actually has a NASA logo sticker.', 'REJECTED', 8, 'Proof description contradicted physical item. Claim denied and logged.', '2026-10-28 12:00:00');

-- =====================================================================
-- Verification Counts
-- =====================================================================
SELECT 'Users count' AS Entity, COUNT(*) AS Total FROM Users
UNION ALL
SELECT 'Locations count', COUNT(*) FROM Locations
UNION ALL
SELECT 'Lost_Items count', COUNT(*) FROM Lost_Items
UNION ALL
SELECT 'Found_Items count', COUNT(*) FROM Found_Items
UNION ALL
SELECT 'Claims count', COUNT(*) FROM Claims;
