After running query from 1.a you realize that there are duplicate results for some customers with the same email that show different statuses for that same email.

| row | uuid | email | status | ….. |
| --- | --- | --- | --- | --- |
| 1 | uuid_1 | mailto:bob@examplecompany.com | Active | ….. |
| 2 | uuid_2 | mailto:bob@examplecompany.com | Past Due | ….. |
| 3 | uuid_3 | mailto:bob@examplecompany.com | Canceled | ….. |
| ….. | ….. | ….. | ….. | ….. |

Update Query 1.a or write a set of queries that will consolidate a list of All Customers with their true status where each unique email has 1 defined status.  Define and justify the criteria to set the customer status for emails with multiple rows and different statuses. If you make any assumptions please write them down explicitly (you will have to do so :) ).