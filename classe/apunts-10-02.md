A la hota de contruit un DW val la pena pensar... Els usuaris que la faran servir, què hauríen de veure?

## Views
Views = SQL queries. They are non-materialized in general, but you can make a materialized view if you pre-compute & store the results in the dard drive. But how do you keep it up to date?...!

### Materialized views.
Segons quin vendor (Oracle, Postgress) implementa les *materialized views* i segons quin (MySQL) no.

**INDEXING example**: You can build a data structure (binary search tree) that maps every employee name to their table entries. This is necessary to avoid the linear cost (actually O(n*m)...) of checking evry employee name.
Options of the sort "FOR UPDATE" are very problematic. 

View expansion can be a problem. You should only write queries on the real tables. Otherwise you will actually be doing unnecessary JOINS



## Problems of today
 - Query answering using views.


### View update.
Keep the views syncronised with the update operations on the database.
BEWARE: some authors refer to the "view update problem" as updating the table from the view, as well as updating the view from the table.

