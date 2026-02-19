# Prove Replication

Let's verify that active-active replication is working by writing data on one node and reading it on the other.

## Create a table on n1

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "
CREATE TABLE cities (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT NOT NULL
);"
```

## Insert data on n1

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "
INSERT INTO cities (id, name, country) VALUES
  (1, 'New York', 'USA'),
  (2, 'London', 'UK'),
  (3, 'Tokyo', 'Japan');"
```

## Read on n2

These rows were written on n1 but should already be replicated to n2 via Spock. Give it a moment, then check:

```bash
sleep 2 && kubectl cnpg psql pgedge-n2 -- -d app -c "SELECT * FROM cities;"
```

You should see all 3 cities.

## Now write on n2

This is the active-active part — n2 can accept writes too:

```bash
kubectl cnpg psql pgedge-n2 -- -d app -c "
INSERT INTO cities (id, name, country) VALUES
  (4, 'Sydney', 'Australia'),
  (5, 'Berlin', 'Germany');"
```

## Read back on n1

All 5 rows should be here — 3 written locally on n1 and 2 replicated from n2:

```bash
sleep 2 && kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM cities ORDER BY id;"
```

You should see all 5 cities. This confirms **bidirectional active-active replication** is working.

## Check replication status

```bash
kubectl cnpg psql pgedge-n1 -- -d app -c "SELECT * FROM spock.sub_show_status();"
```

The subscription should show `replicating` status.
