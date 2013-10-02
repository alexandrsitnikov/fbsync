using System;
using System.IO;
using System.Security.Cryptography;
using ICSharpCode.SharpZipLib.Zip;
using System.Runtime.Serialization;

namespace SB.Sync.Classes
{
	[DataContract]
	public class CompressedData
	{
		private Byte [] data = null;
		protected Byte [] compressedData;
		private bool recompress = true;

		private int size;

		public CompressedData()
		{
			Clear();
		}

        [IgnoreDataMember]
		public Byte [] Data
		{
			get { return data; }
			set 
			{ 
				data = value; 
				size = data.Length;
				recompress = true;
			}
		}

		public int Size
		{
			get { return size; }
			set { size = value; }
		}

		public override string ToString()
		{
			return Convert.ToString(data);
		}

		public virtual void SaveToFile(string fileName)
		{
			DeCompressIfCompressed();
			using (FileStream fs = new FileStream(fileName, FileMode.Create))
				(new BinaryWriter(fs)).Write(data);
		}

		private void DeCompressIfCompressed()
		{
			if (data == null && compressedData != null)
				data = DeCompress(compressedData);
		}

		public virtual void SaveToCompressedFile(string fileName)
		{
			using (FileStream fs = new FileStream(fileName, FileMode.Create))
				(new BinaryWriter(fs)).Write(Compressed);
		}

		protected virtual Byte [] Compress(Byte[] srcData)
		{
			if (compressedData == null || recompress)
			{
				MemoryStream streamOut = new MemoryStream();
				ZipOutputStream zip = new ZipOutputStream(streamOut);
				zip.SetLevel(3);
				zip.PutNextEntry(new ZipEntry("file.out"));
				zip.Write(srcData, 0, srcData.Length);
				zip.Finish();
				zip.Close();
				streamOut.Close();
				compressedData = streamOut.ToArray();
				recompress = false;
			}
			return compressedData;
		}

		protected virtual Byte [] DeCompress(Byte[] srcData)
		{
			if (srcData.Length > 0)
			{
				MemoryStream streamIn = new MemoryStream(srcData);
				ZipInputStream zip = new ZipInputStream(streamIn);
				ZipEntry ze = zip.GetNextEntry();
				if (ze != null)
				{
					MemoryStream streamOut = new MemoryStream(Convert.ToInt32(ze.Size));
					int size = 8192;
					byte [] buf = new byte[size];

					while (true)
					{
						size = zip.Read(buf, 0, buf.Length);
						if (size > 0)
							streamOut.Write(buf, 0, size);
						else
							break;
					}
                    size = Convert.ToInt32(streamOut.Length);
					return streamOut.ToArray();
				}
				else
					return new byte[0];
			}
			else
				return new byte[0];
		}

        [DataMember]
        public Byte[] Compressed
		{
			get
			{
				if (compressedData != null)
					return compressedData;
				else if ((data != null) && (data.Length > 0))
					return Compress(this.data);
				else
					return null;
			}
			set
			{
				if ((value != null) && (value.Length > 0))
					this.data = DeCompress(value);
				else
					Clear();
			}
		}

		public void Clear()
		{
			data = new byte[0];
			size = 0;
			compressedData = null;
		}

		public virtual void LoadFromFile(string fileName)
		{
			using (FileStream fs = new FileStream(fileName, FileMode.Open))
			{
				Byte [] newData = new byte[fs.Length];
				fs.Read(newData, 0, Convert.ToInt32(fs.Length));
				data = newData;
				Size = Convert.ToInt32(fs.Length);
				compressedData = null;
				recompress = true;
			}
		}
	}

	// =====================================================================================

	public class CryptTasks
	{

	}

	// =====================================================================================

	[Serializable]
	public class EncryptedData : CompressedData
	{
		private byte [] hash;

		public byte [] Hash
		{
			get { return hash; }
		}

		protected override Byte[] Compress(Byte[] srcData)
		{
			byte [] result = base.Compress (srcData);		

			hash = (new SHA1Managed()).ComputeHash(srcData);
			return result;
		}
	}

	// =====================================================================================
}
