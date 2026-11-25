import { reports as seedReports } from './mockData'
import type { Report, ReportStatus } from './mockData'

// TEMPORARY mock layer.
// When the real wrappers in ../Database are ready, replace the inside of each
// function below, and keep the function names and return types the same.

let store: Report[] = seedReports.map((r) => ({ ...r }))
const wait = () => new Promise<void>((resolve) => setTimeout(resolve, 200))

export async function getReportsForRole(adminRole: string): Promise<Report[]> {
  await wait()
  return store.filter((r) => r.assignedTo === adminRole)
}

export async function getAllReports(): Promise<Report[]> {
  await wait()
  return [...store]
}

export async function updateReportStatus(id: string, status: ReportStatus, resolvedBy: string): Promise<void> {
  await wait()
  store = store.map((r) =>
    r.id === id ? { ...r, status, resolvedBy: status === 'resolved' ? resolvedBy : undefined } : r,
  )
}