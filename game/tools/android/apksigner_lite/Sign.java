import com.android.apksig.ApkSigner;
import com.android.apksig.ApkVerifier;
import java.io.*;
import java.security.*;
import java.security.cert.X509Certificate;
import java.util.*;

/** The parts of apksigner Godot's Android export calls: sign (in place, or --out) and verify. */
public class Sign {
  public static void main(String[] a) throws Exception {
    if (a.length == 0) { System.err.println("usage: sign|verify ..."); System.exit(2); }
    if (a[0].equals("--version") || a[0].equals("version")) { System.out.println("0.9"); return; }
    String cmd = a[0], ks = null, pass = null, alias = null, keyPass = null, out = null, in = null;
    for (int i = 1; i < a.length; i++) {
      switch (a[i]) {
        case "--ks": ks = a[++i]; break;
        case "--ks-pass": pass = a[++i].replaceFirst("^pass:", ""); break;
        case "--key-pass": keyPass = a[++i].replaceFirst("^pass:", ""); break;
        case "--ks-key-alias": alias = a[++i]; break;
        case "--out": out = a[++i]; break;
        case "--ks-type": case "--min-sdk-version": case "--max-sdk-version": i++; break;
        default: if (!a[i].startsWith("-")) in = a[i];
      }
    }
    if (cmd.equals("verify")) {
      ApkVerifier.Result r = new ApkVerifier.Builder(new File(in)).build().verify();
      System.out.println(r.isVerified() ? "Verified" : "DOES NOT VERIFY: " + r.getErrors());
      for (X509Certificate c : r.getSignerCertificates()) { byte[] d = MessageDigest.getInstance("SHA-256").digest(c.getEncoded()); StringBuilder h = new StringBuilder(); for (byte b : d) h.append(String.format("%02X:", b)); System.out.println("Signer SHA-256: " + h.substring(0, h.length() - 1)); }
      System.exit(r.isVerified() ? 0 : 1);
    }
    KeyStore k = null;
    for (String type : new String[]{"PKCS12", "JKS"}) {
      try { k = KeyStore.getInstance(type); try (InputStream s = new FileInputStream(ks)) { k.load(s, pass.toCharArray()); } break; } catch (Exception e) { k = null; }
    }
    if (alias == null) alias = Collections.list(k.aliases()).get(0);
    PrivateKey key = (PrivateKey) k.getKey(alias, (keyPass != null ? keyPass : pass).toCharArray());
    List<X509Certificate> certs = new ArrayList<>();
    for (java.security.cert.Certificate c : k.getCertificateChain(alias)) certs.add((X509Certificate) c);
    File src = new File(in), dst = out != null ? new File(out) : File.createTempFile("signed", ".apk", src.getAbsoluteFile().getParentFile());
    new ApkSigner.Builder(Collections.singletonList(new ApkSigner.SignerConfig.Builder("CERT", key, certs).build()))
      .setInputApk(src).setOutputApk(dst).setV1SigningEnabled(false).setV2SigningEnabled(true).build().sign();
    if (out == null) { if (!src.delete() || !dst.renameTo(src)) throw new IOException("couldn't replace " + src); }
    System.out.println("Signed");
  }
}
