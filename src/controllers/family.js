// Update file: controllers/family.js
import Family from '../models/family.js';
import User from '../models/user.js';
import Transaction from '../models/transaction.js';
import Budget from '../models/budget.js';
import dayjs from 'dayjs';  // For handling expiresAt
import { InviteEmail, transporter } from '../utils/mail.js';

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
            members: [req.userId]
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
            family: populatedFamily
        });
    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ error: 'Tên gia đình đã tồn tại' });
        }
        console.error('Lỗi tạo family:', error);
        res.status(500).json({ error: 'Lỗi server' });
    }
};

export const generateInviteLink = async (req, res) => {
    const user = await User.findById(req.userId);
    if (!user.familyId || !user.isFamilyAdmin) return res.status(403).json({ error: 'Chỉ admin mới tạo link mời' });

    const family = await Family.findById(user.familyId);
    const inviteLink = `${process.env.APP_URL}/join?familyCode=${family.inviteCode}`;  // e.g., http://yourapp.com/join?familyCode=abc123

    res.json({ message: 'Link mời đã tạo', inviteLink });
};

export const sendInviteEmail = async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email là bắt buộc' });

    const admin = await User.findById(req.userId);
    if (!admin.familyId || !admin.isFamilyAdmin) {
        return res.status(403).json({ error: 'Chỉ admin được mời' });
    }

    const family = await Family.findById(admin.familyId);
    if (!family) return res.status(404).json({ error: 'Không tìm thấy gia đình' });

    // Kiểm tra đã là thành viên chưa
    const existingMember = await User.findOne({ email, familyId: family._id });
    if (existingMember) return res.status(400).json({ error: 'Đã là thành viên' });

    // Tạo pending invite
    const expiresAt = dayjs().add(7, 'day').toDate();
    const invite = family.pendingInvites.find(i => i.email === email);
    if (invite) {
        invite.expiresAt = expiresAt;
        invite.invitedBy = req.userId;
    } else {
        family.pendingInvites.push({ email, invitedBy: req.userId, expiresAt });
    }
    await family.save();

    // Tạo 2 link
    const deepLink = `myapp://join-invite?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;
    const webJoinLink = `${process.env.APP_URL}/api/family/join-web?familyCode=${family.inviteCode}&email=${encodeURIComponent(email)}`;

    // Kiểm tra user đã tồn tại chưa
    const userExists = await User.findOne({ email });

    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: email,
        subject: `Mời tham gia gia đình "${family.name}"`,
        html: `
          <div style="background: linear-gradient(135deg, #7c3aed, #ec4899); padding: 24px; font-family: Arial, sans-serif;">
            <div style="max-width: 640px; margin: 0 auto;">
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 24px rgba(124, 58, 237, 0.25);">
                <tr>
                  <td style="padding: 0;">
                    <div style="background: linear-gradient(135deg, #8b5cf6, #f472b6); color: #ffffff; text-align: center; padding: 28px 16px;">
                      <div style="font-size: 14px; letter-spacing: 1px; opacity: 0.9;">MANEKI NEKO</div>
                      <h2 style="margin: 8px 0 0; font-size: 24px; line-height: 1.4;">Lời mời tham gia gia đình</h2>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 24px 24px 8px; color: #374151; font-size: 15px;">
                    <p style="margin: 0 0 10px;">Xin chào,</p>
                    <p style="margin: 0 0 12px;">
                      <strong>${admin.username}</strong> đã mời bạn tham gia gia đình <strong>"${family.name}"</strong> trên ứng dụng <strong>Maneki Neko</strong>.
                    </p>
                    <p style="margin: 0 0 20px; color: #6b7280;">Kết nối để chia sẻ chi tiêu, thiết lập ngân sách và quản lý tài chính thông minh cùng gia đình.</p>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 0 24px 24px; text-align: center;">
                    <a href="${webJoinLink}"
                       style="display: inline-block; text-decoration: none; background: linear-gradient(135deg, #7c3aed, #ec4899); color: #ffffff; padding: 14px 28px; border-radius: 9999px; font-weight: bold; font-size: 16px; box-shadow: 0 8px 16px rgba(236, 72, 153, 0.35);">
                      ${userExists ? 'Tham gia ngay' : 'Đăng nhập & tham gia'}
                    </a>
                    <div style="margin-top: 12px; font-size: 13px; color: #9ca3af;">Nếu nút không hoạt động, hãy mở liên kết: <br/>
                      <a href="${webJoinLink}" style="color: #7c3aed; text-decoration: underline;">${webJoinLink}</a>
                    </div>
                  </td>
                </tr>
                <tr>
                  <td style="padding: 0 24px 24px;">
                    <div style="border-top: 1px solid #f1f5f9; padding-top: 16px; text-align: center;">
                      <span style="display: inline-block; color: #6b7280; font-size: 12px;">Lời mời hết hạn sau 7 ngày.</span>
                    </div>
                  </td>
                </tr>
              </table>
            </div>
          </div>
        `
    };
    res.json({
        success: true,
        message: 'Đã gửi lời mời',
        webJoinLink,
        deepLink,
        userExists: !!userExists
    });
    setImmediate(() => {
        transporter.sendMail(mailOptions);
    });
};

export const joinFamilyWeb = async (req, res) => {
    const { familyCode, email } = req.query;

    const themedPage = (inner) => `
      <div style="background:linear-gradient(135deg,#7c3aed,#ec4899);padding:32px;font-family:Arial,sans-serif">
        <div style="max-width:640px;margin:auto;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 12px 28px rgba(124,58,237,0.25)">
          <div style="background:linear-gradient(135deg,#8b5cf6,#f472b6);color:#ffffff;text-align:center;padding:24px 16px">
            <div style="font-size:12px;letter-spacing:1px;opacity:.9">MANEKI NEKO</div>
          </div>
          <div style="padding:24px">${inner}</div>
        </div>
      </div>`;

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

        // Kiểm tra invite hợp lệ
        const invite = family.pendingInvites.find(i =>
            i.email === email && dayjs(i.expiresAt).isAfter(dayjs())
        );

        if (!invite) {
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

        // Kiểm tra đã là thành viên chưa
        if (family.members.some(m => m.toString() === user._id.toString())) {
            // Xóa pending invite
            family.pendingInvites = family.pendingInvites.filter(i => i._id !== invite._id);
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

        // Join thành công
        family.members.push(user._id);
        family.pendingInvites = family.pendingInvites.filter(i => i._id !== invite._id);
        await family.save();

        await User.findByIdAndUpdate(user._id, {
            familyId: family._id,
            isFamilyAdmin: false  // Default không phải admin
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
    const user = await User.findById(req.userId);
    if (!user.familyId) return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });

    const family = await Family.findById(user.familyId);

    // Kiểm tra nếu là admin và là thành viên cuối cùng
    const isAdmin = family.adminId.toString() === req.userId.toString();
    const currentMemberCount = family.members.length;

    // Loại bỏ thành viên trước
    family.members = family.members.filter(id => id.toString() !== req.userId.toString());

    if (isAdmin) {
        if (family.members.length > 0) {
            // Chuyển admin cho thành viên khác
            family.adminId = family.members[0];
            await User.findByIdAndUpdate(family.members[0], { isFamilyAdmin: true });
        } else {
            // Xóa family nếu không còn thành viên
            await Family.deleteOne({ _id: family._id });
            await User.findByIdAndUpdate(req.userId, {
                familyId: null,
                isFamilyAdmin: false
            });
            return res.json({ message: 'Đã xóa nhóm gia đình (thành viên cuối cùng)' });
        }
    }

    await family.save();
    await User.findByIdAndUpdate(req.userId, { familyId: null, isFamilyAdmin: false });

    res.json({ message: 'Đã rời nhóm gia đình' });
};

export const getFamilyMembers = async (req, res) => {
    const user = await User.findById(req.userId);
    if (!user.familyId) return res.status(400).json({ error: 'Bạn chưa tham gia nhóm nào' });

    const family = await Family.findById(user.familyId).populate('members', 'username email avatar');
    res.json(family.members);
};