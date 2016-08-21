require "suture"

class Calculator
  def add(a,b)
    Suture.create :add,
      :old => method(:old_add),
      :new => method(:new_add),
      :args => [a,b]
  end

  private

  def old_add(a,b)
    a + b
  end

  def new_add(a,b)
    b + a
  end
end
