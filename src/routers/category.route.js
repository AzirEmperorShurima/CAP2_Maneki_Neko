import { Router } from 'express';
import { createCategory, updateCategory, getCategories, getCategoryImages } from '../controllers/categoryController.js';

const categoryRouter = Router();

categoryRouter.post('/', createCategory);
categoryRouter.get('/', getCategories);
categoryRouter.put('/:id', updateCategory);
categoryRouter.get('/images', getCategoryImages);

export default categoryRouter;
