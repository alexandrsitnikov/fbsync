using System;
using System.Collections.Generic;
using System.Reflection;
using System.IO;
using System.Text;
using log4net;
using log4net.Core;
using log4net.Appender;

namespace SB.Sync.Classes
{
    /// <summary>
    /// состояние обмена
    /// </summary>
    public enum SyncState
    {
        Inactive = 0,
        Validating = 1, 
        Connecting = 2,
        Disconnecting = 3,
        Connected = 4,
        SyncRemoteFromLocalStarted = 5,
        SyncRemoteFromLocalCompleted = 6,
        SyncLocalFromRemoteStarted = 7,
        SyncLocalFromRemoteCompleted = 8
    }

    [Serializable]
    public enum SyncAgentOrder
    {
        RemoteLocal = 0,
        LocalRemote = 1
    }

    public delegate void SyncAgentStateChangedHandler(object state, SyncState CurrentState, SyncState NewState);


    /// <summary>
    /// агент синхронизации
    /// </summary>
    public class SyncAgent
    {
        #region приватные поля данных

        private SyncState _State = SyncState.Inactive;
        private ISyncDatabase _Local;
        private ISyncDatabase _Remote;
        private ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);
        private int _LocalToRemoteLinkId = -1;
        private int _RemoteToLocalLinkId = -1;
        private SyncLink _LocalToRemoteLink;
        private SyncLink _RemoteToLocalLink;
        private SyncAgentOrder _Order = SyncAgentOrder.RemoteLocal;
        private string _Name;
        private SyncLinkFilterList _LocalFilters;
        private SyncLinkFilterList _RemoteFilters;
        //private SyncLogReplica replica;
        private StringBuilder logMessages;
        private TextWriterAppender appenderLogMessages;
        private ulong replicaLogItemsCount;
        
        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -


        public event SyncAgentStateChangedHandler StateChanged;
        public event EventHandler StageCompleted;

        #region конструктор

        public SyncAgent()
        {
            _State = SyncState.Inactive;
            _LocalFilters = new SyncLinkFilterList();
            _RemoteFilters = new SyncLinkFilterList();
        }

        public SyncAgent(ISyncDatabase Local, ISyncDatabase Remote) : this()
        {
            _Local = Local;
            _Remote = Remote;
        }

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        #region свойства

        public ISyncDatabase Local
        {
            get { return _Local; }
            set { _Local = value; }
        }

        public ISyncDatabase Remote
        {
            get { return _Remote; }
            set { _Remote = value; }
        }

        public int LocalToRemoteLinkId
        {
            get { return _LocalToRemoteLinkId; }
            set { _LocalToRemoteLinkId = value; }
        }

        public int RemoteToLocalLinkId
        {
            get { return _RemoteToLocalLinkId; }
            set { _RemoteToLocalLinkId = value; }
        }

        public SyncState State
        {
            get
            {
                return _State;
            }
        }

        public string Name
        {
            get { return _Name; }
            set
            {
                _Name = value;
                log = LogManager.GetLogger(GetType().FullName + "." + value);
            }
        }

        public SyncLinkFilterList LocalFilters
        {
            get { return _LocalFilters; }
        }

