using System;
using System.Collections.Generic;
using System.Linq;
using System.Data;
using System.Text;
using System.Xml.Serialization;
using FirebirdSql.Data.FirebirdClient;
using SB.Sync.Classes;

namespace SB.Sync.Svc
{
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    public class Config
    {
        public string DefaultConnectionType = "FirebirdSql.Data.FirebirdClient.FbConnection,FirebirdSql.Data.FirebirdClient";
        public string DefaultSyncDatabaseConnectionType = "SB.Sync.Svc.SyncDatabase,SB.Sync.Svc";
        public string DefaultListenAddress;
        public int DefaultSyncDelay = 60;

        // количество попыток связи перед констатацией факта что связаться не получится
        public int DefaultLinkRetries = 5;

        // интервал времени для повтора связи после ошибок
        public int DefaultRetryAfterErrorsDelay = 7200;

        public ConfigConnectionList Connections;
        public ConfigSyncLinkList Links;
        public ConfigParamList Params;

        public Config()
        {
            Connections = new ConfigConnectionList();
            Links = new ConfigSyncLinkList();
            Params = new ConfigParamList();
        }

        public string ParseString(string s)
        {
            foreach (ConfigParam par in Params)
                s = s.Replace("$" + par.Name + "$", par.Value);
            return s;
        }

        public virtual void Validate()
        {
            if (DefaultSyncDelay < 5)
                throw new Exception("Недопустимое значение DefaultSyncDelay (должно быть не менее 5 секунд)!");
            Connections.Validate(this);
            Links.Validate(this);
        }

        internal void Loaded()
        {
            foreach (ConfigConnection cc in Connections)
            {
                cc.Config = this;
                cc.Name = ParseString(cc.Name);
            }

            foreach (ConfigSyncLink link in Links)
            {
                link.Config = this;
                link.Local = ParseString(link.Local);
                link.Remote = ParseString(link.Remote);
                link.Name = ParseString(link.Name);
            }
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlInclude(typeof(ConfigDatabase))]
    [XmlInclude(typeof(ConfigRemoteService))]
    [XmlType(TypeName = "Connection")]
    public abstract class ConfigConnection
    {
        [XmlAttribute]
        public string Name;

        [XmlIgnore]
        internal Config Config;

        internal virtual void Validate(Config config)
        {
            if (string.IsNullOrEmpty(Name))
                throw new ArgumentException("ConfigDatabase (??): Не заполнено свойство Name!");
        }

        public abstract IConnection GetConnection();

        // for debugging
        public string DebugSaveRecvPacketFileName;
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    public class ConfigConnectionList : List<ConfigConnection>
    {
        public virtual void Validate(Config config)
        {
            foreach (ConfigConnection cdb in this)
                cdb.Validate(config);
        }

        public ConfigConnection Find(string name)
        {
            return base.Find(delegate(ConfigConnection db)
            {
                return (string.Compare(db.Name, name) == 0);
            });
        }

        public bool Contains(string name)
        {
            return (Find(name) != null);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlType(TypeName="Database")]
    public class ConfigDatabase : ConfigConnection
    {
        public string ConnectionString;
        public string ConnectionType;
        public string SyncDatabaseConnectionType;

        [XmlAttribute]
        [System.ComponentModel.DefaultValue(false)]
        public bool AllowedRemoteAccess;

        [XmlAttribute]
        public bool ListenEvents = true;

        internal override void Validate(Config config)
        {
            base.Validate(config);
            if (string.IsNullOrEmpty(ConnectionString))
                throw new ArgumentException(string.Format("ConfigRemoteService ({0}): Не заполнено свойство ConnectionString!", Name));
            if (string.IsNullOrEmpty(ConnectionType))
                ConnectionType = config.DefaultConnectionType;
            if (string.IsNullOrEmpty(SyncDatabaseConnectionType))
                SyncDatabaseConnectionType = config.DefaultSyncDatabaseConnectionType;
        }

        public override IConnection GetConnection()
        {
            if (string.IsNullOrEmpty(SyncDatabaseConnectionType))
                throw new ArgumentException("Не задан тип обработчика БД синхронизации (SyncDatabaseConnectionType)!");

            Type t = Type.GetType(Config.ParseString(SyncDatabaseConnectionType));
            if (t == null)
                throw new ArgumentException(string.Format(
                    "Не найден тип обработчика БД синхронизации ({0})!", SyncDatabaseConnectionType));

            return Activator.CreateInstance(t, this) as SyncDatabaseConnection;
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlType(TypeName = "RemoteService")]
    public class ConfigRemoteService : ConfigConnection
    {
        public string Address;
        public string DatabaseName;

        internal override void Validate(Config config)
        {
            base.Validate(config);
            if (string.IsNullOrEmpty(Address))
                throw new ArgumentException(string.Format("ConfigRemoteService ({0}): Не заполнено свойство Address!", Name));
            if (string.IsNullOrEmpty(DatabaseName))
                throw new ArgumentException(string.Format("ConfigRemoteService ({0}): Не заполнено свойство DatabaseName!", Name));
        }

        public string GetAddressString()
        {
            return Config.ParseString(Address);
        }

        public string GetDatabaseNameString()
        {
            return Config.ParseString(DatabaseName);
        }

        public override IConnection GetConnection()
        {
            return new RemoteSyncDatabaseConnection(this);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlType(TypeName = "SyncLink")]
    public class ConfigSyncLink
    {
        [XmlIgnore]
        internal Config Config;

        [XmlAttribute]
        public string Name;

        public string Local;
        public string Remote;

        [System.ComponentModel.DefaultValue(SyncAgentOrder.RemoteLocal)]
        public SyncAgentOrder Order;
        
        [System.ComponentModel.DefaultValue(0)]
        public int LocalId = 0;

        [System.ComponentModel.DefaultValue(0)]
        public int RemoteId = 0;

        public ConfigConnection LocalConnection;
        public ConfigConnection RemoteConnection;

        [XmlAttribute]
        public bool Enabled = true;

        [System.ComponentModel.DefaultValue(0)]
        public int SyncDelay = 0;

        public SyncLinkFilterList LocalFilters;
        public SyncLinkFilterList RemoteFilters;

        // количество попыток связи перед констатацией факта что связаться не получится
        public int LinkRetries;

        // интервал времени для повтора связи после ошибок
        public int RetryAfterErrorsDelay;

        public ConfigSyncLink()
        {
            LocalFilters = new SyncLinkFilterList();
            RemoteFilters = new SyncLinkFilterList();
        }

        public virtual void Validate(Config config)
        {
            if (SyncDelay <= 5)
                SyncDelay = config.DefaultSyncDelay;

            if (LinkRetries <= 1)
                LinkRetries = config.DefaultLinkRetries;

            if (RetryAfterErrorsDelay <= 600)
                RetryAfterErrorsDelay = config.DefaultRetryAfterErrorsDelay;

            if (RetryAfterErrorsDelay <= 600)
                RetryAfterErrorsDelay = 600;

            if (string.IsNullOrEmpty(Name))
                throw new ArgumentException("ConfigSyncLink (??): Не заполнено свойство Name!");
            
            if (string.IsNullOrEmpty(Local))
                throw new ArgumentException(string.Format("ConfigSyncLink ({0}): Не заполнено свойство Local!", Name));

            if (string.IsNullOrEmpty(Remote))
                throw new ArgumentException(string.Format("ConfigSyncLink ({0}): Не заполнено свойство Remote!", Name));

            if (!config.Connections.Contains(Local))
                throw new ArgumentException(string.Format("ConfigSyncLink ({0}): Не найдено соединение, указанное в Local ({1})!", 
                    Name, Local));

            if (!config.Connections.Contains(Remote))
                throw new ArgumentException(string.Format("ConfigSyncLink ({0}): Не найдено соединение, указанное в Remote ({1})!", 
                    Name, Remote));

            LocalConnection = config.Connections.Find(Local);
            RemoteConnection = config.Connections.Find(Remote);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    public class ConfigSyncLinkList : List<ConfigSyncLink>
    {
        public virtual void Validate(Config config)
        {
            foreach (ConfigSyncLink cdb in this)
                cdb.Validate(config);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlType(TypeName = "Param")]
    public class ConfigParam
    {
        [XmlAttribute]
        public string Name;
        
        [XmlAttribute]
        public string Value;

        public ConfigParam()
        {

        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

    [Serializable]
    [XmlType(TypeName = "Params")]
    public class ConfigParamList : List<ConfigParam>
    {
    }
}
