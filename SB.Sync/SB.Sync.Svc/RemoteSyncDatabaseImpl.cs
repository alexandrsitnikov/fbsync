using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using SB.Sync.Classes;
using System.ServiceModel;
using System.Runtime.Serialization;
using log4net;
using log4net.Appender;
using log4net.Core;

namespace SB.Sync.Svc
{
    /// <summary>
    /// удаленное соединение с базой данных
    /// открывается с помощью WCF
    /// </summary>
    [ServiceBehavior(
        IncludeExceptionDetailInFaults = true)]
    public class SyncDatabaseRemote : ISyncDatabaseRemote, IDisposable
    {
        #region закрытые поля

        private Service svc;
        private ISyncDatabase sync_db;
        private ILog log;
        private MemoryAppender appender;
        
        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        #region конструктор

        public SyncDatabaseRemote()
        {
            svc = Service.Current;
        }

        ~SyncDatabaseRemote()
        {
            Dispose();
        }
        
        #endregion
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - -

        public void Initialize(string databaseName)
        {
            ConfigConnection conn = svc.Config.Connections.Find(databaseName);
            if (conn == null)
                throw new ArgumentException(string.Format("Не найдено подключение к базе данных: {0}", databaseName), "databaseName");
            if (!(conn is ConfigDatabase))
                throw new ArgumentException(string.Format("Указанное соединение не является соединением к БД: {0}", databaseName), "databaseName");
            if (!(conn as ConfigDatabase).AllowedRemoteAccess)
                throw new ArgumentException(string.Format("Указанное соединение ({0}) не допускает удаленный доступ. Установите свойство AllowedRemoteAccess в true!", databaseName), "databaseName");

            sync_db = conn.GetConnection().GetSyncDatabase();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - -

        #region ISyncDatabaseRemote Members (обертка вокруг sync_db)

        public void Connect()
        {
            sync_db.Connect();
        }

        public void Disconnect()
        {
            sync_db.Disconnect();
        }

        public void StartSession(SB.Sync.Classes.SessionMode Mode)
        {
            sync_db.StartSession(Mode);
        }

        public void EndSession(bool commit)
        {
            sync_db.EndSession(commit);
        }

        public SyncLogReplicaInfo SourcePrepare(SyncLink link)
        {
            return sync_db.SourcePrepare(link);
        }

        public SyncLogReplica SourceGetNextReplica(SyncLogReplicaInfo replicaInfo, SourcePrepareOptions Options, SyncLinkFilterList Filters)
        {
            SyncLogReplica replica = sync_db.SourceGetNextReplica(replicaInfo, Options, Filters);
            return replica;
        }

        public void SourceCommitReplica(SyncLogReplicaInfo replica)
        {
            sync_db.SourceCommitReplica(replica);
        }

        public SyncReplicaProcessResult TargetProcessReplica(SyncLogReplica replica, TargetProcessOptions Options)
        {
            return sync_db.TargetProcessReplica(replica, Options);
        }

        public SyncLink GetSyncLink(int syncLinkId)
        {
            return sync_db.GetSyncLink(syncLinkId);
        }

        public string Name
        {
            get
            {
                return sync_db.Name;
            }
            set
            {
                sync_db.Name = value;
            }
        }

        public void SetLoggerName(string loggerName)
        {
            sync_db.SetLoggerName(loggerName);
            log = LogManager.GetLogger(loggerName);
        }

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - -

        #region ISyncDatabaseRemote Members

        public void StartRegisterPendingEvents()
        {
            CloseAppender();
            OpenAppender();
        }

        private void OpenAppender()
        {
            if (appender == null)
            {
                appender = new MemoryAppender();
                (log.Logger as log4net.Core.IAppenderAttachable).AddAppender(appender);
            }
        }

        private void CloseAppender()
        {
            if (appender != null)
            {
                (log.Logger as log4net.Core.IAppenderAttachable).RemoveAppender(appender);
                appender.Close();
                appender = null;
            }
        }

        public LogEventList GetPendingLoggingEvents()
        {
            LogEventList list = new LogEventList();

            if (appender != null)
            {
                LoggingEvent[] result = appender.GetEvents();
                foreach (LoggingEvent evt in result)
                    list.Add(new LogEvent(evt));
                appender.Clear();
            }
            return list;
        }

        #endregion

        #region IDisposable Members

        public void Dispose()
        {
            CloseAppender();
        }

        #endregion

        #region ISyncDatabaseRemote Members


        public void StopRegisterPendingEvents()
        {
            OpenAppender();
        }

        #endregion
    }
}
