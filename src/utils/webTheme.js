export const themedPage = (inner) => `
  <div style="background:linear-gradient(135deg,#7c3aed,#ec4899);padding:32px;font-family:Arial,sans-serif">
    <div style="max-width:640px;margin:auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 12px 28px rgba(124,58,237,0.25)">
      <div style="background:linear-gradient(135deg,#8b5cf6,#f472b6);color:#ffffff;text-align:center;padding:24px 16px">
        <div style="font-size:12px;letter-spacing:1px;opacity:.9">MANEKI NEKO</div>
      </div>
      <div style="padding:24px">${inner}</div>
    </div>
  </div>`;

