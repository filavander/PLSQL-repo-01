-- Step 1: Define the granular object record layout (Fix: specified VARCHAR2 lengths and type for cost)
CREATE OR REPLACE TYPE mirek.t_product_pipe_row AS OBJECT (
    v_prod_id    NUMBER,
    v_prod_name  VARCHAR2(200),
    v_final_cost NUMBER
);
/

-- Step 2: Define table type built directly upon the custom object layout
CREATE OR REPLACE TYPE mirek.t_product_pipe_table AS TABLE OF mirek.t_product_pipe_row;
/

-- Step 3: Build high-performance pipelined data transformation stream function
CREATE OR REPLACE FUNCTION get_products_stream(p_discount IN NUMBER)
RETURN mirek.t_product_pipe_table PIPELINED AS
    -- Helper variable to contain intermediate calculated row cost
    v_price NUMBER;
BEGIN
    -- Implicit cursor loop processing inventory data row-by-row
    FOR rec IN (SELECT prod_id, prod_name, prod_list_price FROM mirek.products) LOOP
        
        -- Business logic transformation in-memory
        v_price := rec.prod_list_price - (rec.prod_list_price * (p_discount / 100));
        
        -- Streaming transformed object row immediately to pipe without memory footprint congestion
        PIPE ROW(mirek.t_product_pipe_row(rec.prod_id, UPPER(rec.prod_name), v_price));
        
    END LOOP;
    
    -- Mandatory empty return statement for pipelined call architectures
    RETURN;
END;
/

-- Step 4: High-Performance Data Verification Query (Fix: using TABLE() operator for streaming output)
SELECT * 
FROM TABLE(get_products_stream(10))
WHERE ROWNUM <= 5;
