using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using FirebirdSql.Data.FirebirdClient;
using SB.Sync.Classes;

namespace SB.Sync.Classes
{
    internal class FbSyncDatabaseVendor : SyncDatabaseVendor
    {
        public override Type ConnectionType
        {
            get { return typeof(FbConnection); }
        }

        public override System.Data.IDataAdapter CreateDataAdater(System.Data.IDbCommand command)
        {
            return new FbDataAdapter(command as FbCommand);
        }

        public override SyncTableRelationList GetRelationsForTables(SyncTableList list, SyncDatabase db)
        {
            string sql = @"select rc.rdb$constraint_name constraint_name, rc.rdb$relation_name child_table,
rc2.rdb$relation_name parent_table,
sg.rdb$field_name child_column, sg2.rdb$field_name parent_column
from rdb$relation_constraints rc
 left join rdb$ref_constraints rr on rr.rdb$constraint_name = rc.rdb$constraint_name
 left join rdb$relation_constraints rc2 on rc2.rdb$constraint_name = rr.rdb$const_name_uq
 left join rdb$index_segments sg on sg.rdb$index_name = rc.rdb$index_name
 left join rdb$index_segments sg2 on sg2.rdb$index_name = rc2.rdb$index_name
where rc.rdb$constraint_type = 'FOREIGN KEY'

union all

select '', table_child, table_parent, '', ''
from sync_table_dep
";

            SyncTableRelationList result = new SyncTableRelationList();

            using (FbCommand cmd = db.CreateCommand() as FbCommand)
            {
                cmd.CommandText = sql;
                using (IDataReader reader = cmd.ExecuteReader())
                while (reader.Read())
                {
                    SyncTableRelation rel = new SyncTableRelation();
                    rel.ParentTable = reader["PARENT_TABLE"].ToString().Trim();
                    rel.ChildTable = reader["CHILD_TABLE"].ToString().Trim();
                    rel.ParentColumns = new string [] { reader["PARENT_COLUMN"].ToString().Trim() };
                    rel.ChildColumns = new string[] { reader["CHILD_COLUMN"].ToString().Trim() };
                    result.Add(rel);
                }
            }

            return result;
        }

        public override IDbTransaction StartTransaction(IDbConnection Connection, bool serializable)
        {
            FbTransactionOptions opt = new FbTransactionOptions();
            opt.TransactionBehavior = FbTransactionBehavior.NoWait;
            if (serializable)
            {
                return ((FbConnection)Connection).BeginTransaction(opt);
            }
            else
                return ((FbConnection)Connection).BeginTransaction(opt);
        }

        public override void FillTableColumnsList(SyncDatabase db, string TableName, SyncTable table)
        {
            using (IDbCommand cmd = db.CreateCommand())
            {
                table.Columns.Clear();
                table.KeyColumns.Clear();

                cmd.CommandText = string.Format("select first 0 * from {0}", TableName);
                using (IDataReader reader = cmd.ExecuteReader())
                {
                    DataTable schemaTable = reader.GetSchemaTable();
                    foreach (DataRow row in schemaTable.Rows)
                    {
                        DataColumn col = new DataColumn();
                        col.AllowDBNull = Convert.ToBoolean(row["AllowDBNull"]);
                        col.ColumnName = Convert.ToString(row["ColumnName"]);
                        col.DataType = (row["DataType"] as Type);
                        col.ReadOnly = Convert.ToBoolean(row["IsReadOnly"]);
                        table.Columns.Add(col);

                        if (Convert.ToBoolean(row["IsKey"]))
                            table.KeyColumns.Add(col.ColumnName);
                    }
                }

                if (table.KeyColumns.Count > 1)
                    using (FbCommand cmd_key = db.CreateCommand() as FbCommand)
                    {
                        // если несколько полей в ключе, то перезапрашиваем, чтобы уточнить порядок следования полей

                        cmd_key.CommandText = @"select rdb$field_name
from rdb$relation_constraints c
 left join rdb$index_segments i on i.rdb$index_name = c.rdb$index_name
where rdb$constraint_type = 'PRIMARY KEY' and rdb$relation_name = @tablename
order by rdb$field_position";

                        cmd_key.Parameters.Add("@tablename", FbDbType.VarChar).Value = TableName.ToUpper();
                        table.KeyColumns.Clear();
                        using (IDataReader reader_key = cmd_key.ExecuteReader())
                            while (reader_key.Read())
                            {
                                table.KeyColumns.Add(reader_key[0].ToString().Trim());
                            }
                    }
            }
        }

