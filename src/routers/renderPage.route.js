import { Router } from "express";
import { aboutPage, docsPage, homePage } from "../page/renderPage.js";

const renderPageRouter = Router();

renderPageRouter.get("/about", aboutPage);
renderPageRouter.get("/docs", docsPage);

export default renderPageRouter;
