import category from "../models/category";
import user from "../models/user";

export const createCategory = async (req, res) => {
    const { name, type, keywords, scope } = req.body;
    const _user = await user.findById(req.userId).lean();

    const _category = new category({
        name,
        type,
        keywords,
        scope,
        userId: _user._id,
        familyId: _user.familyId || null
    });
    await _category.save();

    res.json({ success: true, category: _category });
};

export const updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, type, keywords } = req.body;
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

        let normalizedKeywords;
        if (Array.isArray(keywords)) {
            normalizedKeywords = [...new Set(keywords
                .filter(k => typeof k === 'string')
                .map(k => k.trim().toLowerCase())
                .filter(k => k.length > 0))];
        }

        // Chỉ cho phép sửa các trường hợp lý; không cho đổi scope
        const update = {};
        if (typeof name === 'string') update.name = name.trim();
        if (type === 'income' || type === 'expense') update.type = type;
        if (normalizedKeywords) update.keywords = normalizedKeywords;

        if (_category.scope === 'personal') update.userId = _category.userId;
        if (_category.scope === 'family') update.familyId = _category.familyId;

        const updated = await category.findByIdAndUpdate(id, update, { new: true });

        return res.json({ success: true, category: updated });
    } catch (err) {
        console.error('updateCategory error:', err);
        return res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getCategories = async (req, res) => {
    const { type } = req.query;
    const _user = await user.findById(req.userId).lean();

    const match = {
        $or: [
            { scope: 'system', isDefault: true },
            { scope: 'personal', userId: _user._id },
            { scope: 'family', familyId: _user.familyId }
        ]
    };
    if (type) match.type = type;

    const categories = await category.find(match)
        .select('name type scope keywords')
        .sort({ scope: 1, name: 1 });

    res.json({ success: true, categories });
};