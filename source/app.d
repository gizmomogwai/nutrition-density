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
  auto beginTilde = regex("^~");
  auto endTilde = regex("~$");
  this(string line) {
    columns = line.split("^");
  }
  string opIndex(size_t i) {
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
  foreach (line; latin1Lines("NUT_DATA.txt")) {
    new NutritionDetail(line, foods, nutritions);
  }
  sw.stop();
  writeln("time for reading nutrition details: ", sw.peek().msecs, "ms");

  T byName(T)(T[string] from, string name) {
    return find!("a.name == b")(from.values, name)[0];
  }

  Food food_by_name(string name) {
    return byName(foods, name);
  }

  Nutrition nutrition_by_name(string name) {
    return byName(nutritions, name);
  }

  auto interestingFoods = [
                           "Kale, raw",
                           "Kale, cooked, boiled, drained, without salt",
                           "Collards, raw",
                           "Mustard greens, raw",
                           "Watercress, raw",
                           "Chard, swiss, raw",
                           "Cabbage, chinese (pak-choi), raw",
                           "Oranges, raw, all commercial varieties",
                           "Orange juice, raw",
                           "Lemons, raw, without peel",
                           "Mollusks, mussel, blue, raw",
                           "Oil, olive, salad or cooking",
                           "Arugula, raw",
                           "Onions, raw",
                           "Spinach, raw",
                           "Spinach, cooked, boiled, drained, without salt",
                           "Tofu, raw, firm, prepared with calcium sulfate",
                           "Beef, tenderloin, steak, separable lean and fat, trimmed to 1/8\" fat, all grades, raw",
                           "Blueberries, raw",
                           "Blueberries, wild, frozen",
                           "Blueberries, frozen, unsweetened",
                           "SILK Blueberry soy yogurt",
                           "Stinging Nettles, blanched (Northern Plains Indians)"
                           ].map!(a => food_by_name(a));
  foreach (food; interestingFoods) {
    writeln(food);
  }
  auto f = food_by_name("Kale, raw");
  auto n = nutrition_by_name("VITC");
  writeln(f, n, f[n]);
}
