import { Router } from 'express';
import analyticsController from '../controllers/analyticsController.js';

const analyticsRouter = Router();

analyticsRouter.get('/overview', (req, res) => analyticsController.getOverview(req, res));
analyticsRouter.get('/expense-by-category', (req, res) => analyticsController.getExpenseByCategory(req, res));
analyticsRouter.get('/income-by-category', (req, res) => analyticsController.getIncomeByCategory(req, res));
analyticsRouter.get('/spending-trend', (req, res) => analyticsController.getSpendingTrend(req, res));
analyticsRouter.get('/comparison', (req, res) => analyticsController.getComparison(req, res));
analyticsRouter.get('/budget-status', (req, res) => analyticsController.getBudgetStatus(req, res));
analyticsRouter.get('/goals-progress', (req, res) => analyticsController.getGoalsProgress(req, res));
analyticsRouter.get('/wallet-analytics', (req, res) => analyticsController.getWalletAnalytics(req, res));
analyticsRouter.get('/top-transactions', (req, res) => analyticsController.getTopTransactions(req, res));
analyticsRouter.get('/full-report', (req, res) => analyticsController.getFullReport(req, res));

export default analyticsRouter;
