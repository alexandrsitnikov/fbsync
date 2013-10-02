--------------------------------------------------------------------------------
-- ���������� ������������� ����������/��������� ������
-- ��� ���� FIREBIRD SQL SERVER 2.0
-- (�) Copyright, ��������� ��������, ������������, 2007
--------------------------------------------------------------------------------

-- �������� ����������� ����������

CREATE EXCEPTION E_SYNC_001_TABLE_NOT_EXISTS
'SYNC#001. ��������� ������� �� ����������!';

COMMENT ON EXCEPTION E_SYNC_001_TABLE_NOT_EXISTS
IS '�������������: ����������, ������� ���������� � ������ ���� �� ������� ������������� �������';

--------------------

CREATE EXCEPTION E_SYNC_002_NO_DEF_PARTICIPANT 'SYNC#002. �� ����� ������� �������� ������������� (SYNC_PARTICIPANT).';

COMMENT ON EXCEPTION E_SYNC_002_NO_DEF_PARTICIPANT
IS '�������������: ����������, ������� ���������� � ������ ���� �� ����� ������������� ��������� ������������� �� ���������. ������� SYNC_PARTICIPANT.';

--------------------

CREATE EXCEPTION E_SYNC_003_NO_SYNC_TABLE 'SYNC#003. ��� ������ � ������� ������������� � ��������� ������� SYNC_TABLE. ';

COMMENT ON EXCEPTION E_SYNC_003_NO_SYNC_TABLE IS '�������������: ����������, ������� ���������� ����� � ������� SYNC_TABLE ��� ������ � ������� ���������� �������.';

--------------------

CREATE EXCEPTION E_SYNC_004_TABLE_NOT_ARCHIVED 'SYNC#004. ��������� ������� �� �������� ������������!';

COMMENT ON EXCEPTION E_SYNC_004_TABLE_NOT_ARCHIVED
IS '�������������: ����������, ������� ��������� ��� ������� ��������� ����� ���� ��������, ��������� � ��������� ��������� � �� ����� ��� ������� �� �������� �������� (SYNC_TABLE.ARCHIVED=0).';

--------------------

CREATE EXCEPTION E_SYNC_005_ARC_RECOVER_NO_DATA 'SYNC#005. �� ������� ������ ��� �������������� ������ �� �������� �������.';

COMMENT ON EXCEPTION E_SYNC_005_ARC_RECOVER_NO_DATA IS '�������������: ����������, ������� ��������� ��� ������� �������������� ������, ������� �� ������� � �������� �������.';

--------------------

CREATE EXCEPTION E_SYNC_006_ARC_RECOVER_NO_PK 'SYNC#006. �� ����� ��������� ���� ��� ������� � ������� ������������ ������� ������������ ������.';

COMMENT ON EXCEPTION E_SYNC_006_ARC_RECOVER_NO_PK IS '�������������: ����������, ������� ��������� ��� ������� ������������ ������ �������, ��� ������� �� ����� ��������� ����.';

------------


------------
------------
------------
------------