import helmet from "helmet";
import express from "express";
import morgan from "morgan";
import cors from "cors";
import compression from "compression";
import apiRouter from "./src/routers/mainApi.route.js";
import { connectToDatabase } from "./mongo.js";
import { themedPage } from "./src/utils/webTheme.js";

const app = express();
connectToDatabase()

app.set("port", process.env.PORT || 4000);
app.set("env", "development");
app.set("json spaces", 4);

app.use(cors({
  origin: '*',
  credentials: true,
}));
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(compression());

app.get("/", (req, res) => {
  const inner = `
      <div style="text-align:center">
        <h1 style="margin:0 0 10px;font-size:40px;line-height:1.1;color:#111827">Maneki Neko</h1>
        <p style="margin:0 0 18px;color:#6b7280;font-size:16px">Quản lý chi tiêu thông minh, đẹp và ngầu</p>
        <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:12px">
          <a href="myapp://home" style="display:inline-block;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;padding:12px 20px;text-decoration:none;border-radius:9999px;font-weight:bold">Bắt đầu</a>
          <a href="/api" style="display:inline-block;background:#111827;color:#fff;padding:12px 20px;text-decoration:none;border-radius:9999px;font-weight:bold">API JSON</a>
          <a href="/docs" style="display:inline-block;background:#0ea5e9;color:#fff;padding:12px 20px;text-decoration:none;border-radius:9999px;font-weight:bold">Tài liệu API</a>
          <a href="/about" style="display:inline-block;background:#f59e0b;color:#fff;padding:12px 20px;text-decoration:none;border-radius:9999px;font-weight:bold">Giới thiệu</a>
          <a href="#join" style="display:inline-block;background:#ffffff;color:#111827;padding:12px 20px;text-decoration:none;border-radius:9999px;font-weight:bold;border:1px solid #e5e7eb">Tham gia gia đình</a>
        </div>
      </div>

      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px;margin-top:24px">
        <div style="background:rgba(124,58,237,0.06);border:1px solid rgba(124,58,237,0.25);border-radius:14px;padding:16px">
          <div style="font-size:18px;font-weight:700;color:#7c3aed;margin-bottom:6px">Theo dõi giao dịch</div>
          <div style="color:#374151;font-size:14px">Ghi nhận thu chi nhanh, phân loại thông minh.</div>
        </div>
        <div style="background:rgba(236,72,153,0.06);border:1px solid rgba(236,72,153,0.25);border-radius:14px;padding:16px">
          <div style="font-size:18px;font-weight:700;color:#ec4899;margin-bottom:6px">Ngân sách & Mục tiêu</div>
          <div style="color:#374151;font-size:14px">Đặt hạn mức, theo dõi tiến độ đạt mục tiêu.</div>
        </div>
        <div style="background:rgba(17,24,39,0.06);border:1px solid rgba(17,24,39,0.2);border-radius:14px;padding:16px">
          <div style="font-size:18px;font-weight:700;color:#111827;margin-bottom:6px">Gia đình thông minh</div>
          <div style="color:#374151;font-size:14px">Chia sẻ ví, ngân sách, cùng quản lý chi tiêu.</div>
        </div>
        <div style="background:rgba(34,197,94,0.06);border:1px solid rgba(34,197,94,0.25);border-radius:14px;padding:16px">
          <div style="font-size:18px;font-weight:700;color:#22c55e;margin-bottom:6px">Phân tích trực quan</div>
          <div style="color:#374151;font-size:14px">Biểu đồ, xu hướng, thống kê theo thời gian.</div>
        </div>
      </div>

      <div id="join" style="margin-top:28px">
        <div style="text-align:center;margin-bottom:12px">
          <div style="font-size:18px;font-weight:700;color:#111827">Tham gia gia đình bằng mã mời</div>
          <div style="color:#6b7280;font-size:14px">Dùng link từ email hoặc nhập thủ công bên dưới</div>
        </div>
        <form action="/api/family/join-web" method="GET" style="max-width:520px;margin:0 auto;display:grid;gap:10px">
          <input name="email" type="email" placeholder="Email của bạn" required style="padding:12px;border-radius:10px;border:1px solid #e5e7eb;outline:none" />
          <input name="familyCode" type="text" placeholder="Mã mời gia đình" required style="padding:12px;border-radius:10px;border:1px solid #e5e7eb;outline:none" />
          <button type="submit" style="padding:12px;border:none;border-radius:12px;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;font-weight:700">Tham gia ngay</button>
        </form>
      </div>
    `;
  res.status(200).send(themedPage(inner));
});

