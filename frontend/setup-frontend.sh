#!/bin/bash

# ─────────────────────────────────────────────
#  StyleKart — Frontend Setup Script
#  Run from: /home/ayush/stylekart/frontend/
#  Usage: bash setup-frontend.sh
# ─────────────────────────────────────────────

set -e

echo "📁 Creating folder structure..."
mkdir -p src/api
mkdir -p src/components/common
mkdir -p src/components/product
mkdir -p src/components/cart
mkdir -p src/components/order
mkdir -p src/context
mkdir -p src/pages

# ─────────────────────────────────────────────
# tailwind.config.js
# ─────────────────────────────────────────────
echo "📝 Writing tailwind.config.js..."
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,jsx,ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#FF3F6C",
        dark: "#1a1a1a",
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
EOF

# ─────────────────────────────────────────────
# src/index.css
# ─────────────────────────────────────────────
echo "📝 Writing index.css..."
cat > src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background-color: #f5f5f6;
}
EOF

# ─────────────────────────────────────────────
# src/api/axios.js
# ─────────────────────────────────────────────
echo "📝 Writing API config..."
cat > src/api/axios.js << 'EOF'
import axios from 'axios';

const API = axios.create({
  baseURL: 'http://localhost:8080',
});

API.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default API;
EOF

# ─────────────────────────────────────────────
# src/api/auth.js
# ─────────────────────────────────────────────
cat > src/api/auth.js << 'EOF'
import API from './axios';

export const login = (data) => API.post('/api/auth/login', data);
export const register = (data) => API.post('/api/auth/register', data);
export const getProfile = () => API.get('/api/auth/profile');
EOF

# ─────────────────────────────────────────────
# src/api/products.js
# ─────────────────────────────────────────────
cat > src/api/products.js << 'EOF'
import API from './axios';

export const getProducts = (page = 0, size = 12) =>
  API.get(`/api/products?page=${page}&size=${size}`);

export const getProductById = (id) => API.get(`/api/products/${id}`);

export const getProductsByCategory = (categoryId, page = 0) =>
  API.get(`/api/products/category/${categoryId}?page=${page}`);

export const searchProducts = (keyword, page = 0) =>
  API.get(`/api/products/search?keyword=${keyword}&page=${page}`);

export const getCategories = () => API.get('/api/categories');
EOF

# ─────────────────────────────────────────────
# src/api/orders.js
# ─────────────────────────────────────────────
cat > src/api/orders.js << 'EOF'
import API from './axios';

export const createOrder = (data) => API.post('/api/orders', data);
export const getMyOrders = () => API.get('/api/orders');
export const getOrderById = (id) => API.get(`/api/orders/${id}`);
export const cancelOrder = (id) => API.patch(`/api/orders/${id}/cancel`);
EOF

# ─────────────────────────────────────────────
# src/api/payments.js
# ─────────────────────────────────────────────
cat > src/api/payments.js << 'EOF'
import API from './axios';

export const processPayment = (data) => API.post('/api/payments', data);
export const getPaymentByOrderId = (orderId) => API.get(`/api/payments/order/${orderId}`);
export const getMyPayments = () => API.get('/api/payments/my');
EOF

# ─────────────────────────────────────────────
# src/context/AuthContext.js
# ─────────────────────────────────────────────
echo "📝 Writing context..."
cat > src/context/AuthContext.js << 'EOF'
import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(localStorage.getItem('token'));

  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    if (savedUser) setUser(JSON.parse(savedUser));
  }, []);

  const loginUser = (data) => {
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data));
    setToken(data.token);
    setUser(data);
  };

  const logoutUser = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, loginUser, logoutUser }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
EOF

# ─────────────────────────────────────────────
# src/context/CartContext.js
# ─────────────────────────────────────────────
cat > src/context/CartContext.js << 'EOF'
import React, { createContext, useContext, useState } from 'react';

const CartContext = createContext(null);

