/*Номер участника формируется таким образом, 11 значный:

1. начальная единичка
2. номер базы данных (вид базы данных)
3. номер места, родного для этой БД
4. номер точки, 00 - это основная, совпадает с главной БД
5. 2 резервных разряда

например
104030000


Базы данных:

01 Операционный день
02 Вклады
03 Кредиты
04 Удаленный клиент
05 Кредитный клиент
06 Валютный реестр


Офисы:
00 голова
01-08 по таблице офисов*/

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (101000000, 'Операционный день: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (101000100, 'Операционный день: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102000000, 'Вклады: Благовещенск: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102000100, 'Вклады: Благовещенск: резерв', 0);

-------------------------------------------------------------

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102011000, 'Вклады: Бурея: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102011500, 'Вклады: Бурея: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102021000, 'Вклады: Завитинск: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102021500, 'Вклады: Завитинск: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102031000, 'Вклады: Белогорск: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102031500, 'Вклады: Белогорск: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102041000, 'Вклады: Свободный: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102041500, 'Вклады: Свободный: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102051000, 'Вклады: Шимановск: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102051500, 'Вклады: Шимановск: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102061000, 'Вклады: Магдагачи: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102061500, 'Вклады: Магдагачи: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102071000, 'Вклады: Сковородино: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102071500, 'Вклады: Сковородино: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102081000, 'Вклады: Ерофей: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102081500, 'Вклады: Ерофей: головной банк, резерв', 0);

-------------------------------------------------------------

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105000000, 'Кредитный клиент: головной банк, основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105000100, 'Кредитный клиент: головной банк, резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106000000, 'Валютный реестр: основная', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106000100, 'Валютный реестр: резерв', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106051000, 'Валютный реестр: копия Шимана', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106071000, 'Валютный реестр: копия Сковородино', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106061000, 'Валютный реестр: копия Магдагачи', 0);

-------------------------------------------------------------

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104010000, 'Клиент: Бурея: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102010000, 'Вклады: Бурея: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105010000, 'Кредитный клиент: Бурея: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106010000, 'Валютный реестр: Бурея: Основная БД', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104020000, 'Клиент: Завитинск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102020000, 'Вклады: Завитинск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105020000, 'Кредитный клиент: Завитинск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106020000, 'Валютный реестр: Завитинск: Основная БД', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104030000, 'Клиент: Белогорск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102030000, 'Вклады: Белогорск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105030000, 'Кредитный клиент: Белогорск: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106030000, 'Валютный реестр: Белогорск: Основная БД', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104040000, 'Клиент: Свободный: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102040000, 'Вклады: Свободный: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105040000, 'Кредитный клиент: Свободный: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106040000, 'Валютный реестр: Свободный: Основная БД', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104050000, 'Клиент: Шимановск: БД в головном офисе', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102050000, 'Вклады: Шимановск: БД в головном офисе', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105050000, 'Кредитный клиент: Шимановск: БД в головном офисе', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106050000, 'Валютный реестр: Шимановск: БД в головном офисе', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104060000, 'Клиент: Магдагачи: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102060000, 'Вклады: Магдагачи: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105060000, 'Кредитный клиент: Магдагачи: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106060000, 'Валютный реестр: Магдагачи: Основная БД', 0);

INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104070000, 'Клиент: Сковородино: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102070000, 'Вклады: Сковородино: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105070000, 'Кредитный клиент: Сковородино: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106070000, 'Валютный реестр: Сковородино: Основная БД', 0);

-- ерофей
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (104080000, 'Клиент: Ерофей Павлович: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (102080000, 'Вклады: Ерофей Павлович: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (105080000, 'Кредитный клиент: Ерофей Павлович: Основная БД', 0);
INSERT INTO SYNC_PARTICIPANT (ID, NAME, DEF) VALUES (106080000, 'Валютный реестр: Ерофей Павлович: Основная БД', 0);

-------------------------------------------------------------

