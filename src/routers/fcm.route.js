import { Router } from "express";
import {
    clearAllAnotherFCMTokens,
    getFCMTokens,
    registerNewFCMToken,
    removeFCMToken
} from "../controllers/fcmController.js";
import { jwtAuth } from "../middlewares/auth.js";

const fcmRouter = Router()

fcmRouter.post('/register-fcm-token', registerNewFCMToken)
// Protected Routes
fcmRouter.get('/get-fcm-tokens', [jwtAuth, getFCMTokens])
fcmRouter.delete('/delete-fcm-token', [jwtAuth, removeFCMToken])
fcmRouter.post('/clear-all-another-fcm-tokens', [jwtAuth, clearAllAnotherFCMTokens])

export default fcmRouter