-- Library Management System Schema for MySQL
-- Complete .sql file containing CREATE TABLE statements with constraints
-- Includes seed data and sample queries for demonstration
-- Tested for MySQL 8.0+ (uses InnoDB, FK checks, and CHECK constraints)

SET FOREIGN_KEY_CHECKS = 0;

-- Drop existing tables if present
DROP TABLE IF EXISTS fines;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS book_copies;
DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS book_categories;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS publishers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS branches;
DROP TABLE IF EXISTS patrons;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS audit_log;

SET FOREIGN_KEY_CHECKS = 1;

-- ========================
-- TABLE CREATION
-- ========================

CREATE TABLE branches (
  branch_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  address VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100),
  opened_date DATE,
  UNIQUE (name)
) ENGINE=InnoDB;

CREATE TABLE publishers (
  publisher_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  address VARCHAR(255),
  website VARCHAR(255),
  UNIQUE (name)
) ENGINE=InnoDB;

CREATE TABLE authors (
  author_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  birth_date DATE,
  bio TEXT,
  UNIQUE (first_name, last_name)
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE books (
  book_id INT AUTO_INCREMENT PRIMARY KEY,
  isbn VARCHAR(20) UNIQUE,
  title VARCHAR(255) NOT NULL,
  publisher_id INT,
  publication_year YEAR,
  language VARCHAR(50),
  pages INT CHECK (pages >= 0),
  summary TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE book_authors (
  book_id INT NOT NULL,
  author_id INT NOT NULL,
  author_order SMALLINT NOT NULL DEFAULT 1,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE book_categories (
  book_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (book_id, category_id),
  CONSTRAINT fk_bc_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
  CONSTRAINT fk_bc_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE book_copies (
  copy_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  book_id INT NOT NULL,
  branch_id INT NOT NULL,
  call_number VARCHAR(50),
  barcode VARCHAR(50) NOT NULL UNIQUE,
  acquisition_date DATE,
  condition ENUM('New','Good','Fair','Poor') DEFAULT 'Good',
  status ENUM('Available','On Loan','Reserved','Lost','Maintenance') DEFAULT 'Available',
  CONSTRAINT fk_copy_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
  CONSTRAINT fk_copy_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE patrons (
  patron_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  card_number VARCHAR(30) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(30),
  address VARCHAR(255),
  date_of_birth DATE,
  membership_start DATE NOT NULL DEFAULT (CURRENT_DATE),
  membership_end DATE,
  status ENUM('Active','Suspended','Expired') DEFAULT 'Active'
) ENGINE=InnoDB;

CREATE TABLE staff (
  staff_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  role ENUM('Librarian','Manager','Admin','Clerk') DEFAULT 'Librarian',
  hired_date DATE,
  is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE loans (
  loan_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  copy_id BIGINT NOT NULL,
  patron_id BIGINT NOT NULL,
  staff_id INT,
  loan_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date DATE NOT NULL,
  return_date DATETIME,
  renewed_count SMALLINT DEFAULT 0 CHECK (renewed_count >= 0),
  status ENUM('On Loan','Returned','Overdue','Lost') DEFAULT 'On Loan',
  CONSTRAINT fk_loan_copy FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id) ON DELETE RESTRICT,
  CONSTRAINT fk_loan_patron FOREIGN KEY (patron_id) REFERENCES patrons(patron_id) ON DELETE CASCADE,
  CONSTRAINT fk_loan_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL,
  INDEX (patron_id),
  INDEX (copy_id)
) ENGINE=InnoDB;

CREATE TABLE reservations (
  reservation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  patron_id BIGINT NOT NULL,
  book_id INT NOT NULL,
  requested_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  status ENUM('Waiting','Ready for Pickup','Collected','Cancelled','Expired') DEFAULT 'Waiting',
  expires_at DATETIME,
  notified BOOLEAN DEFAULT FALSE,
  CONSTRAINT fk_res_patron FOREIGN KEY (patron_id) REFERENCES patrons(patron_id) ON DELETE CASCADE,
  CONSTRAINT fk_res_book FOREIGN KEY (book_id) REFERENCES books(book_id) ON DELETE CASCADE,
  INDEX (book_id)
) ENGINE=InnoDB;

CREATE TABLE fines (
  fine_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  loan_id BIGINT NOT NULL,
  amount DECIMAL(8,2) NOT NULL CHECK (amount >= 0),
  issued_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  paid BOOLEAN DEFAULT FALSE,
  paid_date DATETIME,
  reason VARCHAR(255),
  CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE audit_log (
  log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  event_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  staff_id INT,
  action VARCHAR(100) NOT NULL,
  details TEXT,
  CONSTRAINT fk_audit_staff FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ========================
-- SEED DATA
-- ========================

INSERT INTO branches (name, address, phone, email, opened_date)
VALUES ('Central Library', '123 Main St', '123-456-7890', 'central@library.org', '2000-01-01');

INSERT INTO publishers (name, address, website)
VALUES ('Penguin Books', '375 Hudson Street, New York, NY', 'https://www.penguin.com');

INSERT INTO authors (first_name, last_name, birth_date, bio)
VALUES ('George', 'Orwell', '1903-06-25', 'English novelist and essayist.');

INSERT INTO categories (name, description)
VALUES ('Dystopian', 'Fictional societies characterized by oppressive control.');

INSERT INTO books (isbn, title, publisher_id, publication_year, language, pages, summary)
VALUES ('9780451524935', '1984', 1, 1949, 'English', 328, 'Dystopian social science fiction novel.');

INSERT INTO book_authors (book_id, author_id, author_order)
VALUES (1, 1, 1);

INSERT INTO book_categories (book_id, category_id)
VALUES (1, 1);

INSERT INTO book_copies (book_id, branch_id, call_number, barcode, acquisition_date, condition, status)
VALUES (1, 1, '823.912 ORW', 'BC001', '2020-01-15', 'Good', 'Available');

INSERT INTO patrons (card_number, first_name, last_name, email, phone, address, date_of_birth)
VALUES ('C12345', 'John', 'Doe', 'johndoe@email.com', '555-1234', '456 Elm St', '1990-05-20');

INSERT INTO staff (username, first_name, last_name, email, role, hired_date)
VALUES ('lib_jane', 'Jane', 'Smith', 'jane.smith@library.org', 'Librarian', '2015-06-01');

-- ========================
-- SAMPLE QUERIES
-- ========================

-- 1. List all available copies of books
SELECT b.title, c.copy_id, br.name AS branch
FROM books b
JOIN book_copies c ON b.book_id = c.book_id
JOIN branches br ON c.branch_id = br.branch_id
WHERE c.status = 'Available';

-- 2. Find all books reserved by a patron
SELECT p.first_name, p.last_name, b.title, r.status
FROM reservations r
JOIN patrons p ON r.patron_id = p.patron_id
JOIN books b ON r.book_id = b.book_id
WHERE p.card_number = 'C12345';

-- 3. Show overdue loans
SELECT l.loan_id, p.first_name, p.last_name, b.title, l.due_date
FROM loans l
JOIN patrons p ON l.patron_id = p.patron_id
JOIN book_copies bc ON l.copy_id = bc.copy_id
JOIN books b ON bc.book_id = b.book_id
WHERE l.status = 'Overdue';

-- 4. Calculate total unpaid fines for each patron
SELECT p.first_name, p.last_name, SUM(f.amount) AS total_unpaid
FROM fines f
JOIN loans l ON f.loan_id = l.loan_id
JOIN patrons p ON l.patron_id = p.patron_id
WHERE f.paid = FALSE
GROUP BY p.patron_id;

-- End of Complete Schema + Seed Data + Sample Queries
