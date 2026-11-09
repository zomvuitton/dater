# Dater

Boş saatlerini **seçtiğin çevrelerle** paylaştığın bir mobil uygulama (Lettuce alternatifi).

- Hesap aç, benzersiz bir `@kullanıcıadı` seç.
- Arkadaşlarını kullanıcı adıyla bul, arkadaşlık isteği gönder.
- **Çevreler** oluştur (ör. "Yakın arkadaşlar", "Tırmanış", "İş"); arkadaşlarını ekle ya da davet kodu/linki paylaş.
- **Takvimim** ekranında haftalık ızgarada boş saatlerini seç (dokun ya da basılı tutup sürükle, güne dokunarak tüm günü seç)
  ve **her seçim için hangi çevrelerin görebileceğini** işaretle. Haftalar arasında gezin, "Geçen haftayı kopyala".
- Çevre ekranında **ısı haritası**: her saatte kaç üyenin boş olduğu; saate dokununca kimlerin boş olduğu ve **Plan öner**.
  Üyeler planlara *Geliyorum / Belki / Gelemem* diye yanıt verir.
- Arayüz Türkçe ve İngilizce (cihaz diline göre, Profil'den değiştirilebilir).

## Yapı

| Klasör | İçerik |
|---|---|
| `app/` | Flutter uygulaması (iOS, Android, web) — Riverpod, go_router, supabase_flutter |
| `app/lib/core/` | Modeller, hafta/saat hesapları (`week.dart`), oturum, yönlendirme, ortak UI |
| `app/lib/features/` | `auth`, `availability` (haftalık ızgara), `circles`, `friends`, `plans`, `profile` |
| `app/lib/l10n/` | `app_tr.arb`, `app_en.arb` çevirileri |
| `supabase/migrations/` | Veritabanı şeması, satır seviyesi güvenlik (RLS) kuralları ve RPC'ler |
| `supabase/tests/` | Erişim kurallarını doğrulayan pgTAP testleri |

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

## Testler
```bash
cd app && flutter analyze && flutter test
```
Gerçek veritabanına karşı uçtan uca akış (kayıt → arkadaşlık → çevre → müsaitlik görünürlüğü → davet → plan),
`supabase start` çalışırken:
```bash
cd app && flutter test test/integration --dart-define=DATER_INTEGRATION=true
```

## Davet linkleri
Davet linki biçimi `dater://app/join/<KOD>`; uygulama Android ve iOS'ta `dater://` şemasını kaydeder.
Linki açan kişi giriş yapmamışsa önce giriş/kayıt ekranına, ardından otomatik olarak çevreye yönlendirilir.
Uygulamayı yüklememiş kişiler için web'de açılan (https) linkler bir alan adı gerektirir; şimdilik kod da mesajda paylaşılır
ve *Çevreler → Kodla katıl* ile girilebilir.
