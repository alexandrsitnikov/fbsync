/* View: V_REL_CONSTRAINTS */
CREATE VIEW V_REL_CONSTRAINTS(
    SQL_DROP,
    SQL_CREATE)
AS
select 'ALTER TABLE ' || rtrim(c.rdb$relation_name) || ' DROP CONSTRAINT ' || rtrim(rc.rdb$constraint_name) || ';' sql_drop,
 'ALTER TABLE ' || rtrim(c.rdb$relation_name) || ' ADD CONSTRAINT ' || rtrim(rc.rdb$constraint_name) || ' FOREIGN KEY ('
 || rtrim(i2.rdb$field_name) || ') REFERENCES ' || rtrim(c2.rdb$relation_name) || ' (' || rtrim(i.rdb$field_name) ||') ;' sql_create
from rdb$ref_constraints rc
 left join rdb$relation_constraints c
  on c.rdb$constraint_name = rc.rdb$constraint_name
 left join rdb$relation_constraints c2
  on c2.rdb$constraint_name = rc.rdb$const_name_uq
 left join rdb$index_segments i on i.rdb$index_name = c2.rdb$index_name
 left join rdb$index_segments i2 on i2.rdb$index_name = c.rdb$index_name
;

