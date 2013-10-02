using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using ICSharpCode.SharpZipLib.Zip;
using System.Reflection;
using System.ServiceModel;
using System.Xml;
using log4net;

namespace SB.Sync.Classes
{
    /// <summary>
    /// передаваемый кусок журнала, результат выполнения запроса к SP_SYNC_LOG_GET
    /// </summary>
    [DataContract, Serializable]
    public class SyncLogReplica
    {
        public SyncLogReplicaInfo Info;
        public int Index;
        public DateTime Created;
        public SyncLogItemList LogItems;
        
        public DataSet DataSet;
        public SyncTableList Tables;

        [NonSerialized]
        internal ILog log = LogManager.GetLogger(MethodInfo.GetCurrentMethod().DeclaringType);

        public SyncLogReplica()
        {
            LogItems = new SyncLogItemList();
            Tables = new SyncTableList();
            DataSet = new DataSet();
            DataSet.RemotingFormat = SerializationFormat.Binary;
            Created = DateTime.Now;
        }

        public SyncLogReplica(SyncLogReplicaInfo replicaInfo) : this()
        {
            Info = replicaInfo;
        }

        /// <summary>
        /// добавление таблицы данных к набору таблиц данных, по указанной таблице
        /// </summary>
        internal DataTable AddDataTable(SyncTable st)
        {
            if (DataSet.Tables.Contains(st.TableName))
                return DataSet.Tables[st.TableName];
            else
            {
                DataTable table = DataSet.Tables.Add(st.TableName);
                foreach (DataColumn col in st.Columns)
                {
                    DataColumn new_col = table.Columns.Add(col.ColumnName, col.DataType);
                    new_col.AllowDBNull = col.AllowDBNull;
                    new_col.ColumnName = col.ColumnName;
                    new_col.DataType = col.DataType;
                    new_col.MaxLength = col.MaxLength;
                    new_col.ReadOnly = col.ReadOnly;
                }

                // добавляем указатель на log item
                table.Columns.Add(Const.Field_LOG_ID, typeof(Int64));
                return table;
            }
        }

        /// <summary>
        /// сериализация реплики в поток
        /// </summary>
        public void Serialize(Stream stream, bool compress)
        {
            if (log.IsDebugEnabled) log.Debug("Serialize:begin");

            try
            {
                if (compress)
                {
                    using (ZipOutputStream zos = new ZipOutputStream(stream))
                    {
                        ZipEntry ze = new ZipEntry("replica.dat");
                        zos.PutNextEntry(ze);
                        using (MemoryStream streamInput = new MemoryStream(4096))
                        {
                            BinaryFormatter bf = new BinaryFormatter();
                            bf.Serialize(streamInput, this);
                            streamInput.Seek(0, SeekOrigin.Begin);

                            int buflen = 4096;
                            byte[] buf = new byte[buflen];
                            int bytesReaded = 0;
                            while ((bytesReaded = streamInput.Read(buf, 0, buflen)) > 0)
                                zos.Write(buf, 0, bytesReaded);
                        }
                        zos.Finish();
                    }
                }
                else
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    bf.Serialize(stream, this);
                }
            }
            catch (Exception ex)
            {
                log.Error("Ошибка при сериализации в поток", ex);
                throw;
            }

            if (log.IsDebugEnabled) log.Debug("Serialize:end");
        }

        public void Serialize(string FileName, bool compress)
        {
            using (FileStream fs = new FileStream(FileName, FileMode.Create, FileAccess.Write))
            {
                Serialize(fs, compress);
            }
        }

        public static SyncLogReplica Deserialize(Stream stream)
        {
            // читаем первые пару байт для определения типа файла
            byte[] buf = new byte[2];

            stream.Read(buf, 0, 2);
            stream.Seek(0, SeekOrigin.Begin);

            Stream serializeStream = stream;

            if (System.Text.Encoding.Default.GetString(buf) == "PK")
            {
                // unpacking
                using (ZipInputStream zs = new ZipInputStream(stream))
                {
                    ZipEntry ze = zs.GetNextEntry();
                    serializeStream = new MemoryStream(4096);
                    int buflen = 4096;
                    buf = new byte[buflen];
                    int bytesReaded = 0;
                    while ((bytesReaded = zs.Read(buf, 0, buflen)) > 0)
                        serializeStream.Write(buf, 0, bytesReaded);
                }
            }
            serializeStream.Seek(0, SeekOrigin.Begin);
            BinaryFormatter bf = new BinaryFormatter();
            return bf.Deserialize(serializeStream) as SyncLogReplica;
        }

        [DataMember]
        public byte[] CompressedData
        {
            get
            {
                MemoryStream ms = new MemoryStream();
                Serialize(ms, true);
                return ms.ToArray();
            }
            set
            {
                using (MemoryStream ms = new MemoryStream(value))
                {
                    SyncLogReplica deserialized = Deserialize(ms);
                    this.DataSet = deserialized.DataSet;
                    this.Created = deserialized.Created;
                    this.Index = deserialized.Index;
                    this.Info = deserialized.Info;
                    this.LogItems = deserialized.LogItems;
                    this.Tables = deserialized.Tables;
                }
            }
        }

        public static Encoding DefaultEncoding = Encoding.GetEncoding(1251);

        /*
        public byte [] DataSet_Bytes
        {
            get
            {
                MemoryStream ms = new MemoryStream();
                using (XmlTextWriter xtw = new XmlTextWriter(ms, DefaultEncoding))
                {
                    DataSet.WriteXml(xtw);
                    return ms.ToArray();
                }
            }
            set
            {
                using (XmlTextReader xtr = new XmlTextReader(new StringReader(DefaultEncoding.GetString(value))))
                {
                    DataSet.ReadXml(xtr);
                }
            }
        }*/
    }
}
