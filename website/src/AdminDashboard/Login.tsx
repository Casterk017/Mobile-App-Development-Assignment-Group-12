import { useState } from 'react'
import type { FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from './auth'

export default function Login() {
  const { user, login } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')

  if (user) {
    return <Navigate to={user.role === 'super_admin' ? '/superadmin' : '/admin'} replace />
  }

  const onSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!login(email.trim(), password)) setError('Wrong email or password')
  }

  return (
    <div className="login-wrap">
      <form className="card login-card" onSubmit={onSubmit}>
        <h2>Admin Login</h2>
        <input type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <input type="password" placeholder="Password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        {error && <p className="error">{error}</p>}
        <button className="primary" type="submit">Log in</button>
        <p className="hint">Demo only: security@demo.com or super@demo.com, password demo123</p>
      </form>
    </div>
  )
}