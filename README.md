Data sample: https://postgrespro.com/docs/postgrespro/10/demodb-bookings-installation.html

```bash
Username: martinig
Pass: _of_7g?oa79.8Buds}Z?{VOTwZtE
Db: dev_braps
Host: source-db-braps-20230720113801970900000004.cmld418qivhi.us-east-1.rds.amazonaws.com

psql --host=source-db-braps-20230720113801970900000004.cmld418qivhi.us-east-1.rds.amazonaws.com --port=5432 --username=martinig --password --dbname=dev_braps
```

Utils:

- https://docs.aws.amazon.com/pt_br/athena/latest/ug/connect-with-odbc-and-power-bi.html
- https://learn.microsoft.com/en-us/power-query/connectors/amazon-redshift

Test queries:

```sql
SELECT * FROM "demodb"."raw_tickets" limit 10;
SELECT COUNT(*) FROM "demodb"."raw_tickets";
SELECT * FROM "demodb"."raw_tickets" where "passenger_name"='MARINA MIKHAYLOVA' limit 10;
SELECT * FROM "raw_tickets" INNER JOIN "raw_bookings" ON "raw_tickets"."book_ref" = "raw_bookings"."book_ref" LIMIT 10;
SELECT SUM("total_amount") AS "Total" FROM "raw_bookings";
```

copy catdemo
from 's3://awssampledbuswest2/tickit/category_pipe.txt'
iam_role 'arn:aws:iam::<aws-account-id>:role/<role-name>'
region 'us-west-2';
