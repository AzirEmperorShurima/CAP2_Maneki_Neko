// controllers/walletController.js
import Wallet from '../models/wallet.js';
import Family from '../models/family.js';

export const createWallet = async (req, res) => {
  try {
    const { name, type, initialBalance, description, details, isShared } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Tên ví là bắt buộc' });
    }

    const wallet = new Wallet({
      userId: req.userId,
      name: name.trim(),
      type: type?.trim() || '',
      balance: initialBalance || 0,
      description: description?.trim() || '',
      details: details || {},
      isShared: isShared || false
    });

    await wallet.save();

    const populatedWallet = await Wallet.findById(wallet._id);
    res.status(201).json({
      message: 'Tạo ví thành công',
      wallet: populatedWallet
    });
  } catch (error) {
    console.error('Lỗi tạo ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const getWallets = async (req, res) => {
  try {
    const { isActive, isShared } = req.query;
    const filter = { userId: req.userId };

    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (isShared !== undefined) filter.isShared = isShared === 'true';

    const wallets = await Wallet.find(filter).sort({ createdAt: -1 });
    res.json({ wallets });
  } catch (error) {
    console.error('Lỗi lấy danh sách ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const getWalletById = async (req, res) => {
  try {
    const { id } = req.params;
    const wallet = await Wallet.findOne({ _id: id, userId: req.userId });

    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    res.json({ wallet });
  } catch (error) {
    console.error('Lỗi lấy thông tin ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const updateWallet = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, description, details, isActive, isShared } = req.body;

    const wallet = await Wallet.findOne({ _id: id, userId: req.userId });
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    if (name !== undefined) wallet.name = name.trim();
    if (type !== undefined) wallet.type = type.trim();
    if (description !== undefined) wallet.description = description?.trim() || '';
    if (details !== undefined) wallet.details = details;
    if (isActive !== undefined) wallet.isActive = isActive;
    if (isShared !== undefined) wallet.isShared = isShared;

    await wallet.save();
    const populatedWallet = await Wallet.findById(wallet._id);

    res.json({ message: 'Cập nhật ví thành công', wallet: populatedWallet });
  } catch (error) {
    console.error('Lỗi cập nhật ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const deleteWallet = async (req, res) => {
  try {
    const { id } = req.params;
    
    const wallet = await Wallet.findOne({ _id: id, userId: req.userId });
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    await Wallet.deleteOne({ _id: id, userId: req.userId });
    res.json({ message: 'Đã xóa ví' });
  } catch (error) {
    console.error('Lỗi xóa ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};