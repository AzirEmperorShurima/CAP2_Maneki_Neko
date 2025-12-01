// routes/walletRoutes.js
import { Router } from 'express';
import {
    createWallet, getWallets,
    getWalletById, updateWallet,
    deleteWallet, manageWalletAccess,
    getTransferHistory, transferBetweenWallets
} from '../controllers/walletController.js';

const walletRouter = Router();

walletRouter.post('/', createWallet);
walletRouter.get('/', getWallets);
walletRouter.get('/:id', getWalletById);
walletRouter.put('/:id', updateWallet);
walletRouter.delete('/:id', deleteWallet);

// Chuyển tiền
walletRouter.post('/transfer', transferBetweenWallets);
walletRouter.get('/transfers/history', getTransferHistory);

// Quản lý quyền
walletRouter.post('/:id/access', manageWalletAccess);

export default walletRouter;
