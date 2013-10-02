using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows.Forms;
using System.Reflection;

namespace Test123
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            Assembly asm = Assembly.Load("SB.Sync.Classes, Version=1.0.0.1, Culture=neutral, PublicKeyToken=a752914650e172c4");

            //SB.Sync.Classes.ITestContract c;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new Form1());
        }
    }
}
