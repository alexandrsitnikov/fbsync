--------------------------------------------------------------------------------

SET TERM ^ ;

ALTER PROCEDURE SP_SYNC_ARC_TABLE_ALTER(
    TABLE_NAME VARCHAR(50))
AS
declare variable arc_table_name varchar(60);
declare variable sql_alter_table varchar(8192);
declare variable column_name varchar(50);
declare variable column_type varchar(50);
declare variable pk_fields varchar(500);
declare variable rdb$computed_source blob sub_type 1 segment size 80;
declare variable rdb$null_flag smallint;
declare variable rdb$field_type smallint;
declare variable rdb$field_length smallint;
declare variable rdb$type_name varchar(31);
declare variable rdb$field_position smallint;
declare variable rdb$description BLOB SUB_TYPE 1 SEGMENT SIZE 80 CHARACTER SET UNICODE_FSS;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is altering archive table

  -- formatting table name
  table_name = rtrim(upper(:table_name));
  arc_table_name = 'ARC$' || table_name;

  -- creating table only if this table is not exists
  if (exists (
    select 1
    from rdb$relations
    where rdb$relation_name = upper(:arc_table_name)
  )) then
   begin
    -- forming sql script to alter table
    sql_alter_table = '';

    -- checking service columns
    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'action_id') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add ACTION_ID D_SYNC_ITEM_ID PRIMARY KEY';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'action_mode') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add action_mode d_sync_row_action';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'tm') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add TM d_sync_timestamp';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'USER_ID') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add USER_ID d_sync_user_id';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'participant_id') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add participant_id integer';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'context_client_address') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add context_client_address varchar(30)';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'context_session_id') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add context_session_id integer';

    if (not exists(select 1 from sp_sync_table_column_exists(
          :arc_table_name, 'context_transaction_id') where col_exists = 1)) then
     sql_alter_table = sql_alter_table ||
       ', add context_transaction_id integer';

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
      if (not exists(select 1 from sp_sync_table_column_exists(
         :arc_table_name, :column_name) where col_exists = 1)) then
       begin
        sql_alter_table = sql_alter_table || ', add ';
        if (rdb$computed_source is null) then
         sql_alter_table = sql_alter_table || column_name || ' ' ||
          :column_type;
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

        --if (rdb$null_flag is not null) then
        -- sql_alter_table = sql_alter_table || ' NOT NULL';
       end
    end

    for
     select rtrim(rf.rdb$field_name)
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:arc_table_name) and
      upper(rtrim(rf.rdb$field_name)) not in (
       'ACTION_ID', 'ACTION_MODE', 'TM', 'PARTICIPANT_ID',
       'CONTEXT_CLIENT_ADDRESS',
       'USER_ID',
       'CONTEXT_SESSION_ID',
       'CONTEXT_TRANSACTION_ID')
     order by rdb$field_position
     into :column_name
    do
     begin
      if (not exists(select 1 from sp_sync_table_column_exists(
         :table_name, :column_name) where col_exists = 1)) then
       sql_alter_table = sql_alter_table || ', drop ' || column_name ;
     end
   end

   if (char_length(:sql_alter_table) > 0) then
    begin
     sql_alter_table = 'ALTER TABLE ' || :arc_table_name || ' ' ||
       substring(sql_alter_table from 3 for 8192);
     execute statement sql_alter_table;
    end

   execute statement 'alter table ' || :arc_table_name ||
     ' alter ACTION_ID position 1';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter ACTION_MODE position 2';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter TM position 3';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter USER_ID position 4';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter PARTICIPANT_ID position 5';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter context_client_address position 6';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter context_session_id position 7';
   execute statement 'alter table ' || :arc_table_name ||
     ' alter context_transaction_id position 8';

   for
    select rtrim(rf.rdb$field_name), rf.rdb$field_position
     from rdb$relation_fields rf
      left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
     where rf.rdb$relation_name = upper(:table_name)
     order by rdb$field_position
     into :column_name, :rdb$field_position
    do
     begin
      rdb$field_position = :rdb$field_position + 9;
      execute statement 'alter table ' || :arc_table_name ||
       ' alter ' || :column_name || ' position ' || :rdb$field_position;
     end

  -- granting privelegies to archive table.
  -- ordinary users allowed only to insert always and delete
  -- if archive cleanup is enabled

  execute statement 'revoke all on ' || :arc_table_name || ' from public;';
  execute statement 'grant insert on ' || :arc_table_name || ' to public;';

  -- updating description for field
  for
   select rtrim(rf.rdb$field_name), rf.rdb$description
   from rdb$relation_fields rf
    left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
   where rf.rdb$relation_name = upper(:table_name)
   order by rdb$field_position
   into :column_name, :rdb$description
  do
   begin
    update rdb$relation_fields
    set rdb$description = :rdb$description
    where rdb$relation_name = upper(:arc_table_name) and
          rdb$field_name = :column_name;
   end

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

