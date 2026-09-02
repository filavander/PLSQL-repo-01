CREATE OR REPLACE PACKAGE pkg_customer_utilities AS
    --  Function get customer's tier, possible values PLATINIUM, GOLD and SILVER.
    FUNCTION get_customer_tier(
        -- Customers id you want to evaluate tier.
        p_cust_id IN NUMBER
    )
    RETURN VARCHAR2
    RESULT_CACHE;    
   -- Procedure counts number of records in a table.  
   PROCEDURE count_table_records(
        -- Name of the table you want to count the rows.
       p_table_name IN VARCHAR2,
        -- Result (counted number of rows).
       p_record_count OUT NUMBER 
   );
END pkg_customer_utilities;
/
CREATE OR REPLACE PACKAGE BODY pkg_customer_utilities AS
    FUNCTION get_customer_tier(
        -- Customer id you want to evaluate tier.
        p_cust_id NUMBER
    )
    RETURN VARCHAR2
    RESULT_CACHE
    AS
    v_credit_limit NUMBER;
    BEGIN
        -- Query getting customer's credit limit.
        SELECT cust_credit_limit INTO v_credit_limit
        FROM mirek.customers
        WHERE cust_id = p_cust_id;
        
        -- Evaluation of customer's tier.
        IF(v_credit_limit > 10000) THEN
            RETURN 'PLATINIUM';
        ELSIF(v_credit_limit >= 5000 AND v_credit_limit <= 10000) THEN
            RETURN 'GOLD';
        ELSE
            RETURN 'SILVER';
        END IF;
        
        -- If user doesn't exist, return UNKNOWN tier.
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 'UNKNOWN';
    END get_customer_tier;

    PROCEDURE count_table_records(
        -- Table name you want to evaluate rows.
        p_table_name IN VARCHAR2,
        -- The p_record_count variable contains the result of evaluation (number of rows).
        p_record_count OUT NUMBER
    ) AS
    -- The v_sql variable contains dynamic sql query.
    v_sql VARCHAR2(400);
    -- The v_safe_table_name contains safe string of the table name.
    v_safe_table_name VARCHAR2(200);
    BEGIN
        -- Asses if the provided table name is safe.
        v_safe_table_name := DBMS_ASSERT.SIMPLE_SQL_NAME(p_table_name);
        -- Create dynamic sql query.
        v_sql := 'SELECT COUNT(*) FROM mirek.' || v_safe_table_name;
        EXECUTE IMMEDIATE v_sql INTO p_record_count;
        DBMS_OUTPUT.PUT_LINE('Table: ' || p_table_name || ' has ' || p_record_count || ' rows.');
        -- When errors occure, they are cought in EXCEPTION section.
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    END count_table_records;
END pkg_customer_utilities;
/