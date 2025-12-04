import Family from '../models/family.js';
import User from '../models/user.js';
import { sendFamilyInviteEmail } from '../services/mail/sendMailService.js';
import { themedPage } from '../utils/webTheme.js';
import { StatusCodes } from 'http-status-codes';
import dayjs from 'dayjs';
import crypto from 'crypto';
import PushNotificationService from '../services/pushNotificationService.js';

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
        const existingFamily = await User.findById(req.userId).populate('familyId');
        if (existingFamily?.familyId) {
            return res.status(400).json({
                error: 'Bạn đã thuộc một gia đình. Hãy rời nhóm trước khi tạo mới.'
            });
        }

        const family = new Family({
            name: name.trim(),
            adminId: req.userId,
            members: [req.userId],
        });

        await family.save();

        await User.findByIdAndUpdate(
            req.userId,
            {
                familyId: family._id,
                isFamilyAdmin: true
            },
            { new: true }
        );

        const populatedFamily = await Family.findById(family._id)
            .populate('adminId', 'username email avatar')
            .populate('members', 'username email avatar');

        res.status(201).json({
            message: 'Đã tạo nhóm gia đình thành công',
            data: populatedFamily
        });
    } catch (error) {
        console.error('Lỗi tạo family:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const generateInviteLink = async (req, res) => {
    try {
        const user = await User.findById(req.userId);
        if (!user.familyId || !user.isFamilyAdmin) {
            return res.status(403).json({ error: 'Chỉ admin mới tạo link mời' });
        }

        const family = await Family.findById(user.familyId);
        if (!family) {
            return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        }

        if (!family.inviteCode || family.inviteCode === 'null') {
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
        if (!admin.familyId || !admin.isFamilyAdmin) {
            return res.status(403).json({ error: 'Bạn phải ở trong 1 gia đình và là admin của gia đình' });
        }

        const family = await Family.findById(admin.familyId);
        if (!family) return res.status(404).json({ error: 'Không tìm thấy gia đình' });
        if (!family.isActive) return res.status(400).json({ error: 'Gia đình đã bị vô hiệu hóa' });

        // Kiểm tra đã là thành viên chưa - SỬA: dùng method isMember
        const existingMember = await User.findOne({ email, familyId: family._id });
        if (existingMember) return res.status(400).json({ error: 'Đã là thành viên' });

        // Tạo/cập nhật pending invite - SỬA: dùng method upsertPendingInvite
        const expiresAt = dayjs().add(7, 'day').toDate();
        family.upsertPendingInvite(email, req.userId, expiresAt);
        await family.save();

        // Đảm bảo có invite code
        if (!family.inviteCode || family.inviteCode === 'null') {
            family.inviteCode = await generateInviteCode();
            await family.save();
        }

        // Tạo 2 link
        const deepLink = `myapp://join-invite?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;
        const webJoinLink = `${process.env.APP_URL}/api/family/join-web?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;

        // Kiểm tra user đã tồn tại chưa
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
            }).catch(() => { });
        });

        if (userExistsBool && userExists.fcmTokens?.length > 0) {
            const messageData = {
                familyCode: family.inviteCode,
                email: email,
                type: 'family_invite'
            };

            setImmediate(async () => {
                try {
                    await PushNotificationService.sendNotificationToUser(
                        userExists,
                        'Lời mời tham gia gia đình',
                        `${adminName} đã mời bạn tham gia gia đình ${family.name}`,
                        messageData
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

        // SỬA: dùng method hasValidPendingInvite
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

        // SỬA: dùng method isMember
        if (family.isMember(user._id)) {
            // Xóa pending invite - SỬA: dùng method removePendingInvite
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

        // Join thành công - SỬA: dùng method addMember
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

        // SỬA: dùng method isAdmin
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
