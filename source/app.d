import std.stdio;
import std.string;
import std.file;
import std.encoding;
import std.datetime;
import std.regex;
import std.algorithm;
import std.conv;

string t(T)(T input) {
  string output;
  transcode(input, output);
  return output;
}

class Line {
  string[] columns;
  this(string line) {
    columns = line.split("^");
  }
  string opIndex(size_t i) {
    auto beginTilde = regex("^~");
    auto endTilde = regex("~$");
    return columns[i].replaceFirst(beginTilde, "").replaceFirst(endTilde, "");
  }
}

class Nutrition {
  string id;
  string unit;
  string name;
  string description;
  this(Line line) {
    id = line[0];
    unit = line[1];
    name = line[2];
    description = line[3];
  }
  override string toString() {
    return format("Nutrition { id: %s, unit: %s, name: %s, description: %s }", id, unit, name, description);
  }
}

class NutritionDetail {
  Food food;
  Nutrition nutrition;
  string amount;
  string id;
  this(Line line, Food[string] foods, Nutrition[string] nutritions) {
    food = foods[line[0]];
    nutrition = nutritions[line[1]];
    amount = line[2];
    food[nutrition] = this;
  }
  override string toString() {
    return format("Nutrition '%s' in Food '%s': %s", nutrition.name, food.name, amount);
  }
}

class Food {
  string id;
  string name;
  NutritionDetail[Nutrition] nutritions;
  this(Line l) {
    id = l[0];
    name = l[2];
  }
  override string toString() {
    return format("Food { id: %s, name: %s }", id, name);
  }
  void opIndexAssign(NutritionDetail detail, Nutrition nutrition) {
    nutritions[nutrition] = detail;
  }
  NutritionDetail opIndex(Nutrition nutrition) {
    return nutritions[nutrition];
  }
}

auto latin1Lines(string fileName) {
  auto file = cast(Latin1String) read("lib/nutrition/density/usda/sr27asc/" ~ fileName);
  return t(file).splitLines().map!(a => new Line(a));
}

T[string] latin1Lines2Hash(T)(string fileName) {
  T[string] result;
  foreach (line; latin1Lines(fileName)) {
    T t = to!T(line);
    result[t.id] = t;
  }
  return result;
}

void main() {
  StopWatch sw;
  sw.start();
  alias toFood = to!Food;
  auto foods = latin1Lines2Hash!(Food)("FOOD_DES.txt");
  sw.stop();
  writeln("time for reading food: ", sw.peek().msecs, "ms");
  sw.start();
  auto nutritions = latin1Lines2Hash!(Nutrition)("NUTR_DEF.txt");
  sw.stop();
  writeln(nutritions);
  writeln("time for reading nutritions: ", sw.peek().msecs, "ms");
  sw.start();
  auto i = 0;
  foreach (line; latin1Lines("NUT_DATA.txt")) {
    new NutritionDetail(line, foods, nutritions);
    i++;
  }
  sw.stop();
  writeln("time for reading nutrition details: ", sw.peek().msecs, "ms");

  Food food_by_name(string name) {
    return find!("a.name == b")(foods.values, name)[0];
  }
  Nutrition nutrition_by_name(string name) {
    return find!("a.name == b")(nutritions.values, name)[0];
  }
  auto f = food_by_name("Kale, raw");
  auto n = nutrition_by_name("VITC");
  writeln(f, n, f[n]);
  
}
