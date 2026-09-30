# Ortak Favo kimliği — uygulanan sözleşme

30 Eylül 2026. İlk sürümün yalnızca harici Kitap bağlantısı veren yaklaşımı yerine,
Favo ve mevcut Favo.Books ön yüzü **tek origin** altında birleştirildi:

- `/`: Favo ana ekranı ve gerçek e-posta/parola girişi.
- `/kitap/`: Favo.Books'un kendi kaynaklarından derlenen uygulama.
- `/api/*`: YARP ile mevcut Kitap API'sine iletilen istekler.
- `/go/books`: token içermeyen, allowlist ile `/kitap/...` yönlendirmesi.

## Kimlik ve veri korunması

Mevcut Identity modülü tek yetkilidir. Favo parola doğrulamaz, JWT imzalamaz ve
kullanıcı tablosu tutmaz. HttpOnly + Secure + SameSite=Lax, `/api/identity` yoluna
ait mevcut refresh çerezi aynen korunur. Erişim JWT'si yalnızca ilgili sayfanın
React belleğinde tutulur. URL, localStorage veya BroadcastChannel ile token taşınmaz.

Favo'da başarılı giriş çerezi oluşturur; Kitap açıldığında mevcut refresh endpoint'i
aynı origin çerezini kullanarak aynı UserId için erişim belirteci üretir. YARP kendi
cookie jar'ını kullanmaz; cookie ve Set-Cookie başlıklarını istemciye aktarır.
Giriş/refresh/çıkış istekleri Web Locks ile aynı origin sekmeleri arasında sıraya alınır.
Bu, mevcut refresh-token rotation ve replay-family-revocation davranışını korur.
Modern, güvenli context destekli tarayıcı gerekir (yerel localhost desteklenir).

BroadcastChannel yalnızca login/logout bildirimi taşır; kendi belgesi kaynaklı
bildirim atlanır. Diğer sekmeler girişte yeniden doğrular, çıkışta bellek oturumunu
kapatır. Yalnızca bildirim amaçlı localStorage fallback'i kimlik veya token tutmaz.
Back/forward cache dönüşünde oturum yeniden doğrulanır. Başarısız logout başarılıymış
gibi gizlenmez; kullanıcıya tekrar deneme hatası gösterilir.

## İstek güvenliği

Gateway tüm API mutation isteklerinde tam yapılandırılmış `Portal:Origin` eşleşmesini
zorunlu tutar ve `Sec-Fetch-Site: cross-site` isteklerini reddeder. Eksik/null origin
kabul edilmez. Sibling subdomain de yetkili sayılmaz. GET/HEAD dışındaki CLI testleri
Origin başlığı göndermelidir. API yanıtları private/no-store'dur.

Backend adresi kullanıcı girdisinden alınmaz; sunucu yapılandırmasından gelir.
Üretimde HTTPS origin gerekir. `/go/books` yalnızca katalog, profil, kök ve GUID
biçimindeki kitap ayrıntısına izin verir; dış URL/query/fragment kabul etmez.
Kitap ProtectedRoute iç dönüş yolunda query/fragment'i de korur. Public kitap
ayrıntıları eskisi gibi doğrudan açılır. Kopyalanan okur linkleri BASE_URL kullanır.

## Sınırlar

Bu sürüm **aynı origin üzerinde ortak giriş** sağlar. Ayrı alan adlarına dağıtılmış
OIDC SSO değildir. İleride farklı origin'ler istenirse mevcut kullanıcı kaynağını
koruyan standart OIDC Authorization Code + PKCE entegrasyonu gerekir; tarayıcı
çerez domain'ini genişleterek veya URL'ye JWT ekleyerek geçiş yapılmamalıdır.

Çıkış mevcut tarayıcı oturumunu ve refresh zincirini kapatır. Önceden verilmiş
JWT'lerin sunucu tarafındaki geçerliliği mevcut Kitap politikasındaki süresiyle
sınırlıdır; tüm cihazlardan çıkış/token blacklist özelliği eklenmedi. Kitap'ın
opsiyonel Google girişi ortak origin'e uygun Client ID yapılandırması gerektirir;
Google ile gerçek E2E yapılmadı. Ana Favo formu mevcut e-posta/parola hesaplarını kullanır.

## Uygulama kapsamı

Kitap'ta yalnızca ön yüz dosyaları değiştirildi: router basename, oturum taşıma
yardımcısı/context, giriş çağrıları, korumalı dönüş yolu, Favo bağlantısı, çıkış
hatası ve paylaşılan profil linki. Mevcut logo/Docker değişiklikleri korundu.
Veritabanı şeması, kullanıcı verileri, JWT anahtarları ve UserSecretsId değiştirilmedi.
Değişiklik öncesi dosyalar Favo `artifacts/books-backup-*` altında saklandı.

YARP uygulaması Microsoft'un [direct forwarding belgesine](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/direct-forwarding?view=aspnetcore-10.0)
dayanır. Test API'si .NET 10 [WebApplicationFactory.UseKestrel](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.mvc.testing.webapplicationfactory-1.usekestrel?view=aspnetcore-10.0)
ile gerçek loopback HTTP sunucusunda çalışır.
