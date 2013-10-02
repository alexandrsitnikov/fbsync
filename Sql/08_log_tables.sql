--------------------------------------------------------------------------------
-- ПОДСИСТЕМА АРХИВИРОВАНИЯ ИЗМЕНЕННЫХ/УДАЛЕННЫХ ДАННЫХ
-- ДЛЯ СУБД FIREBIRD SQL SERVER 2.0
-- (С) Copyright, Александр Ситников, Благовещенск, 2007
--------------------------------------------------------------------------------

-- 05.01.2008. СИСТЕМА ЖУРНАЛИРОВАНИЯ УКАЗАТЕЛЕЙ НА ИЗМЕНЕНИЯ. ТАБЛИЦЫ ДАННЫХ.

-- =============================================================================
-- DOMAINS
-- =============================================================================

CREATE DOMAIN D_SYNC_ITEM_ID_NULLABLE AS BIGINT;

COMMENT ON DOMAIN D_SYNC_ITEM_ID_NULLABLE
IS 'Синхронизация: тип идентификатора элемента (записи), может быть не заполненным.';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

CREATE DOMAIN D_SYNC_INT AS
INTEGER;

COMMENT ON DOMAIN D_SYNC_INT IS 'Синхронизация: тип поля INTEGER';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

CREATE DOMAIN D_SYNC_DATETIME AS TIMESTAMP;

COMMENT ON DOMAIN D_SYNC_DATETIME
IS 'Синхронизация: тип для хранения даты и времени (может быть пустым)';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

CREATE DOMAIN D_SYNC_TIMESTAMP_NULLABLE AS
TIMESTAMP;

COMMENT ON DOMAIN D_SYNC_TIMESTAMP_NULLABLE
IS 'Синхронизация: поле подставления времени (допускающее пустые значения)';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

CREATE DOMAIN D_SYNC_ROW_ID_NULLABLE AS
VARCHAR(256) CHARACTER SET WIN1251
COLLATE WIN1251 ;

COMMENT ON DOMAIN D_SYNC_ROW_ID_NULLABLE
IS 'Синхронизация: указатель на запись, который может быть пустым';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =============================================================================
-- TABLES
-- =============================================================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ОСНОВНАЯ ТАБЛИЦА ЖУРНАЛА

CREATE TABLE SYNC_LOG (
    ID              D_SYNC_ITEM_ID NOT NULL /* D_SYNC_ITEM_ID = BIGINT NOT NULL */,
    TABLE_NAME      D_SYNC_TABLE_NAME /* D_SYNC_TABLE_NAME = VARCHAR(128) NOT NULL */,
    ROW_ID          D_SYNC_ROW_ID NOT NULL /* D_SYNC_ROW_ID = VARCHAR(256) NOT NULL */,
    ACTION_MODE     D_SYNC_ROW_ACTION /* D_SYNC_ROW_ACTION = CHAR(1) NOT NULL CHECK ((value in ('+','-'))) */,
    PARTICIPANT_ID  D_SYNC_PARTICIPANT_ID /* D_SYNC_PARTICIPANT_ID = INTEGER NOT NULL */,
    UPDATE_COUNT    INTEGER DEFAULT 0 NOT NULL,
    TM_INSERTED     D_SYNC_TIMESTAMP /* D_SYNC_TIMESTAMP = TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL */,
    TM_UPDATED      D_SYNC_TIMESTAMP /* D_SYNC_TIMESTAMP = TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL */,
    USER_INSERTED   D_SYNC_USER_ID NOT NULL /* D_SYNC_USER_ID = VARCHAR(30) */,
    USER_UPDATED    D_SYNC_USER_ID /* D_SYNC_USER_ID = VARCHAR(30) */,
    ARC_ID          D_SYNC_ITEM_ID_NULLABLE /* D_SYNC_ITEM_ID_NULLABLE = BIGINT */,
    LAST_CONTEXT_CLIENT_ADDRESS  D_SYNC_NAME,
    LAST_CONTEXT_SESSION_ID      INTEGER,
    LAST_CONTEXT_TRANSACTION_ID  INTEGER
);

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- КОНСТРЭЙНТЫ ТАБЛИЦЫ

