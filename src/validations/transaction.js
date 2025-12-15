import Joi from "joi";
const objectId = Joi.string().hex().length(24);

export const createTransactionSchema = Joi.object({
  amount: Joi.number().positive().required(),
  type: Joi.string().valid("income", "expense").required(),
  date: Joi.alternatives().try(
    Joi.string().pattern(/^\d{1,2}-\d{1,2}-\d{4}$/),  // DD-MM-YYYY
    Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/),      // YYYY-MM-DD
    Joi.date()                                         // Fallback
  ).optional(),
  description: Joi.string().allow("").optional(),
  isShared: Joi.boolean().optional(),
  categoryId: Joi.string().hex().length(24).optional().empty(''),
  walletId: Joi.string().hex().length(24).optional().empty(''),
  expense_for: Joi.string().optional().empty('').default("Tôi"),
});

export function validateCreateTransaction(payload) {
  return createTransactionSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const updateTransactionSchema = Joi.object({
  amount: Joi.number().positive().optional(),
  type: Joi.string().valid("income", "expense").optional(),
  date: Joi.date().optional(),
  description: Joi.string().allow("").optional(),
  isShared: Joi.boolean().optional(),
  categoryId: objectId.optional().empty(''),
  walletId: objectId.optional().empty(''),
  expense_for: Joi.string().optional().empty(''),
});

export function validateUpdateTransaction(payload) {
  return updateTransactionSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export const transactionIdParamSchema = Joi.object({ transactionId: objectId.required() });

export function validateTransactionIdParam(params) {
  return transactionIdParamSchema.validate(params, { abortEarly: false, stripUnknown: true });
}
