import { themedPage } from "../utils/webTheme.js";

export const homePage = (req, res) => {
  const inner = `
      <div class="hero">
        <h1 class="hero-title">Maneki Neko</h1>
        <p class="hero-subtitle">Quản lý chi tiêu thông minh, đẹp và ngầu</p>
        <div class="cta">
          <a href="myapp://home" class="btn btn-gradient">Bắt đầu</a>
          <a href="/api" class="btn btn-dark">API JSON</a>
          <a href="/home/docs" class="btn btn-blue">Tài liệu API</a>
          <a href="/home/about" class="btn btn-amber">Giới thiệu</a>
          <a href="#join" class="btn btn-outline">Tham gia gia đình</a>
        </div>
      </div>

      <div class="feature-grid">
        <div class="feature-card">
          <div class="feature-title purple">Theo dõi giao dịch</div>
          <div class="feature-desc">Ghi nhận thu chi nhanh, phân loại thông minh.</div>
        </div>
        <div class="feature-card">
          <div class="feature-title pink">Ngân sách & Mục tiêu</div>
          <div class="feature-desc">Đặt hạn mức, theo dõi tiến độ đạt mục tiêu.</div>
        </div>
        <div class="feature-card">
          <div class="feature-title black">Gia đình thông minh</div>
          <div class="feature-desc">Chia sẻ ví, ngân sách, cùng quản lý chi tiêu.</div>
        </div>
        <div class="feature-card">
          <div class="feature-title green">Phân tích trực quan</div>
          <div class="feature-desc">Biểu đồ, xu hướng, thống kê theo thời gian.</div>
        </div>
      </div>

      <div id="join" class="join">
        <div class="hero">
          <div class="feature-title">Tham gia gia đình bằng mã mời</div>
          <div class="hero-subtitle">Dùng link từ email hoặc nhập thủ công bên dưới</div>
        </div>
        <form action="/api/family/join-web" method="GET" class="form">
          <input name="email" type="email" placeholder="Email của bạn" required class="input" />
          <input name="familyCode" type="text" placeholder="Mã mời gia đình" required class="input" />
          <button type="submit" class="button btn-gradient">Tham gia ngay</button>
        </form>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">Tài liệu API v1</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs/auth" class="btn btn-blue">Xác thực</a>
          <a href="/home/docs/user" class="btn btn-dark">Người dùng</a>
          <a href="/home/docs/transaction" class="btn btn-dark">Giao dịch</a>
          <a href="/home/docs/budget" class="btn btn-dark">Ngân sách</a>
          <a href="/home/docs/wallet" class="btn btn-dark">Ví tiền</a>
          <a href="/home/docs/goal" class="btn btn-dark">Mục tiêu</a>
          <a href="/home/docs/family" class="btn btn-dark">Gia đình</a>
          <a href="/home/docs/analytics" class="btn btn-dark">Phân tích</a>
          <a href="/home/docs/fcm" class="btn btn-dark">FCM</a>
          <a href="/home/docs/category" class="btn btn-dark">Danh mục</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="section-title">Hướng dẫn</div>
          <div class="feature-desc">Chọn một category ở trên để xem chi tiết endpoint, mẫu request và mẫu response.</div>
          <div class="feature-desc">Các route bảo vệ yêu cầu header: <code class="kbd">Authorization: Bearer &lt;token&gt;</code>.</div>
        </div>
        <div class="doc-card">
          <div class="section-title">Ví dụ nhanh</div>
          <pre class="codeblock">curl -X POST '${base}/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","password":"yourPassword"}'

curl -X GET '${base}/user/profile' \
  -H 'Authorization: Bearer <JWT_TOKEN>'</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/" class="btn btn-dark">Trang chủ</a>
        <a href="/api" class="btn btn-dark">API JSON</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsAuthPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Xác thực</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /auth/register</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "email": "user@example.com",
  "password": "yourPassword",
  "username": "username",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "android"
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Đăng ký thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">POST /auth/login</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "email": "user@example.com",
  "password": "yourPassword",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "ios"
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Đăng nhập thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">POST /auth/login/verify/google-id</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "idToken": "google-id-token",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "android"
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Đăng nhập thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">POST /auth/logout</div>
          <div class="feature-desc">Headers</div>
          <pre class="codeblock">Authorization: Bearer &lt;token&gt;</pre>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "deviceId": "device-123" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Đã đăng xuất thiết bị thành công" }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsUserPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Người dùng</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">GET /user/profile</div>
          <div class="feature-desc">Headers</div>
          <pre class="codeblock">Authorization: Bearer &lt;token&gt;</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Lấy profile thành công",
  "data": {
    "id": "...",
    "email": "user@example.com",
    "username": "username",
    "avatar": "null",
    "authProvider": "local|google|both",
    "hasPassword": true,
    "hasGoogleLinked": false,
    "family": null,
    "isFamilyAdmin": false
  }
}</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsTransactionPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Giao dịch</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /transaction/transactions</div>
          <div class="feature-desc">Headers</div>
          <pre class="codeblock">Authorization: Bearer &lt;token&gt;</pre>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "amount": 50000,
  "currency": "VND",
  "type": "expense",
  "categoryId": "...",
  "walletId": "...",
  "date": "2025-12-08T07:00:00.000Z",
  "description": "Ăn trưa",
  "paymentMethod": "cash",
  "inputType": "manual",
  "isShared": false
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Tạo giao dịch thành công",
  "data": {
    "id": "...",
    "userId": "...",
    "amount": 50000,
    "currency": "VND",
    "type": "expense",
    "categoryId": "...",
    "walletId": "...",
    "date": "2025-12-08T07:00:00.000Z",
    "description": "Ăn trưa",
    "paymentMethod": "cash",
    "inputType": "manual",
    "isShared": false
  }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">GET /transaction/transactions</div>
          <div class="feature-desc">Query</div>
          <pre class="codeblock">{ "from": "2025-12-01", "to": "2025-12-31", "type": "expense" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "OK", "data": [ ] }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">PUT /transaction/transactions/:id</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "description": "Ăn trưa với đồng nghiệp" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Cập nhật thành công", "data": { } }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">GET /transaction/transactions/chart-data</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "month": "2025-12", "type": "expense" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "OK", "data": { } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsBudgetPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Ngân sách</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /budget/</div>
          <div class="feature-desc">Headers</div>
          <pre class="codeblock">Authorization: Bearer &lt;token&gt;</pre>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "type": "monthly",
  "amount": 5000000,
  "categoryId": null,
  "periodStart": "2025-12-01T00:00:00.000Z",
  "periodEnd": "2025-12-31T23:59:59.000Z",
  "isShared": false
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Tạo ngân sách thành công",
  "data": { "id": "...", "type": "monthly", "amount": 5000000, "spentAmount": 0 }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">GET /budget/</div>
          <div class="feature-desc">Query</div>
          <pre class="codeblock">{ "isActive": true, "type": "monthly", "page": 1, "limit": 10 }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "OK", "data": [ ] }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">GET /budget/:id</div>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "OK", "data": { "id": "...", "childBudgets": [ ], "summary": { } } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsWalletPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Ví tiền</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /wallet/</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "name": "Ví chính",
  "balance": 2000000,
  "currency": "VND",
  "isShared": false
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Tạo ví thành công",
  "data": { "id": "...", "name": "Ví chính", "balance": 2000000, "currency": "VND" }
}</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">POST /wallet/transfer</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "fromWalletId": "...", "toWalletId": "...", "amount": 100000 }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Chuyển tiền thành công", "data": { } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsGoalPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Mục tiêu</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /goal/</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{
  "name": "Du lịch Đà Nẵng",
  "targetAmount": 30000000,
  "deadline": "2026-06-01T00:00:00.000Z",
  "description": "Đi biển",
  "associatedWallets": []
}</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{
  "message": "Tạo mục tiêu thành công",
  "goal": { "id": "...", "name": "Du lịch Đà Nẵng", "currentProgress": 0, "status": "active" }
}</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsFamilyPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Gia đình</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">GET /family/join-web</div>
          <div class="feature-desc">Query</div>
          <pre class="codeblock">{ "email": "user@example.com", "familyCode": "ABCDEF" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Tham gia gia đình thành công", "data": { } }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">POST /family/invite</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "email": "member@example.com", "familyId": "..." }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Đã gửi lời mời", "data": { } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsAnalyticsPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Phân tích</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">GET /analytics/overview</div>
          <div class="feature-desc">Headers</div>
          <pre class="codeblock">Authorization: Bearer &lt;token&gt;</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "OK", "data": { } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsFcmPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: FCM</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /fcm/register-fcm-token</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "fcmToken": "...", "deviceId": "device-123", "platform": "android" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Đăng ký FCM thành công" }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const docsCategoryPage = (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div class="hero">
        <h2 class="section-title">API: Danh mục</h2>
        <div class="muted">Base URL: <code class="kbd">${base}</code></div>
        <div class="links" style="margin-top:12px">
          <a href="/home/docs" class="btn btn-amber">Tổng quan</a>
        </div>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="feature-title">POST /category/</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "name": "Ăn uống", "icon": "🍜" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Tạo danh mục thành công", "data": { } }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">GET /category/</div>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Lấy danh mục thành công", "data": [ ] }</pre>
        </div>
        <div class="doc-card">
          <div class="feature-title">PUT /category/:id</div>
          <div class="feature-desc">Body</div>
          <pre class="codeblock">{ "name": "Ăn uống", "icon": "🍱" }</pre>
          <div class="feature-desc">Response</div>
          <pre class="codeblock">{ "message": "Cập nhật danh mục thành công", "data": { } }</pre>
        </div>
      </div>

      <div class="links" style="margin-top:18px">
        <a href="/home/docs" class="btn btn-dark">Tổng quan</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
export const aboutPage = (req, res) => {
  const inner = `
      <div class="hero">
        <h2 class="section-title">Giới thiệu Maneki Neko</h2>
        <p class="hero-subtitle">Nền tảng quản lý chi tiêu cá nhân và gia đình, tập trung vào trải nghiệm nhanh, đẹp, và thông minh.</p>
      </div>

      <div class="doc-grid">
        <div class="doc-card">
          <div class="section-title">Tính năng chính</div>
          <ul style="margin:0;padding-left:18px;color:#374151;line-height:1.6">
            <li>Ghi giao dịch, phân loại thông minh</li>
            <li>Ngân sách theo ngày/tuần/tháng và mục tiêu</li>
            <li>Gia đình: chia sẻ ví, ngân sách, dữ liệu</li>
            <li>Phân tích trực quan: biểu đồ, xu hướng</li>
            <li>Thông báo đẩy, email mời tham gia</li>
          </ul>
        </div>
        <div class="doc-card">
          <div class="section-title">Công nghệ</div>
          <ul style="margin:0;padding-left:18px;color:#374151;line-height:1.6">
            <li>Backend: Express v5, Mongoose</li>
            <li>Bảo mật: JWT, Helmet, CORS</li>
            <li>Hiệu suất: Compression, logging morgan</li>
          </ul>
        </div>
        <div class="doc-card">
          <div class="section-title">Đường dẫn nhanh</div>
          <div class="links">
            <a href="/" class="btn btn-dark">Trang chủ</a>
            <a href="/home/docs" class="btn btn-blue">Tài liệu API</a>
            <a href="/api" class="btn btn-dark">API JSON</a>
          </div>
        </div>
      </div>
    `;
  res.status(200).send(themedPage(inner));
}
