import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { HOME_BY_ROLE, StaffRole, useAuthStore } from './store/authStore';
import Layout from './components/layout/Layout';
import Dashboard from './pages/Dashboard/Dashboard';
import ProductsList from './pages/Products/ProductsList';
import ProductForm from './pages/Products/ProductForm';
import OrdersList from './pages/Orders/OrdersList';
import OrderDetails from './pages/Orders/OrderDetails';
import UsersList from './pages/Users/UsersList';
import PromotionsList from './pages/Promotions/PromotionsList';
import StoresList from './pages/Stores/StoresList';
import StaffList from './pages/Staff/StaffList';
import Login from './pages/Login/Login';
import StaffClaim from './pages/Loyalty/StaffClaim';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
};

/** Renders the page only for the given roles; others go to their home page. */
const RequireRole: React.FC<{ roles: StaffRole[]; children: React.ReactNode }> = ({
  roles,
  children,
}) => {
  const role = useAuthStore((s) => s.role);
  if (!role || !roles.includes(role)) {
    const home = role ? HOME_BY_ROLE[role] : '/login';
    // Avoid a redirect loop if the home page itself is not allowed
    return <Navigate to={home === '/' ? '/login' : home} replace />;
  }
  return <>{children}</>;
};

const ADMIN: StaffRole[] = ['ADMIN'];
const ORDERS: StaffRole[] = ['ADMIN', 'STORE_STAFF'];
const CASH_DESK: StaffRole[] = ['ADMIN', 'STORE_STAFF', 'SUPPORT'];

/** Index page: the dashboard for admins, the role's home page for others. */
const Home: React.FC = () => {
  const role = useAuthStore((s) => s.role);
  if (role && role !== 'ADMIN') {
    return <Navigate to={HOME_BY_ROLE[role]} replace />;
  }
  return <RequireRole roles={ADMIN}><Dashboard /></RequireRole>;
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
          <Route index element={<Home />} />
          <Route path="products" element={<RequireRole roles={ADMIN}><ProductsList /></RequireRole>} />
          <Route path="products/new" element={<RequireRole roles={ADMIN}><ProductForm /></RequireRole>} />
          <Route path="products/:id/edit" element={<RequireRole roles={ADMIN}><ProductForm /></RequireRole>} />
          <Route path="orders" element={<RequireRole roles={ORDERS}><OrdersList /></RequireRole>} />
          <Route path="orders/:id" element={<RequireRole roles={ORDERS}><OrderDetails /></RequireRole>} />
          <Route path="loyalty" element={<RequireRole roles={CASH_DESK}><StaffClaim /></RequireRole>} />
          <Route path="users" element={<RequireRole roles={ADMIN}><UsersList /></RequireRole>} />
          <Route path="staff" element={<RequireRole roles={ADMIN}><StaffList /></RequireRole>} />
          <Route path="promotions" element={<RequireRole roles={ADMIN}><PromotionsList /></RequireRole>} />
          <Route path="stores" element={<RequireRole roles={ADMIN}><StoresList /></RequireRole>} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;
