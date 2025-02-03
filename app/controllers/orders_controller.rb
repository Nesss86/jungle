class OrdersController < ApplicationController

  def show
    @order = Order.find(params[:id])
    @line_items = @order.line_items.includes(:product)
  end

  def create
    charge = perform_stripe_charge
    order = create_order(charge)

    if order.persisted? # Correctly check for persistence
      empty_cart!
      redirect_to order, notice: 'Your Order has been placed.'
    else
      redirect_to cart_path, flash: { error: order.errors.full_messages.first }
    end

  rescue Stripe::CardError => e
    redirect_to cart_path, flash: { error: e.message }
  end

  private

  def empty_cart!
    Rails.logger.debug "Clearing cart..."
    update_cart({})
  end

  def perform_stripe_charge
    Stripe::Charge.create(
      source: params[:stripeToken],
      amount: cart_subtotal_cents,
      description: "Jungle Order",
      currency: 'cad'
    )
  end

  def create_order(stripe_charge)
    order = Order.new(
      email: params[:stripeEmail],
      total_cents: cart_subtotal_cents,
      stripe_charge_id: stripe_charge.id
    )

    # Creating line items and associating them with the order
    enhanced_cart.each do |entry|
      product = entry[:product]
      quantity = entry[:quantity]

      Rails.logger.debug "Adding line item: Product #{product.name}, Quantity #{quantity}, Price per unit: #{product.price_cents}"

      order.line_items.build( # Build instead of create to associate correctly before saving
        product: product,
        quantity: quantity,
        item_price_cents: product.price_cents,
        total_price_cents: product.price_cents * quantity
      )
    end

    if order.save
      Rails.logger.debug "Order #{order.id} created with #{order.line_items.size} line items."
    else
      Rails.logger.debug "Failed to create order: #{order.errors.full_messages.join(', ')}"
    end

    order
  end
end