ALTER TABLE SYNC_LOG ADD CONSTRAINT PK_SYNC_LOG PRIMARY KEY (ID);
ALTER TABLE SYNC_LOG ADD CONSTRAINT UNQ_SYNC_LOG_TABLE_ROW UNIQUE (TABLE_NAME, ROW_ID);
ALTER TABLE SYNC_LOG ADD CHECK ((update_count >= 0));

ALTER TABLE SYNC_LOG ADD CONSTRAINT FK_SYNC_LOG_PARTICIPANT
FOREIGN KEY (PARTICIPANT_ID) REFERENCES SYNC_PARTICIPANT (ID);

ALTER TABLE SYNC_LOG ADD ORIG_LOG_ID D_SYNC_ITEM_ID_NULLABLE;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ДОПОЛНИТЕЛЬНЫЕ ИЗМЕНЕНИЯ ТАБЛИЦЫ SYNC_LOG

ALTER TABLE SYNC_LOG ADD PREV_ROW_ID D_SYNC_ROW_ID_NULLABLE /* D_SYNC_ROW_ID_NULLABLE = VARCHAR(256) */;


--------------------------------------------------------------------------------
-- ПОЛЬЗОВАТЕЛЮ ПРЕДОСТАВЛЯЮТСЯ ВСЕ ПРАВА ТАК КАК
-- ЕГО ДЕЙСТВИЯ ЗАПИСЫВАЮТСЯ В ЖУРНАЛ

GRANT ALL ON SYNC_LOG TO PUBLIC;

--------------------------------------------------------------------------------
-- КОММЕНТАРИИ К ПОЛЯМ ТАБЛИЦЫ SYNC_LOG

COMMENT ON COLUMN SYNC_LOG.ID IS
'Идентификатор изменения';

COMMENT ON COLUMN SYNC_LOG.TABLE_NAME IS
'Имя таблицы';

COMMENT ON COLUMN SYNC_LOG.ROW_ID IS
'Идентификатор ключа в таблице';

COMMENT ON COLUMN SYNC_LOG.ACTION_MODE IS
'Тип изменения таблицы';

COMMENT ON COLUMN SYNC_LOG.PARTICIPANT_ID IS
'Идентификатор участника обмена данными';

COMMENT ON COLUMN SYNC_LOG.UPDATE_COUNT IS
'Количество обновлений записи';

COMMENT ON COLUMN SYNC_LOG.TM_INSERTED IS
'Время добавления (первоначального) записи.';

COMMENT ON COLUMN SYNC_LOG.TM_UPDATED IS
'Время последнего обновления.';

COMMENT ON COLUMN SYNC_LOG.USER_INSERTED IS
'Пользователь, создавший запись.';

COMMENT ON COLUMN SYNC_LOG.USER_UPDATED IS
'Пользователь, изменивший запись.';

COMMENT ON COLUMN SYNC_LOG.ARC_ID IS
'Идентификатор архивной записи в таблице об этом изменении.';

COMMENT ON COLUMN SYNC_LOG.LAST_CONTEXT_CLIENT_ADDRESS IS
'Адрес клиента.';

COMMENT ON COLUMN SYNC_LOG.LAST_CONTEXT_SESSION_ID IS
'Идентификатор сеанса.';

COMMENT ON COLUMN SYNC_LOG.LAST_CONTEXT_TRANSACTION_ID IS
'Идентификатор транзакции.';

COMMENT ON COLUMN SYNC_LOG.ORIG_LOG_ID IS
'Первоначальный идентификатор записи в журнале, если запись в журнале пришедшая, от другого участника синхронизации.';

COMMENT ON COLUMN SYNC_LOG.PREV_ROW_ID IS
'Предыдущий идентификатор записи - заполняется в случае изменения полей, входящих в состав первичного ключа для таблицы.';

--------------------------------------------------------------------------------
-- КОММЕНТАРИЙ К САМОЙ ТАБЛИЦЕ SYNC_LOG

COMMENT ON TABLE SYNC_LOG IS 'Синхронизация: основная таблица для ведения журнала изменений в базе данных';

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ДОБАВОЧНЫЕ ПОЛЯ В SYNC_TABLE ДЛЯ ЖУРНАЛИРОВАНИЯ

