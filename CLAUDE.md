# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Favo; Kitap, Film ve ileride Dizi/Anime/Manga uygulamalarını tek adreste toplayan portal ve ağ geçididir. Kendi iş verisi veya kullanıcı tablosu yoktur.

## Komutlar

```powershell
dotnet build Favo.slnx
dotnet run --project tests/Favo.Checks          # 27 yönlendirme, CSRF ve yapılandırma kontrolü
npm --prefix src/frontend ci
npm --prefix src/frontend run build
npm --prefix src/frontend run lint
```

`tests/Favo.Checks` çalıştırılabilir bir projedir, `dotnet test` onu bulmaz. Filtre yoktur; ilk başarısız kontrolde durur. `tests/shared-auth-http.mjs` ve `tests/Favo.E2eHost` yöntemi `docs/shared-auth-testing.md` içindedir.

Çalıştırma için `.\Start-Favo.ps1 -BooksRoot <yol> -MovieRoot <yol>` kullanılır. Betik Books ve Movie ön yüzlerini derler, çalışmayan API'leri başlatır; günlükler `artifacts/run` altındadır. Yayın paketi `Publish-Favo.ps1` ile üretilir.

## Mimari

`src/backend/Favo.Api/Program.cs` ağ geçidinin tamamıdır:

- `/kitap` ve `/film` statik olarak diğer depoların derlenmiş ön yüzlerini sunar. Bunlar `artifacts/books` ve `artifacts/movie` altına derlenir; Movie yoksa portal yine açılır, Books yoksa açılışta hata verir.
- YARP doğrudan iletim kullanılır: `/api/movies/{**path}` Movie API'ye, kalan `/api/{**path}` Books API'ye gider. Yeni kategori eklerken özel rota, genel `/api` rotasından önce eşleşmelidir.
- Portal ön yüzü geliştirmede Vite üzerinden 5175'te çalışır ve API'yi 5120'ye iletir.
- `/go/books` ve `/go/movie` token taşımayan yönlendirmelerdir. Books hedefleri `BooksNavigation` izin listesinden geçer; dış URL, query veya fragment kabul edilmez.

### Güvenlik sınırları

- `PortalSecurity`: `/api` altındaki GET/HEAD dışındaki her istek, `Portal:Origin` ile tam eşleşen `Origin` ister ve `Sec-Fetch-Site: cross-site` reddedilir. CLI ile yapılan yazma testleri `Origin` göndermelidir.
- Proxy çerez deposu kullanmaz; `Cookie` ve `Set-Cookie` istemciyle Books arasında aynen geçer.
- Erişim JWT'si yalnızca sayfa belleğinde tutulur. URL'ye, localStorage'a veya BroadcastChannel'a token yazılmaz. Sekmeler arası yalnızca login/logout olayı taşınır; kimlik istekleri Web Locks ile sıraya alınır, aksi halde refresh-token rotasyonu oturumu iptal edebilir. Ayrıntılar: `docs/shared-identity.md`.
- Bu yapı tek origin için geçerlidir. Farklı alan adları gerekirse OIDC Authorization Code + PKCE gerekir; çerez alanını genişletmek veya URL ile JWT taşımak kabul edilmez.
- Üretimde `Portal__Origin`, `Books__ApiOrigin`, `Movie__ApiOrigin` HTTPS olmalı ve `AllowedHosts` ayarlanmalıdır; varsayılan yalnızca localhost'a izin verir.

`scripts/Integrate-Books.ps1` ve `scripts/books-changes.json` Books'a bir kez uygulanmış geçmiş entegrasyon adımlarıdır; yeni değişiklikler için kullanılmaz.
