using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Reflection;
using log4net;

namespace SB.Sync.Classes
{
    [Serializable]
    public class SyncLink 
    {

        #region приватные поля данных

        private int _Id;
        private string _Name;
        private SyncParticipant _ParticipantFrom;
        private SyncParticipant _ParticipantTo;
        private long _LogPosition;
        private int _PositionUpdateCount;
        private DateTime _LastUpdateTime;
        private string _LastUpdateUser;
        private string _LastUpdateClientAddr;
        public SyncLinkFilterList Filters;

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region свойства

        public int Id
        {
            get { return _Id; }
            set { _Id = value; }
        }

        public string Name
        {
            get { return _Name; }
            set { _Name = value; }
        }

        public SyncParticipant ParticipantFrom
        {
            get { return _ParticipantFrom; }
            set { _ParticipantFrom = value; }
        }

        public SyncParticipant ParticipantTo
        {
            get { return _ParticipantTo; }
            set { _ParticipantTo = value; }
        }

        public long LogPosition
        {
            get { return _LogPosition; }
            set { _LogPosition = value; }
        }

        public int PositionUpdateCount
        {
            get { return _PositionUpdateCount; }
            set { _PositionUpdateCount = value; }
        }

        public DateTime LastUpdateTime
        {
            get { return _LastUpdateTime; }
            set { _LastUpdateTime = value; }
        }

        public string LastUpdateUser
        {
            get { return _LastUpdateUser; }
            set { _LastUpdateUser = value; }
        }

        public string LastUpdateClientAddr
        {
            get { return _LastUpdateClientAddr; }
            set { _LastUpdateClientAddr = value; }
        }

        #endregion    

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region логгер

        //[NonSerialized]
        //private ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);

        #endregion
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region ISyncDataObject Members

        public void Fill(SyncDatabase db, IDataReader reader)
        {
            _Id = Convert.ToInt32(reader["ID"]);
            _Name = Convert.ToString(reader["NAME"]);
            _ParticipantFrom = SyncParticipant.GetById(Convert.ToInt32(reader["PARTICIPANT_FROM"]), db);
            _ParticipantTo = SyncParticipant.GetById(Convert.ToInt32(reader["PARTICIPANT_TO"]), db);
            _LogPosition = Convert.ToInt64(reader["LOG_POSITION"]);
            _PositionUpdateCount = Convert.ToInt32(reader["POSITION_UPD_COUNT"]);
            if (!reader.IsDBNull(reader.GetOrdinal("LAST_UPDATE_TM")))
                _LastUpdateTime = Convert.ToDateTime(reader["LAST_UPDATE_TM"]);
            if (!reader.IsDBNull(reader.GetOrdinal("LAST_UPDATE_USER_ID")))
                _LastUpdateUser = Convert.ToString(reader["LAST_UPDATE_USER_ID"]);
            if (!reader.IsDBNull(reader.GetOrdinal("LAST_UPDATE_CLIENT_ADDR")))
                _LastUpdateClientAddr = Convert.ToString(reader["LAST_UPDATE_CLIENT_ADDR"]);
        }

        #endregion

        internal bool Fill(SyncDatabase db)
        {
            using (IDbCommand cmd = db.CreateCommand())
            {
                cmd.CommandText = "select * from sync_link where id = @id";
                IDbDataParameter p = cmd.CreateParameter() as IDbDataParameter;
                p.DbType = DbType.Int32;
                p.Direction = ParameterDirection.Input;
                p.Value = Id;
                p.ParameterName = "@id";
                cmd.Parameters.Add(p);
                using (IDataReader reader = cmd.ExecuteReader())
                    if (reader.Read())
                    {
                        Fill(db, reader);
                        return true;
                    }
                    else
                    {
                        Clear();
                        return false;
                    }
            }
        }

        private void Clear()
        {
            _Id = 0;
            _Name = string.Empty;
            _ParticipantFrom = null;
            _ParticipantTo = null;
            _LogPosition = 0;
            _PositionUpdateCount = 0;
            _LastUpdateTime = DateTime.MinValue;
            _LastUpdateUser = string.Empty;
            _LastUpdateClientAddr = string.Empty;
        }

        internal static SyncLink GetById(int value, SyncDatabase db)
        {
            SyncLink result = new SyncLink();
            result.Id = value;
            if (result.Fill(db))
                return result;
            return null;
        }

        public override string ToString()
        {
            return string.Format("{0}: {1}", Id, Name);
        }
    }
}