-- updating tables


ALTER TABLE SYNC_TABLE ADD LOGGED             D_SYNC_BOOL NOT NULL;
ALTER TABLE SYNC_TABLE ADD LOG_INSERTS        D_SYNC_BOOL NOT NULL;
ALTER TABLE SYNC_TABLE ADD LOG_UPDATES        D_SYNC_BOOL NOT NULL;
ALTER TABLE SYNC_TABLE ADD LOG_DELETES        D_SYNC_BOOL NOT NULL;
ALTER TABLE SYNC_TABLE ADD LOG_IGNORE_FIELDS  D_SYNC_OBJ_NAMES_LIST;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

UPDATE SYNC_TABLE SET LOGGED = 0 WHERE LOGGED IS NULL;
UPDATE SYNC_TABLE SET LOG_INSERTS = 0 WHERE LOG_INSERTS IS NULL;
UPDATE SYNC_TABLE SET LOG_UPDATES = 0 WHERE LOG_UPDATES IS NULL;
UPDATE SYNC_TABLE SET LOG_DELETES = 0 WHERE LOG_DELETES IS NULL;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

COMMENT ON COLUMN SYNC_TABLE.LOGGED IS
'Флаг, указывающий на то, что таблица журналируемая';

COMMENT ON COLUMN SYNC_TABLE.LOG_INSERTS IS
'Флаг, указывающий на то, что таблица журналирует вставки';

COMMENT ON COLUMN SYNC_TABLE.LOG_UPDATES IS
'Флаг, указывающий на то, что таблица журналирует изменения';

COMMENT ON COLUMN SYNC_TABLE.LOG_DELETES IS
'Флаг, указывающий на то, что таблица журналирует удаления';

COMMENT ON COLUMN SYNC_TABLE.LOG_IGNORE_FIELDS IS
'Список полей (через точку с запятой), при изменении которых не будет делаться журнальная запись. Сюда полезно ввести часто изменяемые поля, например остаток счета.';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ДОПОЛНИТЕЛЬНАЯ ТАБЛИЦА ЖУРНАЛА ДЛЯ ВЫБОРКИ ЗАПИСЕЙ ЗАВИСАЮЩИХ В ТРАНЗАКЦИЯХ

-- =========================================
-- SP_SYNC_LOG_LOST
-- =========================================

CREATE TABLE SYNC_LOG_LOST (
    ID D_SYNC_ITEM_ID NOT NULL);

--------------------------------------------------------------------------------

ALTER TABLE SYNC_LOG_LOST ADD LOCKED CHAR(1);

--------------------------------------------------------------------------------

alter table SYNC_LOG_LOST
add constraint PK_SYNC_LOG_LOST
primary key (ID);

--------------------------------------------------------------------------------

COMMENT ON COLUMN SYNC_LOG_LOST.ID IS
'Идентификатор добавленного элемента в журнал.
Используется для выгребания застрявших записей в транзакциях.';

--------------------------------------------------------------------------------

COMMENT ON TABLE SYNC_LOG_LOST IS
'Синхронизация: служебная таблица, используемая для восстановления информации о пропущенных идентификаторах в журнале выгрузки.';

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SYNC_LINK
-- =========================================

CREATE TABLE SYNC_LINK (
    ID                       D_SYNC_INT NOT NULL /* D_SYNC_INT = INTEGER */,
    NAME                     D_SYNC_NAME /* D_SYNC_NAME = VARCHAR(100) */,
    PARTICIPANT_FROM         D_SYNC_PARTICIPANT_ID /* D_SYNC_PARTICIPANT_ID = INTEGER NOT NULL */,
    PARTICIPANT_TO           D_SYNC_PARTICIPANT_ID DEFAULT 0 /* D_SYNC_PARTICIPANT_ID = INTEGER NOT NULL */,
    LOG_POSITION             D_SYNC_ITEM_ID /* D_SYNC_ITEM_ID = BIGINT NOT NULL */,
    POSITION_UPD_COUNT       D_SYNC_INT DEFAULT 0 NOT NULL /* D_SYNC_INT = INTEGER */,
    LAST_UPDATE_TM           D_SYNC_TIMESTAMP_NULLABLE /* D_SYNC_TIMESTAMP_NULLABLE = TIMESTAMP */,
    LAST_UPDATE_USER_ID      D_SYNC_USER_ID /* D_SYNC_USER_ID = VARCHAR(30) */,
    LAST_UPDATE_CLIENT_ADDR  D_SYNC_NAME /* D_SYNC_NAME = VARCHAR(100) */,
    CONNECT_ADDR             D_SYNC_NAME /* D_SYNC_NAME = VARCHAR(100) */
);

