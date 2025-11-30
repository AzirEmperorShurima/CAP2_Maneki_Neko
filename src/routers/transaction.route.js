import { Router } from "express";
import { getTransactionChartData, getTransactions, createTransaction, updateTransaction } from "../controllers/transactionController.js";

const transactionRouter = Router()

transactionRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Transaction API",
    })
})
transactionRouter.get("/transactions", getTransactions)
transactionRouter.get("/transactions/chart-data", getTransactionChartData)
transactionRouter.post("/transactions", createTransaction)
transactionRouter.put("/transactions/:id", updateTransaction)

export default transactionRouter
