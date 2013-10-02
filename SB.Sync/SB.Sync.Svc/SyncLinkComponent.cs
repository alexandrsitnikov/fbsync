using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Text;
using SB.Svc.Base;
using SB.Sync.Classes;
using log4net;
using log4net.Appender;
using log4net.Core;

namespace SB.Sync.Svc
{ 
    public class SyncLinkComponent : CustomServiceComponent
    {
        private SyncAgent syncAgent;
        private ConfigSyncLink linkInfo;
        private IConnection localConnection;
        private IConnection remoteConnection;
        private CustomServiceThreadWithTimer thread;
        private ILog log;
        private RollingFileAppender new_appender;
        private int failedCount;

        public SyncLinkComponent(SyncLinkCollection _Links, ConfigSyncLink linkInfo) : 
            base(_Links.Service, "Link." + linkInfo.Name)
        {
            this.linkInfo = linkInfo;

            log = LogManager.GetLogger(Name);

            RegisterLogAppender();

            localConnection = linkInfo.LocalConnection.GetConnection();
            remoteConnection = linkInfo.RemoteConnection.GetConnection();

            localConnection.LogChanged += new EventHandler(localConnection_LogChanged);
            remoteConnection.LogChanged += new EventHandler(localConnection_LogChanged);

            thread = new CustomServiceThreadWithTimer(Svc, "");
            thread.OnExecute += new EventHandler(thread_OnExecute);
        }

        private void RegisterLogAppender()
        {
            new_appender = new RollingFileAppender();
            new_appender.File = (Path.Combine(Properties.Settings.Default.LinksLogDirectory, Name) + ".log").Replace(":", "_");
            new_appender.Layout = new log4net.Layout.PatternLayout(Properties.Settings.Default.LinksLogPattern);
            new_appender.Encoding = Encoding.GetEncoding(1251);
            new_appender.ActivateOptions();

            (log.Logger as log4net.Core.IAppenderAttachable).AddAppender(new_appender);
        }

        void thread_OnExecute(object sender, EventArgs e)
        {
            Synchronize();
        }

        void localConnection_LogChanged(object sender, EventArgs e)
        {
            CallSynchronize();
        }

        private void CallSynchronize()
        {
            thread.Fire();
        }

        protected override void InternalStart()
        {
            base.InternalStart();
            thread.Delay = linkInfo.SyncDelay;
            thread.Start();
            localConnection.StartListenEvents();
            remoteConnection.StartListenEvents();
            thread.Fire();
        }

        protected override void InternalStop()
        {
            localConnection.StopListenEvents();
            remoteConnection.StopListenEvents();
            thread.Stop();
            UnregisterLogAppender();
            base.InternalStop();
        }

        private void UnregisterLogAppender()
        {
            new_appender.Close();
        }

        private void Synchronize()
        {
            if (log.IsDebugEnabled) log.Debug("Synchronize:begin");

            if (!CheckConnection(localConnection, "Local")) return;
            if (!CheckConnection(remoteConnection, "Remote")) return;

            log4net.GlobalContext.Properties["test"] = "123";

            syncAgent = new SyncAgent();
            syncAgent.Local = localConnection.GetSyncDatabase();
            syncAgent.Remote = remoteConnection.GetSyncDatabase();
            syncAgent.LocalToRemoteLinkId = linkInfo.LocalId;
            syncAgent.RemoteToLocalLinkId = linkInfo.RemoteId;
            syncAgent.StateChanged += new SyncAgentStateChangedHandler(syncAgent_StateChanged);
            syncAgent.LocalFilters.AddRange(linkInfo.LocalFilters);
            syncAgent.RemoteFilters.AddRange(linkInfo.RemoteFilters);

            syncAgent.Name = linkInfo.Name;
            syncAgent.Order = linkInfo.Order;

            //syncAgent.Local.Name = string.Format("{0} ({1})", linkInfo.Name, syncAgent.Local.Name);
            //syncAgent.Remote.Name = string.Format("{0} ({1})", linkInfo.Name, syncAgent.Remote.Name);

            syncAgent.SetLoggerName(log.Logger.Name);

            bool executionResult = syncAgent.Execute();
            if (executionResult)
            {
                log.Info("Сеанс синхронизации прошел успешно");
                if (failedCount > 0)
                {
                    // восстановление после ошибки
                    thread.Delay = linkInfo.SyncDelay;
                }
                failedCount = 0; // сброс счетчика ошибок
            }
            else
            {
                failedCount++;
                if (failedCount < linkInfo.LinkRetries)
                {
                    log.WarnFormat("Сеанс синхронизации завершен с ошибкой. Это {0} ошибочный сеанс. По достижении {1} ошибочных сеансов связь будет приостановлена.",
                        failedCount, linkInfo.LinkRetries);
                }
                else if (failedCount >= linkInfo.LinkRetries)
                {
                    log.ErrorFormat("Сеанс синхронизации завершен с ошибкой. Попытка связи № {0}. Связь приостановлена.",
                        failedCount);
                    thread.Delay = linkInfo.RetryAfterErrorsDelay;
                }
            }
            
            if (log.IsDebugEnabled) log.Debug("Synchronize:end");
        }

        void syncAgent_StateChanged(object state, SyncState CurrentState, SyncState NewState)
        {
            if (NewState == SyncState.SyncLocalFromRemoteStarted || NewState == SyncState.SyncRemoteFromLocalStarted)
            {
                StartRegisterPendingEvents(syncAgent.Local);
                StartRegisterPendingEvents(syncAgent.Remote);
            }

            if (NewState == SyncState.SyncLocalFromRemoteCompleted || NewState == SyncState.SyncRemoteFromLocalCompleted)
            {
                StopRegisterPendingEvents(syncAgent.Local);
                StopRegisterPendingEvents(syncAgent.Remote);
            }
        }

        private void StartRegisterPendingEvents(ISyncDatabase db)
        {
            if (db is ISyncDatabaseRemote)
                (db as ISyncDatabaseRemote).StartRegisterPendingEvents();
        }

        private void StopRegisterPendingEvents(ISyncDatabase db)
        {
            ProcessPendingLogMessages(db);
            if (db is ISyncDatabaseRemote)
                (db as ISyncDatabaseRemote).StopRegisterPendingEvents();
        }

        private void ProcessPendingLogMessages(ISyncDatabase db)
        {
            if (db is ISyncDatabaseRemote)
            {
                LogEventList list = (db as ISyncDatabaseRemote).GetPendingLoggingEvents();
                if (list != null)
                    foreach (LogEvent evt in list)
                    {
                        log.Logger.Log(evt.GetLoggingEvent());
                    }
            }
        }

        private bool CheckConnection(IConnection c, string name)
        {
            try
            {
                c.CheckConnection();
                return true;
            }
            catch (Exception ex)
            {
                log.Error(string.Format("Ошибка подключения к объекту соединения ({0}). {1}", name, ex.Message));
                return false;
            }
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    public class SyncLinkCollection : List<SyncLinkComponent>
    {
        private Service _Service;

        public SyncLinkCollection(Service Service)
        {
            this._Service = Service;
        }

        public Service Service
        {
            get { return _Service; }
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
}
