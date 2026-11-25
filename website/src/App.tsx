export default function App() {
  return (
    <div style={{ padding: 32 }}>
      <h1>Admin Dashboard</h1>
      <div className="card" style={{ maxWidth: 360 }}>
        <h3>Theme test</h3>
        <p style={{ color: 'var(--muted)' }}>Reports waiting: 12</p>
        <button className="primary">Report Details</button>
      </div>
    </div>
  )
}