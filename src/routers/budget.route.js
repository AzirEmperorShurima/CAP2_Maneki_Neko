import { Router } from 'express';
import { createBudget, deleteBudget, getBudgetById, getBudgets, renewBudget, updateBudget } from '../controllers/budgetController.js';

const budgetRouter = Router();
budgetRouter.get('/health', (req, res) => {
    res.status(200).json({ message: 'Budget router is healthy' });
});
budgetRouter.post('/', createBudget);
budgetRouter.get('/', getBudgets);
budgetRouter.get('/:id', getBudgetById);
budgetRouter.put('/:id', updateBudget);
budgetRouter.delete('/:id', deleteBudget);
budgetRouter.post('/:id/renew', renewBudget);

export default budgetRouter;
