// controllers/goalController.js
import Goal from '../models/goal.js';
import Wallet from '../models/wallet.js';
import Family from '../models/family.js';
import { validateCreateGoal, validateUpdateGoal, validateAddProgress, validateLinkWallets } from '../validations/goal.js';

export const createGoal = async (req, res) => {
    try {
        const { error, value } = validateCreateGoal(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { name, description, targetAmount, deadline, associatedWallets } = value;

        // Validate associatedWallets nếu có
        const walletIds = associatedWallets || [];
        if (walletIds.length > 0) {
            const validWallets = await Wallet.find({ _id: { $in: walletIds }, userId: req.userId });
            if (validWallets.length !== walletIds.length) {
                return res.status(400).json({ error: 'Một hoặc nhiều ví không tồn tại hoặc không thuộc về bạn' });
            }
        }

        const goal = new Goal({
            userId: req.userId,
            name: name.trim(),
            description: description?.trim() || '',
            targetAmount,
            deadline: new Date(deadline),
            associatedWallets: walletIds,
            currentProgress: 0
        });

        await goal.save();

        const populatedGoal = await Goal.findById(goal._id)
            .populate('associatedWallets', 'name balance');

        res.status(201).json({
            message: 'Tạo mục tiêu thành công',
            data: populatedGoal
        });
    } catch (error) {
        console.error('Lỗi tạo mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getGoals = async (req, res) => {
    try {
        const { status, isActive } = req.query;
        const filter = { userId: req.userId };

        if (status) filter.status = status;
        if (isActive !== undefined) filter.isActive = isActive === 'true';

        const goals = await Goal.find(filter)
            .populate('associatedWallets', 'name balance')
            .sort({ createdAt: -1 });

        res.json({ message: 'Lấy danh sách mục tiêu thành công', data: goals });
    } catch (error) {
        console.error('Lỗi lấy danh sách mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getGoalById = async (req, res) => {
    try {
        const { id } = req.params;
        const goal = await Goal.findOne({ _id: id, userId: req.userId })
            .populate('associatedWallets', 'name balance');

        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        res.json({ message: 'Lấy mục tiêu thành công', data: goal });
    } catch (error) {
        console.error('Lỗi lấy mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const updateGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateUpdateGoal(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { name, description, targetAmount, deadline, associatedWallets } = value;

        const goal = await Goal.findOne({ _id: id, userId: req.userId });
        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        if (name) goal.name = name.trim();
        if (description !== undefined) goal.description = description?.trim() || '';
        if (targetAmount) goal.targetAmount = targetAmount;
        if (deadline) goal.deadline = new Date(deadline);

        // Validate associatedWallets nếu có
        if (associatedWallets !== undefined) {
            const walletIds = associatedWallets || [];
            if (walletIds.length > 0) {
                const validWallets = await Wallet.find({ _id: { $in: walletIds }, userId: req.userId });
                if (validWallets.length !== walletIds.length) {
                    return res.status(400).json({ error: 'Một hoặc nhiều ví không tồn tại hoặc không thuộc về bạn' });
                }
            }
            goal.associatedWallets = walletIds;
        }

        await goal.save();

        const populatedGoal = await Goal.findById(goal._id)
            .populate('associatedWallets', 'name balance');

        res.json({ message: 'Cập nhật mục tiêu thành công', data: populatedGoal });
    } catch (error) {
        console.error('Lỗi cập nhật mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const addProgressToGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateAddProgress(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { amount } = value;

        const goal = await Goal.findOne({ _id: id, userId: req.userId });
        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        if (!goal.isActive) {
            return res.status(400).json({ error: 'Mục tiêu không còn hoạt động' });
        }

        const newProgress = goal.currentProgress + amount;
        const result = await goal.updateProgress(newProgress);

        res.json({
            message: 'Đã cập nhật tiến độ mục tiêu',
            data: {
                currentProgress: goal.currentProgress,
                progressPercentage: result.progressPercentage,
                isCompleted: result.isCompleted
            }
        });
    } catch (error) {
        console.error('Lỗi thêm tiến độ mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const linkWalletsToGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateLinkWallets(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { walletIds } = value;

        const goal = await Goal.findOne({ _id: id, userId: req.userId });
        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        const validWallets = await Wallet.find({ _id: { $in: walletIds }, userId: req.userId });
        if (validWallets.length !== walletIds.length) {
            return res.status(400).json({ error: 'Một hoặc nhiều ví không tồn tại hoặc không thuộc về bạn' });
        }

        const existingWalletIds = goal.associatedWallets.map(w => w.toString());
        const newWalletIds = walletIds.filter(id => !existingWalletIds.includes(id.toString()));

        if (newWalletIds.length === 0) {
            return res.status(400).json({ error: 'Tất cả các ví đã được liên kết với mục tiêu này' });
        }

        goal.associatedWallets.push(...newWalletIds);
        await goal.save();

        const populatedGoal = await Goal.findById(goal._id)
            .populate('associatedWallets', 'name balance');

        res.json({
            message: 'Đã liên kết các ví với mục tiêu',
            data: populatedGoal
        });
    } catch (error) {
        console.error('Lỗi liên kết ví với mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const unlinkWalletFromGoal = async (req, res) => {
    try {
        const { id, walletId } = req.params;

        const goal = await Goal.findOne({ _id: id, userId: req.userId });
        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        const wallet = await Wallet.findOne({ _id: walletId, userId: req.userId });
        if (!wallet) {
            return res.status(404).json({ error: 'Không tìm thấy ví' });
        }

        const initialLength = goal.associatedWallets.length;
        goal.associatedWallets = goal.associatedWallets.filter(w => !w.equals(walletId));

        if (goal.associatedWallets.length === initialLength) {
            return res.status(400).json({ error: 'Ví không được liên kết với mục tiêu này' });
        }

        await goal.save();

        const populatedGoal = await Goal.findById(goal._id)
            .populate('associatedWallets', 'name balance');

        res.json({
            message: 'Đã hủy liên kết ví với mục tiêu',
            data: populatedGoal
        });
    } catch (error) {
        console.error('Lỗi hủy liên kết ví:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const deleteGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const goal = await Goal.findOne({ _id: id, userId: req.userId });

        if (!goal) {
            return res.status(404).json({ error: 'Không tìm thấy mục tiêu' });
        }

        await Goal.deleteOne({ _id: id, userId: req.userId });
        res.json({ message: 'Đã xóa mục tiêu' });
    } catch (error) {
        console.error('Lỗi xóa mục tiêu:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};
