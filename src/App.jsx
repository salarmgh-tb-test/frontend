import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [name, setName] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch(import.meta.env.VITE_API_URL || 'http://backend.test/')
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        setName(data.name)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  if (loading) {
    return <div className="container">Loading...</div>
  }

  if (error) {
    return <div className="container">Error: {error}</div>
  }

  return (
    <div className="container">
      <h1>Hello {name}!</h1>
    </div>
  )
}

export default App

