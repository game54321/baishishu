import { useState } from 'react';
import { Button, Input, List, Space, Typography } from 'antd';
import { PlusOutlined, ArrowUpOutlined, ArrowDownOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import { api } from '../types';

interface Chapter {
  name: string;
  description: string;
  bg: string;
  map?: any;
}

interface Props {
  chapters: Chapter[];
  activeIdx: number | null;
  onChange: (chapters: Chapter[]) => void;
  onSelect: (idx: number) => void;
}

export default function ChapterPanel({ chapters, activeIdx, onChange, onSelect }: Props) {
  const [editIdx, setEditIdx] = useState<number | null>(null);
  const [editForm, setEditForm] = useState<Chapter>({ name: '', description: '', bg: '' });

  const addChapter = () => {
    const newCh: Chapter = { name: `第${chapters.length + 1}章`, description: '', bg: '', map: { floors: [], all_nodes: {}, start_id: '', boss_id: '' } };
    onChange([...chapters, newCh]);
    onSelect(chapters.length);
  };

  const deleteChapter = (idx: number) => {
    onChange(chapters.filter((_, i) => i !== idx));
    if (editIdx === idx) setEditIdx(null);
  };

  const moveChapter = (idx: number, dir: -1 | 1) => {
    const target = idx + dir;
    if (target < 0 || target >= chapters.length) return;
    const next = [...chapters];
    [next[idx], next[target]] = [next[target], next[idx]];
    onChange(next);
  };

  const startEdit = (idx: number) => {
    setEditIdx(idx);
    setEditForm({ name: chapters[idx].name, description: chapters[idx].description, bg: chapters[idx].bg || '' });
  };

  const saveEdit = () => {
    if (editIdx === null) return;
    const next = [...chapters];
    next[editIdx] = { ...chapters[editIdx], name: editForm.name, description: editForm.description, bg: editForm.bg };
    onChange(next);
    setEditIdx(null);
  };

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden', padding: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <Typography.Text strong>章节列表</Typography.Text>
        <Button size="small" icon={<PlusOutlined />} onClick={addChapter}>添加</Button>
      </div>

      <List
        style={{ flex: 1, overflowY: 'auto' }}
        dataSource={chapters}
        renderItem={(ch, i) => {
          const nodeCount = ch.map?.all_nodes ? Object.keys(ch.map.all_nodes).length : 0;
          const isActive = activeIdx === i;
          return (
            <List.Item
              style={{
                padding: 6, marginBottom: 4, cursor: 'pointer',
                background: isActive ? '#1a1a3a' : '#1a1a2e',
                border: isActive ? '1px solid #e8c872' : '1px solid #2a2a4a',
                borderRadius: 4,
              }}
              onClick={() => onSelect(i)}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, color: isActive ? '#e8c872' : '#e0e0e0', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{ch.name}</div>
                  <div style={{ fontSize: 11, color: '#888' }}>{nodeCount > 0 ? `${nodeCount}个节点` : '空地图'}</div>
                </div>
                <Space size={2} onClick={e => e.stopPropagation()}>
                  <Button size="small" icon={<ArrowUpOutlined />} disabled={i === 0} onClick={() => moveChapter(i, -1)} />
                  <Button size="small" icon={<ArrowDownOutlined />} disabled={i === chapters.length - 1} onClick={() => moveChapter(i, 1)} />
                  <Button size="small" icon={<EditOutlined />} onClick={() => startEdit(i)} />
                  <Button size="small" danger icon={<DeleteOutlined />} onClick={() => deleteChapter(i)} />
                </Space>
              </div>
            </List.Item>
          );
        }}
      />

      {editIdx !== null && (
        <div style={{ background: '#1a1a2e', border: '1px solid #3a3a5a', borderRadius: 6, padding: 10, marginTop: 8 }}>
          <div style={{ marginBottom: 6 }}>
            <Typography.Text type="secondary" style={{ fontSize: 11 }}>章节名称</Typography.Text>
            <Input size="small" value={editForm.name} onChange={e => setEditForm({ ...editForm, name: e.target.value })} />
          </div>
          <div style={{ marginBottom: 6 }}>
            <Typography.Text type="secondary" style={{ fontSize: 11 }}>描述</Typography.Text>
            <Input size="small" value={editForm.description} onChange={e => setEditForm({ ...editForm, description: e.target.value })} />
          </div>
          <div style={{ marginBottom: 6 }}>
            <Typography.Text type="secondary" style={{ fontSize: 11 }}>背景图路径</Typography.Text>
            <Input size="small" value={editForm.bg} onChange={e => setEditForm({ ...editForm, bg: e.target.value })} placeholder="res://assets/chapter/1/bg.png" />
          </div>
          <Space>
            <Button size="small" type="primary" onClick={saveEdit}>确认</Button>
            <Button size="small" onClick={() => setEditIdx(null)}>取消</Button>
          </Space>
        </div>
      )}
    </div>
  );
}
