import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import { getMyOrders, getOrderById } from '../api/orders';

const statusColors = {
  PENDING: 'bg-yellow-100 text-yellow-700',
  CONFIRMED: 'bg-blue-100 text-blue-700',
  SHIPPED: 'bg-purple-100 text-purple-700',
  DELIVERED: 'bg-green-100 text-green-700',
  CANCELLED: 'bg-red-100 text-red-700',
};

export const OrderDetailPage = () => {
  const { id } = useParams();
  const location = useLocation();
  const [order, setOrder] = useState(null);
  const payment = location.state?.payment;

  useEffect(() => {
    getOrderById(id).then((res) => setOrder(res.data));
  }, [id]);

  if (!order) return (
    <div className="flex justify-center items-center h-64">
      <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
    </div>
  );

  return (
    <div className="max-w-3xl mx-auto px-4 py-8">
      {payment && (
        <div className={`mb-4 p-4 rounded-lg text-sm font-medium ${payment.status === 'SUCCESS' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}>
          {payment.status === 'SUCCESS'
            ? `✅ Payment successful! Transaction ID: ${payment.transactionId}`
            : `❌ Payment failed: ${payment.failureReason}`}
        </div>
      )}

      <div className="bg-white rounded-xl shadow-sm p-6">
        <div className="flex justify-between items-start mb-4">
          <div>
            <h1 className="text-xl font-bold text-gray-900">Order #{order.id}</h1>
            <p className="text-sm text-gray-400 mt-1">{new Date(order.createdAt).toLocaleString()}</p>
          </div>
          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColors[order.status]}`}>
            {order.status}
          </span>
        </div>

        <div className="divide-y">
          {order.items.map((item) => (
            <div key={item.id} className="py-3 flex justify-between items-center">
              <div>
                <p className="text-sm font-medium text-gray-800">{item.productName}</p>
                <p className="text-xs text-gray-400">{item.brand} · Size: {item.size} · Qty: {item.quantity}</p>
              </div>
              <p className="text-sm font-bold text-gray-900">₹{item.totalPrice}</p>
            </div>
          ))}
        </div>

        <div className="border-t pt-4 mt-2 flex justify-between">
          <span className="font-semibold text-gray-700">Total</span>
          <span className="font-bold text-gray-900 text-lg">₹{order.totalAmount}</span>
        </div>

        <div className="mt-4 text-sm text-gray-500">
          <p>📦 {order.shippingAddress}</p>
          <p>📱 {order.phoneNumber}</p>
        </div>
      </div>
    </div>
  );
};

const OrdersPage = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    getMyOrders().then((res) => {
      setOrders(res.data);
      setLoading(false);
    });
  }, []);

  if (loading) return (
    <div className="flex justify-center items-center h-64">
      <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
    </div>
  );

  return (
    <div className="max-w-3xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">My Orders</h1>
      {orders.length === 0 ? (
        <div className="text-center text-gray-400 py-20">No orders yet.</div>
      ) : (
        <div className="space-y-4">
          {orders.map((order) => (
            <div
              key={order.id}
              onClick={() => navigate(`/orders/${order.id}`)}
              className="bg-white rounded-lg p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
            >
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-medium text-gray-800">Order #{order.id}</p>
                  <p className="text-xs text-gray-400">{new Date(order.createdAt).toLocaleString()}</p>
                  <p className="text-sm text-gray-600 mt-1">{order.items.length} item(s) · ₹{order.totalAmount}</p>
                </div>
                <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColors[order.status]}`}>
                  {order.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrdersPage;
