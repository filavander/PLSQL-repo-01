# Advanced Oracle PL/SQL Portfolio: High-Performance Database Engineering

## 📌 Project Overview
This repository contains production-grade **Oracle PL/SQL** components focusing on **bulk data processing**, **defensive security**, **auditing**, **stateless cursor streaming**, **pipelined transformations**, and **memory optimization**.

## 🛠️ Repository Architecture & Tech Stack
*   **Database Engine:** Oracle Database 19c / 21c / 23ai (Cloud Architecture / OCI)
*   **Core Concepts:** Bulk processing (`BULK COLLECT`, `LIMIT`, `FORALL`), Dynamic SQL (`EXECUTE IMMEDIATE`, `DBMS_ASSERT`), Autonomous transactions, Pipelined functions (`PIPE ROW()`), Triggers, and Object types (`CREATE TYPE AS OBJECT`).

## 📁 Included Component Blueprints
1. **High-Performance ETL Engine (`pkg_products_etl.sql`):** Enterprise batch price adjustment and in-memory validation.
2. **Security & Data Integrity Shield (`security_and_audit_triggers.sql`):** Governance, column audits, and transactional blockades via triggers.
3. **Dynamic Utilities & Memory Cache (`pkg_customer_utilities.sql`):** SGA result caching and defensive dynamic SQL execution.
4. **Enterprise Integration API & Logger (`pkg_integration_api.sql`):** Autonomous logging and `SYS_REFCURSOR` dataset streaming.
5. **Query Performance Tuning Case Study (`05_performance_tuning_case_study.sql`):** Execution plan analysis and Function-Based Index optimization.
6. **High-Performance Data Streaming Pipelines (`06_object_streaming_pipeline.sql`):** Non-blocking transformations using `PIPELINED` and `PIPE ROW()`.
7. **Object-Oriented PL/SQL Architecture (`07_object_types.sql`):** Object-Relational Mapping (ORM) encapsulation with `t_customer_risk_obj`.

*(You can find the full code snippets and structural examples in your repository files `01` through `07`.)*

## 🎯 Best Practices Implemented
*   Strict scope separation between specifications and bodies.
*   Anchored column typing (`%TYPE`) for loose coupling and metadata resilience.
