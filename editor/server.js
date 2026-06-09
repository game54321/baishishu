const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const multer = require('multer');

const app = express();
const PORT = 3001;

const DATA_DIR = path.join(__dirname, 'data');
const NODE_TYPES_FILE = path.join(DATA_DIR, 'node_types.json');
const CARD_TYPES_FILE = path.join(DATA_DIR, 'card_types.json');
const MAPS_DIR = path.join(DATA_DIR, 'maps');
const CHAPTERS_FILE = path.join(DATA_DIR, 'chapters.json');
const GAME_DATA_DIR = path.join(__dirname, '..', 'data');
const GAME_MAPS_DIR = path.join(GAME_DATA_DIR, 'maps');
const GAME_CHAPTERS_FILE = path.join(GAME_DATA_DIR, 'chapters.json');

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(MAPS_DIR)) fs.mkdirSync(MAPS_DIR, { recursive: true });

function initDefaultNodeTypes() {
  if (!fs.existsSync(NODE_TYPES_FILE)) {
    const defaults = [
      { id: 'combat', label: '战', name: '战斗', category: 'combat', color: '#D9A65A', weight: 0.35, minFloor: 0, maxFloor: -1, maxPerMap: -1, requireCards: [{type:'寿元',count:1}], consumeCards: [{type:'寿元',count:1}], produceCards: [] },
      { id: 'elite', label: '精', name: '精英', category: 'combat', color: '#E64040', weight: 0.08, minFloor: 2, maxFloor: -1, maxPerMap: 5, requireCards: [{type:'寿元',count:1}], consumeCards: [{type:'寿元',count:2}], produceCards: [{type:'银两',count:10}] },
      { id: 'rest', label: '休', name: '休息', category: 'rest', color: '#4DBF66', weight: 0.08, minFloor: 0, maxFloor: -1, maxPerMap: -1, requireCards: [], consumeCards: [], produceCards: [{type:'寿元',count:20}] },
      { id: 'shop', label: '店', name: '商店', category: 'shop', color: '#4D8CE6', weight: 0.06, minFloor: 1, maxFloor: -1, maxPerMap: 3, requireCards: [{type:'银两',count:5}], consumeCards: [{type:'银两',count:5}], produceCards: [] },
      { id: 'event', label: '?', name: '事件', category: 'story', color: '#B366D9', weight: 0.08, minFloor: 0, maxFloor: -1, maxPerMap: -1, requireCards: [], consumeCards: [], produceCards: [] },
      { id: 'boss', label: 'B', name: 'Boss', category: 'combat', color: '#D9268C', weight: 0, minFloor: -1, maxFloor: -1, maxPerMap: 1, requireCards: [{type:'寿元',count:1}], consumeCards: [{type:'寿元',count:3}], produceCards: [{type:'银两',count:50}] },
      { id: 'start', label: '起', name: '起点', category: 'start', color: '#999999', weight: 0, minFloor: -1, maxFloor: -1, maxPerMap: 1, requireCards: [], consumeCards: [], produceCards: [{type:'寿元',count:60},{type:'银两',count:10}] },
      { id: 'dojo', label: '武', name: '武馆学武', category: 'story', color: '#D97333', weight: 0.08, minFloor: 1, maxFloor: -1, maxPerMap: 3, requireCards: [{type:'银两',count:5}], consumeCards: [{type:'银两',count:5},{type:'寿元',count:1}], produceCards: [{type:'功法',count:1}] },
      { id: 'tavern', label: '酒', name: '酒馆打工', category: 'story', color: '#996633', weight: 0.08, minFloor: 1, maxFloor: -1, maxPerMap: 3, requireCards: [{type:'寿元',count:1}], consumeCards: [{type:'寿元',count:1}], produceCards: [{type:'银两',count:8}] },
      { id: 'temple', label: '禅', name: '古刹参禅', category: 'story', color: '#8C8CD9', weight: 0.06, minFloor: 3, maxFloor: -1, maxPerMap: 2, requireCards: [{type:'寿元',count:2}], consumeCards: [{type:'寿元',count:2}], produceCards: [{type:'寿元',count:30}] },
      { id: 'blacksmith', label: '铁', name: '铁匠铺', category: 'shop', color: '#B3804D', weight: 0.05, minFloor: 2, maxFloor: -1, maxPerMap: 2, requireCards: [{type:'银两',count:15}], consumeCards: [{type:'银两',count:15}], produceCards: [{type:'功法',count:1}] },
      { id: 'hermit', label: '隐', name: '隐士指点', category: 'story', color: '#66CCB2', weight: 0.04, minFloor: 4, maxFloor: -1, maxPerMap: 2, requireCards: [{type:'寿元',count:3}], consumeCards: [{type:'寿元',count:3}], produceCards: [{type:'功法',count:2}] },
    ];
    fs.writeFileSync(NODE_TYPES_FILE, JSON.stringify(defaults, null, 2), 'utf-8');
  }
}

