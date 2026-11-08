# Favo ortak giriş

Favo’da e-posta/parola ile giriş yaptıktan sonra **Kitap’ı keşfet** bağlantısı,
mevcut Favo.Books uygulamasını aynı oturumla `/kitap/catalog` altında açar.
Film kartı yeni **Favo.Movie** uygulamasını `/film/` altında açar.
Dizi, Anime ve Manga hâlâ Yakında durumundadır.

## Favo.Movie başlangıcı

Proje: `C:\Users\ahmet\source\repos\Favo.Movie\Favo.Movie.slnx`.
Koyu sinema teması, katalog arama/filtreleme, film detayları ve ortak hesap arayüzü hazırdır.
Film profili, sinema avatarları, izleme listeleri, yedi ölçütlü değerlendirme,
kullanıcı arama ve ortak takip ağı eklendi. Ana sayfada takip edilenlerin izledikleri,
takipçilerin film puanları ve kişiselleştirilmiş öneriler bulunur.
Kitap API'sindeki iki yeni okuma ucu nedeniyle **Kitap ve Film backend'lerini yeniden başlatın**.
Film verileri Movie API'nin `App_Data/movie.db` SQLite dosyasında kalıcıdır;
bu dosya Git'e ve yayın paketine dahil edilmemelidir. Yayında kalıcı bir dizin için
`Movie__DatabasePath`, hesap servisi için `Identity__ApiOrigin` ayarlayın.

Film API'si 5130 portunda çalışır. `Start-Favo.ps1` Film ön yüzünü de derler ve
API çalışmıyorsa başlatır. Farklı klasör için `-MovieRoot` parametresini kullanın.
Filmleri yüklemek için TMDB API Read Access Token değerini yerelde kaydedin:

```powershell
cd 'C:\Users\ahmet\source\repos\Favo.Movie'
dotnet user-secrets set 'Tmdb:ReadAccessToken' 'BURAYA_READ_ACCESS_TOKEN' --project src/backend/Favo.Movie.Api
```

Ardından uygulamayı yeniden başlatın. Anahtar yalnızca backend'de tutulur.
Anahtar olmadan katalog hazırlık ekranı gösterilir; gerçek TMDB bağlantısı henüz doğrulanmadı.
Film için ortak giriş adresi `http://localhost:5175/film/`.
API'yi ayrı çalıştırmak için:

```powershell
dotnet run --project 'C:\Users\ahmet\source\repos\Favo.Movie\src\backend\Favo.Movie.Api'
```

## Tek komutla çalıştırma

Docker Desktop açık olmalı; mevcut `favo-kitap-postgres` veritabanı çalışmalı.
Favo klasöründe PowerShell:

```powershell
.\Start-Favo.ps1
```

Bu komut Kitap ön yüzünü `/kitap/` için derler, mevcut Kitap API çalışmıyorsa başlatır,
Favo API ve ön yüzünü başlatır. Adres **http://localhost:5175**.
Kitap API 5117, Favo API 5120 portunda. Kitap ön yüzü Favo tarafından sunulduğu için
ortak giriş testi sırasında ayrı 5173 ön yüzü başlatmak gerekmez.
Ctrl+C yalnızca betiğin başlattığı süreçleri kapatır; önceden çalışan Kitap API korunur.
Docker veritabanını başlatmaz, sıfırlamaz veya migration çalıştırmaz.

Kitap başka klasördeyse:

```powershell
.\Start-Favo.ps1 -BooksRoot 'C:\Users\ahmet\source\repos\KitapKivo'
```

Klasör adı ileride `Favo Kitap` olursa betik onu da otomatik bulur.

## Frontend ve backend ayrı terminallerde

Önce Favo kökünde bir kez (Kitap frontend değişikliklerinden sonra tekrar):

```powershell
.\scripts\Build-Books.ps1 -BooksRoot 'C:\Users\ahmet\source\repos\KitapKivo'
```

Terminal 1 — Kitap backend:

```powershell
cd 'C:\Users\ahmet\source\repos\KitapKivo'
dotnet run --project .\src\backend\Api\Favo.Books.Api --launch-profile http
```

Terminal 2 — Favo backend:

```powershell
cd 'C:\Users\ahmet\OneDrive\Belgeler\ChatGPT\Favo'
dotnet run --project .\src\backend\Favo.Api
```

Terminal 3 — Favo frontend:

```powershell
cd 'C:\Users\ahmet\OneDrive\Belgeler\ChatGPT\Favo\src\frontend'
npm ci
npm run dev
```

Bu üç terminalle **http://localhost:5175** üzerinden her iki uygulamayı test edin.
Kitap bağımsız geliştirme ekranına ayrıca ihtiyaç duyarsanız:

```powershell
cd 'C:\Users\ahmet\source\repos\KitapKivo\src\frontend'
npm run dev -- --port 5173 --strictPort
```

5173 bağımsız geliştirme adresidir. Ortak giriş ve sekmeler arası çıkış testleri
5175 origin'i altındaki `/` ve `/kitap/` üzerinde yapılmalıdır. İki farklı origin'i
aynı anda kullanmak desteklenen ortak oturum topolojisi değildir.

## Kontroller

```powershell
dotnet build Favo.slnx
dotnet run --project tests/Favo.Checks
npm --prefix src/frontend run build
npm --prefix src/frontend run lint
```

27 yönlendirme, CSRF ve adres yapılandırma kontrolü çalıştırılabilir test projesindedir.
`dotnet test` keşfine dahil değildir. Gerçek tarayıcı ve 20 HTTP kontrolünün yöntemi
ve sonuçları: [docs/shared-auth-testing.md](docs/shared-auth-testing.md).

## Oturum mimarisi ve yayın

Mevcut Kitap Identity modülü tek kullanıcı kaynağıdır. Kullanıcı tablosu, parolalar,
UserId, UserSecretsId, JWT ayarları ve mevcut çerez adı değişmez. Favo aynı origin
üzerinden API'ye yönlendirir. Ayrı kullanıcı deposu ya da URL ile token aktarımı yoktur.
Teknik ayrıntılar: [docs/shared-identity.md](docs/shared-identity.md).

Visual Studio çözümü `Favo.slnx`. F5 Favo API'yi açar; Kitap derlemesi ve API'si
önceden hazır olmalıdır. Tüm sistem için Start-Favo.ps1 kullanın.

Yayınlamak için çalışan Favo önizlemesini durdurun (Windows npm dosya kilitleri):

```powershell
.\Publish-Favo.ps1 -BooksRoot 'C:\Users\ahmet\source\repos\KitapKivo'
```

İki ön yüz `artifacts/publish/wwwroot` altında paketlenir. Üretimde
`Portal__Origin=https://FAVO-ADRESI`, `Books__ApiOrigin=https://KITAP-API-ADRESI`
ve `AllowedHosts` ayarlanmalı. HTTPS gateway ve backend bağlantısı zorunludur;
loopback HTTP yalnızca Development ortamında kabul edilir. Gateway sunucusundan
Kitap API erişilebilir olmalı; API'yi kullanıcıya doğrudan yayınlamak gerekmez.
Google girişi Kitap'taki mevcut isteğe bağlı yapılandırmadır; yeni origin Google
istemcisine eklenmeden bu özellik çalışmış sayılmaz. Ana Favo girişi e-posta/paroladır.
