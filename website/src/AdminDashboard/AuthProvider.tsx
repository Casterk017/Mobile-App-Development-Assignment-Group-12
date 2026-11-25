import { useState } from 'react'
import type { ReactNode } from 'react'
import { AuthContext } from './auth'
import { accounts } from './mockData'
import type { Account } from './mockData'

const KEY = 'mockUserId' // demo only, Firebase will replace this

export default function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<Account | null>(() => {
    try {
      const id = sessionStorage.getItem(KEY)
      return accounts.find((a) => a.id === id) ?? null
    } catch {
      return null
    }
  })

  const login = (email: string, password: string) => {
    const found = accounts.find((a) => a.email === email && a.password === password)
    if (!found) return false
    setUser(found)
    try {
      sessionStorage.setItem(KEY, found.id)
    } catch {
      /* ignore */
    }
    return true
  }

  const logout = () => {
    setUser(null)
    try {
      sessionStorage.removeItem(KEY)
    } catch {
      /* ignore */
    }
  }

  return <AuthContext.Provider value={{ user, login, logout }}>{children}</AuthContext.Provider>
}