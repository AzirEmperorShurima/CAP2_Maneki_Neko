import { Router } from "express";
import { addTestBaseUser, addTestUser, deleteTestUser } from "../controllers/testController.js";

const testRouter = Router()

testRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Test API",
        timestamp: Date.now(),
        request_duration_time: Date.now() - req.startTime,
    })
})
testRouter.post('/add-user', addTestUser)
testRouter.delete('/user', deleteTestUser)
testRouter.post('/add-base-user', addTestBaseUser)



export default testRouter
