# On the impact of data quality

The accuracy of models and ML algorithms decreases as data quality increases.

Here are some measures of data quality

### Completness
`|R|` = #records in the dataset

### Accuracy
`e_A` =  absolute error in attribute `A`
Despŕes hi ha un abús de notació, a la mesura relativa de quality in accuracy li diu `Q_A`

### Timeliness (Freshness)
`age(v)` = now - time when data was loaded/updated in the dataset
`Q_T(v)` = timliness measure. If 1 means that is full recent, if 0 means that it is as old as time.

### Consistency
B = set of business rules

## Trade-offs between dimensions
To get data comening in high Timeliness, you may need to scrifice insurances on Accurancy, Consistency, and Completness

To achive full Completness, you may need to do Missing Value Imputation, which by definition, hinders accuracy and consistency.

## Jargon
• Schema-satisfiability: A schema is satisfiable if there is at least one consistent DB state containing
tuples (i.e. each and every constraint is fulfilled)
• Liveliness: A table/view is lively if there is at least one consistent DB state, so that the table/view
contains tuples
• Redundancy: An integrity constraint is redundant if the consistency of the DB does not depend on it
(none of the tuples it tries to avoid can never exist)
• State-reachability: A given set of tuples is reachable if there is at least one consistent DB state
containing those tuples (and maybe others)
• Query containment (subsumption): A query Q1 is contained in another Q2, if the set of tuples of Q1 is
always contained in the set of tuples of Q2 in every consistent DB state


# Schema and Data integration
PROBLEM: Make a single query on several, heterogenous, datasets.

SOLUTIONS
### (a) Manually query the different databases separately
- Know the available databases
- Data
- Data model
- Query language
- Decompose the query
- Integrate the results
### (b) Create  a new database containing all necessary data
- Design it
- Move data
- Modify the applications to use the new repository
- Test everything
### (c) Build a software layer on top of the databases that automatically splits the queries and integrates the answers
- Automate the processing of the queries
- Add a new software layer that defines two access levels