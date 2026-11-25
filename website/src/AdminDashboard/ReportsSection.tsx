import { useEffect, useState } from 'react'
import { useAuth } from './auth'
import { getAllReports, getReportsForRole, updateReportStatus } from './adminService'
import type { Report } from './mockData'
import ReportDetails from './ReportDetails'

type Filter = 'all' | 'waiting' | 'resolved'

export default function ReportsSection() {
  const { user } = useAuth()
  const [reports, setReports] = useState<Report[] | null>(null)
  const [filter, setFilter] = useState<Filter>('all')
  const [selected, setSelected] = useState<Report | null>(null)
  const [reloadKey, setReloadKey] = useState(0)

  const isSuper = user?.role === 'super_admin'
  const adminRole = user?.adminRole ?? ''

  useEffect(() => {
    let cancelled = false
    const request = isSuper ? getAllReports() : getReportsForRole(adminRole)
    request.then((list) => {
      if (!cancelled) setReports(list)
    })
    return () => {
      cancelled = true
    }
  }, [isSuper, adminRole, reloadKey])

  if (!user) return null
  if (reports === null) return <p className="label">Loading reports...</p>

  const shown = reports.filter((r) => filter === 'all' || r.status === filter)

  const resolve = async (id: string) => {
    await updateReportStatus(id, 'resolved', user.name)
    setSelected(null)
    setReloadKey((k) => k + 1)
  }

  return (
    <>
      <h1>{isSuper ? 'All Reports' : `${user.adminRole} Reports`}</h1>

      <div className="tabs">
        {(['all', 'waiting', 'resolved'] as Filter[]).map((f) => (
          <button key={f} className={filter === f ? 'tab active' : 'tab'} onClick={() => setFilter(f)}>
            {f}
          </button>
        ))}
      </div>

      <div className="card" style={{ padding: 0, overflowX: 'auto' }}>
        <table className="table">
          <thead>
            <tr>
              <th>Title</th>
              <th>Location</th>
              {isSuper && <th>Assigned to</th>}
              <th>Date</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {shown.map((r) => (
              <tr key={r.id}>
                <td>{r.title}</td>
                <td>{r.location}</td>
                {isSuper && <td>{r.assignedTo}</td>}
                <td>{r.createdAt}</td>
                <td><span className={`badge ${r.status}`}>{r.status}</span></td>
                <td>
                  <button className="secondary" onClick={() => setSelected(r)}>Report Details</button>
                </td>
              </tr>
            ))}
            {shown.length === 0 && (
              <tr>
                <td colSpan={6} style={{ color: 'var(--muted)' }}>No reports here.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && <ReportDetails report={selected} onClose={() => setSelected(null)} onResolve={resolve} />}
    </>
  )
}