function initDefaultCardTypes() {
  if (!fs.existsSync(CARD_TYPES_FILE)) {
    const defaults = [
      { id: '寿元', name: '寿元', desc: '一年寿命', icon: '⏳', color: '#E8C872', category: 'life', stackable: true, maxValue: 999999999, unit: '一年时间' },
      { id: '银两', name: '银两', desc: '通用货币', icon: '🪙', color: '#C0C0C0', category: 'currency', stackable: true, maxValue: 9999, unit: '两' },
      { id: '功法', name: '功法', desc: '武学功法', icon: '👊', color: '#D97333', category: 'gongfa', stackable: false, maxValue: 1 },
      { id: '武道', name: '武道境界', desc: '武道修行境界', icon: '🌀', color: '#CC9933', category: 'wudao', stackable: false, maxValue: 1 },
    ];
    fs.writeFileSync(CARD_TYPES_FILE, JSON.stringify(defaults, null, 2), 'utf-8');
  }
}

function readJSON(filepath) {
  try { return JSON.parse(fs.readFileSync(filepath, 'utf-8')); }
  catch { return null; }
}

function writeJSON(filepath, data) {
  fs.writeFileSync(filepath, JSON.stringify(data, null, 2), 'utf-8');
}

app.use(cors());
app.use(express.json());
app.use('/game_assets', express.static(path.join(__dirname, '..', 'assets')));

// ==================== 卡牌类型 API ====================
app.get('/api/card-types', (req, res) => {
  res.json(readJSON(CARD_TYPES_FILE) || []);
});

app.post('/api/card-types', (req, res) => {
  const types = readJSON(CARD_TYPES_FILE) || [];
  const t = { id: req.body.id || uuidv4().slice(0, 8), name: req.body.name || '未命名', desc: req.body.desc || '', icon: req.body.icon || '🃏', color: req.body.color || '#999999', category: req.body.category || 'item', stackable: req.body.stackable !== false, maxValue: req.body.maxValue ?? 999 };
  if (types.find(x => x.id === t.id)) return res.status(400).json({ error: 'ID已存在' });
  types.push(t);
  writeJSON(CARD_TYPES_FILE, types);
  res.json(t);
});

app.put('/api/card-types/:id', (req, res) => {
  const types = readJSON(CARD_TYPES_FILE) || [];
  const idx = types.findIndex(t => t.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: '未找到' });
  types[idx] = { ...types[idx], ...req.body, id: types[idx].id };
  writeJSON(CARD_TYPES_FILE, types);
  res.json(types[idx]);
});

app.delete('/api/card-types/:id', (req, res) => {
  let types = readJSON(CARD_TYPES_FILE) || [];
  const len = types.length;
  types = types.filter(t => t.id !== req.params.id);
  if (types.length === len) return res.status(404).json({ error: '未找到' });
  writeJSON(CARD_TYPES_FILE, types);
  res.json({ success: true });
});

