import { Navigate } from 'react-router-dom'
import type { ReactNode } from 'react'
import { useAuth } from './auth'
import type { Role } from './mockData'

export default function ProtectedRoute({ allow, children }: { allow: Role; children: ReactNode }) {
  const { user } = useAuth()
  if (!user) return <Navigate to="/login" replace />
  if (user.role !== allow) {
    return <Navigate to={user.role === 'super_admin' ? '/superadmin' : '/admin'} replace />
  }
  return <>{children}</>
}