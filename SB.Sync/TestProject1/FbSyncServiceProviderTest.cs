using SB.Sync.Classes;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Microsoft.Synchronization;
using FirebirdSql.Data.FirebirdClient;
using System.Diagnostics;

namespace TestProject1
{     
    /// <summary>
    ///This is a test class for FbSyncServiceProviderTest and is intended
    ///to contain all FbSyncServiceProviderTest Unit Tests
    ///</summary>
    [TestClass()]
    public class FbSyncServiceProviderTest
    {
        [TestMethod]
        public void FbSyncServiceMainTest()
        {
            //Microsoft.Synchronization.SyncAgent agent = new Microsoft.Synchronization.SyncAgent();
            //FbConnection conn1 = new FbConnection("Database=fdb:/var/db/ch_bl_s.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251");
            //FbConnection conn2 = new FbConnection("Database=fdb:/var/db/ch_bl_s.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251");

            //conn1.Open();
            //conn2.Open();

            //DbSyncProvider syncProvider1 = new DbSyncProvider(conn1, "LocalProvider");
            //DbSyncProvider syncProvider2 = new DbSyncProvider(conn2, "RemoteProvider");

            //agent.LocalProvider = syncProvider1;
            //agent.RemoteProvider = syncProvider2;

            //agent.StateChanged += new System.EventHandler<SyncAgentStateChangedEventArgs>(agent_StateChanged);

            //Debug.WriteLine("starting synchronization...");

            //try
            //{
            //    agent.Synchronize();
            //}
            //finally
            //{
            //    Debug.WriteLine("synchronization completed ok");
            //}
        }

        void agent_StateChanged(object sender, SyncAgentStateChangedEventArgs e)
        {
            Debug.WriteLine(string.Format("event: StateChanged, current state is {0} (prev state is {1})",
                e.NewState.ToString(), e.OldState.ToString()));
        }
    }
}