--------------------------------------------------------------------------------

ALTER TABLE SYNC_LINK ADD CONSTRAINT PK_SYNC_LINK PRIMARY KEY (ID);

alter table SYNC_LINK
add constraint FK_SYNC_LINK_PARTICIPANT_FROM
foreign key (PARTICIPANT_FROM)
references SYNC_PARTICIPANT(ID)
on update CASCADE;

alter table SYNC_LINK
add constraint FK_SYNC_LINK_PARTICIPANT_TO
foreign key (PARTICIPANT_TO)
references SYNC_PARTICIPANT(ID)
on update CASCADE;

alter table SYNC_LINK
add constraint CHK_SYNC_LINK_POSITION_UPD_COUN
check ((POSITION_UPD_COUNT >= 0));

alter table SYNC_LINK
add constraint CHK_SYNC_LINK_LOG_POSITION
check ((LOG_POSITION >= 0));

alter table SYNC_LINK
add constraint CHK_SYNC_LINK_PARTICIP_NOT_EQ
check ((PARTICIPANT_FROM <> PARTICIPANT_TO));

--------------------------------------------------------------------------------

COMMENT ON TABLE SYNC_LINK IS
'Синхронизация: таблица, описывающая связи между точками. На основании этих направлений строится обмен.';

--------------------------------------------------------------------------------

COMMENT ON COLUMN SYNC_LINK.ID IS
'Идентификатор соединения';

COMMENT ON COLUMN SYNC_LINK.NAME IS
'Наименование соединения (справочно)';

COMMENT ON COLUMN SYNC_LINK.PARTICIPANT_FROM IS
'Участник который передает данные';

COMMENT ON COLUMN SYNC_LINK.PARTICIPANT_TO IS
'Участник который принимает данные';

COMMENT ON COLUMN SYNC_LINK.LOG_POSITION IS
'Последняя обработанная запись журнала';

COMMENT ON COLUMN SYNC_LINK.POSITION_UPD_COUNT IS
'Количество обновлений позиции журнала';

COMMENT ON COLUMN SYNC_LINK.LAST_UPDATE_TM IS
'Время последнего сдвига позиции журнала';

COMMENT ON COLUMN SYNC_LINK.LAST_UPDATE_USER_ID IS
'Пользователь, который последний обновил позицию журнала.';

COMMENT ON COLUMN SYNC_LINK.LAST_UPDATE_CLIENT_ADDR IS
'Адрес компьютера, с которого последний раз было произведено обновление позиции журнала.';

COMMENT ON COLUMN SYNC_LINK.CONNECT_ADDR IS
'Адрес для соединения с удаленным сервером для передачи';

--------------------------------------------------------------------------------

SET TERM ^ ;

CREATE TRIGGER T_SYNC_LINK_BU
FOR SYNC_LINK
ACTIVE BEFORE UPDATE POSITION 0
AS
begin
  if (old.log_position <> new.log_position) then
   begin
    new.position_upd_count = new.position_upd_count + 1;
    new.last_update_tm = current_timestamp;
    new.last_update_client_addr = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
   end
end
^

SET TERM ; ^

--------------------------------------------------------------------------------


-- =============================================================================
-- TRIGGERS
-- =============================================================================

SET TERM ^ ;

