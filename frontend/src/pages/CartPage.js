import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { createOrder } from '../api/orders';
import { processPayment } from '../api/payments';

const CartPage = () => {
  const { cartItems, removeFromCart, updateQuantity, clearCart, totalAmount } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [shippingAddress, setShippingAddress] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('UPI');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleCheckout = async () => {
    if (!user) { navigate('/login'); return; }
    if (!shippingAddress || !phoneNumber) { setError('Please fill shipping details'); return; }

    setLoading(true);
    setError('');
    try {
      const orderPayload = {
        items: cartItems.map((item) => ({
          productId: item.product.id,
          quantity: item.quantity,
          size: item.size,
        })),
        shippingAddress,
        phoneNumber,
      };

      const orderRes = await createOrder(orderPayload);
      const orderId = orderRes.data.id;

      const paymentRes = await processPayment({ orderId, paymentMethod });

      clearCart();
      navigate(`/orders/${orderId}`, {
        state: { payment: paymentRes.data }
      });
    } catch (err) {
      setError(err.response?.data?.error || 'Checkout failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (cartItems.length === 0) {
    return (
      <div className="max-w-3xl mx-auto px-4 py-20 text-center">
        <p className="text-6xl mb-4">🛍️</p>
        <h2 className="text-xl font-semibold text-gray-700">Your cart is empty</h2>
        <button onClick={() => navigate('/')} className="mt-4 text-primary font-medium hover:underline">
          Continue Shopping
        </button>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">My Cart ({cartItems.length} items)</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-3">
          {cartItems.map((item) => (
            <div key={`${item.product.id}-${item.size}`} className="bg-white rounded-lg p-4 shadow-sm flex gap-4">
              <div className="w-20 h-20 bg-gray-100 rounded flex items-center justify-center text-3xl">
                {item.product.imageUrl ? (
                  <img src={item.product.imageUrl} alt={item.product.name} className="w-full h-full object-cover rounded" />
                ) : '👕'}
              </div>
              <div className="flex-1">
                <p className="text-xs text-gray-400">{item.product.brand}</p>
                <p className="text-sm font-medium text-gray-800">{item.product.name}</p>
                <p className="text-xs text-gray-500">Size: {item.size}</p>
                <p className="text-sm font-bold text-gray-900 mt-1">₹{item.product.price}</p>
              </div>
              <div className="flex flex-col items-end justify-between">
                <button onClick={() => removeFromCart(item.product.id, item.size)} className="text-gray-400 hover:text-red-500 text-xs">✕</button>
                <div className="flex items-center gap-2 border rounded">
                  <button onClick={() => updateQuantity(item.product.id, item.size, item.quantity - 1)} className="px-2 py-1 text-gray-600 hover:text-primary">-</button>
                  <span className="text-sm w-6 text-center">{item.quantity}</span>
                  <button onClick={() => updateQuantity(item.product.id, item.size, item.quantity + 1)} className="px-2 py-1 text-gray-600 hover:text-primary">+</button>
                </div>
              </div>
            </div>
          ))}
        </div>

        <div className="bg-white rounded-lg p-5 shadow-sm h-fit space-y-4">
          <h2 className="text-lg font-semibold text-gray-800">Order Summary</h2>
          <div className="flex justify-between text-sm text-gray-600">
            <span>Total Amount</span>
            <span className="font-bold text-gray-900">₹{totalAmount.toFixed(2)}</span>
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700">Shipping Address</label>
            <textarea
              value={shippingAddress}
              onChange={(e) => setShippingAddress(e.target.value)}
              rows={2}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              placeholder="Enter full address"
            />
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700">Phone Number</label>
            <input
              type="tel"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              placeholder="10-digit mobile number"
            />
          </div>

          <div>
            <label className="text-sm font-medium text-gray-700">Payment Method</label>
            <select
              value={paymentMethod}
              onChange={(e) => setPaymentMethod(e.target.value)}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
            >
              <option value="UPI">UPI</option>
              <option value="CREDIT_CARD">Credit Card</option>
              <option value="DEBIT_CARD">Debit Card</option>
              <option value="NET_BANKING">Net Banking</option>
              <option value="WALLET">Wallet</option>
            </select>
          </div>

          {error && <p className="text-red-500 text-xs">{error}</p>}

          <button
            onClick={handleCheckout}
            disabled={loading}
            className="w-full bg-primary text-white py-3 rounded font-semibold text-sm hover:bg-pink-600 disabled:opacity-60"
          >
            {loading ? 'Processing...' : 'Place Order'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default CartPage;
