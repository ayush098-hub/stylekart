import API from './axios';

export const getProducts = (page = 0, size = 12) =>
  API.get(`/api/products?page=${page}&size=${size}`);

export const getProductById = (id) => API.get(`/api/products/${id}`);

export const getProductsByCategory = (categoryId, page = 0) =>
  API.get(`/api/products/category/${categoryId}?page=${page}`);

export const searchProducts = (keyword, page = 0) =>
  API.get(`/api/products/search?keyword=${keyword}&page=${page}`);

export const getCategories = () => API.get('/api/categories');