ALTER TRIGGER T_SYNC_TABLE_VALIDATE_BI
ACTIVE BEFORE INSERT OR UPDATE POSITION 0
AS
begin
  if (new.archived is null) then new.archived = 0;
  if (new.archive_updates is null) then new.archive_updates = 0;
  if (new.archive_deletes is null) then new.archive_deletes = 0;
  if (new.logged is null) then new.logged = 0;
  if (new.log_inserts is null) then new.log_inserts = 0;
  if (new.log_updates is null) then new.log_updates = 0;
  if (new.log_deletes is null) then new.log_deletes = 0;
end
^

SET TERM ; ^

GRANT UPDATE,REFERENCES ON SYNC_TABLE TO TRIGGER T_SYNC_TABLE_VALIDATE_BI;

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ТРИГГЕР НА ЖУРНАЛЬНУЮ ТАБЛИЦУ (ИНИЦИАЛИЗАЦИЯ ПОЛЕЙ)

--DROP TRIGGER T_SYNC_LOG_BIU;

SET TERM ^ ;

/* Trigger: T_SYNC_LOG_BI */
RECREATE TRIGGER T_SYNC_LOG_BIU FOR SYNC_LOG
ACTIVE BEFORE INSERT OR UPDATE POSITION 0
as
  declare variable user_id varchar(30);
begin

-- !!! THIS IS AN INTERNAL TRIGGER !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007-2008
--------------------------------------------------------------------------------

  -- updating field values

  -- if logging is disabled then exit
  if (rdb$get_context('USER_SESSION', 'SYNC_LOG_DISABLED') is not null) then
   exit;

  -- if current transaction disables logging then exit
  if (rdb$get_context('USER_TRANSACTION', 'SYNC_LOG_DISABLED') is not null) then
   exit;

  select user_id from sp_sync_get_current_user_id into :user_id;

  if (inserting) then
   begin
    new.tm_inserted = current_timestamp;
    new.user_inserted = :user_id;
    new.user_updated = :user_id;

    if (new.participant_id is null) then
     select id from sp_sync_get_default_participant into new.participant_id;
   end

  if (updating) then
   begin
    new.tm_updated = current_timestamp;
    new.user_updated = :user_id;
    new.update_count = old.update_count + 1;
   end

  new.LAST_CONTEXT_CLIENT_ADDRESS = rdb$get_context('SYSTEM', 'CLIENT_ADDRESS');
  new.LAST_CONTEXT_SESSION_ID = rdb$get_context('SYSTEM', 'SESSION_ID');
  new.LAST_CONTEXT_TRANSACTION_ID = rdb$get_context('SYSTEM', 'TRANSACTION_ID');
end
^


SET TERM ; ^

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---
-- ТРИГГЕР НА ЖУРНАЛЬНУЮ ТАБЛИЦУ

SET TERM ^ ;

create trigger T_SYNC_LOG_LOST_AIU for SYNC_LOG
active after INSERT OR UPDATE position 1000
as
begin

-- !!! THIS IS AN INTERNAL TRIGGER !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007-2008
--------------------------------------------------------------------------------

  -- inserting id value to "lost" table to get opurtunity to retreive
  -- forgotten log records (that was in transactions when log is retreived)

  INSERT INTO SYNC_LOG_LOST(ID) VALUES (NEW.ID);
end
^

SET TERM ; ^

GRANT UPDATE,REFERENCES ON SYNC_LOG TO TRIGGER T_SYNC_LOG_LOST_AIU;
GRANT INSERT ON SYNC_LOG_LOST TO TRIGGER T_SYNC_LOG_LOST_AIU;

--------------------------------------------------------------------------------

-- =========================================
-- SYNC_TABLE_DEP
-- =========================================

CREATE TABLE SYNC_TABLE_DEP (
    TABLE_PARENT D_SYNC_TABLE_NAME,
    TABLE_CHILD D_SYNC_TABLE_NAME);


COMMENT ON COLUMN SYNC_TABLE_DEP.TABLE_PARENT
IS 'Родительская таблица';

COMMENT ON COLUMN SYNC_TABLE_DEP.TABLE_CHILD
IS 'Подчиненная таблица';

--------------------------------------------------------------------------------

alter table SYNC_TABLE_DEP
add constraint PK_SYNC_TABLE_DEP
primary key (TABLE_PARENT,TABLE_CHILD);

--------------------------------------------------------------------------------

