import { Router } from "express";
import { register, login, verifyGoogleId } from "../controllers/authController.js";

const authRouter = Router()

authRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Auth API",
    })
})

authRouter.post("/register", register)
authRouter.post("/login", login)
authRouter.get("/login/verify/google-id", verifyGoogleId)


export default authRouter
