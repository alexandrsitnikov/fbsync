ALTER TABLE SYNC_LOG_LOST
ADD TIME_RECOVERED D_SYNC_DATETIME;

COMMENT ON COLUMN SYNC_LOG_LOST.TIME_RECOVERED IS
'Время восстановления записи. Восстановленные записи держатся повторно 1 час, чтобы добавлялись для всех потоков.';

declare external function addHour
timestamp, int
returns timestamp
entry_point 'addHour' module_name 'fbudf';

SET TERM ^ ;

CREATE OR ALTER PROCEDURE SP_SYNC_LOG_GET_BY(
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

     update sync_log_lost
     set time_recovered = current_timestamp
     where time_recovered is null and id = :old_id;

    -- if deadlock
    when sqlcode -901 do
     -- update "lost" records table
     update sync_log_lost set locked = 'L' where id = :old_id;
    end
   end

  -- deleting unlocked lost records information
  begin
   delete from sync_log_lost where locked is null
   and (time_recovered is null or
        (current_timestamp > addHour(time_recovered, 1)));
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
end
^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT SELECT,DELETE,UPDATE ON SYNC_LOG_LOST TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT SELECT,UPDATE ON SYNC_LOG TO PROCEDURE SP_SYNC_LOG_GET_BY;
GRANT EXECUTE ON PROCEDURE SP_SYNC_LOG_WRITE TO PROCEDURE SP_SYNC_LOG_GET_BY;

