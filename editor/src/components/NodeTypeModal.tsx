import { useState } from 'react';
import { Modal, Form, Input, Select, InputNumber, ColorPicker, Button, Divider, Typography } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import { NodeType, CardType, CardRef, api } from '../types';

interface Props {
  nodeTypes: NodeType[];
  cardTypes: CardType[];
  editingId: string | null;
  onClose: () => void;
  onSaved: () => void;
}

function CardRefFormItem({ label, value = [], cardTypes, onChange }: {
  label: string;
  value?: CardRef[];
  cardTypes: CardType[];
  onChange?: (refs: CardRef[]) => void;
}) {
  const addRef = () => {
    if (cardTypes.length === 0 || !onChange) return;
    onChange([...value, { type: cardTypes[0].id, count: 1 }]);
  };

  const updateRef = (idx: number, field: keyof CardRef, val: any) => {
    const next = [...value];
    next[idx] = { ...next[idx], [field]: val };
    onChange?.(next);
  };

  const removeRef = (idx: number) => {
    onChange?.(value.filter((_, i) => i !== idx));
  };

  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <Typography.Text type="secondary" style={{ fontSize: 11 }}>{label}</Typography.Text>
        <Button size="small" icon={<PlusOutlined />} onClick={addRef} />
      </div>
      {value.map((ref, idx) => (
        <div key={idx} style={{ display: 'flex', gap: 4, alignItems: 'center', marginBottom: 3 }}>
          <Select
            size="small"
            value={ref.type}
            style={{ flex: 1 }}
            onChange={val => updateRef(idx, 'type', val)}
            options={cardTypes.map(c => ({ value: c.id, label: `${c.icon} ${c.name}` }))}
          />
          <InputNumber size="small" value={ref.count} min={1} style={{ width: 50 }} onChange={val => updateRef(idx, 'count', val || 1)} />
          <Button size="small" danger icon={<DeleteOutlined />} onClick={() => removeRef(idx)} />
        </div>
      ))}
    </div>
  );
}

export default function NodeTypeModal({ nodeTypes, cardTypes, editingId, onClose, onSaved }: Props) {
  const existing = editingId ? nodeTypes.find(t => t.id === editingId) : null;
  const [form] = Form.useForm();

  const [requireCards, setRequireCards] = useState<CardRef[]>(existing?.requireCards || []);
  const [consumeCards, setConsumeCards] = useState<CardRef[]>(existing?.consumeCards || []);
  const [produceCards, setProduceCards] = useState<CardRef[]>(existing?.produceCards || []);

  const handleSave = async () => {
    const values = await form.validateFields();
    const payload = {
      ...values,
      color: typeof values.color === 'string' ? values.color : values.color?.toHexString?.() || values.color,
      requireCards,
      consumeCards,
      produceCards,
    };
    if (editingId) {
      await api('PUT', `/node-types/${editingId}`, payload);
    } else {
      await api('POST', '/node-types', payload);
    }
    onSaved();
    onClose();
  };

  return (
    <Modal
      title={editingId ? '编辑节点类型' : '新增节点类型'}
      open
      onCancel={onClose}
      onOk={handleSave}
      width={440}
      destroyOnClose
    >
      <Form form={form} layout="vertical" size="small" initialValues={{
        id: existing?.id || '',
        label: existing?.label || '',
        name: existing?.name || '',
        category: existing?.category || 'story',
        color: existing?.color || '#999999',
        weight: existing?.weight ?? 0.05,
        minFloor: existing?.minFloor ?? 0,
        maxFloor: existing?.maxFloor ?? -1,
        maxPerMap: existing?.maxPerMap ?? -1,
      }}>
        <Form.Item label="ID" name="id" rules={[{ required: true }]}>
          <Input disabled={!!editingId} />
        </Form.Item>
        <Form.Item label="标签" name="label" rules={[{ required: true }]}>
          <Input maxLength={2} />
        </Form.Item>
        <Form.Item label="名称" name="name" rules={[{ required: true }]}>
          <Input />
        </Form.Item>
        <Form.Item label="分类" name="category">
          <Select options={[
            { value: 'combat', label: '战斗' }, { value: 'story', label: '剧情' },
            { value: 'rest', label: '休息' }, { value: 'shop', label: '商店' },
            { value: 'start', label: '起点' },
          ]} />
        </Form.Item>
        <Form.Item label="颜色" name="color">
          <ColorPicker />
        </Form.Item>
        <Form.Item label="权重" name="weight">
          <InputNumber step={0.01} min={0} max={1} style={{ width: '100%' }} />
        </Form.Item>
        <Form.Item label="最早层" name="minFloor">
          <InputNumber min={0} style={{ width: '100%' }} />
        </Form.Item>
        <Form.Item label="最晚层" name="maxFloor">
          <InputNumber min={-1} style={{ width: '100%' }} />
        </Form.Item>
        <Form.Item label="每图上限" name="maxPerMap">
          <InputNumber min={-1} style={{ width: '100%' }} />
        </Form.Item>

        <Divider />
        <Typography.Title level={5} style={{ color: '#e8c872', marginBottom: 8 }}>卡牌配置</Typography.Title>
        <CardRefFormItem label="需求卡牌 (进入条件)" value={requireCards} cardTypes={cardTypes} onChange={setRequireCards} />
        <CardRefFormItem label="消耗卡牌 (进入后扣除)" value={consumeCards} cardTypes={cardTypes} onChange={setConsumeCards} />
        <CardRefFormItem label="产出卡牌 (完成后获得)" value={produceCards} cardTypes={cardTypes} onChange={setProduceCards} />
      </Form>
    </Modal>
  );
}
