using System;
using System.Collections.Generic;
using System.Text;
using System.Data;

namespace SB.Sync.Classes
{
    /// <summary>
    /// интерфейс для работы с объектом БД
    /// </summary>
    interface ISyncDataObject
    {
        void Fill(IDataReader reader);
    }
}
