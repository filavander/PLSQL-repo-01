CREATE OR REPLACE PACKAGE pkg_products_etl AS
    /* 
       Author: Miroslaw Pekacki
       Description: Package for bulk processing and optimization of product prices.
       Demonstrates: BULK COLLECT, LIMIT, FORALL, Custom Records, and Error Logging.
    */
    
    -- Header declaration of "process_prices_bulk" procedure.
    PROCEDURE process_prices_bulk(
        p_change_percentage IN NUMBER,
        p_batch_size        IN NUMBER DEFAULT 1000
    );
END pkg_products_etl;
/

CREATE OR REPLACE PACKAGE BODY pkg_products_etl AS

    -- Implementation of "process_prices_bulk" procedure.
    PROCEDURE process_prices_bulk(
        p_change_percentage IN NUMBER,
        p_batch_size        IN NUMBER DEFAULT 1000
    ) AS
        -- Cursor fetching target data for dynamic adjustment
        CURSOR c_products IS
            SELECT prod_id, prod_list_price FROM mirek.products;
            
        -- Custom record to minimize memory footprint in PGA
        TYPE t_price_record IS RECORD(
            prod_id         mirek.products.prod_id%TYPE,
            prod_list_price mirek.products.prod_list_price%TYPE
        );
        
        -- Collection type for bulk processing
        TYPE t_price_tab IS TABLE OF t_price_record;
        
        v_prices            t_price_tab;
        v_temp_price        NUMBER;
    BEGIN
        OPEN c_products;
            LOOP
                -- Loading batches of data into collection to safely manage RAM resources
                FETCH c_products BULK COLLECT INTO v_prices LIMIT p_batch_size;
                
                -- Defining loop exit condition when collection is empty
                EXIT WHEN v_prices.COUNT = 0;
                
                -- In-memory data validation and adjustments
                FOR i IN 1..v_prices.COUNT LOOP
                    v_temp_price := v_prices(i).prod_list_price + (v_prices(i).prod_list_price * (p_change_percentage / 100));
                    
                    -- Integrity Check: If adjusted price is negative, cap it to 0 and log an anomaly
                    IF (v_temp_price < 0) THEN
                        v_prices(i).prod_list_price := 0;
                        
                        INSERT INTO mirek.etl_error_log (prod_id, error_message, log_date) 
                        VALUES (
                            v_prices(i).prod_id,
                            'Attempted to set a negative price (' || ROUND(v_temp_price, 2) || '). Value forced to 0.',
                            SYSDATE
                        );
                    ELSE
                        v_prices(i).prod_list_price := v_temp_price;
                    END IF;
                END LOOP;
                
                -- High-performance mass update reducing context switching between PL/SQL and SQL engines
                FORALL i IN 1..v_prices.COUNT
                    UPDATE mirek.products
                    SET prod_list_price = v_prices(i).prod_list_price
                    WHERE prod_id = v_prices(i).prod_id;
                    
            END LOOP;
        CLOSE c_products;
        
        -- Transaction boundary: Commit changes after entire batch is successfully processed.
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Ensure data consistency by rolling back partial modifications in case of unexpected errors
            ROLLBACK;
            IF c_products%ISOPEN THEN
                CLOSE c_products;
            END IF;
            DBMS_OUTPUT.PUT_LINE('Bulk Processing Failed: ' || SQLERRM);
    END process_prices_bulk;

END pkg_products_etl;
/
