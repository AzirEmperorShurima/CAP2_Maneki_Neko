import category from "../models/category.js";
import user from "../models/user.js";
import { validateCreateCategory, validateUpdateCategory, validateGetCategoriesQuery } from "../validations/category.js";

export const createCategory = async (req, res) => {
    const { error, value } = validateCreateCategory(req.body);
    if (error) {
        return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
    }
    const { name, type, scope } = value;
    const _user = await user.findById(req.userId).lean();
    if (!_user) return res.status(404).json({ error: 'User not found' });

    const _category = new category({
        name,
        type,
        scope: scope || 'personal',
        userId: _user._id,
        familyId: _user.familyId || null,
        isDefault: scope === 'system',
    });
    await _category.save();

    res.json({ message: 'Tạo danh mục thành công', data: _category });
};

export const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { error, value } = validateUpdateCategory(req.body);
        if (error) {
            return res.status(400).json({ error: 'Invalid payload', details: error.details.map(d => ({ field: d.path.join('.'), message: d.message })) });
        }
        const { name, type } = value;
        const _user = await user.findById(req.userId).lean();

        const _category = await category.findById(id);
        if (!_category) return res.status(404).json({ error: 'Không tìm thấy category' });

        // Không cho sửa category mặc định của hệ thống
        if (_category.scope === 'system' && _category.isDefault) {
            return res.status(400).json({ error: 'Category mặc định không thể chỉnh sửa' });
        }

        // Kiểm tra quyền theo scope hiện tại
        if (_category.scope === 'personal') {
            if (_category.userId?.toString() !== req.userId.toString()) {
                return res.status(403).json({ error: 'Bạn không có quyền sửa danh mục này' });
            }
        } else if (_category.scope === 'family') {
            if (!_user?.familyId || _category.familyId?.toString() !== _user.familyId.toString()) {
                return res.status(403).json({ error: 'Bạn không có quyền sửa danh mục của gia đình này' });
            }
        }

        // Chỉ cho phép sửa các trường hợp lý; không cho đổi scope
        const update = {};
        if (typeof name === 'string') update.name = name.trim();
        if (type === 'income' || type === 'expense') update.type = type;

        if (_category.scope === 'personal') update.userId = _category.userId;
        if (_category.scope === 'family') update.familyId = _category.familyId;

        const updated = await category.findByIdAndUpdate(id, update, { new: true });

        return res.json({ message: 'Cập nhật danh mục thành công', data: updated });
    } catch (err) {
        console.error('updateCategory error:', err);
        return res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getCategories = async (req, res) => {
    try {
        const { error, value } = validateGetCategoriesQuery(req.query);
        if (error) {
            return res.status(400).json({
                error: 'Invalid query',
                details: error.details.map(d => ({
                    field: d.path.join('.'),
                    message: d.message
                }))
            });
        }
        const { type } = value;
        const _user = await user.findById(req.userId).lean();

        if (!_user) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }

        // Build query conditions
        const orConditions = [
            { scope: 'system', isDefault: true },
            { scope: 'personal', userId: _user._id }
        ];

        if (_user.familyId) {
            orConditions.push({ scope: 'family', familyId: _user.familyId });
        }

        const match = { $or: orConditions };
        if (type) {
            match.type = type;
        }

        const categories = await category.find(match)
            .select('_id name type scope userId familyId isDefault')
            .sort({ scope: 1, name: 1 })
            .lean();
        const normalizedCategories = categories.map(cat => {
            const { _id, ...rest } = cat;
            return {
                id: _id.toString(),
                ...rest,
                userId: cat.userId?.toString() || "",
                familyId: cat.familyId?.toString() || ""
            };
        });

        res.json({
            message: 'Lấy danh mục thành công',
            data: normalizedCategories
        });
    } catch (err) {
        console.error('getCategories error:', err);
        return res.status(500).json({ error: 'Lỗi server' });
    }
};