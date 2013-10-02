using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;

namespace SB.Sync.Svc
{
    public class LogLinksFileAppender : log4net.Appender.RollingFileAppender
    {
        public override void ActivateOptions()
        {
            base.ActivateOptions();
        }

        protected override void Append(log4net.Core.LoggingEvent loggingEvent)
        {
            base.Append(loggingEvent);
        }
    }
}
