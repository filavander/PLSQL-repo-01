-- ========================================================================
-- Description: Object Type Specification for Customer Risk Assessment
-- Demonstrates: Object-Relational PL/SQL mapping and member function encapsulation.
-- ========================================================================
CREATE OR REPLACE TYPE mirek.t_customer_risk_obj AS OBJECT (
    customer_id     NUMBER,
    last_name       VARCHAR2(100),
    credit_limit    NUMBER,
    
    -- Declaring a member function to calculate risk exposure dynamically
    MEMBER FUNCTION get_available_exposure RETURN NUMBER
);
/

-- ========================================================================
-- Description: Object Type Body implementing member business logic
-- ========================================================================
CREATE OR REPLACE TYPE BODY mirek.t_customer_risk_obj AS
    MEMBER FUNCTION get_available_exposure RETURN NUMBER AS
        v_limit NUMBER;
    BEGIN
        -- Safe exposure is capped at 80% of the customer's total credit limit.
        -- 'self' references the current object instance state in memory.
        v_limit := self.credit_limit * 0.8;
        RETURN v_limit;
    END;
END;
/

-- ========================================================================
-- Description: Anonymous block verifying Object-Relational Mapping (ORM)
-- ========================================================================
DECLARE
    -- Declaring an instance variable of the custom object type
    v_client_obj mirek.t_customer_risk_obj;
BEGIN
    -- Directly instantiating the object via its constructor within the SELECT clause
    SELECT mirek.t_customer_risk_obj(cust_id, cust_last_name, cust_credit_limit)
    INTO v_client_obj
    FROM mirek.customers
    WHERE cust_id = 13;
    
    -- Accessing object attributes and invoking the member function
    DBMS_OUTPUT.PUT_LINE('Last name: ' || v_client_obj.last_name || 
                         ' | Safe Exposure Limit: ' || v_client_obj.get_available_exposure());
END;
/
