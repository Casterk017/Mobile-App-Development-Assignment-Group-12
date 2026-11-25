import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import AuthProvider from './AdminDashboard/AuthProvider'
import Login from './AdminDashboard/Login'
import ProtectedRoute from './AdminDashboard/ProtectedRoute'
import AdminLayout from './AdminDashboard/AdminLayout'
import AdminHome from './AdminDashboard/AdminHome'

function ComingSoon({ title }: { title: string }) {
  return (
    <>
      <h1>{title}</h1>
      <p style={{ color: 'var(--muted)' }}>Coming soon.</p>
    </>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />

          <Route path="/admin" element={<ProtectedRoute allow="admin"><AdminLayout /></ProtectedRoute>}>
            <Route index element={<AdminHome />} />
            <Route path="reports" element={<ComingSoon title="Reports" />} />
            <Route path="chat" element={<ComingSoon title="Chat" />} />
          </Route>

          <Route path="/superadmin" element={<ProtectedRoute allow="super_admin"><AdminLayout /></ProtectedRoute>}>
            <Route index element={<ComingSoon title="Global Analytics" />} />
            <Route path="reports" element={<ComingSoon title="All Reports" />} />
            <Route path="chat" element={<ComingSoon title="Chat" />} />
            <Route path="accounts" element={<ComingSoon title="Account Management" />} />
          </Route>

          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}