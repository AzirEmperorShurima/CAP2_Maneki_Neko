import mongoose from "mongoose";

const budgetSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ['daily', 'weekly', 'monthly'],
        required: true
    },
    amount: {
        type: Number,
        required: true,
        min: 0
    }, // Số tiền tối đa được phép chi tiêu trong khoảng thời gian
    familyId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Family'
    },
    isShared: { // isShared: true nếu ngân sách chia sẻ giữa nhiều người trong gia đình
        type: Boolean,
        default: false
    },
    categoryId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Category'
    }, // Có thể áp dụng cho một danh mục cụ thể hoặc null (áp dụng cho tất cả)
    isActive: {
        type: Boolean,
        default: true
    }, // Trạng thái hoạt động của budget
    periodStart: {
        type: Date
    }, // Ngày bắt đầu của kỳ budget (tự động tính toán dựa trên type)
    periodEnd: {
        type: Date
    } // Ngày kết thúc của kỳ budget
}, { timestamps: true });

// Index 
budgetSchema.index({ userId: 1, type: 1 });
budgetSchema.index({ userId: 1, isActive: 1 });
budgetSchema.index({ familyId: 1 });

export default mongoose.model("Budget", budgetSchema);