using System;
using System.Collections.Generic;
using System.Linq;
using System.Configuration;
using System.Text;

namespace SB.Sync.Svc
{
    public class ConfigSectionHandler : IConfigurationSectionHandler
    {
        #region IConfigurationSectionHandler Members

        public object Create(object parent, object configContext, System.Xml.XmlNode section)
        {
            throw new NotImplementedException();
        }

        #endregion
    }
}
