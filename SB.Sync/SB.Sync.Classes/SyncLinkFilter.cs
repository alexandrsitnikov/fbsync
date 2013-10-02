using System;
using System.Collections.Generic;
using System.Data;
using System.Text;
using System.Xml.Serialization;
using System.Runtime.Serialization;

namespace SB.Sync.Classes
{
    [Serializable]
    [XmlType(TypeName = "Filter")]
    public abstract class SyncLinkFilter
    {
        public abstract bool FilterRow(DataTable table, DataRow newRow, SyncLogItem log_item);
    }

    // ---------------------------------------------------------------------------

    [Serializable]
    [XmlInclude(typeof(SyncLinkFieldValueRowFilter))]
    [KnownType(typeof(SyncLinkFieldValueRowFilter))]
    public class SyncLinkFilterList : List<SyncLinkFilter>
    {
        internal bool FilterRow(DataTable table, DataRow newRow, SyncLogItem log_item)
        {
            foreach (SyncLinkFilter flt in this)
                if (!flt.FilterRow(table, newRow, log_item))
                    return false;
            return true;
        }
    }

    // ---------------------------------------------------------------------------

    [Serializable]
    [XmlType(TypeName = "FieldValueRowFilter")]
    public class SyncLinkFieldValueRowFilter : SyncLinkFilter
    {
        [XmlAttribute]
        public string FieldName;

        [XmlAttribute]
        public string FieldValue;

        public override bool FilterRow(DataTable table, DataRow newRow, SyncLogItem log_item)
        {
            if (newRow.Table.Columns.Contains(FieldName))
                return (string.Compare(newRow[FieldName].ToString(), FieldValue, true) == 0);
            else
                return true;
        }
    }
}
