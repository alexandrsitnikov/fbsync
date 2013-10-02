using System;
using System.Collections.Generic;
using System.Text;

namespace SB.Sync.Classes
{
    /// <summary>
    /// информация о репликации, заголовок
    /// </summary>
    [Serializable]
    public class SyncLogReplicaInfo
    {
        public DateTime Created;
        public SyncLink Link;
        public long MinLogId;
        public long MaxLogId;
        public ulong LogCount;
        public int ReplicaBatchSize;
        public uint ReplicaCount;

        public SyncLogReplicaInfo()
        {
            Created = DateTime.Now;
        }
    }

}
