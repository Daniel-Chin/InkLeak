static final String TARGET = "verdana.png";
static final String sequence = "DCPBNQqwertyuiopasdfghjklzxcvbnmWERTYUIOASFGHJKLZXVM";

PImage img;
float zoom;
int seq_i = 0;
Letter nowLetter;
Edge nowEdge;
int acc_x = 0;
boolean start_new_edge = true;

class Edge {
  boolean is_close = false;
  PVector a;
  PVector b;
}

class Stroke {
  ArrayList<Edge> edges;

  Stroke() {
    edges = new ArrayList<Edge>();
  }
}

class Letter {
  char name;
  ArrayList<Stroke> strokes;
  float _width = -1f;

  Letter(char x) {
    name = x;
    strokes = new ArrayList<Stroke>();
  }
}

ArrayList<Letter> letters;

void setup() {
  size(830, 830);
  zoom = width / 100f;
  img = loadImage(TARGET);
  letters = new ArrayList<Letter>();
  nowLetter = new Letter(sequence.charAt(0));
  letters.add(nowLetter);

  fill(#0000FF);
}

void draw() {
  pushMatrix();
  scale(zoom);
  stroke(#FF0000);
  strokeWeight(.4);
  image(img, - acc_x, 0);
  if (nowEdge != null) {
    for (Edge edge : nowLetter.edges) {
      if (! edge.is_close) {
        if (edge == nowEdge && ! start_new_edge) {
          rect(edge.a.x, edge.a.y, 5, 5);
        } else {
          line(edge.a.x, edge.a.y, edge.b.x, edge.b.y);
        }
      }
    }
    if (nowLetter._width > 0) {
      stroke(#00FF00);
      line(nowLetter._width, 0, nowLetter._width, 100);
    }
  }
  popMatrix();
}

void mouseClicked() {
  if (mouseButton == LEFT) {
    PVector clickPos = new PVector(mouseX / zoom, mouseY / zoom);
    if (start_new_edge) {
      Edge edge = new Edge();
      nowLetter.edges.add(edge);
      edge.a = clickPos;
      nowEdge = edge;
    } else {
      nowEdge.b = clickPos;
    }
    start_new_edge = ! start_new_edge;
  } else {
    if (start_new_edge) {
      if (nowEdge != null) {
        nowEdge.b = null;
      } else {
        if (letters.size() >= 2) {
          letters.remove(nowLetter);
          nowLetter = letters.get(letters.size() - 1);
          nowEdge = nowLetter.edges.get(nowLetter.edges.size() - 1);
          acc_x -= nowLetter._width;
          seq_i --;
          start_new_edge = ! start_new_edge;  // for later to reverse
        }
      }
    } else {
      nowLetter.edges.remove(nowEdge);
      if (nowLetter.edges.size() == 0) {
        nowEdge = null;
      } else {
        nowEdge = nowLetter.edges.get(nowLetter.edges.size() - 1);
      }
    }
    start_new_edge = ! start_new_edge;
  }
}

void keyPressed() {
  if (key == 'w') {
    nowLetter._width = mouseX / zoom;
  }
  if (key == 'W' && nowLetter._width > 0 && start_new_edge) {
    acc_x += nowLetter._width;
    nowEdge = null;
    seq_i ++;
    nowLetter = new Letter(sequence.charAt(seq_i));
    letters.add(nowLetter);
  }
  if (key == 'c') {
    Edge edge = new Edge();
    nowLetter.edges.add(edge);
    edge.is_close = true;
    nowEdge = edge;
  }
  if (key == 's') {
  }
}
