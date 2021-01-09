static final String TARGET = "verdana.png";
static final String sequence = "DCPBNQqwertyuiopasdfghjklzxcvbnmWERTYUIOASFGHJKLZXVM_";

PImage img;
float zoom;
ArrayList<Command> commands;
int len_commands = 0;

float _width = -1f;
PVector edgeStart = null;

class Command {
  char type;
  PVector a;
  PVector b;
  float _width;
}

class Edge {
  PVector a;
  PVector b;

  Edge(Command c) {
    a = c.a;
    b = c.b;
  }
}

class Stroke {
  boolean do_close = false;
  ArrayList<Edge> edges;

  Stroke() {
    edges = new ArrayList<Edge>();
  }
}

class Letter {
  char name;
  ArrayList<Stroke> strokes;
  float _width;

  Letter(char x) {
    name = x;
    strokes = new ArrayList<Stroke>();
  }
}

void setup() {
  size(830, 830);
  zoom = width / 100f;
  img = loadImage(TARGET);
  commands = new ArrayList<Command>();
}

void draw() {
  ArrayList<Letter> letters = compile();
  pushMatrix();
  scale(zoom);

  {
    float acc_x = 0;
    for (Letter l : letters) {
      acc_x += l._width;
    }
    image(img, - acc_x, 0);
  }

  stroke(#FF00FF);
  strokeWeight(.4);
  fill(0, 255, 0, 128);
  Letter l = letters.get(letters.size() - 1);
  for (Stroke s : l.strokes) {
    beginShape(QUAD_STRIP);
    boolean first_edge = true;
    for (Edge e : s.edges) {
      vertex(e.a.x, e.a.y);
      vertex(e.b.x, e.b.y);
      if (first_edge) {
        first_edge = false;
        line(e.a.x, e.a.y, e.b.x, e.b.y);
      }
    }
    if (s.do_close) {
      Edge e = s.edges.get(0);
      vertex(e.a.x, e.a.y);
      vertex(e.b.x, e.b.y);
    }
      endShape();
  }

  stroke(#0000FF);
  line(_width, 0, _width, 100);

  stroke(#0000FF);
  fill(255, 0, 0, 128);
  if (edgeStart != null) {
    rect(edgeStart.x, edgeStart.y, 5, 5);
  }
  popMatrix();
}

ArrayList<Letter> compile() {
  ArrayList<Letter> letters = new ArrayList<Letter>();
  Letter nowLetter = new Letter(sequence.charAt(0));
  letters.add(nowLetter);
  Stroke nowStroke = new Stroke();
  nowLetter.strokes.add(nowStroke);
  for (Command c : commands) {
    switch (c.type) {
      case 'e':
        nowStroke.edges.add(new Edge(c));
        break;
      case 'c':
        nowStroke.do_close = true;
        nowStroke = new Stroke();
        nowLetter.strokes.add(nowStroke);
        break;
      case 's':
        nowStroke = new Stroke();
        nowLetter.strokes.add(nowStroke);
        break;
      case 'w':
        nowLetter._width = c._width;
        nowLetter = new Letter(sequence.charAt(letters.size()));
        letters.add(nowLetter);
        nowStroke = new Stroke();
        nowLetter.strokes.add(nowStroke);
        break;
    }
  }
  return letters;
}

void mouseClicked() {
  println("click");
  if (mouseButton == LEFT) {
    PVector clickPos = new PVector(mouseX / zoom, mouseY / zoom);
    if (edgeStart == null) {
      edgeStart = clickPos;
    } else {
      Command c = new Command();
      c.type = 'e';
      c.a = edgeStart;
      c.b = clickPos;
      edgeStart = null;
      commands.add(c);
    }
  } else {
    if (edgeStart == null) {
      commands.remove(commands.size() - 1);
    } else {
      edgeStart = null;
    }
  }
}

void keyPressed() {
  if (key == 'w') {
    _width = mouseX / zoom;
  }
  if (key == 'W' && _width > 0) {
    Command c = new Command();
    c.type = 'w';
    c._width = _width;
    commands.add(c);
  }
  if (key == 'c') {
    Command c = new Command();
    c.type = 'c';
    commands.add(c);
  }
  if (key == 's') {
    Command c = new Command();
    c.type = 's';
    commands.add(c);
  }
  if (key == 'o') {
    output();
  }
}

void output() {
  PrintWriter w;
  w = createWriter("trace_result.js"); 
  ArrayList<Letter> letters = compile();
  w.println("const this_font = { ");
  for (Letter l : letters) {
    w.println(l.name + ": [");
    for (Stroke s : l.strokes) {
      if (s.edges.size() == 0) {
        continue;
      }
      w.println("[");
      if (s.do_close) {
        w.println("CLOSE, ");
      } else {
        w.println("OPEN, ");
      }
      for (Edge e : s.edges) {
        w.println(String.format(
          "[ %4.1f, %4.1f, %4.1f, %4.1f ],", 
          e.a.x, e.a.y, 
          e.b.x, e.b.y
        ));
      }
      w.println("], ");
    }
    w.println("], ");
  }
  w.println("};");
  w.flush();
  w.close();
  println("File saved successfully. ");
}
