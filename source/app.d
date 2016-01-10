import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.encoding;
import std.file;
import std.math;
import std.regex;
import std.stdio;
import std.string;
import vibe.core.file;
import vibe.core.stream;
import vibe.templ.diet;

string t(T)(T input) {
  string output;
  transcode(input, output);
  return output;
}

class Line {
  string[] columns;
  static beginTilde = regex("^~");
  static endTilde = regex("~$");
  this(string line) {
    columns = array(line.split("^").map!(a => a.replaceFirst(beginTilde, "").replaceFirst(endTilde, "")));
  }
  string opIndex(size_t i) {
    return columns[i];
  }
  override string toString() {
    return "Line(" ~ to!string(columns) ~ ")";
  }
}

class Nutrition {
  int id;
  string unit;
  string name;
  public string uiName;
  string description;
  this(Line line) {
    id = to!int(line[0]);
    unit = line[1];
    name = line[2];
    description = line[3];
  }
  override string toString() {
    return format("Nutrition { id: %d, unit: %s, name: %s, description: %s }", id, unit, name, description);
  }

  Nutrition setUiName(string uiName) {
    this.uiName = uiName;
    return this;
  }
}

class NutritionDetail {
  Food food;
  Nutrition nutrition;
  public string amount;
  this(Line line, Food[int] foods, Nutrition[int] nutritions) {
    auto foodId = to!int(line[0]);
    food = foods[foodId];
    auto nutritionId = to!int(line[1]);
    nutrition = nutritions[nutritionId];
    amount = line[2];
    food[nutrition] = this;
  }
  override string toString() {
    return format("Nutrition '%s' in Food '%s': %s", nutrition.name, food.name, amount);
  }
  string amountForUi() {
    return format("%.2f", to!float(amount));
  }
  string amountPerCalForUi(NutritionDetail calories) {
    if (calories is null) {
      return "???";
    } else {
      return format("%.2f", to!float(amount) / to!float(calories.amount));
    }
  }
}

class Food {
  int id;
  string name;
  NutritionDetail[Nutrition] nutritions;
  public NutritionDetail cal;
  this(Line l) {
    id = to!int(l[0]);
    name = l[2];
  }
  override string toString() {
    return format("Food { id: %d, name: %s }", id, name);
  }
  void opIndexAssign(NutritionDetail detail, Nutrition nutrition) {
    nutritions[nutrition] = detail;
    if (nutrition.name == "ENERC_KCAL") {
      cal = detail;
    }
  }

  NutritionDetail opIndex(Nutrition nutrition) {
    return nutritions[nutrition];
  }

  bool nutritionDataAvailableFor(Nutrition n) {
    return !((n in nutritions) is null);
  }

  double nutritionPerCal(Nutrition n) {
    auto d = nutritions[n];
    return to!float(d.amount) / to!float(cal.amount);
  }
}

auto latin1Lines(string fileName) {
  auto file = cast(Latin1String) read("lib/nutrition/density/usda/sr27asc/" ~ fileName);
  return t(file).splitLines().map!(a => new Line(a));
}

T[int] latin1Lines2Hash(T)(string fileName) {
  T[int] result;
  foreach (line; latin1Lines(fileName)) {
    T t = to!T(line);
    result[t.id] = t;
  }
  return result;
}

class Data {
  Food[int] foods;
  Nutrition[int] nutritions;

  this() {
    readFoods();
    readNutritions();
    readNutritionDetails();
  }

  private void readFoods() {
    StopWatch sw;
    sw.start();
    foods = latin1Lines2Hash!(Food)("FOOD_DES.txt");
    sw.stop();
    writeln("time for reading food: ", sw.peek().msecs, "ms");
  }

  private void readNutritions() {
    StopWatch sw;
    sw.start();
    nutritions = latin1Lines2Hash!(Nutrition)("NUTR_DEF.txt");
    sw.stop();
    writeln("time for reading nutritions: ", sw.peek().msecs, "ms");
  }

  private void readNutritionDetails() {
    StopWatch sw;
    sw.start();
    foreach (line; latin1Lines("NUT_DATA.txt")) {
      new NutritionDetail(line, foods, nutritions);
    }
    sw.stop();
    writeln("time for reading nutrition details: ", sw.peek().msecs, "ms");
  }

  private T byName(T)(T[int] from, string name) {
    return find!((a, b) => a.name == b)(from.values, name)[0];
  }

  public Food foodByName(string name) {
    return byName(foods, name);
  }

  public Nutrition nutritionByName(string name) {
    return byName(nutritions, name);
  }

}

void main() {
  Data data = new Data();

  auto foods = [
                "Arugula, raw",
                "Beef, tenderloin, steak, separable lean and fat, trimmed to 1/8\" fat, all grades, raw",
                "Blueberries, frozen, unsweetened",
                "Blueberries, raw",
                "Broccoli, raw",
                "Broccoli, cooked, boiled, drained, without salt",
                "Brussels sprouts, cooked, boiled, drained, without salt",
                "Brussels sprouts, raw",
                "Cabbage, chinese (pak-choi), raw",
                "Chard, swiss, raw",
                "Collards, raw",
                "Kale, cooked, boiled, drained, without salt",
                "Kale, raw",
                "Lemons, raw, without peel",
                "Mollusks, mussel, blue, raw",
                "Mustard greens, raw",
                "Oil, olive, salad or cooking",
                "Onions, raw",
                "Orange juice, raw",
                "Oranges, raw, all commercial varieties",
                "Spinach, cooked, boiled, drained, without salt",
                "Spinach, raw",
                "Watercress, raw",
                // "Blueberries, wild, frozen",
                // "SILK Blueberry soy yogurt",
                // "Stinging Nettles, blanched (Northern Plains Indians)",
                // "Tofu, raw, firm, prepared with calcium sulfate",
                ].map!(a => data.foodByName(a));

  auto nutritions =
    [
     data.nutritionByName("FAT").setUiName("Fat"),
     data.nutritionByName("VITC").setUiName("VitC"),
     data.nutritionByName("MG").setUiName("MG"),
     data.nutritionByName("FE").setUiName("FE"),
     data.nutritionByName("SUGAR").setUiName("Sugar"),
     data.nutritionByName("PROCNT").setUiName("Protein"),
     ];
  foreach (nutrition; nutritions) {
    Food res = null;
    double maxNutrition = 0.0;
    foreach (food; data.foods.values) {
      if (food.nutritionDataAvailableFor(nutrition)) {
        auto nutritionPerCal = food.nutritionPerCal(nutrition);
        if (nutritionPerCal > maxNutrition) {
          maxNutrition = nutritionPerCal;
          res = food;
        }
      }
    }
    if (!(res is null)) {
      writeln(format("max for nutrition %s is %s", nutrition, res));
    } else {
      writeln(format("no nutrition found for %s", nutrition));
    }
  }

  OutputStream output = openFile("out/index.html", FileMode.createTrunc);
  compileDietFile!("nutrition.dt", foods, nutritions)(output);
}
