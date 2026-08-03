import React, {useEffect, useState} from 'react';
import {createRoot} from 'react-dom/client';
import './styles.css';

function App() {
  const [status, setStatus] = useState('checking');
  useEffect(() => { fetch('/api/v1/status').then(r => r.json()).then(() => setStatus('healthy')).catch(() => setStatus('unavailable')); }, []);
  return <main><p className="eyebrow">PLATFORM ENGINEERING HOME LAB</p><h1>Service platform status</h1><p>This application is deployed through Helm and observed by Prometheus.</p><section><span className={status}/><strong> API is {status}</strong></section><ul><li>Ingress routing</li><li>Metrics and alerting</li><li>Autoscaling and resource limits</li><li>Network policy and RBAC</li></ul></main>;
}
createRoot(document.getElementById('root')).render(<App/>);
