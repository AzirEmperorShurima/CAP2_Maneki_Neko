import Joi from "joi";

export const createTransactionSchema = Joi.object({
  amount: Joi.number().positive().required(),
  type: Joi.string().valid("income", "expense").required(),
  date: Joi.date().optional(),
  description: Joi.string().allow("").optional(),
  isShared: Joi.boolean().optional(),
  categoryId: Joi.string().hex().length(24).required(),
});

export function validateCreateTransaction(payload) {
  return createTransactionSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

