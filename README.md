# Advanced Oracle PL/SQL Portfolio: High-Performance Database Engineering

## 📌 Project Overview
This repository contains a curated collection of production-grade **Oracle PL/SQL** components designed for enterprise environments. The core focus of these scripts is to demonstrate advanced backend capabilities including **bulk data processing (ETL)**, **defensive security programming**, **automated database auditing**, **stateless cursor streaming**, and **memory-optimized caching strategies**.

All components were successfully compiled and tested on an Oracle Cloud Autonomous Database environment utilizing a standard enterprise database schema footprint.

---

## 🛠️ Repository Architecture & Tech Stack
*   **Database Engine:** Oracle Database 19c / 21c / 23ai (Cloud Architecture / OCI)
*   **Core Concepts Demonstrated:** 
    *   Bulk Data Processing (`BULK COLLECT`, `LIMIT`, `FORALL`)
    *   Dynamic SQL & Application Security (`EXECUTE IMMEDIATE`, `DBMS_ASSERT`)
    *   Autonomous Sub-Transactions (`PRAGMA AUTONOMOUS_TRANSACTION`)
    *   Stateless Dataset Streaming (`SYS_REFCURSOR`)
    *   Automated Database Auditing & Constraints (`BEFORE/AFTER Row Triggers`)
    *   Performance Tuning & Memory Caching (`RESULT_CACHE`, Custom Records)

---

## 📁 Included Component Blueprints

### 1. High-Performance ETL Engine (`PKG_PRODUCTS_ETL`)
*   **File:** `pkg_products_etl.sql`
*   **Objective:** Enterprise-scale batch price adjustment with non-breaking in-memory data validation.
*   **Key Architectural Patterns:**
    *   **Context-Switch Optimization:** Implements a state-of-the-art cursor fetching architecture utilizing `BULK COLLECT` alongside an explicit row `LIMIT` to enforce predictable PGA memory consumption regardless of the dataset volume.
    *   **Mass Vector DML:** Utilizes the high-speed `FORALL` driver to pipe the sanitized collections back to the disk in a single database round-trip.
    *   **In-Memory Row Iteration:** Modifies structural scalar fields directly within custom RECORD collections before vector binding occurs.

### 2. Enterprise Integration API & Logger (`PKG_INTEGRATION_API`)
*   **File:** `pkg_integration_api.sql`
*   **Objective:** Secure decoupled integration layer providing external applications with fast data streaming and non-blocking transactional logging.
*   **Key Architectural Patterns:**
    *   **Autonomous Log Isolation:** Leverages `PRAGMA AUTONOMOUS_TRANSACTION` inside the auditing layer. Activity and error traces are permanently written to `etl_error_log` instantly, completely uncoupled from the parent transaction's success, failure, or global `ROLLBACK` states.
    *   **Stateless Cursor Pointer Streaming:** Employs `SYS_REFCURSOR` out-parameters to safely stream extensive rows to calling programs (such as Java/Python application endpoints) without consuming local server memory pools. The client tier maintains fetch controls and memory deallocation responsibilities.

### 3. Security & Data Integrity Shield (`Triggers Pack`)
*   **File:** `security_and_audit_triggers.sql`
*   **Objective:** Shifting core governance and audit capabilities straight into the data layer, agnostic of application state.
*   **Key Architectural Patterns:**
    *   **Targeted Column-Audit (`trg_customer_credit_audit`):** Employs explicit column tracking (`AFTER UPDATE OF cust_credit_limit`) to trap modification footprints only when critical telemetry shifts. Maps `:OLD` and `:NEW` states into `customer_credit_audit` including operational contexts via the `USER` global function.
    *   **Transactional Blockades (`trg_prevent_customer_deletion`):** Enforces static compliance bounds. Intercepts structural database removals (`BEFORE DELETE`) and terminates the call stack gracefully utilizing custom application errors (`RAISE_APPLICATION_ERROR`), inducing an instant transactional rollback.

