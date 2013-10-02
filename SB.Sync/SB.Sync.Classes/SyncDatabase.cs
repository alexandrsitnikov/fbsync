using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Reflection;
using log4net;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using log4net.Core;
using log4net.Appender;

namespace SB.Sync.Classes
{
    public class SyncDatabase : MarshalByRefObject, ISyncDatabase
    {
        #region приватные поля данных
        
        private IDbConnection _Connection;
        private IDbTransaction _Transaction;
        private SyncDatabaseVendor vendor;
        private ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);
        //private SyncSession _Session;
        private string _Name;
        private SyncTableList _AllTables;
        private IDbCommand cmd_ExecuteReader;
        private IDbCommand cmd_FillSyncTables;
        private SyncTableRelationList relations;
        private bool _InSession;
        
        // параметры подготовки журнала
        private SyncLink link;
        private SyncLogItemList logList;
        private SyncTableList logUsedTables;
        private long minLogId;
        private long lastLogId;

        // параметры запуска
        private int _BatchLogItemCount = -1;

        private int LogIndex;
        private int LogReplicaIndex;

        private SyncLogReplicaInfo replicaInfo;
        private SyncReplicaProcessResult _TargetProcessResult;
        private SyncTableRelationList _CrossLinks;
        private bool _SecondStage;
        private SyncTableList _SecondStageTables;

        private SyncReplicaProcessResult _ProcessResult;
        private StringBuilder logMessages;
        private TextWriterAppender appenderLogMessages;
        
        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region конструктор
        
