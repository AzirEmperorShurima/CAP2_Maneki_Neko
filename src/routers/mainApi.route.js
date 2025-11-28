import { Router } from "express";
import authRouter from "./auth.route.js";
import chatRouter from "./chat.js";
import userRouter from "./user.Route.js";
import { jwtAuth } from "../middlewares/auth.js";
import testRouter from "./testRouter.js";
import transactionRouter from "./transaction.route.js";
import familyRouter from "./family.route.js";
import { joinFamilyWeb } from "../controllers/family.js";
import goalRouter from "./goal.route.js";
import walletRouter from "./wallet.route.js";
import budgetRouter from "./budget.route.js";

const apiRouter = Router()

apiRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko API",
        timestamp: Date.now(),
        request_duration_time: Date.now() - req.startTime,
    })
})
// ============================================
// non-Protected Routes
// ============================================
apiRouter.use("/auth", authRouter)
apiRouter.use("/test", testRouter)
// Public family join endpoint
apiRouter.get("/family/join-web", joinFamilyWeb)
// ============================================
// Protected Routes
// ============================================
apiRouter.use(jwtAuth)
apiRouter.use("/chat", chatRouter)
apiRouter.use("/user", userRouter)
apiRouter.use("/transaction", transactionRouter)
apiRouter.use("/family", familyRouter)
apiRouter.use("/budget", budgetRouter)
apiRouter.use("/wallet", walletRouter)
apiRouter.use("/goal", goalRouter)

export default apiRouter
