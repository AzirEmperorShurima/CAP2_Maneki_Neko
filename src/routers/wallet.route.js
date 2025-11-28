// routes/walletRoutes.js
import { Router } from 'express';
import { createWallet, getWallets, getWalletById, updateWallet, deleteWallet } from '../controllers/walletController.js';

const walletRouter = Router();

walletRouter.post('/', createWallet);
walletRouter.get('/', getWallets);
walletRouter.get('/:id', getWalletById);
walletRouter.put('/:id', updateWallet);
walletRouter.delete('/:id', deleteWallet);

export default walletRouter;
