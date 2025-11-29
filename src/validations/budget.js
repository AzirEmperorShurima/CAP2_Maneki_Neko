import Joi from "joi";

const objectId = Joi.string().hex().length(24);

export const createBudgetSchema = Joi.object({
  type: Joi.string().valid('daily', 'weekly', 'monthly').required(),
  amount: Joi.number().positive().required(),
  categoryId: objectId.allow(null).optional(),
  isShared: Joi.boolean().optional(),
  familyId: objectId.when('isShared', { is: true, then: Joi.required(), otherwise: Joi.optional() }),
});

export const updateBudgetSchema = Joi.object({
  type: Joi.string().valid('daily', 'weekly', 'monthly').optional(),
  amount: Joi.number().positive().optional(),
  categoryId: objectId.allow(null).optional(),
  isActive: Joi.boolean().optional(),
  isShared: Joi.boolean().optional(),
  familyId: objectId.optional(),
});

export const getBudgetsQuerySchema = Joi.object({
  isActive: Joi.string().valid('true', 'false').optional(),
  isShared: Joi.string().valid('true', 'false').optional(),
});

export function validateCreateBudget(payload) {
  return createBudgetSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateUpdateBudget(payload) {
  return updateBudgetSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateGetBudgetsQuery(query) {
  return getBudgetsQuerySchema.validate(query, { abortEarly: false, stripUnknown: true });
}

