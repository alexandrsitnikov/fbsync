--------------------------------------------------------------------------------
-- ПОДСИСТЕМА АРХИВИРОВАНИЯ ИЗМЕНЕННЫХ/УДАЛЕННЫХ ДАННЫХ
-- ДЛЯ СУБД FIREBIRD SQL SERVER 2.0
-- (С) Copyright, Александр Ситников, Благовещенск, 2007
--------------------------------------------------------------------------------

-- СОЗДАНИЕ ХРАНИМЫХ ПРОЦЕДУР (ПРОЦЕДУРЫ АРХИВИВРОВАНИЯ ИЗМЕНЯЕМЫХ ДАННЫХ)

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_CLEANUP_MAX_COUNT
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT (
    table_name varchar(30),
    max_count smallint,
    mode char(1))
as
declare variable last_call_param varchar(40);
declare variable last_call_tm_s varchar(50);
declare variable minute_period double precision;
declare variable x double precision;
declare variable i integer;
declare variable sql varchar(8192);
declare variable arc_table_name varchar(50);
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure doing cleanup of archive table by maximum count of records
---of specified type

  -- preparing archive table name
  arc_table_name = 'ARC$' || rtrim(upper(:table_name));

  -- calling this procedure only once in three minutes
  last_call_param = 'SYNC#ARC_CLEANUP_MAX_COUNT.' ||
   upper(rtrim(:table_name));
  last_call_tm_s  = rdb$get_context('USER_SESSION', last_call_param);

  minute_period = cast(1.0 as double precision)/12/60;
  minute_period = minute_period * 3;

  x = cast((current_timestamp -
    cast(last_call_tm_s as timestamp)) as double precision);

  if ((last_call_tm_s is null) or
      (x > minute_period) or (x < -minute_period) ) then
   begin
    sql = 'delete from ' || :arc_table_name || ' where action_id < (
select min(action_id)
from (select first ' || :max_count || ' action_id
from ' || :arc_table_name || ' where action_mode = '''||:mode||
''' order by action_id desc))';

    execute statement sql;

    i = rdb$set_context('USER_SESSION', last_call_param,
     cast(current_timestamp as varchar(40)));
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT IS
'Синхронизация: (!внутренняя процедура!) автоматическая очистка архивной таблицы по критерию максимального кол-ва записей.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT
TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT TO SYNC_ADM;

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_CLEANUP_MAX_DAYS
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS (
    table_name varchar(30),
    max_days smallint,
    mode char(1))
