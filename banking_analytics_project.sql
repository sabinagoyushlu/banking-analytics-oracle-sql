-- ============================================================
-- BANKING ANALYTICS PROJECT
-- DATA QUALITY ANALYSIS
-- Oracle SQL
-- ============================================================


-- ============================================================
-- 00.  RAW DATA IMPORT & RAW DATA VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- 00.1 Check current Oracle user
-- ------------------------------------------------------------

SELECT USER FROM dual;

-- ------------------------------------------------------------
-- 00.2 Preview imported RAW tables
-- Historical import validation
-- These checks were run before table renaming
-- ------------------------------------------------------------

-- SELECT * FROM RAW_ACCOUNT_STATUSES;
-- SELECT * FROM RAW_ACCOUNT_TYPES;
-- SELECT * FROM RAW_ACCOUNTS;
-- SELECT * FROM RAW_ADRESSES;
-- SELECT * FROM RAW_BRANCHES;
-- SELECT * FROM RAW_CUSTOMER_TYPES;
-- SELECT * FROM RAW_CUSTOMERS;
-- SELECT * FROM RAW_LOAN_STATUS;
-- SELECT * FROM RAW_LOANS;
-- SELECT * FROM RAW_TRANSACTION_TYPES;
-- SELECT * FROM RAW_TRANSACTION;

-- ------------------------------------------------------------
-- 00.3 Rename incorrectly named RAW tables
-- One-time setup commands, already executed
-- ------------------------------------------------------------

--ALTER TABLE RAW_LOAN_STATUS RENAME TO RAW_LOAN_STATUSES;
--ALTER TABLE RAW_TRANSACTION RENAME TO RAW_TRANSACTIONS;
--ALTER TABLE RAW_ADRESSES RENAME TO RAW_ADDRESSES;

-- ------------------------------------------------------------
-- 00.4 Validate row counts for all RAW tables
-- ------------------------------------------------------------

SELECT 'RAW_ACCOUNT_STATUSES' AS table_name, COUNT(*) AS row_count FROM RAW_ACCOUNT_STATUSES
UNION ALL
SELECT 'RAW_ACCOUNT_TYPES', COUNT(*) FROM RAW_ACCOUNT_TYPES
UNION ALL
SELECT 'RAW_ACCOUNTS', COUNT(*) FROM RAW_ACCOUNTS
UNION ALL
SELECT 'RAW_ADDRESSES', COUNT(*) FROM RAW_ADDRESSES
UNION ALL
SELECT 'RAW_BRANCHES', COUNT(*) FROM RAW_BRANCHES
UNION ALL
SELECT 'RAW_CUSTOMER_TYPES', COUNT(*) FROM RAW_CUSTOMER_TYPES
UNION ALL
SELECT 'RAW_CUSTOMERS', COUNT(*) FROM RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_LOAN_STATUSES', COUNT(*) FROM RAW_LOAN_STATUSES
UNION ALL
SELECT 'RAW_LOANS', COUNT(*) FROM RAW_LOANS
UNION ALL
SELECT 'RAW_TRANSACTION_TYPES', COUNT(*) FROM RAW_TRANSACTION_TYPES
UNION ALL
SELECT 'RAW_TRANSACTIONS', COUNT(*) FROM RAW_TRANSACTIONS
ORDER BY table_name;

-- ============================================================
-- 01. RAW_TRANSACTIONS - DATA QUALITY ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 01.1 Identify duplicate TransactionID values
-- ------------------------------------------------------------

SELECT TransactionID, COUNT(*) AS duplicate_count FROM RAW_TRANSACTIONS
GROUP BY TransactionID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

----Data Quality Analysis


-- ------------------------------------------------------------
-- 01.2 Count excess duplicate transaction rows
-- ------------------------------------------------------------

SELECT SUM(duplicate_count - 1) AS duplicate_rows
FROM ( SELECT TransactionID, COUNT(*) AS duplicate_count
FROM RAW_TRANSACTIONS
GROUP BY TransactionID
HAVING COUNT(*) > 1 );

-- ------------------------------------------------------------
-- 01.3 Check NULL values in transaction columns
-- ------------------------------------------------------------

SELECT 
    SUM(CASE WHEN TransactionID IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN AccountOriginID IS NULL THEN 1 ELSE 0 END) AS null_origin_id,
    SUM(CASE WHEN AccountDestinationID IS NULL THEN 1 ELSE 0 END) AS null_destination_id,
    SUM(CASE WHEN TransactionTypeID IS NULL THEN 1 ELSE 0 END) AS null_type_id,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN TransactionDate IS NULL THEN 1 ELSE 0 END) AS null_transaction_date,
    SUM(CASE WHEN BranchID IS NULL THEN 1 ELSE 0 END) AS null_branch_id,
    SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END) AS null_description
FROM RAW_TRANSACTIONS;

