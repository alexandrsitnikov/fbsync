using System;
using System.Collections.Generic;
using System.Text;
using System.ServiceModel;
using log4net;
using log4net.Core;

namespace SB.Sync.Classes
{
    public enum SessionMode
    {
        Read = 0,
        Write = 1
    }

    [ServiceContract(SessionMode = System.ServiceModel.SessionMode.Required)]
    public interface ISyncDatabase 
    {
        [OperationContract]
        void Connect();

        // connection methods
        [OperationContract]
        void Disconnect();

        // session methods
        [OperationContract]
        void StartSession(SessionMode Mode);
        
        [OperationContract]
        void EndSession(bool commit);

        // replica reading methods
        [OperationContract]
        SyncLogReplicaInfo SourcePrepare(SyncLink link);

        [OperationContract]
        SyncLogReplica SourceGetNextReplica(SyncLogReplicaInfo ReplicaInfo, SourcePrepareOptions Options, SyncLinkFilterList Filters);

        [OperationContract]
        void SourceCommitReplica(SyncLogReplicaInfo ReplicaInfo);

        // replica writing methods
        [OperationContract]
        SyncReplicaProcessResult TargetProcessReplica(SyncLogReplica replica, TargetProcessOptions Options);

        [OperationContract]
        SyncLink GetSyncLink(int syncLinkId);
        
        string Name 
        {
            [OperationContract]
            get;
            [OperationContract]
            set; 
        }

        [OperationContract]
        void SetLoggerName(string loggerName);

        [OperationContract]
        string GetLogMessages();

        [OperationContract]
        void WriteSyncJournal(SyncJournalInfo Info);
    }

    // ------------------------------------------------------------

    [ServiceContract(SessionMode=System.ServiceModel.SessionMode.Required)]
    public interface ISyncDatabaseRemote : ISyncDatabase
    {
        [OperationContract]
        void Initialize(string databaseName);

        [OperationContract]
        void StartRegisterPendingEvents();

        [OperationContract]
        void StopRegisterPendingEvents();

        [OperationContract]
        LogEventList GetPendingLoggingEvents();
    }

    // ------------------------------------------------------------

    public enum SourcePrepareOptions
    {
        None
    }

    // ------------------------------------------------------------

    public enum TargetProcessOptions
    {
        None
    }
}
