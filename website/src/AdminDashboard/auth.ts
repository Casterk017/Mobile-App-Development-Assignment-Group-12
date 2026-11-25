import { createContext, useContext } from 'react'
import type { Account } from './mockData'

export type AuthState = {
  user: Account | null
  login: (email: string, password: string) => boolean
  logout: () => void
}

export const AuthContext = createContext<AuthState | null>(null)

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider')
  return ctx
}