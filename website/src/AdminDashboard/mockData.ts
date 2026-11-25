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
  description: string
  location: string
  reportedBy: string
  assignedTo: string // matches an admin's adminRole
  status: ReportStatus
  createdAt: string
  resolvedBy?: string
}

export const accounts: Account[] = [
  { id: 'a1', name: 'Alex Tan', email: 'security@demo.com', password: 'demo123', role: 'admin', adminRole: 'Security' },
  { id: 'a2', name: 'Maya Lim', email: 'maintenance@demo.com', password: 'demo123', role: 'admin', adminRole: 'Maintenance' },
  { id: 's1', name: 'Super Admin', email: 'super@demo.com', password: 'demo123', role: 'super_admin' },
]

export const reports: Report[] = [
  { id: 'r1', title: 'Suspicious person near library', description: 'A person has been standing near the back entrance for over an hour.', location: 'Library', reportedBy: 'Student A', assignedTo: 'Security', status: 'waiting', createdAt: '2026-11-24' },
  { id: 'r2', title: 'Broken streetlight', description: 'The light on the path to Block C is out, so the path is very dark at night.', location: 'Block C', reportedBy: 'Student B', assignedTo: 'Maintenance', status: 'waiting', createdAt: '2026-11-23' },
  { id: 'r3', title: 'Lost wallet reported', description: 'A black wallet was found near the cafeteria counter.', location: 'Cafeteria', reportedBy: 'Student C', assignedTo: 'Security', status: 'resolved', createdAt: '2026-11-20', resolvedBy: 'Alex Tan' },
  { id: 'r4', title: 'Water leak in corridor', description: 'Water is dripping from the ceiling on level 2.', location: 'Block A', reportedBy: 'Student D', assignedTo: 'Maintenance', status: 'resolved', createdAt: '2026-11-19', resolvedBy: 'Maya Lim' },
  { id: 'r5', title: 'Unlocked lab door at night', description: 'Lab 2 was found unlocked at 11 PM with nobody inside.', location: 'Lab 2', reportedBy: 'Student E', assignedTo: 'Security', status: 'waiting', createdAt: '2026-11-25' },
]