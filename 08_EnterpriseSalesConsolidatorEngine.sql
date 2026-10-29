CREATE OR REPLACE PACKAGE mirek.pkg_sales_consolidator AS
    /**
     * Package for high-performance sales data consolidation and multi-level auditing.
     * Implements dynamic batching, robust exception saving, and autonomous process tracking.
     */
    PROCEDURE run_consolidation(
        p_year          IN NUMBER,
        p_filter_column IN VARCHAR2,
        p_filter_value  IN VARCHAR2
    );
END pkg_sales_consolidator;
/

CREATE OR REPLACE PACKAGE BODY mirek.pkg_sales_consolidator AS

    /**
     * Private procedure operating within an autonomous transaction.
     * Logs process checkpoints and row-level failures independently of the main transaction outcome.
     */
    PROCEDURE log_process_status(p_code IN NUMBER, p_message IN VARCHAR2) AS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO mirek.error_log (
            log_date, proc_name, oracle_code, error_msg
        ) VALUES (
            SYSDATE, 
            $$PLSQL_UNIT, -- Compile-time directive returning the current package name
            p_code, 
            p_message
        );
        COMMIT; -- Permanent flush to the audit table, entirely isolated from parent rollback
    END log_process_status;

    /**
     * Main orchestration routine for secure, chunked sales consolidation.
     */
    PROCEDURE run_consolidation(
        p_year          IN NUMBER,
        p_filter_column IN VARCHAR2,
        p_filter_value  IN VARCHAR2
    ) AS 
        safe_filter_column VARCHAR2(100);
        v_sql              VARCHAR2(1000);
        
        -- Enterprise best practice: anchored types explicitly bound to the table metadata
        TYPE t_data_rec IS RECORD(
            prod_id     mirek.sales.prod_id%TYPE,
            cust_id     mirek.sales.cust_id%TYPE,
            amount_sold mirek.sales.amount_sold%TYPE
        );
        TYPE t_data_tab IS TABLE OF t_data_rec;
        v_data_tab t_data_tab;
        
        c_cursor           SYS_REFCURSOR; -- Weak ref cursor used for data streaming
        v_total_rows       NUMBER := 0;
        
        -- Bulk array DML exception mapping (ORA-24381)
        e_mass             EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_mass, -24381);
    BEGIN
        -- 1. Initialize process auditing
        log_process_status(0, 'Process Started. Year: ' || p_year || ' | Filter: ' || p_filter_column || '=' || p_filter_value);
        
        -- 2. Mitigate SQL Injection risks by verifying column identifier sanity
        safe_filter_column := DBMS_ASSERT.SIMPLE_SQL_NAME(UPPER(p_filter_column));
        
        -- 3. Construct the dynamic query template for cursor streaming
        v_sql := 'SELECT s.prod_id, s.cust_id, s.amount_sold ' ||
                 'FROM mirek.sales s ' ||
                 'JOIN mirek.times t ON s.time_id = t.time_id ' ||
                 'WHERE t.calendar_year = :1 AND s.' || safe_filter_column || ' = :2';

        -- 4. Open the data pipeline stream with bind variables
        OPEN c_cursor FOR v_sql USING p_year, p_filter_value;
        
        -- 5. Safe batch loop protecting the system from PGA RAM saturation
        LOOP
            -- Fetch rows in optimal, predictable chunks instead of loading the entire table at once
            FETCH c_cursor BULK COLLECT INTO v_data_tab LIMIT 1000;
            EXIT WHEN v_data_tab.COUNT = 0;

            -- In-memory transformation phase inside the local PGA boundary
            FOR i IN 1..v_data_tab.COUNT LOOP
                v_data_tab(i).amount_sold := v_data_tab(i).amount_sold * 1.10;
            END LOOP;

            -- Resilient bulk update phase with row-level error capturing
            BEGIN
                FORALL i IN 1..v_data_tab.COUNT SAVE EXCEPTIONS
                    UPDATE mirek.sales
                    SET amount_sold = v_data_tab(i).amount_sold
                    WHERE prod_id = v_data_tab(i).prod_id 
                      AND cust_id = v_data_tab(i).cust_id;
            EXCEPTION
                WHEN e_mass THEN
                    -- Post-mortem correlation: log failures using the ERROR_INDEX pointer map
                    FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                        log_process_status(
                            SQL%BULK_EXCEPTIONS(i).ERROR_CODE,
                            'Row index: ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX || 
                            ' failed with message: ' || SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE) -- Negative code conversion for SQLERRM
                        );
                    END LOOP;
            END;
        END LOOP;
        
        -- 6. Capture operational row metrics prior to closing the data pipeline resource
        v_total_rows := c_cursor%ROWCOUNT;
        CLOSE c_cursor;
        
        DBMS_OUTPUT.PUT_LINE('Success. Total rows processed by cursor pipeline: ' || v_total_rows);
        log_process_status(200, 'Success. Processed ' || v_total_rows || ' rows.');
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Resource lifecycle defensive safety check
            IF c_cursor%ISOPEN THEN
                CLOSE c_cursor;
            END IF;
            log_process_status(SQLCODE, 'Critical internal crash detected: ' || SQLERRM);
            RAISE;
    END run_consolidation;

END pkg_sales_consolidator;
/
