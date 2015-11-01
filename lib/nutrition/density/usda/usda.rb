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

        def []=(nutrition, amount)
          @nutritions[nutrition] = amount
        end

        def [](nutrition)
          return @nutritions[nutrition]
        end
      end

      class Nutrition
        attr_reader :id, :unit, :name, :description
        def initialize(line)
          @id = line[0]
          @unit = line[1]
          @name = line[2]
          @description = line[3]
        end
        def to_s
          "#{description} (#{@unit})"
        end
      end

      class NutritionDetail
        attr_reader :food, :nutrition, :amount
        def initialize(line, nutritions)
          @food = line[0]
          @nutrition = nutritions[line[1]]
          @amount = line[2]
        end
        def to_s
          "#{@nutrition}: #{@amount}"
        end
      end

      class Data
        attr_reader :foods, :nutritions
        def initialize(food_description, nutrition_description, nutrition_data)
          @foods = {}
          File.open(food_description, 'rb', :encoding => 'iso-8859-1').each_line() do |line|
            food = Food.new(Line.new(line))
            @foods[food.id] = food
          end

          @nutritions = {}
          File.open(nutrition_description, 'rb', :encoding => 'iso-8859-1').each_line() do |line|
            nutrition = Nutrition.new(Line.new(line))
            @nutritions[nutrition.id] = nutrition
          end

          File.open(nutrition_data, 'rb', :encoding => 'iso-8859-1').each_line() do |line|
            detail = NutritionDetail.new(Line.new(line), @nutritions)
            @foods[detail.food][detail.nutrition] = detail
          end
        end

        def food_by_name(name)
          k, v = @foods.find{|k,v|v.name == name}
          raise "food '#{name}' not found" unless v
          return v
        end

        def nutrition_by_name(name)
          k, v = @nutritions.find{|k,v|v.name == name}
          raise "nutrition '#{name}' not found" unless v
          return v
        end

        def nutrition_for_food_by_names(food_name, nutrition_name)
          food = food_by_name(food_name)
          nutrition = nutrition_by_name(nutrition_name)
          return food[nutrition]
        end

        def vitamin_c(name)
          food = food_by_name(name)
          nutrition = nutrition_by_name('VITC')
          res = food[nutrition]
          return nil unless res
          return Float(res.amount)
        end

        def cal(name)
          food = food_by_name(name)
          nutrition = nutrition_by_name('ENERC_KCAL')
          res = food[nutrition]
          return nil unless res
          return Float(res.amount)
        end
      end
    end
  end
end
