import Wallet from '../models/wallet.js';
import { WalletTransfer } from '../models/walletTransfer.js';
import Family from '../models/family.js';
import User from '../models/user.js';
import mongoose from 'mongoose';

// ===== TẠO VÍ =====
export const createWallet = async (req, res) => {
  try {
    const {
      name,
      type,
      initialBalance,
      description,
      details,
      isShared,
      familyId
    } = req.body;

    if (!name) {
      return res.status(400).json({ error: 'Tên ví là bắt buộc' });
    }

    // Kiểm tra nếu tạo ví gia đình
    if (isShared) {
      if (!familyId) {
        return res.status(400).json({ error: 'Cần chỉ định familyId khi tạo ví gia đình' });
      }

      // Kiểm tra user có phải admin của family không
      const family = await Family.findOne({
        _id: familyId,
        adminId: req.userId
      });

      if (!family) {
        return res.status(403).json({
          error: 'Chỉ admin của gia đình mới có thể tạo ví gia đình'
        });
      }

      // Tạo ví gia đình
      const wallet = new Wallet({
        userId: req.userId, // Owner là admin
        familyId,
        name: name.trim(),
        type: type?.trim() || 'family_wallet',
        balance: initialBalance || 0,
        description: description?.trim() || '',
        details: details || {},
        isShared: true,
        accessControl: {
          canView: family.members, // Tất cả members có thể xem
          canTransact: [req.userId] // Mặc định chỉ admin giao dịch được
        }
      });

      await wallet.save();

      // Thêm vào sharedResources của family
      await family.addSharedResource('wallets', wallet._id);

      const populatedWallet = await Wallet.findById(wallet._id)
        .populate('familyId', 'name')
        .populate('accessControl.canView', 'username email')
        .populate('accessControl.canTransact', 'username email');

      return res.status(201).json({
        message: 'Tạo ví gia đình thành công',
        wallet: populatedWallet
      });
    } else {
      // Tạo ví cá nhân
      const wallet = new Wallet({
        userId: req.userId,
        name: name.trim(),
        type: type?.trim() || 'personal',
        balance: initialBalance || 0,
        description: description?.trim() || '',
        details: details || {},
        isShared: false
      });

      await wallet.save();

      return res.status(201).json({
        message: 'Tạo ví cá nhân thành công',
        wallet
      });
    }
  } catch (error) {
    console.error('Lỗi tạo ví:', error);
    res.status(500).json({ error: 'Lỗi server', message: error.message });
  }
};

