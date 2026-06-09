import { Button, List, Typography } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { NodeType } from '../types';

interface Props {
  nodeTypes: NodeType[];
  onAddNode: (typeId: string) => void;
  onEditType: (id: string) => void;
  onCreateType: () => void;
}

export default function NodeTypePanel({ nodeTypes, onAddNode, onEditType, onCreateType }: Props) {
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderBottom: '1px solid #2a2a4a' }}>
        <Typography.Text strong>节点类型</Typography.Text>
        <Button size="small" icon={<PlusOutlined />} onClick={onCreateType}>新增</Button>
      </div>
      <List
        style={{ flex: 1, overflowY: 'auto' }}
        dataSource={nodeTypes}
        renderItem={t => (
          <List.Item
            style={{ padding: '7px 8px', cursor: 'pointer', borderBottom: '1px solid #2a2a4a' }}
            onClick={() => onAddNode(t.id)}
            onDoubleClick={() => onEditType(t.id)}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%' }}>
              <div style={{
                width: 32, height: 32, borderRadius: 5, display: 'flex', alignItems: 'center',
                justifyContent: 'center', fontSize: 14, fontWeight: 'bold', background: t.color, flexShrink: 0,
              }}>{t.label}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 'bold' }}>{t.name}</div>
                <div style={{ fontSize: 10, color: '#888' }}>{t.category} | w:{t.weight}</div>
              </div>
            </div>
          </List.Item>
        )}
      />
    </div>
  );
}
