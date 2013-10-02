using System;
using System.Collections.Generic;
using System.Windows.Forms;
using SB.Svc.Base;
using SB.Sync.Classes;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using System.Runtime.Serialization;
using System.Threading;
using System.Text;
using log4net;
using FirebirdSql.Data.FirebirdClient;

namespace SB.Sync.Svc
{
    static class Program
    {
        static ILog log;
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main(string [] args)    
        {
            AppDomain.CurrentDomain.UnhandledException += new UnhandledExceptionEventHandler(CurrentDomain_UnhandledException);
            log4net.Config.XmlConfigurator.Configure();
            log = LogManager.GetLogger(typeof(Program));
            try
            {
                SB.Svc.Base.ServiceLauncher.Execute(new Service(), args);
            }
            catch (Exception ex)
            {
                log.Error(string.Format("Необработанное исключение при работе службы:\r\n{0}", ex.Message), ex);
            }
        }

        static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            log.Fatal(string.Format("Произошла аварийная ошибка.\nТекст ошибки: {0}\nСтек трассировки: {1}",
                ((Exception)e.ExceptionObject).Message, ((Exception)e.ExceptionObject).StackTrace), (Exception)e.ExceptionObject);
        }
    }
}