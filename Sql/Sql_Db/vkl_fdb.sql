INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102000000, 'Вклады: Благовещенск: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102000100, 'Вклады: Благовещенск: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102010000, 'Вклады: Бурея: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102010100, 'Вклады: Бурея: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102020000, 'Вклады: Завитинск: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102020100, 'Вклады: Завитинск: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102030000, 'Вклады: Белогорск: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102030100, 'Вклады: Белогорск: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102040000, 'Вклады: Свободный: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102040100, 'Вклады: Свободный: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102050000, 'Вклады: Шимановск: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102050100, 'Вклады: Шимановск: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102060000, 'Вклады: Магдагачи: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102060100, 'Вклады: Магдагачи: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102070000, 'Вклады: Сковородино: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102070100, 'Вклады: Сковородино: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102080000, 'Вклады: Ерофей: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102080100, 'Вклады: Ерофей: резерв', 0);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202010001, 'Резерв: Вклады Бурея', 102010000, 102010100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202020001, 'Резерв: Вклады Завитинск', 102020000, 102020100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202030001, 'Резерв: Вклады Белогорск', 102030000, 102030100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202040001, 'Резерв: Вклады Свободный', 102040000, 102040100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202050001, 'Резерв: Вклады Шимановск', 102050000, 102050100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202060001, 'Резерв: Вклады Магдагачи', 102060000, 102060100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202070001, 'Резерв: Вклады Сковородино', 102070000, 102070100, 0, 0, NULL, NULL, NULL, NULL);

INSERT INTO SYNC_LINK (ID, NAME, PARTICIPANT_FROM, PARTICIPANT_TO, LOG_POSITION, POSITION_UPD_COUNT, LAST_UPDATE_TM, LAST_UPDATE_USER_ID, LAST_UPDATE_CLIENT_ADDR, CONNECT_ADDR)
VALUES (202080001, 'Резерв: Вклады Ерофей', 102080000, 102080100, 0, 0, NULL, NULL, NULL, NULL);

execute procedure sp_sync_log_init_table('ACCOUNT', 1);
execute procedure sp_sync_log_init_table('CARD_IV_CUS', 1);
execute procedure sp_sync_log_init_table('CARD_OPER', 1);
execute procedure sp_sync_log_init_table('CARD_OPER_STATUS', 1);
execute procedure sp_sync_log_init_table('CARD_OPER_TYPE', 1);
execute procedure sp_sync_log_init_table('CARD_PROVIDER', 1);
execute procedure sp_sync_log_init_table('CARD_SCH', 1);
execute procedure sp_sync_log_init_table('COUNTRY', 1);
execute procedure sp_sync_log_init_table('CURREN', 1);
execute procedure sp_sync_log_init_table('CURREN_PEREOCEN', 1);
execute procedure sp_sync_log_init_table('DOC_OFFICE_EXCH', 1);
execute procedure sp_sync_log_init_table('DOC_TEMPLATE', 1);
execute procedure sp_sync_log_init_table('DOC_TEMPLATE_FOLDER', 1);
execute procedure sp_sync_log_init_table('DOC_VID', 1);
execute procedure sp_sync_log_init_table('DOKYM', 1);
execute procedure sp_sync_log_init_table('DOKYM_SVOD', 1);
execute procedure sp_sync_log_init_table('EXPORTDOCS_FORMATS', 1);
execute procedure sp_sync_log_init_table('EXPORTDOCS_NAZN', 1);
execute procedure sp_sync_log_init_table('GDB_TASKS', 1);
execute procedure sp_sync_log_init_table('KLIENT', 1);
execute procedure sp_sync_log_init_table('MESTO', 1);
execute procedure sp_sync_log_init_table('OD_DOC_NAZN', 1);
execute procedure sp_sync_log_init_table('OD_DOGOV', 1);
execute procedure sp_sync_log_init_table('OD_DOG_TYPE', 1);
execute procedure sp_sync_log_init_table('OD_GAS', 1);
execute procedure sp_sync_log_init_table('OD_POS', 1);
execute procedure sp_sync_log_init_table('OD_POS_HISTORY', 1);
execute procedure sp_sync_log_init_table('OD_QUALITY_CATEGORY', 1);
execute procedure sp_sync_log_init_table('OD_VYD', 1);
execute procedure sp_sync_log_init_table('OPER_DNI', 0);
execute procedure sp_sync_log_init_table('ORGS', 1);
execute procedure sp_sync_log_init_table('PAY_BILL', 1);
execute procedure sp_sync_log_init_table('PAY_BILL_SPR', 1);
execute procedure sp_sync_log_init_table('PAY_BILL_SPR_LNK', 1);
execute procedure sp_sync_log_init_table('PAY_BILL_SPR_MODE', 1);
execute procedure sp_sync_log_init_table('PAY_SERVICE', 1);
execute procedure sp_sync_log_init_table('PROC_ST', 1);
execute procedure sp_sync_log_init_table('RATE_CBREFIN', 1);
execute procedure sp_sync_log_init_table('REPORTS', 1);
execute procedure sp_sync_log_init_table('REPORTSTAT', 1);
execute procedure sp_sync_log_init_table('RPL_CHECKPOINTS', 1);
execute procedure sp_sync_log_init_table('SCHEDPAY', 1);
execute procedure sp_sync_log_init_table('SCHEDPAY_PLAN', 1);
execute procedure sp_sync_log_init_table('SCHET', 1);
execute procedure sp_sync_log_init_table('SCHKLINKS', 1);
execute procedure sp_sync_log_init_table('SCH_NOTES', 1);
execute procedure sp_sync_log_init_table('SCH_OD', 1);
execute procedure sp_sync_log_init_table('SCH_VID', 1);
execute procedure sp_sync_log_init_table('SEARCH', 1);
execute procedure sp_sync_log_init_table('SMS_CONTRACT', 1);
execute procedure sp_sync_log_init_table('SMS_MSG_SEND', 1);
execute procedure sp_sync_log_init_table('SMS_MSG_STATE', 1);
execute procedure sp_sync_log_init_table('SMS_MSG_TPL', 1);
execute procedure sp_sync_log_init_table('SMS_RULE', 1);
execute procedure sp_sync_log_init_table('SPR_KLIENT_PASP', 1);
execute procedure sp_sync_log_init_table('USERS', 1);
execute procedure sp_sync_log_init_table('VKLAD', 1);
execute procedure sp_sync_log_init_table('VKLAD_CURR_JOIN', 1);
execute procedure sp_sync_log_init_table('VKLAD_SROK_TYPE', 1);


