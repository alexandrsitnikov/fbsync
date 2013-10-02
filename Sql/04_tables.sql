--------------------------------------------------------------------------------
-- ���������� ������������� ����������/��������� ������
-- ��� ���� FIREBIRD SQL SERVER 2.0
-- (�) Copyright, ��������� ��������, ������������, 2007
--------------------------------------------------------------------------------

-- �������

-- =========================================
-- SYNC_PARTICIPANT
-- =========================================

CREATE TABLE SYNC_PARTICIPANT (
    ID    D_SYNC_PARTICIPANT_ID NOT NULL
    /* D_SYNC_PARTICIPANT_ID = INTEGER NOT NULL */,
    NAME  D_SYNC_NAME NOT NULL
    /* D_SYNC_NAME = VARCHAR(100) */,
    DEF   D_SYNC_BOOL NOT NULL
    /* D_SYNC_BOOL = SMALLINT CHECK (((value is null) or
     ((value is not null) and (value in (0,1))))) */);

-------------------------------------------------

ALTER TABLE SYNC_PARTICIPANT
ADD CONSTRAINT PK_SYNC_PARTICIPANT PRIMARY KEY (ID);

-------------------------------------------------

COMMENT ON TABLE SYNC_PARTICIPANT IS
'�������������: ������ ���������� (��� ������) � ������������� � �������������.';

-------------------------------------------------

COMMENT ON COLUMN SYNC_PARTICIPANT.ID IS
'������������� ��������� �������������';

COMMENT ON COLUMN SYNC_PARTICIPANT.NAME IS
'������������ ��������� �������������';

COMMENT ON COLUMN SYNC_PARTICIPANT.DEF IS
'���������� ���� - �������� �� ������� �������� ���������� �� ���������';

-------------------------------------------------

GRANT ALL ON SYNC_PARTICIPANT TO SYNC_ADM;
GRANT SELECT, REFERENCES ON SYNC_PARTICIPANT TO PUBLIC;

-------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SYNC_TABLE
-- =========================================

CREATE TABLE SYNC_TABLE (
    TABLE_NAME                 D_SYNC_TABLE_NAME NOT NULL
    /* D_SYNC_TABLE_NAME = VARCHAR(128) NOT NULL */,
    NAME                       D_SYNC_NAME
    /* D_SYNC_NAME = VARCHAR(100) */,
    DESCR                      D_SYNC_MEMO
    /* D_SYNC_MEMO = BLOB SUB_TYPE 1 SEGMENT SIZE 80 */,
    ARCHIVED                   D_SYNC_BOOL DEFAULT 0 NOT NULL
    /* D_SYNC_BOOL = SMALLINT CHECK (((value is null) or ((value is not null) and (value in (0,1))))) */,
    ARCHIVE_UPDATES            D_SYNC_BOOL DEFAULT 0 NOT NULL
    /* D_SYNC_BOOL = SMALLINT CHECK (((value is null) or ((value is not null) and (value in (0,1))))) */,
    ARCHIVE_DELETES            D_SYNC_BOOL DEFAULT 0 NOT NULL
    /* D_SYNC_BOOL = SMALLINT CHECK (((value is null) or ((value is not null) and (value in (0,1))))) */,
    ARCHIVE_UPDATES_MAX_DAYS   D_SYNC_TABLE_DAYS_COUNT
    /* D_SYNC_TABLE_DAYS_COUNT = SMALLINT CHECK (((value is null) or (value >= 1))) */,
    ARCHIVE_UPDATES_MAX_COUNT  D_SYNC_TABLE_MAX_COUNT
    /* D_SYNC_TABLE_MAX_COUNT = SMALLINT CHECK (((value is null) or (value >= 100))) */,
    ARCHIVE_DELETES_MAX_DAYS   D_SYNC_TABLE_DAYS_COUNT
    /* D_SYNC_TABLE_DAYS_COUNT = SMALLINT CHECK (((value is null) or (value >= 1))) */,
    ARCHIVE_DELETES_MAX_COUNT  D_SYNC_TABLE_MAX_COUNT
    /* D_SYNC_TABLE_MAX_COUNT = SMALLINT CHECK (((value is null) or (value >= 100))) */
);

-------------------------------------------------

ALTER TABLE SYNC_TABLE ADD CONSTRAINT PK_SYNC_TABLE PRIMARY KEY (TABLE_NAME);

-------------------------------------------------

SET TERM ^ ;

-------------------------------------------------
/* Trigger: T_SYNC_TABLE_VALIDATE_BI */
-------------------------------------------------

CREATE TRIGGER T_SYNC_TABLE_VALIDATE_BI FOR SYNC_TABLE
ACTIVE BEFORE INSERT OR UPDATE POSITION 0
AS
begin
  if (new.archive_updates is null) then
   new.archive_updates = 0;
  if (new.archive_deletes is null) then
   new.archive_deletes = 0;
end
^

SET TERM ; ^

-------------------------------------------------

COMMENT ON TABLE SYNC_TABLE
IS
'�������������: ������ ������, ��� ������� ������� ������������ � ������ ���������';

-------------------------------------------------

COMMENT ON COLUMN SYNC_TABLE.TABLE_NAME IS
'��� ������� �������������';

COMMENT ON COLUMN SYNC_TABLE.NAME IS
'������������ ��� ������� �������������';

COMMENT ON COLUMN SYNC_TABLE.DESCR IS
'����������� � ������� �������������';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVED IS
'����, ����������� �� ��, ��� ������� ������������';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_UPDATES IS
'����, ����������� �� ��, ��� ������� ���������� ���������';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_DELETES IS
'����, ����������� �� ��, ��� ������� ���������� ��������';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_UPDATES_MAX_DAYS IS
'������������ ���-�� ���� ��� �������� �������� ���������� �� ���������� (���� ���������)';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_UPDATES_MAX_COUNT IS
'������������ ���-�� ������� ��� �������� �������� ���������� �� ���������� (���� ���������)';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_DELETES_MAX_DAYS IS
'������������ ���-�� ���� ��� �������� �������� ���������� �� ��������� (���� ���������)';

COMMENT ON COLUMN SYNC_TABLE.ARCHIVE_DELETES_MAX_COUNT IS
'������������ ���-�� ������� ��� �������� �������� ���������� �� ��������� (���� ���������)';

-------------------------------------------------

GRANT SELECT, REFERENCES ON SYNC_TABLE TO PUBLIC;

GRANT ALL ON SYNC_TABLE TO SYNC_ADM;

-------------------------------------------------

-- =========================================

-- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- --- -- - -- ---

-- =========================================
-- SYNC_TABLE
-- =========================================