as
declare variable last_call_param varchar(40);
declare variable last_call_tm_s varchar(50);
declare variable minute_period double precision;
declare variable x double precision;
declare variable i integer;
declare variable sql varchar(8192);
declare variable arc_table_name varchar(50);
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure doing cleanup of archive table by maximum stored days
-- of records of specified type

  -- preparing archive table name
  arc_table_name = 'ARC$' || rtrim(upper(:table_name));

  -- calling this procedure only once in three minutes
  last_call_param = 'SYNC#ARC_CLEANUP_MAX_COUNT.' ||
   upper(rtrim(:table_name));
  last_call_tm_s  = rdb$get_context('USER_SESSION', last_call_param);

  minute_period = cast(1.0 as double precision)/12/60;
  minute_period = minute_period * 3;

  x = cast((current_timestamp -
    cast(last_call_tm_s as timestamp)) as double precision);

  if ((last_call_tm_s is null) or
      (x > minute_period) or (x < -minute_period) ) then
   begin
    sql = 'delete from ' || :arc_table_name || ' where tm < CURRENT_DATE - '
     || :max_days || ' and action_mode = '''|| :mode || ''';';

    execute statement sql;

    i = rdb$set_context('USER_SESSION', last_call_param,
     cast(current_timestamp as varchar(40)));
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS IS
'Синхронизация: (!внутренняя процедура!) автоматическая очистка архивной таблицы по критерию кол-ва дней хранения данных.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS
TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_RECOVER_RECORD
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_RECOVER_RECORD (
    table_name varchar(50),
    action_id bigint)
as
declare variable arc_table_name varchar(35);
declare variable archived smallint;
declare variable x integer;
declare variable fld_list varchar(8192);
declare variable fn varchar(1024);
declare variable rdb$computed_source blob sub_type 1 segment size 80;
declare variable column_name varchar(40);
declare variable f smallint;
declare variable sql varchar(30000);
declare variable pk_where varchar(8192);
declare variable rec_exists smallint;
begin

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is recovering specified version of archived record

  table_name = rtrim(upper(:table_name));
  arc_table_name = 'ARC$'||:table_name;

  -- performing checks
  execute procedure sp_sync_check_table_exists(:table_name);

  -- performing check for table must be archived
  select archived from sync_table where table_name = :table_name into :archived;

  -- no sync table data record
  if (archived is null) then
   exception e_sync_003_no_sync_table;

  -- check for table has archived mark
  if (archived <> 1) then
   exception e_sync_004_table_not_archived;

  -- looking up record in archive
  sql = 'select cast(1 as integer) from ' || :arc_table_name ||
   ' where action_id = ' || :action_id || ';';

  execute statement sql into :x;

  if (x is null) then
   exception e_sync_005_arc_recover_no_data;

  -- building record where string by it's primary key
  pk_where = '';
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
    if (char_length(pk_where) > 0) then
     pk_where = pk_where || ' || '' AND '' || ';
    pk_where = pk_where || '''' || column_name || ' = '''''' || ' || :column_name
    || ' || ''''''''';
   end

  if (char_length(pk_where) = 0) then
   exception e_sync_006_arc_recover_no_pk;

  sql = 'select '||:pk_where||' from ' || :arc_table_name || ' where action_id = ' ||
    :action_id || ';';
  execute statement sql into :pk_where;

  -- looking up record in main table
  sql = 'select cast(1 as smallint) from ' || :table_name ||
   ' where ' || :pk_where || ';';

  execute statement sql into :rec_exists;

  if (rec_exists is not null) then
   begin
    -- if record exists - updating it
    sql = 'update ' || :table_name || ' set ';
    f = 1;
    for
     select rtrim(rf.rdb$field_name), f.rdb$computed_source
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:table_name)
     order by rdb$field_position
     into :column_name, :rdb$computed_source
    do
     if (rdb$computed_source is null) then
     begin
      if (f = 0) then
       sql = sql || ',';
      sql = sql || '
       ' || :column_name || ' = (select ' || :column_name || ' from ' ||
       :arc_table_name || ' where action_id = ' || :action_id || ')';
      f = 0;
     end

    sql = sql || ' where ' || :pk_where || ';';
   end
  else
   begin
    sql = 'insert into ' || :table_name || ' (';
    fld_list = '';
    f = 1;
    for
     select rtrim(rf.rdb$field_name), f.rdb$computed_source
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:table_name)
     order by rdb$field_position
     into :column_name, :rdb$computed_source
    do
     if (rdb$computed_source is null) then
     begin
      if (f = 0) then
       fld_list = fld_list || ',';
      fld_list = fld_list || :column_name;
      f = 0;
     end

    sql = sql || :fld_list || ') select ' || :fld_list || ' from ' ||
     :arc_table_name || ' where action_id = ' || :action_id || ';';

   end

  x = rdb$set_context('USER_TRANSACTION', 'SYNC_ARCHIVE_RECOVERING', '1');

  execute statement sql;

  x = rdb$set_context('USER_TRANSACTION', 'SYNC_ARCHIVE_RECOVERING', null);
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_RECOVER_RECORD IS
'Синхронизация: восстановление данных из архивной таблицы по указанному ACTION_ID.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_ARC_RECOVER_RECORD;

--------------------------------------------------------------------------------

GRANT SELECT ON SYNC_TABLE TO PROCEDURE SP_SYNC_ARC_RECOVER_RECORD;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_RECOVER_RECORD TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_RECOVER_RECORD TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_RECOVER
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_RECOVER (
    table_name varchar(30),
    where_str varchar(8192) = '',
    time_from timestamp = '01.01.1900',
    time_to timestamp = current_timestamp)
