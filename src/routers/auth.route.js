import { Router } from "express";
import { loginBase, verifyGoogleId } from "../controllers/auth.js";

const authRouter = Router()

authRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Auth API",
    })
})

authRouter.get("/login/verify/google-id", verifyGoogleId)
authRouter.post("/login/base", loginBase)


export default authRouter