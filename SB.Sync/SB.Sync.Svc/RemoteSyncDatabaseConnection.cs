using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using SB.Sync.Classes;
using System.ServiceModel;

namespace SB.Sync.Svc
{
    // ============================================================================================================

    public class RemoteSyncDatabaseConnection : IConnection
    {
        #region закрытые поля
        
        private ConfigRemoteService ConfigRemote;
        private SyncDatabaseRemoteClient Client;
        
        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        #region конструктор
        
        public RemoteSyncDatabaseConnection(ConfigRemoteService ConfigRemote)
        {
            this.ConfigRemote = ConfigRemote;
        }

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public void StartListenEvents()
        {
            // удаленное соединение не поддерживает события обновления
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public void StopListenEvents()
        {
            // удаленное соединение не поддерживает события обновления
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public void CheckConnection()
        {
            Client = new SyncDatabaseRemoteClient(ConfigRemote.GetAddressString());
            try
            {
                Client.Initialize(ConfigRemote.GetDatabaseNameString());
            }
            catch (Exception ex)
            {
                throw new Exception(string.Format("Ошибка подключения к удаленной БД:\r\n{0}", ex.Message), ex);
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private void LogChangesStub()
        {
            LogChanged(this, EventArgs.Empty);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public ISyncDatabase GetSyncDatabase()
        {
            return Client;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public event EventHandler LogChanged;
    }

    // ============================================================================================================

    internal class SyncDatabaseRemoteClient : ClientBase<ISyncDatabaseRemote>, ISyncDatabaseRemote
    {
        public SyncDatabaseRemoteClient(string address)
            : base("endpoint1", new EndpointAddress(address))
        {
        }

        public new ISyncDatabaseRemote Channel
        {
            get { return base.Channel; }
        }

        #region ISyncDatabaseRemote Members

        public void Initialize(string databaseName)
        {
            Channel.Initialize(databaseName);
        }

        #endregion

        #region ISyncDatabase Members

        public void Connect()
        {
            Channel.Connect();
        }

        public void Disconnect()
        {
            Channel.Disconnect();
            Close();
        }

        public void StartSession(SB.Sync.Classes.SessionMode Mode)
        {
            Channel.StartSession(Mode);
        }

        public void EndSession(bool commit)
        {
            Channel.EndSession(commit);
        }

        public SyncLogReplicaInfo SourcePrepare(SyncLink link)
        {
            return Channel.SourcePrepare(link);
        }

        public SyncLogReplica SourceGetNextReplica(SyncLogReplicaInfo replicaInfo, SourcePrepareOptions Options, SyncLinkFilterList Filters)
        {
            return Channel.SourceGetNextReplica(replicaInfo, Options, Filters);
        }

        public void SourceCommitReplica(SyncLogReplicaInfo replica)
        {
            Channel.SourceCommitReplica(replica);
        }

        public SyncReplicaProcessResult TargetProcessReplica(SyncLogReplica replica, TargetProcessOptions Options)
        {
            return Channel.TargetProcessReplica(replica, Options);
        }

        public SyncLink GetSyncLink(int syncLinkId)
        {
            return Channel.GetSyncLink(syncLinkId);
        }

        public string Name
        {
            get
            {
                return Channel.Name;
            }
            set
            {
                Channel.Name = value;
            }
        }

        public void SetLoggerName(string loggerName)
        {
            Channel.SetLoggerName(loggerName);
        }

        public LogEventList GetPendingLoggingEvents()
        {
            return Channel.GetPendingLoggingEvents();
        }

        #endregion

        #region ISyncDatabaseRemote Members


        public void StartRegisterPendingEvents()
        {
            Channel.StartRegisterPendingEvents();
        }

        #endregion

        #region ISyncDatabaseRemote Members


        public void StopRegisterPendingEvents()
        {
            Channel.StopRegisterPendingEvents();
        }

        #endregion
    }

    // ============================================================================================================

}