as
declare variable arc_table_name varchar(35);
declare variable sql varchar(8192);
declare variable action_id bigint;
begin

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is recovering records specified by where_str condition and
-- time condition

  -- performing checks
  execute procedure sp_sync_check_table_exists(:table_name);

  -- initalizing default parameter values
  if (where_str is null) then where_str = '';
  if (time_from is null) then time_from = '01.01.1900';
  if (time_to is null) then time_to = CURRENT_TIMESTAMP;

  -- initalizing table names
  table_name = rtrim(upper(:table_name));
  arc_table_name = 'ARC$' || :table_name;

  -- creating sql to select archived records
  sql = 'select cast(action_id as bigint) from ' || :arc_table_name ||
   ' where tm between ''' ||
   :time_from || ''' and ''' || :time_to || ''' ';

  -- adding custom condition (where_str)
  if (char_length(coalesce(:where_str, '')) > 0) then
   sql = sql || ' and (' || :where_str || ')';

  sql = sql || ' order by action_id;';

  -- for each found record performing recover
  for
   execute statement sql
   into :action_id
  do
   execute procedure sp_sync_arc_recover_record(:table_name, :action_id);
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_RECOVER IS
'Синхронизация: восстановление данных из архивной таблицы по указанным критериям.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS
TO PROCEDURE SP_SYNC_ARC_RECOVER;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_RECOVER_RECORD
TO PROCEDURE SP_SYNC_ARC_RECOVER;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_RECOVER TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_RECOVER TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_TABLE_CREATE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_TABLE_CREATE (
    table_name varchar(50))
as
declare variable arc_table_name varchar(60);
declare variable sql_create_table varchar(8192);
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

-- this procedure is creating archive table

  -- formatting table name
  table_name = rtrim(upper(:table_name));
  arc_table_name = 'ARC$' || table_name;

  -- creating table only if this table is not exists
  if (not exists (
    select 1
    from rdb$relations
    where rdb$relation_name = upper(:arc_table_name)
  )) then
   begin
    -- forming sql script to create table
    sql_create_table = 'create table ' || arc_table_name || ' (' ||
    'ACTION_ID D_SYNC_ITEM_ID PRIMARY KEY,
     action_mode d_sync_row_action,
     TM d_sync_timestamp,
     USER_ID d_sync_user_id,
     participant_id integer,
     context_client_address varchar(30),
     context_session_id integer,
     context_transaction_id integer';

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
      sql_create_table = sql_create_table || ',';
      if (rdb$computed_source is null) then
       sql_create_table = sql_create_table || column_name || ' ' || :column_type;
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

        sql_create_table = sql_create_table || column_name || ' ' ||
         :rdb$type_name || ' (' || :rdb$field_length || ')';
       end

      if (rdb$null_flag is not null) then
       sql_create_table = sql_create_table || ' NOT NULL';
     end
   sql_create_table = sql_create_table || ');';
   execute statement :sql_create_table;
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

    -- creating index on primary key fields
   if (char_length(pk_fields) > 0) then
    begin
     sql_create_index = 'create index ix_' || arc_table_name || '_pk on ' ||
      :arc_table_name || '(' || :pk_fields || ');';
     execute statement :sql_create_index;
    end

   -- creating index on timestamp field
   sql_create_index = 'create index ix_' || arc_table_name || '_tm on ' ||
      :arc_table_name || '(tm);';
   execute statement :sql_create_index;

   -- creating index on action
   sql_create_index = 'create index ix_' || arc_table_name || '_ac on ' ||
      :arc_table_name || '(action_mode);';
   execute statement :sql_create_index;

   -- creating index on action descended field
   sql_create_index = 'create DESCENDING index ix_' || arc_table_name || '_ad on ' ||
      :arc_table_name || '(action_id);';
   execute statement :sql_create_index;

  end

  -- granting privelegies to archive table.
  -- ordinary users allowed only to insert always and delete
  -- if archive cleanup is enabled

  execute statement 'revoke all on ' || :arc_table_name || ' from public;';
  execute statement 'grant insert on ' || :arc_table_name || ' to public;';

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

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_TABLE_CREATE IS
'Синхронизация: (!внутренняя процедура!) создание архивной таблицы для хранения изменяемых/удаляемых версий записей.';

--------------------------------------------------------------------------------

GRANT SELECT ON SYNC_TABLE TO PROCEDURE SP_SYNC_ARC_TABLE_CREATE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_CREATE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_CREATE TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_TABLE_DROP
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_TABLE_DROP (
    table_name varchar(50))
as
declare variable arc_table_name varchar(60);
declare variable sql_drop_table varchar(8192);
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is dropping trigger for table to archive

  arc_table_name = 'ARC$' || table_name;

  if (exists (
    select 1
    from rdb$relations
    where rdb$relation_name = upper(:arc_table_name)
  )) then
   begin
    sql_drop_table = 'drop table ' || arc_table_name || ';';
    execute statement :sql_drop_table;
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_TABLE_DROP
IS
'Синхронизация: (!внутренняя процедура!) удаление архивной таблицы.';

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_DROP TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_DROP TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_TRIGGER_CREATE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE (
    table_name varchar(50))
as
declare variable arc_trigger_name varchar(60);
declare variable sql varchar(8192);
declare variable column_name varchar(100);
declare variable has_pk smallint;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is creating trigger for table to archive
-- updating/deleting versions of records

  -- performing checks
  execute procedure sp_sync_check_table_exists(:table_name);

  -- preparing trigger name
  table_name = upper(table_name);
  arc_trigger_name = 'T_SYNC$' || :table_name || '_BUD';

  ---

  -- preparing sql to create trigger
  sql = '
     active before update or delete position 32767
AS
  declare variable mode char(1);
  declare variable where_str varchar(1024);
begin
  if (updating)  then mode = ''+'';
  if (deleting)  then mode = ''-'';

  where_str = ''1=1'';';

  ---

  -- preparing sql to query record by it's primary key
  has_pk = 0;
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
     sql = sql || '
  where_str = where_str || '' and ' || :column_name || ' = '''''' || OLD.' || :column_name || '|| ''''''''; ';
     has_pk = 1;
    end

  ---

  --- if there is no primary key, using all columns values
  if (has_pk = 0) then
   begin
    for
     select rtrim(rf.rdb$field_name)
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:table_name)
     order by rdb$field_position
     into :column_name
    do
     begin
     sql = sql || '
  where_str = where_str || '' and ' || :column_name || ' = '''''' || OLD.' || :column_name || '|| ''''''''; ';
     end
   end

  ---

  --- performing check that any column is changed

  sql = sql || '
  if ((updating and ((1=0) ';

  for
   select rtrim(rf.rdb$field_name)
   from rdb$relation_fields rf
    left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
   where rf.rdb$relation_name = upper(:table_name)
   order by rdb$field_position
   into :column_name
  do
   begin
    sql = sql || '
   or ((old.'|| :column_name || ' <> new.'|| :column_name || ') or ((old.'||
   :column_name || ' is null and new.'|| :column_name || ' is not null) or new.'||
   :column_name || ' is not null and new.'|| :column_name || ' is null))';
   end

  sql = sql || '
  )) or (deleting)) THEN ';

  ---

  sql = sql || '
   execute procedure sp_sync_arc_write('''|| :table_name || ''', :mode, :where_str);
end';

  ---

  -- creating trigger
  if (not exists(
   select 1
   from rdb$triggers
   where rdb$trigger_name = upper(:arc_trigger_name)
  )) then
    sql = 'CREATE  trigger ' || :arc_trigger_name || ' for ' || :table_name || sql;
  else
    sql = 'ALTER trigger ' || :arc_trigger_name ||  sql;

  execute statement sql;

  ---
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE
IS
'Синхронизация: (!внутренняя процедура!) создание триггера на таблицу для архивирования изменяемых/удаляемых данных';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_TRIGGER_DROP
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_TRIGGER_DROP (
    table_name varchar(50))
as
declare variable arc_trigger_name varchar(60);
declare variable sql_drop_trigger varchar(8192);
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is dropping trigger for table to archive

  -- preparing trigger name
  table_name = upper(table_name);
  arc_trigger_name = 'T_SYNC$' || :table_name || '_BUD';

  if (exists (
    select 1
    from rdb$triggers
    where rdb$trigger_name = upper(:arc_trigger_name)
  )) then
   begin
    sql_drop_trigger = 'drop trigger ' || arc_trigger_name || ';';
    execute statement :sql_drop_trigger;
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_TRIGGER_DROP IS
'Синхронизация: (!внутренняя процедура!) процедура удаления триггера который архивирует старые версии изменяемых/удаляемых записей';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_DROP TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_DROP TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_INIT_TABLE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_INIT_TABLE (
    table_name varchar(50),
    b_init smallint,
    archive_updates smallint = 1,
    archive_deletes smallint = 1,
    archive_updates_max_count smallint = null,
    archive_updates_max_days smallint = null,
    archive_deletes_max_count smallint = null,
    archive_deletes_max_days smallint = null)
as
begin

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is initializing or uninitializing table for archiving

  -- performing checks
  execute procedure sp_sync_check_table_exists(:table_name);

  if (b_init is null) then b_init = 1;

  table_name = upper(rtrim(:table_name));

  if (archive_updates is null) then archive_updates = 1;
  if (archive_deletes is null) then archive_deletes = 1;

  -- writing to SYNC_TABLE
  if (not exists(
    select 1
    from sync_table
    where table_name = :table_name
  )) then
   insert into sync_table(
    table_name, name, archived, archive_updates, archive_deletes,
    archive_updates_max_count, archive_updates_max_days,
    archive_deletes_max_count, archive_deletes_max_days)
   values (:table_name,
     'Automatically created description for table ' || :table_name,
     :b_init, :archive_updates, :archive_deletes, :archive_updates_max_count,
     :archive_updates_max_days, :archive_deletes_max_count,
     :archive_deletes_max_days);
   else
    update sync_table
    set
     archived = :b_init,
     archive_updates = :archive_updates,
     archive_deletes = :archive_deletes,
     archive_updates_max_count = :archive_updates_max_count,
     archive_updates_max_days = :archive_updates_max_days,
     archive_deletes_max_count = :archive_deletes_max_count,
     archive_deletes_max_days = :archive_deletes_max_days
    where table_name = :table_name;

  if (b_init = 1) then
   begin
    execute procedure sp_sync_arc_table_create(:table_name);
    execute procedure sp_sync_arc_trigger_create(:table_name);
   end
  else
   begin
    execute procedure sp_sync_arc_trigger_drop(:table_name);
    execute procedure sp_sync_arc_table_drop(:table_name);
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_INIT_TABLE
IS
'Синхронизация: инициализация/деинициализация таблицы для архивирования.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT SELECT,INSERT,UPDATE ON SYNC_TABLE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_CREATE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_DROP TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_DROP TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_INIT_TABLE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_INIT_TABLE TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_WRITE_ALLOWED
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_WRITE_ALLOWED (
    table_name varchar(50),
    mode char(1),
    where_str varchar(1024))
returns (
    allowed smallint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning 1 if is it OK to write to the log.
-- this is a placeholder

  allowed = 1;

  suspend;
end^

SET TERM ; ^

COMMENT ON PROCEDURE SP_SYNC_ARC_WRITE_ALLOWED IS
'Синхронизация: функция для переопределения логики записи в архив';

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_WRITE_ALLOWED TO "PUBLIC";
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_WRITE_ALLOWED TO SYSDBA;

-- =========================================

SET TERM ^ ;

ALTER PROCEDURE SP_SYNC_ARC_WRITE_ALLOWED (
    table_name varchar(50),
    mode char(1),
    where_str varchar(1024))
returns (
    allowed smallint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning 1 if is it OK to write to the log.
-- this is a placeholder

  allowed = 1;

  if (isrepluser(user) = 1) then
   allowed = 0;

  suspend;
end
^

SET TERM ; ^

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_ARC_WRITE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_ARC_WRITE (
    table_name varchar(50),
    mode char(1),
    where_str varchar(1024))
as
declare variable arc_action_id bigint;
declare variable sql varchar(16384);
declare variable row_version smallint;
declare variable sync_table_name varchar(30);
declare variable sync_archived smallint;
declare variable sync_archive_updates smallint;
declare variable sync_archive_deletes smallint;
declare variable sync_archive_updates_max_days smallint;
declare variable sync_archive_updates_max_count smallint;
declare variable sync_archive_deletes_max_days smallint;
declare variable sync_archive_deletes_max_count smallint;
declare variable allowed smallint;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is writing data to archive table

  table_name = rtrim(upper(table_name));

  -- if archiving is disabled then exit
  if (rdb$get_context('USER_SESSION', 'SYNC_ARCHIVE_DISABLED') is not null) then
   exit;

  -- if recovering record then exit
  if (rdb$get_context('USER_TRANSACTION',
    'SYNC_ARCHIVE_RECOVERING') is not null) then
   exit;

  -- if in old replication receive mode then exit
  select allowed
  from sp_sync_arc_write_allowed(:table_name, :mode, :where_str)
  into :allowed;

  if (:allowed <> 1) then
   exit;

  -- retreiving the sync table metadata
  select table_name, archived, archive_updates, archive_deletes,
   archive_updates_max_count, archive_deletes_max_count,
   archive_updates_max_days, archive_deletes_max_days
  from sync_table
  where table_name = :table_name
  into :sync_table_name, :sync_archived, :sync_archive_updates,
   :sync_archive_deletes, :sync_archive_updates_max_count,
   :sync_archive_deletes_max_count, :sync_archive_updates_max_days,
   :sync_archive_deletes_max_days;

  -- if no sync table metadata then we raising error
  if (sync_table_name is null) then
   exception e_sync_003_no_sync_table;

  -- if sync table not marked as archived then exiting
  if (:sync_archived = 0) then
   exit;

  -- if sync table not marked as archiving updates then exiting
  if ((:sync_archive_updates <> 1) and (:mode = '+')) then
   exit;

  -- if sync table not marked as archiving deletes then exiting
  if ((:sync_archive_deletes <> 1) and (:mode = '-')) then
   exit;

  -- retreiving new archive log action id
  select action_id from sp_sync_gen_arc_action_id into :arc_action_id;

  -- retreiving this row version
  --sql = 'select cast(count(*) + 1 as smallint) from arc$' || :table_name || ' where ' || :where_str ||
  --' PLAN (ARC$' || :table_name || ' INDEX (IX_ARC$' || :table_name || '_PK));';
  --execute statement sql into :row_version;
  row_version = 1;

  -- building sql text to move record to archive table
  sql = 'insert into arc$' || table_name || '
   select ' || :arc_action_id || ',''' || :mode || ''', CURRENT_TIMESTAMP,
   (select user_id from SP_sync_GET_CURRENT_USER_ID),'
   --|| :row_version
   || '(select id from SP_sync_GET_DEFAULT_PARTICIPANT_ID),
   rdb$get_context(''SYSTEM'', ''CLIENT_ADDRESS''),
   rdb$get_context(''SYSTEM'', ''SESSION_ID''),
   rdb$get_context(''SYSTEM'', ''TRANSACTION_ID''),' ||
   :table_name || '.* from ' || :table_name || ' where ' || :where_str || ';';

  execute statement :sql;

  -- performing cleanup procedures
  if (mode = '+') then
   begin
    if (:sync_archive_updates_max_days is not null) then
     execute procedure sp_sync_arc_cleanup_max_days(:table_name,
      :sync_archive_updates_max_days, '+');
    if (:sync_archive_updates_max_count is not null) then
     execute procedure sp_sync_arc_cleanup_max_count(:table_name,
      :sync_archive_updates_max_count, '+');
   end

  if (mode = '-') then
   begin
    if (:sync_archive_deletes_max_days is not null) then
     execute procedure sp_sync_arc_cleanup_max_days(:table_name,
      :sync_archive_deletes_max_days, '-');
    if (:sync_archive_deletes_max_count is not null) then
     execute procedure sp_sync_arc_cleanup_max_count(:table_name,
      :sync_archive_deletes_max_count, '-');
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_ARC_WRITE
IS
'Синхронизация: (!внутренняя процедура!) процедура записи старых версий изменяющихся/удаляемых данных в архивную таблицу';

--------------------------------------------------------------------------------

GRANT SELECT ON SYNC_TABLE TO PROCEDURE SP_SYNC_ARC_WRITE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID TO PROCEDURE SP_SYNC_ARC_WRITE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_DAYS TO PROCEDURE SP_SYNC_ARC_WRITE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_CLEANUP_MAX_COUNT TO PROCEDURE SP_SYNC_ARC_WRITE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_WRITE TO "PUBLIC";
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_WRITE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_WRITE TO SYNC_ADM;

--------------------------------------------------------------------------------

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

update rdb$relations set rdb$system_flag = 0
where rdb$relation_name like 'ARC$%';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
