module ApplicationHelper
  def format_price(amount)
    # Convert integers to Money objects before formatting
    money = amount.is_a?(Integer) ? Money.new(amount, "USD") : amount
    money.format(symbol: true, no_cents_if_whole: false)
  end
end












