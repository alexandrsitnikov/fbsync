using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Reflection;
using FirebirdSql.Data.FirebirdClient;
using log4net;

namespace SB.Sync.Classes
{

    // ===============================================================================================

    [Serializable]
    public class SyncParticipant 
    {

        #region приватные поля данных
        
        private int _Id;
        private string _Name;
        private bool _IsDefault;

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - -

        #region свойства
        
        public int Id
        {
            get { return _Id; }
        }

        public string Name
        {
            get { return _Name; }
        }

        public bool IsDefault
        {
            get { return _IsDefault; }
        }

        #endregion        
        
        // - - - - - - - - - - - - - - - - - - - - - - -

        #region логгер

        //[NonSerialized]
        //private ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

        #region конструктор

        public SyncParticipant()
        {
        }

        // - - - - - - - - - - - - - - - - - - - - - - -

        public SyncParticipant(IDataReader reader)
        {
            Fill(reader, null);
        }

        #endregion

        // - - - - - - - - - - - - - - - - - - - - - - -

        public override string ToString()
        {
            return Name;
        }

        // - - - - - - - - - - - - - - - - - - - - - - -

        #region ISyncDataObject Members

        public void Fill(IDataReader reader, IDbConnection connection)
        {
            _Id = Convert.ToInt32(reader["ID"]);
            _Name = Convert.ToString(reader["NAME"]);
            _IsDefault = (Convert.ToInt32(reader["DEF"]) == 1);
        }

        #endregion

        /// <summary>
        /// получение участника синхронизации по идентификатору
        /// </summary>
        /// <param name="id">идентификатор участника синхронизации</param>
        /// <returns></returns>
        public static SyncParticipant GetById(int id, SyncDatabase db)
        {
            using (IDbCommand cmd = db.CreateCommand())
            {
                cmd.CommandText = Const.Sql_SyncParticipantGet;
                cmd.Parameters.Add(cmd.CreateParameter());
                IDbDataParameter p = (cmd.Parameters[0] as IDbDataParameter);
                p.Direction = ParameterDirection.Input;
                p.ParameterName = "@id";
                p.Value = id;
                using (IDataReader reader = cmd.ExecuteReader())
                    if (reader.Read())
                        return new SyncParticipant(reader);
                    else
                        return null;
            }
        }
    }

    // ===============================================================================================

    public class SyncParticipantList : List<SyncParticipant>
    {
        public void Fill(IDbConnection connection)
        {
            Clear();
            using (IDbCommand command = connection.CreateCommand())
            {
                command.CommandText = Const.Table_SyncParticipants;
                command.CommandType = CommandType.TableDirect;
                using (IDataReader reader = command.ExecuteReader())
                    while (reader.Read())
                        Add(new SyncParticipant(reader));
            }
        }
    }

    // ===============================================================================================

}
