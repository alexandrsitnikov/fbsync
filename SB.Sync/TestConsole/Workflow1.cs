using System;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Collections;
using System.Drawing;
using System.Linq;
using System.Workflow.ComponentModel.Compiler;
using System.Workflow.ComponentModel.Serialization;
using System.Workflow.ComponentModel;
using System.Workflow.ComponentModel.Design;
using System.Workflow.Runtime;
using System.Workflow.Activities;
using System.Workflow.Activities.Rules;
using System.Runtime.Serialization.Formatters.Binary;
using log4net;
using SB.Sync.Classes;
using System.IO;
using FirebirdSql.Data.FirebirdClient;
using System.Messaging;

namespace TestConsole
{
	public sealed partial class Workflow1: SequentialWorkflowActivity
	{
		public Workflow1()
		{
			InitializeComponent();
		}

        private void initLogger_ExecuteCode(object sender, EventArgs e)
        {
            log4net.Config.BasicConfigurator.Configure();
        }

        private void waitForInput_ExecuteCode(object sender, EventArgs e)
        {
            Console.WriteLine("<press any key to exit>");
            Console.ReadKey();
        }

        public static DependencyProperty test_ExecuteCode1Event = DependencyProperty.Register("test_ExecuteCode1", typeof(System.EventHandler), typeof(TestConsole.Workflow1));

        [DesignerSerializationVisibilityAttribute(DesignerSerializationVisibility.Visible)]
        [BrowsableAttribute(true)]
        [CategoryAttribute("Handlers")]
        public event EventHandler test_ExecuteCode1
        {
            add
            {
                base.AddHandler(test_ExecuteCode1Event, value);
            }
            remove
            {
                base.RemoveHandler(test_ExecuteCode1Event, value);
            }   
        }

        private void test_ExecuteCode(object sender, EventArgs e)
        {
            SyncLogReplica replica1;
            BinaryFormatter bf = new BinaryFormatter();
            using (FileStream fs = new FileStream(@"C:\test.replica", FileMode.Open, FileAccess.Read))
            {
                replica1 = SyncLogReplica.Deserialize(fs);
            }            

            SyncDatabase db2 = new SyncDatabase(
    new FbConnection("Database=fdb:/var/db/ch_bl_s2.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251"));

            db2.StartSession(SessionMode.Write);

            //db2.TargetProcessReplica(replica1, false);    

            db2.EndSession(true);
            
            // - - - 

        }

        private void PrepareReplica_ExecuteCode(object sender, EventArgs e)
        {
            SyncDatabase db = new SyncDatabase(
                new FbConnection("Database=fdb:/var/db/ch_bl_s.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251"));

            db.StartSession(SessionMode.Read);

            SyncLogReplicaInfo replicaInfo = db.SourcePrepare(db.GetSyncLink(0));

            //SyncLogReplica replica = db.SourceGetNextReplica(replicaInfo, false) as SyncLogReplica;
            //replica.Serialize("c:\\test.replica", true);
            db.EndSession(true);
        }

        private void SyncAgentTest_ExecuteCode(object sender, EventArgs e)
        {
            SyncAgent agent = new SyncAgent();
            agent.Local = new SyncDatabase(
                new FbConnection(
                    "Database=fdb:/var/db/ch_bl_s.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251"));
            agent.Remote = new SyncDatabase(
                new FbConnection(
                    "Database=fdb:/var/db/ch_bl_s2.fdb;User=SYSDBA;Password=3Ky1u6nd;Charset=WIN1251"));
            agent.LocalToRemoteLinkId = 0;

            try
            {
                agent.Execute();
            }
            catch 
            {

            }
        }

        private void codeActivity1_ExecuteCode(object sender, EventArgs e)
        {

        }

        private void codeActivity2_ExecuteCode(object sender, EventArgs e)
        {
            TestContractClient cc = new TestContractClient();
            Console.WriteLine(cc.Add(3, 4));

            Console.WriteLine("press any key");
            Console.ReadLine();
        }
	}

}
