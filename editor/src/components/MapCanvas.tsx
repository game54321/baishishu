import { useRef, useEffect, useCallback } from 'react';
import { MapData, NodeType, CardType } from '../types';

interface Props {
  currentMap: MapData | null;
  nodeTypes: NodeType[];
  cardTypes: CardType[];
  selectedNodeId: string | null;
  connectMode: boolean;
  onSelectNode: (id: string | null) => void;
  onMoveNode: (id: string, x: number, y: number) => void;
  onAddConnection: (from: string, to: string) => void;
}

const NODE_R = 28;

export default function MapCanvas({ currentMap, nodeTypes, cardTypes, selectedNodeId, connectMode, onSelectNode, onMoveNode, onAddConnection }: Props) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const camRef = useRef({ x: 0, y: 0, zoom: 1 });
  const dragRef = useRef({ active: false, nodeId: '', ox: 0, oy: 0 });
  const panRef = useRef({ active: false, sx: 0, sy: 0, cx: 0, cy: 0 });
  const connectRef = useRef<string | null>(null);
  const mouseWorldRef = useRef({ x: 0, y: 0 });

  const screenToWorld = (sx: number, sy: number) => {
    const cam = camRef.current;
    return { x: (sx - cam.x) / cam.zoom, y: (sy - cam.y) / cam.zoom };
  };

  const findNodeAt = (wx: number, wy: number) => {
    if (!currentMap) return null;
    for (let i = currentMap.nodes.length - 1; i >= 0; i--) {
      const n = currentMap.nodes[i];
      const dx = n.x - wx, dy = n.y - wy;
      if (dx * dx + dy * dy <= NODE_R * NODE_R) return n;
    }
    return null;
  };

  const render = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d')!;
    const cam = camRef.current;
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // 网格
    const gs = 50 * cam.zoom;
    const ox = cam.x % gs, oy = cam.y % gs;
    ctx.strokeStyle = '#1a1a3e';
    ctx.lineWidth = 1;
    for (let x = ox; x < canvas.width; x += gs) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, canvas.height); ctx.stroke(); }
    for (let y = oy; y < canvas.height; y += gs) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(canvas.width, y); ctx.stroke(); }

    if (!currentMap) return;

    ctx.save();
    ctx.translate(cam.x, cam.y);
    ctx.scale(cam.zoom, cam.zoom);

    // 连线
    currentMap.connections.forEach(c => {
      const from = currentMap.nodes.find(n => n.id === c.from);
      const to = currentMap.nodes.find(n => n.id === c.to);
      if (!from || !to) return;
      const hl = selectedNodeId === c.from || selectedNodeId === c.to;
      ctx.beginPath();
      ctx.moveTo(from.x, from.y);
      ctx.lineTo(to.x, to.y);
      ctx.strokeStyle = hl ? '#e8c872' : '#4a4a6a';
      ctx.lineWidth = hl ? 3 : 1.5;
      ctx.stroke();
    });

    // 连线预览
    if (connectMode && connectRef.current) {
      const from = currentMap.nodes.find(n => n.id === connectRef.current);
      if (from) {
        ctx.beginPath();
        ctx.setLineDash([6, 4]);
        ctx.moveTo(from.x, from.y);
        ctx.lineTo(mouseWorldRef.current.x, mouseWorldRef.current.y);
        ctx.strokeStyle = '#e8c872';
        ctx.lineWidth = 2;
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }

    // 节点
    currentMap.nodes.forEach(node => {
      const type = nodeTypes.find(t => t.id === node.typeId);
      const color = type?.color || '#666';
      const label = type?.label || '?';
      const isSel = node.id === selectedNodeId;
      const isCF = node.id === connectRef.current;

      if (isSel || isCF) {
        ctx.beginPath();
        ctx.arc(node.x, node.y, NODE_R + 6, 0, Math.PI * 2);
        ctx.fillStyle = isCF ? 'rgba(232,200,114,0.3)' : 'rgba(232,200,114,0.2)';
        ctx.fill();
      }

      ctx.beginPath();
      ctx.arc(node.x, node.y, NODE_R, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.fill();
      ctx.strokeStyle = isSel ? '#e8c872' : '#2a2a4a';
      ctx.lineWidth = isSel ? 3 : 1.5;
      ctx.stroke();

      ctx.fillStyle = '#fff';
      ctx.font = 'bold 16px Microsoft YaHei';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(label, node.x, node.y);
    });

    ctx.restore();
  }, [currentMap, nodeTypes, selectedNodeId, connectMode]);

  // resize
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const parent = canvas.parentElement!;
    const resize = () => { canvas.width = parent.clientWidth; canvas.height = parent.clientHeight; render(); };
    resize();
    window.addEventListener('resize', resize);
    return () => window.removeEventListener('resize', resize);
  }, [render]);

  // re-render on state change
  useEffect(() => { render(); }, [render]);

  // keyboard
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { connectRef.current = null; onSelectNode(null); }
      if (e.key === 'Delete' && selectedNodeId) { /* handled by parent */ }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [selectedNodeId, onSelectNode]);

  const handleMouseDown = (e: React.MouseEvent) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
    const w = screenToWorld(sx, sy);

    if (e.button === 2 || e.button === 1) {
      panRef.current = { active: true, sx: e.clientX, sy: e.clientY, cx: camRef.current.x, cy: camRef.current.y };
      return;
    }

    const node = findNodeAt(w.x, w.y);

    if (connectMode) {
      if (node) {
        if (!connectRef.current) {
          connectRef.current = node.id;
        } else if (connectRef.current !== node.id) {
          onAddConnection(connectRef.current, node.id);
          connectRef.current = null;
        }
      }
      render();
      return;
    }

    if (node) {
      onSelectNode(node.id);
      dragRef.current = { active: true, nodeId: node.id, ox: w.x - node.x, oy: w.y - node.y };
    } else {
      // 左键点击空白区域：平移画布
      onSelectNode(null);
      panRef.current = { active: true, sx: e.clientX, sy: e.clientY, cx: camRef.current.x, cy: camRef.current.y };
    }
    render();
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    const rect = canvasRef.current!.getBoundingClientRect();
    const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
    mouseWorldRef.current = screenToWorld(sx, sy);

    if (panRef.current.active) {
      camRef.current.x = panRef.current.cx + (e.clientX - panRef.current.sx);
      camRef.current.y = panRef.current.cy + (e.clientY - panRef.current.sy);
      render();
      return;
    }

    if (dragRef.current.active) {
      onMoveNode(dragRef.current.nodeId, mouseWorldRef.current.x - dragRef.current.ox, mouseWorldRef.current.y - dragRef.current.oy);
      render();
    }

    if (connectMode && connectRef.current) render();
  };

  const handleMouseUp = () => {
    dragRef.current.active = false;
    panRef.current.active = false;
  };

  const handleWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const rect = canvasRef.current!.getBoundingClientRect();
    const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
    const old = camRef.current.zoom;
    camRef.current.zoom *= e.deltaY < 0 ? 1.1 : 0.9;
    camRef.current.zoom = Math.max(0.2, Math.min(3, camRef.current.zoom));
    camRef.current.x = sx - (sx - camRef.current.x) * camRef.current.zoom / old;
    camRef.current.y = sy - (sy - camRef.current.y) * camRef.current.zoom / old;
    render();
  };

  return (
    <div className="canvas-area">
      <canvas
        ref={canvasRef}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
        onContextMenu={e => e.preventDefault()}
      />
      {connectMode && <div className="mode-banner active">连线模式 - 点击源节点，再点击目标节点 | ESC退出</div>}
      <div className="canvas-info">
        缩放: {(camRef.current.zoom * 100).toFixed(0)}% | 节点: {currentMap?.nodes.length || 0} | 连线: {currentMap?.connections.length || 0}
      </div>
    </div>
  );
}