### 4. Dynamic Utilities & Memory Cache (`PKG_CUSTOMER_UTILITIES`)
*   **File:** `pkg_customer_utilities.sql`
*   **Objective:** Adaptable dynamic reporting combined with low-latency memory lookup management.
*   **Key Architectural Patterns:**
    *   **SGA Result Caching:** The `get_customer_tier` function hooks directly into Oracle's `RESULT_CACHE` mechanism. Slow disc-bound lookups are memoized into the SGA, serving recurring analytical footprints directly from RAM.
    *   **Defensive Dynamic SQL:** The `count_table_records` procedure abstracts cross-table matrix scans via dynamic strings (`EXECUTE IMMEDIATE`).
    *   **SQL Injection Hardening:** Leverages `DBMS_ASSERT.SIMPLE_SQL_NAME` to parse incoming arguments *before* the evaluator line fires, completely locking out execution threats and parameter-probing anomalies.

### 5. Query Performance Tuning Case Study (`05_performance_tuning_case_study.sql`)
*   **File:** `05_performance_tuning_case_study.sql`
*   **Objective:** Eliminating high-cost scanning operations through query execution plan analysis and index engineering.
*   **Key Architectural Patterns:**
    *   **Execution Plan Analytics:** Leverages `EXPLAIN PLAN FOR` and `DBMS_XPLAN.DISPLAY` to dissect Cost-Based Optimizer (CBO) decisions.
    *   **Function Modifier Traps:** Demonstrates how common functional filters (e.g., `UPPER()`) invalidate standard B-Tree lookups, leading to expensive `INDEX FAST FULL SCANS`.
    *   **Advanced Index Engineering:** Solves data mutations in query predicates by deploying an advanced **Function-Based Index (FBI)**, restoring optimal `INDEX RANGE SCAN` behavior and delivering a ~94% reduction in computational cost.

---

## 📈 Code Sample Highlights

### Example: Memory-Safe Batch Data Processing (`LIMIT` + `FORALL`)
```sql
LOOP
    -- Loading batches of data into collection to safely manage RAM resources
    FETCH c_products BULK COLLECT INTO v_products LIMIT 5;
    
    -- Deterministic exits based on collection footprint (safe from kursor state mutation)
    EXIT WHEN v_products.COUNT = 0;

    -- Local RAM records parsing modification
    FOR i IN 1..v_products.COUNT LOOP
        v_products(i).prod_list_price := v_products(i).prod_list_price - 10;
    END LOOP;

    -- High-performance mass update reducing context switching
    FORALL i IN 1..v_products.COUNT
        UPDATE mirek.products
        SET prod_list_price = v_products(i).prod_list_price
        WHERE prod_id = v_products(i).prod_id;
END LOOP;
```

### Example: Non-Blocking Autonomous Anomaly Capturing
```sql
PROCEDURE log_api_activity(p_action_name IN VARCHAR2, p_status_msg IN VARCHAR2) AS
    -- Run this procedure in its own isolated transaction boundary
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO mirek.etl_error_log (prod_id, error_message, log_date)
    VALUES (NULL, p_action_name || ' - ' || p_status_msg, SYSDATE);
    
    -- Commits the log row instantly, even if the parent execution aborts or rolls back
    COMMIT; 
END log_api_activity;
```

### Example: Injection-Hardened Dynamic Evaluation
```sql
-- Assess if the provided table name is structurally safe before evaluation
v_safe_table_name := DBMS_ASSERT.SIMPLE_SQL_NAME(p_table_name);

-- Skim database with completely sanitized parameters
v_sql := 'SELECT COUNT(*) FROM mirek.' || v_safe_table_name;
EXECUTE IMMEDIATE v_sql INTO p_record_count;
```

---

## 🎯 Best Practices Implemented
*   **Strict Scope Separation:** Architectural distinction between Package Specifications (Public APIs) and Package Bodies (Private Implementations) enabling online logic modification without invalidating downstream dependencies.
*   **Purity Rules Compliance:** Analytical reporting functions are kept deterministic and pure, preventing illegal mutations during simple database reads (`SELECT`).
*   **Deterministic Out-Invariants:** Enforces clear parameter initialization. Captures out-parameters dynamically in local application scopes, ensuring safe exception cascades without dangling memory states.
*   **Clean Structural Typing:** Extensive leverage of anchored column typing (`%TYPE`) to build loose-coupling data layers that don't shatter during production metadata updates.
