using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using SB.Sync.Classes;
using System.Text;

namespace SB.Sync.Svc
{
    public interface IConnection
    {
        void StartListenEvents();
        void StopListenEvents();
        void CheckConnection();
        ISyncDatabase GetSyncDatabase();
        event EventHandler LogChanged;
    }

    public class SyncDatabaseConnection : IConnection
    {
        protected Type connectionType;
        protected IDbConnection connection;
        protected SyncDatabase syncDb;
        protected ConfigDatabase ConfigDb;

        public SyncDatabaseConnection(ConfigDatabase ConfigDb)
        {
            this.ConfigDb = ConfigDb;
            connectionType = Type.GetType(ConfigDb.ConnectionType);
            if (connectionType == null)
                throw new ArgumentException("Некорректно задан тип соединения!");

            connection = Activator.CreateInstance(connectionType) as IDbConnection;
            connection.ConnectionString = ConfigDb.Config.ParseString(ConfigDb.ConnectionString);
        }

        #region IConnection Members

        public ISyncDatabase GetSyncDatabase()
        {
            syncDb = new SyncDatabase(connection);
            syncDb.Name = ConfigDb.Name;
            return syncDb; 
        }

        public virtual void OnLogChanged()
        {
            if (LogChanged != null)
                LogChanged(this, EventArgs.Empty);
        }

        public event EventHandler LogChanged;

        public virtual void StartListenEvents()
        {
        }

        public virtual void StopListenEvents()
        {
        }

        public void CheckConnection()
        {
            if (connection.State != ConnectionState.Open)
            {
                connection.Open();
            }
            try
            {
                Ping();
            }
            catch
            {
                try
                {
                    // reconnecting
                    if (connection.State != ConnectionState.Closed)
                        connection.Close();
                    connection.Open();
                    Ping();
                }
                catch 
                {
                    throw;
                }
            }
        }

        protected virtual void Ping()
        {
        }

        #endregion
    }

}
