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
