using System;
using System.Collections.Generic;
using System.Text;
using System.Data;
using System.Text.RegularExpressions;

namespace SB.Sync.Classes
{
    public class Func
    {
        public static DbType TypeToDbType(Type type)
        {
            if (type == typeof(DateTime))
                return DbType.DateTime;
            else if (type == typeof(Double))
                return DbType.Double;
            else if (type == typeof(Decimal))
                return DbType.Double;
            else if (type == typeof(Int16))
                return DbType.Int16;
            else if (type == typeof(Int32))
                return DbType.Int32;
            else if (type == typeof(Int64))
                return DbType.Int64;
            else if (type == typeof(string))
                return DbType.String;
            else
                return DbType.Object;

        }


        internal static object [] GetRowIdValues(string row_id)
        {
            if (!row_id.StartsWith("<"))
                return new string [] { row_id } ;
            else
            {
                List<string> result = new List<string>();
                Regex regex = new Regex("<[^<>]*>", RegexOptions.Compiled);
                MatchCollection mc = regex.Matches(row_id);
                foreach (Match m in mc)
                    result.Add(m.Value.Trim(' ', '<', '>'));
                return result.ToArray();
            }
        }
    }
}
