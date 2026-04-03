import axios from 'axios';

const API = axios.create({
  baseURL: 'http://192.168.49.2:31080',
});

API.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default API;
