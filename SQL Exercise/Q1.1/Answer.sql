/*
Assumptions
- The name field in the customer table is `name` and not
`attributes_clearbit_person_name_ full_name` or one of the
other similarly labeled fields
- The address fields in the customer table represent billing information
- I should concatenate the separate address components into a single address field
*/

SELECT
  name,
  email,
  CONCAT(
    address_city_state, ', ',
    address_country, ', ',
    address_zip) AS billing_address,
  arr,
  -- Renaming the column alias to avoid reserved keyword conflict
  status AS customer_status
FROM
  customer
/*
I used LOWER to ensure that if the status was entered without
capitalization, the filter would still catch it
*/
WHERE
  LOWER(status) != 'new lead'
GROUP BY
  name,
  email,
  billing_address,
  arr,
  customer_status;