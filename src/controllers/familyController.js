import Family from '../models/family.js';
import User from '../models/user.js';
import Transaction from '../models/transaction.js';
import Category from '../models/category.js';
import { sendFamilyInviteEmail } from '../services/mail/sendMailService.js';
import { themedPage } from '../utils/webTheme.js';
import { StatusCodes } from 'http-status-codes';
import dayjs from 'dayjs';
import crypto from 'crypto';
import PushNotificationService from '../services/pushNotificationService.js';
import { sendFamilyInviteNotification } from '../utils/notificationHelper.js';
import { formatFamilyResponse } from '../utils/family.js';

const generateInviteCode = async (length = 8) => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const charLen = chars.length;
    let attempts = 0;
    const maxAttempts = 100;
    for (; ;) {
        let code = '';
        const buf = crypto.randomBytes(length);
        for (let i = 0; i < length; i++) code += chars[buf[i] % charLen];
        const exists = await Family.findOne({ inviteCode: code }).lean();
        if (!exists) return code;
        attempts++;
        if (attempts >= maxAttempts) {
            attempts = 0;
            length += 1;
        }
    }
};

export const createFamily = async (req, res) => {
    const { name } = req.body;

    if (!name || name.trim().length < 2) {
        return res.status(400).json({
            error: 'Tên gia đình phải có ít nhất 2 ký tự'
        });
    }

    try {
        // Kiểm tra user đã thuộc family nào chưa (check cả familyId và members)
        const existingUser = await User.findById(req.userId).select('familyId');
        if (existingUser?.familyId) {
            return res.status(400).json({
                error: 'Bạn đã thuộc một gia đình. Hãy rời nhóm trước khi tạo mới.'
            });
        }

        // Double check: Kiểm tra xem user có trong members của family nào không
        const existsInMembers = await Family.findOne({ members: req.userId }).select('_id');
        if (existsInMembers) {
            return res.status(400).json({
                error: 'Bạn đã là thành viên của một gia đình. Hãy rời nhóm hiện tại trước.'
            });
        }

        // Tạo family mới
        const family = new Family({
            name: name.trim(),
            adminId: req.userId,
            members: [req.userId],
            inviteCode: await generateInviteCode()
        });

        await family.save();

        // Cập nhật user
        await User.findByIdAndUpdate(
            req.userId,
            {
                familyId: family._id,
                isFamilyAdmin: true
            },
            { new: true }
        );

        // Lấy family với thông tin đầy đủ
        const populatedFamily = await Family.findById(family._id)
            .populate('adminId', 'username email avatar')
            .populate('members', 'username email avatar');

        // Format response chuẩn
        const formattedFamily = formatFamilyResponse(populatedFamily, req.userId);

        res.status(201).json({
            message: 'Đã tạo nhóm gia đình thành công',
            data: formattedFamily
        });
    } catch (error) {
        console.error('Lỗi tạo family:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};


export const generateInviteLink = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user || !user.familyId || !user.isFamilyAdmin) {
            return res.status(403).json({ error: 'Chỉ admin mới tạo link mời' });
        }

        const family = await Family.findById(user.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        if (!family.inviteCode) {
            family.inviteCode = await generateInviteCode();
            await family.save();
        }

        const inviteLink = `${process.env.APP_URL}/join?familyCode=${family.inviteCode}`;

        res.json({ message: 'Link mời đã tạo', data: { inviteLink } });
    } catch (error) {
        console.error('Lỗi tạo invite link:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const sendInviteEmail = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ error: 'Email là bắt buộc' });

        const admin = await User.findById(req.userId);
        if (!admin || !admin.familyId || !admin.isFamilyAdmin) {
            return res.status(403).json({ error: 'Bạn phải ở trong 1 gia đình và là admin của gia đình' });
        }

        const family = await Family.findById(admin.familyId);
        if (!family) return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        if (!family.isActive) return res.status(400).json({ error: 'Gia đình đã bị vô hiệu hóa' });

        const existingMember = await User.findOne({ email, familyId: family._id });
        if (existingMember) return res.status(400).json({ error: 'Đã là thành viên' });

        const expiresAt = dayjs().add(7, 'day').toDate();
        family.upsertPendingInvite(email, req.userId, expiresAt);
        await family.save();

        if (!family.inviteCode) {
            family.inviteCode = await generateInviteCode();
            await family.save();
        }

        const deepLink = `myapp://join-invite?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;
        const webJoinLink = `${process.env.APP_URL}/api/family/join-web?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;

        const userExists = await User.findOne({ email });
        const userExistsBool = !!userExists;

        res.json({
            message: 'Đã gửi lời mời',
            data: {
                webJoinLink,
                deepLink,
                userExists: userExistsBool
            }
        });

        const adminName = admin.username || admin.email;
        setImmediate(() => {
            sendFamilyInviteEmail({
                to: email,
                adminName,
                familyName: family.name,
                webJoinLink,
                deepLink,
                userExists: userExistsBool,
            }).catch((error) => {
                console.log('Error sending email:', error);
            });
        });

        if (userExistsBool) {
            setImmediate(async () => {
                try {
                    await sendFamilyInviteNotification(
                        userExists._id,
                        family.name,
                        adminName,
                        family._id.toString()
                    );
                } catch (error) {
                    console.error('Error sending push notification:', error);
                }
            });
        }
    } catch (error) {
        console.error('Lỗi gửi invite email:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const joinFamilyWeb = async (req, res) => {
    const { familyCode, email } = req.query;

    if (!familyCode || !email || !/^\S+@\S+\.\S+$/.test(email)) {
        return res.status(400).send(themedPage(`
            <h2 style="margin:0 0 8px;color:#ef4444;text-align:center">Lỗi</h2>
            <p style="color:#6b7280;text-align:center">Thông tin không hợp lệ. Vui lòng sử dụng link từ email.</p>
            <div style="text-align:center;margin-top:16px">
              <a href="/" style="color:#7c3aed;text-decoration:underline">Quay lại trang chủ</a>
            </div>
        `));
    }

    try {
        const family = await Family.findOne({ inviteCode: familyCode })
            .populate('adminId', 'username email');

        if (!family) {
            return res.status(404).send(themedPage(`
                <h2 style="margin:0 0 8px;color:#ef4444;text-align:center">Mã mời không hợp lệ</h2>
                <p style="color:#6b7280;text-align:center">Mã mời bạn sử dụng không tồn tại hoặc đã hết hạn.</p>
                <div style="text-align:center;margin-top:16px">
                  <a href="/" style="color:#7c3aed;text-decoration:underline">Quay lại trang chủ</a>
                </div>
            `));
        }

        if (!family.isActive) {
            return res.status(400).send(themedPage(`
                <h2 style="margin:0 0 8px;color:#ef4444;text-align:center">Gia đình đã bị vô hiệu hóa</h2>
                <p style="color:#6b7280;text-align:center">Không thể tham gia vào lúc này.</p>
            `));
        }

        if (!family.hasValidPendingInvite(email)) {
            return res.status(400).send(themedPage(`
                <h2 style="margin:0 0 8px;color:#ef4444;text-align:center">Lời mời đã hết hạn</h2>
                <p style="color:#6b7280;text-align:center">Lời mời này đã hết hạn hoặc không tồn tại.</p>
                <p style="text-align:center"><a href="mailto:${family.adminId.email}" style="color:#ec4899;text-decoration:underline">Liên hệ admin</a> để được mời lại.</p>
            `));
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(400).send(themedPage(`
                <h2 style="margin:0 0 8px;color:#f59e0b;text-align:center">Chưa có tài khoản</h2>
                <p style="color:#6b7280;text-align:center">Tài khoản email này chưa được đăng ký.</p>
                <div style="max-width:460px;margin:12px auto;color:#374151">
                  <ol style="text-align:left;display:inline-block;line-height:1.6">
                    <li>Mở app <strong>Quản Lý Chi Tiêu</strong></li>
                    <li>Đăng ký/đăng nhập với email <strong>${email}</strong></li>
                    <li>Sử dụng lại link mời này</li>
                  </ol>
                </div>
                <div style="text-align:center;margin-top:16px">
                  <a href="myapp://join-invite?familyCode=${familyCode}&email=${encodeURIComponent(email)}" style="display:inline-block;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;padding:10px 20px;text-decoration:none;border-radius:9999px;font-weight:bold;margin-right:10px;">Mở App</a>
                  <a href="/" style="color:#7c3aed;text-decoration:underline">Trang chủ</a>
                </div>
            `));
        }

        if (family.isMember(user._id)) {
            family.removePendingInvite(email);
            await family.save();

            return res.send(themedPage(`
                <h2 style="margin:0 0 8px;color:#22c55e;text-align:center">✅ Đã là thành viên</h2>
                <p style="color:#6b7280;text-align:center">Bạn đã tham gia gia đình <strong>${family.name}</strong> rồi!</p>
                <div style="text-align:center;margin-top:16px">
                  <a href="myapp://home" style="display:inline-block;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;padding:12px 24px;text-decoration:none;border-radius:9999px;font-weight:bold">Mở App</a>
                </div>
            `));
        }

        // Kiểm tra user đã thuộc family khác chưa
        if (user.familyId && user.familyId.toString() !== family._id.toString()) {
            return res.status(400).send(themedPage(`
                <h2 style="margin:0 0 8px;color:#f59e0b;text-align:center">Cảnh báo</h2>
                <p style="color:#6b7280;text-align:center">Bạn hiện đang thuộc một gia đình khác.</p>
                <p style="color:#6b7280;text-align:center">Vui lòng rời gia đình hiện tại trước khi tham gia gia đình mới.</p>
                <div style="text-align:center;margin-top:16px">
                  <a href="myapp://home" style="display:inline-block;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;padding:10px 20px;text-decoration:none;border-radius:9999px;font-weight:bold">Mở App</a>
                </div>
            `));
        }

        family.addMember(user._id);
        family.removePendingInvite(email);
        await family.save();

        await User.findByIdAndUpdate(user._id, {
            familyId: family._id,
            isFamilyAdmin: false
        });

        res.send(themedPage(`
            <h2 style="margin:0 0 8px;color:#22c55e;text-align:center">🎉 Tham gia thành công!</h2>
            <p style="color:#6b7280;text-align:center">Chào mừng bạn đến với gia đình <strong>${family.name}</strong></p>
            <p style="color:#6b7280;text-align:center"><strong>${family.adminId.username}</strong> là admin hiện tại.</p>
            <div style="text-align:center;margin-top:16px">
              <a href="myapp://home" style="display:inline-block;background:linear-gradient(135deg,#7c3aed,#ec4899);color:#fff;padding:12px 24px;text-decoration:none;border-radius:9999px;font-weight:bold;margin:5px;">Mở App</a>
              <a href="/" style="color:#7c3aed;text-decoration:underline;margin:5px">Trang chủ web</a>
            </div>
        `));
    } catch (err) {
        console.error('Lỗi join family:', err);
        res.status(500).send(themedPage(`
            <h2 style="margin:0 0 8px;color:#ef4444;text-align:center">Lỗi hệ thống</h2>
            <p style="color:#6b7280;text-align:center">Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.</p>
            <div style="text-align:center;margin-top:16px">
              <a href="/" style="color:#7c3aed;text-decoration:underline">Quay lại trang chủ</a>
            </div>
        `));
    }
};
export const joinFamilyApp = async (req, res) => {
    try {
        const { familyCode: rawFamilyCode } = req.body;
        const userId = req.userId;
        const familyCode = (rawFamilyCode || '').trim();
        if (!userId) {
            return res.status(401).json({ error: 'Bạn cần đăng nhập' });
        }
        if (!familyCode) {
            return res.status(400).json({ error: 'Thông tin không hợp lệ. Cần mã gia đình (familyCode).' });
        }

        const family = await Family.findOne({ inviteCode: familyCode }).populate('adminId', 'username email avatar');
        if (!family) {
            return res.status(404).json({ error: 'Mã mời không hợp lệ hoặc đã hết hạn' });
        }
        if (!family.isActive) {
            return res.status(400).json({ error: 'Gia đình đã bị vô hiệu hóa' });
        }

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }

        if (family.isMember(user._id)) {
            return res.json({
                message: 'Bạn đã là thành viên của gia đình này',
                data: {
                    familyId: family._id,
                    familyName: family.name
                }
            });
        }

        if (user.familyId && user.familyId.toString() !== family._id.toString()) {
            return res.status(400).json({ error: 'Bạn đang thuộc một gia đình khác. Vui lòng rời gia đình hiện tại trước.' });
        }

        family.addMember(user._id);
        await family.save();

        await User.findByIdAndUpdate(user._id, {
            familyId: family._id,
            isFamilyAdmin: false
        });

        const plain = typeof family.toObject === 'function' ? family.toObject() : family;
        const normalized = {
            id: plain._id,
            name: plain.name || '',
            admin_id: plain.adminId?._id?.toString() || (plain.adminId ? String(plain.adminId) : ''),
            members: Array.isArray(plain.members) ? plain.members.map(m => (m && m.toString ? m.toString() : String(m))) : []
        };

        return res.json({
            message: 'Tham gia gia đình thành công',
            data: normalized
        });
    } catch (err) {
        console.error('Lỗi join family app:', err);
        res.status(500).json({ error: 'Lỗi server' });
    }
}

export const leaveFamily = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        // SỬA: dùng method isAdmin
        const isAdmin = family.isAdmin(req.userId);

        // SỬA: dùng method removeMember
        family.removeMember(req.userId);

        if (isAdmin) {
            if (family.members.length > 0) {
                // Chuyển admin cho thành viên khác
                family.adminId = family.members[0];
                await User.findByIdAndUpdate(family.members[0], { isFamilyAdmin: true });
                await family.save();
            } else {
                // Xóa family nếu không còn thành viên
                await Family.deleteOne({ _id: family._id });
                await User.findByIdAndUpdate(req.userId, {
                    familyId: null,
                    isFamilyAdmin: false
                });
                return res.json({ message: 'Đã xóa nhóm gia đình (thành viên cuối cùng)' });
            }
        } else {
            await family.save();
        }

        await User.findByIdAndUpdate(req.userId, {
            familyId: null,
            isFamilyAdmin: false
        });

        res.json({ message: 'Đã rời nhóm gia đình' });
    } catch (error) {
        console.error('Lỗi leave family:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFamilyMembers = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId)
            .populate('members', 'username email avatar');

        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        res.json({ message: 'Lấy danh sách thành viên gia đình thành công', data: family.members });
    } catch (error) {
        console.error('Lỗi get family members:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const dissolveFamily = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user) {
            return res.status(StatusCodes.BAD_REQUEST).json({
                error: 'Unauthorized'
            });
        }
        if (!user.familyId) {
            return res.status(StatusCodes.BAD_REQUEST).json({
                error: 'Bạn chưa tham gia nhóm nào'
            });
        }

        const family = await Family.findById(user.familyId);
        if (!family) {
            return res.status(StatusCodes.NOT_FOUND).json({
                error: 'Không tìm thấy gia đình'
            });
        }

        if (!family.isAdmin(req.userId)) {
            return res.status(StatusCodes.FORBIDDEN).json({
                error: 'Chỉ có admin mới có thể phá hủy nhóm'
            });
        }

        await Family.deleteOne({ _id: family._id });
        await User.updateMany(
            { familyId: family._id },
            { familyId: null, isFamilyAdmin: false }
        );

        res.status(StatusCodes.OK).json({ message: 'Đã phá hủy nhóm gia đình' });
    } catch (err) {
        console.error('Lỗi dissolve family:', err);
        res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({ error: 'Lỗi hệ thống' });
    }
};

export const updateSharingSettings = async (req, res) => {
    try {
        const userDoc = await User.findById(req.userId);
        if (!userDoc?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(userDoc.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        // SỬA: dùng method isAdmin
        if (!family.isAdmin(req.userId)) {
            return res.status(403).json({ error: 'Chỉ admin mới chỉnh chia sẻ' });
        }

        const { transactionVisibility, walletVisibility, goalVisibility } = req.body;
        const tv = ['all', 'only_income', 'none'];
        const wv = ['all', 'owner_only', 'summary_only'];
        const gv = ['all', 'owner_only'];

        if (transactionVisibility && !tv.includes(transactionVisibility)) {
            return res.status(400).json({ error: 'transactionVisibility không hợp lệ' });
        }
        if (walletVisibility && !wv.includes(walletVisibility)) {
            return res.status(400).json({ error: 'walletVisibility không hợp lệ' });
        }
        if (goalVisibility && !gv.includes(goalVisibility)) {
            return res.status(400).json({ error: 'goalVisibility không hợp lệ' });
        }

        family.sharingSettings = {
            transactionVisibility: transactionVisibility || family.sharingSettings.transactionVisibility,
            walletVisibility: walletVisibility || family.sharingSettings.walletVisibility,
            goalVisibility: goalVisibility || family.sharingSettings.goalVisibility,
        };

        await family.save();
        res.json({ message: 'Cập nhật thiết lập chia sẻ thành công', data: family.sharingSettings });
    } catch (error) {
        console.error('Lỗi update sharing settings:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const addSharedResource = async (req, res) => {
    try {
        const userDoc = await User.findById(req.userId);
        if (!userDoc?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(userDoc.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        // SỬA: dùng method isAdmin
        if (!family.isAdmin(req.userId)) {
            return res.status(403).json({ error: 'Chỉ admin mới chỉnh tài nguyên' });
        }

        const { resourceType, resourceId } = req.body;
        const allowed = ['budgets', 'wallets', 'goals'];
        if (!allowed.includes(resourceType)) {
            return res.status(400).json({ error: 'resourceType không hợp lệ' });
        }

        // SỬA: method đã có sẵn trong schema
        const added = await family.addSharedResource(resourceType, resourceId);
        res.json({ message: 'Đã thêm tài nguyên chia sẻ', data: added });
    } catch (error) {
        console.error('Lỗi add shared resource:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const removeSharedResource = async (req, res) => {
    try {
        const userDoc = await User.findById(req.userId);
        if (!userDoc?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(userDoc.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        if (!family.isAdmin(req.userId)) {
            return res.status(403).json({ error: 'Chỉ admin mới chỉnh tài nguyên' });
        }

        const { resourceType, resourceId } = req.body;
        const allowed = ['budgets', 'wallets', 'goals'];
        if (!allowed.includes(resourceType)) {
            return res.status(400).json({ error: 'resourceType không hợp lệ' });
        }

        // SỬA: gọi method từ family, không phải family.adminId
        const removed = await family.removeSharedResource(resourceType, resourceId);
        res.json({ message: 'Đã xóa tài nguyên chia sẻ', data: removed });
    } catch (error) {
        console.error('Lỗi remove shared resource:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const addFamilyMember = async (req, res) => {
    try {
        const admin = await User.findById(req.userId);
        if (!admin?.familyId || !admin.isFamilyAdmin) {
            return res.status(403).json({ error: 'Chỉ admin mới có thể thêm thành viên' });
        }
        const { email, userId } = req.body;
        let targetUser = null;
        if (userId) {
            targetUser = await User.findById(userId);
        } else if (email) {
            targetUser = await User.findOne({ email });
        } else {
            return res.status(400).json({ error: 'Cần cung cấp email hoặc userId' });
        }
        if (!targetUser) {
            return res.status(404).json({ error: 'Không tìm thấy người dùng' });
        }
        const family = await Family.findById(admin.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }
        if (targetUser.familyId && targetUser.familyId.toString() !== family._id.toString()) {
            return res.status(400).json({ error: 'User đang thuộc gia đình khác' });
        }
        if (family.isMember(targetUser._id)) {
            return res.status(400).json({ error: 'Đã là thành viên' });
        }
        family.addMember(targetUser._id);
        await family.save();
        targetUser.familyId = family._id;
        targetUser.isFamilyAdmin = false;
        await targetUser.save();
        const added = await User.findById(targetUser._id).select('username email avatar');
        const normalized = { id: added._id.toString(), username: added.username, email: added.email, avatar: added.avatar };
        res.json({ message: 'Đã thêm thành viên', data: normalized });
    } catch (error) {
        console.error('addFamilyMember error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const removeFamilyMember = async (req, res) => {
    try {
        const admin = await User.findById(req.userId);
        if (!admin?.familyId || !admin.isFamilyAdmin) {
            return res.status(403).json({ error: 'Chỉ admin mới có thể xóa thành viên' });
        }
        const { userId } = req.body;
        if (!userId) {
            return res.status(400).json({ error: 'Cần cung cấp userId' });
        }
        const family = await Family.findById(admin.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }
        if (!family.isMember(userId)) {
            return res.status(404).json({ error: 'User không phải là thành viên' });
        }
        if (family.adminId.toString() === userId.toString()) {
            return res.status(400).json({ error: 'Không thể xóa admin hiện tại' });
        }
        family.removeMember(userId);
        await family.save();
        await User.findByIdAndUpdate(userId, { familyId: null, isFamilyAdmin: false });
        res.json({ message: 'Đã xóa thành viên' });
    } catch (error) {
        console.error('removeFamilyMember error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFamilySpendingSummary = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId).populate('members', '_id username email avatar');
        if (!family || !family.isMember(req.userId)) {
            return res.status(403).json({ error: 'Không có quyền truy cập gia đình này' });
        }

        let { startDate, endDate, range } = req.query;
        let periodLabel = '';

        // Nếu có range, tính startDate và endDate theo range
        if (range) {
            const now = new Date();

            switch (range.toLowerCase()) {
                case 'week': {
                    // Tuần hiện tại (Thứ 2 đến Chủ nhật)
                    const dayOfWeek = now.getDay(); // 0 = Chủ nhật, 1 = Thứ 2, ...
                    const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

                    startDate = new Date(now);
                    startDate.setDate(now.getDate() + diffToMonday);
                    startDate.setHours(0, 0, 0, 0);

                    endDate = new Date(startDate);
                    endDate.setDate(startDate.getDate() + 6);
                    endDate.setHours(23, 59, 59, 999);

                    periodLabel = 'Tuần này';
                    break;
                }

                case 'month': {
                    // Tháng hiện tại
                    startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                    startDate.setHours(0, 0, 0, 0);

                    endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
                    endDate.setHours(23, 59, 59, 999);

                    periodLabel = `Tháng ${now.getMonth() + 1}/${now.getFullYear()}`;
                    break;
                }

                case 'quarter': {
                    // Quý hiện tại (Q1: 1-3, Q2: 4-6, Q3: 7-9, Q4: 10-12)
                    const currentMonth = now.getMonth();
                    const quarterStartMonth = Math.floor(currentMonth / 3) * 3;
                    const quarterNumber = Math.floor(currentMonth / 3) + 1;

                    startDate = new Date(now.getFullYear(), quarterStartMonth, 1);
                    startDate.setHours(0, 0, 0, 0);

                    endDate = new Date(now.getFullYear(), quarterStartMonth + 3, 0);
                    endDate.setHours(23, 59, 59, 999);

                    periodLabel = `Quý ${quarterNumber}/${now.getFullYear()}`;
                    break;
                }

                case 'year': {
                    // Năm hiện tại
                    startDate = new Date(now.getFullYear(), 0, 1);
                    startDate.setHours(0, 0, 0, 0);

                    endDate = new Date(now.getFullYear(), 11, 31);
                    endDate.setHours(23, 59, 59, 999);

                    periodLabel = `Năm ${now.getFullYear()}`;
                    break;
                }

                default: {
                    return res.status(400).json({
                        error: 'Range không hợp lệ. Chỉ chấp nhận: week, month, quarter, year'
                    });
                }
            }
        } else if (!startDate && !endDate) {
            // Nếu không có range và không có startDate/endDate, mặc định là tháng hiện tại
            const now = new Date();
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
            startDate.setHours(0, 0, 0, 0);

            endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
            endDate.setHours(23, 59, 59, 999);

            periodLabel = `Tháng ${now.getMonth() + 1}/${now.getFullYear()}`;
        } else {
            // Xử lý startDate và endDate tùy chỉnh
            if (startDate) {
                startDate = new Date(startDate);
                startDate.setHours(0, 0, 0, 0);
            }
            if (endDate) {
                endDate = new Date(endDate);
                endDate.setHours(23, 59, 59, 999);
            }
            periodLabel = 'Tùy chỉnh';
        }

        // Lấy danh sách userId của các thành viên trong family
        const memberIds = family.members.map(m => m._id);

        // Match condition cho tất cả giao dịch của family members
        const match = {
            userId: { $in: memberIds },
            isDeleted: { $ne: true }
        };

        // Thêm filter theo ngày
        if (startDate || endDate) {
            match.date = {};
            if (startDate) match.date.$gte = startDate;
            if (endDate) match.date.$lte = endDate;
        }

        // Tổng thu chi theo loại
        const totals = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: '$type',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        // Thu chi theo member (cho biểu đồ cột)
        const memberSummary = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: {
                        userId: '$userId',
                        type: '$type'
                    },
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            {
                $group: {
                    _id: '$_id.userId',
                    income: {
                        $sum: {
                            $cond: [
                                { $eq: ['$_id.type', 'income'] },
                                '$total',
                                0
                            ]
                        }
                    },
                    expense: {
                        $sum: {
                            $cond: [
                                { $eq: ['$_id.type', 'expense'] },
                                '$total',
                                0
                            ]
                        }
                    },
                    incomeCount: {
                        $sum: {
                            $cond: [
                                { $eq: ['$_id.type', 'income'] },
                                '$count',
                                0
                            ]
                        }
                    },
                    expenseCount: {
                        $sum: {
                            $cond: [
                                { $eq: ['$_id.type', 'expense'] },
                                '$count',
                                0
                            ]
                        }
                    }
                }
            },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'user'
                }
            },
            { $unwind: '$user' },
            {
                $project: {
                    _id: 0,
                    userId: { $toString: '$_id' },
                    username: '$user.username',
                    email: '$user.email',
                    avatar: '$user.avatar',
                    income: 1,
                    expense: 1,
                    balance: { $subtract: ['$income', '$expense'] },
                    incomeCount: 1,
                    expenseCount: 1
                }
            },
            { $sort: { expense: -1 } }
        ]);

        // Thu nhập theo danh mục
        // const incByCategory = await Transaction.aggregate([
        //     { $match: { ...match, type: 'income' } },
        //     {
        //         $group: {
        //             _id: '$categoryId',
        //             total: { $sum: '$amount' },
        //             count: { $sum: 1 }
        //         }
        //     },
        //     {
        //         $lookup: {
        //             from: 'categories',
        //             localField: '_id',
        //             foreignField: '_id',
        //             as: 'category'
        //         }
        //     },
        //     {
        //         $unwind: {
        //             path: '$category',
        //             preserveNullAndEmptyArrays: true
        //         }
        //     },
        //     {
        //         $project: {
        //             _id: 0,
        //             categoryId: { $toString: '$_id' },
        //             categoryName: { $ifNull: ['$category.name', 'Không phân loại'] },
        //             total: 1,
        //             count: 1
        //         }
        //     },
        //     { $sort: { total: -1 } }
        // ]);

        const totalExpense = totals.find(t => t._id === 'expense')?.total || 0;
        const totalIncome = totals.find(t => t._id === 'income')?.total || 0;

        // Tính phần trăm cho income by category
        incByCategory.forEach(item => {
            item.percentage = totalIncome > 0
                ? Math.round((item.total / totalIncome) * 100 * 100) / 100
                : 0;
        });

        res.json({
            message: 'Lấy báo cáo tổng chi tiêu gia đình thành công',
            data: {
                period: {
                    startDate: startDate,
                    endDate: endDate,
                    range: range || 'custom',
                    label: periodLabel
                },
                totals: {
                    expense: totalExpense,
                    income: totalIncome,
                    balance: totalIncome - totalExpense,
                    transactionCount: totals.reduce((sum, t) => sum + t.count, 0)
                },
                memberSummary: memberSummary,
                // incomeByCategory: incByCategory
            }
        });
    } catch (error) {
        console.error('getFamilySpendingSummary error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFamilyUserBreakdown = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId);
        if (!family || !family.isMember(req.userId)) {
            return res.status(403).json({ error: 'Không có quyền truy cập gia đình này' });
        }

        const { startDate, endDate } = req.query;

        const memberIds = family.members;

        const match = {
            userId: { $in: memberIds },
            isDeleted: false
        };

        if (startDate || endDate) {
            match.date = {};
            if (startDate) match.date.$gte = new Date(startDate);
            if (endDate) match.date.$lte = new Date(endDate);
        }
        const totalCount = await Transaction.countDocuments(match);

        const breakdown = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: '$userId',
                    totalExpense: {
                        $sum: {
                            $cond: [{ $eq: ['$type', 'expense'] }, '$amount', 0]
                        }
                    },
                    expenseCount: {
                        $sum: {
                            $cond: [{ $eq: ['$type', 'expense'] }, 1, 0]
                        }
                    },
                    totalIncome: {
                        $sum: {
                            $cond: [{ $eq: ['$type', 'income'] }, '$amount', 0]
                        }
                    },
                    incomeCount: {
                        $sum: {
                            $cond: [{ $eq: ['$type', 'income'] }, 1, 0]
                        }
                    },
                    totalTransactions: { $sum: 1 }
                }
            },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'userInfo'
                }
            },
            {
                $unwind: {
                    path: '$userInfo',
                    preserveNullAndEmptyArrays: true
                }
            },
            {
                $project: {
                    _id: 0,
                    userId: { $toString: '$_id' },
                    username: { $ifNull: ['$userInfo.username', 'Unknown User'] },
                    email: { $ifNull: ['$userInfo.email', ''] },
                    avatar: { $ifNull: ['$userInfo.avatar', ''] },
                    expense: {
                        total: '$totalExpense',
                        count: '$expenseCount'
                    },
                    income: {
                        total: '$totalIncome',
                        count: '$incomeCount'
                    },
                    balance: { $subtract: ['$totalIncome', '$totalExpense'] },
                    totalTransactions: 1
                }
            },
            { $sort: { 'expense.total': -1 } }
        ]);

        let finalBreakdown = breakdown;
        if (breakdown.length === 0) {
            const members = await User.find({ _id: { $in: memberIds } })
                .select('username email avatar')
                .lean();

            finalBreakdown = members.map(member => ({
                userId: member._id.toString(),
                username: member.username || 'Unknown User',
                email: member.email || '',
                avatar: member.avatar || '',
                expense: {
                    total: 0,
                    count: 0
                },
                income: {
                    total: 0,
                    count: 0
                },
                balance: 0,
                totalTransactions: 0
            }));
        }

        const summary = {
            totalExpense: finalBreakdown.reduce((sum, item) => sum + item.expense.total, 0),
            totalIncome: finalBreakdown.reduce((sum, item) => sum + item.income.total, 0),
            totalTransactions: finalBreakdown.reduce((sum, item) => sum + item.totalTransactions, 0),
            memberCount: family.members.length
        };
        summary.familyBalance = summary.totalIncome - summary.totalExpense;

        // Tạo data cho biểu đồ tròn - phân bổ chi tiêu theo thành viên
        const expenseChartData = finalBreakdown
            .filter(item => item.expense.total > 0) // Chỉ lấy members có chi tiêu
            .map(item => ({
                name: item.username,
                value: item.expense.total,
                percentage: summary.totalExpense > 0
                    ? parseFloat(((item.expense.total / summary.totalExpense) * 100).toFixed(1))
                    : 0,
                userId: item.userId
            }))
            .sort((a, b) => b.value - a.value);

        const incomeChartData = finalBreakdown
            .filter(item => item.income.total > 0)
            .map(item => ({
                name: item.username,
                value: item.income.total,
                percentage: summary.totalIncome > 0
                    ? parseFloat(((item.income.total / summary.totalIncome) * 100).toFixed(1))
                    : 0,
                userId: item.userId
            }))
            .sort((a, b) => b.value - a.value);

        res.json({
            message: 'Lấy phân tích theo thành viên thành công',
            data: {
                period: {
                    startDate: startDate || null,
                    endDate: endDate || null
                },
                summary,
                breakdown: finalBreakdown,
                charts: {
                    expense: {
                        title: 'Phân bổ chi tiêu theo thành viên',
                        data: expenseChartData,
                        total: summary.totalExpense
                    },
                    income: {
                        title: 'Phân bổ thu nhập theo thành viên',
                        data: incomeChartData,
                        total: summary.totalIncome
                    }
                }
            }
        });
    } catch (error) {
        console.error('getFamilyUserBreakdown error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFamilyTopCategories = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId);
        if (!family || !family.isMember(req.userId)) {
            return res.status(403).json({ error: 'Không có quyền truy cập gia đình này' });
        }

        const { startDate, endDate, limit = '5', type = 'expense' } = req.query;

        // Lấy transaction của tất cả members trong family (không cần isShared)
        const memberIds = family.members;

        const match = {
            userId: { $in: memberIds },
            isDeleted: false,
            type: type // 'expense' hoặc 'income'
        };

        // Thêm filter theo thời gian nếu có
        if (startDate || endDate) {
            match.date = {};
            if (startDate) match.date.$gte = new Date(startDate);
            if (endDate) match.date.$lte = new Date(endDate);
        }

        console.log('Match condition:', JSON.stringify(match, null, 2));

        // Aggregate để lấy top categories
        const topCategories = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: '$categoryId',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            {
                $lookup: {
                    from: 'categories',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'categoryInfo'
                }
            },
            {
                $unwind: {
                    path: '$categoryInfo',
                    preserveNullAndEmptyArrays: true
                }
            },
            {
                $project: {
                    _id: 0,
                    categoryId: {
                        $cond: [
                            { $ifNull: ['$_id', false] },
                            { $toString: '$_id' },
                            null
                        ]
                    },
                    categoryName: {
                        $ifNull: ['$categoryInfo.name', 'Không phân loại']
                    },
                    total: 1,
                    count: 1,
                    percentage: { $literal: 0 }
                }
            },
            { $sort: { total: -1 } },
            { $limit: parseInt(limit) || 5 }
        ]);

        console.log('Top categories result:', JSON.stringify(topCategories, null, 2));

        // Tính tổng amount để tính percentage
        const grandTotal = topCategories.reduce((sum, item) => sum + item.total, 0);

        // Thêm percentage vào từng category
        const topWithPercentage = topCategories.map(item => ({
            ...item,
            percentage: grandTotal > 0
                ? parseFloat(((item.total / grandTotal) * 100).toFixed(1))
                : 0
        }));

        // Tính tổng của TẤT CẢ categories (không chỉ top)
        const allCategoriesTotal = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: null,
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        const summary = {
            total: allCategoriesTotal[0]?.total || 0,
            count: allCategoriesTotal[0]?.count || 0,
            topCategoriesTotal: grandTotal,
            categoryCount: topCategories.length
        };

        // Tạo data cho biểu đồ tròn
        const chartData = topWithPercentage.map(item => ({
            name: item.categoryName,
            value: item.total,
            percentage: item.percentage,
            categoryId: item.categoryId
        }));

        res.json({
            message: `Lấy top ${type === 'expense' ? 'chi tiêu' : 'thu nhập'} theo danh mục thành công`,
            data: {
                period: {
                    startDate: startDate || null,
                    endDate: endDate || null
                },
                type: type,
                summary,
                categories: topWithPercentage,
                chart: {
                    title: type === 'expense'
                        ? 'Top danh mục chi tiêu'
                        : 'Top danh mục thu nhập',
                    data: chartData,
                    total: grandTotal
                }
            }
        });
    } catch (error) {
        console.error('getFamilyTopCategories error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const getFamilyTopSpender = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user?.familyId) {
            return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });
        }

        const family = await Family.findById(user.familyId).populate('members', '_id');
        if (!family || !family.isMember(req.userId)) {
            return res.status(403).json({ error: 'Không có quyền truy cập gia đình này' });
        }

        const { startDate, endDate } = req.query;

        // Lấy danh sách userId của các thành viên trong family
        const memberIds = family.members.map(m => m._id);

        // Match condition
        const match = {
            userId: { $in: memberIds }, // Lọc theo thành viên trong family
            type: 'expense',
            isDeleted: { $ne: true } // Bỏ qua giao dịch đã xóa
        };

        // Thêm filter theo ngày nếu có
        if (startDate || endDate) {
            match.date = {};
            if (startDate) {
                match.date.$gte = new Date(startDate);
            }
            if (endDate) {
                // Set time to end of day
                const end = new Date(endDate);
                end.setHours(23, 59, 59, 999);
                match.date.$lte = end;
            }
        }

        const top = await Transaction.aggregate([
            { $match: match },
            {
                $group: {
                    _id: '$userId',
                    total: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            },
            { $sort: { total: -1 } },
            { $limit: 1 },
            {
                $lookup: {
                    from: 'users',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'user'
                }
            },
            { $unwind: '$user' },
            {
                $project: {
                    _id: 0,
                    userId: { $toString: '$user._id' },
                    username: '$user.username',
                    email: '$user.email',
                    avatar: '$user.avatar',
                    total: 1,
                    count: 1
                }
            }
        ]);

        const result = top[0] || null;

        res.json({
            message: 'Lấy thành viên chi tiêu nhiều nhất thành công',
            data: result
        });
    } catch (error) {
        console.error('getFamilyTopSpender error:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};
