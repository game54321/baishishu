export interface CardRef {
  type: string;
  count: number;
  gongfaId?: string;
  gainExp?: number;
}

export interface NodeType {
  id: string;
  label: string;
  name: string;
  category: string;
  color: string;
  weight: number;
  minFloor: number;
  maxFloor: number;
  maxPerMap: number;
  requireCards: CardRef[];
  consumeCards: CardRef[];
  produceCards: CardRef[];
}

export interface CardType {
  id: string;
  name: string;
  desc: string;
  icon: string;
  color: string;
  category: string;
  stackable: boolean;
  maxValue: number;
}

export interface MapNode {
  id: string;
  typeId: string;
  floor: number;
  column: number;
  x: number;
  y: number;
  dojoName?: string;
  workName?: string;
  consumeCards?: CardRef[];
  produceCards?: CardRef[];
}

export interface Connection {
  from: string;
  to: string;
}

export interface MapData {
  id: string;
  name: string;
  numFloors: number;
  minNodesPerFloor: number;
  maxNodesPerFloor: number;
  maxBranches: number;
  nodes: MapNode[];
  connections: Connection[];
  createdAt: string;
  updatedAt: string;
}

export interface MapListItem {
  id: string;
  name: string;
  floors: number;
  updatedAt: string;
}

const isStatic = import.meta.env.PROD;
const base = import.meta.env.BASE_URL;

const STATIC_ROUTES: Record<string, string> = {
  'GET /node-types': 'data/node_types.json',
  'GET /card-types': 'data/card_types.json',
  'GET /chapters': 'data/chapters.json',
};

export const api = async (method: string, path: string, body?: any) => {
  if (isStatic) {
    const key = `${method} ${path}`;
    const file = STATIC_ROUTES[key];
    if (file) {
      const res = await fetch(base + file);
      return res.json();
    }
    return null;
  }
  const opts: RequestInit = { method, headers: { 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`/api${path}`, opts);
  return res.json();
};
