import { useEffect, useState } from 'react'
import { useAuth } from './auth'
import { getReportsForRole } from './adminService'
import type { Report } from './mockData'

export default function AdminHome() {
  const { user } = useAuth()
  const [mine, setMine] = useState<Report[] | null>(null)
  const adminRole = user?.adminRole ?? ''

  useEffect(() => {
    let cancelled = false
    getReportsForRole(adminRole).then((list) => {
      if (!cancelled) setMine(list)
    })
    return () => {
      cancelled = true
    }
  }, [adminRole])

  if (!user) return null

  const waiting = mine ? mine.filter((r) => r.status === 'waiting').length : '...'
  const resolved = mine ? mine.filter((r) => r.status === 'resolved').length : '...'

  return (
    <>
      <h1>Welcome, {user.name}</h1>
      <div className="stats">
        <div className="card">
          <p className="label">Your role</p>
          <h2>{user.adminRole}</h2>
        </div>
        <div className="card">
          <p className="label">Waiting to be resolved</p>
          <h2>{waiting}</h2>
        </div>
        <div className="card">
          <p className="label">Resolved by you</p>
          <h2>{resolved}</h2>
        </div>
      </div>
    </>
  )
}