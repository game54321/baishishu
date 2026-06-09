import { useState } from 'react';
import { Button, Modal, Form, Input, InputNumber, ColorPicker, Upload, List, Popconfirm, Typography, message } from 'antd';
import { PlusOutlined, DeleteOutlined, UploadOutlined, ClearOutlined } from '@ant-design/icons';
import { Gongfa, api } from '../types';

interface Props {
  gongfaList: Gongfa[];
  onRefresh: () => void;
}

export default function GongfaPanel({ gongfaList, onRefresh }: Props) {
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form] = Form.useForm();
  const [previewPath, setPreviewPath] = useState<string>('');
  const [hitEffectPreview, setHitEffectPreview] = useState<string>('');

  const imgSrc = (path: string) => {
    if (!path || typeof path !== 'string' || !path.startsWith('res://')) return '';
    return path.replace('res://assets/', '/game_assets/');
  };

  const openNew = () => {
    setEditingId(null);
    setPreviewPath('');
    setHitEffectPreview('');
    form.resetFields();
    form.setFieldsValue({
      id: '', name: '', icon_path: '', hit_effect_path: '', desc: '',
      baseDamage: 10, gainExp: 30, color: '#D97333',
    });
    setOpen(true);
  };

  const openEdit = (g: Gongfa) => {
    setEditingId(g.id);
    setPreviewPath(g.icon_path || '');
    setHitEffectPreview(g.hit_effect_path || '');
    form.setFieldsValue({ ...g, color: g.color || '#D97333' });
    setOpen(true);
  };

  const handleSave = async () => {
    const values = await form.validateFields();
    if (!values.id || !values.name) return;
    const payload = {
      ...values,
      color: typeof values.color === 'string' ? values.color : values.color?.toHexString?.() || '#D97333',
      baseDamage: Number(values.baseDamage) || 10,
      gainExp: Number(values.gainExp) || 30,
    };
    if (editingId) {
      await api('PUT', `/gongfa/${editingId}`, payload);
    } else {
      await api('POST', '/gongfa', payload);
    }
    onRefresh();
    setOpen(false);
  };

  const handleDelete = async (id: string) => {
    await api('DELETE', `/gongfa/${id}`);
    onRefresh();
  };

  const handleCleanupUnused = async () => {
    try {
      const res = await fetch('/api/gongfa/cleanup-unused', { method: 'POST' });
      const data = await res.json();
      if (data.deleted > 0) {
        message.success(`已清理 ${data.deleted} 个未使用插图`);
      } else {
        message.info('没有需要清理的插图');
      }
    } catch {
      message.error('清理失败');
    }
  };

  const uploadProps = {
    name: 'file',
    accept: '.png,.jpg,.jpeg,.webp',
    maxCount: 1,
    showUploadList: false,
    listType: 'text' as const,
    isImageUrl: () => false,
    customRequest: async (options: any) => {
      const formData = new FormData();
      formData.append('file', options.file);
      try {
        const res = await fetch('/api/gongfa/upload', { method: 'POST', body: formData });
        const data = await res.json();
        if (data.icon_path) {
          form.setFieldsValue({ icon_path: data.icon_path });
          setPreviewPath(data.icon_path);
          options.onSuccess?.(data);
        } else {
          options.onError?.(new Error(data.error || '上传失败'));
        }
      } catch (err) {
        options.onError?.(err);
      }
    },
  };

  const hitEffectUploadProps = {
    name: 'file',
    accept: '.png,.jpg,.jpeg,.webp',
    maxCount: 1,
    showUploadList: false,
    listType: 'text' as const,
    isImageUrl: () => false,
    customRequest: async (options: any) => {
      const formData = new FormData();
      formData.append('file', options.file);
      try {
        const res = await fetch('/api/gongfa/upload', { method: 'POST', body: formData });
        const data = await res.json();
        if (data.icon_path) {
          form.setFieldsValue({ hit_effect_path: data.icon_path });
          setHitEffectPreview(data.icon_path);
          options.onSuccess?.(data);
        } else {
          options.onError?.(new Error(data.error || '上传失败'));
        }
      } catch (err) {
        options.onError?.(err);
      }
    },
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', borderBottom: '1px solid #2a2a4a' }}>
        <Typography.Text strong>功法管理</Typography.Text>
        <Button size="small" icon={<PlusOutlined />} onClick={openNew}>新增</Button>
        <Button size="small" icon={<ClearOutlined />} onClick={handleCleanupUnused} style={{ marginLeft: 4 }}>清理未用插图</Button>
      </div>
      <List
        style={{ flex: 1, overflowY: 'auto' }}
        dataSource={gongfaList}
        renderItem={g => (
          <List.Item
            style={{ padding: '7px 8px', cursor: 'pointer', borderBottom: '1px solid #2a2a4a' }}
            onClick={() => openEdit(g)}
            actions={[
              <Popconfirm title="确定删除此功法？" onConfirm={(e) => { e?.stopPropagation(); handleDelete(g.id); }} onCancel={e => e?.stopPropagation()}>
                <Button size="small" danger icon={<DeleteOutlined />} onClick={e => e.stopPropagation()} />
              </Popconfirm>
            ]}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{
                width: 36, height: 36, borderRadius: 5, display: 'flex', alignItems: 'center',
                justifyContent: 'center', fontSize: 20, background: g.color || '#D97333', flexShrink: 0,
                overflow: 'hidden',
              }}>
                <img
                  src={imgSrc(g.icon_path)}
                  alt=""
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12, fontWeight: 'bold' }}>{g.name}</div>
                <div style={{ fontSize: 10, color: '#888' }}>
                  伤害:{g.baseDamage} | 经验:{g.gainExp}
                  {g.desc && ` | ${g.desc}`}
                </div>
              </div>
            </div>
          </List.Item>
        )}
      />

      <Modal
        title={editingId ? '编辑功法' : '新增功法'}
        open={open}
        onCancel={() => setOpen(false)}
        onOk={handleSave}
        destroyOnClose
        width={480}
      >
        <Form form={form} layout="vertical" size="small">
          <Form.Item label="ID" name="id" rules={[{ required: true, message: '请输入ID' }]}>
            <Input disabled={!!editingId} placeholder="如 wild-dog-fist" />
          </Form.Item>
          <Form.Item label="名称" name="name" rules={[{ required: true, message: '请输入名称' }]}>
            <Input placeholder="如 野狗拳" />
          </Form.Item>
          <Form.Item label="描述" name="desc">
            <Input.TextArea rows={2} placeholder="功法效果描述" />
          </Form.Item>
          <Form.Item label="颜色" name="color">
            <ColorPicker />
          </Form.Item>
          <Form.Item label="插图" name="icon_path">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {imgSrc(previewPath) && (
                <img
                  src={imgSrc(previewPath)}
                  alt="preview"
                  style={{ width: 64, height: 64, objectFit: 'cover', borderRadius: 6, border: '1px solid #444' }}
                  onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                />
              )}
              <Upload {...uploadProps}>
                <Button icon={<UploadOutlined />}>{previewPath ? '更换插图' : '上传插图'}</Button>
              </Upload>
              {previewPath && (
                <Button size="small" danger onClick={() => { form.setFieldsValue({ icon_path: '' }); setPreviewPath(''); }}>移除</Button>
              )}
            </div>
          </Form.Item>
          <Form.Item label="击中特效" name="hit_effect_path">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {imgSrc(hitEffectPreview) && (
                <img
                  src={imgSrc(hitEffectPreview)}
                  alt="preview"
                  style={{ width: 64, height: 64, objectFit: 'cover', borderRadius: 6, border: '1px solid #444' }}
                  onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }}
                />
              )}
              <Upload {...hitEffectUploadProps}>
                <Button icon={<UploadOutlined />}>{hitEffectPreview ? '更换特效' : '上传击中特效'}</Button>
              </Upload>
              {hitEffectPreview && (
                <Button size="small" danger onClick={() => { form.setFieldsValue({ hit_effect_path: '' }); setHitEffectPreview(''); }}>移除</Button>
              )}
            </div>
          </Form.Item>
          <div style={{ display: 'flex', gap: 12 }}>
            <Form.Item label="基础伤害" name="baseDamage" style={{ flex: 1 }}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item label="获取经验" name="gainExp" style={{ flex: 1 }}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
          </div>
        </Form>
      </Modal>
    </div>
  );
}
