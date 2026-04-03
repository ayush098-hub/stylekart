import API from './axios';

export const login = (data) => API.post('/api/auth/login', data);
export const register = (data) => API.post('/api/auth/register', data);
export const getProfile = () => API.get('/api/auth/profile');
