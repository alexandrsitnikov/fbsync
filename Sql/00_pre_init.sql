--------------------------------------------------------------------------------
-- ���������� ������������� ����������/��������� ������
-- ��� ���� FIREBIRD SQL SERVER 2.0
-- (�) Copyright, ��������� ��������, ������������, 2007
--------------------------------------------------------------------------------

-- ��������������� ������������� ��

DECLARE EXTERNAL FUNCTION RTRIM
    CSTRING(4096)
RETURNS CSTRING(4096) FREE_IT
ENTRY_POINT 'IB_UDF_rtrim' MODULE_NAME 'ib_udf';

COMMENT ON EXTERNAL FUNCTION RTRIM
IS '������� ��� ������� �������� � ������ ������';

------------
------------
------------
------------
------------

