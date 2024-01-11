/*
Note: Sam LaFell contributed significantly to this code

Assumptions
- The final pivot table doesn't need to be tiered; it just needs to contain both
monthly and yearly summary information for the top highest recurring revenues
(MRR and ARR, respectively)
- I added code for a tiered pivot table just to explore that extra step

paid_invoices CTE
- Paid invoices are indicated when transactions.type = 'payment' and
transactions.result = 'successful'

paid_invoice_line_items CTE
- The question asks for "all paid invoices specified by invoice item" . I'll
assume this refers to a long column table containing `invoice_uuid` and
invoice item IDs
- To keep things simple, I'll assume the plan_uuids are the products and
the invoice items. Therefore, `plan_uuid` refers to the specific product and
`plan.name` is the `name of the product` requested in the question

valid_customer_country CTE
- Only countries associated with customers who have paid invoices should
be considered

recurring_revenues CTE
- I can pull `country` from the customer table and `billing_cycle`, `arr`,
and `mrr` from the metrics_subscription table
- The `plan` column in the metrics_subscription table indicates `plan_uuid`
- Each row in the metrics_subscription refers to the mrr and arr earned from
a specific customer's plan, so each row represents one plan for one customer
- Again, the plan IDs are the products and the plan names are the product names
- `Top highest recurring revenue` means the largest summed arr and mrr for a
plan, which needs to be broken down further by country
- Different currencies don't need to be accounted for since that wasn't specified
- Rows with a `monthly` value for billing-cycle contain mrr but not arr
- Vice versa, rows with a `yearly` value for billing-cycle contain arr but not mrr

Final Pivot Table
-Should be composed of both monthly and yearly top highest recurring revenue
*/

-- All Paid Invoices
WITH paid_invoices AS (
  SELECT it.invoice_uuid,
          invoice.customer_uuid
  FROM invoice_transaction it
  INNER JOIN invoice
      ON it.invoice_uuid = invoice.uuid
  WHERE LOWER(trans.type) = 'payment'
      AND LOWER(trans.result) = 'successful'
),

-- All Paid Invoice Line Items
paid_invoice_line_items AS (
	SELECT pi.invoice_uuid,
	        pi.customer_uuid,
	        item.plan_uuid,
	        plan.name AS plan_name
	FROM paid_invoices AS pi
	INNER JOIN invoice_line_item AS item
	    ON item.invoice_uuid = pi.invoice_uuid
	INNER JOIN plan
	    ON item.plan_uuid = plan.uuid
),

-- Get Customers' countries who have Paid
valid_customer_country AS (
  SELECT pi.customer_uuid,
          customer.country
  FROM paid_invoices AS pi
  INNER JOIN customer
      ON pi.customer_uuid = customer.uuid
),

-- All Paid Invoice Line Items with MRR and ARR
recurring_revenues AS (
	SELECT vc.country,
		--Using double-quotes here because of the hyphen in `billing-cycle`
		"ms.billing-cycle" AS billing_cycle,
		--plan_name is the name of the product
		pi.plan_name,
		SUM(ms.mrr) AS total_mrr,
		SUM(ms.arr) AS total_arr
  FROM paid_invoice_line_items AS pi
  INNER JOIN valid_customer_country AS vc
      USING(customer_uuid)
  INNER JOIN metrics_subscription AS ms
      USING(customer_uuid)
	GROUP BY
		vc.country,
		"ms.billing-cycle",
		pi.plan_name
)

-- Final Pivot Table
SELECT
    country,
    billing_cycle,
    plan_name,
		CASE
        WHEN LOWER(billing_cycle) = 'monthly' THEN MAX(total_mrr)
        WHEN LOWER(billing_cycle) = 'yearly' THEN MAX(total_arr)
    END AS highest_revenue
		AS highest_recurring_revenue
		FROM recurring_revenues
GROUP BY
	country,
	billing_cycle,
	plan_name
ORDER BY
    country ASC,
    plan_name ASC;

--Additional query for a tiered pivot table
SELECT
    COALESCE(country, '(overall)') as country,
    COALESCE(billing_cycle, '(overall)') as billing_cycle,
    COALESCE(plan_name, '(overall)') as plan_name,
    CASE
        WHEN LOWER(billing_cycle) = 'monthly' THEN MAX(total_mrr)
        WHEN LOWER(billing_cycle) = 'yearly' THEN MAX(total_arr)
    END AS highest_revenue
FROM recurring_revenues
GROUP BY ROLLUP(
	country,
	billing_cycle,
	plan_name
);