end
^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_TABLE_COLUMN_EXISTS TO PROCEDURE SP_SYNC_ARC_TABLE_ALTER;

--------------------------------------------------------------------------------

SET TERM ^ ;

ALTER PROCEDURE SP_SYNC_ARC_INIT_TABLE(
    TABLE_NAME VARCHAR(50),
    B_INIT SMALLINT,
    ARCHIVE_IGNORE_FIELDS VARCHAR(16384) = null,
    ARCHIVE_UPDATES SMALLINT = 1,
    ARCHIVE_DELETES SMALLINT = 1,
    ARCHIVE_UPDATES_MAX_COUNT SMALLINT = null,
    ARCHIVE_UPDATES_MAX_DAYS SMALLINT = null,
    ARCHIVE_DELETES_MAX_COUNT SMALLINT = null,
    ARCHIVE_DELETES_MAX_DAYS SMALLINT = null)
AS
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

    -- preparing parameters
  if (archive_ignore_fields is not null) then
   archive_ignore_fields = upper(archive_ignore_fields || ';');

  -- writing to SYNC_TABLE
  if (not exists(
    select 1
    from sync_table
    where table_name = :table_name
  )) then
   insert into sync_table(
    table_name, name, archived, archive_updates, archive_deletes,
    archive_updates_max_count, archive_updates_max_days,
    archive_deletes_max_count, archive_deletes_max_days, archive_ignore_fields)
   values (:table_name,
     'Automatically created description for table ' || :table_name,
     :b_init, :archive_updates, :archive_deletes, :archive_updates_max_count,
     :archive_updates_max_days, :archive_deletes_max_count,
     :archive_deletes_max_days, :archive_ignore_fields);
   else
    update sync_table
    set
     archived = :b_init,
     archive_updates = :archive_updates,
     archive_deletes = :archive_deletes,
     archive_updates_max_count = :archive_updates_max_count,
     archive_updates_max_days = :archive_updates_max_days,
     archive_deletes_max_count = :archive_deletes_max_count,
     archive_deletes_max_days = :archive_deletes_max_days,
     archive_ignore_fields = :archive_ignore_fields
    where table_name = :table_name;

  if (b_init = 1) then
   begin
    execute procedure sp_sync_arc_table_create(:table_name);
    execute procedure sp_sync_arc_trigger_create(:table_name,
      :archive_ignore_fields);
    execute procedure sp_sync_arc_table_alter(:table_name);
   end
  else
   begin
    execute procedure sp_sync_arc_trigger_drop(:table_name);
    execute procedure sp_sync_arc_table_drop(:table_name);
   end
end
^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT SELECT,INSERT,UPDATE ON SYNC_TABLE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_CREATE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_CREATE TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_ALTER TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TRIGGER_DROP TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_ARC_TABLE_DROP TO PROCEDURE SP_SYNC_ARC_INIT_TABLE;

--------------------------------------------------------------------------------

