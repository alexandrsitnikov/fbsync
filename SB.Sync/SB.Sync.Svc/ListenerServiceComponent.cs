using System;
using System.Collections.Generic;
using System.Text;
using System.ServiceModel;
using System.ServiceModel.Description;
using SB.Sync.Classes;

namespace SB.Sync.Svc
{
    public class ListenerServiceComponent : SB.Svc.Base.CustomServiceComponent
    {
        private Service _Service;
        private ServiceHost host;

        public ListenerServiceComponent(Service Service) : base(Service, "Listener")
        {
            this._Service = Service;
        }

        protected override void InternalStart()
        {
            base.InternalStart();

            host = new ServiceHost(typeof(SyncDatabaseRemote), new Uri(_Service.Config.DefaultListenAddress));

            host.Open();
        }

        void host_Opened(object sender, EventArgs e)
        {
            
        }

        void host_Opening(object sender, EventArgs e)
        {
        }

        protected override void InternalStop()
        {
            host.Close();
            base.InternalStop();
        }
    }
}
