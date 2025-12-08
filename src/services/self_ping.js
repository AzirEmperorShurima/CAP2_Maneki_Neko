import cron from "node-cron";
import https from "https";
import http from "http";

// URL server của bạn trên Render
const SERVER_URL = process.env.APP_URL || "https://cap2-maneki-neko.onrender.com";

// Parse URL để xác định protocol
const isHttps = SERVER_URL.startsWith("https");
const protocol = isHttps ? https : http;

/**
 * Hàm ping server để giữ nó active
 */
const pingServer = () => {
    const startTime = Date.now();

    console.log(`🏓 [${new Date().toLocaleString()}] Đang ping server: ${SERVER_URL}`);

    const request = protocol.get(SERVER_URL, (res) => {
        const duration = Date.now() - startTime;

        if (res.statusCode === 200) {
            console.log(`✅ Server phản hồi thành công (${res.statusCode}) - Thời gian: ${duration}ms`);
        } else {
            console.log(`⚠️ Server phản hồi với status: ${res.statusCode} - Thời gian: ${duration}ms`);
        }

        // Consume response data để tránh memory leak
        res.on('data', () => { });
        res.on('end', () => { });
    });

    request.on('error', (error) => {
        console.error(`❌ Lỗi khi ping server:`, error.message);
    });

    request.on('timeout', () => {
        console.error(`⏱️ Request timeout sau 30s`);
        request.destroy();
    });

    // Set timeout 30s
    request.setTimeout(30000);
};

/**
 * Khởi tạo cron job để ping server định kỳ
 */
export const initKeepAliveCron = () => {
    // Kiểm tra xem có nên chạy cron không (chỉ chạy trên production)
    const shouldRunCron = process.env.NODE_ENV === "production" ||
        process.env.ENABLE_KEEP_ALIVE === "true";

    if (!shouldRunCron) {
        console.log("ℹ️ Keep-alive cron job bị tắt (chỉ chạy trên production)");
        return;
    }

    if (!SERVER_URL || SERVER_URL.includes("your-app")) {
        console.error("⚠️ Cảnh báo: SERVER_URL chưa được cấu hình đúng!");
        console.error("   Vui lòng set biến môi trường SERVER_URL trong Render");
        return;
    }

    // Ping mỗi 14 phút (Render free tier sleep sau 15 phút không hoạt động)
    // Cron pattern: */14 * * * * = Mỗi 14 phút
    const cronSchedule = "*/14 * * * *";

    cron.schedule(cronSchedule, () => {
        pingServer();
    }, {
        scheduled: true,
        timezone: "Asia/Ho_Chi_Minh" // Đổi timezone phù hợp
    });

    console.log("🚀 Keep-alive cron job đã được khởi động!");
    console.log(`⏰ Schedule: Ping server mỗi 14 phút`);
    console.log(`🎯 Target URL: ${SERVER_URL}`);

    // Ping ngay lập tức khi khởi động
    setTimeout(() => {
        console.log("🎬 Thực hiện ping đầu tiên...");
        pingServer();
    }, 5000); // Đợi 5s để server khởi động xong
};

/**
 * Health check endpoint để cron ping
 * Thêm route này vào Express app của bạn
 */
export const createHealthCheckRoute = (app) => {
    app.get("/", (req, res) => {
        res.status(200).json({
            status: "ok",
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            message: "Server is alive"
        });
    });

    app.get("/ping", (req, res) => {
        res.status(200).send("pong");
    });

    console.log("✅ Health check routes đã được tạo: /health, /ping");
};