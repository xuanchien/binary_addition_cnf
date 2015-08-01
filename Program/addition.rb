$number_of_clauses = 0
$number_of_vars = 0
$clause_string = []

#Class to map all variables into standard list of variables from 1 to 3*n + m + 2
class Mapper
  def initialize(n, m)
    @n = n
    @m = m

    $number_of_vars = 3*n + m + 2
  end

  #convert id into numeric variable
  def map(id)
    prefix = id.chars.first
    index = id.scan(/\d+/).first.to_i

    index = if prefix == 'z'
      index
    elsif prefix == 'x'
      @n + 1 + index
    elsif prefix == 'y'
      2*@n + 1 + index
    elsif prefix == 'c'
      2*@n + @m + 1 + index
    end

    index + 1
  end
end

#Represent a atomic variable
class Variable
  def initialize(id)
    @id = id
    @not = false
  end

  def to_s
    @not ? "-#{$mapper.map(@id)}" : $mapper.map(@id)
  end

  def not!
    @not = true

    self
  end
end

class AndClause
  def initialize(*clauses)
    @sub_clauses = clauses
  end

  def println
    @sub_clauses.each do |clause|
      clause.println
    end
  end
end

class OrClause
  def initialize(*variables)
    @variables = variables
  end

  def println
    $number_of_clauses += 1
    $clause_string << @variables.map { |variable| variable.to_s }.join(" ") + " 0"
  end
end

def f_and(*clauses)
  AndClause.new(*clauses)
end

def f_or(*variables)
  OrClause.new(*variables)
end

def f_not(variable)
  v = variable.dup
  v.not!
end

class Addition
  def initialize(x, y)
    @x = x.reverse
    @y = y.reverse

    @n = @x.length
    @m = @y.length

    $mapper = Mapper.new(@n, @m)
  end

  #Represent (z <=> x xor y) expression in CNF form
  def equivalent_with_xor2(z, x, y)
    rule1 = f_and(f_or(f_not(z), x, y), f_or(f_not(z), f_not(x), f_not(y)))

    rule2 = f_and(f_or(z, f_not(x), y), f_or(z, x, f_not(y)))

    f_and(rule1, rule2)
  end

  #Represent (z <=> x xor y xor c) expression in CNF form
  def equivalent_with_xor3(z, x, y, c)
    rule1 = f_and(
      f_or(f_not(z), x, f_not(y), f_not(c)),
      f_or(f_not(z), f_not(x), y, f_not(c)),
      f_or(f_not(z), f_not(x), f_not(y), c),
      f_or(f_not(z), x, y, c)
    )

    rule2 = f_and(
      f_or(z, f_not(x), y, c),
      f_or(z, x, f_not(y), c),
      f_or(z, x, y, f_not(c)),
      f_or(z, f_not(x), f_not(y), f_not(c))
    )

    f_and(rule1, rule2)
  end

  #Represent (x <=> y and z) expression in CNF form
  def equivalent_with_and(x, y, z)
    f_and(
      f_and(f_or(f_not(x), y), f_or(f_not(x), z)),
      f_and(f_or(f_not(y), f_not(z), x))
    )
  end

  #Represent (x <=> at_least_two(y, z, t)) expression in CNF form
  def equivalent_with_at_least_two(x, y, z, t)
    rule1 = f_and(
      f_or(f_not(x), y, z),
      f_or(f_not(x), y, t),
      f_or(f_not(x), z, t)
    )

    rule2 = f_and(
      f_or(x, f_not(y), f_not(z)),
      f_or(x, f_not(y), f_not(t)),
      f_or(x, f_not(z), f_not(t))
    )

    f_and(rule1, rule2)
  end

  #Represent (x <=> y) expression in CNF form
  def equivalent(x, y)
    f_and(f_or(f_not(x), y), f_or(f_not(y), x))
  end

  #Main function to generate clauses
  def generate_clauses
    x = Array.new(@n)
    y = Array.new(@m)
    c = Array.new(@n + 1)
    z = Array.new(@n + 1)

    @n.times do |i|
      x[i] = Variable.new("x#{i}")
    end

    @m.times do |i|
      y[i] = Variable.new("y#{i}")
    end

    (@n + 1).times do |i|
      c[i] = Variable.new("c#{i}")
      z[i] = Variable.new("z#{i}")
    end

    #Generate clauses for z[0] <=> x[0] xor y[0]
    equivalent_with_xor2(z[0], x[0], y[0]).println

    #Generate clauses for c[1] <=> x[0] and y[0]
    equivalent_with_and(c[1], x[0], y[0]).println

    #Generate clauses (in case 0 < i < m)
    # z[i] <=> x[i] xor y[i] xor z[i]
    # c[i+1] <=> at_least_two(x[i], y[i], c[i])
    (1..@m-1).each do |i|
      equivalent_with_xor3(z[i], x[i], y[i], c[i]).println
      equivalent_with_at_least_two(c[i+1], x[i], y[i], c[i]).println
    end

    #Generate clauses (in case m <= i < n)
    # z[i] <=> x[i] xor c[i]
    # c[i+1] <=> x[i] and c[i]
    (@m..@n-1).each do |i|
      equivalent_with_xor2(z[i], x[i], c[i]).println
      equivalent_with_and(c[i+1], x[i], c[i]).println
    end

    #Generate clauses for z[n] <=> c[n]
    equivalent(z[@n], c[@n]).println

    #Clauses for representing input numbers
    @x.chars.each_with_index do |ch, i|
      if ch == '1'
        $clause_string << "#{x[i].to_s} 0"
      else
        $clause_string << "-#{x[i].to_s} 0"
      end
    end

    @y.chars.each_with_index do |ch, i|
      if ch == '1'
        $clause_string << "#{y[i].to_s} 0"
      else
        $clause_string << "-#{y[i].to_s} 0"
      end
    end

    $clause_string << "-#{c[0].to_s} 0"
  end
end

if ARGV.length == 0
  puts "Please specify input file"
  exit
end

f = File.open(ARGV.first, "r")
x, y = f.readline.split(/\s+/)

puts ""
puts "Processing..."
Addition.new(x, y).generate_clauses

puts ""
puts "Writing config file..."
File.open("config.txt", "w") do |f|
  f.puts "c Addition of two binary numbers: #{x} and #{y}"
  f.puts "p cnf #{$number_of_vars} #{$number_of_clauses}"
  $clause_string.each do |string|
    f.puts string
  end
end

puts ""
puts "Done! Config file has been generated successfully!"