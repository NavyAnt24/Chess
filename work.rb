class Employee
  attr_accessor :name, :title, :salary, :boss

  def initialize(name, title, salary, boss)
    @name = name
    @title = title
    @salary = salary
    @boss = boss
  end

  def bonus_multiplier(multiplier)
    bonus = @salary * multiplier
  end

end

class Manager < Employee

  def initialize(name, title, salary, boss)
    super(name, title, salary, boss)
    @employees = []
  end

  def add_employee(employee)
    employee.boss = self.name
    @employees << employee
  end

  def bonus_multiplier(multiplier)
    total_salaries = 0
    @employees.each do |employee|
      total_salaries += employee.salary
      total_salaries += employee.bonus_multiplier(1) if employee.is_a?(Manager)
    end
    total_salaries *= multiplier
  end

end

lead_manager = Manager.new("CEO", "Leader", 5000, "no one!")

m1 = Manager.new("Micah", "Lead programmer", 2000, "CEO")
m2 = Manager.new("Micah2", "Lead programmer", 2000, "CEO")
m3 = Manager.new("Micah3", "Lead programmer", 2000, "CEO")

e1 = Employee.new("David", "Programmer", 1000, "Micah")
e2 = Employee.new("David2", "Programmer", 1000, "Micah")
e3 = Employee.new("David3", "Programmer", 1000, "Micah")
e4 = Employee.new("David4", "Programmer", 1000, "Micah")
e5 = Employee.new("David5", "Programmer", 1000, "Micah")

lead_manager.add_employee(m1)
lead_manager.add_employee(m2)
lead_manager.add_employee(m3)

m1.add_employee(e1)
m2.add_employee(e2)
m2.add_employee(e3)
m2.add_employee(e4)
m3.add_employee(e5)



p lead_manager.bonus_multiplier(0.1)