const imageBaseURI = "https://res.cloudinary.com/dugcn9xdz/image/upload/"

export const initialExpenseCats = [
    { name: 'Ăn uống', image: imageBaseURI + "food_fz3pdf.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Chi tiêu hằng ngày', image: imageBaseURI + "daily_squ1ge.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Di chuyển', image: imageBaseURI + "traffic_fqdklv.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Xã Giao', image: imageBaseURI + "beer_xk0caj.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Nhà ở', image: imageBaseURI + "house_xmquuh.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Quà tặng', image: imageBaseURI + "box_gpmyv5.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Internet', image: imageBaseURI + "internet_hdk580.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Mua sắm', image: imageBaseURI + "online-shopping_vg0wnb.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Giải trí', image: imageBaseURI + "cinema_rbajd0.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Làm đẹp', image: imageBaseURI + "skin-care_foyba1.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Sức khỏe', image: imageBaseURI + "health_ftuqv5.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Thuế/Phạt', image: imageBaseURI + "tax_orgim7.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Chi tiêu Khác', image: imageBaseURI + "expense_jnepnh.png", type: 'expense', isDefault: true, scope: 'system' },
    { name: 'Du lịch', image: imageBaseURI + "travel_btbeuk.png", type: 'expense', isDefault: true, scope: 'system' },
];

export const initialIncomeCats = [
    { name: 'Lương', image: imageBaseURI + "salary_dacijm.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Quà tặng', image: imageBaseURI + "box_gpmyv5.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Chuyển khoản', image: imageBaseURI + "money_transfer_wedg1h.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Thu nhập Khác', image: imageBaseURI + "financial-statement_bvburu.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Tiền công', image: imageBaseURI + "money_transfer_wedg1h.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Đầu tư', image: imageBaseURI + "investment_prjdmw.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Lãi suất', image: imageBaseURI + "interest-rate_an8hzo.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Tiền thưởng', image: imageBaseURI + "offer_swsqna.png", type: 'income', isDefault: true, scope: 'system' },
    { name: 'Bán thời gian', image: imageBaseURI + "office-hours_d3bi4z.png", type: 'income', isDefault: true, scope: 'system' },
];

export const initialCats = [...initialExpenseCats, ...initialIncomeCats];
