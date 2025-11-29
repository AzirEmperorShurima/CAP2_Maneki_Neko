import Joi from "joi";

const objectId = Joi.string().hex().length(24);

export const createGoalSchema = Joi.object({
  name: Joi.string().min(1).max(80).required(),
  description: Joi.string().allow('').optional(),
  targetAmount: Joi.number().positive().required(),
  deadline: Joi.date().required(),
  associatedWallets: Joi.array().items(objectId).optional(),
});

export const updateGoalSchema = Joi.object({
  name: Joi.string().min(1).max(80).optional(),
  description: Joi.string().allow('').optional(),
  targetAmount: Joi.number().positive().optional(),
  deadline: Joi.date().optional(),
  associatedWallets: Joi.array().items(objectId).optional(),
});

export const addProgressSchema = Joi.object({
  amount: Joi.number().positive().required(),
});

export const linkWalletsSchema = Joi.object({
  walletIds: Joi.array().items(objectId).min(1).required(),
});

export function validateCreateGoal(payload) {
  return createGoalSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateUpdateGoal(payload) {
  return updateGoalSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateAddProgress(payload) {
  return addProgressSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

export function validateLinkWallets(payload) {
  return linkWalletsSchema.validate(payload, { abortEarly: false, stripUnknown: true });
}

