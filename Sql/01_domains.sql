--------------------------------------------------------------------------------
-- ПОДСИСТЕМА АРХИВИРОВАНИЯ ИЗМЕНЕННЫХ/УДАЛЕННЫХ ДАННЫХ
-- ДЛЯ СУБД FIREBIRD SQL SERVER 2.0
-- (С) Copyright, Александр Ситников, Благовещенск, 2007
--------------------------------------------------------------------------------

-- СОЗДАНИЕ НЕОБХОДИМЫХ ДОМЕНОВ

------------

CREATE DOMAIN D_SYNC_BOOL AS
SMALLINT
CHECK (((value is null) or ((value is not null) and (value in (0,1)))));

COMMENT ON DOMAIN D_SYNC_BOOL
IS 'Синхронизация: тип логического поля';

------------

CREATE DOMAIN D_SYNC_ITEM_ID AS
BIGINT
NOT NULL;

COMMENT ON DOMAIN D_SYNC_ITEM_ID
IS 'Синхронизация: тип идентификатора элемента (записи)';

------------

CREATE DOMAIN D_SYNC_MEMO AS
BLOB SUB_TYPE 1 SEGMENT SIZE 80;

COMMENT ON DOMAIN D_SYNC_MEMO
IS 'Синхронизация: простое мемо поле';

------------

CREATE DOMAIN D_SYNC_NAME AS
VARCHAR(100);

COMMENT ON DOMAIN D_SYNC_NAME
IS 'Синхронизация: тип наименования объекта в таблицах синхронизации';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_DAT AS
DATE;

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_DAT
IS 'Синхронизация: тип опции для хранения даты';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_NUM AS
INTEGER;

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_NUM
IS 'Синхронизация: тип опции для хранения номера';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_STR AS
VARCHAR(512);

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_STR
IS 'Синхронизация: тип опции для хранения текстовой строки';

------------

CREATE DOMAIN D_SYNC_PARTICIPANT_ID AS
INTEGER
NOT NULL;

COMMENT ON DOMAIN D_SYNC_PARTICIPANT_ID
IS 'Синхронизация: тип идентификатора участника синхронизации';

------------

CREATE DOMAIN D_SYNC_ROW_ACTION AS
CHAR(1)
NOT NULL
CHECK ((value in ('+','-')));

COMMENT ON DOMAIN D_SYNC_ROW_ACTION
IS 'Синхронизация: тип для хранения действия над записью. + это добавление или изменение. - это удаление.';

------------

CREATE DOMAIN D_SYNC_ROW_ID AS
VARCHAR(256)
NOT NULL;

COMMENT ON DOMAIN D_SYNC_ROW_ID
IS 'Синхронизация: тип идентификатора записи данных';

------------

CREATE DOMAIN D_SYNC_TABLE_NAME AS
VARCHAR(128)
NOT NULL;

COMMENT ON DOMAIN D_SYNC_TABLE_NAME
IS 'Синхронизация: тип имени таблицы';

------------

CREATE DOMAIN D_SYNC_TIMESTAMP AS
TIMESTAMP
DEFAULT CURRENT_TIMESTAMP
NOT NULL;

COMMENT ON DOMAIN D_SYNC_TIMESTAMP
IS 'Синхронизация: поле подставления времени';

------------

CREATE DOMAIN D_SYNC_USER_ID AS
VARCHAR(30);

COMMENT ON DOMAIN D_SYNC_USER_ID
IS 'Синхронизация: тип идентификатора пользователя сделавшего изменение (справочно)';

------------

CREATE DOMAIN D_SYNC_TABLE_DAYS_COUNT AS
SMALLINT
CHECK (((value is null) or (value >= 1)));

COMMENT ON DOMAIN D_SYNC_TABLE_DAYS_COUNT IS 'Синхронизация: параметр для максимального количества дней хранения архивной информации.';

------------

CREATE DOMAIN D_SYNC_TABLE_MAX_COUNT AS
SMALLINT
CHECK (((value is null) or (value >= 100)));

COMMENT ON DOMAIN D_SYNC_TABLE_MAX_COUNT IS 'Синхронизация: параметр для максимального количества записей хранения архивной информации.';

------------
------------
------------
------------
------------
