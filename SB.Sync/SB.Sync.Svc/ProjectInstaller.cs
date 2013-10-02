using System;
using System.Collections.Generic;
using System.Text;
using System.Configuration.Install;
using System.ComponentModel;
using System.ServiceProcess;
using SB.Svc.Base;

namespace SB.Sync.Svc
{
    [RunInstaller(true)]
    public class ProjectInstaller : Installer
    {
        private ServiceProcessInstaller serviceProcessInstaller;
        private ServiceInstaller serviceInstaller;

        public static string ServiceSuffix = string.Empty;

        public override void Install(System.Collections.IDictionary stateSaver)
        {
            UpdateServiceState();
            base.Install(stateSaver);
        }

        public override void Uninstall(System.Collections.IDictionary savedState)
        {
            UpdateServiceState();
            base.Uninstall(savedState);
        }

        public ProjectInstaller()
        {
            serviceProcessInstaller = new ServiceProcessInstaller();
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;
            serviceProcessInstaller.Username = null;
            serviceProcessInstaller.Password = null;

            serviceInstaller = new ServiceInstaller();
            serviceInstaller.DisplayName = "S-BANK: Служба синхронизации";
            serviceInstaller.ServiceName = "SB.Sync.Svc";

            UpdateServiceState();

            serviceInstaller.StartType = ServiceStartMode.Automatic;

            Installers.AddRange(
                new Installer [] 
                {
                    serviceProcessInstaller,
                    serviceInstaller
                });
        }

        private bool updatedName = false;
        private void UpdateServiceState()
        {
            if (!string.IsNullOrEmpty(ServiceSuffix) && !updatedName)
            {
                updatedName = true;
                serviceInstaller.DisplayName = string.Format("{0} ({1})", serviceInstaller.DisplayName, ServiceSuffix);
                serviceInstaller.ServiceName = string.Format("{0}.{1}", serviceInstaller.ServiceName, ServiceSuffix);
            }
        }
    }
}