// ==================== 功法 API ====================
function readGongfaList() {
  const types = readJSON(CARD_TYPES_FILE) || [];
  const gongfaCard = types.find(t => t.category === 'gongfa');
  return { types, gongfaCard, list: gongfaCard?.gongfaList || [] };
}

function saveGongfaList(types) {
  writeJSON(CARD_TYPES_FILE, types);
  const gameCardFile = path.join(GAME_DATA_DIR, 'card_types.json');
  writeJSON(gameCardFile, types);
}

app.get('/api/gongfa', (req, res) => {
  res.json(readGongfaList().list);
});

app.post('/api/gongfa', (req, res) => {
  const { types, list } = readGongfaList();
  const g = {
    id: req.body.id || uuidv4().slice(0, 8),
    name: req.body.name || '未命名',
    icon_path: req.body.icon_path || '',
    hit_effect_path: req.body.hit_effect_path || '',
    desc: req.body.desc || '',
    baseDamage: req.body.baseDamage ?? 10,
    gainExp: req.body.gainExp ?? 30,
    color: req.body.color || '#D97333',
  };
  if (list.find(x => x.id === g.id)) return res.status(400).json({ error: 'ID已存在' });
  list.push(g);
  const gongfaCard = types.find(t => t.category === 'gongfa');
  if (gongfaCard) gongfaCard.gongfaList = list;
  saveGongfaList(types);
  res.json(g);
});

app.put('/api/gongfa/:id', (req, res) => {
  const { types, list } = readGongfaList();
  const idx = list.findIndex(g => g.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: '未找到' });
  list[idx] = { ...list[idx], ...req.body, id: list[idx].id };
  const gongfaCard = types.find(t => t.category === 'gongfa');
  if (gongfaCard) gongfaCard.gongfaList = list;
  saveGongfaList(types);
  res.json(list[idx]);
});

app.delete('/api/gongfa/:id', (req, res) => {
  const { types, list } = readGongfaList();
  const len = list.length;
  const filtered = list.filter(g => g.id !== req.params.id);
  if (filtered.length === len) return res.status(404).json({ error: '未找到' });
  const gongfaCard = types.find(t => t.category === 'gongfa');
  if (gongfaCard) gongfaCard.gongfaList = filtered;
  saveGongfaList(types);
  res.json({ success: true });
});

app.get('/api/gongfa/images', (req, res) => {
  const imgDir = path.join(__dirname, '..', 'assets', '功法插图');
  if (!fs.existsSync(imgDir)) return res.json([]);
  const files = fs.readdirSync(imgDir).filter(f => /\.(png|jpg|jpeg|webp)$/i.test(f));
  res.json(files.map(f => `res://assets/功法插图/${f}`));
});

