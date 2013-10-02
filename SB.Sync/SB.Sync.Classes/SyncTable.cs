using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace SB.Sync.Classes
{
    /// <summary>
    /// класс для хранения информации о таблице, учавствующей в процессе синхронизации
    /// </summary>
    [Serializable]
    public class SyncTable
    {
        // - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region приватные поля данных

        private string _TableName;
        private string _Name;
        private string _Description;
        private bool _Archived;
        private bool _ArchiveUpdates;
        private bool _ArchiveDeletes;
        private int _ArchiveUpdatesMaxDays;
        private long _ArchiveUpdatesMaxCount;
        private int _ArchiveDeletesMaxDays;
        private long _ArchiveDeletesMaxCount;
        private string _ArchiveIgnoreFields;
        private bool _Logged;
        private bool _LogInserts;
        private bool _LogUpdates;
        private bool _LogDeletes;
        private string _LogIgnoreFields;

        [NonSerialized]
        private List<DataColumn> _Columns;
        private List<string> keyColumns;

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public SyncTable()
        {
            _Columns = new List<DataColumn>();
            keyColumns = new List<string>();
        }

        #region свойства

        public string TableName
        {
            get { return _TableName; }
            set { _TableName = value; }
        }

        public string Name
        {
            get { return _Name; }
            set { _Name = value; }
        }

        public string Description
        {
            get { return _Description; }
            set { _Description = value; }
        }

        public bool Archived
        {
            get { return _Archived; }
            set { _Archived = value; }
        }

        public bool ArchiveUpdates
        {
            get { return _ArchiveUpdates; }
            set { _ArchiveUpdates = value; }
        }

        public bool ArchiveDeletes
        {
            get { return _ArchiveDeletes; }
            set { _ArchiveDeletes = value; }
        }

        public int ArchiveUpdatesMaxDays
        {
            get { return _ArchiveUpdatesMaxDays; }
            set { _ArchiveUpdatesMaxDays = value; }
        }

        public long ArchiveUpdatesMaxCount
        {
            get { return _ArchiveUpdatesMaxCount; }
            set { _ArchiveUpdatesMaxCount = value; }
        }

        public int ArchiveDeletesMaxDays
        {
            get { return _ArchiveDeletesMaxDays; }
            set { _ArchiveDeletesMaxDays = value; }
        }

        public long ArchiveDeletesMaxCount
        {
            get { return _ArchiveDeletesMaxCount; }
            set { _ArchiveDeletesMaxCount = value; }
        }

        public string ArchiveIgnoreFields
        {
            get { return _ArchiveIgnoreFields; }
            set { _ArchiveIgnoreFields = value; }
        }

        public bool Logged
        {
            get { return _Logged; }
            set { _Logged = value; }
        }

        public bool LogInserts
        {
            get { return _LogInserts; }
            set { _LogInserts = value; }
        }

        public bool LogUpdates
        {
            get { return _LogUpdates; }
            set { _LogUpdates = value; }
        }

        public bool LogDeletes
        {
            get { return _LogDeletes; }
            set { _LogDeletes = value; }
        }

        public string LogIgnoreFields
        {
            get { return _LogIgnoreFields; }
            set { _LogIgnoreFields = value; }
        }

        public List<DataColumn> Columns
        {
            get { return _Columns; }
            set { _Columns = value; }
        }

        public List<string> KeyColumns
        {
            get { return keyColumns; }
        }

	    #endregion    

        // - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region методы

        public void FillFromReader(IDataReader reader)
        {
            _TableName = Convert.ToString(reader["TABLE_NAME"]);
            _Name = Convert.ToString(reader["NAME"]);
            _Description = Convert.ToString(reader["DESCR"]);
            _Archived = (Convert.ToInt32(reader["ARCHIVED"]) == 1);
            _ArchiveUpdates = (Convert.ToInt32(reader["ARCHIVE_UPDATES"]) == 1);
            _ArchiveDeletes = (Convert.ToInt32(reader["ARCHIVE_DELETES"]) == 1);
            _ArchiveUpdatesMaxDays = ReadInt32(reader, "ARCHIVE_UPDATES_MAX_DAYS");
            _ArchiveUpdatesMaxCount = ReadInt32(reader, "ARCHIVE_UPDATES_MAX_COUNT");
            _ArchiveDeletesMaxDays = ReadInt32(reader, "ARCHIVE_DELETES_MAX_DAYS");
            _ArchiveDeletesMaxCount = ReadInt32(reader, "ARCHIVE_DELETES_MAX_COUNT");
            _ArchiveIgnoreFields = Convert.ToString(reader["ARCHIVE_IGNORE_FIELDS"]);
            _Logged = (Convert.ToInt32(reader["LOGGED"]) == 1);
            _LogInserts = (Convert.ToInt32(reader["LOG_INSERTS"]) == 1);
            _LogUpdates = (Convert.ToInt32(reader["LOG_UPDATES"]) == 1);
            _LogDeletes = (Convert.ToInt32(reader["LOG_DELETES"]) == 1);
            _LogIgnoreFields = Convert.ToString(reader["LOG_IGNORE_FIELDS"]);
        }

        private int ReadInt32(IDataReader reader, string fn)
        {
            if (!reader.IsDBNull(reader.GetOrdinal(fn)))
                return Convert.ToInt32(reader[fn]);
            else
                return 0;
        }

        public DataColumn FindColumn(string columnName)
        {
            return Columns.Find(delegate(DataColumn col)
            {
                return (string.Compare(col.ColumnName, columnName) == 0);
            });
        }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(TableName);
            if (!string.IsNullOrEmpty(Name))
            {
                sb.Append(": ");
                sb.Append(Name);
            }
            return sb.ToString();
        }

        #endregion
    }

    // ========================================================================

    [Serializable]
    public class SyncTableList : List<SyncTable>
    {
        public SyncTable this[string tableName]
        {
            get
            {
                return Find(delegate(SyncTable st)
                {
                    return (string.Compare(st.TableName, tableName) == 0);
                });
            }
        }


    }

    // ========================================================================

}
