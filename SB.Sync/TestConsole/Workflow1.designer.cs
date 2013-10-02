using System;
using System.ComponentModel;
using System.ComponentModel.Design;
using System.Collections;
using System.Drawing;
using System.Reflection;
using System.Workflow.ComponentModel.Compiler;
using System.Workflow.ComponentModel.Serialization;
using System.Workflow.ComponentModel;
using System.Workflow.ComponentModel.Design;
using System.Workflow.Runtime;
using System.Workflow.Activities;
using System.Workflow.Activities.Rules;

namespace TestConsole
{
	partial class Workflow1
	{
		#region Designer generated code
		
		/// <summary> 
		/// Required method for Designer support - do not modify 
		/// the contents of this method with the code editor.
		/// </summary>
        [System.Diagnostics.DebuggerNonUserCode]
		private void InitializeComponent()
		{
            this.CanModifyActivities = true;
            this.waitForInput = new System.Workflow.Activities.CodeActivity();
            this.test = new System.Workflow.Activities.CodeActivity();
            this.PrepareReplica = new System.Workflow.Activities.CodeActivity();
            this.SyncAgentTest = new System.Workflow.Activities.CodeActivity();
            this.codeActivity1 = new System.Workflow.Activities.CodeActivity();
            this.initLogger = new System.Workflow.Activities.CodeActivity();
            this.terminateActivity1 = new System.Workflow.ComponentModel.TerminateActivity();
            this.codeActivity2 = new System.Workflow.Activities.CodeActivity();
            // 
            // waitForInput
            // 
            this.waitForInput.Name = "waitForInput";
            this.waitForInput.ExecuteCode += new System.EventHandler(this.waitForInput_ExecuteCode);
            // 
            // test
            // 
            this.test.Enabled = false;
            this.test.Name = "test";
            this.test.ExecuteCode += new System.EventHandler(this.test_ExecuteCode);
            // 
            // PrepareReplica
            // 
            this.PrepareReplica.Enabled = false;
            this.PrepareReplica.Name = "PrepareReplica";
            this.PrepareReplica.ExecuteCode += new System.EventHandler(this.PrepareReplica_ExecuteCode);
            // 
            // SyncAgentTest
            // 
            this.SyncAgentTest.Name = "SyncAgentTest";
            this.SyncAgentTest.ExecuteCode += new System.EventHandler(this.SyncAgentTest_ExecuteCode);
            // 
            // codeActivity1
            // 
            this.codeActivity1.Name = "codeActivity1";
            this.codeActivity1.ExecuteCode += new System.EventHandler(this.codeActivity1_ExecuteCode);
            // 
            // initLogger
            // 
            this.initLogger.Name = "initLogger";
            this.initLogger.ExecuteCode += new System.EventHandler(this.initLogger_ExecuteCode);
            // 
            // terminateActivity1
            // 
            this.terminateActivity1.Name = "terminateActivity1";
            // 
            // codeActivity2
            // 
            this.codeActivity2.Name = "codeActivity2";
            this.codeActivity2.ExecuteCode += new System.EventHandler(this.codeActivity2_ExecuteCode);
            // 
            // Workflow1
            // 
            this.Activities.Add(this.codeActivity2);
            this.Activities.Add(this.terminateActivity1);
            this.Activities.Add(this.initLogger);
            this.Activities.Add(this.codeActivity1);
            this.Activities.Add(this.SyncAgentTest);
            this.Activities.Add(this.PrepareReplica);
            this.Activities.Add(this.test);
            this.Activities.Add(this.waitForInput);
            this.Name = "Workflow1";
            this.CanModifyActivities = false;

		}

		#endregion

        private TerminateActivity terminateActivity1;
        private CodeActivity codeActivity2;
        private CodeActivity codeActivity1;
        private CodeActivity SyncAgentTest;
        private CodeActivity PrepareReplica;
        private CodeActivity waitForInput;
        private CodeActivity test;
        private CodeActivity initLogger;















    }
}
