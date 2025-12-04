import { Router } from 'express';
import { createCategory, updateCategory, getCategories } from '../controllers/categoryController.js';

const categoryRouter = Router();

categoryRouter.post('/', createCategory);
categoryRouter.get('/', getCategories);
categoryRouter.put('/:id', updateCategory);

export default categoryRouter;
