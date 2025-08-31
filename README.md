# Library Management System

## Project Title
Library Management System Database (MySQL)

## Description
This project is a full-featured Library Management System designed using MySQL. It includes:  
- Tables for books, authors, publishers, categories, patrons, staff, loans, reservations, fines, and branches.  
- Proper constraints (Primary Keys, Foreign Keys, UNIQUE, NOT NULL).  
- Relationships (1-1, 1-M, M-M where needed).  
- Sample seed data to test the database.  
- Sample queries for common library operations like book loans, reservations, fines, and tracking book copies.  

The system helps manage library operations efficiently, keeping track of patrons, staff, and physical copies of books across multiple branches.

## How to Run / Setup
1. Make sure MySQL Server is installed and running.  
2. Download or clone this repository.  
3. Open MySQL Workbench or use a terminal.  
4. Create a new database by running:  
   ```sql
   CREATE DATABASE library_db;
   USE library_db;
