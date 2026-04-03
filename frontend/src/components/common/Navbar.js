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