-- ------------------------------------------------------------
-- 01.4 Check invalid TransactionDate formats
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_date_format FROM RAW_TRANSACTIONS
WHERE TransactionDate IS NOT NULL
AND VALIDATE_CONVERSION( TransactionDate AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 0;
      
-- ------------------------------------------------------------
-- 01.5 Check transaction dates later than current system date
-- ------------------------------------------------------------

SELECT COUNT(*) AS future_dates FROM RAW_TRANSACTIONS
WHERE TransactionDate IS NOT NULL 
AND TO_TIMESTAMP( TransactionDate, 'YYYY-MM-DD HH24:MI:SS.FF') > SYSDATE;
      
-- ------------------------------------------------------------
-- 01.6 Analyze transaction year distribution
-- ------------------------------------------------------------

SELECT EXTRACT(
         YEAR FROM TO_TIMESTAMP(TransactionDate, 'YYYY-MM-DD HH24:MI:SS.FF')
       ) AS year,
       COUNT(*) AS row_count
FROM RAW_TRANSACTIONS
WHERE TransactionDate IS NOT NULL
GROUP BY EXTRACT( YEAR FROM TO_TIMESTAMP(TransactionDate, 'YYYY-MM-DD HH24:MI:SS.FF')
)
ORDER BY year;

-- ------------------------------------------------------------
-- 01.7 Check dates after the dataset reference period
-- ------------------------------------------------------------

SELECT COUNT(*) AS future_date_rows FROM RAW_TRANSACTIONS
WHERE TransactionDate IS NOT NULL
AND TO_TIMESTAMP( TransactionDate,'YYYY-MM-DD HH24:MI:SS.FF') > TIMESTAMP '2024-12-31 23:59:59';
      

-- ------------------------------------------------------------
-- 01.8 Check for complete duplicate transaction rows
-- ------------------------------------------------------------

SELECT TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, Description,
COUNT(*) AS duplicate_count
FROM RAW_TRANSACTIONS
GROUP BY TransactionID, AccountOriginID, AccountDestinationID, TransactionTypeID, Amount, TransactionDate, BranchID, Description
HAVING COUNT(*) > 1
ORDER BY TransactionID;

-- ------------------------------------------------------------
-- 01.9 Check AccountOriginID referential integrity
-- ------------------------------------------------------------

SELECT t.TransactionID, t.AccountOriginID FROM RAW_TRANSACTIONS t
LEFT JOIN RAW_ACCOUNTS a ON t.AccountOriginID = a.AccountID
WHERE t.AccountOriginID IS NOT NULL
AND a.AccountID IS NULL;

-- ------------------------------------------------------------
-- 01.10 Check AccountDestinationID referential integrity
-- ------------------------------------------------------------

SELECT t.TransactionID, t.AccountDestinationID FROM RAW_TRANSACTIONS t
LEFT JOIN RAW_ACCOUNTS a ON t.AccountDestinationID = a.AccountID
WHERE t.AccountDestinationID IS NOT NULL
AND a.AccountID IS NULL;

-- ------------------------------------------------------------
-- 01.11 Check TransactionTypeID referential integrity
-- ------------------------------------------------------------

SELECT t.TransactionID, t.TransactionTypeID FROM RAW_TRANSACTIONS t
LEFT JOIN RAW_TRANSACTION_TYPES tt ON t.TransactionTypeID = tt.TransactionTypeID
WHERE t.TransactionTypeID IS NOT NULL
AND tt.TransactionTypeID IS NULL;

-- ------------------------------------------------------------
-- 01.12 Check BranchID referential integrity
-- ------------------------------------------------------------

SELECT t.TransactionID, t.BranchID FROM RAW_TRANSACTIONS t
LEFT JOIN RAW_BRANCHES b ON t.BranchID = b.BranchID
WHERE t.BranchID IS NOT NULL
AND b.BranchID IS NULL;

-- ------------------------------------------------------------
-- 01.13 Identify invalid Amount numeric values
-- ------------------------------------------------------------

SELECT TransactionID, Amount FROM RAW_TRANSACTIONS
WHERE Amount IS NOT NULL
AND VALIDATE_CONVERSION( Amount AS NUMBER, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') = 0;

-- ------------------------------------------------------------
-- 01.14 Identify non-positive Amount values
-- ------------------------------------------------------------

SELECT TransactionID, Amount FROM RAW_TRANSACTIONS
WHERE Amount IS NOT NULL
AND TO_NUMBER( Amount, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') <= 0;

-- ============================================================
-- 02. RAW_ADDRESSES - COUNTRY DATA QUALITY ANALYSIS
-- ============================================================

------typo / inconsistent text values

-- ------------------------------------------------------------
-- 02.1 Country value distribution excluding NULL values
-- ------------------------------------------------------------

SELECT Country, COUNT(Country) FROM RAW_ADDRESSES GROUP BY Country
ORDER BY COUNT(Country) DESC;

-- ------------------------------------------------------------
-- 02.2 Country value distribution including NULL values
-- ------------------------------------------------------------

SELECT Country, COUNT(*) FROM RAW_ADDRESSES GROUP BY Country 
ORDER BY COUNT(*) DESC;

-- ------------------------------------------------------------
-- 02.3 Preview Country typo standardization
-- ------------------------------------------------------------

SELECT Country,CASE WHEN Country IN (
               'Unitd States',
               'United Slates',
               'United vtates',
               'Pnited States',
               'United Staes',
               'United StateR',
               'United State',
               'United StXtes',
               'United0States',
               'UnitedcStates'
           )
THEN 'United States' ELSE Country
END AS country_clean FROM RAW_ADDRESSES;
       
------ Country standardization preview

-- ------------------------------------------------------------
-- 02.4 Validate Country typo standardization results
-- ------------------------------------------------------------

SELECT country_clean, COUNT(*) FROM (
SELECT CASE WHEN Country IN (
               'Unitd States',
               'United Slates',
               'United vtates',
               'Pnited States',
               'United Staes',
               'United StateR',
               'United State',
               'United StXtes',
               'United0States',
               'UnitedcStates'
               )
THEN 'United States' ELSE Country END AS country_clean
FROM RAW_ADDRESSES
)
GROUP BY country_clean;

-- ------------------------------------------------------------
-- 02.5 Investigate rows with missing Country
-- ------------------------------------------------------------

SELECT AddressID, Street, City, Country FROM RAW_ADDRESSES
WHERE Country IS NULL;

-- ============================================================
-- 03. RAW_CUSTOMERS - BASIC DATA QUALITY ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 03.1 Inspect RAW_CUSTOMERS table structure
-- ------------------------------------------------------------

DESC RAW_CUSTOMERS;

-- ------------------------------------------------------------
-- 03.2 Check NULL values in customer columns
-- ------------------------------------------------------------

SELECT 
SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_cutomer_id,
SUM(CASE WHEN FIRSTNAME IS NULL THEN 1 ELSE 0 END) AS null_firstname,
SUM(CASE WHEN LASTNAME IS NULL THEN 1 ELSE 0 END) AS null_lastname,
SUM(CASE WHEN DATEOFBIRTH IS NULL THEN 1 ELSE 0 END) AS null_dateofbirth,
SUM(CASE WHEN ADDRESSID IS NULL THEN 1 ELSE 0 END) AS null_adress_id,
SUM(CASE WHEN CUSTOMERTYPEID IS NULL THEN 1 ELSE 0 END) AS null_customertypeid
FROM RAW_CUSTOMERS;

-- ------------------------------------------------------------
-- 03.3 Identify customers with missing FirstName or LastName
-- ------------------------------------------------------------

SELECT CustomerID, FirstName, LastName FROM RAW_CUSTOMERS
WHERE Firstname IS NULL OR Lastname IS NULL;

-- ------------------------------------------------------------
-- 03.4 Identify customers with both FirstName and LastName missing
-- ------------------------------------------------------------

SELECT * FROM RAW_CUSTOMERS
WHERE FirstName IS NULL
AND LastName IS NULL;

-- ------------------------------------------------------------
-- 03.5 Identify duplicate CustomerID values
-- ------------------------------------------------------------

SELECT CustomerID, COUNT(*) AS duplicate_count
FROM RAW_CUSTOMERS
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------
-- 03.6 Display all rows belonging to duplicate CustomerIDs
-- ------------------------------------------------------------

SELECT * FROM RAW_CUSTOMERS
WHERE CustomerID IN (
    SELECT CustomerID
    FROM RAW_CUSTOMERS
    GROUP BY CustomerID
    HAVING COUNT(*) > 1
)
ORDER BY CustomerID;

-- ------------------------------------------------------------
-- 03.7 Check for complete duplicate customer rows
-- ------------------------------------------------------------

SELECT CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID,
COUNT(*) AS duplicate_count
FROM RAW_CUSTOMERS
GROUP BY CustomerID, FirstName, LastName, DateOfBirth, AddressID, CustomerTypeID
HAVING COUNT(*) > 1
ORDER BY CustomerID;

-- ============================================================
-- 04. RAW_CUSTOMERS - DATE OF BIRTH DATA QUALITY ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 04.1 Count DateOfBirth values with invalid standard format
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_dateofbirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth IS NOT NULL
AND VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP,'YYYY-MM-DD HH24:MI:SS.FF') = 0;
      
-- ------------------------------------------------------------
-- 04.2 Display DateOfBirth values with invalid standard format
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth IS NOT NULL
AND VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP,'YYYY-MM-DD HH24:MI:SS.FF') = 0;

-- ------------------------------------------------------------
-- 04.3 Group invalid DateOfBirth values
-- ------------------------------------------------------------

SELECT DateOfBirth, COUNT(*) AS count_date
FROM RAW_CUSTOMERS
WHERE DateOfBirth IS NOT NULL
  AND VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF' ) = 0
GROUP BY DateOfBirth
ORDER BY COUNT(*) DESC;

-- ------------------------------------------------------------
-- 04.4 Identify NaT values
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth = 'NaT';

-- ------------------------------------------------------------
-- 04.5 Identify DateOfBirth values using T timestamp format
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth LIKE '____-__-__T%';

-- ------------------------------------------------------------
-- 04.6 Identify dotted DateOfBirth formats
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE REGEXP_LIKE( DateOfBirth, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$');

-- ------------------------------------------------------------
-- 04.7 Classify dotted DateOfBirth formats
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth, CASE
WHEN VALIDATE_CONVERSION (DateOfBirth AS DATE, 'DD.MM.YYYY') = 1
AND VALIDATE_CONVERSION (DateOfBirth AS DATE, 'MM.DD.YYYY') = 1
THEN 'AMBIGUOUS- BOTH'

WHEN VALIDATE_CONVERSION (DateOfBirth AS DATE, 'DD.MM.YYYY') = 1
THEN 'DD.MM.YYYY'

WHEN VALIDATE_CONVERSION (DateOfBirth AS DATE, 'MM.DD.YYYY') = 1
THEN 'MM.DD.YYYY'
ELSE 'INVALID'
END AS date_format
FROM RAW_CUSTOMERS 
WHERE REGEXP_LIKE ( DateOfBirth, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$' );

-- ------------------------------------------------------------
-- 04.8 Identify slash-separated DateOfBirth formats
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth LIKE '%/%';

-- ------------------------------------------------------------
-- 04.9 Classify slash-separated DateOfBirth formats
-- ------------------------------------------------------------

SELECT DateOfBirth,
       CASE
           WHEN VALIDATE_CONVERSION(DateOfBirth AS DATE, 'YYYY/MM/DD') = 1
               THEN 'YYYY/MM/DD'

           WHEN VALIDATE_CONVERSION(DateOfBirth AS DATE, 'DD/MM/YYYY') = 1
            AND VALIDATE_CONVERSION(DateOfBirth AS DATE, 'MM/DD/YYYY') = 1
               THEN 'AMBIGUOUS'

           WHEN VALIDATE_CONVERSION(DateOfBirth AS DATE, 'DD/MM/YYYY') = 1
               THEN 'DD/MM/YYYY'

           WHEN VALIDATE_CONVERSION(DateOfBirth AS DATE, 'MM/DD/YYYY') = 1
               THEN 'MM/DD/YYYY'

           ELSE 'INVALID'
       END AS date_format
FROM RAW_CUSTOMERS
WHERE DateOfBirth LIKE '%/%';

-- ------------------------------------------------------------
-- 04.10 Preview YYYY/MM/DD to YYYY-MM-DD standardization
-- ------------------------------------------------------------

SELECT CustomerID,DateOfBirth,
       TO_CHAR( TO_DATE(DateOfBirth, 'YYYY/MM/DD'), 'YYYY-MM-DD' ) AS clean_dateofbirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth LIKE '%/%'
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY/MM/DD') = 1;
      
-- ------------------------------------------------------------
-- 04.11 Preview T-format DateOfBirth standardization
-- ------------------------------------------------------------

SELECT DateOfBirth,
       TO_CHAR( TO_TIMESTAMP(DateOfBirth, 'YYYY-MM-DD"T"HH24:MI:SS'), 'YYYY-MM-DD' ) AS clean_dateofbirth
FROM RAW_CUSTOMERS
WHERE DateOfBirth LIKE '____-__-__T%';

-- ------------------------------------------------------------
-- 04.12 Classify YYYY-MM-DD and YYYY-DD-MM formats
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth,
CASE WHEN VALIDATE_CONVERSION( DateOfBirth AS DATE,
    'YYYY-MM-DD'
) = 1
THEN 'VALID YYYY-MM-DD'
WHEN VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-DD-MM') = 1
THEN 'VALID YYYY-DD-MM'
ELSE 'INVALID' END AS date_status
FROM RAW_CUSTOMERS 
WHERE REGEXP_LIKE( DateOfBirth, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$');

-- ------------------------------------------------------------
-- 04.13 Preview YYYY-DD-MM correction
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth,
    TO_CHAR( TO_DATE(DateOfBirth, 'YYYY-DD-MM'), 'YYYY-MM-DD' ) AS possible_clean_date
FROM RAW_CUSTOMERS
WHERE VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-MM-DD') = 0
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-DD-MM') = 1;

-- ------------------------------------------------------------
-- 04.14 Preview unambiguous MM.DD.YYYY standardization
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth,
    TO_CHAR( TO_DATE(DateOfBirth, 'MM.DD.YYYY'), 'YYYY-MM-DD' ) AS clean_dateofbirth
FROM RAW_CUSTOMERS
WHERE REGEXP_LIKE( DateOfBirth, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$')
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'MM.DD.YYYY') = 1
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'DD.MM.YYYY') = 0;

-- ============================================================
-- 05. RAW_CUSTOMERS - LOGICAL DATE VALIDATION
-- ============================================================

-- ------------------------------------------------------------
-- 05.1 Check future DateOfBirth values
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth
FROM RAW_CUSTOMERS
WHERE VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP,'YYYY-MM-DD HH24:MI:SS.FF'
) = 1
AND TO_TIMESTAMP( DateOfBirth, 'YYYY-MM-DD HH24:MI:SS.FF') > SYSTIMESTAMP;
    
-- ------------------------------------------------------------
-- 05.2 Identify customers older than 120 years
-- ------------------------------------------------------------

SELECT CustomerID, DateOfBirth FROM RAW_CUSTOMERS WHERE VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 1 
AND TO_TIMESTAMP( DateOfBirth, 'YYYY-MM-DD HH24:MI:SS.FF') < SYSTIMESTAMP - INTERVAL '120' YEAR(3);

-- 06. CUSTOMER REFERENTIAL INTEGRITY CHECKS

--     - AddressID -> RAW_ADDRESSES

SELECT c.CustomerID, c.AddressID
FROM RAW_CUSTOMERS c
LEFT JOIN RAW_ADDRESSES a ON c.AddressID = a.AddressID
WHERE a.AddressID IS NULL;

--     - CustomerTypeID -> RAW_CUSTOMER_TYPES

SELECT c.CustomerID, c.CustomerTypeID
FROM RAW_CUSTOMERS c
LEFT JOIN RAW_CUSTOMER_TYPES t ON c.CustomerTypeID = t.CustomerTypeID
WHERE t.CustomerTypeID IS NULL;

-- ============================================================
-- 07. RAW_ACCOUNTS - DATA QUALITY ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 07.1 Inspect RAW_ACCOUNTS table structure
-- ------------------------------------------------------------

DESC RAW_ACCOUNTS;

-- ------------------------------------------------------------
-- 07.2 Check NULL values in account columns
-- ------------------------------------------------------------

SELECT
    SUM(CASE WHEN AccountID IS NULL THEN 1 ELSE 0 END) AS null_account_id,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN AccountTypeID IS NULL THEN 1 ELSE 0 END) AS null_account_type_id,
    SUM(CASE WHEN AccountStatusID IS NULL THEN 1 ELSE 0 END) AS null_account_status_id,
    SUM(CASE WHEN Balance IS NULL THEN 1 ELSE 0 END) AS null_balance,
    SUM(CASE WHEN OpeningDate IS NULL THEN 1 ELSE 0 END) AS null_opening_date
FROM RAW_ACCOUNTS;

-- ------------------------------------------------------------
-- 07.3 Identify duplicate AccountID values
-- ------------------------------------------------------------

SELECT AccountID, COUNT(*) AS duplicate_count FROM RAW_ACCOUNTS
GROUP BY AccountID
HAVING COUNT(*) > 1
ORDER BY AccountID;

-- ------------------------------------------------------------
-- 07.4 Display rows belonging to duplicate AccountIDs
-- ------------------------------------------------------------

SELECT * FROM RAW_ACCOUNTS WHERE AccountID IN (
    SELECT AccountID FROM RAW_ACCOUNTS
    GROUP BY AccountID
    HAVING COUNT(*) > 1
)
ORDER BY AccountID;

-- ------------------------------------------------------------
-- 07.5 Check for complete duplicate account rows
-- ------------------------------------------------------------

SELECT AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate, COUNT(*) AS duplicate_count FROM RAW_ACCOUNTS
GROUP BY AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance, OpeningDate
HAVING COUNT(*) > 1
ORDER BY AccountID;

-- ------------------------------------------------------------
-- 07.6 Check CustomerID referential integrity
-- RAW_ACCOUNTS.CustomerID -> RAW_CUSTOMERS.CustomerID
-- ------------------------------------------------------------

SELECT a.AccountID, a.CustomerID FROM RAW_ACCOUNTS a
LEFT JOIN RAW_CUSTOMERS c ON a.CustomerID = c.CustomerID
WHERE a.CustomerID IS NOT NULL
AND c.CustomerID IS NULL;

-- ------------------------------------------------------------
-- 07.7 Check AccountTypeID referential integrity
-- RAW_ACCOUNTS.AccountTypeID -> RAW_ACCOUNT_TYPES.AccountTypeID
-- ------------------------------------------------------------

SELECT a.AccountID, a.AccountTypeID FROM RAW_ACCOUNTS a
LEFT JOIN RAW_ACCOUNT_TYPES t ON a.AccountTypeID = t.AccountTypeID
WHERE a.AccountTypeID IS NOT NULL
AND t.AccountTypeID IS NULL;


-- ------------------------------------------------------------
-- 07.8 Check AccountStatusID referential integrity
-- RAW_ACCOUNTS.AccountStatusID -> RAW_ACCOUNT_STATUSES.AccountStatusID
-- ------------------------------------------------------------

SELECT a.AccountID, a.AccountStatusID FROM RAW_ACCOUNTS a
LEFT JOIN RAW_ACCOUNT_STATUSES s ON a.AccountStatusID = s.AccountStatusID
WHERE a.AccountStatusID IS NOT NULL
AND s.AccountStatusID IS NULL;

-- ------------------------------------------------------------
-- 07.9 Preview Balance values and numeric session settings
-- ------------------------------------------------------------

SELECT Balance FROM RAW_ACCOUNTS
FETCH FIRST 20 ROWS ONLY;

SELECT value FROM NLS_SESSION_PARAMETERS
WHERE parameter = 'NLS_NUMERIC_CHARACTERS';

-- ------------------------------------------------------------
-- 07.10 Count invalid Balance numeric values
-- ------------------------------------------------------------

SELECT COUNT(*) AS invalid_balance_count FROM RAW_ACCOUNTS
WHERE Balance IS NOT NULL AND VALIDATE_CONVERSION(
Balance AS NUMBER, '999999999999D99','NLS_NUMERIC_CHARACTERS=''.,''') = 0;

-- ------------------------------------------------------------
-- 07.11 Identify accounts with negative Balance
-- ------------------------------------------------------------

SELECT AccountID, CustomerID, AccountTypeID, AccountStatusID, Balance AS negative_balance FROM RAW_ACCOUNTS
WHERE Balance IS NOT NULL AND TO_NUMBER( Balance, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') < 0
ORDER BY TO_NUMBER( Balance, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''');

-- ------------------------------------------------------------
-- 07.12 Inspect account type and account status reference tables
-- ------------------------------------------------------------

SELECT * FROM RAW_ACCOUNT_TYPES;

SELECT * FROM RAW_ACCOUNT_STATUSES;

-- ------------------------------------------------------------
-- 07.13 Identify invalid OpeningDate values
-- ------------------------------------------------------------

SELECT AccountID, CustomerID, OpeningDate FROM RAW_ACCOUNTS
WHERE OpeningDate IS NOT NULL AND VALIDATE_CONVERSION( OpeningDate AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 0;

-- ------------------------------------------------------------
-- 07.14 Analyze account opening year distribution
-- ------------------------------------------------------------

SELECT EXTRACT( YEAR FROM TO_TIMESTAMP( OpeningDate, 'YYYY-MM-DD HH24:MI:SS.FF')
) AS opening_year,
COUNT(*) AS account_count
FROM RAW_ACCOUNTS
WHERE OpeningDate IS NOT NULL
GROUP BY EXTRACT( YEAR FROM TO_TIMESTAMP( OpeningDate,'YYYY-MM-DD HH24:MI:SS.FF')
)
ORDER BY opening_year;

-- ------------------------------------------------------------
-- 07.15 Identify OpeningDate values after dataset reference period
-- Project-specific cutoff: end of 2024
-- ------------------------------------------------------------

SELECT AccountID, CustomerID, OpeningDate FROM RAW_ACCOUNTS
WHERE OpeningDate IS NOT NULL AND TO_TIMESTAMP( OpeningDate, 'YYYY-MM-DD HH24:MI:SS.FF') > TIMESTAMP '2024-12-31 23:59:59'
ORDER BY TO_TIMESTAMP( OpeningDate, 'YYYY-MM-DD HH24:MI:SS.FF');

-- ============================================================
-- 08. RAW_LOANS - DATA QUALITY ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 08.1 Inspect RAW_LOANS table structure
-- ------------------------------------------------------------

DESC RAW_LOANS;

-- ------------------------------------------------------------
-- 08.2 Check NULL values in loan columns
-- ------------------------------------------------------------

SELECT
    SUM(CASE WHEN LoanID IS NULL THEN 1 ELSE 0 END) AS null_loan_id,
    SUM(CASE WHEN AccountID IS NULL THEN 1 ELSE 0 END) AS null_account_id,
    SUM(CASE WHEN LoanStatusID IS NULL THEN 1 ELSE 0 END) AS null_loan_status_id,
    SUM(CASE WHEN PrincipalAmount IS NULL THEN 1 ELSE 0 END) AS null_principal_amount,
    SUM(CASE WHEN InterestRate IS NULL THEN 1 ELSE 0 END) AS null_interest_rate,
    SUM(CASE WHEN StartDate IS NULL THEN 1 ELSE 0 END) AS null_start_date,
    SUM(CASE WHEN EstimatedEndDate IS NULL THEN 1 ELSE 0 END) AS null_estimated_end_date
FROM RAW_LOANS;

-- ------------------------------------------------------------
-- 08.3 Identify duplicate LoanID values
-- ------------------------------------------------------------

SELECT LoanID, COUNT(*) AS duplicate_count FROM RAW_LOANS
GROUP BY LoanID
HAVING COUNT(*) > 1
ORDER BY LoanID;

-- ------------------------------------------------------------
-- 08.4 Check for complete duplicate loan rows
-- ------------------------------------------------------------

SELECT LoanID, AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate, COUNT(*) AS duplicate_count
FROM RAW_LOANS
GROUP BY LoanID,AccountID, LoanStatusID, PrincipalAmount, InterestRate, StartDate, EstimatedEndDate
HAVING COUNT(*) > 1
ORDER BY LoanID;

-- ------------------------------------------------------------
-- 08.5 Check AccountID referential integrity
-- RAW_LOANS.AccountID -> RAW_ACCOUNTS.AccountID
-- ------------------------------------------------------------

SELECT l.LoanID, l.AccountID FROM RAW_LOANS l
LEFT JOIN RAW_ACCOUNTS a ON l.AccountID = a.AccountID
WHERE l.AccountID IS NOT NULL
AND a.AccountID IS NULL;

-- ------------------------------------------------------------
-- 08.6 Check LoanStatusID referential integrity
-- RAW_LOANS.LoanStatusID -> RAW_LOAN_STATUSES.LoanStatusID
-- ------------------------------------------------------------

SELECT l.LoanID, l.LoanStatusID FROM RAW_LOANS l
LEFT JOIN RAW_LOAN_STATUSES s ON l.LoanStatusID = s.LoanStatusID
WHERE l.LoanStatusID IS NOT NULL
AND s.LoanStatusID IS NULL;

-- ------------------------------------------------------------
-- 08.7 Identify invalid PrincipalAmount numeric values
-- ------------------------------------------------------------

SELECT LoanID, PrincipalAmount FROM RAW_LOANS
WHERE PrincipalAmount IS NOT NULL AND VALIDATE_CONVERSION( PrincipalAmount AS NUMBER, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') = 0;

-- ------------------------------------------------------------
-- 08.8 Identify non-positive PrincipalAmount values
-- ------------------------------------------------------------

SELECT LoanID, PrincipalAmount FROM RAW_LOANS
WHERE PrincipalAmount IS NOT NULL AND TO_NUMBER( PrincipalAmount, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') <= 0;

-- ------------------------------------------------------------
-- 08.9 Identify invalid InterestRate numeric values
-- ------------------------------------------------------------

SELECT LoanID, InterestRate FROM RAW_LOANS
WHERE InterestRate IS NOT NULL AND VALIDATE_CONVERSION( InterestRate AS NUMBER,'9D9999', 'NLS_NUMERIC_CHARACTERS=''.,''') = 0;

-- ------------------------------------------------------------
-- 08.10 Identify non-positive InterestRate values
-- ------------------------------------------------------------

SELECT LoanID, InterestRate FROM RAW_LOANS
WHERE InterestRate IS NOT NULL AND TO_NUMBER(InterestRate, '9D9999','NLS_NUMERIC_CHARACTERS=''.,''') <= 0;

-- ------------------------------------------------------------
-- 08.11 Analyze InterestRate range and average
-- ------------------------------------------------------------

SELECT MIN( TO_NUMBER( InterestRate, '9D9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
) AS min_interest_rate,
MAX( TO_NUMBER( InterestRate, '9D9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
) AS max_interest_rate,
AVG( TO_NUMBER( InterestRate,'9D9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
) AS avg_interest_rate
FROM RAW_LOANS
WHERE InterestRate IS NOT NULL;

-- ------------------------------------------------------------
-- 08.12 Count invalid StartDate and EstimatedEndDate formats
-- ------------------------------------------------------------

SELECT SUM(CASE WHEN StartDate IS NOT NULL AND VALIDATE_CONVERSION( StartDate AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 0
THEN 1 ELSE 0 END
) AS invalid_start_date,
SUM(CASE WHEN EstimatedEndDate IS NOT NULL AND VALIDATE_CONVERSION( EstimatedEndDate AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 0
THEN 1 ELSE 0 END
) AS invalid_estimated_end_date
FROM RAW_LOANS;

-- ------------------------------------------------------------
-- 08.13 Display invalid loan date values
-- ------------------------------------------------------------

SELECT LoanID, 'StartDate' AS date_column, StartDate AS invalid_value FROM RAW_LOANS
WHERE StartDate IS NOT NULL AND VALIDATE_CONVERSION( StartDate AS TIMESTAMP,'YYYY-MM-DD HH24:MI:SS.FF') = 0

UNION ALL

SELECT LoanID, 'EstimatedEndDate' AS date_column, EstimatedEndDate AS invalid_value FROM RAW_LOANS
WHERE EstimatedEndDate IS NOT NULL AND VALIDATE_CONVERSION( EstimatedEndDate AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 0;

-- ------------------------------------------------------------
-- 08.14 Identify loans where EstimatedEndDate precedes StartDate
-- ------------------------------------------------------------

SELECT LoanID, StartDate,EstimatedEndDate FROM RAW_LOANS
WHERE StartDate IS NOT NULL AND EstimatedEndDate IS NOT NULL  
AND TO_TIMESTAMP( EstimatedEndDate, 'YYYY-MM-DD HH24:MI:SS.FF') < TO_TIMESTAMP( StartDate, 'YYYY-MM-DD HH24:MI:SS.FF');

-- ------------------------------------------------------------
-- 08.15 Identify StartDate values after dataset reference period
-- Project-specific cutoff: end of 2024
-- ------------------------------------------------------------

SELECT LoanID, AccountID, StartDate FROM RAW_LOANS
WHERE StartDate IS NOT NULL AND TO_TIMESTAMP( StartDate, 'YYYY-MM-DD HH24:MI:SS.FF' ) > TIMESTAMP '2024-12-31 23:59:59'
ORDER BY TO_TIMESTAMP( StartDate, 'YYYY-MM-DD HH24:MI:SS.FF');

-- ------------------------------------------------------------
-- 08.16 Identify loans with missing StartDate or EstimatedEndDate
-- ------------------------------------------------------------

SELECT LoanID, AccountID, LoanStatusID, StartDate, EstimatedEndDate FROM RAW_LOANS
WHERE StartDate IS NULL
OR EstimatedEndDate IS NULL
ORDER BY LoanID;

-- ============================================================
-- 09. CLEAN DATA LAYER
-- ============================================================

-- ------------------------------------------------------------
-- 09.1 Create clean reference tables
-- ------------------------------------------------------------

CREATE TABLE CLN_ACCOUNT_STATUSES AS
SELECT DISTINCT
    TO_NUMBER(TRIM(AccountStatusID)) AS AccountStatusID,
    TRIM(StatusName) AS StatusName
FROM RAW_ACCOUNT_STATUSES;

CREATE TABLE CLN_ACCOUNT_TYPES AS
SELECT DISTINCT
    TO_NUMBER(TRIM(AccountTypeID)) AS AccountTypeID,
    TRIM(TypeName) AS TypeName
FROM RAW_ACCOUNT_TYPES;

CREATE TABLE CLN_CUSTOMER_TYPES AS
SELECT DISTINCT
    TO_NUMBER(TRIM(CustomerTypeID)) AS CustomerTypeID,
    TRIM(TypeName) AS TypeName
FROM RAW_CUSTOMER_TYPES;

CREATE TABLE CLN_LOAN_STATUSES AS
SELECT DISTINCT
    TO_NUMBER(TRIM(LoanStatusID)) AS LoanStatusID,
    TRIM(StatusName) AS StatusName
FROM RAW_LOAN_STATUSES;

CREATE TABLE CLN_TRANSACTION_TYPES AS
SELECT DISTINCT
    TO_NUMBER(TRIM(TransactionTypeID)) AS TransactionTypeID,
    TRIM(TypeName) AS TypeName
FROM RAW_TRANSACTION_TYPES;

-- ------------------------------------------------------------
-- 09.2 Create clean addresses table
-- ------------------------------------------------------------

CREATE TABLE CLN_ADDRESSES AS
WITH ranked_addresses AS ( SELECT r.*,
        ROW_NUMBER() OVER ( PARTITION BY AddressID ORDER BY ROWID) AS rn
FROM RAW_ADDRESSES r
)
SELECT TO_NUMBER(TRIM(AddressID)) AS AddressID,
NULLIF( TRIM(Street), '' ) AS Street,
NULLIF( TRIM(City), '') AS City,
CASE WHEN Country IN (
            'Unitd States',
            'United Slates',
            'United vtates',
            'Pnited States',
            'United Staes',
            'United StateR',
            'United State',
            'United StXtes',
            'United0States',
            'UnitedcStates'
        )
THEN 'United States'
WHEN Country IS NULL
THEN NULL
ELSE TRIM(Country)
END AS Country
FROM ranked_addresses
WHERE rn = 1;

-- ------------------------------------------------------------
-- 09.3 Create clean branches table
-- ------------------------------------------------------------

CREATE TABLE CLN_BRANCHES AS
WITH ranked_branches AS (
SELECT r.*, ROW_NUMBER() OVER (
PARTITION BY BranchID
ORDER BY ROWID
    ) AS rn
FROM RAW_BRANCHES r
)
SELECT TO_NUMBER(TRIM(BranchID)) AS BranchID,
    NULLIF(TRIM(BranchName), '') AS BranchName,
    TO_NUMBER(TRIM(AddressID)) AS AddressID
FROM ranked_branches
WHERE rn = 1;

-- ------------------------------------------------------------
-- 09.4 Create clean customers table
-- ------------------------------------------------------------

CREATE TABLE CLN_CUSTOMERS AS
WITH ranked_customers AS (
SELECT r.*,
ROW_NUMBER() OVER ( PARTITION BY CustomerID ORDER BY ROWID ) AS rn
FROM RAW_CUSTOMERS r ),
parsed_customers AS (
SELECT CustomerID, FirstName, LastName, AddressID, CustomerTypeID,
CASE

-- Missing / NaT
WHEN DateOfBirth IS NULL
OR TRIM(DateOfBirth) = 'NaT' THEN CAST(NULL AS DATE)

-- Standard timestamp
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?$' )
AND VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF') = 1
THEN TO_DATE( SUBSTR(DateOfBirth, 1, 10), 'YYYY-MM-DD')

-- ISO T timestamp
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' )
AND VALIDATE_CONVERSION( DateOfBirth AS TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS') = 1
THEN TO_DATE( SUBSTR(DateOfBirth, 1, 10), 'YYYY-MM-DD'
)

 -- YYYY/MM/DD
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{4}/[0-9]{2}/[0-9]{2}$' )
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY/MM/DD') = 1
THEN TO_DATE( DateOfBirth, 'YYYY/MM/DD' )

-- Valid YYYY-MM-DD
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' )
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-MM-DD') = 1
THEN TO_DATE( DateOfBirth, 'YYYY-MM-DD')


-- Incorrect YYYY-DD-MM that can be corrected safely
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' )
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-MM-DD') = 0
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'YYYY-DD-MM' ) = 1
THEN TO_DATE( DateOfBirth, 'YYYY-DD-MM')

-- Unambiguous MM.DD.YYYY
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$')
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'MM.DD.YYYY') = 1
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'DD.MM.YYYY') = 0
THEN TO_DATE( DateOfBirth, 'MM.DD.YYYY')

-- Unambiguous DD.MM.YYYY
WHEN REGEXP_LIKE( DateOfBirth, '^[0-9]{2}\.[0-9]{2}\.[0-9]{4}$')
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'DD.MM.YYYY') = 1
AND VALIDATE_CONVERSION( DateOfBirth AS DATE, 'MM.DD.YYYY') = 0
THEN TO_DATE( DateOfBirth, 'DD.MM.YYYY')

-- Unknown / ambiguous values
ELSE CAST(NULL AS DATE)
END AS parsed_dateofbirth
FROM ranked_customers
WHERE rn = 1
)
SELECT TO_NUMBER(TRIM(CustomerID)) AS CustomerID,
NULLIF( TRIM(FirstName), '' ) AS FirstName,
NULLIF( TRIM(LastName), '' ) AS LastName,
CASE WHEN parsed_dateofbirth <= DATE '2024-12-31'
THEN parsed_dateofbirth ELSE NULL END AS DateOfBirth,
TO_NUMBER(TRIM(AddressID)) AS AddressID,
TO_NUMBER(TRIM(CustomerTypeID)) AS CustomerTypeID
FROM parsed_customers;

-- ------------------------------------------------------------
-- 09.5 Create clean accounts table
-- ------------------------------------------------------------

CREATE TABLE CLN_ACCOUNTS AS
WITH ranked_accounts AS (
SELECT r.*,
ROW_NUMBER() OVER ( PARTITION BY AccountID ORDER BY ROWID ) AS rn
FROM RAW_ACCOUNTS r
)
SELECT
    TO_NUMBER(TRIM(AccountID)) AS AccountID,
    TO_NUMBER(TRIM(CustomerID)) AS CustomerID,
    TO_NUMBER(TRIM(AccountTypeID)) AS AccountTypeID,
    TO_NUMBER(TRIM(AccountStatusID)) AS AccountStatusID,

    TO_NUMBER( Balance, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') AS Balance,

    CASE WHEN OpeningDate IS NULL THEN CAST(NULL AS TIMESTAMP)

        WHEN TO_TIMESTAMP( OpeningDate, 'YYYY-MM-DD HH24:MI:SS.FF' ) > TIMESTAMP '2024-12-31 23:59:59'
        THEN CAST(NULL AS TIMESTAMP)
        ELSE TO_TIMESTAMP( OpeningDate, 'YYYY-MM-DD HH24:MI:SS.FF' ) END AS OpeningDate
FROM ranked_accounts
WHERE rn = 1;

-- ------------------------------------------------------------
-- 09.6 Create clean loans table
-- ------------------------------------------------------------

CREATE TABLE CLN_LOANS AS
WITH ranked_loans AS ( SELECT r.*,
ROW_NUMBER() OVER ( PARTITION BY LoanID ORDER BY ROWID ) AS rn
FROM RAW_LOANS r )
SELECT
    TO_NUMBER(TRIM(LoanID)) AS LoanID,
    TO_NUMBER(TRIM(AccountID)) AS AccountID,
    TO_NUMBER(TRIM(LoanStatusID)) AS LoanStatusID,

    TO_NUMBER( PrincipalAmount, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''' ) AS PrincipalAmount,
    TO_NUMBER( InterestRate, '9D9999', 'NLS_NUMERIC_CHARACTERS=''.,''' ) AS InterestRate,

    CASE WHEN StartDate IS NULL THEN CAST(NULL AS TIMESTAMP)
    WHEN TO_TIMESTAMP( StartDate, 'YYYY-MM-DD HH24:MI:SS.FF') > TIMESTAMP '2024-12-31 23:59:59'
    THEN CAST(NULL AS TIMESTAMP) ELSE TO_TIMESTAMP( StartDate, 'YYYY-MM-DD HH24:MI:SS.FF')
    END AS StartDate,

    CASE WHEN EstimatedEndDate IS NULL THEN CAST(NULL AS TIMESTAMP) ELSE TO_TIMESTAMP( EstimatedEndDate, 'YYYY-MM-DD HH24:MI:SS.FF')
    END AS EstimatedEndDate
FROM ranked_loans
WHERE rn = 1;

-- ------------------------------------------------------------
-- 09.7 Create clean transactions table
-- ------------------------------------------------------------

CREATE TABLE CLN_TRANSACTIONS AS
WITH ranked_transactions AS ( SELECT r.*, ROW_NUMBER() OVER ( PARTITION BY TransactionID ORDER BY ROWID ) AS rn
FROM RAW_TRANSACTIONS r
)

SELECT
    TO_NUMBER(TRIM(TransactionID)) AS TransactionID,
    TO_NUMBER(TRIM(AccountOriginID)) AS AccountOriginID,
    TO_NUMBER(TRIM(AccountDestinationID)) AS AccountDestinationID,
    TO_NUMBER(TRIM(TransactionTypeID)) AS TransactionTypeID,

    TO_NUMBER( Amount, '999999999999D99', 'NLS_NUMERIC_CHARACTERS=''.,''') AS Amount,

    CASE WHEN TransactionDate IS NULL THEN CAST(NULL AS TIMESTAMP)

    WHEN TO_TIMESTAMP( TransactionDate, 'YYYY-MM-DD HH24:MI:SS.FF' ) > TIMESTAMP '2024-12-31 23:59:59'
    THEN CAST(NULL AS TIMESTAMP) ELSE TO_TIMESTAMP( TransactionDate, 'YYYY-MM-DD HH24:MI:SS.FF' )
    END AS TransactionDate,

    TO_NUMBER(TRIM(BranchID)) AS BranchID,

    NULLIF( TRIM(Description), '') AS Description
FROM ranked_transactions
WHERE rn = 1;

-- ============================================================
-- 09.8 CLEAN LAYER VALIDATION
-- ============================================================


-- ------------------------------------------------------------
-- 09.8.1 Compare RAW and CLEAN row counts
-- ------------------------------------------------------------

SELECT 'ADDRESSES' AS table_name,
       (SELECT COUNT(*) FROM RAW_ADDRESSES) AS raw_rows,
       (SELECT COUNT(*) FROM CLN_ADDRESSES) AS clean_rows
FROM dual

UNION ALL

SELECT 'CUSTOMERS',
       (SELECT COUNT(*) FROM RAW_CUSTOMERS),
       (SELECT COUNT(*) FROM CLN_CUSTOMERS)
FROM dual

UNION ALL

SELECT 'ACCOUNTS',
       (SELECT COUNT(*) FROM RAW_ACCOUNTS),
       (SELECT COUNT(*) FROM CLN_ACCOUNTS)
FROM dual

UNION ALL

SELECT 'LOANS',
       (SELECT COUNT(*) FROM RAW_LOANS),
       (SELECT COUNT(*) FROM CLN_LOANS)
FROM dual

UNION ALL

SELECT 'TRANSACTIONS',
       (SELECT COUNT(*) FROM RAW_TRANSACTIONS),
       (SELECT COUNT(*) FROM CLN_TRANSACTIONS)
FROM dual;

-- ------------------------------------------------------------
-- 09.8.2 Confirm duplicate business keys were removed
-- ------------------------------------------------------------

SELECT AccountID, COUNT(*) FROM CLN_ACCOUNTS
GROUP BY AccountID
HAVING COUNT(*) > 1;

SELECT LoanID, COUNT(*) FROM CLN_LOANS
GROUP BY LoanID
HAVING COUNT(*) > 1;

SELECT TransactionID, COUNT(*) FROM CLN_TRANSACTIONS
GROUP BY TransactionID
HAVING COUNT(*) > 1;

SELECT CustomerID, COUNT(*) FROM CLN_CUSTOMERS
GROUP BY CustomerID
HAVING COUNT(*) > 1;

SELECT AddressID, COUNT(*) FROM CLN_ADDRESSES
GROUP BY AddressID
HAVING COUNT(*) > 1;

-- ------------------------------------------------------------
-- 09.8.3 Inspect clean table structures
-- ------------------------------------------------------------

DESC CLN_CUSTOMERS;
DESC CLN_ACCOUNTS;
DESC CLN_LOANS;
DESC CLN_TRANSACTIONS;

-- ------------------------------------------------------------
-- 09.8.4 Validate clean referential integrity
-- ------------------------------------------------------------

SELECT a.AccountID FROM CLN_ACCOUNTS a
LEFT JOIN CLN_CUSTOMERS c ON a.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;


SELECT l.LoanID FROM CLN_LOANS l
LEFT JOIN CLN_ACCOUNTS a ON l.AccountID = a.AccountID
WHERE a.AccountID IS NULL;


SELECT t.TransactionID FROM CLN_TRANSACTIONS t
LEFT JOIN CLN_ACCOUNTS a ON t.AccountOriginID = a.AccountID
WHERE a.AccountID IS NULL;


SELECT t.TransactionID FROM CLN_TRANSACTIONS t
LEFT JOIN CLN_ACCOUNTS a ON t.AccountDestinationID = a.AccountID
WHERE a.AccountID IS NULL;

-- ============================================================
-- 10. RELATIONAL MODEL & DATA INTEGRITY CONSTRAINTS
-- ============================================================

-- ------------------------------------------------------------
-- 10.1 Add Primary Key constraints
-- ------------------------------------------------------------

ALTER TABLE CLN_ACCOUNT_STATUSES
ADD CONSTRAINT PK_CLN_ACCT_STATUS
PRIMARY KEY (AccountStatusID);

ALTER TABLE CLN_ACCOUNT_TYPES
ADD CONSTRAINT PK_CLN_ACCT_TYPE
PRIMARY KEY (AccountTypeID);

ALTER TABLE CLN_CUSTOMER_TYPES
ADD CONSTRAINT PK_CLN_CUST_TYPE
PRIMARY KEY (CustomerTypeID);

ALTER TABLE CLN_LOAN_STATUSES
ADD CONSTRAINT PK_CLN_LOAN_STATUS
PRIMARY KEY (LoanStatusID);

ALTER TABLE CLN_TRANSACTION_TYPES
ADD CONSTRAINT PK_CLN_TXN_TYPE
PRIMARY KEY (TransactionTypeID);

ALTER TABLE CLN_ADDRESSES
ADD CONSTRAINT PK_CLN_ADDRESS
PRIMARY KEY (AddressID);

ALTER TABLE CLN_BRANCHES
ADD CONSTRAINT PK_CLN_BRANCH
PRIMARY KEY (BranchID);

ALTER TABLE CLN_CUSTOMERS
ADD CONSTRAINT PK_CLN_CUSTOMER
PRIMARY KEY (CustomerID);

ALTER TABLE CLN_ACCOUNTS
ADD CONSTRAINT PK_CLN_ACCOUNT
PRIMARY KEY (AccountID);

ALTER TABLE CLN_LOANS
ADD CONSTRAINT PK_CLN_LOAN
PRIMARY KEY (LoanID);

ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT PK_CLN_TXN
PRIMARY KEY (TransactionID);

-- ------------------------------------------------------------
-- 10.2 Add NOT NULL constraints to required attributes
-- ------------------------------------------------------------

ALTER TABLE CLN_ACCOUNT_STATUSES
MODIFY ( StatusName NOT NULL );

ALTER TABLE CLN_ACCOUNT_TYPES
MODIFY ( TypeName NOT NULL );

ALTER TABLE CLN_CUSTOMER_TYPES
MODIFY ( TypeName NOT NULL );

ALTER TABLE CLN_LOAN_STATUSES
MODIFY ( StatusName NOT NULL );

ALTER TABLE CLN_TRANSACTION_TYPES
MODIFY ( TypeName NOT NULL );

ALTER TABLE CLN_BRANCHES
MODIFY ( BranchName NOT NULL, AddressID NOT NULL );

ALTER TABLE CLN_CUSTOMERS
MODIFY ( AddressID NOT NULL, CustomerTypeID NOT NULL );

ALTER TABLE CLN_ACCOUNTS
MODIFY ( CustomerID NOT NULL, AccountTypeID NOT NULL, AccountStatusID NOT NULL, Balance NOT NULL );

ALTER TABLE CLN_LOANS
MODIFY ( AccountID NOT NULL, LoanStatusID NOT NULL, PrincipalAmount NOT NULL, InterestRate NOT NULL );

ALTER TABLE CLN_TRANSACTIONS
MODIFY ( AccountOriginID NOT NULL, AccountDestinationID NOT NULL, TransactionTypeID NOT NULL, Amount NOT NULL, BranchID NOT NULL );

-- ------------------------------------------------------------
-- 10.3 Add Foreign Key constraints
-- ------------------------------------------------------------

-- Branch -> Address
ALTER TABLE CLN_BRANCHES
ADD CONSTRAINT FK_BRANCH_ADDRESS
FOREIGN KEY (AddressID)
REFERENCES CLN_ADDRESSES (AddressID);

-- Customer -> Address
ALTER TABLE CLN_CUSTOMERS
ADD CONSTRAINT FK_CUSTOMER_ADDRESS
FOREIGN KEY (AddressID)
REFERENCES CLN_ADDRESSES (AddressID);

-- Customer -> Customer Type
ALTER TABLE CLN_CUSTOMERS
ADD CONSTRAINT FK_CUSTOMER_TYPE
FOREIGN KEY (CustomerTypeID)
REFERENCES CLN_CUSTOMER_TYPES (CustomerTypeID);

-- Account -> Customer
ALTER TABLE CLN_ACCOUNTS
ADD CONSTRAINT FK_ACCOUNT_CUSTOMER
FOREIGN KEY (CustomerID)
REFERENCES CLN_CUSTOMERS (CustomerID);

-- Account -> Account Type
ALTER TABLE CLN_ACCOUNTS
ADD CONSTRAINT FK_ACCOUNT_TYPE
FOREIGN KEY (AccountTypeID)
REFERENCES CLN_ACCOUNT_TYPES (AccountTypeID);

-- Account -> Account Status
ALTER TABLE CLN_ACCOUNTS
ADD CONSTRAINT FK_ACCOUNT_STATUS
FOREIGN KEY (AccountStatusID)
REFERENCES CLN_ACCOUNT_STATUSES (AccountStatusID);

-- Loan -> Account
ALTER TABLE CLN_LOANS
ADD CONSTRAINT FK_LOAN_ACCOUNT
FOREIGN KEY (AccountID)
REFERENCES CLN_ACCOUNTS (AccountID);

-- Loan -> Loan Status
ALTER TABLE CLN_LOANS
ADD CONSTRAINT FK_LOAN_STATUS
FOREIGN KEY (LoanStatusID)
REFERENCES CLN_LOAN_STATUSES (LoanStatusID);

-- Transaction Origin -> Account
ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT FK_TXN_ORIGIN
FOREIGN KEY (AccountOriginID)
REFERENCES CLN_ACCOUNTS (AccountID);

-- Transaction Destination -> Account
ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT FK_TXN_DEST
FOREIGN KEY (AccountDestinationID)
REFERENCES CLN_ACCOUNTS (AccountID);

-- Transaction -> Transaction Type
ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT FK_TXN_TYPE
FOREIGN KEY (TransactionTypeID)
REFERENCES CLN_TRANSACTION_TYPES (TransactionTypeID);

-- Transaction -> Branch
ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT FK_TXN_BRANCH
FOREIGN KEY (BranchID)
REFERENCES CLN_BRANCHES (BranchID);

-- ------------------------------------------------------------
-- 10.4 Add business-rule CHECK constraints
-- ------------------------------------------------------------

-- Loan principal must be positive
ALTER TABLE CLN_LOANS
ADD CONSTRAINT CHK_LOAN_PRINCIPAL
CHECK (PrincipalAmount > 0);

-- InterestRate is stored as a decimal
-- Example: 0.08 = 8%
ALTER TABLE CLN_LOANS
ADD CONSTRAINT CHK_LOAN_RATE
CHECK ( InterestRate > 0 AND InterestRate <= 1 );

-- EstimatedEndDate cannot precede StartDate
-- NULL dates are allowed
ALTER TABLE CLN_LOANS
ADD CONSTRAINT CHK_LOAN_DATES
CHECK ( EstimatedEndDate >= StartDate
OR StartDate IS NULL
OR EstimatedEndDate IS NULL );

-- Transaction amount must be positive
ALTER TABLE CLN_TRANSACTIONS
ADD CONSTRAINT CHK_TXN_AMOUNT
CHECK (Amount > 0);

-- ------------------------------------------------------------
-- 10.5 Validate created constraints
-- ------------------------------------------------------------

SELECT Table_Name, Constraint_Name, Constraint_Type, Status FROM USER_CONSTRAINTS
WHERE Table_Name LIKE 'CLN_%'
ORDER BY Table_Name, Constraint_Type, Constraint_Name;

-- ------------------------------------------------------------
-- 10.6 Final relational model row counts
-- ------------------------------------------------------------

SELECT 'CLN_ADDRESSES' AS table_name, COUNT(*) AS row_count FROM CLN_ADDRESSES
UNION ALL
SELECT 'CLN_CUSTOMERS', COUNT(*) FROM CLN_CUSTOMERS
UNION ALL
SELECT 'CLN_ACCOUNTS', COUNT(*) FROM CLN_ACCOUNTS
UNION ALL
SELECT 'CLN_LOANS', COUNT(*) FROM CLN_LOAN
UNION ALL
SELECT 'CLN_TRANSACTIONS', COUNT(*) FROM CLN_TRANSACTIONS
UNION ALL
SELECT 'CLN_BRANCHES', COUNT(*) FROM CLN_BRANCHES;

-- ============================================================
-- 11. BUSINESS / DATA ANALYSIS
-- ============================================================


-- ------------------------------------------------------------
-- 11.1 Customer distribution by customer type
-- Business question:
-- How is the customer base distributed across customer segments?
-- ------------------------------------------------------------

SELECT ct.TypeName AS customer_type, COUNT(*) AS customer_count,
    ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2 ) AS customer_percentage
FROM CLN_CUSTOMERS c
JOIN CLN_CUSTOMER_TYPES ct ON c.CustomerTypeID = ct.CustomerTypeID
GROUP BY ct.TypeName
ORDER BY customer_count DESC;

-- ------------------------------------------------------------
-- 11.2 Account distribution by account type
-- Business question:
-- Which banking products are most commonly used?
-- ------------------------------------------------------------

SELECT at.TypeName AS account_type, COUNT(*) AS account_count,
    ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2 ) AS account_percentage
FROM CLN_ACCOUNTS a
JOIN CLN_ACCOUNT_TYPES at ON a.AccountTypeID = at.AccountTypeID
GROUP BY at.TypeName
ORDER BY account_count DESC;

-- ------------------------------------------------------------
-- 11.3 Account distribution by status
-- Business question:
-- What proportion of accounts are Active, Inactive or Closed?
-- ------------------------------------------------------------

SELECT s.StatusName AS account_status, COUNT(*) AS account_count,
    ROUND(
COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2 ) AS account_percentage
FROM CLN_ACCOUNTS a
JOIN CLN_ACCOUNT_STATUSES s ON a.AccountStatusID = s.AccountStatusID
GROUP BY s.StatusName
ORDER BY account_count DESC;

-- ------------------------------------------------------------
-- 11.4 Analyze account balances by account type
-- Business question:
-- Which account types hold the largest customer balances?
-- ------------------------------------------------------------

SELECT at.TypeName AS account_type, COUNT(*) AS account_count,
    ROUND(SUM(a.Balance), 2) AS total_balance,
    ROUND(AVG(a.Balance), 2) AS average_balance,
    ROUND(MIN(a.Balance), 2) AS minimum_balance,
    ROUND(MAX(a.Balance), 2) AS maximum_balance
FROM CLN_ACCOUNTS a
JOIN CLN_ACCOUNT_TYPES at ON a.AccountTypeID = at.AccountTypeID
GROUP BY at.TypeName
ORDER BY total_balance DESC;

-- ------------------------------------------------------------
-- 11.5 Loan portfolio by loan status
-- Business question:
-- How is the loan portfolio distributed by status?
-- ------------------------------------------------------------

SELECT ls.StatusName AS loan_status, COUNT(*) AS loan_count,
    ROUND( COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2 ) AS loan_percentage,
    ROUND( SUM(l.PrincipalAmount), 2 ) AS total_principal,
    ROUND( AVG(l.PrincipalAmount), 2 ) AS average_principal,
    ROUND( AVG(l.InterestRate) * 100, 2) AS average_interest_rate_pct
FROM CLN_LOANS l
JOIN CLN_LOAN_STATUSES ls ON l.LoanStatusID = ls.LoanStatusID
GROUP BY ls.StatusName
ORDER BY total_principal DESC;

-- ------------------------------------------------------------
-- 11.6 Analyze overdue loan exposure
-- Business question:
-- How much principal is associated with overdue loans?
-- ------------------------------------------------------------

SELECT COUNT(*) AS overdue_loan_count,
    ROUND(SUM(l.PrincipalAmount), 2) AS overdue_principal,
    ROUND(AVG(l.PrincipalAmount), 2) AS average_overdue_loan,
    ROUND(AVG(l.InterestRate) * 100, 2) AS average_interest_rate_pct
FROM CLN_LOANS l
JOIN CLN_LOAN_STATUSES ls ON l.LoanStatusID = ls.LoanStatusID
WHERE ls.StatusName = 'Overdue';

-- ------------------------------------------------------------
-- 11.7 Analyze loan portfolio by account type
-- Business question:
-- Which account types are associated with the largest
-- loan exposure?
-- ------------------------------------------------------------

SELECT at.TypeName AS account_type, COUNT(l.LoanID) AS loan_count,
    ROUND(SUM(l.PrincipalAmount), 2) AS total_principal,
    ROUND(AVG(l.PrincipalAmount), 2) AS average_loan,
    ROUND(AVG(l.InterestRate) * 100, 2) AS average_interest_rate_pct
FROM CLN_LOANS l
JOIN CLN_ACCOUNTS a ON l.AccountID = a.AccountID
JOIN CLN_ACCOUNT_TYPES at ON a.AccountTypeID = at.AccountTypeID
GROUP BY at.TypeName
ORDER BY total_principal DESC;

-- ------------------------------------------------------------
-- 11.8 Analyze transaction activity by transaction type
-- Business question:
-- Which transaction types generate the highest activity
-- and transaction volume?
-- ------------------------------------------------------------

SELECT tt.TypeName AS transaction_type, COUNT(*) AS transaction_count,
    ROUND(SUM(t.Amount), 2) AS total_transaction_volume,
    ROUND(AVG(t.Amount), 2) AS average_transaction_amount
FROM CLN_TRANSACTIONS t
JOIN CLN_TRANSACTION_TYPES tt ON t.TransactionTypeID = tt.TransactionTypeID
GROUP BY tt.TypeName
ORDER BY total_transaction_volume DESC;

-- ------------------------------------------------------------
-- 11.9 Analyze branch transaction activity
-- Business question:
-- Which branches process the highest transaction volume?
-- ------------------------------------------------------------

SELECT b.BranchID, b.BranchName, COUNT(t.TransactionID) AS transaction_count,
    ROUND(SUM(t.Amount), 2) AS total_transaction_volume,
    ROUND(AVG(t.Amount), 2) AS average_transaction_amount
FROM CLN_BRANCHES b
JOIN CLN_TRANSACTIONS t ON b.BranchID = t.BranchID
GROUP BY b.BranchID, b.BranchName
ORDER BY total_transaction_volume DESC;

-- ------------------------------------------------------------
-- 11.10 Identify customers with the highest total balances
-- Business question:
-- Which customers hold the largest combined account balances?
-- ------------------------------------------------------------

SELECT * FROM ( SELECT c.CustomerID, c.FirstName, c.LastName, ct.TypeName AS customer_type,
        COUNT(a.AccountID) AS account_count,
        ROUND( SUM(a.Balance), 2 ) AS total_balance
FROM CLN_CUSTOMERS c
JOIN CLN_CUSTOMER_TYPES ct ON c.CustomerTypeID = ct.CustomerTypeID
JOIN CLN_ACCOUNTS a ON c.CustomerID = a.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, ct.TypeName
ORDER BY total_balance DESC )
WHERE ROWNUM <= 10;

-- ------------------------------------------------------------
-- 11.11 Analyze yearly transaction trend
-- Business question:
-- How has transaction activity changed over time?
-- ------------------------------------------------------------

SELECT EXTRACT( YEAR FROM TransactionDate ) AS transaction_year, COUNT(*) AS transaction_count,
    ROUND( SUM(Amount), 2 ) AS total_transaction_volume,
    ROUND( AVG(Amount), 2) AS average_transaction_amount
FROM CLN_TRANSACTIONS
WHERE TransactionDate IS NOT NULL
GROUP BY EXTRACT( YEAR FROM TransactionDate )
ORDER BY transaction_year;

-- ============================================================
-- 12. BUSINESS INSIGHTS
-- ============================================================


-- ------------------------------------------------------------
-- 12.1 Executive KPI Summary
-- ------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM CLN_CUSTOMERS) AS total_customers,
    (SELECT COUNT(*) FROM CLN_ACCOUNTS) AS total_accounts,
    (SELECT COUNT(*) FROM CLN_LOANS) AS total_loans,
    (SELECT COUNT(*) FROM CLN_TRANSACTIONS) AS total_transactions,

    (SELECT ROUND(SUM(Balance), 2)
FROM CLN_ACCOUNTS) AS total_account_balance,
    (SELECT ROUND(SUM(PrincipalAmount), 2)
FROM CLN_LOANS) AS total_loan_principal,

    (SELECT COUNT(*) FROM CLN_LOANS l
     JOIN CLN_LOAN_STATUSES s ON l.LoanStatusID = s.LoanStatusID
     WHERE s.StatusName = 'Overdue') AS overdue_loans,

    (SELECT ROUND(SUM(l.PrincipalAmount), 2)
FROM CLN_LOANS l
JOIN CLN_LOAN_STATUSES s ON l.LoanStatusID = s.LoanStatusID
WHERE s.StatusName = 'Overdue') AS overdue_principal

FROM dual;

-- ------------------------------------------------------------
-- 12.2 Customer Base Insight
-- ------------------------------------------------------------
-- The customer base is relatively balanced across the three
-- customer segments.

-- Large Enterprise: 36.09%
-- Small Business:    32.00%
-- Individual:        31.91%

-- No single customer segment dominates the dataset.

-- ------------------------------------------------------------
-- 12.3 Account Portfolio Insight
-- ------------------------------------------------------------
-- 80.38% of accounts are Active.
-- 15.14% are Inactive.
-- 4.48% are Closed.

-- Business accounts represent the largest account category
-- with 360 accounts (21.80% of all accounts).

-- ------------------------------------------------------------
-- 12.4 Balance Portfolio Insight
-- ------------------------------------------------------------
-- Total customer account balances are approximately 81.04M.

-- Business accounts hold the largest total balance:
-- approximately 17.40M.

-- Payroll accounts have the highest average balance:
-- approximately 50.46K.

-- A small number of accounts have negative balances.
-- These were preserved because negative bank balances may
-- represent overdraft or debt conditions rather than data errors.

-- ------------------------------------------------------------
-- 12.5 Loan Portfolio Insight
-- ------------------------------------------------------------
-- The clean loan portfolio contains 330 loans with total
-- principal exposure of approximately 17.09M.

-- Active loans:   239 (72.42%)
-- Paid Off loans:  57 (17.27%)
-- Overdue loans:   34 (10.30%)

-- ------------------------------------------------------------
-- 12.6 Credit Risk Insight
-- ------------------------------------------------------------
-- Overdue loans represent approximately 10.30% of loan records
-- and approximately 9.78% of total loan principal.

-- Total overdue principal exposure is approximately 1.67M.

-- This segment should receive additional monitoring because
-- it represents the portfolio's most immediate repayment risk.

-- ------------------------------------------------------------
-- 12.7 Loan Exposure by Account Type
-- ------------------------------------------------------------
-- Business accounts have the largest loan exposure:
-- approximately 4.48M, representing about 26.23%
-- of total loan principal.

-- Business accounts also have the highest average loan size
-- at approximately 56.02K.

-- ------------------------------------------------------------
-- 12.8 Transaction Activity Insight
-- ------------------------------------------------------------
-- The clean transaction dataset contains 49,500 transactions
-- with total transaction volume of approximately 123.96M.

-- Transaction volume is distributed approximately as follows:

-- Deposit:     30.37%
-- Transfer:    30.00%
-- Withdrawal:  29.64%
-- Payment:      9.99%

-- Average transaction amounts are very similar across
-- transaction types at approximately 2.5K.

-- ------------------------------------------------------------
-- 12.9 Branch Activity Insight
-- ------------------------------------------------------------
-- Branch 47 has the highest total transaction volume,
-- approximately 2.67M.

-- Transaction activity is relatively evenly distributed
-- across branches, with no branch dominating total volume.

-- ------------------------------------------------------------
-- 12.10 Time Trend Insight
-- ------------------------------------------------------------
-- Transaction activity is relatively stable from 2020 to 2023

-- 2024 contains substantially fewer transactions because
-- available 2024 data only covers the beginning of the year

-- Therefore, 2024 should NOT be interpreted as a decline
-- in banking activity without a complete year of data

-- ------------------------------------------------------------
-- 12.11 Business Recommendations
-- ------------------------------------------------------------

-- 1. Monitor the overdue loan portfolio more closely,
-- particularly the approximately 1.67M principal exposure.

-- 2. Investigate negative account balances separately before
-- classifying them as data-quality errors, as they may represent
-- legitimate overdraft or debt conditions.

-- 3. Avoid year-over-year conclusions for 2024 until a complete
-- annual transaction period is available.