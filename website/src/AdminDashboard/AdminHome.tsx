import { useAuth } from './auth'
import { reports } from './mockData'

export default function AdminHome() {
  const { user } = useAuth()
  if (!user) return null

  const mine = reports.filter((r) => r.assignedTo === user.adminRole)
  const waiting = mine.filter((r) => r.status === 'waiting').length
  const resolved = mine.filter((r) => r.status === 'resolved').length

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