isql -i 08_log_tables.sql -u %2 -pass %3 -ch win1251 %1 -e -o _install.log
isql -i 09_sp_log.sql -u %2 -pass %3 -ch win1251 %1 -e -o _install.log
