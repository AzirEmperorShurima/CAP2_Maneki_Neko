import Wallet from '../models/wallet.js';
import { WalletTransfer } from '../models/walletTransfer.js';
import Family from '../models/family.js';
import mongoose from 'mongoose';
import {
  validateCreateWallet,
  validateGetWalletsQuery,
  validateIdParam,
  validateUpdateWallet,
  validateTransferBetweenWallets,
  validateManageWalletAccess,
  validateGetTransferHistoryQuery,
  validatePayDebt
} from '../validations/wallet.js';
import user from '../models/user.js';
import transaction from '../models/transaction.js';

// ===== TẠO VÍ =====
export const createWallet = async (req, res) => {
  try {
    const { error, value } = validateCreateWallet(req.body);
    if (error) {
      return res.status(400).json({
        error: 'Invalid payload',
        details: error.details.map(d => ({ field: d.path.join('.'), message: d.message }))
      });
    }
    const {
      name,
      type,
      balance,
      description,
      details,
      icon,
      isShared,
      familyId
    } = value;

    if (!name) {
      return res.status(400).json({ error: 'Tên ví là bắt buộc' });
    }

    if (isShared) {
      if (!familyId) {
        return res.status(400).json({
          error: 'Cần chỉ định familyId khi tạo ví gia đình'
        });
      }

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
        userId: req.userId,
        familyId,
        name: name.trim(),
        scope: 'family',
        type: type?.trim() || '',
        balance: initialBalance || 0,
        description: description?.trim() || '',
        details: details || {},
        icon: icon || '👨‍👩‍👧‍👦',
        isShared: true,
        canDelete: true,
        accessControl: {
          canView: family.members,
          canTransact: [req.userId]
        }
      });

      await wallet.save();
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
        scope: 'personal',
        type: type?.trim() || '',
        balance: balance || 0,
        description: description?.trim() || '',
        details: details || {},
        icon: icon || '💰',
        isShared: false,
        canDelete: true
      });

      await wallet.save();

      return res.status(201).json({
        message: 'Tạo ví cá nhân thành công',
        data: {
          wallet
        }
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
    const { error, value } = validateGetWalletsQuery(req.query);
    if (error) {
      return res.status(400).json({ error: 'Invalid query', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { isActive, isShared, scope, type, includeSystem = 'true' } = value;

    const filter = {
      $or: [
        { userId: req.userId },
        { 'accessControl.canView': req.userId }
      ]
    };

    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (isShared !== undefined) filter.isShared = isShared === 'true';
    if (scope) filter.scope = scope;
    if (type) filter.type = { $regex: type, $options: 'i' }; // Case-insensitive search
    if (includeSystem === 'false') filter.isSystemWallet = false;

    const wallets = await Wallet.find(filter)
      .populate('familyId', 'name')
      .populate('userId', 'username email')
      .sort({ isSystemWallet: 1, isDefault: -1, createdAt: -1 })
      .lean();

    const walletsWithPermissions = wallets.map(wallet => {
      const ownerId = wallet?.userId && typeof wallet.userId === 'object' && wallet.userId._id ? wallet.userId._id : wallet.userId;
      const isOwner = String(ownerId) === String(req.userId);
      const canTransact = isOwner || (wallet.accessControl?.canTransact?.some(id => {
        const memberId = id && typeof id === 'object' && id._id ? id._id : id;
        return String(memberId) === String(req.userId);
      }) ?? false);

      return {
        ...wallet,
        permissions: {
          canView: true,
          canTransact,
          canDelete: isOwner && wallet.canDelete,
          isOwner
        }
      };
    });

    // Chuẩn hóa id và userId trong response
    const normalizeWallet = (wallet) => {
      if (!wallet) return null;
      const { _id, userId, __v, ...rest } = wallet;
      return {
        ...rest,
        id: _id && _id.toString ? _id.toString() : String(_id),
        userId: userId && typeof userId === 'object' && userId._id
          ? userId._id.toString()
          : (userId !== undefined && userId !== null ? String(userId) : null)
      };
    };

    const normalizedWallets = walletsWithPermissions.map(normalizeWallet);

    // Phân loại ví (đã chuẩn hóa)
    const categorized = {
      personal: normalizedWallets.filter(w => w.scope === 'personal'),
      family: normalizedWallets.filter(w => w.scope === 'family'),
      system: {
        receive: normalizedWallets.find(w => w.scope === 'default_receive'),
        savings: normalizedWallets.find(w => w.scope === 'default_savings'),
        debt: normalizedWallets.find(w => w.scope === 'default_debt')
      }
    };

    // Thống kê theo mục đích (type)
    const typeStats = {};
    normalizedWallets
      .filter(w => w.type && !w.isSystemWallet)
      .forEach(w => {
        if (!typeStats[w.type]) {
          typeStats[w.type] = {
            count: 0,
            totalBalance: 0
          };
        }
        typeStats[w.type].count++;
        typeStats[w.type].totalBalance += w.balance;
      });

    res.json({
      message: 'Lấy danh sách ví thành công',
      data: {
        wallets: normalizedWallets,
        categorized,
        summary: {
          total: normalizedWallets.length,
          personal: categorized.personal.length,
          family: categorized.family.length,
          totalBalance: normalizedWallets.reduce((sum, w) => sum + w.balance, 0),
          totalDebt: categorized.system.debt ?
            Math.abs(Math.min(0, categorized.system.debt.balance)) : 0
        },
        typeStats
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
    const { error, value } = validateIdParam(req.params);
    if (error) {
      return res.status(400).json({ error: 'Invalid param', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { id } = value;
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

    const ownerId = wallet?.userId && wallet.userId._id ? wallet.userId._id : wallet.userId;
    const isOwner = String(ownerId) === String(req.userId);

    const plain = typeof wallet.toObject === 'function' ? wallet.toObject() : wallet;
    const normalizedWallet = {
      id: plain._id,
      name: plain.name || '',
      scope: plain.scope || '',
      type: plain.type || '',
      balance: plain.balance ?? 0,
      isActive: !!plain.isActive,
      isShared: !!plain.isShared,
      isDefault: !!plain.isDefault,
      isSystemWallet: !!plain.isSystemWallet,
      canDelete: !!plain.canDelete,
      description: plain.description || '',
      icon: plain.icon || '',
      details: {
        bankName: plain.details?.bankName || '',
        accountNumber: plain.details?.accountNumber || '',
        cardNumber: plain.details?.cardNumber || ''
      },
      family: plain.familyId ? {
        id: plain.familyId._id,
        name: plain.familyId.name || ''
      } : {
        id: '',
        name: ''
      },
      owner: plain.userId ? {
        id: plain.userId._id || plain.userId,
        username: plain.userId.username || '',
        email: plain.userId.email || ''
      } : {
        id: '',
        username: '',
        email: ''
      },
      accessControl: {
        canView: Array.isArray(plain.accessControl?.canView) ? plain.accessControl.canView.map(u => ({
          id: u?._id || u,
          username: u?.username || '',
          email: u?.email || ''
        })) : [],
        canTransact: Array.isArray(plain.accessControl?.canTransact) ? plain.accessControl.canTransact.map(u => ({
          id: u?._id || u,
          username: u?.username || '',
          email: u?.email || ''
        })) : []
      }
    };

    res.json({
      message: 'Lấy thông tin ví thành công',
      data: {
        wallet: normalizedWallet,
        permissions: {
          canView: true,
          canTransact: wallet.canUserTransact(req.userId),
          isOwner
        }
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
    const { error: idErr, value: idVal } = validateIdParam(req.params);
    if (idErr) {
      return res.status(400).json({ error: 'Invalid param', details: idErr.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { id } = idVal;

    const { error, value } = validateUpdateWallet(req.body);
    if (error) {
      return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { name, type, description, details, icon, isActive } = value;

    const wallet = await Wallet.findById(id);
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }

    // Chỉ owner mới có thể cập nhật
    if (!wallet.userId.equals(req.userId)) {
      return res.status(403).json({ error: 'Chỉ chủ ví mới có thể cập nhật' });
    }

    // Không cho phép thay đổi scope của system wallet
    if (wallet.isSystemWallet) {
      return res.status(400).json({
        error: 'Không thể chỉnh sửa ví hệ thống'
      });
    }

    if (name !== undefined) wallet.name = name.trim();
    if (type !== undefined) wallet.type = type.trim();
    if (description !== undefined) wallet.description = description?.trim() || '';
    if (details !== undefined) wallet.details = details;
    if (icon !== undefined) wallet.icon = icon;
    if (isActive !== undefined) wallet.isActive = isActive;

    await wallet.save();

    const populatedWallet = await Wallet.findById(wallet._id)
      .populate('familyId', 'name')
      .populate('accessControl.canView', 'username email')
      .populate('accessControl.canTransact', 'username email');

    res.json({
      message: 'Cập nhật ví thành công',
      data: {
        wallet: populatedWallet
      }
    });
  } catch (error) {
    console.error('Lỗi cập nhật ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const addAmountToWallet = async (req, res) => {
  try {
    const { id, amount } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Số tiền phải lớn hơn 0' });
    }
    const wallet = await Wallet.findById(id);
    if (!wallet) {
      return res.status(404).json({ error: 'Không tìm thấy ví' });
    }
    // Chỉ owner mới có thể cập nhật
    if (!wallet.userId.equals(req.userId)) {
      return res.status(403).json({ error: 'Chỉ chủ ví mới có thể cập nhật' });
    }
    wallet.balance += amount;
    await wallet.save();
    res.json({
      message: 'Cập nhật ví thành công',
      data: {
        wallet
      }
    });
  } catch (error) {
    console.error('Lỗi cập nhật ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

// ===== XÓA VÍ =====
export const deleteWallet = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { error, value } = validateIdParam(req.params);
    if (error) {
      await session.abortTransaction();
      return res.status(400).json({ error: 'Invalid param', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { id } = value;

    const wallet = await Wallet.findById(id).session(session);
    if (!wallet) {
      throw new Error('Không tìm thấy ví');
    }

    // Kiểm tra quyền xóa
    if (wallet.isShared && wallet.familyId) {
      const family = await Family.findById(wallet.familyId);
      if (!family || !family.isAdmin(req.userId)) {
        throw new Error('Chỉ admin gia đình mới có thể xóa ví gia đình');
      }
    } else {
      if (!wallet.canUserDelete(req.userId)) {
        throw new Error('Không thể xóa ví hệ thống này');
      }
    }

    const balance = wallet.balance;
    let transferRecord = null;

    // XỬ LÝ SỐ DƯ KHI XÓA
    if (balance !== 0) {
      let targetWallet;
      let transferNote;

      if (balance > 0) {
        // Số dư dương → Quỹ Tiết Kiệm
        targetWallet = await Wallet.getOrCreateDefaultWallet(
          wallet.userId,
          'default_savings',
          wallet.isShared ? wallet.familyId : null
        );
        transferNote = `Tự động chuyển ${balance.toLocaleString('vi-VN')}đ từ ví "${wallet.name}" (${wallet.type || 'không có mục đích'}) vào Quỹ Tiết Kiệm khi xóa`;

        targetWallet.balance += balance;
        await targetWallet.save({ session });

      } else {
        // Số dư âm → Ví Nợ
        targetWallet = await Wallet.getOrCreateDefaultWallet(
          wallet.userId,
          'default_debt',
          wallet.isShared ? wallet.familyId : null
        );
        transferNote = `Tự động ghi nợ ${Math.abs(balance).toLocaleString('vi-VN')}đ từ ví "${wallet.name}" (${wallet.type || 'không có mục đích'}) vào Ví Ghi Nợ khi xóa`;

        targetWallet.balance += balance;
        await targetWallet.save({ session });
      }

      // Lưu lịch sử transfer
      transferRecord = new WalletTransfer({
        fromWalletId: wallet._id,
        toWalletId: targetWallet._id,
        amount: Math.abs(balance),
        initiatedBy: req.userId,
        type: 'system_auto_transfer',
        status: 'completed',
        note: transferNote,
        isSystemTransfer: true,
        metadata: {
          fromWalletName: wallet.name,
          toWalletName: targetWallet.name,
          fromWalletBalance: 0,
          toWalletBalance: targetWallet.balance,
          reason: 'wallet_deletion'
        }
      });

      await transferRecord.save({ session });
    }

    // Xóa khỏi family sharedResources
    if (wallet.isShared && wallet.familyId) {
      const family = await Family.findById(wallet.familyId);
      if (family) {
        await family.removeSharedResource('wallets', wallet._id);
      }
    }

    await Wallet.deleteOne({ _id: id }).session(session);

    await session.commitTransaction();

    res.json({
      message: 'Đã xóa ví thành công',
      data: {
        name: wallet.name,
        type: wallet.type,
        scope: wallet.scope,
        balanceTransferred: balance !== 0 ? {
          amount: Math.abs(balance),
          to: balance > 0 ? 'Quỹ Tiết Kiệm' : 'Ví Ghi Nợ',
          transfer: transferRecord
        } : null
      }
    });

  } catch (error) {
    await session.abortTransaction();
    console.error('Lỗi xóa ví:', error);
    res.status(400).json({ error: error.message || 'Lỗi khi xóa ví' });
  } finally {
    session.endSession();
  }
};

// ===== CHUYỂN TIỀN GIỮA CÁC VÍ =====
export const transferBetweenWallets = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { error, value } = validateTransferBetweenWallets(req.body);
    if (error) {
      await session.abortTransaction();
      return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { fromWalletId, toWalletId, toUserId, amount, note } = value;

    if (!amount || amount <= 0) {
      throw new Error('Số tiền phải lớn hơn 0');
    }

    // Lấy ví nguồn
    const fromWallet = await Wallet.findById(fromWalletId).session(session);
    if (!fromWallet) {
      return res.status(404).json({ message: 'Không tìm thấy ví nguồn' });
    }

    if (!fromWallet.canUserTransact(req.userId)) {
      return res.status(403).json({ message: 'Bạn không có quyền chuyển tiền từ ví này' });
    }

    let toWallet;
    let transferType;

    // XỬ LÝ VÍ ĐÍCH
    if (toWalletId) {
      // Chỉ định ví đích cụ thể
      toWallet = await Wallet.findById(toWalletId).session(session);
      if (!toWallet) {
        return res.status(404).json({ message: 'Không tìm thấy ví đích' });
      }

      // Xác định loại transfer
      if (!fromWallet.isShared && !toWallet.isShared) {
        if (!fromWallet.userId.equals(req.userId) || !toWallet.userId.equals(req.userId)) {
          return res.status(403).json({ message: 'Chỉ có thể chuyển tiền giữa các ví cá nhân của chính mình' });
        }
        transferType = 'personal_to_personal';
      } else if (fromWallet.isShared && !toWallet.isShared) {
        const family = await Family.findById(fromWallet.familyId);
        if (!family || !family.isAdmin(req.userId)) {
          return res.status(403).json({ message: 'Chỉ admin gia đình mới có thể chuyển tiền từ ví gia đình' });
        }
        if (!family.isMember(toWallet.userId)) {
          return res.status(403).json({ message: 'Ví đích phải thuộc về thành viên của gia đình' });
        }
        transferType = 'family_to_personal';
      } else if (!fromWallet.isShared && toWallet.isShared) {
        if (!fromWallet.userId.equals(req.userId)) {
          return res.status(403).json({ message: 'Chỉ có thể chuyển từ ví cá nhân của chính mình' });
        }
        transferType = 'personal_to_family';
      } else {
        return res.status(403).json({ message: 'Không hỗ trợ chuyển tiền giữa 2 ví gia đình' });
      }

    } else if (toUserId) {
      if (!fromWallet.isShared || !fromWallet.familyId) {
        return res.status(403).json({ message: 'Chỉ có thể chuyển từ ví gia đình khi dùng toUserId' });
      }

      const family = await Family.findById(fromWallet.familyId);
      if (!family || !family.isAdmin(req.userId)) {
        return res.status(403).json({ message: 'Chỉ admin gia đình mới có thể chuyển tiền cho thành viên' });
      }

      if (!family.isMember(toUserId)) {
        return res.status(403).json({ message: 'User phải là thành viên của gia đình' });
      }

      // Tạo hoặc lấy ví nhận mặc định
      toWallet = await Wallet.getOrCreateDefaultWallet(toUserId, 'default_receive');
      transferType = 'family_to_personal';

    } else {
      throw new Error('Cần chỉ định toWalletId hoặc toUserId');
    }

    // Kiểm tra số dư (CHO PHÉP ÂM cho ví thường)
    if (fromWallet.balance < amount) {
      // Nếu số dư không đủ, ghi nợ vào ví nguồn
      console.log(`⚠️ Wallet ${fromWallet.name} going negative: ${fromWallet.balance} - ${amount}`);
    }

    // Thực hiện chuyển tiền
    fromWallet.balance -= amount;
    toWallet.balance += amount;

    await Promise.all([
      fromWallet.save({ session }),
      toWallet.save({ session })
    ]);

    // Lưu lịch sử
    const transfer = new WalletTransfer({
      fromWalletId: fromWallet._id,
      toWalletId: toWallet._id,
      amount,
      initiatedBy: req.userId,
      type: transferType,
      status: 'completed',
      note: note || (toUserId && !toWalletId ? 'Chuyển tiền từ gia đình (tự động tạo ví nhận)' : ''),
      isSystemTransfer: !!(toUserId && !toWalletId),
      metadata: {
        fromWalletName: fromWallet.name,
        toWalletName: toWallet.name,
        fromWalletBalance: fromWallet.balance,
        toWalletBalance: toWallet.balance,
        reason: toUserId && !toWalletId ? 'auto_receive' : 'user_transfer'
      }
    });

    await transfer.save({ session });

    await session.commitTransaction();

    const populatedTransfer = await WalletTransfer.findById(transfer._id)
      .populate('fromWalletId', 'name balance type')
      .populate('toWalletId', 'name balance type')
      .populate('initiatedBy', 'username email');

    res.json({
      message: 'Chuyển tiền thành công',
      data: {
        transfer: populatedTransfer,
        warning: fromWallet.balance < 0 ?
          'Ví nguồn đã vượt quá số dư và chuyển sang trạng thái âm' : null
      }
    });

  } catch (error) {
    await session.abortTransaction();
    console.error('Lỗi chuyển tiền:', error);
    res.status(400).json({ error: error.message || 'Lỗi khi chuyển tiền' });
  } finally {
    session.endSession();
  }
};

// ===== LỊCH SỬ CHUYỂN TIỀN =====
export const getTransferHistory = async (req, res) => {
  try {
    const { error, value } = validateGetTransferHistoryQuery(req.query);
    if (error) {
      return res.status(400).json({ error: 'Invalid query', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { walletId, type, limit = 50, page = 1 } = value;
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
      message: 'Lấy lịch sử chuyển tiền thành công',
      data: {
        transfers,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / limit)
        }
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
    const { error: pErr, value: pVal } = validateIdParam(req.params);
    if (pErr) {
      return res.status(400).json({ error: 'Invalid param', details: pErr.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { id } = pVal;

    const { error, value } = validateManageWalletAccess(req.body);
    if (error) {
      return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { action, userId: targetUserId, accessType } = value;
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
      data: {
        wallet: populatedWallet
      }
    });
  } catch (error) {
    console.error('Lỗi quản lý quyền truy cập:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const getWalletTransactions = async (req, res) => {
  try {
    const _user = await user.findById(req.userId);
    if (!_user) return res.status(404).json({ error: 'User không tồn tại' });

    const { walletId } = req.params;
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const skip = (page - 1) * limit;
    const { type, startDate, endDate } = req.query;

    const wallet = await Wallet.findOne({ _id: walletId, isActive: true });
    if (!wallet) {
      return res.status(404).json({ error: 'Ví không tồn tại hoặc đã bị vô hiệu hóa' });
    }

    if (!wallet.canUserView(req.userId)) {
      return res.status(403).json({ error: 'Bạn không có quyền xem giao dịch của ví này' });
    }

    const baseMatch = { walletId: wallet._id, isDeleted: false };
    if (startDate || endDate) {
      baseMatch.date = {};
      if (startDate) baseMatch.date.$gte = new Date(startDate);
      if (endDate) baseMatch.date.$lte = new Date(endDate);
    }

    const normalize = (t) => {
      const plain = t.toObject();
      return {
        id: plain._id,
        amount: plain.amount,
        type: plain.type,
        expense_for: plain.expense_for || '',
        date: plain.date,
        description: plain.description || '',
        isShared: plain.isShared || false,
        isOwner: plain.userId?._id?.toString() === req.userId.toString(),
        owner: plain.userId ? {
          id: plain.userId._id,
          username: plain.userId.username || 'Không tên',
          avatar: plain.userId.avatar || null
        } : null,
        category: plain.categoryId ? {
          id: plain.categoryId._id,
          name: plain.categoryId.name,
          image: plain.categoryId.image || '',
        } : { name: 'Không xác định' },
        wallet: plain.walletId ? {
          id: plain.walletId._id,
          name: plain.walletId.name,
          balance: plain.walletId.balance,
          scope: plain.walletId.scope,
          type: plain.walletId.type,
          icon: plain.walletId.icon
        } : null
      };
    };

    if (type && ['income', 'expense'].includes(type)) {
      const match = { ...baseMatch, type };

      const [transactions, total] = await Promise.all([
        Transaction.find(match)
          .populate('categoryId', 'name image')
          .populate('userId', 'username avatar')
          .populate('walletId', 'name balance scope type icon')
          .sort({ date: -1 })
          .skip(skip)
          .limit(limit),
        Transaction.countDocuments(match)
      ]);

      const result = transactions.map(normalize);
      return res.json({
        message: 'Lấy giao dịch theo ví thành công',
        data: {
          wallet: { id: wallet._id, name: wallet.name, balance: wallet.balance },
          transactions: result,
          pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
            hasNext: page < Math.ceil(total / limit)
          }
        }
      });
    }

    const matchIncome = { ...baseMatch, type: 'income' };
    const matchExpense = { ...baseMatch, type: 'expense' };

    const [incomeList, incomeTotal, expenseList, expenseTotal] = await Promise.all([
      transaction.find(matchIncome)
        .populate('categoryId', 'name image')
        .populate('userId', 'username avatar')
        .populate('walletId', 'name balance scope type icon')
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit),
      transaction.countDocuments(matchIncome),
      transaction.find(matchExpense)
        .populate('categoryId', 'name image')
        .populate('userId', 'username avatar')
        .populate('walletId', 'name balance scope type icon')
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit),
      transaction.countDocuments(matchExpense)
    ]);

    const income = incomeList.map(normalize);
    const expense = expenseList.map(normalize);

    return res.json({
      message: 'Lấy danh sách income/expense theo ví thành công',
      data: {
        wallet: { id: wallet._id, name: wallet.name, balance: wallet.balance },
        income: {
          items: income,
          pagination: {
            page,
            limit,
            total: incomeTotal,
            totalPages: Math.ceil(incomeTotal / limit),
            hasNext: page < Math.ceil(incomeTotal / limit)
          }
        },
        expense: {
          items: expense,
          pagination: {
            page,
            limit,
            total: expenseTotal,
            totalPages: Math.ceil(expenseTotal / limit),
            hasNext: page < Math.ceil(expenseTotal / limit)
          }
        }
      }
    });
  } catch (error) {
    console.error('Lỗi lấy giao dịch theo ví:', error);
    res.status(500).json({ error: 'Lỗi server' });
  }
};

export const payDebt = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { error, value } = validatePayDebt(req.body);
    if (error) {
      await session.abortTransaction();
      return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { fromWalletId, amount } = value;

    if (!amount || amount <= 0) {
      throw new Error('Số tiền phải lớn hơn 0');
    }

    const fromWallet = await Wallet.findById(fromWalletId).session(session);
    if (!fromWallet || !fromWallet.userId.equals(req.userId)) {
      throw new Error('Không tìm thấy ví hoặc không có quyền');
    }

    const debtWallet = await Wallet.getOrCreateDefaultWallet(req.userId, 'default_debt');

    if (debtWallet.balance >= 0) {
      throw new Error('Không có nợ cần thanh toán');
    }

    const debtAmount = Math.abs(debtWallet.balance);
    const payAmount = Math.min(amount, debtAmount);

    if (fromWallet.balance < payAmount) {
      throw new Error('Số dư không đủ để thanh toán nợ');
    }

    fromWallet.balance -= payAmount;
    debtWallet.balance += payAmount; // Tăng lên (gần về 0)

    await Promise.all([
      fromWallet.save({ session }),
      debtWallet.save({ session })
    ]);

    const transfer = new WalletTransfer({
      fromWalletId: fromWallet._id,
      toWalletId: debtWallet._id,
      amount: payAmount,
      initiatedBy: req.userId,
      type: 'system_auto_transfer',
      status: 'completed',
      note: 'Thanh toán nợ',
      isSystemTransfer: true,
      metadata: {
        fromWalletName: fromWallet.name,
        toWalletName: debtWallet.name,
        fromWalletBalance: fromWallet.balance,
        toWalletBalance: debtWallet.balance,
        reason: 'debt_payment'
      }
    });

    await transfer.save({ session });
    await session.commitTransaction();

    res.json({
      message: 'Thanh toán nợ thành công',
      data: {
        paid: payAmount,
        remaining: Math.abs(Math.min(0, debtWallet.balance))
      }
    });

  } catch (error) {
    await session.abortTransaction();
    console.error('Lỗi thanh toán nợ:', error);
    res.status(400).json({ error: error.message });
  } finally {
    session.endSession();
  }
};
