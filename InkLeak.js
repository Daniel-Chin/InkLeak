import React, { useRef, useEffect, useCallback } from 'react';
import { noise } from './perlin';
import { VERDANA, CLOSE } from './verdana';

const WIGGLE_NOISE_UNCORRELATE = .3;
const WIGGLE_ROOM = .4;
const PADDING = 40;
const TOP_PAD = 15;
const BLINK_PHASE_DELTA = .02;
const MIN_BRUSH_DENSITY = 2;

const InkLeak = ({
  text, height, period, do_border, max_brush_density, 
  clear_density, fore_color, back_color, 
}) => {
  const canvas = useRef();
  noise.seed(Math.random());

  period = period || 2000;
  do_border = do_border || true;
  max_brush_density = max_brush_density || 3;
  clear_density = clear_density || .0018;
  fore_color = fore_color || '#000000';
  back_color = back_color || '#FFFFFF';

  const root = Root({ do_border });
  const width = vectorizeText(text, root, height / (100 + TOP_PAD));

  const draw = useCallback((ctx, t, dt) => {
    const phase = (t / period) % 1;

    ctx.strokeStyle = back_color;
    echoClear(ctx, width, height, clear_density * dt);
    ctx.strokeStyle = fore_color;
    drawRoot(root, ctx, phase, max_brush_density);
  }, [
    root, height, period, max_brush_density, 
    clear_density, back_color, fore_color, width, 
  ]);

  useEffect(() => {
    const current = canvas.current;
    if (! current) return;
    const context = current.getContext('2d');
    let animation_frame_id;
    let _t = 0;

    const loop = (t) => {
      const dt = Math.min(100, t - _t);
      _t = t;
      draw(context, t, dt);
      animation_frame_id = window.requestAnimationFrame(loop);
    };
    loop(_t);

    return () => {
      window.cancelAnimationFrame(animation_frame_id);
    };
  }, [draw]);

  return (
    <canvas 
      alt={text} ref={canvas} 
      width={width} height={height} 
    />
  );
};

const Node = (x_offset, scale, i, ax, ay, bx, by) => {
  const x = scale * ((ax + bx) / 2 + x_offset);
  const y = scale * ((ay + by) / 2 + TOP_PAD); 
  const dx = scale * (ax - bx);
  const dy = scale * (ay - by);
  const length = Math.sqrt(dx ** 2 + dy ** 2); 
  const angle = Math.atan(dy / dx);

  return {
    x, y, length, angle, 
    effective_x: x, 
    effective_y: y, 
    noise_phase: i * WIGGLE_NOISE_UNCORRELATE, 
    wiggle_size: length * WIGGLE_ROOM, 
    wiggle_speed: 2,
  };
};

const wiggle = (node) => {
  if (node.wiggle_speed && (node.wiggle_speed !== 0)) {
    node.noise_phase += node.wiggle_speed * 0.01;
    const offset = noise.perlin2(node.noise_phase, 0) * node.wiggle_size;
    node.effective_x = node.x + offset * Math.cos(node.angle);
    node.effective_y = node.y + offset * Math.sin(node.angle);
  }
};

const sample = (node) => {
  const beta = Math.random() * node.length - node.length * .5;
  return {
    x: node.effective_x + (beta * Math.cos(node.angle)), 
    y: node.effective_y + (beta * Math.sin(node.angle)), 
  };
}

const correlateNoise = (nodeA, nodeB) => {
  nodeB.noise_phase = nodeA.noise_phase;
};
const orientWith = (nodeA, nodeB) => {
  const perpendi = {
    x: nodeB.y - nodeA.y, 
    y: nodeA.x - nodeB.x, 
  }
  if (
    dotProduct(perpendi, unitVectorFromAngle(nodeA.angle))
    * dotProduct(perpendi, unitVectorFromAngle(nodeB.angle))
    < 0
  ) {
    nodeB.angle += Math.PI;
  }
};

const Edge = (root, nodeA, nodeB) => {
  root.edge_phase += BLINK_PHASE_DELTA;
  return {
    nodeA, nodeB, 
    phase: root.edge_phase, 
  };
};

