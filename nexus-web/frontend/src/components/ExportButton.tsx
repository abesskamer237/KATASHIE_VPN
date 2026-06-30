import { Download } from 'lucide-react';
import { useI18n } from '../contexts/I18nContext';

interface ExportButtonProps {
  type?: 'clients' | 'audit';
  className?: string;
}

export default function ExportButton({ type = 'clients', className = '' }: ExportButtonProps) {
  const { t } = useI18n();
  const handleExport = () => {
    window.open(`/api/export/${type}/csv`, '_blank');
  };
  return (
    <button onClick={handleExport} className={`btn btn-ghost btn-sm ${className}`}>
      <Download size={14} /> {t('accounts.export_csv')}
    </button>
  );
}
