import Joi from "joi";

const objectId = Joi.string().hex().length(24);

export const createWalletSchema = Joi.object({
  name: Joi.string().min(1).max(50).required(),
  type: Joi.string().allow("").max(100).optional(),
  balance: Joi.number().min(0).optional(),
  description: Joi.string().allow("").max(500).optional(),
  details: Joi.object({
    bankName: Joi.string().optional(),
    accountNumber: Joi.string().optional(),
    cardNumber: Joi.string().optional()
  }).optional(),
  icon: Joi.string().optional(),
  isShared: Joi.boolean().optional(),
  familyId: objectId.when("isShared", { is: true, then: Joi.required(), otherwise: Joi.optional() })
});

export function validateCreateWallet(payload) {
  return createWalletSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const getWalletsQuerySchema = Joi.object({
  isActive: Joi.string().valid("true", "false").optional(),
  isShared: Joi.string().valid("true", "false").optional(),
  scope: Joi.string().valid("personal", "family", "default_receive", "default_savings", "default_debt").optional(),
  type: Joi.string().optional(),
  includeSystem: Joi.string().valid("true", "false").optional()
});

export function validateGetWalletsQuery(payload) {
  return getWalletsQuerySchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const updateWalletSchema = Joi.object({
  name: Joi.string().min(1).max(50).optional(),
  type: Joi.string().allow("").max(100).optional(),
  description: Joi.string().allow("").max(500).optional(),
  details: Joi.object({
    bankName: Joi.string().optional(),
    accountNumber: Joi.string().optional(),
    cardNumber: Joi.string().optional()
  }).optional(),
  icon: Joi.string().optional(),
  isActive: Joi.boolean().optional()
});

export function validateUpdateWallet(payload) {
  return updateWalletSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const idParamSchema = Joi.object({ id: objectId.required() });

export function validateIdParam(payload) {
  return idParamSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const transferBetweenWalletsSchema = Joi.object({
  fromWalletId: objectId.required(),
  toWalletId: objectId.optional(),
  toUserId: objectId.optional(),
  amount: Joi.number().positive().required(),
  note: Joi.string().allow("").optional()
}).xor("toWalletId", "toUserId");

export function validateTransferBetweenWallets(payload) {
  return transferBetweenWalletsSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const manageWalletAccessSchema = Joi.object({
  action: Joi.string().valid("grant", "revoke").required(),
  accessType: Joi.string().valid("view", "transact").required(),
  userId: objectId.required()
});

export function validateManageWalletAccess(payload) {
  return manageWalletAccessSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const getTransferHistoryQuerySchema = Joi.object({
  walletId: objectId.optional(),
  type: Joi.string().valid("personal_to_personal", "family_to_personal", "personal_to_family", "system_auto_transfer").optional(),
  limit: Joi.number().integer().min(1).max(200).optional(),
  page: Joi.number().integer().min(1).optional()
});

export function validateGetTransferHistoryQuery(payload) {
  return getTransferHistoryQuerySchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const payDebtSchema = Joi.object({
  fromWalletId: objectId.required(),
  amount: Joi.number().positive().required()
});

export function validatePayDebt(payload) {
  return payDebtSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

