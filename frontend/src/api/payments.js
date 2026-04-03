import API from './axios';

export const processPayment = (data) => API.post('/api/payments', data);
export const getPaymentByOrderId = (orderId) => API.get(`/api/payments/order/${orderId}`);
export const getMyPayments = () => API.get('/api/payments/my');
