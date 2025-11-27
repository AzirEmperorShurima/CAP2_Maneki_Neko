import helmet from "helmet";
import express from "express";
import morgan from "morgan";
import cors from "cors";
import compression from "compression";
import apiRouter from "./src/routers/mainApi.route.js";
import { connectToDatabase } from "./mongo.js";

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