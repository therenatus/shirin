import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from './store/authStore';
import Layout from './components/layout/Layout';
import Dashboard from './pages/Dashboard/Dashboard';
import ProductsList from './pages/Products/ProductsList';
import ProductForm from './pages/Products/ProductForm';
import OrdersList from './pages/Orders/OrdersList';
import OrderDetails from './pages/Orders/OrderDetails';
import UsersList from './pages/Users/UsersList';
import PromotionsList from './pages/Promotions/PromotionsList';
import StoresList from './pages/Stores/StoresList';
import Login from './pages/Login/Login';
import StaffClaim from './pages/Loyalty/StaffClaim';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
};

/** SUPPORT staff only has access to the coffee claim page. */
const AdminOnly: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const role = useAuthStore((s) => s.role);
  if (role !== 'ADMIN') {
    return <Navigate to="/loyalty" replace />;
  }
  return <>{children}</>;
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/"
          element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          }
        >
          <Route index element={<AdminOnly><Dashboard /></AdminOnly>} />
          <Route path="products" element={<AdminOnly><ProductsList /></AdminOnly>} />
          <Route path="products/new" element={<AdminOnly><ProductForm /></AdminOnly>} />
          <Route path="products/:id/edit" element={<AdminOnly><ProductForm /></AdminOnly>} />
          <Route path="orders" element={<AdminOnly><OrdersList /></AdminOnly>} />
          <Route path="orders/:id" element={<AdminOnly><OrderDetails /></AdminOnly>} />
          <Route path="loyalty" element={<StaffClaim />} />
          <Route path="users" element={<AdminOnly><UsersList /></AdminOnly>} />
          <Route path="promotions" element={<AdminOnly><PromotionsList /></AdminOnly>} />
          <Route path="stores" element={<AdminOnly><StoresList /></AdminOnly>} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
