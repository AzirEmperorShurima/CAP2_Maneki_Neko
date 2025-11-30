import mongoose from "mongoose";
import category from "./src/models/category.js";
import { initialCats } from "./src/seed/categories.js";
import { models_list } from "./src/models/models_list.js";

const MONGO_ATLAS_URI = process.env.MONGO_URI_ATLAS;
const MONGO_RAILWAY_URI = process.env.MONGO_URI_RAILWAY;
const MONGO_LOCAL_URI = "mongodb://localhost:27017/Maneki_Neko";

const MAX_RETRIES = 5;
const RETRY_INTERVAL = 5000;

const checkMongoConnection = async () => {
    if (mongoose.connection.readyState === 1) {
        return true;
    }
    return false;
};

export const initializeCollections = async (models) => {
    console.log("🔁 Initializing Mongoose collections...");
    let initializedCount = 0;

    for (const [modelName, model] of Object.entries(models)) {
        try {
            if (model?.prototype instanceof mongoose.Model) {
                await model.init();
                console.log(`✅ Initialized: ${modelName}`);
                initializedCount++;
            } else {
                console.warn(`⚠️ Skipped: ${modelName} is not a valid Mongoose Model`);
            }
        } catch (err) {
            console.error(`❌ Failed to initialize ${modelName}:`, err);
        }
    }

    console.log(
        `🎉 Initialized ${initializedCount} collections of Maneki_Neko.`
    );
};

const tryConnectToMongo = async (uri, label) => {
    try {
        console.log(`📡 Đang thử kết nối ${label}...`);

        // Cấu hình connection options dựa trên MongoDB Atlas recommended settings
        const connectionOptions = {
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        };

        // Thêm serverApi cho MongoDB Atlas
        if (label === "MongoDB Atlas") {
            connectionOptions.serverApi = {
                version: '1',
                strict: true,
                deprecationErrors: true,
            };
        }

        await mongoose.connect(uri, connectionOptions);

        // Ping để xác nhận kết nối (tương tự code mẫu MongoDB Atlas)
        await mongoose.connection.db.admin().command({ ping: 1 });

        console.log(`✅ Kết nối ${label} thành công! Đã ping database thành công.`);
        return true;
    } catch (error) {
        console.error(`❌ Kết nối ${label} thất bại:`, error.message);

        // Đảm bảo đóng connection nếu có lỗi
        if (mongoose.connection.readyState !== 0) {
            await mongoose.connection.close();
        }

        return false;
    }
};

const connectWithFallback = async () => {
    // Thử MongoDB Atlas trước (ưu tiên cao nhất)
    if (MONGO_ATLAS_URI) {
        const atlasConnected = await tryConnectToMongo(MONGO_ATLAS_URI, "MongoDB Atlas");
        if (atlasConnected) return true;
    } else {
        console.log("⚠️ MongoDB Atlas URI không được cấu hình (MONGO_URI_ATLAS)");
    }

    // Fallback sang Railway
    if (MONGO_RAILWAY_URI) {
        const railwayConnected = await tryConnectToMongo(MONGO_RAILWAY_URI, "Railway MongoDB");
        if (railwayConnected) return true;
    } else {
        console.log("⚠️ Railway MongoDB URI không được cấu hình (MONGO_URI_RAILWAY)");
    }

    // Fallback cuối cùng sang Local
    console.log("⚠️ Đang fallback sang MongoDB Local...");
    const localConnected = await tryConnectToMongo(MONGO_LOCAL_URI, "MongoDB Local");
    return localConnected;
};

const reconnectWithRetry = async (retryCount = 0) => {
    try {
        const connected = await connectWithFallback();
        if (connected) {
            return true;
        }

        throw new Error("Tất cả các MongoDB URIs đều thất bại");
    } catch (error) {
        console.error(
            `❌ Lỗi kết nối MongoDB (Lần thử ${retryCount + 1}/${MAX_RETRIES}):`,
            error.message
        );

        if (retryCount < MAX_RETRIES) {
            console.log(
                `⏳ Đang thử kết nối lại sau ${RETRY_INTERVAL / 1000} giây...`
            );
            await new Promise((resolve) => setTimeout(resolve, RETRY_INTERVAL));
            return reconnectWithRetry(retryCount + 1);
        } else {
            console.error("❌ Đã vượt quá số lần thử kết nối tối đa!");
            return false;
        }
    }
};

export const connectToDatabase = async () => {
    try {
        console.log("🔄 Đang kiểm tra kết nối MongoDB...");
        console.log("📋 Fallback chain: Atlas → Railway → Local");

        const isConnected = await checkMongoConnection();
        if (!isConnected) {
            console.log("📡 Đang thiết lập kết nối mới với fallback chain...");
            const connectionSuccess = await reconnectWithRetry();
            if (!connectionSuccess) {
                throw new Error("Không thể kết nối đến MongoDB sau nhiều lần thử");
            }
        } else {
            console.log("✅ MongoDB đã được kết nối sẵn");
        }

        await initializeCollections(models_list);
        await category.deleteMany({});
        await category.insertMany(initialCats);

        mongoose.connection.on("disconnected", async () => {
            console.log("⚠️ MongoDB đã ngắt kết nối! Đang thử kết nối lại...");
            await reconnectWithRetry();
        });

        mongoose.connection.on("error", (error) => {
            console.error("❌ Lỗi kết nối MongoDB:", error);
        });
    } catch (err) {
        console.error("❌ Lỗi trong quá trình kết nối database:", err);
        throw err;
    }
};

process.on("SIGINT", async () => {
    try {
        await mongoose.connection.close();
        console.log("📴 Đã đóng kết nối MongoDB an toàn");
        process.exit(0);
    } catch (err) {
        console.error("❌ Lỗi khi đóng kết nối MongoDB:", err);
        process.exit(1);
    }
});