using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using Microsoft.Synchronization;
using System.Runtime.Serialization;
using System.Reflection;
using log4net;

namespace SB.Sync.Classes
{
    /// <summary>
    /// провайдер синхронизации Sync System for Firebird 2.0 (SSF2)
    /// </summary>
    public class DbSyncProvider : KnowledgeSyncProvider
    {
        #region private data fields

        private SyncDatabase _Db;
        private IDbTransaction _Transaction;
        private string _Name;
        private SyncIdFormatGroup idFormats;
        private SyncLink _Link;
        private int _LinkId;
        private DataTable tableSyncLog;
        
        #endregion

        private ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);

        #region Конструктор
        
        public DbSyncProvider(IDbConnection Connection, string Name)
        {
            log.Debug("ctor");

            this._Db = new SyncDatabase(Connection);
            this._Name = Name;
            
            Configuration.ConflictResolutionPolicy = ConflictResolutionPolicy.SourceWins;

            // установка значений форматов идентификаторов
            idFormats = new SyncIdFormatGroup();

            // для идентификаторов изменений используется BIGINT (2^64)
            IdFormats.ChangeUnitIdFormat.Length = 64;

            // filter-id какие то, пока не знаю что это
            IdFormats.FilterIdFormat.Length = 64;

            // идентификатор элементов
            IdFormats.ItemIdFormat.Length = 256;
            IdFormats.ItemIdFormat.IsVariableLength = true;

            IdFormats.ReplicaIdFormat.Length = 300;
            IdFormats.ReplicaIdFormat.IsVariableLength = true;

            // создание таблицы, которая будет использована для сбора информации о синхронизации
            tableSyncLog = new DataTable();

            log.Debug("ctor finished");
        } 

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        #region свойства
        
        public SyncDatabase Db
        {
            get { return _Db; }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        /// <summary>
        /// информация о соединении
        /// </summary>
        public SyncLink Link
        {
            get { return _Link; }
            set { _Link = value; }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        #endregion
            
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override void BeginSession(SyncSessionContext syncSessionContext)
        {
            Db.BeginSession();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override void EndSession(SyncSessionContext syncSessionContext)
        {
            Db.EndSession();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override ChangeBatch GetChangeBatch(uint batchSize, SyncKnowledge destinationKnowledge, out ForgottenKnowledge forgottenKnowledge, out object changeDataRetriever)
        {
            forgottenKnowledge = null;
            changeDataRetriever = "hello";
            ChangeBatchBuilder cb = new ChangeBatchBuilder(idFormats);
            ItemChange ic = new ItemChange(idFormats, destinationKnowledge.ReplicaId,
                new SyncId("1"), new SyncVersion(0, 0), new SyncVersion(1, 1));
            cb.AddChanges(new ItemChange [] {ic}, destinationKnowledge, false);
            return cb.GetChangeBatch();

        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override ChangeBatch GetFullEnumerationChangeBatch(uint batchSize, SyncId lowerEnumerationBound, SyncKnowledge knowledgeForDataRetrieval, out ForgottenKnowledge forgottenKnowledge, out object changeDataRetriever)
        {
            throw new NotImplementedException();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public int LinkId
        {
            get
            {
                return _LinkId;
            }
            set
            {
                _LinkId = value;
            }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        /// <summary>
        /// получение параметров обмена
        /// </summary>
        /// <param name="batchSize"></param>
        /// <param name="knowledge"></param>
        public override void GetSyncBatchParameters(out uint batchSize, out SyncKnowledge knowledge)
        {
            _Link = SyncLink.GetById(_LinkId, Db);

            if (_Link == null)
                throw new ArgumentException("Не задан идентификатор соединения для синхронизации!");

            Db.FillSyncLogTable(tableSyncLog, Link.Id);

            batchSize = Convert.ToUInt32(tableSyncLog.Rows.Count);
            knowledge = new DbSyncKnowledge(this);


        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override SyncIdFormatGroup IdFormats
        {
            get { return idFormats; }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override string Name
        {
            get { return _Name; }
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override void ProcessChangeBatch(ConflictResolutionPolicy resolutionPolicy, ChangeBatch sourceChanges, ForgottenKnowledge sourceForgottenKnowledge, object changeDataRetriever, SyncCallbacks syncCallback, SyncSessionStatistics sessionStatistics)
        {
            throw new NotImplementedException();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override void ProcessFullEnumerationChangeBatch(ConflictResolutionPolicy resolutionPolicy, SyncId destinationVersionEnumerationRangeLowerBound, SyncId destinationVersionEnumerationRangeUpperBound, ChangeBatch sourceChanges, ForgottenKnowledge sourceForgottenKnowledge, object changeDataRetriever, SyncCallbacks syncCallback, SyncSessionStatistics sessionStatistics)
        {
            throw new NotImplementedException();
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    }

    // ==============================================================================================================

    public class DbSyncKnowledge : SyncKnowledge
    {
        public string Aaa;

        public DbSyncKnowledge(DbSyncProvider provider) : base(provider.IdFormats, 
            new SyncId(GenerateReplicaIdString(provider.Db)), 
            Convert.ToUInt64(DateTime.Now.Ticks))
        {
            Aaa = provider.Name;
        }

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        public override void GetObjectData(SerializationInfo info, StreamingContext context)
        {
            base.GetObjectData(info, context);
        }

        private static string GenerateReplicaIdString(SyncDatabase Connection)
        {
            try
            {
                IDbCommand cmd_gen_replica = Connection.CreateCommand();
                cmd_gen_replica.CommandText = "SP_SYNC_GEN_REPLICA_ID";
                cmd_gen_replica.CommandType = CommandType.StoredProcedure;
                return Convert.ToString(cmd_gen_replica.ExecuteScalar());
            }
            catch (Exception ex)
            {
                throw new InvalidOperationException(
                    string.Format("Невозможно сгенерировать код новой реплики. {0}.", ex.Message), ex);
            }
        }
    }

    // ==============================================================================================================


}
