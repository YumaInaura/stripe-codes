#! /usr/bin/env ruby

require 'stripe'

# You Need
# `$ gem install activesupport` befure run ruby script
require 'active_support/core_ext'

# Docs
# https://stripe.com/docs/api/subscriptions/create
# https://stripe.com/docs/billing/subscriptions/billing-cycle#prorations


Stripe::api_key = ENV['STRIPE_SECRET_KEY']

def create_subscription_and_cancel(cancel_at_natural_cycle_end:, prorate:)
  product1 = Stripe::Product.create(name: "Gold plan #{rand(9999999999)}")
  plan1 = Stripe::Plan.create(interval: 'month', currency: 'jpy', amount: 980, product: product1.id, usage_type: 'licensed')

  tax_rate = Stripe::TaxRate.create(display_name: 'Tax Rate', percentage: 10.0, inclusive: false)
  customer = Stripe::Customer.create
  payment_method = Stripe::PaymentMethod.create(type: 'card', card: { number: '4242424242424242', exp_year: 2030, exp_month: 01})
  customer_payment_method = Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

  subscription = Stripe::Subscription.create(
    {
      customer: customer.id,
      default_payment_method: customer_payment_method.id,
      items: [
        [
          { plan: plan1.id },
        ],
      ],
      prorate: prorate,
      default_tax_rates: [tax_rate],
    }
  )

  cancel_at = if cancel_at_natural_cycle_end
                Time.at(subscription.current_period_start).since(1.month).to_i
              else
                Time.at(subscription.current_period_start).since(1.month).ago(1.day).to_i
              end

  updated_subscription = Stripe::Subscription.update( subscription.id, cancel_at: cancel_at )

  puts '=' * 100
  puts "SUBSCRIPTION"
  puts '-' * 100
  puts "cancel_at_natural_cycle_end: #{cancel_at_natural_cycle_end}"
  puts "prorate: #{prorate}"
  puts "cancel_at: #{updated_subscription.cancel_at} ( #{Time.at(updated_subscription.cancel_at)} ) "
  if ENV['VERBOSE']
    puts '-' * 100
    puts updated_subscription
  end

  puts '-' * 100
  puts 'UPCOMING INVOICE'
  puts '-' * 100

  begin
    upcoming_invoice = Stripe::Invoice.upcoming(customer: updated_subscription.customer)
    puts "subotal: #{upcoming_invoice.subtotal}"
    puts "tax: #{upcoming_invoice.tax}"
    puts "total: #{upcoming_invoice.total}"
  rescue Stripe::InvalidRequestError => e
    puts e.message
  end

  if ENV['VERBOSE']
    puts '-' * 100
    puts upcoming_invoice
  end

  puts '-' * 100
  puts "https://dashboard.stripe.com/test/subscriptions/#{subscription.id}"

  updated_subscription
end

create_subscription_and_cancel(cancel_at_natural_cycle_end: true, prorate: true)
create_subscription_and_cancel(cancel_at_natural_cycle_end: false, prorate: true)

create_subscription_and_cancel(cancel_at_natural_cycle_end: true, prorate: false)
create_subscription_and_cancel(cancel_at_natural_cycle_end: false, prorate: false)

