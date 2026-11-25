import type { Report } from './mockData'

type Props = {
  report: Report
  onClose: () => void
  onResolve: (id: string) => void
}

export default function ReportDetails({ report, onClose, onResolve }: Props) {
  return (
    <div className="overlay" onClick={onClose}>
      <div className="card modal" onClick={(e) => e.stopPropagation()}>
        <h2>{report.title}</h2>
        <p className="label">Report #{report.id}</p>
        <p>{report.description}</p>
        <p><strong>Location:</strong> {report.location}</p>
        <p><strong>Reported by:</strong> {report.reportedBy}</p>
        <p><strong>Assigned to:</strong> {report.assignedTo}</p>
        <p><strong>Date:</strong> {report.createdAt}</p>
        <p>
          <strong>Status:</strong> <span className={`badge ${report.status}`}>{report.status}</span>
          {report.resolvedBy && <> by {report.resolvedBy}</>}
        </p>
        <div className="actions">
          {report.status === 'waiting' && (
            <button className="primary" onClick={() => onResolve(report.id)}>Mark as resolved</button>
          )}
          <button className="secondary" onClick={onClose}>Close</button>
        </div>
      </div>
    </div>
  )
}