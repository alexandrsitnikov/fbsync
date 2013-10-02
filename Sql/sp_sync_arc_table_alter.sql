SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_TABLE_ALTER(
    TABLE_NAME VARCHAR(50))
AS
declare variable arc_table_name varchar(60);
declare variable sql_alter_table varchar(8192);
declare variable sql_create_index varchar(1024);
declare variable column_name varchar(50);
declare variable column_type varchar(50);
declare variable pk_fields varchar(500);
declare variable rdb$computed_source blob sub_type 1 segment size 80;
declare variable rdb$null_flag smallint;
declare variable rdb$field_type smallint;
declare variable rdb$field_length smallint;
declare variable rdb$type_name varchar(31);
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is altering archive table to synchronize structure of tables

  -- formatting table name
  table_name = rtrim(upper(:table_name));
  arc_table_name = 'ARC$' || table_name;
/*
  -- creating table only if this table is not exists
  if (exists (
    select 1
    from rdb$relations
    where rdb$relation_name = upper(:arc_table_name)
  )) then
   begin
    -- forming sql script to create table

    for
     select rtrim(rf.rdb$field_name), rtrim(f.rdb$field_name),
      f.rdb$computed_source,
      rf.rdb$null_flag, f.rdb$field_type, f.rdb$field_length
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:table_name)
     order by rdb$field_position
     into :column_name, :column_type, :rdb$computed_source, :rdb$null_flag,
      :rdb$field_type, :rdb$field_length
    do
     begin
      sql_alter_table = sql_alter_table || ',';
      if (rdb$computed_source is null) then
       sql_alter_table = sql_alter_table || column_name || ' ' || :column_type;
      else
       begin
        -- this field is computed - resolving field type and recreating it
        -- as non-computed field
        select rdb$type_name
        from rdb$types
        where rdb$field_name = 'RDB$FIELD_TYPE' and rdb$type = :rdb$field_type
        into :rdb$type_name;

        if (rdb$type_name = 'VARYING') then
         rdb$type_name = 'VARCHAR';

        sql_alter_table = sql_alter_table || column_name || ' ' ||
         :rdb$type_name || ' (' || :rdb$field_length || ')';
       end

      if (rdb$null_flag is not null) then
       sql_alter_table = sql_alter_table || ' NOT NULL';
     end

   sql_alter_table = sql_alter_table || ');';
   execute statement :sql_alter_table;
   update rdb$relations set rdb$system_flag = 0
   where rdb$relation_name = upper(:arc_table_name);

   -- creating index on primary key to archived records
   pk_fields = '';
   for
    select rtrim(rdb$field_name)
    from rdb$relation_constraints rc
     left join rdb$index_segments i on i.rdb$index_name = rc.rdb$index_name
    where rdb$constraint_type = 'PRIMARY KEY'
    and rc.rdb$relation_name = upper(:table_name)
    order by i.rdb$field_position
    into :column_name
   do
    begin
     if (char_length(pk_fields) > 0) then
      pk_fields = pk_fields || ',';
     pk_fields = pk_fields || column_name;
    end
  end

  -- granting privelegies to archive table.
  -- ordinary users allowed only to insert always and delete
  -- if archive cleanup is enabled

  execute statement 'revoke all on ' || :arc_table_name || ' from public;';
  execute statement 'grant insert on ' || :arc_table_name || ' to public;';
   */
  if (exists(
    select 1
    from sync_table
    where table_name = :table_name
    and (
     archive_updates_max_days is not null or
     archive_updates_max_count is not null or
     archive_deletes_max_days is not null or
     archive_deletes_max_count is not null))) then
   execute statement 'grant delete on ' || :arc_table_name || ' to public;';
end^

SET TERM ; ^

COMMENT ON PROCEDURE SP_SYNC_ARC_TABLE_ALTER IS
'—инхронизаци€: (!внутренн€€ процедура!) создание архивной таблицы дл€ хранени€ измен€емых/удал€емых версий записей.';

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_ALTER TO SYSDBA;
