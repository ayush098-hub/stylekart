import axios from 'axios';

const API = axios.create({
    baseURL: 'http://k8s-default-stylekar-4aa298fc3a-60568287.ap-south-1.elb.amazonaws.com',
,
});

API.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default API;
