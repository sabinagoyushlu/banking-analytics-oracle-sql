# banking-analytics-oracle-sql
Oracle SQL project for banking data quality, data cleaning, relational modeling, business analysis, and portfolio insights
## Overview
This project demonstrates an end-to-end banking data analysis workflow using **Oracle SQL**.  
The project focuses on data quality assessment, data cleaning, relational modeling, business analysis, and actionable banking insights.
The workflow follows a structured approach:

**RAW Data → Data Quality Checks → Clean Layer → Relational Model → Business Analysis → Business Insights & Recommendations**
---

## Project Objectives
- Profile and validate raw banking data
- Identify duplicate, missing, inconsistent, and invalid values
- Validate referential integrity across related tables
- Create cleaned analytical tables while preserving raw data
- Build a relational model using primary keys, foreign keys, and business-rule constraints
- Analyze customers, accounts, loans, transactions, and branch activity
- Translate SQL results into business insights and practical recommendations
---

## Dataset Structure
The project works with the following banking tables:

- `ACCOUNT_STATUSES`
- `ACCOUNT_TYPES`
- `CUSTOMER_TYPES`
- `LOAN_STATUSES`
- `TRANSACTION_TYPES`
- `ADDRESSES`
- `BRANCHES`
- `CUSTOMERS`
- `ACCOUNTS`
- `LOANS`
- `TRANSACTIONS`

The original imported tables are preserved in the `RAW_` layer, while cleaned tables use the `CLN_` prefix.
---

## Data Quality Analysis
The project includes checks for:

- Duplicate business keys and complete duplicate rows
- NULL values
- Invalid numeric values
- Invalid and inconsistent date formats
- Dates outside the dataset reference period
- Referential integrity issues
- Country-name inconsistencies
- Non-positive transaction and loan amounts
- Negative account balances
- Loan-date inconsistencies

Cleaning decisions were designed to avoid unsupported assumptions. For example, missing country values remain `NULL` instead of being automatically assigned to a country, and negative balances are preserved because they may represent legitimate overdraft or debt conditions.
---

## Clean Data Layer
Clean tables are created from the raw layer by:

- Removing confirmed duplicate records
- Converting text-based numeric fields to numeric data types
- Standardizing known inconsistent values
- Parsing valid date formats
- Preserving unknown or ambiguous values as `NULL`
- Retaining the original raw tables unchanged

The clean layer includes validation checks to confirm row counts, duplicate removal, table structure, and referential integrity.
---

## Relational Model
The cleaned tables are converted into a relational banking model using:

- `PRIMARY KEY`
- `FOREIGN KEY`
- `NOT NULL`
- `CHECK` constraints

Examples of modeled relationships include:

- Customer → Customer Type
- Customer → Address
- Account → Customer
- Account → Account Type
- Account → Account Status
- Loan → Account
- Loan → Loan Status
- Transaction → Origin Account
- Transaction → Destination Account
- Transaction → Transaction Type
- Transaction → Branch
- Branch → Address
---

## Business Analysis
The SQL analysis answers questions such as:

- How is the customer base distributed across customer segments?
- Which account types are most commonly used?
- What proportion of accounts are Active, Inactive, or Closed?
- Which account types hold the largest total balances?
- How is the loan portfolio distributed by loan status?
- How much principal is associated with overdue loans?
- Which account types have the largest loan exposure?
- Which transaction types generate the highest transaction volume?
- Which branches process the highest transaction volume?
- Which customers hold the largest combined account balances?
- How has transaction activity changed over time?
---

## Key Results
| Metric | Result |
|---|---:|
| Clean Customers | 1,100 |
| Clean Accounts | 1,651 |
| Clean Loans | 330 |
| Clean Transactions | 49,500 |
| Total Account Balance | ~81.04M |
| Total Loan Principal | ~17.09M |
| Overdue Loans | 34 |
| Overdue Principal | ~1.67M |
| Total Transaction Volume | ~123.96M |

### Selected Insights
- **80.38%** of accounts are Active.
- Business accounts represent the largest account category with **360 accounts (21.80%)**.
- Business accounts hold the largest total account balance at approximately **17.40M**.
- The loan portfolio contains **330 loans**, of which **34 (10.30%)** are Overdue.
- Overdue loans represent approximately **9.78% of total loan principal**.
- Business accounts have the largest loan exposure at approximately **4.48M**.
- The clean transaction dataset contains **49,500 transactions** with approximately **123.96M** in total transaction volume.
- Branch 47 has the highest total transaction volume at approximately **2.67M**.
- 2024 transaction data covers only part of the year, so it should not be interpreted as a full-year decline.
---

## Business Recommendations
1. Monitor the overdue loan portfolio more closely, particularly the approximately **1.67M** principal exposure.
2. Investigate negative account balances separately before classifying them as data-quality errors, as they may represent legitimate overdraft or debt conditions.
3. Avoid year-over-year conclusions for 2024 until a complete annual transaction period is available.
---

## Technologies

- **Oracle SQL**
- **Oracle SQL Developer**
- SQL concepts used:
  - Joins
  - CTEs
  - Window functions
  - Aggregations
  - CASE expressions
  - Data type conversion
  - Data validation
  - Primary and foreign keys
  - CHECK constraints
  - Referential integrity analysis
