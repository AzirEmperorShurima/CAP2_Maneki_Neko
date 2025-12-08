import { Router } from "express";
import { aboutPage, docsPage, homePage, docsAuthPage, docsUserPage, docsTransactionPage, docsBudgetPage, docsWalletPage, docsGoalPage, docsFamilyPage, docsAnalyticsPage, docsFcmPage, docsCategoryPage } from "../page/renderPage.js";

const renderPageRouter = Router();

renderPageRouter.get("/about", aboutPage);
renderPageRouter.get("/docs", docsPage);
renderPageRouter.get("/docs/auth", docsAuthPage);
renderPageRouter.get("/docs/user", docsUserPage);
renderPageRouter.get("/docs/transaction", docsTransactionPage);
renderPageRouter.get("/docs/budget", docsBudgetPage);
renderPageRouter.get("/docs/wallet", docsWalletPage);
renderPageRouter.get("/docs/goal", docsGoalPage);
renderPageRouter.get("/docs/family", docsFamilyPage);
renderPageRouter.get("/docs/analytics", docsAnalyticsPage);
renderPageRouter.get("/docs/fcm", docsFcmPage);
renderPageRouter.get("/docs/category", docsCategoryPage);

export default renderPageRouter;