        public SyncDatabase(IDbConnection Connection)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("ctor:begin"));

            SourcePrepare_AddSequences = true;
            
            this._Connection = Connection;
            vendor = SyncDatabaseVendor.List.GetVendor(Connection.GetType());
            if (vendor == null)
                throw new ArgumentException(string.Format(
                    "No registered database vendor for type \"{0}\"!", Connection.GetType().Name), "Connection");

            _Name = string.Empty;

            logList = new SyncLogItemList();
            logUsedTables = new SyncTableList();
            _CrossLinks = new SyncTableRelationList();

            if (log.IsDebugEnabled) log.Debug(FMsg("ctor:end"));
        }

        #endregion
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
        
        #region свойства

        public string Name
        {
            get { return _Name; }
            set 
            { 
                _Name = value;
                log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType.FullName + "." + Name);
            }
        }

        public IDbConnection Connection
        {
            get { return _Connection; }
        }

        public IDbTransaction Transaction
        {
            get { return _Transaction; }
        }

        internal SyncDatabaseVendor Vendor
        {
            get { return vendor; }
            set { vendor = value; }
        }

        public bool InSession
        {
            get { return _InSession; }
        }

        public SessionMode SessionMode
        {
            get;
            private set;
        }

        /// <summary>
        /// максимальное количество передаваемых элементов журнала
        /// </summary>
        public int BatchLogItemCount
        {
            get { return _BatchLogItemCount; }
            set { _BatchLogItemCount = value; }
        }

        public bool SourcePrepare_AddSequences
        {
            get;
            set;
        }
        
        #endregion      
        
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        internal IDbCommand CreateCommand()
        {
            IDbCommand result = Connection.CreateCommand();
            result.Transaction = Transaction;
            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


        private IDataReader ExecuteReader(string sql)
        {
            if (cmd_ExecuteReader != null)
                cmd_ExecuteReader = CreateCommand();
            cmd_ExecuteReader.CommandText = sql;
            return cmd_ExecuteReader.ExecuteReader();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


        private void AddParameter(IDbCommand cmd, string par_name, DbType par_type, object par_value)
        {
            IDbDataParameter par = cmd.CreateParameter();
            par.DbType = par_type;
            par.Direction = ParameterDirection.Input;
            par.ParameterName = par_name;
            par.Value = par_value;
            cmd.Parameters.Add(par);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public SyncLink GetSyncLink(int link_id)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("GetSyncLink"));
            EnsureConnectionIsOpen();
            return SyncLink.GetById(link_id, this);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public void StartSession(SessionMode Mode)
        {
            _BeginStoreLogMessages();
            if (log.IsDebugEnabled) log.Debug(FMsg("StartSession:begin"));
            this.SessionMode = Mode;
            
            CheckInSessionState(false);

            _Transaction = vendor.StartTransaction(Connection, (Mode == SessionMode.Read));

            log.Info(FMsg(" -- начат сеанс работы"));

            if (Mode == SessionMode.Read)
                StartSessionRead();
            else if (Mode == SessionMode.Write)
                StartSessionWrite();

            vendor.StartSession(this, Mode);

            _InSession = true;

            if (log.IsDebugEnabled) log.Debug(FMsg("StartSession:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void StartSessionRead()
        {
            FillAllTables();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void StartSessionWrite()
        {
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void EnsureConnectionIsOpen()
        {
            if (Connection.State != ConnectionState.Open)
            {
                log.Info(FMsg("открывается соединение с БД"));
                Connection.Open();
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void FillAllTables()
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("FillAllTables:begin"));

            _AllTables = new SyncTableList();
            if (cmd_FillSyncTables == null)
            {
                cmd_FillSyncTables = CreateCommand();
                cmd_FillSyncTables.CommandText = "select * from SYNC_TABLE";
            }
         
            using (IDataReader reader = cmd_FillSyncTables.ExecuteReader())
                while (reader.Read())
                {
                    SyncTable st = new SyncTable();
                    st.FillFromReader(reader);
                    _AllTables.Add(st);
                }

            log.DebugFormat(FMsg("{0} таблиц синхронизации"), _AllTables.Count);

            if (log.IsDebugEnabled) log.Debug(FMsg("FillAllTables:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        internal string FMsg(string p)
        {
            MDC.Set("db_name", Name);
 	        return string.Format("{1}", Name, p);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public ILog Log
        {
            get { return log; }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public void EndSession(bool commit)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("EndSession:begin"));

            try
            {
                if (_InSession)
                {
                    if (commit)
                    {
                        Transaction.Commit();
                        log.Info(FMsg("транзакция подтверждена"));
                    }
                    else
                    {
                        Transaction.Rollback();
                        log.Warn(FMsg("транзакция откачена"));
                    }

                    _InSession = false;
                }
            }
            catch (Exception ex)
            {
                log.Error(string.Format(FMsg("Ошибка при завершении сеанса: {0}"), ex.Message), ex);
                throw;
            }

            if (log.IsDebugEnabled) log.Debug(FMsg("EndSession:end"));
            _EndStoreLogMessages();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void CheckInSessionState(bool sessionState)
        {
            if (!sessionState)
            {
                if (_InSession)
                    throw new InvalidOperationException("Session already started!");
            }
            else
            {
                if (!_InSession)
                    throw new InvalidOperationException("Session not started!");
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public SyncLogReplicaInfo SourcePrepare(SyncLink link)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("GetReplica:begin"));

            this.link = link;

            log.InfoFormat(FMsg("подготовка данных: {0}"), link.ToString());

            // проверка открытого сеанса
            CheckInSessionState(true);

            // проверка переданной связи
            CheckLink(link);

            // запрос журнала
            FillSyncLogItems();

            LogIndex = 0;
            LogReplicaIndex = 0;

            replicaInfo = new SyncLogReplicaInfo();
            replicaInfo.Created = DateTime.Now;
            replicaInfo.Link = link;
            replicaInfo.LogCount = Convert.ToUInt64(logList.Count);
            replicaInfo.MaxLogId = lastLogId;
            replicaInfo.MinLogId = minLogId;
            replicaInfo.ReplicaBatchSize = BatchLogItemCount;
            if (BatchLogItemCount > 0)
                replicaInfo.ReplicaCount = Convert.ToUInt32(logList.Count / BatchLogItemCount);
            else
                replicaInfo.ReplicaCount = 1;

            if (log.IsDebugEnabled) log.Debug(FMsg("GetReplica:end"));
            return replicaInfo;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void FillSyncLogItems()
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("FillSyncLogItems:begin"));

            log.Info(FMsg("запрос журнала"));

            // используем отдельную транзакцию для получения журнала
            _Transaction.Commit();
            try
            {
                IDbTransaction transaction = vendor.StartTransaction(Connection, false);
                try
                {
                    logList.Clear();
                    logUsedTables.Clear();

                    lastLogId = 0;
                    minLogId = Int32.MaxValue;
                    using (IDbCommand cmd = CreateCommand())
                    {
                        cmd.CommandText = Const.SP_SYNC_LOG_GET;
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Transaction = transaction;
                        AddParameter(cmd, Const.Par_BY_LINK_ID, DbType.Int32, link.Id);
                        using (IDataReader reader = cmd.ExecuteReader())
                            while (reader.Read())
                            {
                                SyncLogItem item = new SyncLogItem(reader);
                                logList.Add(item);
                                lastLogId = Convert.ToInt64(reader["LAST_LOG_ID"]);
                                minLogId = Math.Min(minLogId, item.Id);
                            }
                    }
                    if (logList.Count > 0)
                        log.InfoFormat(FMsg("получен журнал с {0} записями"), logList.Count);
                    transaction.Commit();
                }
                catch
                {
                    transaction.Rollback();
                    throw;
                }
            }
            finally
            {
                _Transaction = vendor.StartTransaction(Connection, true);
            }

            if (logList.Count > 0)
            {
                // подготовка списка используемых таблиц в журнале
                logUsedTables = GetTableListFromLog(logList);

                // заполнение схемы (списка полей) используемых таблиц
                UsedTablesFillColumns(logUsedTables);
            }
            if (log.IsDebugEnabled) log.Debug(FMsg("FillSyncLogItems:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// заполнение схемы (списка полей) используемых таблиц
        /// </summary>
        /// <param name="logUsedTables"></param>
        private void UsedTablesFillColumns(SyncTableList tables)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("UsedTablesFillColumns:begin"));

            foreach (SyncTable table in tables)
            {
                table.Columns.Clear();
                vendor.FillTableColumnsList(this, table.TableName, table);
            }

            log.InfoFormat(FMsg("получена схема для {0} таблиц в выгружаемом пакете"), tables.Count);

            if (log.IsDebugEnabled) log.Debug(FMsg("UsedTablesFillColumns:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// заполнение схемы (списка полей) используемых таблиц
        /// </summary>
        /// <param name="logUsedTables"></param>
        private void TargetProcessFillColumns(SyncTableList tables)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessFillColumns:begin"));

            foreach (SyncTable table in tables)
                if (table.Columns == null)
                {
                    table.Columns = new List<DataColumn>();
                    vendor.FillTableColumnsList(this, table.TableName, table);
                }

            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessFillColumns:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private SyncTableList GetTableListFromLog(SyncLogItemList list)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("GetTableListFromLog:begin"));

            SyncTableList result = new SyncTableList();
            foreach (SyncLogItem li in list)
                if (li.TableName != Const.Table_SYNC_LOG)
                {
                    SyncTable st = _AllTables[li.TableName];
                    if (st == null)
                        throw new InvalidOperationException(
                            string.Format(Const.Msg_SyncTableNotFound, li.TableName));
                    if (!result.Contains(st))
                        result.Add(st);
                }

            if (log.IsDebugEnabled) log.Debug(FMsg("GetTableListFromLog:end"));

            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void CheckLink(SyncLink link)
        {
            if (!link.Fill(this))
                throw new ArgumentException("Invalid sync link specified!");
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private SyncTableList SortTableList(SyncTableList list, bool FindCrossLinks)
        {
            return SortTableList(list, FindCrossLinks, true);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// сортировка списка таблиц в порядке их обхода
        /// </summary>
        private SyncTableList SortTableList(SyncTableList list, bool FindCrossLinks, bool ascending)
        {
            SyncTableList result = new SyncTableList();
            result.AddRange(list.ToArray());

            relations = vendor.GetRelationsForTables(list, this);
            if (FindCrossLinks)
                PrepareRelationsList(relations, list);

            int max_iteration_count = relations.Count * 3;

            bool bmoved = true;
            int it_count = 0;
            while (bmoved && (it_count++ < max_iteration_count))
            {
                bmoved = false;
                foreach (SyncTableRelation rel in relations)
                {
                    SyncTable t_parent = result[rel.ParentTable];
                    SyncTable t_child = result[rel.ChildTable];
                    if ((t_parent != null) && (t_child != null))
                    {
                        int ix_parent = result.IndexOf(t_parent);
                        int ix_child = result.IndexOf(t_child);
                        if (ix_parent > ix_child)
                        {
                            result.RemoveAt(ix_parent);
                            result.Insert(ix_parent, t_child);
                            result.RemoveAt(ix_child);
                            result.Insert(ix_child, t_parent);
                            bmoved = true;
                        }
                    }
                }
            }

            if (!ascending)
                result.Reverse();

            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// подготовка списка - убирание взаимозависимых парных связей
        /// </summary>
        /// <param name="relations"></param>
        private void PrepareRelationsList(SyncTableRelationList relations, SyncTableList list)
        {
            _CrossLinks.Clear();
            SyncTableRelationList remove_list = new SyncTableRelationList();
            foreach (SyncTableRelation rel1 in relations)
                foreach (SyncTableRelation rel2 in relations)
                    if (rel1 != rel2 &&
                        !remove_list.Contains(rel1) &&
                        !remove_list.Contains(rel2) &&
                        rel1.ParentTable == rel2.ChildTable &&
                        rel2.ParentTable == rel1.ChildTable)
                    {
                        remove_list.Add(rel1);
                        remove_list.Add(rel2);

                        if (list[rel1.ChildTable] != null)
                            rel1.ChildNullable = list[rel1.ChildTable].FindColumn(rel1.ChildColumns[0].Trim()).AllowDBNull;
                        if (list[rel2.ChildTable] != null)
                            rel2.ChildNullable = list[rel2.ChildTable].FindColumn(rel2.ChildColumns[0].Trim()).AllowDBNull;

                        if (!rel1.ChildNullable && !rel2.ChildNullable)
                            throw new ArgumentException(string.Format(
                                "Невозможно обработать взаимную связь, для которой обе стороны помечены как NOT NULL! ({0}; {1})",
                                rel1, rel2));

                        _CrossLinks.Add(rel1);
                        _CrossLinks.Add(rel2);
                    }
            foreach (SyncTableRelation rel in remove_list)
                relations.Remove(rel);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        public SyncLogReplica SourceGetNextReplica(SyncLogReplicaInfo info, SourcePrepareOptions Options, SyncLinkFilterList Filters)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("SourceGetNextReplica:begin"));

            SyncLogReplica replica = new SyncLogReplica(replicaInfo);
            replica.Index = LogReplicaIndex++;

            log.InfoFormat(FMsg("заполнение журнала реплики № {0}"), replica.Index);
            if (BatchLogItemCount > 0)
                log.InfoFormat(FMsg("макс кол-во записей журнала в реплике - {0}"), BatchLogItemCount);

            while (LogIndex < logList.Count)
            {
                if (BatchLogItemCount > 0)
                    if (replica.LogItems.Count >= BatchLogItemCount)
                        break;
                replica.LogItems.Add(logList[LogIndex]);
                LogIndex++;
            }

            log.InfoFormat(FMsg("в журнале реплики {0} записей"), replica.LogItems.Count);

            FillReplica(replica, Filters);

            if (log.IsDebugEnabled) log.Debug(FMsg("SourceGetNextReplica:end"));

            return replica;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void FillReplica(SyncLogReplica replica, SyncLinkFilterList Filters)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("FillReplica:begin"));

            log.InfoFormat(FMsg("заполнение данных реплики № {0}"), replica.Index);

            replica.Tables = GetTableListFromLog(replica.LogItems);

            SyncLogItemList LogItemsToRemove = new SyncLogItemList();

            foreach (SyncTable st in replica.Tables)
            {
                log.DebugFormat(FMsg("{0}..."), st.TableName);
                int count = 0;

                // создается структура таблицы
                DataTable table = replica.AddDataTable(st);
                IDbCommand cmdReadRow = CreateReadRowCommand(st);

                // заполняются данные в пакете
                foreach (SyncLogItem log_item in replica.LogItems)
                {
                    log_item.ReplicaTableIndex = table.DataSet.Tables.IndexOf(log_item.TableName);
                 
                    if (log_item.TableName == st.TableName &&
                        log_item.ActionMode != Const.ActionMode_Deleted)
                    {
                        bool added = true;
                        SetCommandParameters(cmdReadRow, log_item.RowId, table);
                        try
                        {
                            using (IDataReader reader = cmdReadRow.ExecuteReader())
                            {
                                int added_count = 0;
                                while (reader.Read())
                                {
                                    if (!AddToTable(reader, table, log_item, Filters))
                                    {
                                        LogItemsToRemove.Add(log_item);
                                        added = false;
                                    }
                                    else
                                        added_count++;
                                }
                                if (added)
                                {
                                    if (added_count == 0)
                                        log.WarnFormat(FMsg("запрос для получения записи ({0};{1}) не вернул записей!"),
                                            st.TableName, log_item.RowId);
                                    if (added_count > 1)
                                        log.WarnFormat(FMsg("запрос для получения записи ({0};{1}) вернул более одной записи!"),
                                            st.TableName, log_item.RowId);
                                }
                            }
                        }
                        catch
                        {
                            throw;
                        }
                        if (added)
                            count++;
                    }
                }

                if (count > 0)
                    log.InfoFormat(FMsg("{0} - {1} записей."), st.TableName, count);
            }

            foreach (SyncLogItem log_item_remove in LogItemsToRemove)
            {
                replica.LogItems.Remove(log_item_remove);
            }

            // очистка пустых таблиц данных
           /* int i = 0;
            while (i < replica.Tables.Count)
            {
                string tableName = replica.Tables[i].TableName;
                if (replica.DataSet.Tables[tableName].Rows.Count == 0)
                {
                    //replica.Tables.RemoveAt(i);
                    replica.DataSet.Tables.Remove(tableName);
                }
                //else
                    i++;
            }*/

            if (log.IsDebugEnabled) log.Debug(FMsg("FillReplica:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// копирование полученных данных в таблицу буфера
        /// </summary>
        private bool AddToTable(IDataReader reader, DataTable table, SyncLogItem log_item, SyncLinkFilterList Filters)
        {
            try
            {
                DataRow newRow = table.NewRow();
                foreach (DataColumn col in table.Columns)
                {
                    if (col.ColumnName == Const.Field_LOG_ID)
                        newRow[Const.Field_LOG_ID] = log_item.Id;
                    else
                    {
                        int reader_index = reader.GetOrdinal(col.ColumnName);
                        if (reader_index >= 0)
                            newRow[col] = reader[reader_index];
                    }
                }

                bool allow_add = true;
                if (Filters != null)
                    allow_add = Filters.FilterRow(table, newRow, log_item);

                if (allow_add)
                {
                    table.Rows.Add(newRow);

                    if (log_item.ReplicaRowIndexes == null || log_item.ReplicaRowIndexes.Length == 0)
                        log_item.ReplicaRowIndexes = new int[] { table.Rows.Count - 1 };
                    else
                    {
                        int cur_count = log_item.ReplicaRowIndexes.Length;
                        int[] saved = log_item.ReplicaRowIndexes;
                        log_item.ReplicaRowIndexes = new int[cur_count + 1];
                        for (int i = 0; i < cur_count; i++)
                            log_item.ReplicaRowIndexes[i] = saved[i];
                        log_item.ReplicaRowIndexes[cur_count] = table.Rows.Count;
                    }
                    return true;
                }
                else
                    return false;

            }
            catch (Exception ex)
            {
                LogMethodException(MethodInfo.GetCurrentMethod(), ex);
                throw;
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void LogMethodException(MethodBase method, Exception ex)
        {
            log.Error(string.Format(FMsg("{0}: Необработанное исключение. {1}."), method.Name, ex.Message), ex);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void SetCommandParameters(IDbCommand cmd, string row_id, DataTable table)
        {
            List<string> keys = new List<string>(3);
            if (row_id.StartsWith("<"))
            {
                Regex regex = new Regex("<[^<>]*>", RegexOptions.Compiled);
                MatchCollection mc = regex.Matches(row_id);
                foreach (Match m in mc)
                    keys.Add(m.Value.Trim(' ', '<', '>'));
            }
            else
                keys.Add(row_id);

            if (cmd.Parameters.Count != keys.Count)
                throw new ArgumentException(string.Format("Несоответствие числа полей данных первичному ключу таблицы! ({0}, {1})",
                    table.TableName, row_id));

            List<string> key_cols = vendor.GetKeyColumns(this, table.TableName);

            for (int i = 0; i < keys.Count; i++)
            {
                string col_name = key_cols[i];
                DataColumn col = table.Columns[col_name];
                if (col == null)
                    throw new ArgumentException(string.Format("Не найдена колонка {0} в параметрах запроса!", col_name));

                object val;

                if (string.IsNullOrEmpty(keys[i]))
                    val = DBNull.Value;
                else if (col.DataType == typeof(DateTime))
                    val = Convert.ToDateTime(keys[i]);
                else if (col.DataType == typeof(Double))
                    val = Convert.ToDouble(keys[i].Replace(".", 
                        System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator));
                else if (col.DataType == typeof(Decimal))
                    val = Convert.ToDecimal(keys[i].Replace(".",
                        System.Globalization.CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator));
                else if (col.DataType == typeof(Int16))
                    val = Convert.ToInt16(keys[i]);
                else if (col.DataType == typeof(Int32))
                    val = Convert.ToInt32(keys[i]);
                else if (col.DataType == typeof(Int64))
                    val = Convert.ToInt64(keys[i]);
                else
                    val = Convert.ToString(keys[i]);

                (cmd.Parameters["@" + col_name] as IDbDataParameter).Value = val;
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// подготовка команды для чтения по идентификатору записи
        /// </summary>
        private IDbCommand CreateReadRowCommand(SyncTable st)
        {
            IDbCommand result = CreateCommand();
            StringBuilder sb = new StringBuilder();
            sb.AppendFormat("select * from {0} where ", st.TableName);
            for (int i = 0; i < st.KeyColumns.Count; i++)
            {
                if (i > 0)
                    sb.Append(" and ");
                sb.AppendFormat("{0} = @{0}", st.KeyColumns[i]);
            }

            result.CommandText = sb.ToString();

            foreach (string key_col in st.KeyColumns)
            {
                IDbDataParameter p = result.CreateParameter();
                p.Direction = ParameterDirection.Input;
                p.ParameterName = "@" + key_col;
                result.Parameters.Add(p);
            }
          
            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// подтверждение реплики
        /// </summary>
        /// <param name="replica"></param>
        public void SourceCommitReplica(SyncLogReplicaInfo replica)
        {
            if (log.IsDebugEnabled) log.Debug("SourceCommitReplica:begin");

            using (IDbCommand cmd = CreateCommand())
            {
                _Transaction.Commit();
                _Transaction = vendor.StartTransaction(Connection, true);
                cmd.CommandText = "SP_SYNC_LOG_COMMIT";
                cmd.Transaction = _Transaction;
                cmd.CommandType = CommandType.StoredProcedure;
                AddParameter(cmd, "@LINK_ID", DbType.Int32, replica.Link.Id);
                AddParameter(cmd, "@LOG_POSITION", DbType.Int64, replica.MaxLogId);
                cmd.ExecuteNonQuery();
                log.InfoFormat("Выполнено подтверждение реплики на позиции журнала - {0}", replica.MaxLogId);
                _Transaction.Commit();
                _Transaction = vendor.StartTransaction(Connection, false);
            }

            if (log.IsDebugEnabled) log.Debug("SourceCommitReplica:end");
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        /// <summary>
        /// обработка реплики
        /// </summary>
        /// <param name="replica"></param>
        public SyncReplicaProcessResult TargetProcessReplica(SyncLogReplica replica, TargetProcessOptions Options)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessReplica:begin"));

            _ProcessResult = new SyncReplicaProcessResult();

            TargetProcessFillColumns(replica.Tables);

            vendor.UpgradeAndDisableTriggers(this, replica.Tables);

            _TargetProcessResult = new SyncReplicaProcessResult();

            // подготавливаем список таблиц для обработки
            SyncTableList tables = SortTableList(replica.Tables, true);

            log.InfoFormat(FMsg("Обрабатываются изменения для {0} таблиц"), replica.Tables.Count);
            log.InfoFormat(FMsg("Общее количество изменений: {0}"), replica.LogItems.Count);

            // обрабатываем удаления, но ошибки пока пропускаем
            TargetProcessDeletes(replica, false);

            // по каждой табличке идем и обрабатываем данные из пакета
            _SecondStage = false;
            _SecondStageTables = new SyncTableList();
            
            foreach (SyncTable table in tables)
            {
                TargetProcessSyncTable(table, replica);
            }

            // второй проход - для взаимно связанных таблиц
            _SecondStage = true;

            foreach (SyncTable table in _SecondStageTables)
            {
                TargetProcessSyncTable(table, replica);
            }
            

            // обрабатываем удаления, и ошибки уже не пропускаем
            TargetProcessDeletes(replica, true);
            
            // копирование журнала
            TargetCopyJournal(replica);

            log.InfoFormat(FMsg("Обработка реплики завершена."));

            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessReplica:end"));

            if (_TargetProcessResult.Errors.Count > 0)
                _TargetProcessResult.Code = SyncReplicaProcessResultCode.WithErrors;
            else
                _TargetProcessResult.Code = SyncReplicaProcessResultCode.OK;

            return _TargetProcessResult;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void TargetProcessDeletes(SyncLogReplica replica, bool process_errors)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessDeletes:begin"));

            try
            {
                int count_deleted = 0;
                foreach (SyncLogItem log_item in replica.LogItems)
                    if (log_item.ActionMode == Const.ActionMode_Deleted)
                        count_deleted++;

                vendor.StartSession(this, SessionMode.Write);

                if (count_deleted > 0)
                {
                    log.InfoFormat("Обработка удаленных записей, кол-во - {0}", count_deleted);

                    SyncTableList table_list = new SyncTableList();

                    // составляем список таблиц для обработки
                    foreach (SyncLogItem log_item in replica.LogItems)
                        if (log_item.ActionMode == Const.ActionMode_Deleted)
                        {
                            SyncTable table = replica.Tables[log_item.TableName];
                            if (!table_list.Contains(table))
                                table_list.Add(table);
                        }
                    table_list = SortTableList(table_list, false, false);

                    foreach (SyncTable table in table_list)
                    {
                        IDbCommand cmd = CreateDeleteCommand(replica, table);

                        foreach (SyncLogItem log_item in replica.LogItems)
                            if ((log_item.ActionMode == Const.ActionMode_Deleted) &&
                                (log_item.TableName == table.TableName))
                            {

                                object[] key_vals = Func.GetRowIdValues(log_item.RowId);
                                for (int i = 0; i < table.KeyColumns.Count; i++)
                                {
                                    (cmd.Parameters[i] as IDbDataParameter).Value = key_vals[i];
                                }
                                try
                                {
                                    cmd.ExecuteNonQuery();
                                }
                                catch (Exception ex)
                                {
                                    if (process_errors)
                                        ProcessApplyUpdatesError(ex, log_item, null);
                                }
                            }
                    }
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            if (log.IsDebugEnabled) log.Debug(FMsg("TargetProcessDeletes:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private IDbCommand CreateDeleteCommand(SyncLogReplica replica, SyncTable table)
        {
            IDbCommand result = CreateCommand();
            StringBuilder sb = new StringBuilder(100);
            sb.Append("DELETE FROM ");
            sb.Append(table.TableName);
            sb.Append(" WHERE ");
            int cc = 0;
            foreach (string key_col in table.KeyColumns)
            {
                if (cc++ > 0)
                    sb.Append(" and ");
                sb.AppendFormat("({0} = @{0})", key_col);
            }
            result.CommandText = sb.ToString();
            foreach (string key_col in table.KeyColumns)
            {
                IDbDataParameter param = result.CreateParameter();
                param.DbType = Func.TypeToDbType(replica.DataSet.Tables[table.TableName].Columns[key_col].DataType);
                param.Direction = ParameterDirection.Input;
                param.ParameterName = "@" + key_col;
                result.Parameters.Add(param);
            }
            return result;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void TargetCopyJournal(SyncLogReplica replica)
        {
            if (log.IsDebugEnabled) log.Debug(FMsg("TargetCopyJournal:begin"));

            log.InfoFormat(FMsg("Производится копирование журнала изменений ({0} записей)..."), replica.LogItems.Count);
            using  (IDbCommand cmd = CreateCommand())
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.CommandText = "SP_SYNC_LOG_WRITE_COPY";
                AddParameter(cmd, "@ORIG_LOG_ID", DbType.Int64, DBNull.Value);
                AddParameter(cmd, "@TABLE_NAME", DbType.String, DBNull.Value);
                AddParameter(cmd, "@ROW_ID", DbType.String, DBNull.Value);
                AddParameter(cmd, "@LOG_MODE", DbType.String, DBNull.Value);
                AddParameter(cmd, "@PARTICIPANT_ID", DbType.Int32, DBNull.Value);
                AddParameter(cmd, "@UPDATE_COUNT", DbType.Int32, DBNull.Value);
                AddParameter(cmd, "@TM_INSERTED", DbType.DateTime, DBNull.Value);
                AddParameter(cmd, "@TM_UPDATED", DbType.DateTime, DBNull.Value);
                AddParameter(cmd, "@USER_INSERTED", DbType.String, DBNull.Value);
                AddParameter(cmd, "@USER_UPDATED", DbType.String, DBNull.Value);
                AddParameter(cmd, "@LAST_CONTEXT_CLIENT_ADDRESS", DbType.String, DBNull.Value);
                AddParameter(cmd, "@LAST_CONTEXT_SESSION_ID", DbType.Int32, DBNull.Value);
                AddParameter(cmd, "@LAST_CONTEXT_TRANSACTION_ID", DbType.Int32, DBNull.Value);
                AddParameter(cmd, "@PREV_ROW_ID", DbType.String, DBNull.Value);

                foreach (SyncLogItem log_item in replica.LogItems)
                    if (log_item.TableName != "SYNC_LOG")
                    {
                        ((IDbDataParameter)cmd.Parameters["@ORIG_LOG_ID"]).Value = log_item.Id;
                        ((IDbDataParameter)cmd.Parameters["@TABLE_NAME"]).Value = log_item.TableName;
                        ((IDbDataParameter)cmd.Parameters["@ROW_ID"]).Value = log_item.RowId;
                        ((IDbDataParameter)cmd.Parameters["@LOG_MODE"]).Value = log_item.ActionMode;
                        ((IDbDataParameter)cmd.Parameters["@PARTICIPANT_ID"]).Value = replica.Info.Link.ParticipantFrom.Id;
                        ((IDbDataParameter)cmd.Parameters["@UPDATE_COUNT"]).Value = log_item.UpdateCount;
                        ((IDbDataParameter)cmd.Parameters["@TM_INSERTED"]).Value = log_item.TimeInserted;
                        ((IDbDataParameter)cmd.Parameters["@TM_UPDATED"]).Value = log_item.TimeUpdated;
                        ((IDbDataParameter)cmd.Parameters["@USER_INSERTED"]).Value = log_item.UserInserted;
                        ((IDbDataParameter)cmd.Parameters["@USER_UPDATED"]).Value = log_item.UserUpdated;
                        ((IDbDataParameter)cmd.Parameters["@LAST_CONTEXT_CLIENT_ADDRESS"]).Value = log_item.LastContextClientAddress;
                        ((IDbDataParameter)cmd.Parameters["@LAST_CONTEXT_SESSION_ID"]).Value = log_item.LastContextSessionId;
                        ((IDbDataParameter)cmd.Parameters["@LAST_CONTEXT_TRANSACTION_ID"]).Value = log_item.LastContextTransactionId;
                        ((IDbDataParameter)cmd.Parameters["@PREV_ROW_ID"]).Value = log_item.PrevRowId;
                        try
                        {
                            cmd.ExecuteNonQuery();
                        }
                        catch (Exception ex)
                        {
                            throw ex;
                        }
                    }
            }
            
            log.InfoFormat(FMsg("Закончено копирование журнала изменений. Скопировано {0} записей."), replica.LogItems.Count);

            if (log.IsDebugEnabled) log.Debug(FMsg("TargetCopyJournal:end"));
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private IDbCommand cmdApplyUpdates;

        private void TargetProcessSyncTable(SyncTable table, SyncLogReplica replica)
        {
            if (log.IsDebugEnabled) log.DebugFormat(FMsg("TargetProcessReplica:begin ({0})"), table.TableName);

            DataTable dataTable = replica.DataSet.Tables[table.TableName];

            if (dataTable == null)
                return;

            List<string> excludeFields = new List<string>();

            // проверка по списку взаимных ссылок
            if (!_SecondStage)
            {
                foreach (SyncTableRelation rel in _CrossLinks)
                    if (rel.ChildTable == table.TableName && rel.ChildNullable)
                    {
                        foreach (string col_n in rel.ChildColumns)
                            excludeFields.Add(col_n);
                        _SecondStageTables.Add(table);
                    }
            }            

            cmdApplyUpdates = vendor.CreateSpecialCommand(this,
                SyncDatabaseVendorCommandMode.UpdateOrInsertTable, table, dataTable, excludeFields);
            try
            {
                if (dataTable.Rows.Count > 0)
                {
                    log.InfoFormat(FMsg("Обрабатывается таблица {0} (кол-во записей - {1})"),
                        table.TableName, dataTable.Rows.Count);

                    int count = 0;

                    // идем по всем указателям изменений в данной реплике по указанной таблице
                    foreach (SyncLogItem logItem in replica.LogItems)
                        if (logItem.TableName == table.TableName && logItem.ActionMode != Const.ActionMode_Deleted)
                        {
                            ApplyUpdate(logItem, table, dataTable);
                            count++;
                        }
                    log.InfoFormat(FMsg("  закончена обработка таблицы {0} (кол-во записей - {1})"),
                        table.TableName, count);
                }
            }
            finally
            {
                vendor.CleanSpecialCommand(this, SyncDatabaseVendorCommandMode.UpdateOrInsertTable);
            }

            if (log.IsDebugEnabled) log.DebugFormat(FMsg("TargetProcessReplica:end ({0})"), table.TableName);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void ApplyUpdate(SyncLogItem logItem, SyncTable table, DataTable dataTable)
        {
            // идем по запомненным индексам данных и достаем оттуда данные
            try
            {
                if (logItem.ReplicaRowIndexes != null)
                {
                    foreach (int rowIndex in logItem.ReplicaRowIndexes)
                    {
                        DataRow row = dataTable.Rows[rowIndex];

                        foreach (IDbDataParameter param in cmdApplyUpdates.Parameters)
                            param.Value = DBNull.Value;

                        foreach (DataColumn col in dataTable.Columns)
                            if (col.ColumnName != Const.Field_LOG_ID)
                            {
                                IDbDataParameter param = cmdApplyUpdates.Parameters[
                                    vendor.GetParameterPrefix() + col.ColumnName] as IDbDataParameter;
                                if (param == null)
                                    throw new InvalidOperationException(string.Format(
                                        "Не найден параметр {0} в запросе обновления!", col.ColumnName));
                                if (!row.IsNull(col))
                                    param.Value = row[col];
                            }

                        object[] key_values = Func.GetRowIdValues(logItem.RowId);
                        if (!string.IsNullOrEmpty(logItem.PrevRowId))
                            key_values = Func.GetRowIdValues(logItem.PrevRowId);

                        for (int i = 0; i < table.KeyColumns.Count; i++)
                        {
                            string pk_col_name = table.KeyColumns[i];
                            string par_name = vendor.GetParameterPrefix() + "PK_" + pk_col_name;
                            IDbDataParameter param = cmdApplyUpdates.Parameters[par_name] as IDbDataParameter;
                            if (param == null)
                                throw new InvalidOperationException(string.Format(
                                    "Не найден параметр {0} в запросе обновления!", par_name));
                            param.Value = key_values[i];
                        }

                        try
                        {
                            object result = cmdApplyUpdates.ExecuteScalar();

                            if (result == null)
                                throw new SyncDatabaseException("команда обновления возвратила NULL");
                            uint RowsAffected = Convert.ToUInt32(result);
                            if (RowsAffected == 0)
                                throw new SyncDatabaseException("команда обновления возвратила 0 добавленных/измененных записей");
                            if (RowsAffected > 1)
                                throw new SyncDatabaseException("команда обновления возвратила более одной добавленных/измененных записей");
                        }
                        catch (Exception ex)
                        {
                            ProcessApplyUpdatesError(ex, logItem, row);
                        }
                    }
                }
                else
                {
                    log.WarnFormat("невозможно применить изменение ({0}) - нет связанных данных", logItem);
                }
            }
            catch
            {
                throw;
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private void ProcessApplyUpdatesError(Exception ex, SyncLogItem logItem, DataRow row)
        {
            log.Error(string.Format("Ошибка при внесении изменений:\r\n{0}\r\nЗапись в журнале: ID={1}; ROW_ID={2}", 
                ex.Message, logItem.Id, logItem.RowId));
            
            SyncReplicaProcessError error = new SyncReplicaProcessError();
            error.Index = Convert.ToUInt32(_TargetProcessResult.Errors.Count);
            error.KeyValues = Func.GetRowIdValues(logItem.RowId);
            error.Message = ex.Message;
            error.TableName = logItem.TableName;
            if (row != null)
                error.DataValues = row.ItemArray;
            _TargetProcessResult.Errors.Add(error);

            if (_TargetProcessResult.Errors.Count >= Properties.Settings.Default.MaxErrors)
            {
                throw new InvalidOperationException(string.Format(
                    "Количество ошибок при обработке достигло максимального значения ({0}) - импорт прерван!",
                    Properties.Settings.Default.MaxErrors));
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


        #region ISyncDatabase Members

        public void Connect()
        {
            EnsureConnectionIsOpen();
        }

        public void Disconnect()
        {
            if (Connection.State != ConnectionState.Closed)
            {
                log.Info(FMsg("закрывается соединение с БД"));
                Connection.Close();
            }
        }

        #endregion

        #region ISyncDatabase Members


        public void SetLoggerName(string loggerName)
        {
            log = LogManager.GetLogger(loggerName);
        }

        #endregion


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

        public string GetLogMessages()
        {
            return logMessages != null ? logMessages.ToString() : "";
        }

        public void WriteSyncJournal(SyncJournalInfo Info)
        {
            Vendor.WriteSyncJournal(this, Info);
        }
    }

    public class SyncDatabaseException : Exception
    {
        public SyncDatabaseException(string msg) : base(msg)
        {

        }
    }
}
