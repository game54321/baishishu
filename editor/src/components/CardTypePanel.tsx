import { useState } from 'react';
import { Button, Modal, Form, Input, Select, InputNumber, Switch, ColorPicker, List, Popconfirm, Typography } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import { CardType, api } from '../types';

interface Props {
  cardTypes: CardType[];
  onRefresh: () => void;
}

const categoryLabels: Record<string, string> = {
  life: '生命', currency: '货币', ability: '能力', item: '物品', social: '社交', spiritual: '精神',
};

export default function CardTypePanel({ cardTypes, onRefresh }: Props) {
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form] = Form.useForm();

  const openNew = () => {
    setEditingId(null);
    form.resetFields();
    form.setFieldsValue({ id: '', name: '', desc: '', icon: '🃏', color: '#999999', category: 'item', stackable: true, maxValue: 999 });
    setOpen(true);
  };

  const openEdit = (c: CardType) => {
    setEditingId(c.id);
    form.setFieldsValue({ ...c, color: c.color });
    setOpen(true);
  };

  const handleSave = async () => {
    const values = await form.validateFields();
    if (!values.id || !values.name) return;
    const payload = { ...values, color: typeof values.color === 'string' ? values.color : values.color.toHexString() };
    if (editingId) {
      await api('PUT', `/card-types/${editingId}`, payload);
    } else {
      await api('POST', '/card-types', payload);
    }
    onRefresh();
    setOpen(false);
  };

  const handleDelete = async (id: string) => {
    await api('DELETE', `/card-types/${id}`);
    onRefresh();
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderBottom: '1px solid #2a2a4a' }}>
        <Typography.Text strong>卡牌类型</Typography.Text>
        <Button size="small" icon={<PlusOutlined />} onClick={openNew}>新增</Button>
      </div>
      <List
        style={{ flex: 1, overflowY: 'auto' }}
        dataSource={cardTypes}
        renderItem={c => (
          <List.Item
            style={{ padding: '7px 8px', cursor: 'pointer', borderBottom: '1px solid #2a2a4a' }}
            onClick={() => openEdit(c)}
            actions={[
              <Popconfirm title="确定删除此卡牌类型？" onConfirm={(e) => { e?.stopPropagation(); handleDelete(c.id); }} onCancel={e => e?.stopPropagation()}>
                <Button size="small" danger icon={<DeleteOutlined />} onClick={e => e.stopPropagation()} />
              </Popconfirm>
            ]}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{
                width: 32, height: 32, borderRadius: 5, display: 'flex', alignItems: 'center',
                justifyContent: 'center', fontSize: 18, background: c.color, flexShrink: 0,
              }}>{c.icon}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 'bold' }}>{c.name}</div>
                <div style={{ fontSize: 10, color: '#888' }}>{categoryLabels[c.category] || c.category} | {c.stackable ? '可堆叠' : '不可堆叠'} | 上限:{c.maxValue}</div>
              </div>
            </div>
          </List.Item>
        )}
      />

      <Modal title={editingId ? '编辑卡牌类型' : '新增卡牌类型'} open={open} onCancel={() => setOpen(false)} onOk={handleSave} destroyOnClose>
        <Form form={form} layout="vertical" size="small">
          <Form.Item label="ID" name="id" rules={[{ required: true }]}>
            <Input disabled={!!editingId} />
          </Form.Item>
          <Form.Item label="名称" name="name" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item label="描述" name="desc">
            <Input />
          </Form.Item>
          <Form.Item label="图标" name="icon">
            <Input style={{ width: 60 }} />
          </Form.Item>
          <Form.Item label="颜色" name="color">
            <ColorPicker />
          </Form.Item>
          <Form.Item label="分类" name="category">
            <Select options={[
              { value: 'life', label: '生命' }, { value: 'currency', label: '货币' },
              { value: 'ability', label: '能力' }, { value: 'item', label: '物品' },
              { value: 'social', label: '社交' }, { value: 'spiritual', label: '精神' },
            ]} />
          </Form.Item>
          <Form.Item label="可堆叠" name="stackable" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Form.Item label="上限" name="maxValue">
            <InputNumber min={1} style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
