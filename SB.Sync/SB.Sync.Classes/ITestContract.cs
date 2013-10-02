using System;
using System.Collections.Generic;
using System.Text;
using System.ServiceModel;

namespace SB.Sync.Classes
{
    /// <summary>
    /// тестовый контракт для проверки возможностей WCF
    /// </summary>
    [ServiceContract]
    public interface ITestContract
    {
        [OperationContract]
        int Add(int a, int b);
    }
}
