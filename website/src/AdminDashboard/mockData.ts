export type Role = 'admin' | 'super_admin'
export type ReportStatus = 'waiting' | 'resolved'

export type Account = {
  id: string
  name: string
  email: string
  password: string // fake, demo only. Real login will use Firebase.
  role: Role
  adminRole?: string // only for regular admins
}

export type Report = {
  id: string
  title: string
  location: string
  assignedTo: string // matches an admin's adminRole
  status: ReportStatus
  createdAt: string
}

export const accounts: Account[] = [
  { id: 'a1', name: 'Alex Tan', email: 'security@demo.com', password: 'demo123', role: 'admin', adminRole: 'Security' },
  { id: 'a2', name: 'Maya Lim', email: 'maintenance@demo.com', password: 'demo123', role: 'admin', adminRole: 'Maintenance' },
  { id: 's1', name: 'Super Admin', email: 'super@demo.com', password: 'demo123', role: 'super_admin' },
]

export const reports: Report[] = [
  { id: 'r1', title: 'Suspicious person near library', location: 'Library', assignedTo: 'Security', status: 'waiting', createdAt: '2026-11-24' },
  { id: 'r2', title: 'Broken streetlight', location: 'Block C', assignedTo: 'Maintenance', status: 'waiting', createdAt: '2026-11-23' },
  { id: 'r3', title: 'Lost wallet reported', location: 'Cafeteria', assignedTo: 'Security', status: 'resolved', createdAt: '2026-11-20' },
  { id: 'r4', title: 'Water leak in corridor', location: 'Block A', assignedTo: 'Maintenance', status: 'resolved', createdAt: '2026-11-19' },
  { id: 'r5', title: 'Unlocked lab door at night', location: 'Lab 2', assignedTo: 'Security', status: 'waiting', createdAt: '2026-11-25' },
]