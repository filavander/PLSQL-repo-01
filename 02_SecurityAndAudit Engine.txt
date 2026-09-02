CREATE TABLE mirek.customer_credit_audit (
    audit_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id     NUMBER,
    old_limit       NUMBER,
    new_limit       NUMBER,
    changed_by      VARCHAR2(100),
    changed_at      DATE DEFAULT SYSDATE
);

CREATE OR REPLACE TRIGGER trg_customer_credit_audit
AFTER UPDATE OF cust_credit_limit ON mirek.customers
FOR EACH ROW
BEGIN
    INSERT INTO mirek.customer_credit_audit
    (
        customer_id,
        old_limit,
        new_limit,
        changed_by,
        changed_at
    )
    VALUES (
        :OLD.cust_id,
        :OLD.cust_credit_limit,
        :NEW.cust_credit_limit,
        USER,
        SYSDATE
    );
END trg_customer_credit_audit;
/