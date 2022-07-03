## CRUD

# CREATE
CREATE TABLE product(
product_id int,
product_name varchar(10));

# INSERT
INSERT INTO product
VALUES (1, 'apple');

INSERT INTO product(product_id)
VALUES (2);

# DELETE
DELETE FROM product
WHERE product_id = 2;

# UPDATE
UPDATE product
SET product_name = 'banana'
WHERE product_id = 1;

# VIEW
CREATE VIEW view_prod
AS
SELECT *
FROM product
WHERE product_name = 'banana';

SELECT * FROM view_prod;