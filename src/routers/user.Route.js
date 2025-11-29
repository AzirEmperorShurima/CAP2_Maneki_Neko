import { Router } from "express";
import { getUserProfile } from "../controllers/authController.js";

const userRouter = Router()

userRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko User API",
    })
})
userRouter.get("/profile", getUserProfile)

export default userRouter
