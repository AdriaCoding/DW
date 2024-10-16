## Semantical and Syntactical Optimization

Una query una mica cutre que podria fer un ususari:

> SELECT name FOM Model WHERE price > 10 AND price > 20

Un Relational Database Management System eliminaria les combrovacions de la primera condició (superflua) de la query. Això es diu **Semantic Optimization**

> SELECT id FROM Car C, Model M WHERE C.model = M.name AND C.id=`1234`

Com es computa la nostra query?
 - Join Car i Model -> Select id=`1234`-> Project id

 - Select id=`1234`-> Join Car i Model -> Project id

La decisió de fer-ho de la segona manera (la millor) seria un exemple de **Syntactic Optimization** que fa el nostra Relational Database Management System. 

### Semantical Optimization
Molt bo l'exemple de la diapo 11. Si afegim el segon filtre, disminuirem el tamany del subcunjunt de la taula `e` abans de fer el join implicit a `WHERE e.dpt = d.code`
El exemple de la diapo 12 no té gran interès.

> Fact: Primary keys can never be null

### Relation Algebra
Invented by F.Codd, it is a very interesting algebraic model. However, it is not the same as SQL, as relational algebra deals with sets (no repetitions) and SQL allows for repetitions (DISTINCT keyword).

### Syntactic Optimization.
Try to always push Selections at the bottom of the syntactic tree (first example ^)

Selection and Projection are commutative (rule IV), unless they have conflicting attributes (rule V)
