--------------------------------------------------------------------------------
-- ПОДСИСТЕМА АРХИВИРОВАНИЯ ИЗМЕНЕННЫХ/УДАЛЕННЫХ ДАННЫХ
-- ДЛЯ СУБД FIREBIRD SQL SERVER 2.0
-- (С) Copyright, Александр Ситников, Благовещенск, 2007
--------------------------------------------------------------------------------

-- СОЗДАНИЕ ХРАНИМЫХ ПРОЦЕДУР (ОБЩИЕ ПРОЦЕДУРЫ)

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_CHECK_TABLE_EXISTS
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS(
 table_name varchar(50))
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is checking if field is exists

  if (not exists(
    select 1
    from rdb$relations
    where rdb$relation_name = upper(rtrim(:table_name))
  )) then
   exception e_sync_001_table_not_exists;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS
IS
'Синхронизация: процедура проверки существования указанной таблицы';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_CHECK_TABLE_EXISTS TO SYNC_ADM;

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GEN_ACTION_ID
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_GEN_ACTION_ID
returns (
    action_id bigint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning new action_id value for logging

  action_id = gen_id(sync_gen_action_id, 1);
  suspend;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_GEN_ACTION_ID
IS
'Синхронизация: (!внутренняя процедура!) генерирование нового идентификатора журналирования.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ACTION_ID TO SYNC_ADM;

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GEN_ACTION_ID
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID
returns (
    action_id bigint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning new action_id value for archiving

  action_id = gen_id(sync_gen_arc_action_id, 1);
  suspend;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID
IS
'Синхронизация: (!внутренняя процедура!) генерирование нового идентификатора архивирования.';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID
TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GEN_ARC_ACTION_ID TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GET_CURRENT_USER_ID
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_GET_CURRENT_USER_ID
returns (
    user_id varchar(30))
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning new action_id value for archiving

  user_id = CURRENT_USER;
  suspend;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_GET_CURRENT_USER_ID IS
'Синхронизация: (!внутренняя процедура!) процедура возвращает текущий идентификатор пользователя (по умолчанию - имя).';

--------------------------------------------------------------------------------

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_CURRENT_USER_ID
TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_CURRENT_USER_ID TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_CURRENT_USER_ID TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_CURRENT_USER_ID TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SP_SYNC_GET_CURRENT_USER_ID
-- =========================================

SET TERM ^ ;

CREATE PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT
returns (
    id integer)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is retreiving current default participant id

  -- trying to retreive this id from context variable
  select rdb$get_context('USER_SESSION', 'SYNC#DEFAULT_PARTICIPANT')
  from rdb$database
  into :id;

  -- trying to retreive this id from table
  if (id is null) then
   select id
   from sync_participant
   where def = 1
   into :id;

  -- if id is null than no data found
  if (id is null) then
   exception e_sync_002_no_def_participant;

  -- saving current id to context variable
  rdb$set_context('USER_SESSION', 'SYNC#DEFAULT_PARTICIPANT', :id);

  suspend;
end^

SET TERM ; ^

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT IS
'Синхронизация: (!внутренняя процедура!) процедура возвращает текущий идентификатор участника синхронизации.';

--------------------------------------------------------------------------------

GRANT SELECT ON SYNC_PARTICIPANT TO PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT;

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT
TO PROCEDURE SP_SYNC_ARC_WRITE;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT TO PUBLIC;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_DEFAULT_PARTICIPANT TO SYNC_ADM;

--------------------------------------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