const gongfaImgDir = path.join(__dirname, '..', 'assets', '功法插图');
if (!fs.existsSync(gongfaImgDir)) fs.mkdirSync(gongfaImgDir, { recursive: true });
const upload = multer({
  storage: multer.diskStorage({
    destination: gongfaImgDir,
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname) || '.png';
      cb(null, `${uuidv4().slice(0, 8)}${ext}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (/\.(png|jpg|jpeg|webp)$/i.test(path.extname(file.originalname))) cb(null, true);
    else cb(new Error('仅支持 png/jpg/webp 格式'));
  },
});

app.post('/api/gongfa/upload', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: '未上传文件' });
  const iconPath = `res://assets/功法插图/${req.file.filename}`;
  res.json({ icon_path: iconPath });
});

app.post('/api/gongfa/cleanup-unused', (req, res) => {
  const imgDir = path.join(__dirname, '..', 'assets', '功法插图');
  if (!fs.existsSync(imgDir)) return res.json({ deleted: 0, files: [] });

  // 收集所有在用的插图路径
  const usedFiles = new Set();
  const types = readJSON(CARD_TYPES_FILE) || [];
  for (const t of types) {
    if (t.category === 'gongfa' && t.gongfaList) {
      for (const g of t.gongfaList) {
        if (g.icon_path) usedFiles.add(path.basename(g.icon_path));
        if (g.hit_effect_path) usedFiles.add(path.basename(g.hit_effect_path));
      }
    }
  }

  // 扫描目录，删除未使用的
  const allFiles = fs.readdirSync(imgDir).filter(f => /\.(png|jpg|jpeg|webp)$/i.test(f));
  const deleted = [];
  for (const f of allFiles) {
    if (!usedFiles.has(f)) {
      const fp = path.join(imgDir, f);
      fs.unlinkSync(fp);
      // 同时删 .import
      const importFp = fp + '.import';
      if (fs.existsSync(importFp)) fs.unlinkSync(importFp);
      deleted.push(f);
    }
  }

  res.json({ deleted: deleted.length, files: deleted });
});

// ==================== 节点类型 API ====================
app.get('/api/node-types', (req, res) => {
  res.json(readJSON(NODE_TYPES_FILE) || []);
});

app.post('/api/node-types', (req, res) => {
  const types = readJSON(NODE_TYPES_FILE) || [];
  const t = { id: req.body.id || uuidv4().slice(0, 8), label: req.body.label || '?', name: req.body.name || '未命名', category: req.body.category || 'story', color: req.body.color || '#999999', weight: req.body.weight ?? 0.05, minFloor: req.body.minFloor ?? 0, maxFloor: req.body.maxFloor ?? -1, maxPerMap: req.body.maxPerMap ?? -1 };
  if (types.find(x => x.id === t.id)) return res.status(400).json({ error: 'ID已存在' });
  types.push(t);
  writeJSON(NODE_TYPES_FILE, types);
  res.json(t);
});

app.put('/api/node-types/:id', (req, res) => {
  const types = readJSON(NODE_TYPES_FILE) || [];
  const idx = types.findIndex(t => t.id === req.params.id);
  if (idx === -1) return res.status(404).json({ error: '未找到' });
  types[idx] = { ...types[idx], ...req.body, id: types[idx].id };
  writeJSON(NODE_TYPES_FILE, types);
  res.json(types[idx]);
});

app.delete('/api/node-types/:id', (req, res) => {
  let types = readJSON(NODE_TYPES_FILE) || [];
  const len = types.length;
  types = types.filter(t => t.id !== req.params.id);
  if (types.length === len) return res.status(404).json({ error: '未找到' });
  writeJSON(NODE_TYPES_FILE, types);
  res.json({ success: true });
});

// ==================== 地图 API ====================
app.get('/api/maps', (req, res) => {
  if (!fs.existsSync(MAPS_DIR)) return res.json([]);
  const files = fs.readdirSync(MAPS_DIR).filter(f => f.endsWith('.json'));
  const maps = files.map(f => { const d = readJSON(path.join(MAPS_DIR, f)); return { id: f.replace('.json', ''), name: d?.name || f, floors: d?.nodes?.length || 0, updatedAt: d?.updatedAt || '' }; });
  res.json(maps);
});

app.get('/api/maps/:id', (req, res) => {
  const d = readJSON(path.join(MAPS_DIR, `${req.params.id}.json`));
  if (!d) return res.status(404).json({ error: '未找到' });
  res.json(d);
});

app.post('/api/maps', (req, res) => {
  const id = uuidv4().slice(0, 8);
  const m = { id, name: req.body.name || '新地图', numFloors: req.body.numFloors || 15, minNodesPerFloor: req.body.minNodesPerFloor || 3, maxNodesPerFloor: req.body.maxNodesPerFloor || 5, maxBranches: req.body.maxBranches || 3, nodes: [], connections: [], createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
  writeJSON(path.join(MAPS_DIR, `${id}.json`), m);
  res.json(m);
});

app.put('/api/maps/:id', (req, res) => {
  const fp = path.join(MAPS_DIR, `${req.params.id}.json`);
  const existing = readJSON(fp);
  if (!existing) return res.status(404).json({ error: '未找到' });
  const updated = { ...existing, ...req.body, id: existing.id, updatedAt: new Date().toISOString() };
  writeJSON(fp, updated);
  // 自动导出Godot格式
  _exportGodot(req.params.id);
  res.json(updated);
});

app.delete('/api/maps/:id', (req, res) => {
  const fp = path.join(MAPS_DIR, `${req.params.id}.json`);
  if (!fs.existsSync(fp)) return res.status(404).json({ error: '未找到' });
  fs.unlinkSync(fp);
  res.json({ success: true });
});

// 自动生成
app.post('/api/maps/:id/generate', (req, res) => {
  const fp = path.join(MAPS_DIR, `${req.params.id}.json`);
  const mapData = readJSON(fp);
  if (!mapData) return res.status(404).json({ error: '未找到' });
  const nodeTypes = readJSON(NODE_TYPES_FILE) || [];
  const { numFloors, minNodesPerFloor, maxNodesPerFloor, maxBranches } = mapData;
  const nodes = [];
  const connections = [];

  const startType = nodeTypes.find(t => t.id === 'start') || { id: 'start', label: '起', color: '#999' };
  const startNode = { id: 'start_0', typeId: startType.id, floor: 0, column: 0, x: 0, y: 0 };
  nodes.push(startNode);

  for (let f = 1; f < numFloors - 1; f++) {
    const count = minNodesPerFloor + Math.floor(Math.random() * (maxNodesPerFloor - minNodesPerFloor + 1));
    for (let i = 0; i < count; i++) {
      const eligible = nodeTypes.filter(t => t.weight > 0 && t.minFloor <= f && (t.maxFloor === -1 || t.maxFloor >= f));
      const totalW = eligible.reduce((s, t) => s + t.weight, 0);
      let roll = Math.random() * totalW;
      let type = eligible[0] || { id: 'event', label: '?', color: '#B366D9' };
      for (const t of eligible) { roll -= t.weight; if (roll <= 0) { type = t; break; } }
      nodes.push({ id: `floor_${f}_node_${i}`, typeId: type.id, floor: f, column: i, x: 0, y: 0 });
    }
  }

  const bossType = nodeTypes.find(t => t.id === 'boss') || { id: 'boss', label: 'B', color: '#D9268C' };
  const bossNode = { id: 'boss_0', typeId: bossType.id, floor: numFloors - 1, column: 0, x: 0, y: 0 };
  nodes.push(bossNode);

  const floor1 = nodes.filter(n => n.floor === 1);
  const sb = Math.min(2 + Math.floor(Math.random() * 2), floor1.length);
  [...floor1].sort(() => Math.random() - 0.5).slice(0, sb).forEach(t => connections.push({ from: startNode.id, to: t.id }));

  for (let f = 1; f < numFloors - 2; f++) {
    const cur = nodes.filter(n => n.floor === f);
    const nxt = nodes.filter(n => n.floor === f + 1);
    cur.forEach(node => {
      const nearby = [...nxt].sort((a, b) => Math.abs(a.column - node.column) - Math.abs(b.column - node.column));
      const cnt = 1 + Math.floor(Math.random() * Math.min(maxBranches, nearby.length));
      nearby.slice(0, cnt).forEach(t => { if (!connections.find(c => c.from === node.id && c.to === t.id)) connections.push({ from: node.id, to: t.id }); });
    });
    nxt.forEach(node => {
      if (!connections.find(c => c.to === node.id)) {
        const closest = [...cur].sort((a, b) => Math.abs(a.column - node.column) - Math.abs(b.column - node.column))[0];
        connections.push({ from: closest.id, to: node.id });
      }
    });
  }

  nodes.filter(n => n.floor === numFloors - 2).forEach(n => {
    if (!connections.find(c => c.from === n.id && c.to === bossNode.id)) connections.push({ from: n.id, to: bossNode.id });
  });

  const ns = 120, fs = 100, mx = 80, mb = 60;
  const floorCounts = {};
  nodes.filter(n => n.floor > 0 && n.floor < numFloors - 1).forEach(n => { floorCounts[n.floor] = (floorCounts[n.floor] || 0) + 1; });
  const maxC = Math.max(...Object.values(floorCounts).map(Number)) || 5;
  const tw = maxC * ns + mx * 2;
  const th = numFloors * fs + mb;
  nodes.forEach(node => {
    const fn = nodes.filter(n => n.floor === node.floor);
    const c = fn.length;
    const fw = (c - 1) * ns;
    const sx = (tw - fw) / 2;
    node.x = sx + node.column * ns;
    node.y = th - mb - node.floor * fs;
  });

  mapData.nodes = nodes;
  mapData.connections = connections;
  mapData.updatedAt = new Date().toISOString();
  writeJSON(fp, mapData);
  res.json(mapData);
});

// ==================== 章节 API ====================
app.get('/api/chapters', (req, res) => {
  // 优先读editor数据，不存在则从游戏数据复制
  if (!fs.existsSync(CHAPTERS_FILE) && fs.existsSync(GAME_CHAPTERS_FILE)) {
    const data = readJSON(GAME_CHAPTERS_FILE);
    if (data) writeJSON(CHAPTERS_FILE, data);
  }
  res.json(readJSON(CHAPTERS_FILE) || []);
});

app.put('/api/chapters', (req, res) => {
  const chapters = req.body;
  writeJSON(CHAPTERS_FILE, chapters);
  // 同步到游戏数据目录
  writeJSON(GAME_CHAPTERS_FILE, chapters);
  res.json({ success: true });
});

// ==================== 导出 Godot（从章节数据生成godot格式地图，存入章节map字段） ====================
function _exportGodot(mapId) {
  const mapData = readJSON(path.join(MAPS_DIR, `${mapId}.json`));
  if (!mapData) return null;
  const nodeTypes = readJSON(NODE_TYPES_FILE) || [];
  const godotData = { floors: [], all_nodes: {}, start_id: '', boss_id: '' };
  const fm = {};
  mapData.nodes.forEach(n => { if (!fm[n.floor]) fm[n.floor] = []; fm[n.floor].push(n); });
  Object.keys(fm).sort((a, b) => Number(a) - Number(b)).forEach(fi => {
    const fl = fm[fi].map((n, i) => {
      const nd = { id: n.id, type_id: n.typeId, floor_index: n.floor, column_index: i, connections: mapData.connections.filter(c => c.from === n.id).map(c => c.to), position: { x: n.x, y: n.y } };
      if (n.dojoName) nd.dojo_name = n.dojoName;
      if (n.workName) nd.work_name = n.workName;
      if (n.consumeCards && n.consumeCards.length > 0) nd.consume_cards = n.consumeCards;
      if (n.produceCards && n.produceCards.length > 0) nd.produce_cards = n.produceCards;
      godotData.all_nodes[n.id] = nd;
      if (n.typeId === 'start') godotData.start_id = n.id;
      if (n.typeId === 'boss') godotData.boss_id = n.id;
      return nd;
    });
    godotData.floors.push(fl);
  });
  const exportDir = path.join(__dirname, '..', 'data', 'maps');
  if (!fs.existsSync(exportDir)) fs.mkdirSync(exportDir, { recursive: true });
  const mapName = mapData.name || mapId;
  const ep = path.join(exportDir, `${mapName}_godot.json`);
  writeJSON(ep, godotData);
  return { path: ep, data: godotData };
}

app.post('/api/export/godot', (req, res) => {
  const result = _exportGodot(req.body.mapId);
  if (!result) return res.status(404).json({ error: '未找到' });
  res.json(result);
});

initDefaultNodeTypes();
initDefaultCardTypes();
app.listen(PORT, () => console.log(`中台已启动: http://localhost:${PORT}`));
