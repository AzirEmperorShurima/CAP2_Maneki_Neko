export const formatFamilyResponse = (family, currentUserId = null) => {
    const plain = typeof family.toObject === 'function' ? family.toObject() : family;
    
    return {
        id: plain._id?.toString() || '',
        name: plain.name || '',
        inviteCode: plain.inviteCode || '',
        isActive: !!plain.isActive,
        admin_id: plain.adminId?._id 
            ? plain.adminId._id.toString() 
            : (plain.adminId?.toString() || ''),
        sharedResources: {
            budgets: Array.isArray(plain.sharedResources?.budgets) 
                ? plain.sharedResources.budgets.map(b => b.toString()) 
                : [],
            wallets: Array.isArray(plain.sharedResources?.wallets) 
                ? plain.sharedResources.wallets.map(w => w.toString()) 
                : [],
            goals: Array.isArray(plain.sharedResources?.goals) 
                ? plain.sharedResources.goals.map(g => g.toString()) 
                : []
        },
        sharingSettings: {
            transactionVisibility: plain.sharingSettings?.transactionVisibility || 'all',
            walletVisibility: plain.sharingSettings?.walletVisibility || 'summary_only',
            goalVisibility: plain.sharingSettings?.goalVisibility || 'all'
        },
        admin: plain.adminId ? {
            id: plain.adminId._id?.toString() || plain.adminId.toString(),
            username: plain.adminId.username || '',
            email: plain.adminId.email || '',
            avatar: plain.adminId.avatar || ''
        } : null,
        members: Array.isArray(plain.members) ? plain.members.map(m => {
            if (m && typeof m === 'object' && m._id) {
                return {
                    id: m._id.toString(),
                    username: m.username || '',
                    email: m.email || '',
                    avatar: m.avatar || ''
                };
            }
            return { id: m?.toString() || '', username: '', email: '', avatar: '' };
        }) : [],
        pendingInvites: Array.isArray(plain.pendingInvites) ? plain.pendingInvites.map(inv => ({
            email: inv?.email || '',
            invitedBy: inv?.invitedBy?._id?.toString() || inv?.invitedBy?.toString() || '',
            expiresAt: inv?.expiresAt || ''
        })) : [],
        createdAt: plain.createdAt,
        updatedAt: plain.updatedAt
    };
};