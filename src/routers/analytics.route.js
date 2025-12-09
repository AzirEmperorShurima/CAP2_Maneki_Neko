import { Router } from 'express';
import analyticsController from '../controllers/analyticsController.js';

const analyticsRouter = Router();

analyticsRouter.get('/personal/overview', analyticsController.getPersonalOverview);
analyticsRouter.get('/personal/spending-trend', analyticsController.getPersonalSpendingTrend);
analyticsRouter.get('/personal/by-wallet', analyticsController.getAnalyticsByWallet);
analyticsRouter.get('/personal/wallet/:walletId/details', analyticsController.getWalletDetailedAnalytics);
analyticsRouter.get('/personal/by-category', analyticsController.getAnalyticsByCategory);
analyticsRouter.get('/personal/top-transactions', analyticsController.getTopTransactions);
analyticsRouter.get('/personal/comparison', analyticsController.getPeriodComparison);
analyticsRouter.get('/personal/payment-method', analyticsController.getAnalyticsByPaymentMethod);

export default analyticsRouter;
