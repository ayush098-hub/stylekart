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
