--------------------------------------------------------------------------------
-- ���������� ������������� ����������/��������� ������
-- ��� ���� FIREBIRD SQL SERVER 2.0
-- (�) Copyright, ��������� ��������, ������������, 2007
--------------------------------------------------------------------------------

-- �������� ����������� �������

------------

CREATE DOMAIN D_SYNC_BOOL AS
SMALLINT
CHECK (((value is null) or ((value is not null) and (value in (0,1)))));

COMMENT ON DOMAIN D_SYNC_BOOL
IS '�������������: ��� ����������� ����';

------------

CREATE DOMAIN D_SYNC_ITEM_ID AS
BIGINT
NOT NULL;

COMMENT ON DOMAIN D_SYNC_ITEM_ID
IS '�������������: ��� �������������� �������� (������)';

------------

CREATE DOMAIN D_SYNC_MEMO AS
BLOB SUB_TYPE 1 SEGMENT SIZE 80;

COMMENT ON DOMAIN D_SYNC_MEMO
IS '�������������: ������� ���� ����';

------------

CREATE DOMAIN D_SYNC_NAME AS
VARCHAR(100);

COMMENT ON DOMAIN D_SYNC_NAME
IS '�������������: ��� ������������ ������� � �������� �������������';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_DAT AS
DATE;

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_DAT
IS '�������������: ��� ����� ��� �������� ����';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_NUM AS
INTEGER;

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_NUM
IS '�������������: ��� ����� ��� �������� ������';

------------

CREATE DOMAIN D_SYNC_OPTION_VAL_STR AS
VARCHAR(512);

COMMENT ON DOMAIN D_SYNC_OPTION_VAL_STR
IS '�������������: ��� ����� ��� �������� ��������� ������';

------------

CREATE DOMAIN D_SYNC_PARTICIPANT_ID AS
INTEGER
NOT NULL;

COMMENT ON DOMAIN D_SYNC_PARTICIPANT_ID
IS '�������������: ��� �������������� ��������� �������������';

------------

CREATE DOMAIN D_SYNC_ROW_ACTION AS
CHAR(1)
NOT NULL
CHECK ((value in ('+','-')));

COMMENT ON DOMAIN D_SYNC_ROW_ACTION
IS '�������������: ��� ��� �������� �������� ��� �������. + ��� ���������� ��� ���������. - ��� ��������.';

------------

CREATE DOMAIN D_SYNC_ROW_ID AS
VARCHAR(256)
NOT NULL;

COMMENT ON DOMAIN D_SYNC_ROW_ID
IS '�������������: ��� �������������� ������ ������';

------------

CREATE DOMAIN D_SYNC_TABLE_NAME AS
VARCHAR(128)
NOT NULL;

COMMENT ON DOMAIN D_SYNC_TABLE_NAME
IS '�������������: ��� ����� �������';

------------

CREATE DOMAIN D_SYNC_TIMESTAMP AS
TIMESTAMP
DEFAULT CURRENT_TIMESTAMP
NOT NULL;

COMMENT ON DOMAIN D_SYNC_TIMESTAMP
IS '�������������: ���� ������������ �������';

------------

CREATE DOMAIN D_SYNC_USER_ID AS
VARCHAR(30);

COMMENT ON DOMAIN D_SYNC_USER_ID
IS '�������������: ��� �������������� ������������ ���������� ��������� (���������)';

------------

CREATE DOMAIN D_SYNC_TABLE_DAYS_COUNT AS
SMALLINT
CHECK (((value is null) or (value >= 1)));

COMMENT ON DOMAIN D_SYNC_TABLE_DAYS_COUNT IS '�������������: �������� ��� ������������� ���������� ���� �������� �������� ����������.';

------------

CREATE DOMAIN D_SYNC_TABLE_MAX_COUNT AS
SMALLINT
CHECK (((value is null) or (value >= 100)));

COMMENT ON DOMAIN D_SYNC_TABLE_MAX_COUNT IS '�������������: �������� ��� ������������� ���������� ������� �������� �������� ����������.';

------------
------------
------------
------------
------------
