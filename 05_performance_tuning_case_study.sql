/* 
================================================================================
CASE STUDY: Database Query Performance Tuning & Index Optimization
Author: Mirek
Description: This script demonstrates a real-world optimization scenario.
             It showcases the analysis of an Execution Plan, identifying a 
             Performance Trap caused by data-modifying functions (UPPER), 
             and resolving it using a Function-Based Index to reduce CBO cost.
================================================================================
*/

-- =============================================================================
-- STEP 1: INITIAL STATE (The Performance Anomaly)
-- Scenario: Searching for customers by last name using case-insensitive search.
-- Target Table: mirek.customers (Enterprise-scale analytical dataset)
-- =============================================================================

-- Generating the execution plan for an unindexed column query combined with an uppercase function
EXPLAIN PLAN FOR
SELECT cust_id 
FROM mirek.customers 
WHERE UPPER(cust_last_name) = 'JENSON';

-- Displaying the baseline plan
-- NOTE FOR RECRUITERS: Initially, this forced a high-cost HASH JOIN or TABLE ACCESS FULL
-- because standard B-Tree indexes cannot index values wrapped inside functions.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- =============================================================================
-- STEP 2: INTERMEDIATE ATTEMPT (Standard Index Trap)
-- Action: Creating a traditional B-Tree index on the raw column.
-- =============================================================================

CREATE INDEX mirek.idx_cust_last_name_standard 
ON mirek.customers (cust_last_name);

-- Testing if the database engine can utilize the standard index with the UPPER function
EXPLAIN PLAN FOR
SELECT cust_id 
FROM mirek.customers 
WHERE UPPER(cust_last_name) = 'JENSON';

-- Displaying the intermediate plan
-- RESULT: CBO is forced to do an INDEX FAST FULL SCAN (Index Join) instead of an INDEX RANGE SCAN.
-- It reads the entire index block from end to end because the function invalidates direct lookups.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- =============================================================================
-- STEP 3: THE PRODUCTION RESOLUTION (Function-Based Index)
-- Action: Creating an advanced index that materializes the function result in RAM.
-- =============================================================================

-- Drop the sub-optimal standard index to keep the schema lean and avoid DML overhead
DROP INDEX mirek.idx_cust_last_name_standard;

-- Create a tailored Function-Based Index (FBI)
CREATE INDEX mirek.idx_cust_last_name_upper 
ON mirek.customers (UPPER(cust_last_name));


-- =============================================================================
-- STEP 4: VERIFICATION & PERFORMANCE GAIN ANALYSIS (Before vs After)
-- =============================================================================

EXPLAIN PLAN FOR
SELECT cust_id 
FROM mirek.customers 
WHERE UPPER(cust_last_name) = 'JENSON';

-- Displaying the optimized execution plan
-- EXPECTED PRODUCTION METRICS EVALUATION:
-- 1. Operation shifts to a highly optimized INDEX RANGE SCAN (Vertical tree traversal).
-- 2. Physical disk operations drop to TABLE ACCESS BY INDEX ROWID BATCHED.
-- 3. Execution Cost drops exponentially (e.g., from 275 down to 15), yielding a ~94% efficiency gain.
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- =============================================================================
-- CLEANUP (Optional production environment housekeeping)
-- =============================================================================
-- DROP INDEX mirek.idx_cust_last_name_upper;
