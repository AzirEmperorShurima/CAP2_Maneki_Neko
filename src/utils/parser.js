// utils/parser.js
export function parseTransactionText(text) {
    const result = { valid: false, type: null, amount: 0, currency: '', description: '', keywords: [], date: new Date() };

    // Xác định loại
    const incomePatterns = [/cho.+tiền/, /được.+tiền/, /nhận/, /lương/, /thưởng/, /kiếm được/];
    const expensePatterns = [/mua/, /hết/, /chi/, /trả/, /tốn/, /ăn.+k/, /đi.+k/];

    if (incomePatterns.some(p => p.test(text))) result.type = 'income';
    else if (expensePatterns.some(p => p.test(text))) result.type = 'expense';
    else return result;

    // Parse số tiền
    const amountMatch = text.match(/(\d+(?:\.\d+)?)\s*(k|nghìn|ngàn|triệu|trăm|củ|d|đ)?/i);
    if (!amountMatch) return result;

    let amount = parseFloat(amountMatch[1]);
    const unit = amountMatch[2]?.toLowerCase();
    if (unit === 'k' || unit === 'nghìn' || unit === 'ngàn') amount *= 1000;
    else if (unit === 'triệu' || unit === 'củ') amount *= 1000000;
    else if (unit === 'trăm') amount *= 100;
    else {
        result.amount = Math.round(amount);
        result.currency = unit || 'vnd';
        result.valid = true;
        return result;
    }

    result.amount = Math.round(amount);
    result.description = text.replace(/hôm nay|hôm qua|ngày mai/gi, '').replace(/\d+(k|nghìn|triệu|củ)?/gi, '').trim();
    result.keywords = result.description.split(' ').filter(w => w.length > 2);
    result.valid = true;
    return result;
}