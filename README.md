# Advanced Oracle PL/SQL Portfolio: High-Performance Database Engineering

## 📌 Project Overview
This repository contains a curated collection of production-grade **Oracle PL/SQL** components designed for enterprise environments. The core focus of these scripts is to demonstrate advanced backend capabilities including **bulk data processing (ETL)**, **defensive security programming**, **automated database auditing**, and **memory-optimized caching strategies**.

All components were successfully compiled and tested on an Oracle Cloud Autonomous Database environment utilizing a standard enterprise database schema footprint.

---

## 🛠️ Repository Architecture & Tech Stack
*   **Database Engine:** Oracle Database 19c / 21c (Cloud Architecture)
*   **Core Concepts Demonstrated:** 
    *   Bulk Data Processing (`BULK COLLECT`, `LIMIT`, `FORALL`)
    *   Dynamic SQL & Application Security (`EXECUTE IMMEDIATE`, `DBMS_ASSERT`)
    *   Automated Database Auditing & Constraints (`BEFORE/AFTER Row Triggers`)
    *   Performance Tuning & Memory Caching (`RESULT_CACHE`, Custom Records)

---

## 📁 Included Component Blueprints

### 1. High-Performance ETL Engine (`PKG_PRODUCTS_ETL`)
*   **File:** `pkg_products_etl.sql`
*   **Objective:** Enterprise-scale batch price adjustment with non-breaking in-memory data validation.
*   **Key Architectural Patterns:**
    *   **Context-Switch Optimization:** Implements a state-of-the-art cursor fetching architecture utilizing `BULK COLLECT` alongside an explicit row `LIMIT` to enforce predictable PGA memory consumption regardless of the dataset volume.
    *   **Mass Vector DML:** Utilizes the high-speed `FORALL` driver to pipe the sanitized collections back to the disk in a single round-trip.
    *   **Autonomous Anomaly Capture:** Validates bounds in RAM. If a negative outcome is detected, it falls back gracefully to a capped zero value and pipes the transaction anomaly to a separate log (`etl_error_log`).

### 2. Security & Data Integrity Shield (`Triggers Pack`)
*   **File:** `security_and_audit_triggers.sql`
*   **Objective:** Shifting core governance and audit capabilities straight into the data layer, agnostic of application state.
*   **Key Architectural Patterns:**
    *   **Targeted Column-Audit (`trg_customer_credit_audit`):** Employs explicit column tracking (`AFTER UPDATE OF cust_credit_limit`) to trap modification footprints only when critical telemetry shifts. Maps `:OLD` and `:NEW` states into `customer_credit_audit` including operational contexts via the `USER` global function.
    *   **Transactional Blockades (`trg_prevent_customer_deletion`):** Enforces static compliance bounds. Intercepts structural database removals (`BEFORE DELETE`) and terminates the call stack gracefully utilizing custom application errors (`RAISE_APPLICATION_ERROR`), inducing an instant transactional rollback.

### 3. Dynamic Utilities & Memory Cache (`PKG_CUSTOMER_UTILITIES`)
*   **File:** `pkg_customer_utilities.sql`
*   **Objective:** Adaptable dynamic reporting combined with low-latency memory lookup management.
*   **Key Architectural Patterns:**
    *   **SGA Result Caching:** The `get_customer_tier` function hooks directly into Oracle's `RESULT_CACHE` mechanism. Slow disc-bound lookups are memoized into the SGA, serving recurring analytical footprints directly from RAM.
    *   **Defensive Dynamic SQL:** The `count_table_records` procedure abstracts cross-table matrix scans via dynamic strings (`EXECUTE IMMEDIATE`).
    *   **SQL Injection Hardening:** Leverages `DBMS_ASSERT.SIMPLE_SQL_NAME` to parse incoming arguments *before* the evaluator line fires, completely locking out execution threats and parameter-probing anomalies.

---

## 📈 Code Sample Highlights

### Example: Memory-Safe Batch Data Processing
```sql
-- Loading batches of data into collection to safely manage RAM resources
FETCH c_products BULK COLLECT INTO v_prices LIMIT p_batch_size;
EXIT WHEN v_prices.COUNT = 0;

-- High-performance mass update reducing context switching
FORALL i IN 1..v_prices.COUNT
    UPDATE mirek.products
    SET prod_list_price = v_prices(i).prod_list_price
    WHERE prod_id = v_prices(i).prod_id;
```

### Example: Injection-Hardened Dynamic Evaluation
```sql
-- Assess if the provided table name is structurally safe before evaluation
v_safe_table_name := DBMS_ASSERT.SIMPLE_SQL_NAME(p_table_name);
v_sql := 'SELECT COUNT(*) FROM mirek.' || v_safe_table_name;
EXECUTE IMMEDIATE v_sql INTO p_record_count;
```

---

## 🎯 Best Practices Implemented
*   **Strict Scope Separation:** Architectural distinction between Package Specifications (Public APIs) and Package Bodies (Private Implementations).
*   **Purity Rules Compliance:** Analytical reporting functions are kept deterministic and pure, preventing illegal mutations during simple database reads (`SELECT`).
*   **Robust Boundary Protection:** Every standalone transaction boundary explicitly isolates structural errors through `WHEN OTHERS THEN ROLLBACK` logic patterns, ensuring database states are never left corrupt or dangling.
*   **Clean Structural Typing:** Extensive leverage of anchored column typing (`%TYPE`) to build loose-coupling data layers that don't shatter during production metadata updates.