using System;
using System.Collections.Generic;
using System.Text;
using System.Runtime.Serialization;
using System.ServiceModel;
using log4net;
using log4net.Core;

namespace SB.Sync.Classes
{
    public enum SyncReplicaProcessResultCode
    {
        Unknown,
        OK,
        WithErrors
    }

    [DataContract]
    [KnownType(typeof(LoggingEvent))]
    [KnownType(typeof(SyncReplicaProcessError))]
    public class SyncReplicaProcessResult
    {
        private SyncReplicaProcessResultCode _Code;
        private SyncReplicaProcessErrorList _Errors;
        private List<LoggingEvent> _Messages;

        public SyncReplicaProcessResult()
        {
            _Errors = new SyncReplicaProcessErrorList();
            _Messages = new List<LoggingEvent>();
        }

        public SyncReplicaProcessResult(SyncReplicaProcessResultCode Code) : this()
        {
            this.Code = Code;
        }

        [DataMember]
        public SyncReplicaProcessResultCode Code
        {
            get { return _Code; }
            set { _Code = value; }
        }

        //[DataMember]
        public SyncReplicaProcessErrorList Errors
        {
            get { return _Errors; }
            set { _Errors = value; }
        }

        public bool Success
        {
            get { return _Code == SyncReplicaProcessResultCode.OK; }
        }
    }

    /// <summary>
    /// описание ошибки, возникающей при обработке данных
    /// </summary>
    [Serializable]
    public class SyncReplicaProcessError
    {
        private uint _Index;
        private string _Message;
        private string _TableName;
        private object[] _KeyValues;
        private object[] _DataValues;

        public uint Index
        {
            get { return _Index; }
            set { _Index = value; }
        }

        public string Message
        {
            get { return _Message; }
            set { _Message = value; }
        }

        public string TableName
        {
            get { return _TableName; }
            set { _TableName = value; }
        }

        public object[] KeyValues
        {
            get { return _KeyValues; }
            set { _KeyValues = value; }
        }

        public object[] DataValues
        {
            get { return _DataValues; }
            set { _DataValues = value; }
        }
    }

    [KnownType(typeof(SyncReplicaProcessError))]
    public class SyncReplicaProcessErrorList : List<SyncReplicaProcessError>
    {
    }
}
