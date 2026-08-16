import { useState } from 'react';
import { ProtocolType } from '@/lib/types';
import { Check, Copy, Send } from 'lucide-react';

interface ConfigOutputProps {
  config: string;
  protocol: ProtocolType;
}

export default function ConfigOutput({ config, protocol }: ConfigOutputProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(config);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleTelegram = () => {
    const encoded = encodeURIComponent(config);
    window.open(`https://t.me/share/url?text=${encoded}`, '_blank');
  };

  return (
    <div className="glass-card p-6 animate-slide-in">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-foreground">
          Configuration Générée — <span className="text-primary uppercase">{protocol}</span>
        </h3>
        <div className="flex items-center gap-2">
          <button onClick={handleCopy} className="btn-ghost flex items-center gap-2 text-sm">
            {copied ? <Check className="w-4 h-4 text-success" /> : <Copy className="w-4 h-4" />}
            {copied ? 'Copié!' : 'Copier'}
          </button>
          <button onClick={handleTelegram} className="btn-ghost flex items-center gap-2 text-sm">
            <Send className="w-4 h-4" />
            Telegram
          </button>
        </div>
      </div>
      <pre className="config-block overflow-x-auto whitespace-pre">{config}</pre>
    </div>
  );
}
