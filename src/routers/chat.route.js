import { Router } from "express";
import { chat } from "../controllers/chatController.js";
import { geminiChatController } from "../controllers/chat_geminiController.js";

const chatRouter = Router()
// chatRouter.use(jwtAuth)

chatRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Chat API",
        timestamp: Date.now(),
        request_duration_time: Date.now() - req.startTime,
    })
})
chatRouter.post('/old-chat', chat)
chatRouter.post('/gemini-chat', geminiChatController)
chatRouter.post('/gemini', geminiChatController)

export default chatRouter
