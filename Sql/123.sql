SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_INIT_TABLE (
    table_name varchar(50),
    b_init smallint,
    log_ignore_fields varchar(16384) = null,
    log_inserts smallint = 1,
    log_updates smallint = 1,
    log_deletes smallint = 1)
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

  if (log_inserts is null) then log_inserts = 1;
  if (log_updates is null) then log_updates = 1;
  if (log_deletes is null) then log_deletes = 1;

    -- preparing parameters
  if (log_ignore_fields is not null) then
   log_ignore_fields = upper(log_ignore_fields || ';');

  -- writing to SYNC_TABLE
  if (not exists(
    select 1
    from sync_table
    where table_name = :table_name
  )) then
   insert into sync_table(
    table_name, name, logged, log_inserts, log_updates, log_deletes,
    log_ignore_fields)
   values (:table_name,
     'Automatically created description for table ' || :table_name,
     :b_init, :log_inserts, :log_updates, :log_deletes,
     :log_ignore_fields);
   else
    update sync_table
    set
     logged = :b_init,
     log_inserts = :log_inserts,
     log_updates = :log_updates,
     log_deletes = :log_deletes,
     log_ignore_fields = :log_ignore_fields
    where table_name = :table_name;

  if (b_init = 1) then
   begin
    execute procedure sp_sync_log_trigger_create(:table_name,
      :log_ignore_fields);
   end
  else
   begin
    execute procedure sp_sync_log_trigger_drop(:table_name);
   end
end^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT SELECT,INSERT,UPDATE ON SYNC_TABLE TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_DROP TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_INIT_TABLE TO SYSDBA;
