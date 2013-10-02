using System;
using System.Collections.Generic;
using System.Text;
using System.ServiceModel;

namespace SB.Sync.Classes
{
    [ServiceContract]
    public interface ISyncRemoteSingleton
    {
        [OperationContract]
        ISyncDatabase GetDatabase(string DatabaseName);

        [OperationContract]
        ISyncRemoteDatabaseWrapper GetDatabaseWrapper(string DatabaseName);
    }
}
