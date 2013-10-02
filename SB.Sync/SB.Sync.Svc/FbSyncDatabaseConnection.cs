using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using FirebirdSql.Data.FirebirdClient;

namespace SB.Sync.Svc
{

    public class FbSyncDatabaseConnection : SyncDatabaseConnection
    {
        private FbConnection conn;
        private FbRemoteEvent remoteEvent;

        public FbSyncDatabaseConnection(ConfigDatabase db) : base(db)
        {
            conn = base.connection as FbConnection;
        }

        void remoteEvent_RemoteEventCounts(object sender, FbRemoteEventEventArgs e)
        {
            OnLogChanged();
        }

        public override void StartListenEvents()
        {
            if (ConfigDb.ListenEvents)
            {
                base.StartListenEvents();
                if (conn.State != System.Data.ConnectionState.Open)
                    conn.Open();
                remoteEvent = new FbRemoteEvent(conn, new string[] { "LOG_ALERT" });
                remoteEvent.RemoteEventCounts += new FbRemoteEventEventHandler(remoteEvent_RemoteEventCounts);
                remoteEvent.QueueEvents();
            }
        }

        public override void StopListenEvents()
        {
            if (ConfigDb.ListenEvents)
            {
                if (remoteEvent != null)
                {
                    try
                    {
                        remoteEvent.CancelEvents();
                    }
                    catch
                    {
                    }
                    remoteEvent = null;
                }
                conn.Close();
                base.StopListenEvents();
            }
        }

        protected override void Ping()
        {
            using (FbCommand cmd = new FbCommand("select 1 from rdb$database", conn))
            {
                object o = cmd.ExecuteScalar();
                if (Convert.ToInt32(o) != 1)
                    throw new Exception("Ошибка проверки связи с БД");
            }
        }
    }
}
