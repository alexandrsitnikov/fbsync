--------------------------------------------------------------------------------
-- ПОДСИСТЕМА АРХИВИРОВАНИЯ ИЗМЕНЕННЫХ/УДАЛЕННЫХ ДАННЫХ
-- ДЛЯ СУБД FIREBIRD SQL SERVER 2.0
-- (С) Copyright, Александр Ситников, Благовещенск, 2007
--------------------------------------------------------------------------------

-- СОЗДАНИЕ ХРАНИМЫХ ПРОЦЕДУР (ПРОЦЕДУРЫ ЖУРНАЛИРОВАНИЯ ИЗМЕНЯЕМЫХ ДАННЫХ)

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =============================================================================
-- GENERATORS
-- =============================================================================

CREATE GENERATOR SYNC_GEN_REPLICA_ID;

COMMENT ON GENERATOR SYNC_GEN_REPLICA_ID
IS 'Синхронизация: генератор уникального значения реплики';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =============================================================================
-- EXCEPTIONS
-- =============================================================================

CREATE EXCEPTION E_SYNC_008_SP_ERR 'SYNC#008. Ошибка в хранимой процедуре.';

CREATE EXCEPTION E_SYNC_009_TABLE_NO_PK 'SYNC#009. Для таблицы не задан первичный ключ!';

COMMENT ON EXCEPTION E_SYNC_009_TABLE_NO_PK
IS 'Синхронизация: исключение, которое возникает если таблица не имеет первичного ключа.';


CREATE EXCEPTION E_SYNC_010_LINK_NOT_FOUND
'SYNC#010. Не найден указанный маршрут передачи данных.';

COMMENT ON EXCEPTION E_SYNC_010_LINK_NOT_FOUND
IS 'Синхронизация: исключение, которое возникает если не найден указанный  маршрут передачи данных.';

--------------------------------------------------------------------------------

CREATE EXCEPTION E_SYNC_011_LINK_MULTI_DEF
'SYNC#011. Есть несколько маршрутов от текущего участника обмена. Не могу выбрать маршрут по умолчанию.';

COMMENT ON EXCEPTION E_SYNC_011_LINK_MULTI_DEF
IS 'Синхронизация: исключение, которое возникает если есть несколько равноправных маршрутов от текущего учасника  и неизвестно кому отдать предпочтение.';

--------------------------------------------------------------------------------

CREATE EXCEPTION E_SYNC_012_INV_NEW_ID
'SYNC#012. Нарушение очередности выгрузки из журнала изменений. Новый идентификатор меньше указанного.';

COMMENT ON EXCEPTION E_SYNC_012_INV_NEW_ID
IS 'Синхронизация: исключение, которое возникает если при подготовке журнала к выгрузке новый идентификатор записи журнала получился меньше чем указанный в параметре процедуры.';

--------------------------------------------------------------------------------

CREATE EXCEPTION E_SYNC_013_GET_LOG_ACTIVE
'SYNC#013. В данное время идет получение журнала изменений в другой транзакции.';

COMMENT ON EXCEPTION E_SYNC_013_GET_LOG_ACTIVE IS
'Синхронизация: исключение, которое возникает если при подготовке журнала к выгрузке возникает deadlock.';

--------------------------------------------------------------------------------

-- =========================================
-- SP_SYNC_LOG_WRITE_ALLOWED
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED(
    TABLE_NAME VARCHAR(50),
    MODE CHAR(1),
    row_id varchar(256))
RETURNS (
    ALLOWED SMALLINT)
AS
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
end
^

ALTER PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED(
    TABLE_NAME VARCHAR(50),
    MODE CHAR(1),
    row_id varchar(256))
RETURNS (
    ALLOWED SMALLINT)
AS
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

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED IS
'Синхронизация: функция для переопределения логики записи в журнал';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED TO SYNC_ADM;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_TRIGGER_CREATE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE (
    table_name varchar(50),
    ignore_fields varchar(16384))
