# coding: utf-8
module Nutrition
  module Density
    module Usda
      def self.path_to_resource(resource)
        return File.join(File.dirname(File.expand_path(__FILE__)), resource)
      end

      def self.load()
        return Data.new(
          path_to_resource('sr27asc/FOOD_DES.txt'),
          path_to_resource('sr27asc/NUTR_DEF.txt'),
          path_to_resource('sr27asc/NUT_DATA.txt')
        )
      end

      class Line
        def initialize(line)
          @columns = line.split("^")
        end
        def [](i)
          return @columns[i].gsub('~', '')
        end
        def to_s
          @columns.join(', ')
        end
      end

      class Food
        attr_reader :id, :name, :nutritions
        def initialize(line)
          @id = line[0]
          @name = line[2]
          @nutritions = {}
        end

        def cal
          _, v = find_by_name(@nutritions, 'nutrition', 'ENERC_KCAL')
          return Float(v.amount)
        end

        def []=(nutrition, detail)
          @nutritions[nutrition] = detail
        end

        def [](nutrition)
          return @nutritions[nutrition]
        end
      end

      class Nutrition
        attr_reader :id, :unit, :name, :description, :ui_name
        def initialize(line)
          @id = line[0]
          @unit = line[1]
          @name = line[2]
          @description = line[3]
        end
        def set_ui_name(name)
          @ui_name = name
          return self
        end
        def to_s
          "#{description} (#{@unit})"
        end
      end

      class NutritionDetail
        attr_reader :food, :nutrition, :amount
        def initialize(line, nutritions, foods)
          @food = foods[line[0]]
          @nutrition = nutritions[line[1]]
          @amount = line[2]
          food[@nutrition] = self
        end
        def amount_for_ui
          return Float(@amount).round(3)
        end
        def amount_per_cal_for_ui(cal)
          return (Float(@amount) / cal).round(3)
        end
        def to_s
          "#{@nutrition}: #{@amount}"
        end
      end

      def each_iso_8859_line_to_hash(file)
        res = Hash.new
        File.open(file, 'rb', :encoding => 'iso-8859-1').each_line() do |line|
          o = yield(Line.new(line))
          res[o.id] = o
        end
        return res
      end

      class Data
        attr_reader :foods, :nutritions
        def initialize(food_description, nutrition_description, nutrition_data)
          @foods = each_iso_8859_line_to_hash(food_description) {|line|Food.new(Line.new(line))}
          @nutritions = each_iso_8859_line_to_hash(nutrition_description) {|line|Nutrition.new(line)}
          each_iso_8859_line_to_hash(nutrition_data) {|line|NutritionDetail.new(line, @nutritions, @foods)}
        end

        def food_by_name(name)
          return find_by_name(@foods, 'food', name)
        end

        def nutrition_by_name(name)
          return find_by_name(@nutritions, 'nutrition', name)
        end

        def find_by_name(what, msg, name)
          _, v = what.find{|_,v|v.name == name}
          raise "#{msg} '#{name}' not found" unless v
          return v
        end
      end
    end
  end
end
