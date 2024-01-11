/*
Assumptions
- We can't simply choose the latest status from the `customer` table because
there are no dates
- Rationale for determining true status: In a scenario where the `customer` table
isn't automatically updated, the `metrics_subscription` table may be more
up-to-date.
Because this table includes dates and status, and can be joined easily
to the `customer` table, it's the simplest table to use for our solution.
Therefore, we can go by the latest `start_date` for every `customer_uuid`
in the `metrics_subscription` table to find a customer's updated true subscription
status.
I'll use `start_date` instead of `end_date` because `end_date` may still be in the
future
*/

--Latest start date for each customer
WITH latest_start_dates AS (
  SELECT
    customer_uuid,
    MAX(start_date) AS start_date
  FROM
    metrics_subscription
	--Ensure status is populated
	WHERE status IS NOT NULL
	GROUP BY customer_uuid
),

--Latest status for each customer based on the latest start date
latest_status AS (
	SELECT
		--Use `uuid` alias to simplify JOIN in next SELECT
		ms.customer_uuid AS uuid,
		ms.status AS customer_status,
		ms.start_date
	FROM metrics_subscription AS ms
	JOIN latest_start_dates AS dates
		USING(customer_uuid)
	--Filter on latest metrics subscription start date
	WHERE ms.start_date = dates.start_date
)

SELECT
	customer.name,
	customer.email,
	CONCAT(
		customer.address_city, ', ',
		customer.address_city_state, ', ',
		customer.address_country, ', ',
		customer.address_zip)
	AS billing_address,
	customer.arr,
	ls.customer_status
FROM customer
INNER JOIN latest_status AS ls
	USING(uuid)
WHERE LOWER(ls.customer_status) != 'new lead'
GROUP BY
	customer.name,
	customer.email,
	customer.billing_address,
	customer.arr,
	ls.customer_status;