import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from './auth'

export default function AdminLayout() {
  const { user, logout } = useAuth()
  const isSuper = user?.role === 'super_admin'
  const base = isSuper ? '/superadmin' : '/admin'

  return (
    <div className="shell">
      <aside className="sidebar">
        <h3>Campus Safety</h3>
        <nav>
          <NavLink to={base} end>Dashboard</NavLink>
          <NavLink to={`${base}/reports`}>Reports</NavLink>
          <NavLink to={`${base}/chat`}>Chat</NavLink>
          {isSuper && <NavLink to="/superadmin/accounts">Accounts</NavLink>}
        </nav>
      </aside>
      <div className="main">
        <header className="topbar">
          <span>{user?.name} · {isSuper ? 'Super Admin' : user?.adminRole}</span>
          <button className="primary" onClick={logout}>Log out</button>
        </header>
        <main className="content">
          <Outlet />
        </main>
      </div>
    </div>
  )
}