export const CartProvider = ({ children }) => {
  const [cartItems, setCartItems] = useState([]);

  const addToCart = (product, size) => {
    setCartItems((prev) => {
      const existing = prev.find(
        (item) => item.product.id === product.id && item.size === size
      );
      if (existing) {
        return prev.map((item) =>
          item.product.id === product.id && item.size === size
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prev, { product, size, quantity: 1 }];
    });
  };

  const removeFromCart = (productId, size) => {
    setCartItems((prev) =>
      prev.filter((item) => !(item.product.id === productId && item.size === size))
    );
  };

  const updateQuantity = (productId, size, quantity) => {
    if (quantity <= 0) {
      removeFromCart(productId, size);
      return;
    }
    setCartItems((prev) =>
      prev.map((item) =>
        item.product.id === productId && item.size === size
          ? { ...item, quantity }
          : item
      )
    );
  };

  const clearCart = () => setCartItems([]);

  const totalItems = cartItems.reduce((sum, item) => sum + item.quantity, 0);
  const totalAmount = cartItems.reduce(
    (sum, item) => sum + item.product.price * item.quantity,
    0
  );

  return (
    <CartContext.Provider
      value={{ cartItems, addToCart, removeFromCart, updateQuantity, clearCart, totalItems, totalAmount }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => useContext(CartContext);
EOF

# ─────────────────────────────────────────────
# src/components/common/Navbar.js
# ─────────────────────────────────────────────
echo "📝 Writing components..."
cat > src/components/common/Navbar.js << 'EOF'
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useCart } from '../../context/CartContext';

const Navbar = () => {
  const { user, logoutUser } = useAuth();
  const { totalItems } = useCart();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');

  const handleSearch = (e) => {
    e.preventDefault();
    if (search.trim()) navigate(`/search?q=${search}`);
  };

  return (
    <nav className="bg-white shadow-md sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
        <Link to="/" className="text-2xl font-bold text-primary tracking-tight">
          StyleKart
        </Link>

        <form onSubmit={handleSearch} className="flex-1 max-w-md">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search for products, brands..."
            className="w-full border border-gray-300 rounded px-4 py-2 text-sm focus:outline-none focus:border-primary"
          />
        </form>

        <div className="flex items-center gap-4 text-sm font-medium">
          {user ? (
            <>
              <Link to="/orders" className="text-gray-600 hover:text-primary">
                Orders
              </Link>
              <button
                onClick={() => { logoutUser(); navigate('/'); }}
                className="text-gray-600 hover:text-primary"
              >
                Logout
              </button>
            </>
          ) : (
            <Link to="/login" className="text-gray-600 hover:text-primary">
              Login
            </Link>
          )}

          <Link to="/cart" className="relative">
            <span className="text-2xl">🛍️</span>
            {totalItems > 0 && (
              <span className="absolute -top-2 -right-2 bg-primary text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                {totalItems}
              </span>
            )}
          </Link>
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
EOF

# ─────────────────────────────────────────────
# src/components/product/ProductCard.js
# ─────────────────────────────────────────────
cat > src/components/product/ProductCard.js << 'EOF'
import React from 'react';
import { Link } from 'react-router-dom';

const ProductCard = ({ product }) => {
  return (
    <Link to={`/product/${product.id}`} className="group">
      <div className="bg-white rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
        <div className="bg-gray-100 h-64 flex items-center justify-center overflow-hidden">
          {product.imageUrl ? (
            <img
              src={product.imageUrl}
              alt={product.name}
              className="h-full w-full object-cover group-hover:scale-105 transition-transform duration-300"
            />
          ) : (
            <span className="text-6xl">👕</span>
          )}
        </div>
        <div className="p-3">
          <p className="text-xs text-gray-400 uppercase tracking-wide">{product.brand}</p>
          <p className="text-sm font-medium text-gray-800 mt-1 truncate">{product.name}</p>
          <p className="text-sm font-bold text-gray-900 mt-1">₹{product.price}</p>
          <div className="flex gap-1 mt-2 flex-wrap">
            {product.availableSizes?.slice(0, 4).map((size) => (
              <span key={size} className="text-xs border border-gray-300 px-1.5 py-0.5 rounded text-gray-500">
                {size}
              </span>
            ))}
          </div>
        </div>
      </div>
    </Link>
  );
};

export default ProductCard;
EOF

# ─────────────────────────────────────────────
# src/pages/HomePage.js
# ─────────────────────────────────────────────
echo "📝 Writing pages..."
cat > src/pages/HomePage.js << 'EOF'
import React, { useEffect, useState } from 'react';
import { getProducts, getCategories, getProductsByCategory } from '../api/products';
import ProductCard from '../components/product/ProductCard';

const HomePage = () => {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);

  useEffect(() => {
    getCategories().then((res) => setCategories(res.data));
  }, []);

  useEffect(() => {
    setLoading(true);
    const fetch = selectedCategory
      ? getProductsByCategory(selectedCategory, page)
      : getProducts(page);

    fetch.then((res) => {
      setProducts(res.data.content);
      setTotalPages(res.data.totalPages);
      setLoading(false);
    });
  }, [selectedCategory, page]);

  return (
    <div className="max-w-7xl mx-auto px-4 py-6">
      {/* Categories */}
      <div className="flex gap-3 overflow-x-auto pb-3 mb-6">
        <button
          onClick={() => { setSelectedCategory(null); setPage(0); }}
          className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap border transition-colors
            ${!selectedCategory ? 'bg-primary text-white border-primary' : 'bg-white text-gray-600 border-gray-300 hover:border-primary'}`}
        >
          All
        </button>
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => { setSelectedCategory(cat.id); setPage(0); }}
            className={`px-4 py-2 rounded-full text-sm font-medium whitespace-nowrap border transition-colors
              ${selectedCategory === cat.id ? 'bg-primary text-white border-primary' : 'bg-white text-gray-600 border-gray-300 hover:border-primary'}`}
          >
            {cat.name}
          </button>
        ))}
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
        </div>
      ) : products.length === 0 ? (
        <div className="text-center text-gray-400 py-20">No products found.</div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex justify-center gap-2 mt-8">
          {Array.from({ length: totalPages }, (_, i) => (
            <button
              key={i}
              onClick={() => setPage(i)}
              className={`w-9 h-9 rounded-full text-sm font-medium border transition-colors
                ${page === i ? 'bg-primary text-white border-primary' : 'bg-white text-gray-600 border-gray-300'}`}
            >
              {i + 1}
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

export default HomePage;
EOF

# ─────────────────────────────────────────────
# src/pages/ProductDetailPage.js
# ─────────────────────────────────────────────
cat > src/pages/ProductDetailPage.js << 'EOF'
import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getProductById } from '../api/products';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';

const ProductDetailPage = () => {
  const { id } = useParams();
  const [product, setProduct] = useState(null);
  const [selectedSize, setSelectedSize] = useState('');
  const [added, setAdded] = useState(false);
  const { addToCart } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    getProductById(id).then((res) => setProduct(res.data));
  }, [id]);

  const handleAddToCart = () => {
    if (!user) { navigate('/login'); return; }
    if (!selectedSize) { alert('Please select a size'); return; }
    addToCart(product, selectedSize);
    setAdded(true);
    setTimeout(() => setAdded(false), 2000);
  };

  if (!product) return (
    <div className="flex justify-center items-center h-64">
      <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
    </div>
  );

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      <div className="bg-white rounded-xl shadow-sm grid grid-cols-1 md:grid-cols-2 gap-8 p-6">
        <div className="bg-gray-100 rounded-lg h-96 flex items-center justify-center">
          {product.imageUrl ? (
            <img src={product.imageUrl} alt={product.name} className="h-full w-full object-cover rounded-lg" />
          ) : (
            <span className="text-8xl">👕</span>
          )}
        </div>

        <div className="flex flex-col justify-between">
          <div>
            <p className="text-sm text-gray-400 uppercase tracking-widest">{product.brand}</p>
            <h1 className="text-2xl font-bold text-gray-900 mt-1">{product.name}</h1>
            <p className="text-3xl font-bold text-gray-900 mt-3">₹{product.price}</p>
            <p className="text-sm text-green-600 mt-1">
              {product.stockQuantity > 0 ? `${product.stockQuantity} in stock` : 'Out of stock'}
            </p>
            <p className="text-gray-600 mt-4 text-sm leading-relaxed">{product.description}</p>

            <div className="mt-6">
              <p className="text-sm font-semibold text-gray-700 mb-2">Select Size</p>
              <div className="flex gap-2 flex-wrap">
                {product.availableSizes?.map((size) => (
                  <button
                    key={size}
                    onClick={() => setSelectedSize(size)}
                    className={`px-4 py-2 border rounded text-sm font-medium transition-colors
                      ${selectedSize === size ? 'border-primary text-primary bg-pink-50' : 'border-gray-300 text-gray-600 hover:border-primary'}`}
                  >
                    {size}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <button
            onClick={handleAddToCart}
            disabled={product.stockQuantity === 0}
            className={`mt-6 w-full py-3 rounded-lg font-semibold text-white transition-colors
              ${added ? 'bg-green-500' : 'bg-primary hover:bg-pink-600'} disabled:bg-gray-300`}
          >
            {added ? '✓ Added to Cart' : 'Add to Cart'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ProductDetailPage;
EOF

# ─────────────────────────────────────────────
# src/pages/LoginPage.js
# ─────────────────────────────────────────────
cat > src/pages/LoginPage.js << 'EOF'
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { login } from '../api/auth';
import { useAuth } from '../context/AuthContext';

const LoginPage = () => {
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { loginUser } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await login(form);
      loginUser(res.data);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Invalid credentials');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded-xl shadow-sm w-full max-w-md">
        <h1 className="text-2xl font-bold text-gray-900 mb-1">Welcome back</h1>
        <p className="text-sm text-gray-500 mb-6">Login to your StyleKart account</p>

        {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded mb-4">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              required
            />
          </div>
          <div>
            <label className="text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary text-white py-2.5 rounded font-semibold text-sm hover:bg-pink-600 disabled:opacity-60"
          >
            {loading ? 'Logging in...' : 'Login'}
          </button>
        </form>

        <p className="text-sm text-center text-gray-500 mt-4">
          New here?{' '}
          <Link to="/register" className="text-primary font-medium hover:underline">
            Create account
          </Link>
        </p>
      </div>
    </div>
  );
};

export default LoginPage;
EOF

# ─────────────────────────────────────────────
# src/pages/RegisterPage.js
# ─────────────────────────────────────────────
cat > src/pages/RegisterPage.js << 'EOF'
import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { register } from '../api/auth';
import { useAuth } from '../context/AuthContext';

const RegisterPage = () => {
  const [form, setForm] = useState({ firstName: '', lastName: '', email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { loginUser } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await register(form);
      loginUser(res.data);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="bg-white p-8 rounded-xl shadow-sm w-full max-w-md">
        <h1 className="text-2xl font-bold text-gray-900 mb-1">Create account</h1>
        <p className="text-sm text-gray-500 mb-6">Join StyleKart today</p>

        {error && <div className="bg-red-50 text-red-600 text-sm p-3 rounded mb-4">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-medium text-gray-700">First Name</label>
              <input
                type="text"
                value={form.firstName}
                onChange={(e) => setForm({ ...form, firstName: e.target.value })}
                className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
                required
              />
            </div>
            <div>
              <label className="text-sm font-medium text-gray-700">Last Name</label>
              <input
                type="text"
                value={form.lastName}
                onChange={(e) => setForm({ ...form, lastName: e.target.value })}
                className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
                required
              />
            </div>
          </div>
          <div>
            <label className="text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              required
            />
          </div>
          <div>
            <label className="text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              value={form.password}
              onChange={(e) => setForm({ ...form, password: e.target.value })}
              className="mt-1 w-full border border-gray-300 rounded px-3 py-2 text-sm focus:outline-none focus:border-primary"
              required
              minLength={8}
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-primary text-white py-2.5 rounded font-semibold text-sm hover:bg-pink-600 disabled:opacity-60"
          >
            {loading ? 'Creating account...' : 'Create Account'}
          </button>
        </form>

        <p className="text-sm text-center text-gray-500 mt-4">
          Already have an account?{' '}
          <Link to="/login" className="text-primary font-medium hover:underline">
            Login
          </Link>
        </p>
      </div>
    </div>
  );
};

export default RegisterPage;
EOF

# ─────────────────────────────────────────────
# src/pages/CartPage.js
# ─────────────────────────────────────────────
cat > src/pages/CartPage.js << 'EOF'
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
EOF

# ─────────────────────────────────────────────
# src/pages/OrdersPage.js
# ─────────────────────────────────────────────
cat > src/pages/OrdersPage.js << 'EOF'
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
EOF

# ─────────────────────────────────────────────
# src/pages/SearchPage.js
# ─────────────────────────────────────────────
cat > src/pages/SearchPage.js << 'EOF'
import React, { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { searchProducts } from '../api/products';
import ProductCard from '../components/product/ProductCard';

const SearchPage = () => {
  const location = useLocation();
  const keyword = new URLSearchParams(location.search).get('q');
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (keyword) {
      setLoading(true);
      searchProducts(keyword).then((res) => {
        setProducts(res.data.content);
        setLoading(false);
      });
    }
  }, [keyword]);

  return (
    <div className="max-w-7xl mx-auto px-4 py-6">
      <h1 className="text-lg font-semibold text-gray-700 mb-4">
        Search results for: <span className="text-primary">"{keyword}"</span>
      </h1>

      {loading ? (
        <div className="flex justify-center items-center h-64">
          <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-primary"></div>
        </div>
      ) : products.length === 0 ? (
        <div className="text-center text-gray-400 py-20">No products found for "{keyword}"</div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}
    </div>
  );
};

export default SearchPage;
EOF

# ─────────────────────────────────────────────
# src/App.js
# ─────────────────────────────────────────────
echo "📝 Writing App.js..."
cat > src/App.js << 'EOF'
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import Navbar from './components/common/Navbar';
import HomePage from './pages/HomePage';
import ProductDetailPage from './pages/ProductDetailPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import CartPage from './pages/CartPage';
import OrdersPage, { OrderDetailPage } from './pages/OrdersPage';
import SearchPage from './pages/SearchPage';

const ProtectedRoute = ({ children }) => {
  const { user } = useAuth();
  return user ? children : <Navigate to="/login" />;
};

const AppRoutes = () => (
  <>
    <Navbar />
    <Routes>
      <Route path="/" element={<HomePage />} />
      <Route path="/product/:id" element={<ProductDetailPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/search" element={<SearchPage />} />
      <Route path="/cart" element={<ProtectedRoute><CartPage /></ProtectedRoute>} />
      <Route path="/orders" element={<ProtectedRoute><OrdersPage /></ProtectedRoute>} />
      <Route path="/orders/:id" element={<ProtectedRoute><OrderDetailPage /></ProtectedRoute>} />
    </Routes>
  </>
);

const App = () => (
  <BrowserRouter>
    <AuthProvider>
      <CartProvider>
        <AppRoutes />
      </CartProvider>
    </AuthProvider>
  </BrowserRouter>
);

export default App;
EOF

echo ""
echo "✅ Frontend setup complete!"
echo ""
echo "Next steps:"
echo "  cd /home/ayush/stylekart/frontend"
echo "  npm start"
echo "  Open http://localhost:3000"
