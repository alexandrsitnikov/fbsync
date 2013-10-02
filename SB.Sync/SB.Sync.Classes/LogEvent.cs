using System;
using System.Collections.Generic;
//using System.Linq;
using System.Text;
using System.Runtime.Serialization;
using System.ServiceModel;
using log4net.Core;

namespace SB.Sync.Classes
{
    public enum LogEventLevel
    {
        Debug,
        Info,
        Warn,
        Error,
        Fatal
    }

    [DataContract]
    public class LogEvent
    {
        private LoggingEventData logEventData;

        [DataMember]
        public string Domain;

        [DataMember]
        public string Message;

        [DataMember]
        public string Exception_Message;
        
        [DataMember]
        public string Exception_StackTrace;

        [DataMember]
        public string Identity;

        [DataMember]
        public LogEventLevel Level;

        [DataMember]
        public string LoggerName;

        [DataMember]
        public string ThreadName;

        [DataMember]
        public DateTime Timestamp;

        [DataMember]
        public string UserName;

        public LogEvent()
        {
            logEventData = new LoggingEventData();
        }

        public LogEvent(LoggingEvent evt) : this()
        {
            Domain = evt.Domain;
            Message = evt.MessageObject.ToString();
            if (evt.ExceptionObject != null)
            {
                Exception_Message = evt.ExceptionObject.Message;
                Exception_StackTrace = evt.ExceptionObject.StackTrace;
            }
            Identity = evt.Identity;
            Level = GetLevel(evt.Level);
            LoggerName = evt.LoggerName;
            ThreadName = evt.ThreadName;
            Timestamp = evt.TimeStamp;
            UserName = evt.UserName;
        }

        private LogEventLevel GetLevel(Level level)
        {
            if (level == log4net.Core.Level.Fatal)
                return LogEventLevel.Fatal;
            else if (level == log4net.Core.Level.Error)
                return LogEventLevel.Error;
            else if (level == log4net.Core.Level.Warn)
                return LogEventLevel.Warn;
            else if (level == log4net.Core.Level.Info)
                return LogEventLevel.Warn;
            else
                return LogEventLevel.Debug;
        }

        public LoggingEvent GetLoggingEvent()
        {
            logEventData.Domain = Domain;
            logEventData.ExceptionString = Exception_Message;
            logEventData.Identity = Identity;
            logEventData.Level = GetLevel2(Level);
            logEventData.LoggerName = LoggerName;
            logEventData.Message = Message;
            logEventData.ThreadName = ThreadName;
            logEventData.TimeStamp = Timestamp;
            logEventData.UserName = UserName;

            return new LoggingEvent(logEventData);
        }

        private Level GetLevel2(LogEventLevel level)
        {
            if (level == LogEventLevel.Fatal)
                return log4net.Core.Level.Fatal;
            else if (level == LogEventLevel.Error)
                return log4net.Core.Level.Error;
            else if (level == LogEventLevel.Warn)
                return log4net.Core.Level.Warn;
            else if (level == LogEventLevel.Info)
                return log4net.Core.Level.Info;
            else
                return log4net.Core.Level.Debug;
        }
    }

    [KnownType(typeof(LogEvent))]
    public class LogEventList : List<LogEvent>
    {
    }

}
