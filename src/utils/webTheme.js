export const themedPage = (inner) => `
  <style>
    .gradient-bg { background: radial-gradient(1200px 700px at 20% -200px, rgba(255,107,214,.35), transparent), linear-gradient(135deg,#ff6bd6,#8b5cf6); min-height: 100vh; padding: 40px 24px; font-family: Arial, sans-serif; position: relative; }
    .ribbon { position: absolute; inset: 0 0 auto 0; height: 10px; background: linear-gradient(90deg,#ff6bd6,#ec4899,#7c3aed,#8b5cf6); background-size: 300% 100%; animation: slide 8s linear infinite; box-shadow: 0 6px 18px rgba(124,58,237,.35); border-bottom-left-radius: 12px; border-bottom-right-radius: 12px; }
    @keyframes slide { 0% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } 100% { background-position: 0% 50%; } }
    .blob { position: absolute; border-radius: 50%; filter: blur(60px); opacity: .35; animation: blobFloat 18s ease-in-out infinite; }
    .blob1 { width: 380px; height: 380px; left: -80px; top: 120px; background: linear-gradient(135deg,#ff6bd6,#f472b6); }
    .blob2 { width: 320px; height: 320px; right: -60px; bottom: 40px; background: linear-gradient(135deg,#7c3aed,#8b5cf6); animation-delay: 6s; }
    @keyframes blobFloat { 0% { transform: translate(0,0) } 50% { transform: translate(16px,-12px) } 100% { transform: translate(0,0) } }
    .card { max-width: 1040px; margin: 64px auto; background: #ffffff; border-radius: 22px; overflow: hidden; box-shadow: 0 24px 46px rgba(124,58,237,0.30); border: 1px solid rgba(124,58,237,0.15); }
    .card-head { background: radial-gradient(1200px 400px at 50% -200px, rgba(139,92,246,.28), transparent), linear-gradient(135deg,#8b5cf6,#f472b6); color: #ffffff; text-align: center; padding: 30px 20px; }
    .brand { font-size: 12px; letter-spacing: .12em; opacity: .92; }
    .cat { position: fixed; right: 24px; bottom: 24px; width: 120px; height: 120px; z-index: 50; filter: drop-shadow(0 8px 18px rgba(0,0,0,.25)); animation: float 3.6s ease-in-out infinite; }
    @keyframes float { 0% { transform: translateY(0) } 50% { transform: translateY(-6px) } 100% { transform: translateY(0) } }
    .paw { transform-origin: 83px 56px; animation: wave 2s ease-in-out infinite; }
    @keyframes wave { 0%,100% { transform: rotate(0deg) } 50% { transform: rotate(-18deg) } }
    .container { max-width: 960px; margin: 0 auto; padding: 24px; }
    .hero { text-align: center; }
    .hero-title { margin: 0 0 8px; font-size: 40px; line-height: 1.1; color: #111827; }
    .hero-subtitle { margin: 0 0 18px; color: #6b7280; font-size: 16px; }
    .cta { display: flex; gap: 10px; justify-content: center; flex-wrap: wrap; margin-top: 12px; }
    .btn { display: inline-block; padding: 12px 20px; border-radius: 9999px; font-weight: 700; text-decoration: none; }
    .btn-gradient { background: linear-gradient(135deg,#7c3aed,#ec4899); color: #fff; }
    .btn-dark { background: #111827; color: #fff; }
    .btn-blue { background: #0ea5e9; color: #fff; }
    .btn-amber { background: #f59e0b; color: #fff; }
    .btn-outline { background: #ffffff; color: #111827; border: 1px solid #e5e7eb; }
    .feature-grid { display: grid; grid-template-columns: repeat(auto-fit,minmax(220px,1fr)); gap: 16px; margin-top: 24px; }
    .feature-card { background: #ffffff; border: 1px solid rgba(17,24,39,.08); border-radius: 14px; padding: 16px; }
    .feature-title { font-size: 18px; font-weight: 700; color: #111827; margin-bottom: 6px; }
    .feature-desc { color: #374151; font-size: 14px; }
    .join { margin-top: 28px; }
    .input { padding: 12px; border-radius: 10px; border: 1px solid #e5e7eb; outline: none; }
    .form { max-width: 520px; margin: 0 auto; display: grid; gap: 10px; }
    .doc-grid { margin-top: 18px; display: grid; grid-template-columns: repeat(auto-fit,minmax(320px,1fr)); gap: 16px; }
    .doc-card { background: #fff; border: 1px solid #e5e7eb; border-radius: 14px; padding: 16px; }
    .section-title { font-weight: 700; color: #111827; margin-bottom: 6px; }
    .kbd { display: inline-block; background: #0b1021; color: #e5e7eb; padding: 6px 10px; border-radius: 10px; font-size: 12px; }
    .codeblock { background: #0b1021; color: #e5e7eb; padding: 10px; border-radius: 10px; overflow: auto; }
  </style>
  <div class="gradient-bg">
    <div class="ribbon"></div>
    <div class="blob blob1"></div>
    <div class="blob blob2"></div>
    <svg viewBox="0 0 120 120" class="cat" aria-hidden="true">
      <defs>
        <linearGradient id="fur" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#fff7f9"/>
          <stop offset="100%" stop-color="#ffe4ec"/>
        </linearGradient>
        <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="0%">
          <stop offset="0%" stop-color="#ff6bd6"/>
          <stop offset="100%" stop-color="#8b5cf6"/>
        </linearGradient>
      </defs>
      <circle cx="60" cy="70" r="36" fill="url(#fur)" stroke="#e5e7eb" stroke-width="1"/>
      <circle cx="60" cy="48" r="20" fill="url(#fur)" stroke="#e5e7eb" stroke-width="1"/>
      <path d="M46 34 L52 22 L58 34" fill="#ffe4ec" stroke="#e5e7eb" stroke-width="1"/>
      <path d="M62 34 L68 22 L74 34" fill="#ffe4ec" stroke="#e5e7eb" stroke-width="1"/>
      <circle cx="52" cy="48" r="3" fill="#111827"/>
      <circle cx="68" cy="48" r="3" fill="#111827"/>
      <path d="M54 56 Q60 60 66 56" stroke="#111827" stroke-width="2" fill="none"/>
      <g class="paw">
        <ellipse cx="86" cy="56" rx="8" ry="10" fill="url(#fur)" stroke="#e5e7eb" stroke-width="1"/>
        <circle cx="86" cy="63" r="4" fill="#f59e0b"/>
      </g>
      <circle cx="60" cy="84" r="10" fill="url(#accent)"/>
      <text x="60" y="87" text-anchor="middle" font-size="9" fill="#ffffff" font-weight="700">福</text>
    </svg>
    <div class="card">
      <div class="card-head">
        <div class="brand">MANEKI NEKO</div>
      </div>
      <div class="container">${inner}</div>
    </div>
  </div>`;
