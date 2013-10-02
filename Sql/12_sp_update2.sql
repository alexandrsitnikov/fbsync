--------------------------------------------------------------------------------
-- 20/04/2009 - Исправление ошибок, связанных с "забытием" записей
-- при одновременной выгрузке в нескольких потоках
--------------------------------------------------------------------------------

ALTER TABLE SYNC_LOG_LOST
ADD TM TIMESTAMP
DEFAULT CURRENT_TIMESTAMP
NOT NULL;

UPDATE SYNC_LOG_LOST
SET TM = CURRENT_TIMESTAMP
WHERE TM IS NULL;

COMMENT ON COLUMN SYNC_LOG_LOST.TM IS 'Log timestamp';

--------------------------------------------------------------------------------

CREATE TABLE SYNC_LOG_LAST (
    ID              D_SYNC_ITEM_ID NOT NULL /* D_SYNC_ITEM_ID = BIGINT NOT NULL */,
    TM              TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL);

ALTER TABLE SYNC_LOG_LAST ADD CONSTRAINT PK_SYNC_LOG_LAST PRIMARY KEY (ID);

COMMENT ON TABLE SYNC_LOG_LAST IS
'Синхронизация: служебная таблица, используемая для восстановления информации о пропущенных идентификаторах в журнале выгрузки.';

COMMENT ON COLUMN SYNC_LOG_LAST.ID IS
'Идентификатор добавленного элемента в журнал.
Используется для выгребания застрявших записей в транзакциях.';

COMMENT ON COLUMN SYNC_LOG_LAST.TM IS
'Log timestamp';

grant select, delete, insert, update on sync_log_last to public;

--------------------------------------------------------------------------------

CREATE TABLE SYNC_LOG_LAST_USED (
    ID D_SYNC_ITEM_ID NOT NULL,
    LINK_ID D_SYNC_INT NOT NULL);

COMMENT ON COLUMN SYNC_LOG_LAST_USED.ID IS
'LOG_ID identifier';

COMMENT ON COLUMN SYNC_LOG_LAST_USED.LINK_ID IS
'LINK_ID identifier';

COMMENT ON TABLE SYNC_LOG_LAST_USED IS 'Fixing SYNC_LOG_LAST history for link';

alter table SYNC_LOG_LAST_USED
add constraint PK_SYNC_LOG_LAST_USED
primary key (ID,LINK_ID);

alter table SYNC_LOG_LAST_USED
add constraint FK_SYNC_LOG_LAST_USED_ID
foreign key (ID)
references SYNC_LOG_LAST(ID)
on delete CASCADE
on update CASCADE;

alter table SYNC_LOG_LAST_USED
add constraint FK_SYNC_LOG_LAST_USED_LINK
foreign key (LINK_ID)
references SYNC_LINK(ID)
on delete CASCADE
on update CASCADE;

grant select, delete, insert, update on sync_log_last_used to public;

--------------------------------------------------------------------------------

