using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using log4net;
using System.Xml.Serialization;

namespace SB.Sync.Svc
{
    public class Service : SB.Svc.Base.CustomService
    {
        private Config _Config;
        private SyncLinkCollection _Links;
        private static Service _Current;

        public Service() : base("SB.Sync.Svc", "S-BANK: Служба синхронизации данных")
        {
            _Current = this;
            log = LogManager.GetLogger(typeof(Service));
            Components.Clear();
            Components.Add(new ListenerServiceComponent(this));
            _Links = new SyncLinkCollection(this);
        }

        public static Service Current
        {
            get { return _Current; }
        }

        public override void Start()
        {
            if (LoadConfig())
            {
                CreateLinks();
                base.Start();
            }
        }

        private bool LoadConfig()
        {
            log.Debug("LoadConfig:begin");
            try
            {
                _Config = new Config();
                XmlSerializer xs = new XmlSerializer(typeof(Config));
                string fn = Path.Combine(AppDomain.CurrentDomain.BaseDirectory,
                    Path.GetFileName(Properties.Settings.Default.ConfigFileName));
                if (File.Exists(fn))
                    using (StreamReader sr = new StreamReader(fn, Encoding.GetEncoding(1251)))
                        _Config = xs.Deserialize(sr) as Config;
                else
                    throw new ArgumentException(string.Format("Не найден файл конфигурации: {0}", fn));

                using (StreamWriter sw = new StreamWriter(fn, false, Encoding.GetEncoding(1251)))
                {
                    xs.Serialize(sw, _Config);
                }

                _Config.Loaded();

                log.InfoFormat("Загружена конфигурация службы из файла {0}", Path.GetFileName(fn));

                log.Info("выполняется проверка конфигурации");
                try
                {
                    Config.Validate();
                }
                catch (Exception ex)
                {
                    log.Error(string.Format("Ошибка конфигурации: {0}", ex.Message), ex);
                    return false;
                }
                log.Info("конфигурация проверена. ошибок нет.");
            }
            catch (Exception ex)
            {
                log.Error(string.Format("Ошибка в процедуре LoadConfig: {0}", ex.Message), ex);
                return false;
            }
            log.Debug("LoadConfig:end");
            return true;
        }

        private void CreateLinks()
        {
            if (log.IsDebugEnabled) log.Debug("CreateLinks:begin");

            foreach (SyncLinkComponent lnk in _Links)
                Components.Remove(lnk);
            _Links.Clear();

            if (Config.Links.Count > 0)
            {
                log.Info("создаются потоки для обслуживания исходящих соединений синхронизации");

                foreach (ConfigSyncLink link in Config.Links)
                    if (link.Enabled)
                    {
                        SyncLinkComponent lnk = new SyncLinkComponent(_Links, link);
                        _Links.Add(lnk);
                        Components.Add(lnk);
                    }
                log.InfoFormat("создано {0} поток(а,ов) для обслуживания исходящих соединений синхронизации", _Links.Count);
            }
            else
                log.Warn("Нет исходящих соединений для данной службы!");

            if (log.IsDebugEnabled) log.Debug("CreateLinks:end");
        }

        public Config Config
        {
            get { return _Config; }
        }
    }
}
