// controllers/testUser.js
import User from '../models/user.js';
import Family from '../models/family.js';

export const addTestUser = async (req, res) => {
    // Chỉ cho phép trong môi trường dev
    if (process.env.NODE_ENV !== 'development') {
        return res.status(403).json({ error: 'Chỉ dùng trong dev mode' });
    }

    const { username, email, googleId, avatar, familyId, privateCode } = req.body;
    if (privateCode !== "vlxx") {
        return res.status(403).json({ error: 'Mã riêng tư không hợp lệ' });
    }

    // Bắt buộc
    if (!email || !googleId) {
        return res.status(400).json({ error: 'email và googleId là bắt buộc' });
    }

    try {
        // Kiểm tra trùng email
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: 'Email đã tồn tại' });
        }

        // Tạo user mới
        const newUser = new User({
            username: username || email.split('@')[0],
            email,
            googleId,
            avatar: avatar || `https://i.pravatar.cc/150?u=${email}`,
            familyId: null,
            isFamilyAdmin: false,
        });

        // Nếu có familyId → join nhóm
        if (familyId) {
            const family = await Family.findById(familyId);
            if (!family) {
                return res.status(404).json({ error: 'Không tìm thấy gia đình với ID này' });
            }

            // Kiểm tra đã là thành viên chưa
            if (family.members.includes(newUser._id)) {
                return res.status(400).json({ error: 'User đã là thành viên gia đình' });
            }

            newUser.familyId = family._id;
            family.members.push(newUser._id);
            await family.save();
        }

        await newUser.save();

        res.status(201).json({
            message: 'Tạo user test thành công',
            data: {
                id: newUser._id,
                username: newUser.username,
                email: newUser.email,
                familyId: newUser.familyId,
                isFamilyAdmin: newUser.isFamilyAdmin,
            },
        });
    } catch (err) {
        console.error('Add test user error:', err);
        res.status(500).json({ error: err.message });
    }
};

export const addTestBaseUser = async (req, res) => {
    try {
        const { email, password, privateCode } = req.body;
        if (privateCode !== "vlxx") {
            return res.status(403).json({ error: 'Mã riêng tư không hợp lệ' });
        }
        // Kiểm tra trùng email
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: 'Email đã tồn tại' });
        }
        // Tạo user mới
        const newUser = new User({
            email,
            password,
            googleId: null,
            avatar: null,
            familyId: null,
            isFamilyAdmin: false,
        });
        await newUser.save();
        res.status(201).json({
            message: 'Tạo user test thành công',
            data: {
                id: newUser._id,
                email: newUser.email,
            },
        });
    } catch (err) {
        console.error('Add test base user error:', err);
        res.status(500).json({ error: err.message });
    }
}

export const deleteTestUser = async (req, res) => {
    if (process.env.NODE_ENV !== 'development') {
        return res.status(403).json({ error: 'Dev only' });
    }

    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email bắt buộc' });

    const result = await User.deleteOne({ email });
    res.json({ message: 'Xóa user test', data: { deleted: result.deletedCount > 0 } });
};
