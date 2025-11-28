// routes/goalRoutes.js
import { Router } from 'express';
import { createGoal, getGoals, getGoalById, updateGoal, addProgressToGoal, linkWalletsToGoal, unlinkWalletFromGoal, deleteGoal } from '../controllers/goal.js';

const goalRouter = Router();

goalRouter.post('/', createGoal);
goalRouter.get('/', getGoals);
goalRouter.get('/:id', getGoalById);
goalRouter.put('/:id', updateGoal);
goalRouter.post('/:id/progress', addProgressToGoal);
goalRouter.post('/:id/link-wallets', linkWalletsToGoal);
goalRouter.delete('/:id/wallet/:walletId', unlinkWalletFromGoal);
goalRouter.delete('/:id', deleteGoal);

export default goalRouter;