        public override string GetParameterPrefix()
        {
            return "@";
        }

        public override IDbCommand CreateSpecialCommand(SyncDatabase db, SyncDatabaseVendorCommandMode mode, params object[] args)
        {
            if (mode == SyncDatabaseVendorCommandMode.UpdateOrInsertTable)
            {
                return GetInsertOrUpdateCommand2(db, args[0] as SyncTable, args[1] as DataTable, args[2] as List<string>);
            }
            return null;
        }

        // - - - - - - - - - - - - - - - - - - - - 

        private FbCommand GetInsertOrUpdateCommand(SyncDatabase db, SyncTable syncTable, DataTable dataTable, List<string> excludeFields)
        {
            FbCommand cmd = db.CreateCommand() as FbCommand;

            CreateInsertOrUpdateStoredProc(db, syncTable, dataTable, excludeFields);

            
            StringBuilder sb = new StringBuilder(string.Format("select rows_affected from {0}(", get_sp_name()));
            int cc = 0;
            foreach (DataColumn col in syncTable.Columns)
                if (col.ColumnName != Const.Field_LOG_ID)
                {
                    if (cc++ > 0)
                        sb.Append(",");

                    sb.Append("@");
                    sb.Append(col.ColumnName);
                }

            foreach (string key_col in syncTable.KeyColumns)
            {
                if (cc++ > 0)
                    sb.Append(",");

                sb.Append("@");
                sb.Append(key_col);
            }

            sb.Append(");");

            cmd.CommandText = sb.ToString();

            foreach (DataColumn col in syncTable.Columns)
            {
                if (col.ColumnName != Const.Field_LOG_ID)
                    CreateParameter(cmd, col, col.ColumnName);
            }

            foreach (string key_col in syncTable.KeyColumns)
            {
                DataColumn col = dataTable.Columns[key_col];
                if (col.ColumnName != Const.Field_LOG_ID)
                    CreateParameter(cmd, col, "PK_" + col.ColumnName);
            }

            return cmd;
        }

        private string get_sp_name()
        {
            return sp_name_const + "_" + System.Threading.Thread.CurrentThread.ManagedThreadId.ToString();
        }

