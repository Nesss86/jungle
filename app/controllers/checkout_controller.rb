class CheckoutController < ApplicationController
  def create_session
    # Create and persist the order before the Stripe session
    order = create_order

    # Ensure the order has a valid ID before generating the session
    if order.persisted?
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: [{
          price_data: {
            currency: 'cad',
            product_data: {
              name: "Jungle Order"
            },
            unit_amount: cart_subtotal_cents
          },
          quantity: 1
        }],
        mode: 'payment',
        success_url: order_url(order), # Redirect to order show page after payment
        cancel_url: cart_url
      )

      render json: { id: session.id }
    else
      render json: { error: "Order creation failed: #{order.errors.full_messages.join(', ')}" }, status: :unprocessable_entity
    end
  end

  private

  def create_order
    order = Order.new(
      email: "test@example.com",
      total_cents: cart_subtotal_cents,
      stripe_charge_id: nil
    )

    enhanced_cart.each do |entry|
      product = entry[:product]
      quantity = entry[:quantity]

      order.line_items.build(
        product: product,
        quantity: quantity,
        item_price_cents: product.price_cents,
        total_price_cents: product.price_cents * quantity
      )
    end

    order.save
    order
  end
end