app.get("/about", (req, res) => {
  const inner = `
      <div style="text-align:center">
        <h2 style="margin:0 0 8px;color:#111827">Giới thiệu Maneki Neko</h2>
        <p style="color:#6b7280">Nền tảng quản lý chi tiêu cá nhân và gia đình, tập trung vào trải nghiệm nhanh, đẹp, và thông minh.</p>
      </div>

      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px;margin-top:18px">
        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Tính năng chính</div>
          <ul style="margin:0;padding-left:18px;color:#374151;line-height:1.6">
            <li>Ghi giao dịch, phân loại thông minh</li>
            <li>Ngân sách theo ngày/tuần/tháng và mục tiêu</li>
            <li>Gia đình: chia sẻ ví, ngân sách, dữ liệu</li>
            <li>Phân tích trực quan: biểu đồ, xu hướng</li>
            <li>Thông báo đẩy, email mời tham gia</li>
          </ul>
        </div>
        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Công nghệ</div>
          <ul style="margin:0;padding-left:18px;color:#374151;line-height:1.6">
            <li>Backend: Express v5, Mongoose</li>
            <li>Bảo mật: JWT, Helmet, CORS</li>
            <li>Hiệu suất: Compression, logging morgan</li>
          </ul>
        </div>
        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Đường dẫn nhanh</div>
          <div style="display:flex;gap:10px;flex-wrap:wrap">
            <a href="/" style="display:inline-block;background:#111827;color:#fff;padding:10px 16px;border-radius:10px;text-decoration:none">Trang chủ</a>
            <a href="/docs" style="display:inline-block;background:#0ea5e9;color:#fff;padding:10px 16px;border-radius:10px;text-decoration:none">Tài liệu API</a>
            <a href="/api" style="display:inline-block;background:#111827;color:#fff;padding:10px 16px;border-radius:10px;text-decoration:none">API JSON</a>
          </div>
        </div>
      </div>
    `;
  res.status(200).send(themedPage(inner));
});