        private static void CreateParameter(FbCommand cmd, DataColumn col, string par_name)
        {
            FbParameter par = cmd.CreateParameter() as FbParameter;
            par.ParameterName = "@" + par_name;
            par.DbType = Func.TypeToDbType(col.DataType);
            par.Direction = ParameterDirection.Input;
            par.IsNullable = col.AllowDBNull;
            cmd.Parameters.Add(par);
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        private const string sp_name_const = "sp_sync__temp_upd";

        private void CreateInsertOrUpdateStoredProc(SyncDatabase db, SyncTable syncTable, DataTable dataTable, List<string> excludeFields)
        {
            CleanSpecialCommand(db, SyncDatabaseVendorCommandMode.UpdateOrInsertTable);

            try
            {
                StringBuilder sb = new StringBuilder(100);
                string cmd_proc = "create";
                if (IsProcExists(get_sp_name(), db))
                    cmd_proc = "alter";

                sb.AppendLine(string.Format(cmd_proc + " procedure {0}", get_sp_name()));
                sb.AppendLine("(" + GetColumnsInfo(db, syncTable.TableName, syncTable) + ")");
                sb.AppendLine("returns (rows_affected integer)");
                sb.AppendLine("as");
                sb.AppendLine("begin");

                sb.AppendFormat("  update {0} set ", syncTable.TableName);

                int col_count = 0;

                foreach (DataColumn col in syncTable.Columns)
                    if ((col.ColumnName != Const.Field_LOG_ID) &&
                        (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                    {
                        if (col_count++ > 0)
                            sb.Append(", ");
                        sb.Append(col.ColumnName);
                        sb.Append("=:");
                        sb.Append(col.ColumnName);
                    }

                sb.AppendFormat(" where ");
                int cc = 0;
                foreach (string key_col in syncTable.KeyColumns)
                {
                    if (cc++ > 0)
                        sb.Append(" and ");
                    sb.AppendFormat("({0} = :PK_{0} or {0} = :{0})", key_col);
                }

                sb.AppendLine(";");

                // - - - -

                sb.AppendLine("  if (row_count = 0) then");
                sb.AppendFormat("  insert into {0} (", syncTable.TableName);

                col_count = 0;

                foreach (DataColumn col in syncTable.Columns)
                    if (col.ColumnName != Const.Field_LOG_ID && (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                    {
                        if (col_count++ > 0)
                            sb.Append(", ");
                        sb.Append(col.ColumnName);
                    }

                sb.Append(") values (");

                col_count = 0;

                foreach (DataColumn col in syncTable.Columns)
                    if (col.ColumnName != Const.Field_LOG_ID && (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                    {
                        if (col_count++ > 0)
                            sb.Append(", ");
                        sb.Append(":");
                        sb.Append(col.ColumnName);
                    }

                sb.AppendLine(");");
                sb.AppendLine(" rows_affected = row_count;");
                sb.AppendLine(" suspend;");
                sb.AppendLine("end");

                // используем отдельное соединение
                /*using (FbConnection conn = new FbConnection(db.Connection.ConnectionString))
                {
                    conn.Open();
                    using (FbTransaction trans = conn.BeginTransaction(FbTransactionOptions.NoWait))
                    using (FbCommand cmd_sp = new FbCommand(sb.ToString(), conn, trans))
                    {
                        cmd_sp.ExecuteNonQuery();
                        trans.Commit();
                    }
                    conn.Close();
                }*/

                // 14.04.2008 обновление генератора RDB$PROCEDURES

                using (IDbCommand cmd = db.CreateCommand())
                {
                    cmd.CommandText = sb.ToString();
                    try
                    {
                        cmd.ExecuteNonQuery();
                    }
                    catch (FirebirdSql.Data.FirebirdClient.FbException ex)
                    {
                        if (ex.Message.Contains("arithmetic"))
                        {
                            TryFixRdbProcGen(db);
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch
            {
                CleanSpecialCommand(db, SyncDatabaseVendorCommandMode.UpdateOrInsertTable);
                throw;
            }

        }

        private void TryFixRdbProcGen(SyncDatabase db)
        {           
                string sql = @"select
gen_id(rdb$procedures,
 (select max(rdb$procedure_id) + 1000 from rdb$procedures) -
 (gen_id(rdb$procedures, 0)))
from rdb$database";

                using (IDbCommand cmd = db.CreateCommand())
                {
                    cmd.CommandText = sql;
                    cmd.ExecuteNonQuery();
                }
        }

        private bool IsProcExists(string proc_name, SyncDatabase db)
        {
            using (FbCommand cmd = db.CreateCommand() as FbCommand)
            {
                cmd.CommandText = "select count(*) from rdb$procedures where rdb$procedure_name = @name";
                cmd.Parameters.Add("@name", FbDbType.VarChar).Value = proc_name.ToUpper();
                return (Convert.ToInt32(cmd.ExecuteScalar()) > 0);
            }
        }

        private bool IsTableExists(string proc_name, SyncDatabase db)
        {
            using (FbCommand cmd = db.CreateCommand() as FbCommand)
            {
                cmd.CommandText = "select count(*) from rdb$relations where rdb$relation_name = @name";
                cmd.Parameters.Add("@name", FbDbType.VarChar).Value = proc_name.ToUpper();
                return (Convert.ToInt32(cmd.ExecuteScalar()) > 0);
            }
        }

        private string GetColumnsInfo(SyncDatabase db, string table_name, SyncTable table)
        {
            string sql =
@"select rtrim(rf.rdb$field_name),
CASE rtrim(t.rdb$type_name)
   WHEN 'LONG' THEN 'INTEGER'
   WHEN 'VARYING' THEN 'VARCHAR'
   WHEN 'DOUBLE' THEN 'DOUBLE PRECISION'
   WHEN 'SHORT' THEN 'SMALLINT'
   WHEN 'TEXT' THEN 'CHAR'
   WHEN 'INT64' THEN iif(f.rdb$field_scale = 0, 'BIgINt', 'NUMERIC(' || cast(f.rdb$field_precision  as varchar(10)) || ',' || cast(-f.rdb$field_scale as varchar(10)) || ')')
   ELSE rtrim(t.rdb$type_name)
END ||
iif(rtrim(t.rdb$type_name) = 'VARYING', '(' || f.rdb$field_length || ')', '') ||
iif(rtrim(t.rdb$type_name) = 'TEXT', '(' || f.rdb$field_length || ')', '') ||
iif(rtrim(t.rdb$type_name) = 'BLOB',
 iif(f.rdb$field_sub_type is not null, ' SUB_TYPE ' || f.rdb$field_sub_type, '') ||
 iif(f.rdb$segment_length is not null,' SEGMENT SIZE ' || f.rdb$segment_length, ''), '')
type_name
from rdb$relation_fields rf
 left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
 left join rdb$types t on t.rdb$type = f.rdb$field_type and t.rdb$field_name = 'RDB$FIELD_TYPE'
where rf.rdb$relation_name = upper(@table_name)
order by rdb$field_position";

            StringBuilder sb = new StringBuilder(1024);
            StringBuilder sb_key = new StringBuilder(100);

            FbCommand cmd = db.CreateCommand() as FbCommand;
            cmd.CommandText = sql;
            cmd.Parameters.Add("@table_name", FbDbType.VarChar).Value = table_name;
            using (FbDataReader reader = cmd.ExecuteReader())
            while (reader.Read())
            {
                if (sb.Length > 0)
                    sb.Append(", ");
                string col_name = reader[0].ToString();
                string col_type = reader[1].ToString();
                if (table.KeyColumns.Contains(col_name))
                {
                    if (sb_key.Length > 0)
                        sb_key.Append(", ");
                    sb_key.AppendFormat("PK_{0} {1}", col_name, col_type);
                }
                sb.AppendFormat("{0} {1}", col_name, col_type);
            }

            sb.Append(",");
            sb.Append(sb_key.ToString());

            return sb.ToString();
        }

        public override void CleanSpecialCommand(SyncDatabase db, SyncDatabaseVendorCommandMode mode)
        {
            /*if (mode == SyncDatabaseVendorCommandMode.UpdateOrInsertTable)            
            {
                try
                {
                    using (IDbCommand cmd_sp = db.CreateCommand())
                    {
                        cmd_sp.CommandText = string.Format("drop procedure {0}", get_sp_name());
                        cmd_sp.ExecuteNonQuery();
                    }
                }
                catch (FbException ex)
                {
                    if (!ex.Message.Contains("not found"))
                        throw;
                }

            }*/
        }

        public override void StartSession(SyncDatabase db, SessionMode Mode)
        {
            ExecSql(db, "select rdb$set_context('USER_TRANSACTION', 'SYNC_RECV', '1') from rdb$database");

            if (Mode == SessionMode.Write)
            {
                using (IDbCommand cmd = db.CreateCommand())
                {
                    cmd.CommandText = "select rdb$set_context('USER_TRANSACTION', 'SYNC_LOG_DISABLED', '1') from rdb$database";
                    cmd.ExecuteNonQuery();
                }
                ExecSql(db, "select rdb$set_context('USER_TRANSACTION', 'TRG_DISABLE', '1') from rdb$database");
            }
        }


        private void UpgradeTriggers(SyncDatabase db, SyncTableList tables)
        {
            db.Log.Debug(db.FMsg("Выполняется обновление текста триггеров..."));

            StringBuilder sb = new StringBuilder(100);
            foreach (SyncTable t in tables)
            {
                if (sb.Length > 0)
                    sb.Append(",");
                sb.Append("'");
                sb.Append(t.TableName);
                sb.Append("'");
            }

            if (sb.Length == 0)
                return;

            string triggers_disable_hook = "/*TRG_DIS*/if (rdb$get_context('USER_TRANSACTION', 'TRG_DISABLE') is not null) then exit;";

            // для триггеров архивации другая строчка (их не отключаем
            string triggers_disable_hook_arc = "/*TRG_DIS*/if (rdb$get_context('USER_TRANSACTION', 'TRG_DISABLE_ARC') is not null) then exit;";

            string sql = string.Format(@"select * from rdb$triggers
where rdb$system_flag = 0 and rdb$trigger_name not like 'CHECK%' and rdb$relation_name <> 'SYNC_LOG' and 
rdb$relation_name in ('', {0})", sb.ToString());
            FbTransaction trg_trans = db.Transaction as FbTransaction;
                //(db.Connection as FbConnection).BeginTransaction(FbTransactionOptions.NoWait | FbTransactionOptions.ReadCommitted);
            using (FbCommand cmd = new FbCommand(string.Empty, db.Connection as FbConnection, trg_trans))
            {
                cmd.CommandText = sql;
                using (FbDataReader reader = cmd.ExecuteReader())
                    while (reader.Read())
                    {
                        string trigger_name = reader["RDB$TRIGGER_NAME"].ToString().Trim();
                        string trigger_source = reader["RDB$TRIGGER_SOURCE"].ToString().Trim();
                        string l_trigger_source = trigger_source.ToLower();

                        string trg_hook = triggers_disable_hook;
                        if (trigger_name.StartsWith("T_SYNC$"))
                            trg_hook = triggers_disable_hook_arc;

                        // закладка для кредитного клиента
                        if ((db.Connection as FbConnection).ConnectionString.ToLower().Contains("kredclient") && 
                            trigger_source.ToLower().Contains("sp_write_log"))
                            trg_hook = triggers_disable_hook_arc;

                        if (!l_trigger_source.Contains(trg_hook.ToLower()))
                        {
                            int pos_begin = l_trigger_source.IndexOf("begin");
                            if (pos_begin >= 0)
                            {
                                trigger_source = trigger_source.Insert(pos_begin + 5, "\r\n" + trg_hook);

                                if ((trg_hook == triggers_disable_hook_arc) && trigger_source.Contains(triggers_disable_hook))
                                    trigger_source = trigger_source.Replace(triggers_disable_hook, string.Empty);

                                using (FbCommand cmd_alter = db.CreateCommand() as FbCommand)
                                {
                                    cmd_alter.CommandText = string.Format("ALTER TRIGGER {0}\r\n{1}",
                                        trigger_name, trigger_source);
                                    try
                                    {
                                        cmd_alter.ExecuteNonQuery();
                                        trg_trans.CommitRetaining();
                                    }
                                    catch (Exception ex)
                                    {
                                        trg_trans.RollbackRetaining();
                                        db.Log.Warn(string.Format(db.FMsg("Ошибка при обновлении текста триггера ({0}):  {1}"),
                                            trigger_name, ex.Message));
                                    }
                                }
                            }
                        }
                    }
                trg_trans.CommitRetaining();
            }

            db.Log.Debug(db.FMsg("Обновление текста триггеров выполнено."));
        }

        private static void ExecSql(SyncDatabase db, string sql)
        {
            using (IDbCommand cmd = db.CreateCommand())
            {
                cmd.CommandText = sql;
                object o = cmd.ExecuteScalar();
            }
        }

        public override void UpgradeAndDisableTriggers(SyncDatabase db, SyncTableList tables)
        {
            UpgradeTriggers(db, tables);
            ExecSql(db, "select rdb$set_context('USER_TRANSACTION', 'TRG_DISABLE', '1') from rdb$database");
        }

        public override void DisableTriggers(SyncDatabase db)
        {
            ExecSql(db, "select rdb$set_context('USER_TRANSACTION', 'TRG_DISABLE', '1') from rdb$database");
        }

        public override List<string> GetKeyColumns(SyncDatabase syncDatabase, string tableName)
        {
            using (FbCommand cmd = syncDatabase.CreateCommand() as FbCommand)
            {
                cmd.CommandText = @"select rtrim(rdb$field_name)
     from rdb$relation_constraints rc
      left join rdb$index_segments i on i.rdb$index_name = rc.rdb$index_name
     where rdb$constraint_type = 'PRIMARY KEY'
     and rc.rdb$relation_name = upper(@table_name)
     order by i.rdb$field_position";
                cmd.Parameters.Add("@table_name", FbDbType.VarChar).Value = tableName;
                List<string>result = new List<string>();
                using (FbDataReader reader = cmd.ExecuteReader())
                while (reader.Read())
                    result.Add(reader[0].ToString());
                return result;
            }
        }


        /// <summary>
        /// новый метод - через EXECUTE BLOCK
        /// </summary>
        /// <param name="db"></param>
        /// <param name="syncTable"></param>
        /// <param name="dataTable"></param>
        /// <param name="excludeFields"></param>
        /// <returns></returns>
        private FbCommand GetInsertOrUpdateCommand2(SyncDatabase db, SyncTable syncTable, DataTable dataTable, List<string> excludeFields)
        {
            FbCommand cmd = db.CreateCommand() as FbCommand;

            // создаем текст запроса
            StringBuilder sb = new StringBuilder(100);

            sb.AppendLine("execute block");
            sb.AppendLine("(" + GetColumnsInfoForExecuteBlock(db, syncTable.TableName, syncTable) + ")");
            sb.AppendLine("returns (rows_affected integer)");
            sb.AppendLine("as");
            sb.AppendLine("begin");

            sb.AppendFormat("  update {0} set ", syncTable.TableName);

            int col_count = 0;

            foreach (DataColumn col in syncTable.Columns)
                if ((col.ColumnName != Const.Field_LOG_ID) &&
                    (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                {
                    if (col_count++ > 0)
                        sb.Append(", ");
                    sb.Append(col.ColumnName);
                    sb.Append("=:");
                    sb.Append(col.ColumnName);
                }

            sb.AppendFormat(" where ");
            int cc = 0;
            foreach (string key_col in syncTable.KeyColumns)
            {
                if (cc++ > 0)
                    sb.Append(" and ");
                sb.AppendFormat("({0} = :PK_{0} or {0} = :{0})", key_col);
            }

            sb.AppendLine(";");

            // - - - -

            sb.AppendLine("  if (row_count = 0) then");
            sb.AppendFormat("  insert into {0} (", syncTable.TableName);

            col_count = 0;

            foreach (DataColumn col in syncTable.Columns)
                if (col.ColumnName != Const.Field_LOG_ID && (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                {
                    if (col_count++ > 0)
                        sb.Append(", ");
                    sb.Append(col.ColumnName);
                }

            sb.Append(") values (");

            col_count = 0;

            foreach (DataColumn col in syncTable.Columns)
                if (col.ColumnName != Const.Field_LOG_ID && (!col.ReadOnly) && (!excludeFields.Contains(col.ColumnName)))
                {
                    if (col_count++ > 0)
                        sb.Append(", ");
                    sb.Append(":");
                    sb.Append(col.ColumnName);
                }

            sb.AppendLine(");");
            sb.AppendLine(" rows_affected = row_count;");
            sb.AppendLine(" suspend;");
            sb.AppendLine("end");

            cmd.CommandText = sb.ToString();

            foreach (DataColumn col in syncTable.Columns)
            {
                if (col.ColumnName != Const.Field_LOG_ID)
                    CreateParameter(cmd, col, col.ColumnName);
            }

            foreach (string key_col in syncTable.KeyColumns)
            {
                DataColumn col = dataTable.Columns[key_col];
                if (col.ColumnName != Const.Field_LOG_ID)
                    CreateParameter(cmd, col, "PK_" + col.ColumnName);
            }

            return cmd;
        }

        private string GetColumnsInfoForExecuteBlock(SyncDatabase db, string table_name, SyncTable table)
        {
            string sql =
@"select rtrim(rf.rdb$field_name),
CASE rtrim(t.rdb$type_name)
   WHEN 'LONG' THEN 'INTEGER'
   WHEN 'VARYING' THEN 'VARCHAR'
   WHEN 'DOUBLE' THEN 'DOUBLE PRECISION'
   WHEN 'SHORT' THEN 'SMALLINT'
   WHEN 'TEXT' THEN 'CHAR'
   WHEN 'INT64' THEN iif(f.rdb$field_scale = 0, 'BIgINt', 'NUMERIC(' || cast(f.rdb$field_precision  as varchar(10)) || ',' || cast(-f.rdb$field_scale as varchar(10)) || ')')
   ELSE rtrim(t.rdb$type_name)
END ||
iif(rtrim(t.rdb$type_name) = 'VARYING', '(' || f.rdb$field_length || ')', '') ||
iif(rtrim(t.rdb$type_name) = 'TEXT', '(' || f.rdb$field_length || ')', '') ||
iif(rtrim(t.rdb$type_name) = 'BLOB',
 iif(f.rdb$field_sub_type is not null, ' SUB_TYPE ' || f.rdb$field_sub_type, '') ||
 iif(f.rdb$segment_length is not null,' SEGMENT SIZE ' || f.rdb$segment_length, ''), '')
type_name
from rdb$relation_fields rf
 left join rdb$fields f on f.rdb$field_name = rf.rdb$field_source
 left join rdb$types t on t.rdb$type = f.rdb$field_type and t.rdb$field_name = 'RDB$FIELD_TYPE'
where rf.rdb$relation_name = upper(@table_name) and f.rdb$computed_blr is null
order by rdb$field_position";

            StringBuilder sb = new StringBuilder(1024);
            StringBuilder sb_key = new StringBuilder(100);

            FbCommand cmd = db.CreateCommand() as FbCommand;
            cmd.CommandText = sql;
            cmd.Parameters.Add("@table_name", FbDbType.VarChar).Value = table_name;
            using (FbDataReader reader = cmd.ExecuteReader())
                while (reader.Read())
                {
                    if (sb.Length > 0)
                        sb.Append(", ");
                    string col_name = reader[0].ToString();
                    string col_type = reader[1].ToString();
                    if (table.KeyColumns.Contains(col_name))
                    {
                        if (sb_key.Length > 0)
                            sb_key.Append(", ");
                        sb_key.AppendFormat("PK_{0} {1} = @PK_{0}", col_name, col_type);
                    }
                    sb.AppendFormat("{0} {1} = @{0}", col_name, col_type);
                }

            sb.Append(",");
            sb.Append(sb_key.ToString());

            return sb.ToString();
        }

        public override void WriteSyncJournal(SyncDatabase db, SyncJournalInfo JournalInfo)
        {
            if (IsTableExists("SYNC_JNL", db) && (JournalInfo.LocalReplicaCount > 1 || JournalInfo.RemoteReplicaCount > 1))
            {
                string sql = @"INSERT INTO SYNC_JNL (DAT, LOCAL_LINK_ID, REMOTE_LINK_ID, TIME_START, TIME_END, LOGTEXT, SUCCESS, LOCAL_REPLICA_COUNT, REMOTE_REPLICA_COUNT) 
VALUES (@DAT, @LOCAL_LINK_ID, @REMOTE_LINK_ID, @TIME_START, @TIME_END, @LOGTEXT, @SUCCESS,  @LOCAL_REPLICA_COUNT, @REMOTE_REPLICA_COUNT)";

                FbCommand cmd = db.CreateCommand() as FbCommand;
                cmd.CommandText = sql;
                cmd.Parameters.Add("@DAT", FbDbType.Date).Value = JournalInfo.Date;
                cmd.Parameters.Add("@LOCAL_LINK_ID", FbDbType.Date).Value = JournalInfo.LocalLinkId;
                cmd.Parameters.Add("@REMOTE_LINK_ID", FbDbType.Date).Value = JournalInfo.RemoteLinkId;
                cmd.Parameters.Add("@TIME_START", FbDbType.Date).Value = JournalInfo.TimeStart;
                cmd.Parameters.Add("@TIME_END", FbDbType.Date).Value = JournalInfo.TimeEnd;
                cmd.Parameters.Add("@LOGTEXT", FbDbType.Date).Value = JournalInfo.LogMessages;
                cmd.Parameters.Add("@SUCCESS", FbDbType.SmallInt).Value = JournalInfo.Success ? 1 : 0;
                cmd.Parameters.Add("@LOCAL_REPLICA_COUNT", FbDbType.Integer).Value = JournalInfo.LocalReplicaCount;
                cmd.Parameters.Add("@REMOTE_REPLICA_COUNT", FbDbType.Integer).Value = JournalInfo.RemoteReplicaCount;
                cmd.ExecuteNonQuery();
            }
        }
    }
}
