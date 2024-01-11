/*
Assumptions
- There is no information on the customer detail
(https://dev.chartmogul.com/reference/list-customers) about
the specifics of the cancellation date fields
- The `cancellation_dates` field consists of a single date per row and the
plural name (dateS) exists to accomodate plans that have been
cancelled multiple times
- Time zones don't need to be accounted for
- 'canceled during the last 60 days' implies that we should check for dates
which are within 60 days before the current date, inclusive
*/

/*
Find latest cancellation date per subscription ID,
assuming plans can be cancelled and re-opened multiple times
*/
WITH latest_cancellations AS (
	SELECT
		subscription_uuid,
		MAX(cancellation_dates) AS latest_cancellation_date
	FROM cancellation_date
	GROUP BY subscription_uuid
)

SELECT
	subscription_uuid
FROM latest_cancellations
WHERE latest_cancellation_date >= CURRENT_DATE - INTERVAL '60 days';
