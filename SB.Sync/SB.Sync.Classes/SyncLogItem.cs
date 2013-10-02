using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Xml.Serialization;

namespace SB.Sync.Classes
{
    [Serializable]
    public class SyncLogItem 
    {

        // - - - - - - - - - - - - - - - - - - - - - - - - 

        #region приватные поля

        private long _Id;
        private string _TableName;
        private int _ParticipantId;
        private int _UpdateCount;
        private string _ActionMode;
        private string _RowId;
        private DateTime _TimeInserted;
        private DateTime _TimeUpdated;
        private string _UserInserted;
        private string _UserUpdated;
        private string _LastContextClientAddress;
        private int _LastContextSessionId;
        private int _LastContextTransactionId;
        private long _OrigLogId;
        private string _PrevRowId;

        // указатели на данные в пакете, для облегчения доступа к ним
        private int _ReplicaTableIndex;
        private int [] _ReplicaRowIndexes;

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - 

        #region конструктор

        public SyncLogItem()
        {
        }

        public SyncLogItem(IDataReader reader)
        {
            FillFromReader(reader);
        }

        #endregion
        // - - - - - - - - - - - - - - - - - - - - - - - - 

        #region свойства

        public long Id
        {
            get { return _Id; }
            set { _Id = value; }
        }

        public string TableName
        {
            get { return _TableName; }
            set { _TableName = value; }
        }

        public string ActionMode
        {
            get { return _ActionMode; }
            set { _ActionMode = value; }
        }

        public string RowId
        {
            get { return _RowId; }
            set { _RowId = value; }
        }

        public int ParticipantId
        {
            get { return _ParticipantId; }
            set { _ParticipantId = value; }
        }

        public int UpdateCount
        {
            get { return _UpdateCount; }
            set { _UpdateCount = value; }
        }

        public DateTime TimeInserted
        {
            get { return _TimeInserted; }
            set { _TimeInserted = value; }
        }

        public DateTime TimeUpdated
        {
            get { return _TimeUpdated; }
            set { _TimeUpdated = value; }
        }

        public string UserInserted
        {
            get { return _UserInserted; }
            set { _UserInserted = value; }
        }

        public string UserUpdated
        {
            get { return _UserUpdated; }
            set { _UserUpdated = value; }
        }

        public string LastContextClientAddress
        {
            get { return _LastContextClientAddress; }
            set { _LastContextClientAddress = value; }
        }

        public int LastContextSessionId
        {
            get { return _LastContextSessionId; }
            set { _LastContextSessionId = value; }
        }

        public int LastContextTransactionId
        {
            get { return _LastContextTransactionId; }
            set { _LastContextTransactionId = value; }
        }

        public long OrigLogId
        {
            get { return _OrigLogId; }
            set { _OrigLogId = value; }
        }

        public string PrevRowId
        {
            get { return _PrevRowId; }
            set { _PrevRowId = value; }
        }

        public int ReplicaTableIndex
        {
            get { return _ReplicaTableIndex; }
            set { _ReplicaTableIndex = value; }
        }

        public int[] ReplicaRowIndexes
        {
            get { return _ReplicaRowIndexes; }
            set { _ReplicaRowIndexes = value; }
        }
         
	    #endregion    

        // - - - - - - - - - - - - - - - - - - - - - - - - 

        public virtual void FillFromReader(IDataReader reader)
        {
            _Id = Convert.ToInt64(reader["ID"]);
            _TableName = Convert.ToString(reader["TABLE_NAME"]);
            _ActionMode = Convert.ToString(reader["ACTION_MODE"]);
            _RowId = Convert.ToString(reader["ROW_ID"]);
            _PrevRowId = Convert.ToString(reader["PREV_ROW_ID"]);
            _ParticipantId = Convert.ToInt32(reader["PARTICIPANT_ID"]);
            _UpdateCount = Convert.ToInt32(reader["UPDATE_COUNT"]);
            _TimeInserted = Convert.ToDateTime(reader["TM_INSERTED"]);
            _TimeUpdated = Convert.ToDateTime(reader["TM_UPDATED"]);
            _UserInserted = Convert.ToString(reader["USER_INSERTED"]);
            _UserUpdated = Convert.ToString(reader["USER_UPDATED"]);
            _LastContextClientAddress = Convert.ToString(reader["LAST_CONTEXT_CLIENT_ADDRESS"]);
            _LastContextSessionId = Convert.ToInt32(reader["LAST_CONTEXT_SESSION_ID"]);
            _LastContextTransactionId = Convert.ToInt32(reader["LAST_CONTEXT_TRANSACTION_ID"]);
        }

        public override string ToString()
        {
            return string.Format("{3}: {0}: {1} {2}", TableName, ActionMode, RowId, Id);
        }

    }

    [Serializable]
    public class SyncLogItemList : List<SyncLogItem>
    {
    }
}
