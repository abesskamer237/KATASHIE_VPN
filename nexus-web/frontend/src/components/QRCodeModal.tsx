import { useState } from 'react';
import { QrCode, X, Copy, Download, ExternalLink } from 'lucide-react';

interface QRCodeModalProps {
  clientId: string;
  username: string;
  protocol: string;
  onClose: () => void;
}

export default function QRCodeModal({ clientId, username, protocol, onClose }: QRCodeModalProps) {
  const [qrData, setQrData] = useState<{ qr?: string; uri?: string } | null>(null);
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const token = localStorage.getItem('token');

  const load = async () => {
    setLoading(true);
    try {
      const r = await fetch(`/api/qrcode/${clientId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setQrData(await r.json());
    } finally { setLoading(false); }
  };

  if (!qrData && !loading) load();

  const copyUri = async () => {
    if (!qrData?.uri) return;
    await navigator.clipboard.writeText(qrData.uri);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const downloadQr = () => {
    if (!qrData?.qr) return;
    const link = document.createElement('a');
    link.href = qrData.qr;
    link.download = `katashie-${username}.png`;
    link.click();
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" style={{ maxWidth: 400 }} onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <QrCode size={18} color="var(--blue)" />
            <h3>QR Code — {username}</h3>
          </div>
          <button className="btn btn-ghost btn-sm" onClick={onClose}><X size={16} /></button>
        </div>
        <div className="modal-body" style={{ textAlign: 'center', display: 'grid', gap: '1rem' }}>
          <span className="badge" style={{ justifySelf: 'center' }}>{protocol.toUpperCase()}</span>
          {loading && <div style={{ padding: '2rem', color: 'var(--text-muted)' }}>Génération...</div>}
          {qrData?.qr && (
            <img src={qrData.qr} alt="QR Code" style={{ width: '100%', borderRadius: 12, border: '1px solid var(--border)' }} />
          )}
          {qrData?.uri && (
            <div style={{ background: 'var(--surface-2)', borderRadius: 8, padding: '0.75rem', wordBreak: 'break-all', fontSize: '0.7rem', color: 'var(--text-muted)', textAlign: 'left', maxHeight: 80, overflow: 'auto' }}>
              {qrData.uri}
            </div>
          )}
          <div style={{ display: 'flex', gap: '0.5rem', justifyContent: 'center' }}>
            <button className="btn btn-ghost btn-sm" onClick={copyUri}>
              <Copy size={14} /> {copied ? 'Copié !' : 'Copier URI'}
            </button>
            <button className="btn btn-primary btn-sm" onClick={downloadQr}>
              <Download size={14} /> Télécharger
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
