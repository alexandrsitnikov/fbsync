using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using SB.Sync.Classes;
using System.ServiceModel;

namespace SB.Sync.Svc
{
    [ServiceBehavior(InstanceContextMode = InstanceContextMode.Single)]
    public class SyncRemoteSingletonImpl : ISyncRemoteSingleton
    {
        private Service Service;

        public SyncRemoteSingletonImpl(Service svc)
        {
            Service = svc;
        }

        #region ISyncRemoteSingleton Members

        public ISyncDatabase GetDatabase(string DatabaseName)
        {
            SyncDatabaseConnection c = new SyncDatabaseConnection(Service.Config.Connections[0] as ConfigDatabase);
            return c.GetSyncDatabase();
        }

        public SB.Sync.Classes.ISyncRemoteDatabaseWrapper GetDatabaseWrapper(string DatabaseName)
        {
            return null;
        }

        #endregion
    }
}