const drawEdge = (root, ctx, phase, max_brush_density, edge) => {
  let [node_0, node_1] = [edge.nodeA, edge.nodeB];
  let point = sample(node_0);
  ctx.moveTo(point.x, point.y);
  const edge_times = MIN_BRUSH_DENSITY + Math.floor((1 - Math.max(
    1, ((1 + edge.phase - phase) % 1) * 2
  )) * max_brush_density);
  for (let _ = edge_times; _ > 0; _ --) {
    [node_0, node_1] = [node_1, node_0];
    point = sample(node_0);
    ctx.lineTo(point.x, point.y);
  }

  if (root.do_border) {
    const hori_a = edge.nodeA.length * Math.cos(edge.nodeA.angle) / 2;
    const vert_a = edge.nodeA.length * Math.sin(edge.nodeA.angle) / 2;
    const hori_b = edge.nodeB.length * Math.cos(edge.nodeB.angle) / 2;
    const vert_b = edge.nodeB.length * Math.sin(edge.nodeB.angle) / 2;
    ctx.moveTo(
      edge.nodeA.effective_x - hori_a, edge.nodeA.effective_y - vert_a, 
    );
    ctx.lineTo(
      edge.nodeB.effective_x - hori_b, edge.nodeB.effective_y - vert_b, 
    );
    ctx.moveTo(
      edge.nodeA.effective_x + hori_a, edge.nodeA.effective_y + vert_a, 
    );
    ctx.lineTo(
      edge.nodeB.effective_x + hori_b, edge.nodeB.effective_y + vert_b,
    );
  }
};

const Root = (options) => ({
  nodes: [], 
  edges: [],
  lastNode: null, 
  edge_phase: 0, 
  ...options, 
});

const link = (root, a, b) => {
  const edge = Edge(root, a, b);
  root.edges.push(edge);
  return edge;
};

const brushTo = (root, node, do_correlate_noise) => {
  if (do_correlate_noise) {
    correlateNoise(root.lastNode, node);
  }
  orientWith(root.lastNode, node);
  root.nodes.push(node);
  link(root, root.lastNode, node);
  root.lastNode = node;
  return node;
};
const moveTo = (root, node) => {
  root.nodes.push(node);
  root.lastNode = node;
  return node;
};

const drawRoot = (root, ctx, phase, max_brush_density) => {
  ctx.beginPath();
  root.nodes.forEach(wiggle);
  root.edges.forEach(drawEdge.bind(null, root, ctx, phase, max_brush_density));
  ctx.stroke();
};

const echoClear = (ctx, width, height, density) => {
  ctx.beginPath();
  ctx.moveTo(0, 0);
  const times = Math.floor(density * height);
  let _width = 0;
  for (let _ = 0; _ < times; _ ++) {
    _width = width - _width;
    ctx.lineTo(_width, Math.random() * height);
  }
  ctx.stroke();
};

const unitVectorFromAngle = (angle) => (
  {
    x: Math.cos(angle), 
    y: Math.sin(angle), 
  }
);
const dotProduct = (a, b) => (
  a.x * b.x + a.y * b.y
);

let all_letters = 'qwertyuiopasdfghjklzxcvbnm ';
all_letters += all_letters.toUpperCase();
const vectorizeText = (text, root, scale) => {
  let x_offset = PADDING;
  let node_i = 0;
  for (const c of text) {
    if (! all_letters.includes(c)) continue;
    const letter = [...VERDANA[c]];
    const char_width = letter.shift();
    for (const _stroke of letter) {
      const stroke = [..._stroke];
      const do_close = stroke.shift() === CLOSE;
      const firstNode = Node(x_offset, scale, node_i++, ...stroke.shift());
      moveTo(root, firstNode);
      for (const node_coords of stroke) {
        brushTo(root, Node(x_offset, scale, node_i++, ...node_coords));
      }
      if (do_close) {
        link(root, root.lastNode, firstNode);
      }
    }
    x_offset += char_width;
  }
  return (x_offset + PADDING) * scale;
};

export default InkLeak;
