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