        public SyncLinkFilterList RemoteFilters
        {
            get { return _RemoteFilters; }
        }

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        protected virtual void StateChange(SyncState NewState)
        {
            if (NewState != _State)
            {
                if (log.IsDebugEnabled) log.DebugFormat("StateChange: {0} --> {1}", _State, NewState);
                log.InfoFormat("Состояние изменилось: {0} --> {1}", _State, NewState);
                if (StateChanged != null)
                    StateChanged(this, _State, NewState);
                this._State = NewState;
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private SyncJournalInfo jnl;

        public bool Execute()
        {
            bool result = false;
            jnl = new SyncJournalInfo();
            jnl.Date = DateTime.Today;
            jnl.TimeStart = DateTime.Now;
            jnl.LocalLinkId = _LocalToRemoteLinkId;
            jnl.RemoteLinkId = _RemoteToLocalLinkId;
            jnl.Success = true;

            _BeginStoreLogMessages();
            try
            {

                if (log.IsDebugEnabled) log.Debug("Execute:begin");
                log.Info("-- начало синхронизации --------------");

                try
                {
                    try
                    {
                        Validate();
                        Connect();
                        try
                        {
                            if (_Order == SyncAgentOrder.RemoteLocal)
                            {
                                SyncRemoteFromLocal();
                                if (RemoteToLocalLinkId != 0)
                                    SyncLocalFromRemote();
                            }
                            else if (_Order == SyncAgentOrder.LocalRemote)
                            {
                                if (RemoteToLocalLinkId != 0)
                                    SyncLocalFromRemote();
                                SyncRemoteFromLocal();
                            }

                        }
                        finally
                        {
                            try
                            {
                                Disconnect();
                            }
                            catch
                            {
                                // если дисконнет не удался, то скорей всего связь уже прервана
                            }
                            //throw;
                        }

                        result = true;
                    }
                    catch (Exception ex)
                    {
                        log.Error(string.Format(
                            "Ошибка при работе агента синхронизации:\r\nСостояние: {0}\r\nОшибка: {0}",
                            State, ex.Message), ex);
                        StateChange(SyncState.Inactive);
                        result = false;
                    }
                }
                finally
                {
                    StateChange(SyncState.Inactive);
                }

                log.Info("-- конец синхронизации --------------");
                if (log.IsDebugEnabled) log.Debug("Execute:end");
            }
            finally
            {
            }

            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private void Disconnect()
        {
            if (log.IsDebugEnabled) log.Debug("Disconnect:begin");

            _EndStoreLogMessages();
            jnl.TimeEnd = DateTime.Now;
            jnl.LogMessages = logMessages.ToString();
            Local.WriteSyncJournal(jnl);

            Local.Disconnect();
            Remote.Disconnect();

            if (log.IsDebugEnabled) log.Debug("Disconnect:end");
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public SyncAgentOrder Order
        {
            get { return _Order; }
            set { _Order = value; }
        }


        private void Validate()
        {
            StateChange(SyncState.Validating);
            if (Local == null)
                throw new ArgumentException("Не задано свойство Local!");
            if (Remote == null)
                throw new ArgumentException("Не задано свойство Remote!");
            if (LocalToRemoteLinkId < 0)
                throw new ArgumentException("Не задано свойство LocalToRemoteLinkId!");

            if (string.IsNullOrEmpty(Local.Name))
                Local.Name = "Local";

            if (string.IsNullOrEmpty(Remote.Name))
                Remote.Name = "Remote";
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private void Connect()
        {
            if (log.IsDebugEnabled) log.Debug("Connect:begin");

            StateChange(SyncState.Connecting);
            Local.Connect();
            Remote.Connect();
            StateChange(SyncState.Connected);

            if (log.IsDebugEnabled) log.Debug("Connect:end");
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private void SyncRemoteFromLocal()
        {
            if (_LocalToRemoteLinkId > 0)
            {
                if (log.IsDebugEnabled) log.Debug("SyncRemoteFromLocal:begin");

                StateChange(SyncState.SyncRemoteFromLocalStarted);

                _LocalToRemoteLink = Local.GetSyncLink(LocalToRemoteLinkId);
                if (_LocalToRemoteLink == null)
                    throw new ArgumentException(string.Format("Не найдена связь по идентификатору ({0}) в локальном провайдере!", LocalToRemoteLinkId));

                ExecuteSession(Local, Remote, _LocalToRemoteLink, _LocalFilters);

                jnl.LocalReplicaCount = replicaLogItemsCount;

                StateChange(SyncState.SyncRemoteFromLocalCompleted);

                if (log.IsDebugEnabled) log.Debug("SyncRemoteFromLocal:end");
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public void OnStageCompleted()
        {
            if (StageCompleted != null)
                StageCompleted(this, EventArgs.Empty);
        }

        private void SyncLocalFromRemote()
        {
            if (_RemoteToLocalLinkId >= 0)
            {
                if (log.IsDebugEnabled) log.Debug("SyncLocalFromRemote:begin");

                StateChange(SyncState.SyncLocalFromRemoteStarted);

                _RemoteToLocalLink = Remote.GetSyncLink(_RemoteToLocalLinkId);
                if (_RemoteToLocalLink == null)
                    throw new ArgumentException(string.Format("Не найдена связь по идентификатору ({0}) в удаленном провайдере!", _RemoteToLocalLinkId));

                ExecuteSession(Remote, Local, _RemoteToLocalLink, _RemoteFilters);

                jnl.RemoteReplicaCount = replicaLogItemsCount;

                StateChange(SyncState.SyncLocalFromRemoteCompleted);

                if (log.IsDebugEnabled) log.Debug("SyncLocalFromRemote:end");
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        private void ExecuteSession(ISyncDatabase local, ISyncDatabase remote, SyncLink link, SyncLinkFilterList Filters)
        {
            log.InfoFormat("=== выполняется синхронизация", local.Name, remote.Name);
            // запуск сеанса
            local.StartSession(SessionMode.Read);

            // подготовка реплик
            SyncLogReplicaInfo replicaInfo = local.SourcePrepare(link);
            replicaLogItemsCount = replicaInfo.LogCount;

            if (replicaInfo.LogCount > 1)
            {
                SyncLogReplica replica = local.SourceGetNextReplica(replicaInfo, SourcePrepareOptions.None, Filters);

                remote.StartSession(SessionMode.Write);
                OnStageCompleted();
                SyncReplicaProcessResult result = remote.TargetProcessReplica(replica, TargetProcessOptions.None);
                OnStageCompleted();
                if (result.Success)
                {
                    remote.EndSession(true);
                    OnStageCompleted();
                    local.SourceCommitReplica(replicaInfo);
                }
                else
                {
                    log.ErrorFormat("обработка реплики прошла неудачно (возможно были ошибки) - транзакция не подтверджается");
                    jnl.Success = false;
                    remote.EndSession(false);
                    OnStageCompleted();
                    local.EndSession(false);
                    return;
                }
            }
            else
            {
                log.InfoFormat("нет данных журнала синхронизации", local.Name, remote.Name);
                remote.EndSession(true);
                OnStageCompleted();
            }

            local.EndSession(true);

            string local_messages = local.GetLogMessages();
            string remote_messages = remote.GetLogMessages();

            logMessages.AppendLine("--- BEGIN LOCAL LOG MESSAGES ------------------------------------------------");
            logMessages.Append(local_messages);
            logMessages.AppendLine("--- END LOCAL LOG MESSAGES   ------------------------------------------------");

            logMessages.AppendLine("--- BEGIN REMOTE LOG MESSAGES -----------------------------------------------");
            logMessages.Append(remote_messages);
            logMessages.AppendLine("--- END REMOTE LOG MESSAGES   -----------------------------------------------");
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public virtual void SetLoggerName(string loggerName)
        {
            this.log = LogManager.GetLogger(loggerName);
            if (Local != null)
                Local.SetLoggerName(loggerName);
            if (Remote != null)
                Remote.SetLoggerName(loggerName);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - -


        private void _EndStoreLogMessages()
        {
            if (appenderLogMessages != null)
            {
                appenderLogMessages.Close();
                (log.Logger as IAppenderAttachable).RemoveAppender(appenderLogMessages);
                appenderLogMessages = null;
            }
        }

        // ------------------------------------------------------------------------------------

        private void _BeginStoreLogMessages()
        {
            logMessages = new StringBuilder(8192);
            appenderLogMessages = new TextWriterAppender();
            appenderLogMessages.ImmediateFlush = true;
            appenderLogMessages.Layout = new log4net.Layout.PatternLayout("%date %-5level %message%newline");
            appenderLogMessages.Writer = new StringWriter(logMessages);

            appenderLogMessages.Threshold = Level.Info;

            IAppenderAttachable appender_attachable = log.Logger as IAppenderAttachable;
            if (appender_attachable != null)
                appender_attachable.AddAppender(appenderLogMessages);

            appenderLogMessages.ActivateOptions();
        }

    }
}
