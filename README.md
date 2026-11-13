# Dater

Boş saatlerini **seçtiğin çevrelerle** paylaştığın bir mobil uygulama (Lettuce alternatifi).

- Hesap aç, benzersiz bir `@kullanıcıadı` seç.
- Arkadaşlarını kullanıcı adıyla bul, arkadaşlık isteği gönder.
- **Çevreler** oluştur (ör. "Yakın arkadaşlar", "Tırmanış", "İş"); arkadaşlarını ekle ya da davet kodu/linki paylaş.
- **Takvimim** ekranında haftalık ızgarada boş saatlerini seç (dokun ya da basılı tutup sürükle, güne dokunarak tüm günü seç)
  ve **her seçim için hangi çevrelerin görebileceğini** işaretle. Haftalar arasında gezin, "Geçen haftayı kopyala".
- Çevre ekranında **ısı haritası**: her saatte kaç üyenin boş olduğu; saate dokununca kimlerin boş olduğu ve **Plan öner**.
  Üyeler planlara *Geliyorum / Belki / Gelemem* diye yanıt verir.
- **Bildirimler:** çevrende yeni plan önerilince ve planına yanıt gelince; uygulama içinde zil + bildirim listesi (canlı
  güncellenir), telefonda push bildirimi (Firebase kurulunca, aşağıya bak).
