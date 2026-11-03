// LightCull v0.2.6 helpers. Targets .NET Framework 4.5+ and Windows PowerShell 5.1.
// Metadata: read JPEG marker headers and EXIF TIFF IFDs without decoding JPEG pixels.
// Image loading: decode frozen WPF bitmaps on background worker threads.
using System;
using System.ComponentModel;
using System.Collections.Concurrent;
using System.Globalization;
using System.IO;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace LightCullFast {
  // Identify device/transport failures; do not retry an unreadable USB HDD
  // three times through different WIC decode paths.
  public static class StorageFaults {
    public static bool IsIoFailure(Exception ex) {
      for (Exception e = ex; e != null; e = e.InnerException) {
        if (e is IOException) return true;
        uint hr = unchecked((uint)e.HResult);
        if (hr == 0x8007045D || hr == 0x80070015 ||
            hr == 0x800701B1 || hr == 0x8007048F || hr == 0x80070017)
          return true;
      }
      return false;
    }
  }

  public sealed class PhotoItem : INotifyPropertyChanged {
    public int Id { get; set; }
    public string Path { get; private set; }
    public string Name { get; private set; }
    public string[] RawPaths { get; private set; }
    public string PairLabel { get; private set; }
    public bool Rejected { get; set; }
    public DateTime FileTime { get; private set; }
    public long JpgSize { get; set; }
    public DateTime CaptureTime { get; set; }
    public bool TimeLoaded { get; set; }
    public bool HashLoaded { get; set; }
    public string Hash { get; set; }
    public bool ThumbPending { get; set; }
    private BitmapSource thumbnail;
    private string stateText;
    private string statusColor;
    public BitmapSource Thumbnail {
      get { return thumbnail; }
      set { thumbnail = value; Notify("Thumbnail"); }
    }
    public string StateText {
      get { return stateText; }
      set { stateText = value; Notify("StateText"); }
    }
    public string StatusColor {
      get { return statusColor; }
      set { statusColor = value; Notify("StatusColor"); }
    }
    public PhotoItem(string path, string[] raws, DateTime fileTime) {
      Path = path;
      Name = System.IO.Path.GetFileName(path);
      RawPaths = raws ?? new string[0];
      PairLabel = RawPaths.Length > 0 ? "JPG + RAW" : "JPG";
      StateText = "保留";
      StatusColor = "#86EFAC";
      FileTime = fileTime;
      CaptureTime = DateTime.MinValue;
      Hash = "";
    }
    public event PropertyChangedEventHandler PropertyChanged;
    private void Notify(string name) {
      PropertyChangedEventHandler h = PropertyChanged;
      if (h != null) h(this, new PropertyChangedEventArgs(name));
    }
  }

  public static class FastExif {
    private static ushort U16(byte[] b, int p, bool little) {
      if (little) return (ushort)(b[p] | (b[p + 1] << 8));
      return (ushort)((b[p] << 8) | b[p + 1]);
    }
    private static uint U32(byte[] b, int p, bool little) {
      if (little) return (uint)b[p] | ((uint)b[p + 1] << 8) |
        ((uint)b[p + 2] << 16) | ((uint)b[p + 3] << 24);
      return ((uint)b[p] << 24) | ((uint)b[p + 1] << 16) |
        ((uint)b[p + 2] << 8) | b[p + 3];
    }
    private static bool InRange(byte[] b, long p, long length) {
      return p >= 0 && length >= 0 && p <= b.Length && length <= b.Length - p;
    }
    private static string ReadAsciiEntry(byte[] b, int origin, int entry, bool little) {
      ushort type = U16(b, entry + 2, little);
      uint len = U32(b, entry + 4, little);
      if (type != 2 || len == 0 || len > 2048) return null;
      long dataAt = len <= 4 ? entry + 8 : (long)origin + U32(b, entry + 8, little);
      if (!InRange(b, dataAt, len)) return null;
      return Encoding.ASCII.GetString(b, (int)dataAt, (int)len).TrimEnd('\0', ' ', '\r', '\n');
    }
    private static void ReadIfd(byte[] b, int origin, uint rel, bool little,
      ref string original, ref string subsec, ref string fallback, ref uint exifOffset) {
      long at = (long)origin + rel;
      if (!InRange(b, at, 2)) return;
      int count = U16(b, (int)at, little);
      if (!InRange(b, at + 2, 12L * count)) return;
      for (int i = 0; i < count; i++) {
        int entry = (int)(at + 2 + 12L * i);
        ushort tag = U16(b, entry, little);
        if (tag == 0x8769 && U16(b, entry + 2, little) == 4 &&
            U32(b, entry + 4, little) == 1) {
          exifOffset = U32(b, entry + 8, little);
        } else if (tag == 0x9003) {
          string s = ReadAsciiEntry(b, origin, entry, little);
          if (!String.IsNullOrEmpty(s)) original = s;
        } else if (tag == 0x9291) {
          string s = ReadAsciiEntry(b, origin, entry, little);
          if (!String.IsNullOrEmpty(s)) subsec = s;
        } else if (tag == 0x0132 || tag == 0x9004) {
          string s = ReadAsciiEntry(b, origin, entry, little);
          if (!String.IsNullOrEmpty(s)) fallback = s;
        }
      }
    }
    private static DateTime ParseExif(byte[] segment, DateTime fallback) {
      // TIFF header starts immediately after 'Exif\0\0'.
      if (segment.Length < 20 || segment[0] != 69 || segment[1] != 120 ||
          segment[2] != 105 || segment[3] != 102 || segment[4] != 0 || segment[5] != 0) return fallback;
      const int origin = 6;
      bool little = segment[origin] == 73 && segment[origin + 1] == 73;
      bool big = segment[origin] == 77 && segment[origin + 1] == 77;
      if ((!little && !big) || U16(segment, origin + 2, little) != 42) return fallback;
      string original = null, subsec = null, secondary = null;
      uint exifOffset = 0;
      ReadIfd(segment, origin, U32(segment, origin + 4, little), little,
        ref original, ref subsec, ref secondary, ref exifOffset);
      if (exifOffset > 0) ReadIfd(segment, origin, exifOffset, little,
        ref original, ref subsec, ref secondary, ref exifOffset);
      string capture = !String.IsNullOrEmpty(original) ? original : secondary;
      DateTime time;
      if (capture == null || !DateTime.TryParseExact(capture, "yyyy:MM:dd HH:mm:ss",
          CultureInfo.InvariantCulture, DateTimeStyles.None, out time)) return fallback;
      if (!String.IsNullOrEmpty(original) && !String.IsNullOrEmpty(subsec)) {
        int digits = 0;
        while (digits < subsec.Length && digits < 7 && subsec[digits] >= '0' && subsec[digits] <= '9') digits++;
        if (digits > 0) {
          long fractional = Int64.Parse(subsec.Substring(0, digits), CultureInfo.InvariantCulture);
          for (int n = digits; n < 7; n++) fractional *= 10;
          time = time.AddTicks(fractional);
        }
      }
      return time;
    }
    // EXIF TIFF IFD0 tag 0x0112. This reads JPEG markers only, never the image pixels.
    // Values 1-8 describe rotation and/or mirroring needed to display the photo upright.
    private static int OrientationInExif(byte[] segment) {
      if (segment == null || segment.Length < 20 ||
          segment[0] != 69 || segment[1] != 120 || segment[2] != 105 ||
          segment[3] != 102 || segment[4] != 0 || segment[5] != 0) return 1;
      const int origin = 6;
      bool little = segment[origin] == 73 && segment[origin + 1] == 73;
      bool big = segment[origin] == 77 && segment[origin + 1] == 77;
      if ((!little && !big) || U16(segment, origin + 2, little) != 42) return 1;
      long ifd = (long)origin + U32(segment, origin + 4, little);
      if (!InRange(segment, ifd, 2)) return 1;
      int count = U16(segment, (int)ifd, little);
      if (!InRange(segment, ifd + 2, 12L * count)) return 1;
      for (int i = 0; i < count; i++) {
        int at = (int)(ifd + 2 + 12L * i);
        if (U16(segment, at, little) != 0x0112) continue;
        // TIFF SHORT (type 3), count=1: value is stored directly in the entry.
        if (U16(segment, at + 2, little) != 3 ||
            U32(segment, at + 4, little) != 1) return 1;
        int orientation = U16(segment, at + 8, little);
        return (orientation >= 1 && orientation <= 8) ? orientation : 1;
      }
      return 1;
    }
    public static int ReadOrientation(string path) {
      try {
        using (FileStream s = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 16384, FileOptions.SequentialScan)) {
          if (s.ReadByte() != 0xFF || s.ReadByte() != 0xD8) return 1;
          while (s.Position + 4 <= s.Length) {
            if (s.ReadByte() != 0xFF) return 1;
            int marker;
            do { marker = s.ReadByte(); } while (marker == 0xFF);
            if (marker < 0 || marker == 0xDA || marker == 0xD9) return 1;
            if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
            int high = s.ReadByte(), low = s.ReadByte();
            if (low < 0) return 1;
            int size = (high << 8 | low) - 2;
            if (size < 0 || size > s.Length - s.Position) return 1;
            if (marker == 0xE1 && size >= 14) {
              byte[] data = new byte[size];
              int read = 0;
              while (read < size) {
                int n = s.Read(data, read, size - read);
                if (n <= 0) return 1;
                read += n;
              }
              if (data[0] == 69 && data[1] == 120 && data[2] == 105 &&
                  data[3] == 102 && data[4] == 0 && data[5] == 0)
                return OrientationInExif(data);
            } else s.Seek(size, SeekOrigin.Current);
          }
        }
      } catch (Exception) { /* missing/invalid metadata, inaccessible file */ }
      return 1;
    }
    public static DateTime ReadCaptureTime(string path, DateTime fallback) {
      try {
        using (FileStream s = new FileStream(path, FileMode.Open, FileAccess.Read,
            FileShare.ReadWrite | FileShare.Delete, 16384, FileOptions.SequentialScan)) {
          if (s.ReadByte() != 0xFF || s.ReadByte() != 0xD8) return fallback;
          // JPEG marker scan: skip byte ranges, never decode JPG pixels.
          while (s.Position + 4 <= s.Length) {
            int prefix = s.ReadByte();
            if (prefix != 0xFF) return fallback;
            int marker;
            do { marker = s.ReadByte(); } while (marker == 0xFF);
            if (marker < 0 || marker == 0xDA || marker == 0xD9) return fallback;
            if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
            int high = s.ReadByte(), low = s.ReadByte();
            if (low < 0) return fallback;
            int size = (high << 8 | low) - 2;
            if (size < 0 || size > s.Length - s.Position) return fallback;
            if (marker == 0xE1 && size >= 14) {
              byte[] data = new byte[size];
              int read = 0;
              while (read < size) {
                int n = s.Read(data, read, size - read);
                if (n <= 0) return fallback;
                read += n;
              }
              if (data[0] == 69 && data[1] == 120 && data[2] == 105 && data[3] == 102) {
                return ParseExif(data, fallback);
              }
            } else s.Seek(size, SeekOrigin.Current);
          }
        }
      } catch (IOException) { throw; } // An unreadable disk is NOT missing EXIF.
      catch (Exception) { /* invalid/no EXIF; keep fallback timestamp */ }
      return fallback;
    }
  }

  // WPF BitmapImage does not consistently apply the JPEG EXIF Orientation tag.
  // TransformedBitmap corrects the *displayed bitmap only*; source JPG/RAW remain untouched.
  public static class ImageOrientation {
    public static BitmapSource Apply(BitmapSource source, int orientation) {
      if (source == null || orientation <= 1 || orientation > 8) return source;
      Transform transform;
      switch (orientation) {
        case 2: transform = new ScaleTransform(-1, 1); break; // mirror horizontal
        case 3: transform = new RotateTransform(180); break;
        case 4: transform = new ScaleTransform(1, -1); break; // mirror vertical
        case 5: // transpose (90 degrees + mirror horizontal)
        case 7: { // transverse (90 degrees + mirror vertical)
          TransformGroup group = new TransformGroup();
          group.Children.Add(new RotateTransform(90));
          group.Children.Add(orientation == 5 ? new ScaleTransform(-1, 1) : new ScaleTransform(1, -1));
          transform = group;
          break;
        }
        case 6: transform = new RotateTransform(90); break;  // typical portrait JPG
        case 8: transform = new RotateTransform(270); break;
        default: return source;
      }
      try {
        TransformedBitmap corrected = new TransformedBitmap();
        corrected.BeginInit();
        corrected.Source = source;
        corrected.Transform = transform;
        corrected.EndInit();
        corrected.Freeze();
        return corrected;
      } catch (Exception) {
        // Unsupported/malformed JPEG metadata should not prevent photo browsing.
        return source;
      }
    }
  }

  public sealed class MetadataBatch {
    public volatile bool Finished;
    public int Done;
    public Exception Error;
    public string FaultPath;
    private volatile bool cancelled;
    public void Cancel() { cancelled = true; }
    public DateTime[] Results;
    public MetadataBatch(string[] paths, DateTime[] fallbacks) {
      if (paths == null || fallbacks == null || paths.Length != fallbacks.Length)
        throw new ArgumentException("Metadata input length mismatch");
      Results = (DateTime[])fallbacks.Clone();
      Thread thread = new Thread(delegate() {
        try {
          // HDD-friendly, sequential disk head access. Do not multiplex with 3
          // parallel EXIF reads that scatter seeks across a spinning disk.
          for (int i = 0; i < paths.Length; ++i) {
            if (cancelled) break;
            try { Results[i] = FastExif.ReadCaptureTime(paths[i], fallbacks[i]); }
            catch (Exception ex) {
              if (StorageFaults.IsIoFailure(ex)) { Error = ex; FaultPath = paths[i]; break; }
              Results[i] = fallbacks[i];
            }
            Interlocked.Increment(ref Done);
          }
        } catch (Exception ex) { Error = ex; }
        finally { Finished = true; }
      });
      thread.IsBackground = true;
      thread.Name = "LightCull metadata scanner (HDD-safe)";
      thread.Start();
    }
  }

  // Decode from an explicit file stream: avoids URI image-cache state and works
  // with Windows paths containing #, %, non-ASCII characters, etc.
  // The image is fully loaded + frozen before the stream is closed.
  public static class JpegDecoder {
    private static BitmapSource FromStream(string path, int width, bool ignoreColorProfile) {
      using (FileStream stream = new FileStream(path, FileMode.Open, FileAccess.Read,
          FileShare.ReadWrite | FileShare.Delete)) {
        BitmapImage b = new BitmapImage();
        b.BeginInit();
        b.StreamSource = stream;
        b.CacheOption = BitmapCacheOption.OnLoad;
        if (ignoreColorProfile) b.CreateOptions = BitmapCreateOptions.IgnoreColorProfile;
        if (width > 0) b.DecodePixelWidth = width;
        b.EndInit();
        b.Freeze();
        return b;
      }
    }
    public static BitmapSource Decode(string path, int width) {
      Exception streamError;
      try { return FromStream(path, width, false); }
      catch (Exception ex) {
        if (StorageFaults.IsIoFailure(ex)) throw; // Surface disk I/O error immediately.
        streamError = ex;
      }
      // Some camera JPGs have invalid/unsupported ICC profiles.
      // Only in that case do we retry without color management.
      Exception profileError;
      try { return FromStream(path, width, true); }
      catch (Exception ex) {
        if (StorageFaults.IsIoFailure(ex)) throw;
        profileError = ex;
      }
      try {
        BitmapImage b = new BitmapImage();
        b.BeginInit();
        b.UriSource = new Uri(path, UriKind.Absolute);
        b.CacheOption = BitmapCacheOption.OnLoad;
        b.CreateOptions = BitmapCreateOptions.IgnoreImageCache;
        if (width > 0) b.DecodePixelWidth = width;
        b.EndInit();
        b.Freeze();
        return b;
      } catch (Exception uriError) {
        throw new InvalidOperationException(
          "JPG 解码失败：FileStream=" + streamError.GetType().Name + " (" + streamError.Message +
          "); IgnoreColorProfile=" + profileError.GetType().Name + " (" + profileError.Message +
          "); UriSource=" + uriError.GetType().Name + " (" + uriError.Message + ")", uriError);
      }
    }
  }

  public sealed class DecodeResult {
    public int ItemId;
    public string Path;
    public int Generation;
    public bool IsPreview;
    public BitmapSource Image;
    public int Orientation;
    public string Error;
  }
  internal sealed class DecodeRequest {
    public int ItemId;
    public string Path;
    public int Width;
    public int Generation;
    public bool IsPreview;
  }
  public sealed class AsyncImageLoader : IDisposable {
    private readonly ConcurrentQueue<DecodeRequest> previews = new ConcurrentQueue<DecodeRequest>();
    private readonly ConcurrentQueue<DecodeRequest> thumbs = new ConcurrentQueue<DecodeRequest>();
    private readonly ConcurrentQueue<DecodeResult> results = new ConcurrentQueue<DecodeResult>();
    private readonly AutoResetEvent signal = new AutoResetEvent(false);
    private readonly Thread[] workers;
    private int pageGeneration;
    private int previewGeneration;
    private volatile bool stopping;
    private volatile bool paused;
    private string faultPath = "";
    private string faultMessage = "";
    public bool IsPaused { get { return paused; } }
    public string FaultPath { get { return faultPath; } }
    public string FaultMessage { get { return faultMessage; } }
    public void Pause(string path, string message) {
      faultPath = path ?? "";
      faultMessage = message ?? "";
      paused = true;
    }
    public void Resume() {
      paused = false;
      faultPath = "";
      faultMessage = "";
      signal.Set();
    }
    public AsyncImageLoader() {
      workers = new Thread[1]; // Mechanical-HDD preset: one sequential decoder.
      for (int i = 0; i < workers.Length; i++) {
        workers[i] = new Thread(Work);
        // WPF/WIC image codecs may require COM STA; do not decode on MTA workers.
        workers[i].SetApartmentState(ApartmentState.STA);
        workers[i].IsBackground = true;
        workers[i].Name = "LightCull JPEG decode " + i;
        workers[i].Start();
      }
    }
    public void SetPageGeneration(int value) { Volatile.Write(ref pageGeneration, value); }
    public void SetPreviewGeneration(int value) { Volatile.Write(ref previewGeneration, value); }
    public void RequestThumbnail(int index, string path, int pageGen) {
      thumbs.Enqueue(new DecodeRequest { ItemId = index, Path = path,
        Width = 330, Generation = pageGen, IsPreview = false });
      signal.Set();
    }
    public void RequestPreview(int index, string path, int previewGen) {
      previews.Enqueue(new DecodeRequest { ItemId = index, Path = path,
        Width = 2200, Generation = previewGen, IsPreview = true });
      signal.Set();
    }
    public bool TryGetResult(out DecodeResult result) { return results.TryDequeue(out result); }
    private bool IsCurrent(DecodeRequest job) {
      return job.IsPreview ? job.Generation == Volatile.Read(ref previewGeneration)
        : job.Generation == Volatile.Read(ref pageGeneration);
    }
    private void Work() {
      while (!stopping) {
        if (paused) { signal.WaitOne(200); continue; }
        DecodeRequest job;
        if (!previews.TryDequeue(out job) && !thumbs.TryDequeue(out job)) {
          signal.WaitOne(200);
          continue;
        }
        if (!IsCurrent(job) || paused) continue;
        BitmapSource bitmap = null;
        string error = null;
        int orientation = 1;
        try {
          // The worker only decodes. UI-thread code applies WPF rotation after
          // receiving the frozen bitmap, so a failed transform never hides the JPG.
          bitmap = JpegDecoder.Decode(job.Path, job.Width);
          orientation = FastExif.ReadOrientation(job.Path);
        } catch (Exception ex) {
          error = ex.GetType().Name + ": " + ex.Message;
          if (StorageFaults.IsIoFailure(ex)) Pause(job.Path, error);
        }
        if (IsCurrent(job) && !stopping) results.Enqueue(new DecodeResult {
          ItemId = job.ItemId, Path = job.Path, Generation = job.Generation,
          IsPreview = job.IsPreview, Image = bitmap, Orientation = orientation, Error = error
        });
      }
    }
    public void Dispose() {
      stopping = true;
      signal.Set();
      // Threads are background threads; do not block app exit for slow network storage.
    }
  }
}
