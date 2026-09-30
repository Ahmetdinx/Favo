# Ortak giriş test raporu — 30 Eylül 2026

## Ortam

Gerçek Favo gateway ve ön yüzü, gerçek Favo.Books API ve ön yüzü kullanıldı.
Favo.E2eHost, Books API'yi WebApplicationFactory.UseKestrel ile 5118 portunda açtı.
Testcontainers ayrı PostgreSQL 18.4 konteyneri oluşturdu; mevcut Kitap migration'ları
sadece bu boş geçici DB'ye uygulandı. Test hesabı yalnızca orada oluşturuldu.
Gerçek favo-kitap-postgres veritabanına test kullanıcısı veya kitap yazılmadı.
Test hostu kapatıldıktan sonra Docker listesinde yalnızca sağlıklı gerçek Kitap
konteyneri kaldığı doğrulandı.

## Sonuçlar

- Favo .NET çözümü: 0 hata / 0 uyarı.
- Favo ve Books ön yüzleri: production build ve oxlint başarılı.
- Favo + Books yayın paketi Publish-Favo.ps1 ile başarılı.
- 27 yönlendirme, izinli origin ve CSRF kontrolü geçti.
- 20 gerçek HTTP entegrasyon kontrolü geçti: kötü origin, eksik origin, cross-site,
  yanlış parola, login, cookie Secure/HttpOnly/SameSite/path, no-store, UserId,
  Books SPA deep-link fallback, token'sız aynı-origin geçişi, open redirect,
  refresh rotation, eski token replay/family revocation, tekrar login ve logout.
- Tarayıcı: Favo formunda yanlış parola hatası; başarılı giriş; Kitap kartından
  authenticated katalog; kullanıcı adı görünen profil; yenilemede oturum korunması;
  Favo'ya dönüş; iki sekmenin aynı anda yenilenmesi başarılı.
- Tarayıcı: Kitap logout → diğer Favo sekmesi misafir; Favo logout → diğer korumalı
  Kitap sekmesi login sayfasına geçiyor.
- Tarayıcı: /kitap/profile?from=favo#kitapligim misafir bağlantısı login ister;
  giriş sonrası query ve fragment dahil aynı hedefe döner.
- Başarılı test profilinin görsel görünümü incelendi.

Kapsam sınırı: Google Client ID ile gerçek Google E2E yapılmadı. İki ayrı public
origin'de OIDC SSO test edilmedi; bu uygulamanın topolojisi tek origin'dir.
Tam kitap öneri/katalog/puanlama regresyon paketi bu değişikliğin kapsamı değildir.

## Otomatik kontrolleri tekrar çalıştırma

Favo kökünde normal doğrulama:

```powershell
dotnet build Favo.slnx
dotnet run --project tests/Favo.Checks
npm --prefix src/frontend run build
npm --prefix src/frontend run lint
npm --prefix C:/Users/ahmet/source/repos/KitapKivo/src/frontend run lint
```

İzole test ortamı için önce normal Favo sunucularını kapatın. Terminal 1:

```powershell
$env:FAVO_BOOKS_ROOT = 'C:\Users\ahmet\source\repos\KitapKivo'
dotnet run --project tests/Favo.E2eHost -p:BooksRoot=C:/Users/ahmet/source/repos/KitapKivo
```

READY mesajından sonra terminal 2:

```powershell
.\Start-Favo.ps1 -NoBrowser -BooksApiOrigin http://127.0.0.1:5118 -SkipBooksApiStart
```

Terminal 3:

```powershell
node tests/shared-auth-http.mjs
```

Bu HTTP betiğini yalnızca izole test ortamında çalıştırın. Tarayıcı senaryolarını
http://localhost:5175 adresinde test hostu kaynak kodundaki geçici hesapla uygulayın.
İş bitince iki sunucu terminalinde Ctrl+C. Test konteynerleri otomatik kaldırılır.
Normal verilerle devam etmek için standart .\Start-Favo.ps1 komutunu kullanın.
