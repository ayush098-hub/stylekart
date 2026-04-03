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