as
declare variable log_trigger_name varchar(60);
declare variable sql varchar(16384);
declare variable column_name varchar(100);
declare variable has_pk smallint;
declare variable row_key_new varchar(256);
declare variable row_key_old varchar(256);
declare variable pk_count smallint;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is creating trigger for table to log
-- inserts/updates/deletes of table

  -- performing checks
  execute procedure sp_sync_check_table_exists(:table_name);

  -- preparing trigger name
  table_name = upper(table_name);
  log_trigger_name = 'T_SYNC_L$' || :table_name ;

  -- preparing parameters
  if (ignore_fields is null) then
   ignore_fields = '';

  ignore_fields = upper(ignore_fields || ';');

  ---

  -- preparing sql to create trigger
  sql = '
active after insert or update or delete position 32767
as
  declare variable row_key varchar(256);
  declare variable mode char(1);
  declare variable new_id bigint;
begin
  if (inserting) then mode = ''I'';
  if (updating)  then mode = ''U'';
  if (deleting)  then mode = ''D'';

  row_key = '''';';

  ---

  -- retreiving count of primary key columns
  select count(1)
  from rdb$relation_constraints rc
   left join rdb$index_segments i on i.rdb$index_name = rc.rdb$index_name
  where rdb$constraint_type = 'PRIMARY KEY'
  and rc.rdb$relation_name = upper(:table_name)
  into :pk_count;

  row_key_new = '';
  row_key_old = '';

  -- preparing sql to query record by it's primary key
  has_pk = 0;

  if (pk_count = 1) then
   begin
    select rtrim(rdb$field_name)
    from rdb$relation_constraints rc
     left join rdb$index_segments i on i.rdb$index_name = rc.rdb$index_name
    where rdb$constraint_type = 'PRIMARY KEY'
    and rc.rdb$relation_name = upper(:table_name)
    order by i.rdb$field_position
    into :column_name;

    row_key_new = row_key_new || '
   row_key = row_key || NEW.' || :column_name || ';';
    row_key_old = row_key_old || '
   row_key = row_key || OLD.' || :column_name || ';';
    has_pk = 1;
   end
  else
   begin
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
      row_key_new = row_key_new || '
   row_key = row_key || ''<'' || NEW.' || :column_name || ' || ''>'';';
      row_key_old = row_key_old || '
   row_key = row_key || ''<'' || OLD.' || :column_name || ' || ''>'';';
      has_pk = 1;
     end
   end

  ---

  sql = sql || '
  if (inserting or updating) then
   begin' || :row_key_new || '
   end
  else
   begin' || :row_key_old || '
  end';

  --- if there is no primary key, using all columns values
  if (has_pk = 0) then
   exception e_sync_009_table_no_pk;

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
    if (not (ignore_fields like '%' || upper(:column_name) || ';%' or
             ignore_fields like '%' || upper(:column_name) || ',%')) then
     begin
      sql = sql || '
     or ((old.'|| :column_name || ' <> new.'|| :column_name || ') or ((old.'||
     :column_name || ' is null and new.'|| :column_name || ' is not null) or (old.'||
     :column_name || ' is not null and new.'|| :column_name || ' is null) ))';
     end
   end

  sql = sql || '
  )) or (deleting) or (inserting)) THEN ';

  ---

  sql = sql || '
   select log_id from sp_sync_log_write('''|| :table_name || ''', :row_key, :mode) into :new_id;
end';

  ---

  -- creating trigger
  if (not exists(
   select 1
   from rdb$triggers
   where rdb$trigger_name = upper(:log_trigger_name)
  )) then
    sql = 'CREATE trigger ' || :log_trigger_name || ' for ' || :table_name || sql;
  else
    sql = 'ALTER trigger ' || :log_trigger_name ||  sql;

 execute statement sql;
  ---
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE IS
'Синхронизация: (!внутренняя процедура!) создание триггера на таблицу для журналирования изменяемых/удаляемых данных';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE TO SYNC_ADM;

--------------------------------------------------------------------------------

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_TRIGGER_DROP
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_TRIGGER_DROP(
    TABLE_NAME VARCHAR(50))
AS
declare variable log_trigger_name varchar(60);
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
  log_trigger_name = 'T_SYNC_L$' || :table_name ;

  if (exists (
    select 1
    from rdb$triggers
    where rdb$trigger_name = upper(:log_trigger_name)
  )) then
   begin
    sql_drop_trigger = 'drop trigger ' || log_trigger_name || ';';
    execute statement :sql_drop_trigger;
   end
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_TRIGGER_DROP IS
'Синхронизация: (!внутренняя процедура!) процедура удаления триггера который журналирует старые версии изменяемых/удаляемых записей';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_DROP TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_DROP TO SYNC_ADM;

--------------------------------------------------------------------------------

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- dropping dependend procedures to

DROP PROCEDURE SP_SYNC_LOG_GET;
DROP PROCEDURE SP_SYNC_LOG_GET_BY;
DROP PROCEDURE SP_SYNC_LOG_WRITE;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_WRITE
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_WRITE (
    TABLE_NAME VARCHAR(50),
    ROW_ID VARCHAR(256),
    ACTION_MODE CHAR(1),
    PREV_ROW_ID VARCHAR(256) = NULL)
RETURNS (
    LOG_ID BIGINT)
AS
begin
 suspend;
end^

ALTER PROCEDURE SP_SYNC_LOG_WRITE(
    TABLE_NAME VARCHAR(50),
    ROW_ID VARCHAR(256),
    ACTION_MODE CHAR(1),
    PREV_ROW_ID VARCHAR(256) = NULL)
RETURNS (
    LOG_ID BIGINT)
AS
declare variable sync_table_name varchar(30);
declare variable allowed smallint;
declare variable sync_logged smallint;
declare variable sync_log_inserts smallint;
declare variable sync_log_updates smallint;
declare variable sync_log_deletes smallint;
declare variable log_alert smallint;
declare variable log_mode char(1);
declare variable participant_id integer;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is writing data to log table

  table_name = rtrim(upper(table_name));

  -- validating action mode character
  if (not (:action_mode in ('I', 'U', 'D'))) then
   exception e_sync_008_sp_err;

  -- if logging is disabled then exit
  if (rdb$get_context('USER_SESSION', 'SYNC_LOG_DISABLED') is not null) then
   exit;

  -- if current transaction disables logging then exit
  if (rdb$get_context('USER_TRANSACTION', 'SYNC_LOG_DISABLED') is not null) then
   exit;

  -- if in old replication receive mode then exit
  select allowed
  from sp_sync_log_write_allowed(:table_name, :action_mode, :row_id)
  into :allowed;

  if (:allowed <> 1) then
   exit;

  -- retreiving the sync table metadata
  select table_name, logged, log_inserts, log_updates, log_deletes, log_alert
  from sync_table
  where table_name = :table_name
  into :sync_table_name, :sync_logged, :sync_log_inserts,
    :sync_log_updates, :sync_log_deletes, :log_alert;

  -- special table
  if (table_name = 'SYNC_LOG') then
   begin
    sync_table_name = :table_name;
    sync_logged = 1;
    sync_log_inserts = 1;
   end

  -- if sync table not marked as logged then exiting
  if (:sync_logged = 0) then
   exit;

  -- if sync table not marked as archiving inserts then exiting
  if ((:sync_log_inserts <> 1) and (:action_mode = 'I')) then
   exit;

  -- if sync table not marked as archiving updates then exiting
  if ((:sync_log_updates <> 1) and (:action_mode = 'U')) then
   exit;

  -- if sync table not marked as archiving deletes then exiting
  if ((:sync_log_deletes <> 1) and (:action_mode = 'D')) then
   exit;

  -- if no sync table metadata then we raising error
  if (sync_table_name is null) then
   exception e_sync_003_no_sync_table;

  -- retreiving new action ID
  select action_id from sp_sync_gen_action_id into :log_id;

  if (action_mode = 'D') then
   log_mode = '-';
  else
   log_mode = '+';

  if (prev_row_id = row_id) then
   prev_row_id = null;

  -- if changed primary key values then marking
  if (prev_row_id is not null) then
   begin
    update sync_log
    set id = :log_id, action_mode = '-'
    where table_name = :table_name and row_id = :prev_row_id;

    if (row_count > 0) then
     select action_id from sp_sync_gen_action_id into :log_id;
   end

  select id from sp_sync_get_default_participant into :participant_id;

  -- trying to update in log table
  update sync_log
  set id = :log_id, action_mode = :log_mode, prev_row_id = :prev_row_id,
   participant_id = :participant_id
  where table_name = :table_name and row_id = :row_id;

  -- if update is failed then inserting
  if (row_count = 0) then
   insert into sync_log(id, table_name, row_id, action_mode, prev_row_id,
    participant_id)
    values (:log_id, :table_name, :row_id, :log_mode, :prev_row_id,
    :participant_id);

  if (log_alert = 1) then
   begin
    post_event 'LOG_ALERT';
    post_event 'LOG_ALERT.' || :table_name;
   end

  suspend;
end
^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED TO PROCEDURE SP_SYNC_LOG_WRITE;

--------------------------------------------------------------------------------

GRANT SELECT ON SYNC_TABLE TO PROCEDURE SP_SYNC_LOG_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PROCEDURE SP_SYNC_LOG_WRITE;
GRANT SELECT,INSERT,UPDATE ON SYNC_LOG TO PROCEDURE SP_SYNC_LOG_WRITE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE TO TRIGGER T_SYNC$LOG_DOKYM_AIUD;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE TO PUBLIC;

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_WRITE IS
'Синхронизация: (!внутренняя процедура!) процедура записи в журнал действия по изменению данных';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_INIT_TABLE
-- =========================================

SET TERM ^ ;

RECREATE PROCEDURE SP_SYNC_LOG_INIT_TABLE (
    TABLE_NAME VARCHAR(50),
    B_INIT SMALLINT,
    LOG_IGNORE_FIELDS VARCHAR(16384) = null,
    LOG_ALERT SMALLINT = 1,
    LOG_INSERTS SMALLINT = 1,
    LOG_UPDATES SMALLINT = 1,
    LOG_DELETES SMALLINT = 1)
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
    log_ignore_fields, log_alert)
   values (:table_name,
     'Automatically created description for table ' || :table_name,
     :b_init, :log_inserts, :log_updates, :log_deletes,
     :log_ignore_fields, :log_alert);
   else
    update sync_table
    set
     logged = :b_init,
     log_inserts = :log_inserts,
     log_updates = :log_updates,
     log_deletes = :log_deletes,
     log_ignore_fields = :log_ignore_fields,
     log_alert = :log_alert
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

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT SELECT,INSERT,UPDATE ON SYNC_TABLE TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_CREATE TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_TRIGGER_DROP TO PROCEDURE SP_SYNC_LOG_INIT_TABLE;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_INIT_TABLE TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_INIT_TABLE TO SYNC_ADM;

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_INIT_TABLE
IS 'Синхронизация: инициализация/деинициализация таблицы для журналирования.';

--------------------------------------------------------------------------------

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_GET_BY
-- =========================================

SET TERM ^ ;

RECREATE PROCEDURE SP_SYNC_LOG_GET_BY (
    LOG_ID_FROM BIGINT,
    EXCLUDE_PARTICIPANTS VARCHAR(1024),
    INCLUDE_PARTICIPANTS VARCHAR(1024) = NULL)
RETURNS (
    ID BIGINT,
    TABLE_NAME VARCHAR(30),
    ROW_ID VARCHAR(256),
    ACTION_MODE CHAR(1),
    PARTICIPANT_ID INTEGER,
    UPDATE_COUNT INTEGER,
    TM_INSERTED TIMESTAMP,
    TM_UPDATED TIMESTAMP,
    USER_INSERTED VARCHAR(30),
    USER_UPDATED VARCHAR(30),
    LAST_CONTEXT_CLIENT_ADDRESS VARCHAR(100),
    LAST_CONTEXT_SESSION_ID INTEGER,
    LAST_CONTEXT_TRANSACTION_ID INTEGER,
    LAST_LOG_ID BIGINT,
    ORIG_LOG_ID BIGINT,
    PREV_ROW_ID VARCHAR(256))
AS
declare variable old_id bigint;
declare variable new_id bigint;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is retreiving log data for replication by LOG_ID_FROM

  if (log_id_from is null) then
   log_id_from = 0;

  if (exclude_participants is null) then
   exclude_participants = '';

  if (char_length(INCLUDE_PARTICIPANTS) = 0) then
   INCLUDE_PARTICIPANTS = null;
  else
   include_participants = include_participants || ';';

  exclude_participants = exclude_participants || ';';

  select action_id from sp_sync_gen_action_id into :new_id;
  if (new_id < log_id_from) then
   exception e_sync_012_inv_new_id;

  -- clearing "locked" mark from SYNC_LOG_LOST
  update sync_log_lost set locked = null where locked is not null;

  -- processing "lost" records, that are leaved due their transaction's state
  for
   select id
   from sync_log_lost
   where id <= :LOG_ID_FROM
   into :old_id
  do
   begin
    -- moving record to enddd
    select action_id from sp_sync_gen_action_id into :new_id;

    begin
     update sync_log
     set id = :new_id
     where id = :old_id;
    -- if deadlock
    when sqlcode -901 do
     -- update "lost" records table
     update sync_log_lost set locked = 'L' where id = :old_id;
    end
   end

  -- deleting unlocked lost records information
  begin
   delete from sync_log_lost where locked is null;
  when sqlcode -901 do -- somebody is fetching log too
   exception E_SYNC_013_GET_LOG_ACTIVE;
  end

  if (exists(
       select first 1 id from sync_log where (id > :log_id_from))) then
   begin
    -- inserting dummy separator's record
    begin
     select log_id from sp_sync_log_write('SYNC_LOG', '', 'I', null) into last_log_id;
    when sqlcode -901 do -- somebody is fetching log too
     exception E_SYNC_013_GET_LOG_ACTIVE;
    end

    -- fetching log records
    for
     select id, table_name, participant_id, update_count, tm_inserted, tm_updated,
      user_inserted, user_updated, last_context_client_address,
      last_context_session_id, last_context_transaction_id, row_id, action_mode,
      orig_log_id, prev_row_id
     from sync_log
     where (id > :log_id_from)
     into id, table_name, participant_id, update_count, tm_inserted, tm_updated,
      user_inserted, user_updated, last_context_client_address,
      last_context_session_id, last_context_transaction_id, row_id, action_mode,
      orig_log_id, prev_row_id
    do
     begin
      if (not (exclude_participants like '%' || :participant_id || ';%' or
               exclude_participants like '%' || :participant_id || ',%')) then
       begin
        if ((include_participants is null) or
            ((include_participants is not null) and
             ( (include_participants like '%' || :participant_id || ';%') or
               (include_participants like '%' || :participant_id || ',%') )))
          then
           suspend;
       end
     end
   end

  -- deleting unlocked lost records information
  delete from sync_log_lost where locked is null;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT SELECT,DELETE,UPDATE ON SYNC_LOG_LOST TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT SELECT,UPDATE ON SYNC_LOG TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_GET_BY TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_GET_BY TO SYNC_ADM;

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_GET_BY
IS 'Синхронизация: (!внутренняя процедура!) формирование журнала изменений по указанным параметрам';

--------------------------------------------------------------------------------


-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_GET
-- =========================================

SET TERM ^ ;

RECREATE PROCEDURE SP_SYNC_LOG_GET(
    BY_LINK_ID INTEGER)
RETURNS (
    LINK_ID INTEGER,
    ID BIGINT,
    TABLE_NAME VARCHAR(30),
    ROW_ID VARCHAR(256),
    ACTION_MODE CHAR(1),
    PARTICIPANT_ID INTEGER,
    UPDATE_COUNT INTEGER,
    TM_INSERTED TIMESTAMP,
    TM_UPDATED TIMESTAMP,
    USER_INSERTED VARCHAR(30),
    USER_UPDATED VARCHAR(30),
    LAST_CONTEXT_CLIENT_ADDRESS VARCHAR(100),
    LAST_CONTEXT_SESSION_ID INTEGER,
    LAST_CONTEXT_TRANSACTION_ID INTEGER,
    LAST_LOG_ID BIGINT,
    ORIG_LOG_ID BIGINT,
    PREV_ROW_ID VARCHAR(256))
AS
declare variable my_participant_id integer;
declare variable count_my_participants integer;
declare variable participant_to integer;
declare variable log_position bigint;
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is retreiving log data for replication by sync link

  link_id = :by_link_id;

  select id from sp_sync_get_default_participant into :my_participant_id;

  if (link_id is null) then
   -- retreiving default direction
   begin
    select count(1)
    from sync_link
    where participant_from = :my_participant_id
    into :count_my_participants;

    if (count_my_participants = 0) then
     exception e_sync_010_link_not_found;

    if (count_my_participants > 1) then
     exception e_sync_011_link_multi_def;

    select first 1 id
    from sync_link
    where participant_from = :my_participant_id
    into :link_id;
   end

  if (not exists(select id from sync_link where id = :link_id)) then
   exception e_sync_010_link_not_found;

  select participant_to, log_position
  from sync_link
  where id = :link_id
  into :participant_to, :log_position;

  for
   select id, table_name, participant_id, update_count, tm_inserted, tm_updated,
    user_inserted, user_updated, last_context_client_address,
    last_context_session_id, last_context_transaction_id, last_log_id,
    row_id, action_mode, prev_row_id, ORIG_LOG_ID
   from sp_sync_log_get_by(:log_position, :participant_to)
   into id, table_name, participant_id, update_count, tm_inserted, tm_updated,
    user_inserted, user_updated, last_context_client_address,
    last_context_session_id, last_context_transaction_id, last_log_id,
    row_id, action_mode, :prev_row_id, :ORIG_LOG_ID
  do
   begin
    suspend;
   end
end^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT TO PROCEDURE SP_SYNC_LOG_GET;

GRANT SELECT ON SYNC_LINK TO PROCEDURE SP_SYNC_LOG_GET;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_GET_BY TO PROCEDURE SP_SYNC_LOG_GET;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_GET TO SYSDBA;

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_LOG_GET
IS 'Синхронизация: (!внутренняя процедура!) формирование журнала изменений по указанному идентификатору соединения';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_COMMIT
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_COMMIT (
    link_id integer,
    log_position bigint)
as
begin

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

  UPDATE SYNC_LINK SET LOG_POSITION = :LOG_POSITION WHERE ID = :LINK_ID;
end^

SET TERM ; ^

GRANT SELECT,UPDATE ON SYNC_LINK TO PROCEDURE SP_SYNC_LOG_COMMIT;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_COMMIT TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_COMMIT TO SYNC_ADM;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

COMMENT ON PROCEDURE SP_SYNC_LOG_COMMIT IS 'Синхронизация: (!внутренняя процедура!) процедура подтверждает выгрузку данных по указанной связи';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GEN_REPLICA_ID
-- =========================================

SET TERM ^ ;

create procedure sp_sync_gen_replica_id
returns (id varchar(40))
as
  declare variable participant_id integer;
begin
-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is retreiving new replica id for replication

  select id from sp_sync_get_default_participant into :participant_id;
  id = gen_id(sync_gen_replica_id, 1) ||  '/' || participant_id;

  suspend;
end^

SET TERM ; ^

COMMENT ON PROCEDURE SP_SYNC_GEN_REPLICA_ID IS
'Синхронизация: (!внутренняя процедура!) получение идентификатора реплики';

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT TO PROCEDURE SP_SYNC_GEN_REPLICA_ID;

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_REPLICA_ID TO SYSDBA;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_LOG_WRITE_COPY
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_LOG_WRITE_COPY(
    ORIG_LOG_ID BIGINT,
    TABLE_NAME VARCHAR(50),
    ROW_ID VARCHAR(256),
    LOG_MODE CHAR(1),
    PARTICIPANT_ID INTEGER,
    UPDATE_COUNT INTEGER,
    TM_INSERTED TIMESTAMP,
    TM_UPDATED TIMESTAMP,
    USER_INSERTED VARCHAR(30),
    USER_UPDATED VARCHAR(30),
    LAST_CONTEXT_CLIENT_ADDRESS VARCHAR(100),
    LAST_CONTEXT_SESSION_ID INTEGER,
    LAST_CONTEXT_TRANSACTION_ID INTEGER,
    PREV_ROW_ID VARCHAR(256))
RETURNS (
    LOG_ID BIGINT)
AS
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is writing a copy of log record to log table

  table_name = rtrim(upper(table_name));

  -- retreiving new action ID
  select action_id from sp_sync_gen_action_id into :log_id;

  -- if changed primary key values then marking
  if (prev_row_id is not null) then
   begin
    update sync_log
    set id = :log_id, action_mode = '-'
    where table_name = :table_name and row_id = :prev_row_id;

    if (row_count > 0) then
     select action_id from sp_sync_gen_action_id into :log_id;
   end

  -- trying to update in log table
  update sync_log
  set
   id = :log_id,
   action_mode = :log_mode,
   participant_id = :participant_id,
   update_count = :update_count,
   tm_inserted = :tm_inserted,
   tm_updated = :tm_updated,
   user_inserted = :user_inserted,
   user_updated = :user_updated,
   last_context_client_address = :last_context_client_address,
   last_context_session_id = :last_context_session_id,
   last_context_transaction_id = :last_context_transaction_id,
   orig_log_id = :orig_log_id,
   prev_row_id = :prev_row_id
  where table_name = :table_name and row_id = :row_id;

  -- if update is failed then inserting
  if (row_count = 0) then
   insert into sync_log(id, table_name, row_id, action_mode, participant_id,
    update_count, tm_inserted, tm_updated, user_inserted, user_updated,
    last_context_client_address, last_context_session_id,
    last_context_transaction_id, prev_row_id, orig_log_id)
    values (:log_id, :table_name, :row_id, :log_mode, :participant_id,
    :update_count, :tm_inserted, :tm_updated, :user_inserted, :user_updated,
    :last_context_client_address, :last_context_session_id,
    :last_context_transaction_id, :prev_row_id, :orig_log_id);

  suspend;
end^

SET TERM ; ^

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

COMMENT ON PROCEDURE SP_SYNC_LOG_WRITE_COPY IS
'Синхронизация: (внутренняя процедура) добавляет запись в журнал при копировании его из реплики';

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PROCEDURE SP_SYNC_LOG_WRITE_COPY;

GRANT SELECT,INSERT,UPDATE ON SYNC_LOG TO PROCEDURE SP_SYNC_LOG_WRITE_COPY;

GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE_COPY TO SYSDBA;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GET_SEQUENCE_LIST
-- =========================================

SET TERM ^ ;

create procedure sp_sync_get_sequence_list
returns (seq_name varchar(30),
  seq_val bigint)
as
begin
  suspend;
end^

alter procedure sp_sync_get_sequence_list
returns (seq_name varchar(30),
  seq_val bigint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning list of sequences (generators) to synchronize
-- generator values

  for
   select rtrim(rdb$generator_name)
   from rdb$generators
   where rdb$system_flag is null
   order by rdb$generator_name
   into :seq_name
  do
   begin
    execute statement 'select gen_id(' || :seq_name || ', 0) from rdb$database'
    into :seq_val;
    suspend;
   end
end^

SET TERM ; ^

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

COMMENT ON PROCEDURE SP_SYNC_GET_SEQUENCE_LIST
IS 'Синхронизация: (!внутренняя процедура!) получение списка последовательностей (генераторов) и их значений';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_SEQUENCE_LIST TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_SEQUENCE_LIST TO SYNC_ADM;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