app.get("/docs", (req, res) => {
  const base = `${req.protocol}://${req.get('host')}/api`;
  const inner = `
      <div style="text-align:center">
        <h2 style="margin:0 0 8px;color:#111827">Tài liệu API v1</h2>
        <div style="color:#6b7280">Base URL: <code style="background:#f3f4f6;padding:2px 6px;border-radius:6px">${base}</code></div>
      </div>

      <div style="margin-top:18px;display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:16px">
        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Xác thực</div>
          <div style="color:#6b7280;margin-bottom:8px">Header cho route bảo vệ: <code>Authorization: Bearer &lt;token&gt;</code></div>
          <div style="font-weight:600;color:#111827">POST /auth/register</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "email": "user@example.com",
  "password": "yourPassword",
  "username": "username",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "android"
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Đăng ký thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
          <div style="font-weight:600;color:#111827">POST /auth/login</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "email": "user@example.com",
  "password": "yourPassword",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "ios"
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Đăng nhập thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
          <div style="font-weight:600;color:#111827">POST /auth/login/verify/google-id</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "idToken": "google-id-token",
  "deviceId": "device-123",
  "fcmToken": "token...",
  "platform": "android"
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Đăng nhập thành công",
  "data": { "userId": "...", "accessToken": "...", "expiresAt": 604800 }
}</pre>
          <div style="font-weight:600;color:#111827">POST /auth/logout</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "deviceId": "device-123" }</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "message": "Đã đăng xuất thiết bị thành công" }</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Người dùng</div>
          <div style="font-weight:600;color:#111827">GET /user/profile</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Lấy profile thành công",
  "data": {
    "id": "...",
    "email": "user@example.com",
    "username": "username",
    "avatar": "null",
    "authProvider": "local|google|both",
    "hasPassword": true,
    "hasGoogleLinked": false,
    "family": "null" | { "id": "...", "name": "...", "isAdmin": false, "memberCount": 2, "members": [ { "id": "...", "username": "...", "email": "...", "avatar": "null", "isAdmin": false } ] },
    "isFamilyAdmin": false
  }
}</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Giao dịch</div>
          <div style="font-weight:600;color:#111827">POST /transaction/transactions</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
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
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
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
          <div style="font-weight:600;color:#111827">GET /transaction/transactions</div>
          <div style="color:#6b7280">Query tuỳ chọn: filter theo thời gian, loại</div>
          <div style="font-weight:600;color:#111827;margin-top:8px">PUT /transaction/transactions/:id</div>
          <div style="color:#6b7280">Body giống tạo, chỉnh sửa các trường cần thiết</div>
          <div style="font-weight:600;color:#111827;margin-top:8px">GET /transaction/transactions/chart-data</div>
          <div style="color:#6b7280">Body: { month, type }</div>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Ngân sách</div>
          <div style="font-weight:600;color:#111827">POST /budget/</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "type": "monthly",
  "amount": 5000000,
  "categoryId": null,
  "periodStart": "2025-12-01T00:00:00.000Z",
  "periodEnd": "2025-12-31T23:59:59.000Z",
  "isShared": false
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Tạo ngân sách thành công",
  "data": { "id": "...", "type": "monthly", "amount": 5000000, "spentAmount": 0 }
}</pre>
          <div style="font-weight:600;color:#111827">GET /budget/</div>
          <div style="color:#6b7280">Query: isActive, isShared, type, page, limit</div>
          <div style="font-weight:600;color:#111827;margin-top:8px">GET /budget/:id</div>
          <div style="color:#6b7280">Trả về budget, childBudgets, summary</div>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Ví tiền</div>
          <div style="font-weight:600;color:#111827">POST /wallet/</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "name": "Ví chính",
  "balance": 2000000,
  "currency": "VND",
  "isShared": false
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Tạo ví thành công",
  "data": { "id": "...", "name": "Ví chính", "balance": 2000000, "currency": "VND" }
}</pre>
          <div style="font-weight:600;color:#111827">POST /wallet/transfer</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "fromWalletId": "...", "toWalletId": "...", "amount": 100000 }</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Mục tiêu</div>
          <div style="font-weight:600;color:#111827">POST /goal/</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "name": "Du lịch Đà Nẵng",
  "targetAmount": 30000000,
  "deadline": "2026-06-01T00:00:00.000Z",
  "description": "Đi biển",
  "associatedWallets": []
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "message": "Tạo mục tiêu thành công",
  "data": { "id": "...", "name": "Du lịch Đà Nẵng", "currentProgress": 0, "status": "active" }
}</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Gia đình</div>
          <div style="font-weight:600;color:#111827">POST /family/invite</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{
  "email": "member@example.com",
  "familyId": "..."
}</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "message": "Đã gửi lời mời tham gia gia đình" }</pre>
          <div style="font-weight:600;color:#111827">GET /family/join-web</div>
          <div style="margin:6px 0;color:#374151">Query</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">?familyCode=ABC123&email=user@example.com</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">Phân tích</div>
          <div style="font-weight:600;color:#111827">GET /analytics/overview</div>
          <div style="margin:6px 0;color:#374151">Headers</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">Authorization: Bearer &lt;token&gt;</pre>
          <div style="margin:6px 0;color:#374151">Response</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "message": "OK", "data": { /* thống kê tổng quan */ } }</pre>
        </div>

        <div style="background:#fff;border:1px solid #e5e7eb;border-radius:14px;padding:16px">
          <div style="font-weight:700;color:#111827;margin-bottom:6px">FCM & Danh mục</div>
          <div style="font-weight:600;color:#111827">POST /fcm/register-fcm-token</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "fcmToken": "...", "deviceId": "device-123", "platform": "android" }</pre>
          <div style="font-weight:600;color:#111827;margin-top:8px">POST /category/</div>
          <div style="margin:6px 0;color:#374151">Body</div>
          <pre style="background:#0b1021;color:#e5e7eb;padding:10px;border-radius:10px;overflow:auto">{ "name": "Ăn uống", "icon": "🍜" }</pre>
        </div>
      </div>

      <div style="margin-top:22px">
        <div style="font-weight:700;color:#111827">Ví dụ gọi API</div>
        <pre style="background:#0b1021;color:#e5e7eb;padding:12px;border-radius:12px;overflow:auto">curl -X POST '${base}/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"email":"user@example.com","password":"yourPassword"}'

curl -X GET '${base}/user/profile' \
  -H 'Authorization: Bearer <JWT_TOKEN>'
        </pre>
      </div>

      <div style="margin-top:18px;display:flex;gap:10px;flex-wrap:wrap">
        <a href="/" style="display:inline-block;background:#111827;color:#fff;padding:10px 16px;border-radius:10px;text-decoration:none">Trang chủ</a>
        <a href="/api" style="display:inline-block;background:#111827;color:#fff;padding:10px 16px;border-radius:10px;text-decoration:none">API JSON</a>
      </div>
    `;
  res.status(200).send(themedPage(inner));
});

app.use("/api", apiRouter);

app.use(/^\/api\/.*/, (req, res) => {
  res.status(404).json({
    status: "error",
    path: req.path,
    error: "Endpoint không tìm thấy",
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    status: "error",
    error: "Internal Server Error",
    err: err,
  });
});

export default app;
