CREATE OR REPLACE PACKAGE pkg_integration_api AS
    PROCEDURE log_api_activity(p_action_name IN VARCHAR2, p_status_msg IN VARCHAR2);
    PROCEDURE fetch_active_customers_api(p_credit_floor IN NUMBER, p_recordset OUT SYS_REFCURSOR);
END pkg_integration_api;
/

CREATE OR REPLACE PACKAGE BODY pkg_integration_api AS
    -- Procedure logs activity in to mirek.etl_error_log table.
    PROCEDURE log_api_activity(p_action_name IN VARCHAR2, p_status_msg IN VARCHAR2) AS
    -- Prevents rollback inserted rows to mirek.etl_error_log table when main
    -- application performs ROLLBACK.
    PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        -- inserting activity log.
        INSERT INTO mirek.etl_error_log
        (prod_id,error_message,log_date)
        VALUES
        (NULL,p_action_name || ' - ' || p_status_msg,SYSDATE);
        COMMIT;
    END log_api_activity;

    -- Procedure makes available data from mirek.customers table for applications
    -- using reference cursor.
    PROCEDURE fetch_active_customers_api(p_credit_floor IN NUMBER, p_recordset OUT SYS_REFCURSOR) AS
    BEGIN
        -- logging fetching data from mirek.customers into reference cursor.
        log_api_activity('FETCH_CUSTOMERS', 'Initiated search for limit > ' || p_credit_floor);
        -- fetching data to the reference cursor.
        OPEN p_recordset FOR
            SELECT cust_id,cust_last_name,cust_credit_limit
            FROM mirek.customers
            WHERE cust_credit_limit > p_credit_floor;
        EXCEPTION
            WHEN OTHERS THEN
                -- logging unsuccessful fetching data into mirek.etl_error_log table
                -- and raising an error.
                log_api_activity('FETCH_CUSTOMERS_ERROR', SQLERRM);
                RAISE;
    END fetch_active_customers_api;
END pkg_integration_api;
/