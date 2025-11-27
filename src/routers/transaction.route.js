import { Router } from "express";
import { getTransactionChartData, getTransactions } from "../controllers/transaction.js";

const transactionRouter = Router()

transactionRouter.get("/", (req, res) => {
    res.status(200).json({
        status: "success",
        message: "Welcome to the Maneki Neko Transaction API",
    })
})
transactionRouter.get("/transactions", getTransactions)
transactionRouter.get("/transactions/chart-data", getTransactionChartData)

export default transactionRouter
