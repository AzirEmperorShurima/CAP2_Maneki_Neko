import { Router } from "express";
import authRouter from "./auth.route.js";
import chatRouter from "./chat.js";
import userRouter from "./user.Route.js";
import { jwtAuth } from "../middlewares/auth.js";
import testRouter from "./testRouter.js";
import transactionRouter from "./transaction.route.js";

const apiRouter = Router()

apiRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko API",
        timestamp: Date.now(),
        request_duration_time: Date.now() - req.startTime,
    })
})

apiRouter.use("/auth", authRouter)
apiRouter.use("/test", testRouter)
// ============================================
// Protected Routes
// ============================================
apiRouter.use(jwtAuth)
apiRouter.use("/chat", chatRouter)
apiRouter.use("/user", userRouter)
apiRouter.use("/transaction", transactionRouter)

export default apiRouter