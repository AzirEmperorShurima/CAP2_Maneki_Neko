import { Router } from "express";
import { getTransactionChartData, getTransactions, createTransaction, updateTransaction, getTransactionById } from "../controllers/transactionController.js";

const transactionRouter = Router()

transactionRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Transaction API",
    })
})
transactionRouter.get("/transactions", getTransactions)
transactionRouter.get("/transactions/:transactionId", getTransactionById)
transactionRouter.get("/transactions/chart-data", getTransactionChartData)
transactionRouter.post("/transactions", createTransaction)
transactionRouter.put("/transactions/:transactionId", updateTransaction)

export default transactionRouter