// ===== LẤY DANH SÁCH VÍ =====
export const getWallets = async (req, res) => {
  try {
    const { isActive, isShared, familyId } = req.query;

    // Lấy tất cả ví của user (cá nhân + gia đình)
    const filter = {
      $or: [
        { userId: req.userId }, // Ví của user
        { 'accessControl.canView': req.userId } // Ví gia đình user có quyền xem
      ]
    };

    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (isShared !== undefined) filter.isShared = isShared === 'true';
    if (familyId) filter.familyId = familyId;

    const wallets = await Wallet.find(filter)
      .populate('familyId', 'name')
      .populate('userId', 'username email')
      .sort({ isShared: 1, isDefault: -1, createdAt: -1 })
      .lean();

    // Thêm thông tin quyền truy cập
    const walletsWithPermissions = wallets.map(wallet => ({
      ...wallet,
      permissions: {
        canView: wallet.userId.equals(req.userId) ||
          wallet.accessControl?.canView?.some(id => id.equals(req.userId)),
        canTransact: wallet.userId.equals(req.userId) ||
          wallet.accessControl?.canTransact?.some(id => id.equals(req.userId)),
        isOwner: wallet.userId.equals(req.userId)
      }
    }));

    res.json({
      wallets: walletsWithPermissions,
      summary: {
        total: walletsWithPermissions.length,
        personal: walletsWithPermissions.filter(w => !w.isShared).length,
        family: walletsWithPermissions.filter(w => w.isShared).length,
        totalBalance: walletsWithPermissions.reduce((sum, w) => sum + w.balance, 0)
      }
    });
  } catch (error) {
    console.error('Lỗi lấy danh sách ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== LẤY CHI TIẾT VÍ =====
export const getWalletById = async (req, res) => {
  try {
    const { id } = req.params;
    const wallet = await Wallet.findById(id)
      .populate('familyId', 'name members')
      .populate('userId', 'username email')
      .populate('accessControl.canView', 'username email')
      .populate('accessControl.canTransact', 'username email');

    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    // Kiểm tra quyền xem
    if (!wallet.canUserView(req.userId)) {
      return res.status(403).json({ error: 'Bạn không có quyền xem ví này' });
    }

    res.json({
      wallet,
      permissions: {
        canView: true,
        canTransact: wallet.canUserTransact(req.userId),
        isOwner: wallet.userId.equals(req.userId)
      }
    });
  } catch (error) {
    console.error('Lỗi lấy thông tin ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== CẬP NHẬT VÍ =====
export const updateWallet = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, description, details, isActive } = req.body;

    const wallet = await Wallet.findById(id);
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    // Chỉ owner mới có thể cập nhật
    if (!wallet.userId.equals(req.userId)) {
      return res.status(403).json({ error: 'Chỉ chủ ví mới có thể cập nhật' });
    }

    if (name !== undefined) wallet.name = name.trim();
    if (type !== undefined) wallet.type = type.trim();
    if (description !== undefined) wallet.description = description?.trim() || '';
    if (details !== undefined) wallet.details = details;
    if (isActive !== undefined) wallet.isActive = isActive;

    await wallet.save();

    const populatedWallet = await Wallet.findById(wallet._id)
      .populate('familyId', 'name')
      .populate('accessControl.canView', 'username email')
      .populate('accessControl.canTransact', 'username email');

    res.json({
      message: 'Cập nhật ví thành công',
      wallet: populatedWallet
    });
  } catch (error) {
    console.error('Lỗi cập nhật ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== XÓA VÍ =====
export const deleteWallet = async (req, res) => {
  try {
    const { id } = req.params;

    const wallet = await Wallet.findById(id);
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    // Chỉ owner mới có thể xóa
    if (!wallet.userId.equals(req.userId)) {
      return res.status(403).json({ error: 'Chỉ chủ ví mới có thể xóa' });
    }

    // Kiểm tra số dư
    if (wallet.balance > 0) {
      return res.status(400).json({
        error: 'Không thể xóa ví còn số dư. Vui lòng chuyển hết số dư trước.'
      });
    }

    // Nếu là ví gia đình, xóa khỏi sharedResources
    if (wallet.isShared && wallet.familyId) {
      const family = await Family.findById(wallet.familyId);
      if (family) {
        await family.removeSharedResource('wallets', wallet._id);
      }
    }

    await Wallet.deleteOne({ _id: id });
    res.json({ message: 'Đã xóa ví thành công' });
  } catch (error) {
    console.error('Lỗi xóa ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== CHUYỂN TIỀN GIỮA CÁC VÍ =====
export const transferBetweenWallets = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { fromWalletId, toWalletId, amount, note } = req.body;

    // Validation
    if (!fromWalletId || !toWalletId) {
      throw new Error('Cần chỉ định ví nguồn và ví đích');
    }

    if (!amount || amount <= 0) {
      throw new Error('Số tiền phải lớn hơn 0');
    }

    if (fromWalletId === toWalletId) {
      throw new Error('Không thể chuyển tiền trong cùng một ví');
    }

    // Lấy thông tin 2 ví
    const [fromWallet, toWallet] = await Promise.all([
      Wallet.findById(fromWalletId).session(session),
      Wallet.findById(toWalletId).session(session)
    ]);

    if (!fromWallet || !toWallet) {
      throw new Error('Không tìm thấy ví');
    }

    // Kiểm tra quyền giao dịch ví nguồn
    if (!fromWallet.canUserTransact(req.userId)) {
      throw new Error('Bạn không có quyền chuyển tiền từ ví này');
    }

    // Kiểm tra số dư
    if (fromWallet.balance < amount) {
      throw new Error('Số dư ví nguồn không đủ');
    }

    // Xác định loại chuyển tiền
    let transferType;
    if (!fromWallet.isShared && !toWallet.isShared) {
      // Cả 2 đều là ví cá nhân
      if (!fromWallet.userId.equals(req.userId) || !toWallet.userId.equals(req.userId)) {
        throw new Error('Chỉ có thể chuyển tiền giữa các ví cá nhân của chính mình');
      }
      transferType = 'personal_to_personal';
    } else if (fromWallet.isShared && !toWallet.isShared) {
      // Từ ví gia đình sang ví cá nhân
      // Kiểm tra admin của family
      const family = await Family.findById(fromWallet.familyId);
      if (!family || !family.isAdmin(req.userId)) {
        throw new Error('Chỉ admin gia đình mới có thể chuyển tiền từ ví gia đình sang ví cá nhân');
      }

      // Kiểm tra ví đích có thuộc member của family không
      if (!family.isMember(toWallet.userId)) {
        throw new Error('Ví đích phải thuộc về thành viên của gia đình');
      }
      transferType = 'family_to_personal';
    } else if (!fromWallet.isShared && toWallet.isShared) {
      // Từ ví cá nhân sang ví gia đình
      if (!fromWallet.userId.equals(req.userId)) {
        throw new Error('Chỉ có thể chuyển từ ví cá nhân của chính mình');
      }
      transferType = 'personal_to_family';
    } else {
      throw new Error('Không hỗ trợ chuyển tiền giữa 2 ví gia đình');
    }

    // Thực hiện chuyển tiền
    fromWallet.balance -= amount;
    toWallet.balance += amount;

    await Promise.all([
      fromWallet.save({ session }),
      toWallet.save({ session })
    ]);

    // Lưu lịch sử giao dịch
    const transfer = new WalletTransfer({
      fromWalletId,
      toWalletId,
      amount,
      initiatedBy: req.userId,
      type: transferType,
      status: 'completed',
      note: note || '',
      metadata: {
        fromWalletName: fromWallet.name,
        toWalletName: toWallet.name,
        fromWalletBalance: fromWallet.balance,
        toWalletBalance: toWallet.balance
      }
    });

    await transfer.save({ session });

    await session.commitTransaction();

    const populatedTransfer = await WalletTransfer.findById(transfer._id)
      .populate('fromWalletId', 'name balance')
      .populate('toWalletId', 'name balance')
      .populate('initiatedBy', 'username email');

    res.json({
      message: 'Chuyển tiền thành công',
      transfer: populatedTransfer
    });

  } catch (error) {
    await session.abortTransaction();
    console.error('Lỗi chuyển tiền:', error);
    res.status(400).json({
      error: error.message || 'Lỗi khi chuyển tiền'
    });
  } finally {
    session.endSession();
  }
};

// ===== LỊCH SỬ CHUYỂN TIỀN =====
export const getTransferHistory = async (req, res) => {
  try {
    const { walletId, type, limit = 50, page = 1 } = req.query;
    const skip = (page - 1) * limit;

    const filter = {
      $or: [
        { initiatedBy: req.userId },
        { fromWalletId: walletId },
        { toWalletId: walletId }
      ]
    };

    if (type) filter.type = type;
    if (walletId) {
      // Kiểm tra user có quyền xem ví này không
      const wallet = await Wallet.findById(walletId);
      if (!wallet || !wallet.canUserView(req.userId)) {
        return res.status(403).json({ error: 'Bạn không có quyền xem lịch sử ví này' });
      }

      filter.$or = [
        { fromWalletId: walletId },
        { toWalletId: walletId }
      ];
    }

    const [transfers, total] = await Promise.all([
      WalletTransfer.find(filter)
        .populate('fromWalletId', 'name type isShared')
        .populate('toWalletId', 'name type isShared')
        .populate('initiatedBy', 'username email')
        .sort({ createdAt: -1 })
        .limit(parseInt(limit))
        .skip(skip)
        .lean(),
      WalletTransfer.countDocuments(filter)
    ]);

    res.json({
      transfers,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Lỗi lấy lịch sử chuyển tiền:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== QUẢN LÝ QUYỀN TRUY CẬP VÍ GIA ĐÌNH =====
export const manageWalletAccess = async (req, res) => {
  try {
    const { id } = req.params;
    const { action, userId: targetUserId, accessType } = req.body;
    // action: 'grant' | 'revoke'
    // accessType: 'view' | 'transact'

    const wallet = await Wallet.findById(id);
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    // Chỉ ví gia đình mới có access control
    if (!wallet.isShared) {
      return res.status(400).json({ error: 'Chỉ áp dụng cho ví gia đình' });
    }

    // Kiểm tra quyền: phải là owner hoặc admin của family
    const family = await Family.findById(wallet.familyId);
    if (!family || !family.isAdmin(req.userId)) {
      return res.status(403).json({
        error: 'Chỉ admin gia đình mới có thể quản lý quyền truy cập'
      });
    }

    // Kiểm tra target user có phải member của family không
    if (!family.isMember(targetUserId)) {
      return res.status(400).json({
        error: 'User phải là thành viên của gia đình'
      });
    }

    if (action === 'grant') {
      if (accessType === 'view') {
        wallet.grantViewAccess(targetUserId);
      } else if (accessType === 'transact') {
        wallet.grantTransactAccess(targetUserId);
      }
    } else if (action === 'revoke') {
      wallet.revokeAccess(targetUserId);
    }

    await wallet.save();

    const populatedWallet = await Wallet.findById(wallet._id)
      .populate('accessControl.canView', 'username email')
      .populate('accessControl.canTransact', 'username email');

    res.json({
      message: 'Cập nhật quyền truy cập thành công',
      wallet: populatedWallet
    });
  } catch (error) {
    console.error('Lỗi quản lý quyền truy cập:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};
