using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Reflection;

namespace SB.Sync.Classes
{
    public enum SyncDatabaseVendorCommandMode
    {
        Unknown = 0,
        UpdateOrInsertTable = 1
    }

    public abstract class SyncDatabaseVendor
    {
        private static SyncDatabaseVendorList _List = CreateSyncDatabaseVendorList();

        private static SyncDatabaseVendorList CreateSyncDatabaseVendorList()
        {
            SyncDatabaseVendorList result = new SyncDatabaseVendorList();
            foreach (Assembly assembly in AppDomain.CurrentDomain.GetAssemblies())
                if (!assembly.FullName.StartsWith("SB.Lib"))
                    try
                    {
                        foreach (Type t in assembly.GetTypes())
                            if (t.IsSubclassOf(typeof(SyncDatabaseVendor)))
                                result.Add(Activator.CreateInstance(t) as SyncDatabaseVendor);
                    }
                    catch
                    {
                        // failed to load assembly, continuing
                    }
            return result;
        }

        public abstract IDbTransaction StartTransaction(IDbConnection Connection, bool serializable);

        public static SyncDatabaseVendorList List
        {
            get { return _List; }
        }

        public static void RegisterVendor(SyncDatabaseVendor vendor)
        {
            if (List.GetVendor(vendor.ConnectionType) == null)
                List.Add(vendor);
            else
                throw new ArgumentException("Database vendor with this connection type is already added!");
        }

        public abstract Type ConnectionType
        {
            get;
        }

        public abstract string GetParameterPrefix();

        public abstract IDataAdapter CreateDataAdater(IDbCommand command);

        public abstract SyncTableRelationList GetRelationsForTables(SyncTableList list, SyncDatabase db);

        /// <summary>
        /// заполнить список полей для указанной таблицы
        /// </summary>
        public abstract void FillTableColumnsList(SyncDatabase db, string TableName, SyncTable table);

        /// <summary>
        /// получение специальной команды для выполнения различных действий, например обновления таблицы
        /// </summary>
        /// <param name="mode"></param>
        /// <param name="args"></param>
        public abstract IDbCommand CreateSpecialCommand(SyncDatabase db, SyncDatabaseVendorCommandMode mode, params object[] args);
        public abstract void CleanSpecialCommand(SyncDatabase db, SyncDatabaseVendorCommandMode mode);
        public abstract void StartSession(SyncDatabase db, SessionMode Mode);
        public abstract void UpgradeAndDisableTriggers(SyncDatabase db, SyncTableList tables);
        public abstract void DisableTriggers(SyncDatabase db);
        public abstract List<string> GetKeyColumns(SyncDatabase syncDatabase, string tableName);

        public abstract void WriteSyncJournal(SyncDatabase db, SyncJournalInfo JournalInfo);
    }

    public class SyncDatabaseVendorList : List<SyncDatabaseVendor>
    {
        public SyncDatabaseVendor GetVendor(Type ConnectionType)
        {
            return Find(
                delegate(SyncDatabaseVendor vendor)
                {
                    return (ConnectionType == vendor.ConnectionType);
                });
        }
    }
    
    // ========================================================================================================
    
    public class SyncTableRelation
    {
        public string ParentTable;
        public string [] ParentColumns;
        public string ChildTable;
        public string [] ChildColumns;

        public bool ChildNullable = true;

        public SyncTableRelation()
        {
        }

        public SyncTableRelation(string ParentTable, string [] ParentColumns, 
            string ChildTable, string [] ChildColumns)
        {
        }

        public override string ToString()
        {
            return string.Format("{0} ({1}) -> {2} ({3})",
                ChildTable, ArrayToString(ChildColumns), ParentTable, ArrayToString(ParentColumns));
        }

        private string ArrayToString(string[] cols)
        {
            StringBuilder sb = new StringBuilder();
            foreach (string col in cols)
            {
                if (sb.Length > 0)
                    sb.Append(",");
                sb.Append(col);
            }
            return sb.ToString();
        }
    }

    // ========================================================================================================

    public class SyncTableRelationList : List<SyncTableRelation>
    {

    }

    // ========================================================================================================

    /// <summary>
    /// взаимная связь двух таблиц друг на друга
    /// </summary>
    public class SyncTableCrossLink
    {
        public SyncTableCrossLink( SyncTableRelation rel1, SyncTableRelation rel2)
        {

        }

    }

    // ========================================================================================================

    public class SyncTableCrossLinkList : List<SyncTableCrossLink>
    {
    }

    // ========================================================================================================

    public class SyncJournalInfo
    {
        public DateTime Date { get; set; }
        public DateTime TimeStart { get; set; }
        public DateTime TimeEnd { get; set; }
        public int LocalLinkId { get; set; }
        public int RemoteLinkId { get; set; } 
        public string LogMessages { get; set; }
        public bool Success { get; set; }
        public ulong LocalReplicaCount { get; set; }
        public ulong RemoteReplicaCount { get; set; }
    }
}
