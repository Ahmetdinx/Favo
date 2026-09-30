import AccountDialog from './auth/AccountDialog'

function Brand() {
  return <a className="brand" href="/" aria-label="Favo ana sayfa"><span className="brand-mark" /><span>favo</span></a>
}

function Arrow() { return <span aria-hidden="true">↗</span> }

const upcoming = [
  { id: 'film', name: 'Film', icon: '01', art: <div className="film-art"><div className="film-frame"><span>F</span></div><div className="film-frame"><span>▶</span></div><div className="film-frame"><span>F</span></div></div> },
  { id: 'series', name: 'Dizi', icon: '02', art: <div className="series-art"><i /><i /><i><span>•••</span><b>DEVAM<br />EDECEK.</b></i></div> },
  { id: 'anime', name: 'Anime', icon: '03', art: <div className="anime-art"><i className="orbit" /><i className="sun" /><span>✦</span><b>✧</b></div> },
  { id: 'manga', name: 'Çizgi Roman / Manga', icon: '04', art: <div className="manga-art"><i /><i><span>!</span></i><i>✴</i></div> },
]

export default function App() {
  const knownPage = window.location.pathname === '/' || window.location.pathname === '/index.html'
  return <>
    <a className="skip-link" href="#main">İçeriğe geç</a>
    <header className="header"><Brand /><nav aria-label="Ana gezinme"><a className="explore-link" href="/#worlds">Keşfet</a><AccountDialog /></nav></header>
    <main id="main">
      {!knownPage ? <section className="not-found"><p className="eyebrow">BURADA BİR SAYFA YOK</p><h1>Yeni bir başlangıç?</h1><a className="primary" href="/">Favo’ya dön <Arrow /></a></section> : <>
        <section className="hero" aria-labelledby="hero-title"><div><h1 id="hero-title">Bir sonraki<br /><em>favorini</em> bul<span className="period">.</span></h1></div><div className="hero-note" aria-hidden="true"><span className="hero-mark" /></div></section>
        <section id="worlds" aria-labelledby="worlds-title"><div className="section-heading"><h2 id="worlds-title">Keşfet</h2></div><div className="world-grid">
          <a className="book-card" href="/go/books"><div className="card-top"><span className="live"><i /> KEŞFE AÇIK</span><Arrow /></div><div className="book-art" aria-hidden="true"><div className="book-shadow" /><div className="book-back" /><div className="book-cover"><span>FAVO KOLEKSİYONU</span><strong>Bir<br />başka<br /><em>dünya.</em></strong><div className="cover-shape" /><small>HER SAYFA BİR BAŞLANGIÇ</small></div><span className="book-spark">✳</span></div><div className="book-copy"><h3>Kitap</h3><span className="book-cta">Kitap’ı keşfet <span aria-hidden="true">→</span></span></div></a>
          {upcoming.map(world => <article className={`world-card ${world.id}`} key={world.id} aria-label={`${world.name}, yakında`}><div className="card-top"><span className="mini-label">{world.icon}</span><span className="soon">Yakında</span></div><div className="art" aria-hidden="true">{world.art}</div><div className="world-copy"><h3>{world.name}</h3></div></article>)}
        </div></section>
      </>}
    </main>
    <footer><Brand /><span>© {new Date().getFullYear()} Favo</span></footer>
  </>
}