alter table SYNC_TABLE_DEP
add constraint FK_SYNC_TABLE_DEP_PARENT
foreign key (TABLE_PARENT)
references SYNC_TABLE(TABLE_NAME)
on delete CASCADE
on update CASCADE;

--------------------------------------------------------------------------------

alter table SYNC_TABLE_DEP
add constraint FK_SYNC_TABLE_DEP_CHILD
foreign key (TABLE_CHILD)
references SYNC_TABLE(TABLE_NAME)
on delete CASCADE
on update CASCADE;

--------------------------------------------------------------------------------

COMMENT ON TABLE SYNC_TABLE_DEP IS
'Синхронизация: таблица, описывающая дополнительные зависимости между таблицами данных';

--------------------------------------------------------------------------------

-- =========================================
-- SP_GET_TABLE_PK
-- =========================================

SET TERM ^ ;

recreate procedure sp_sync_get_table_pk (table_name varchar(30))
returns (pk varchar(256))
as
  declare variable column_name varchar(50);
begin
--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is retreiving table primary key (comma separated)

  pk = '';

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
    if (char_length(pk) > 0) then
     pk = pk || ',';
    pk = pk || :column_name;
   end

  suspend;
end^

SET TERM ; ^

GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_TABLE_PK TO SYSDBA;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_TABLE_PK TO SYNC_ADM;
GRANT EXECUTE ON PROCEDURE SP_SYNC_GET_TABLE_PK TO PUBLIC;

--------------------------------------------------------------------------------

COMMENT ON PROCEDURE SP_SYNC_GET_TABLE_PK IS 'Синхронизация: (!внутренняя процедура!) процедура возвращает первичный ключ таблицы';

--------------------------------------------------------------------------------

ALTER TABLE SYNC_TABLE
ADD PK D_SYNC_NAME
COLLATE WIN1251 ;
COMMENT ON COLUMN SYNC_TABLE.PK IS
'Первичный ключ таблицы';

--------------------------------------------------------------------------------
-- 13.03.2008

ALTER TABLE SYNC_TABLE
ADD LOG_ALERT D_SYNC_BOOL
DEFAULT 0
NOT NULL ;

COMMENT ON COLUMN SYNC_TABLE.LOG_ALERT IS
'Флаг, указывающий на то, нужно ли вызывать событие при записи в журнал для данной таблицы.';

update sync_table
set log_alert = 0
where log_alert is null;

commit;

--------------------------------------------------------------------------------

SET TERM ^ ;

ALTER TRIGGER t_sync_table_validate_bi
active before insert or update position 0
AS
begin
  if (new.archived is null) then new.archived = 0;
  if (new.archive_updates is null) then new.archive_updates = 0;
  if (new.archive_deletes is null) then new.archive_deletes = 0;
  if (new.logged is null) then new.logged = 0;
  if (new.log_inserts is null) then new.log_inserts = 0;
  if (new.log_updates is null) then new.log_updates = 0;
  if (new.log_deletes is null) then new.log_deletes = 0;
  if (new.log_alert is null) then new.log_alert = 0;
end
^

SET TERM ; ^

--------------------------------------------------------------------------------

commit;

UPDATE SYNC_TABLE
SET LOG_ALERT = 1
WHERE LOG_ALERT IS NULL;

--------------------------------------------------------------------------------
-- 24.03.2008

-- фильтры

CREATE DOMAIN D_SYNC_FILTER_MODE AS
VARCHAR(15) CHARACTER SET WIN1251
NOT NULL
CHECK ((value in (
'COLUMN_VALUE'
)))
COLLATE WIN1251;

--------------------------------------------------------------------------------

COMMENT ON DOMAIN D_SYNC_FILTER_MODE
IS 'Синхронизация: режим фильтрации данных связи синхронизации';

--------------------------------------------------------------------------------

CREATE DOMAIN D_SYNC_FILTER_EXPRESSION AS
VARCHAR(255) CHARACTER SET WIN1251
COLLATE WIN1251;

--------------------------------------------------------------------------------

COMMENT ON DOMAIN D_SYNC_FILTER_MODE
IS 'Синхронизация: выражение фильтра';

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

COMMIT;

