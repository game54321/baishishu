import { Modal, Select, Input, Button, Typography, Divider, Space } from 'antd';
import { DeleteOutlined, PlusOutlined } from '@ant-design/icons';
import { MapData, NodeType, CardType, Connection, CardRef } from '../types';

interface Props {
  currentMap: MapData | null;
  node: MapData['nodes'][0] | null;
  nodeTypes: NodeType[];
  cardTypes: CardType[];
  onChangeType: (typeId: string) => void;
  onChangeProp: (prop: string, val: any) => void;
  onDeleteNode: (id: string) => void;
  onRemoveConnection: (from: string, to: string) => void;
  onClose: () => void;
}

export default function PropertyPanel({ currentMap, node, nodeTypes, cardTypes, onChangeType, onChangeProp, onDeleteNode, onRemoveConnection, onClose }: Props) {
  if (!currentMap || !node) return null;

  const nodeType = nodeTypes.find(t => t.id === node.typeId);
  const isDojo = node.typeId === 'dojo';
  const isWork = node.typeId === 'tavern';
  const combatTypeIds = ['combat', 'elite', 'boss'];
  const isCombat = combatTypeIds.includes(node.typeId);
  const canEditName = isDojo || isWork;
  const allTypesCanEditName = true;

  const consumeCards = node.consumeCards ?? [];
  const produceCards = node.produceCards ?? [];

  const gongfaType = cardTypes.find(c => c.id === '功法');
  const gongfaList: any[] = (gongfaType as any)?.gongfaList || [];

  const wudaoType = cardTypes.find(c => c.id === '武道');
  const realms: string[] = (wudaoType as any)?.realms || [];

  const addCardRef = (field: 'consumeCards' | 'produceCards') => {
    const current = node[field] || [];
    onChangeProp(field, [...current, { type: '寿元', count: 1 }]);
  };

  const removeCardRef = (field: 'consumeCards' | 'produceCards', index: number) => {
    const current = node[field] || [];
    onChangeProp(field, current.filter((_: any, i: number) => i !== index));
  };

  const updateCardRef = (field: 'consumeCards' | 'produceCards', index: number, updates: Partial<CardRef>) => {
    const current = [...(node[field] || [])];
    current[index] = { ...current[index], ...updates };
    onChangeProp(field, current);
  };

  const inConns = currentMap.connections.filter((c: Connection) => c.to === node.id);
  const outConns = currentMap.connections.filter((c: Connection) => c.from === node.id);

  const renderCardRefRow = (r: CardRef, i: number, field: 'consumeCards' | 'produceCards') => {
    const ct = cardTypes.find(c => c.id === r.type);
    return (
      <div key={i} className="card-ref-row">
        <span style={{ fontSize: 16 }}>{ct?.icon || (r.type === '功法' ? '👊' : '?')}</span>
        <Select
          size="small"
          value={r.type}
          style={{ minWidth: 90 }}
          onChange={val => {
            const updates: any = { type: val };
            if (val === '功法' && gongfaList.length > 0) {
              updates.gongfaId = gongfaList[0].id;
              updates.gainExp = gongfaList[0].gainExp;
            }
            updateCardRef(field, i, updates);
          }}
          options={cardTypes.map(c => ({ value: c.id, label: `${c.icon} ${c.name}` }))}
        />
        {r.type === '功法' ? (
          <Select
            size="small"
            value={r.gongfaId || ''}
            style={{ flex: 1 }}
            onChange={val => {
              const gf = gongfaList.find(g => g.id === val);
              updateCardRef(field, i, { gongfaId: val, gainExp: gf?.gainExp || 30 });
            }}
            options={gongfaList.map(g => ({ value: g.id, label: g.name }))}
          />
        ) : (
          <Input
            size="small"
            type="number"
            value={r.count}
            min={1}
            style={{ width: 55 }}
            onChange={e => updateCardRef(field, i, { count: parseInt(e.target.value) || 0 })}
          />
        )}
        <Button size="small" type="text" danger icon={<DeleteOutlined />} onClick={() => removeCardRef(field, i)} />
      </div>
    );
  };

  return (
    <Modal
      title={<span>{nodeType?.label || '?'} {nodeType?.name || node.typeId}</span>}
      open
      onCancel={onClose}
      footer={[
        <Button key="delete" danger onClick={() => { onDeleteNode(node.id); onClose(); }}>删除节点</Button>,
        <Button key="done" type="primary" onClick={onClose}>完成</Button>,
      ]}
      width={480}
      style={{ top: 20 }}
      bodyStyle={{ maxHeight: '70vh', overflowY: 'auto', padding: '4px 0' }}
    >
      <div style={{ padding: '0 4px' }}>
        <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>基本信息</Typography.Title>
        <div style={{ marginBottom: 10 }}>
          <Typography.Text type="secondary" style={{ fontSize: 12 }}>节点类型</Typography.Text>
          <Select
            value={node.typeId}
            onChange={onChangeType}
            style={{ width: '100%' }}
            options={nodeTypes.map(t => ({ value: t.id, label: `${t.label} - ${t.name}` }))}
          />
        </div>

        <div style={{ marginBottom: 10 }}>
          <Typography.Text type="secondary" style={{ fontSize: 12 }}>节点名称</Typography.Text>
          <Input value={node.name || ''} onChange={e => onChangeProp('name', e.target.value)} placeholder="显示在图标下方的名称" />
        </div>

        {canEditName && isDojo && (
          <>
            <Divider style={{ margin: '8px 0' }} />
            <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>武馆设置</Typography.Title>
            <div style={{ marginBottom: 10 }}>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>武馆名称</Typography.Text>
              <Input value={node.dojoName || ''} onChange={e => onChangeProp('dojoName', e.target.value)} placeholder="输入武馆名" />
            </div>
          </>
        )}

        {canEditName && isWork && (
          <>
            <Divider style={{ margin: '8px 0' }} />
            <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>工作设置</Typography.Title>
            <div style={{ marginBottom: 10 }}>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>工作名称</Typography.Text>
              <Input value={node.workName || ''} onChange={e => onChangeProp('workName', e.target.value)} placeholder="输入工作名" />
            </div>
          </>
        )}

        {isCombat && (
          <>
            <Divider style={{ margin: '8px 0' }} />
            <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>战斗设置</Typography.Title>
            <div style={{ marginBottom: 10 }}>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>敌人境界</Typography.Text>
              <Select
                value={node.enemyRealm || '普通人'}
                onChange={val => onChangeProp('enemyRealm', val)}
                style={{ width: '100%' }}
                options={realms.map(r => ({ value: r, label: r }))}
              />
            </div>
            <div style={{ marginBottom: 10 }}>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>敌人数量</Typography.Text>
              <Input
                type="number"
                value={node.enemyCount ?? 1}
                min={1}
                max={99}
                onChange={e => onChangeProp('enemyCount', parseInt(e.target.value) || 1)}
              />
            </div>
          </>
        )}

        <Divider style={{ margin: '8px 0' }} />
        <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 4 }}>
          消耗卡牌 <Typography.Text type="secondary" style={{ fontSize: 11 }}>玩家进入后扣除</Typography.Text>
        </Typography.Title>
        {consumeCards.map((r: CardRef, i: number) => renderCardRefRow(r, i, 'consumeCards'))}
        <Button block type="dashed" size="small" icon={<PlusOutlined />} onClick={() => addCardRef('consumeCards')} style={{ marginTop: 4 }}>
          添加消耗卡牌
        </Button>

        <Divider style={{ margin: '12px 0 8px' }} />
        <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 4 }}>
          产出卡牌 <Typography.Text type="secondary" style={{ fontSize: 11 }}>完成后获得</Typography.Text>
        </Typography.Title>
        {produceCards.map((r: CardRef, i: number) => renderCardRefRow(r, i, 'produceCards'))}
        <Button block type="dashed" size="small" icon={<PlusOutlined />} onClick={() => addCardRef('produceCards')} style={{ marginTop: 4 }}>
          添加产出卡牌
        </Button>

        <Divider style={{ margin: '12px 0 8px' }} />
        <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>
          连线 ({inConns.length}入 / {outConns.length}出)
        </Typography.Title>
        {inConns.length > 0 && <Typography.Text type="secondary" style={{ fontSize: 11 }}>入边</Typography.Text>}
        {inConns.map(c => {
          const ft = nodeTypes.find(t => t.id === currentMap.nodes.find(n => n.id === c.from)?.typeId);
          return (
            <div key={c.from} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '3px 0', fontSize: 12 }}>
              <span>{ft?.label || '?'} {c.from.slice(0, 16)}</span>
              <Button size="small" danger onClick={() => onRemoveConnection(c.from, c.to)}>删除</Button>
            </div>
          );
        })}
        {outConns.length > 0 && <Typography.Text type="secondary" style={{ fontSize: 11, display: 'block', marginTop: 6 }}>出边</Typography.Text>}
        {outConns.map(c => {
          const tt = nodeTypes.find(t => t.id === currentMap.nodes.find(n => n.id === c.to)?.typeId);
          return (
            <div key={c.to} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '3px 0', fontSize: 12 }}>
              <span>{tt?.label || '?'} {c.to.slice(0, 16)}</span>
              <Button size="small" danger onClick={() => onRemoveConnection(c.from, c.to)}>删除</Button>
            </div>
          );
        })}
      </div>
    </Modal>
  );
}
