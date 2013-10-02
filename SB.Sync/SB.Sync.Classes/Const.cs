using System;
using System.Collections.Generic;
using System.Text;

namespace SB.Sync.Classes
{
    public class Const
    {
        public const string Table_SyncParticipants = "SYNC_PARTICIPANTS";

        public const string Msg_MethodUnknownException = "Неизвестная ошибка в методе {0}.";

        public const string Sql_SyncParticipantGet = "select * from sync_participant where id = @id";

        public const string SP_SYNC_LOG_GET = "SP_SYNC_LOG_GET";

        public const string Par_BY_LINK_ID = "@BY_LINK_ID";

        public const string Msg_SyncTableNotFound = "Таблица {0}, присутствующая в журнале изменений не найдена в метаданных (SYNC_TABLE)!";

        public const string Table_SYNC_LOG = "SYNC_LOG";

        public const string Field_LOG_ID = "$log$id$";

        public const string ActionMode_Deleted = "-";
    }
}
