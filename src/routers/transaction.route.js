import { Router } from "express";
import { getTransactionChartData, getTransactions, createTransaction, updateTransaction, getTransactionById, deleteTransaction } from "../controllers/transactionController.js";

const transactionRouter = Router()

transactionRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Transaction API",
    })
})
transactionRouter.get("/transactions", getTransactions)
transactionRouter.get("/transactions/chart-data", getTransactionChartData)
transactionRouter.get("/transactions/:transactionId([0-9a-fA-F]{24})", getTransactionById)
transactionRouter.post("/transactions", createTransaction)
transactionRouter.put("/transactions/:transactionId", updateTransaction)
transactionRouter.delete("/transactions/:transactionId", deleteTransaction)

export default transactionRouter