- Arayüz Türkçe ve İngilizce (cihaz diline göre, Profil'den değiştirilebilir).

## Yapı

| Klasör | İçerik |
|---|---|
| `app/` | Flutter uygulaması (iOS, Android, web) — Riverpod, go_router, supabase_flutter |
| `app/lib/core/` | Modeller, hafta/saat hesapları (`week.dart`), oturum, yönlendirme, ortak UI |
| `app/lib/features/` | `auth`, `availability` (haftalık ızgara), `circles`, `friends`, `notifications`, `plans`, `profile` |
| `app/lib/l10n/` | `app_tr.arb`, `app_en.arb` çevirileri |
| `supabase/migrations/` | Veritabanı şeması, satır seviyesi güvenlik (RLS) kuralları ve RPC'ler |
| `supabase/functions/push/` | Push gönderen Edge Function (Firebase Cloud Messaging HTTP v1) |
| `supabase/tests/` | Erişim kurallarını ve bildirim tetikleyicilerini doğrulayan pgTAP testleri |

### Gizlilik modeli
Her müsait saat, paylaşıldığı **her çevre için ayrı bir satır** olarak tutulur (`availability(user_id, circle_id, starts_at)`).
Bir satırı yalnızca o çevrenin üyeleri okuyabilir; bu kural veritabanında (RLS) uygulanır, uygulamaya güvenilmez.
Çevreye yalnızca sahibi **kabul edilmiş arkadaşlarını** ekleyebilir; davet koduna sahip herkes katılabilir (sahip kodu
yenileyerek eski linkleri iptal edebilir). Çevreden ayrılan kişinin o çevreyle paylaştığı saatler otomatik silinir.
Zamanlar UTC saklanır, cihazın saat diliminde gösterilir; yaz saati geçişlerinde saatler kaymaz.

## Kurulum

Gerekenler: [Flutter](https://docs.flutter.dev/get-started/install) (3.47+), [Supabase CLI](https://supabase.com/docs/guides/cli), Docker.

### 1. Backend (yerel)
```bash
supabase start
```
```bash
supabase db reset
```
```bash
supabase test db
```

### 2. Uygulama
Yerel Supabase'e bağlanmak için ek ayar gerekmez (varsayılan `http://127.0.0.1:54321`).
Android emülatöründe `127.0.0.1` yerine `10.0.2.2`, gerçek telefonda bilgisayarın yerel IP'sini kullan:
```bash
cd app && flutter run --dart-define=SUPABASE_URL=http://192.168.1.20:54321
```

### 3. Gerçek bir Supabase projesi
1. [supabase.com](https://supabase.com)'da proje oluştur.
2. Şemayı yükle:
   ```bash
   supabase link --project-ref <proje-ref>
   ```
   ```bash
   supabase db push
   ```
3. Dashboard → Authentication → URL Configuration → *Redirect URLs* listesine `dater://login-callback` ekle.
4. Uygulamayı proje adresi ve publishable (anon) anahtarıyla çalıştır:
   ```bash
   cd app && flutter run --dart-define=SUPABASE_URL=https://<proje-ref>.supabase.co --dart-define=SUPABASE_KEY=<publishable-key>
   ```

## Bildirimler

**Nasıl çalışır:** plan önerilince/yanıtlanınca veritabanı tetikleyicileri `notifications` tablosuna satır yazar.
Uygulamadaki zil ve bildirim listesi bu tabloyu okur ve Supabase Realtime ile canlı güncellenir; bunun için ek kurulum
gerekmez. Push için her yeni satırda veritabanı `push` Edge Function'ını çağırır, o da alıcının telefonlarına Firebase
Cloud Messaging (FCM) ile bildirimi alıcının dilinde ve saat diliminde gönderir. Aşağıdaki kurulum yapılana kadar push
kapalıdır; uygulama yine çalışır.

### 1. Firebase projesi
1. [console.firebase.google.com](https://console.firebase.google.com)'da proje oluştur.
2. **Android uygulaması ekle**, paket adı `com.dater.dater` → indirilen `google-services.json` dosyasını
   `app/android/app/` içine koy.
3. **iOS uygulaması ekle**, bundle ID `com.dater.dater` → `GoogleService-Info.plist` dosyasını Xcode'da
   `app/ios/Runner.xcworkspace` açıkken **Runner** klasörüne sürükle ("Copy items if needed" işaretli).
4. iOS için: Apple Developer hesabında bir **APNs Authentication Key (.p8)** oluştur, Firebase › Project settings ›
   Cloud Messaging › Apple app configuration bölümüne yükle. Xcode › Runner › *Signing & Capabilities* altında
   **Push Notifications** ve **Background Modes › Remote notifications** ekle.

> Bu iki yapılandırma dosyası gizli anahtar değildir, repoya eklenebilir; istemezsen `.gitignore`'a ekle.

### 2. Sunucu tarafı (Supabase)
1. Firebase › Project settings › *Service accounts* › **Generate new private key** ile bir JSON indir.
   Bu dosya gizlidir: repoya veya sohbete koyma, sadece Supabase secret olarak ver:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat ~/Downloads/firebase-service-account.json)"
   ```
2. Rastgele bir webhook parolası üret ve function'a ver:
   ```bash
   openssl rand -hex 32
   ```
   ```bash
   supabase secrets set PUSH_WEBHOOK_SECRET=<üretilen-değer>
   ```
3. Function'ı yükle:
   ```bash
   supabase functions deploy push
   ```
4. Supabase Dashboard › SQL Editor'da veritabanına function adresini ve aynı parolayı ver:
   ```sql
   select vault.create_secret('https://<proje-ref>.supabase.co/functions/v1/push', 'push_webhook_url');
   select vault.create_secret('<üretilen-değer>', 'push_webhook_secret');
   ```
   Push'u kapatmak için bu iki secret'ı silmen yeterli.

### 3. Uygulamayı push açık derle
```bash
cd app && flutter run --dart-define=PUSH_ENABLED=true --dart-define=SUPABASE_URL=https://<proje-ref>.supabase.co --dart-define=SUPABASE_KEY=<publishable-key>
```
`PUSH_ENABLED` verilmezse uygulama Firebase'i hiç başlatmaz (yapılandırma dosyaları yokken çökmemesi için).
Uygulama ilk açılışta bildirim izni ister; çıkış yapınca o cihaza push gitmez.

## Testler
```bash
cd app && flutter analyze && flutter test
```
Gerçek veritabanına karşı uçtan uca akış (kayıt → arkadaşlık → çevre → müsaitlik görünürlüğü → davet → plan),
`supabase start` çalışırken:
```bash
cd app && flutter test test/integration --dart-define=DATER_INTEGRATION=true
```
Push function'ının testleri ([Deno](https://deno.com) ile):
```bash
cd supabase/functions/push && deno test
```

## Davet linkleri
Davet linki biçimi `dater://app/join/<KOD>`; uygulama Android ve iOS'ta `dater://` şemasını kaydeder.
Linki açan kişi giriş yapmamışsa önce giriş/kayıt ekranına, ardından otomatik olarak çevreye yönlendirilir.
Uygulamayı yüklememiş kişiler için web'de açılan (https) linkler bir alan adı gerektirir; şimdilik kod da mesajda paylaşılır
ve *Çevreler → Kodla katıl* ile girilebilir.
