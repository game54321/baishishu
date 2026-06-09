import { useState, useEffect, useCallback } from 'react';
import { Button, Tabs, message } from 'antd';
import { LinkOutlined, SaveOutlined } from '@ant-design/icons';
import { NodeType, CardType, MapData, Gongfa, api } from './types';
import NodeTypePanel from './components/NodeTypePanel';
import GongfaPanel from './components/GongfaPanel';
import ChapterPanel from './components/ChapterPanel';
import PropertyPanel from './components/PropertyPanel';
import NodeTypeModal from './components/NodeTypeModal';
import MapCanvas from './components/MapCanvas';

export default function App() {
  const [nodeTypes, setNodeTypes] = useState<NodeType[]>([]);
  const [cardTypes, setCardTypes] = useState<CardType[]>([]);
  const [gongfaList, setGongfaList] = useState<Gongfa[]>([]);
  const [currentMap, setCurrentMap] = useState<MapData | null>(null);
  const [selectedNodeId, setSelectedNodeId] = useState<string | null>(null);
  const [connectMode, setConnectMode] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingTypeId, setEditingTypeId] = useState<string | null>(null);
  const [propModalOpen, setPropModalOpen] = useState(false);
  const [leftTab, setLeftTab] = useState<string>('chapters');
  const [chapters, setChapters] = useState<any[]>([]);
  const [activeChapterIdx, setActiveChapterIdx] = useState<number | null>(null);
  const [messageApi, contextHolder] = message.useMessage();

  const loadNodeTypes = useCallback(async () => {
    setNodeTypes(await api('GET', '/node-types'));
  }, []);

  const loadCardTypes = useCallback(async () => {
    setCardTypes(await api('GET', '/card-types'));
  }, []);

  const loadGongfa = useCallback(async () => {
    setGongfaList(await api('GET', '/gongfa'));
  }, []);

  const loadChapters = useCallback(async () => {
    setChapters(await api('GET', '/chapters'));
  }, []);

  useEffect(() => { loadNodeTypes(); loadCardTypes(); loadGongfa(); loadChapters(); }, [loadNodeTypes, loadCardTypes, loadGongfa, loadChapters]);

  const godotMapToEditor = (rawMap: any, name: string): MapData => {
    const nodes: any[] = [];
    const connections: any[] = [];
    if (rawMap.all_nodes) {
      const connSet = new Set<string>();
      for (const id of Object.keys(rawMap.all_nodes)) {
        const n = rawMap.all_nodes[id];
        nodes.push({
          id: n.id, typeId: n.type_id, floor: n.floor_index ?? n.floor ?? 0,
          column: n.column_index ?? n.column ?? 0,
          x: n.position?.x ?? 0, y: n.position?.y ?? 0,
          dojoName: n.dojo_name, workName: n.work_name,
          consumeCards: n.consume_cards, produceCards: n.produce_cards,
        });
        for (const to of (n.connections || [])) {
          const key = `${n.id}->${to}`;
          if (!connSet.has(key)) { connSet.add(key); connections.push({ from: n.id, to }); }
        }
      }
    }
    return { id: `chapter_${name}`, name, numFloors: 15, minNodesPerFloor: 3, maxNodesPerFloor: 5, maxBranches: 3, nodes, connections, createdAt: '', updatedAt: '' };
  };

  const editorMapToGodot = (map: MapData) => {
    const allNodes: any = {};
    for (const n of map.nodes) {
      allNodes[n.id] = {
        id: n.id, type_id: n.typeId, floor_index: n.floor, column_index: n.column,
        connections: map.connections.filter(c => c.from === n.id).map(c => c.to),
        position: { x: n.x, y: n.y },
        ...(n.dojoName ? { dojo_name: n.dojoName } : {}),
        ...(n.workName ? { work_name: n.workName } : {}),
        ...(n.consumeCards?.length ? { consume_cards: n.consumeCards } : {}),
        ...(n.produceCards?.length ? { produce_cards: n.produceCards } : {}),
      };
    }
    const startNode = map.nodes.find(n => n.typeId === 'start');
    const bossNode = map.nodes.find(n => n.typeId === 'boss');
    return { floors: [], all_nodes: allNodes, start_id: startNode?.id || '', boss_id: bossNode?.id || '' };
  };

  const handleSelectChapter = (idx: number) => {
    if (activeChapterIdx !== null && currentMap) {
      const updated = [...chapters];
      updated[activeChapterIdx] = { ...updated[activeChapterIdx], map: editorMapToGodot(currentMap) };
      setChapters(updated);
    }
    setActiveChapterIdx(idx);
    const ch = chapters[idx];
    setCurrentMap(godotMapToEditor(ch.map || { floors: [], all_nodes: {}, start_id: '', boss_id: '' }, ch.name));
    setSelectedNodeId(null);
    setPropModalOpen(false);
  };

  const handleSaveAndExport = async () => {
    let chaptersToSave = [...chapters];
    if (activeChapterIdx !== null && currentMap) {
      chaptersToSave[activeChapterIdx] = { ...chaptersToSave[activeChapterIdx], map: editorMapToGodot(currentMap) };
      setChapters(chaptersToSave);
    }
    await api('PUT', '/chapters', chaptersToSave);
    messageApi.success('已保存并导出');
  };

  const handleAddNode = (typeId: string) => {
    if (!currentMap) return;
    const node = {
      id: `node_${Date.now()}`,
      typeId,
      floor: 0,
      column: 0,
      x: 400 + Math.random() * 200,
      y: 400 + Math.random() * 200,
    };
    setCurrentMap({ ...currentMap, nodes: [...currentMap.nodes, node] });
    setSelectedNodeId(node.id);
    setPropModalOpen(true);
  };

  const handleUpdateNode = (nodeId: string, updates: Partial<MapData['nodes'][0]>) => {
    if (!currentMap) return;
    setCurrentMap({
      ...currentMap,
      nodes: currentMap.nodes.map(n => n.id === nodeId ? { ...n, ...updates } : n),
    });
  };

  const handleDeleteNode = (nodeId: string) => {
    if (!currentMap) return;
    setCurrentMap({
      ...currentMap,
      nodes: currentMap.nodes.filter(n => n.id !== nodeId),
      connections: currentMap.connections.filter(c => c.from !== nodeId && c.to !== nodeId),
    });
    if (selectedNodeId === nodeId) { setSelectedNodeId(null); setPropModalOpen(false); }
  };

  const handleRemoveConnection = (from: string, to: string) => {
    if (!currentMap) return;
    setCurrentMap({
      ...currentMap,
      connections: currentMap.connections.filter(c => !(c.from === from && c.to === to)),
    });
  };

  const handleAddConnection = (from: string, to: string) => {
    if (!currentMap) return;
    if (from === to) return;
    if (currentMap.connections.find(c => c.from === from && c.to === to)) return;
    setCurrentMap({ ...currentMap, connections: [...currentMap.connections, { from, to }] });
  };

  const handleOpenModal = (editId?: string) => {
    setEditingTypeId(editId || null);
    setModalOpen(true);
  };

  const handleSelectNode = (id: string | null) => {
    setSelectedNodeId(id);
    if (id) setPropModalOpen(true);
  };

  const selectedNode = currentMap?.nodes.find(n => n.id === selectedNodeId) || null;
  const chapterName = activeChapterIdx !== null ? chapters[activeChapterIdx]?.name : '';

  return (
    <>
      {contextHolder}
      <div className="topbar">
        <h1>百世书 - 关卡图编辑器</h1>
        {chapterName && <span style={{ color: '#e8c872', fontSize: 14 }}>{chapterName}</span>}
        <Button type="primary" icon={<SaveOutlined />} onClick={handleSaveAndExport}>保存并导出</Button>
        <Button
          type={connectMode ? 'primary' : 'default'}
          icon={<LinkOutlined />}
          onClick={() => setConnectMode(!connectMode)}
        >
          {connectMode ? '退出连线' : '连线'}
        </Button>
      </div>

      <div className="main">
        <div className="sidebar sidebar-left">
          <Tabs
            activeKey={leftTab}
            onChange={setLeftTab}
            centered
            size="small"
            items={[
              { key: 'nodes', label: '节点' },
              { key: 'gongfa', label: '功法' },
              { key: 'chapters', label: '章节' },
            ]}
          />
          <div style={{ flex: 1, overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
            {leftTab === 'nodes' ? (
              <NodeTypePanel
                nodeTypes={nodeTypes}
                onAddNode={handleAddNode}
                onEditType={handleOpenModal}
                onCreateType={() => handleOpenModal()}
              />
            ) : leftTab === 'gongfa' ? (
              <GongfaPanel gongfaList={gongfaList} onRefresh={loadGongfa} />
            ) : (
              <ChapterPanel chapters={chapters} activeIdx={activeChapterIdx} onChange={setChapters} onSelect={handleSelectChapter} />
            )}
          </div>
        </div>
        <MapCanvas
          currentMap={currentMap}
          nodeTypes={nodeTypes}
          cardTypes={cardTypes}
          selectedNodeId={selectedNodeId}
          connectMode={connectMode}
          onSelectNode={handleSelectNode}
          onMoveNode={(id, x, y) => handleUpdateNode(id, { x, y })}
          onAddConnection={handleAddConnection}
        />
      </div>

      {propModalOpen && selectedNode && (
        <PropertyPanel
          currentMap={currentMap}
          node={selectedNode}
          nodeTypes={nodeTypes}
          cardTypes={cardTypes}
          onChangeType={(typeId) => selectedNodeId && handleUpdateNode(selectedNodeId, { typeId })}
          onChangeProp={(prop, val) => selectedNodeId && handleUpdateNode(selectedNodeId, { [prop]: val })}
          onDeleteNode={handleDeleteNode}
          onRemoveConnection={handleRemoveConnection}
          onClose={() => setPropModalOpen(false)}
        />
      )}

      {modalOpen && (
        <NodeTypeModal
          nodeTypes={nodeTypes}
          cardTypes={cardTypes}
          editingId={editingTypeId}
          onClose={() => setModalOpen(false)}
          onSaved={loadNodeTypes}
        />
      )}
    </>
  );
}
