using System;
using System.Collections.Generic;
using System.Text;

namespace SB.Sync.Classes
{
    public class SyncSession
    {
        private SyncLink _Link;

        public SyncSession(SyncLink Link)
        {
            this._Link = Link;
        }

        public SyncLink Link
        {
            get { return _Link; }
        }
    }
}
