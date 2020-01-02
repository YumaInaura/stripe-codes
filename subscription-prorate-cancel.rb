#! /usr/bin/env ruby


# Docs
# https://stripe.com/docs/api/subscriptions/create
# https://stripe.com/docs/billing/subscriptions/billing-cycle#prorations

require 'stripe'

Stripe::api_key = ENV['STRIPE_SECRET_KEY']

def create_subscription_and_cancel(cancel_at_natural_cycle_end: , prorate: )
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

  puts '=' * 100
  puts "SUBSCRIPTION CREATED"


    binding.pry

  cancel_at_natural_cycle_end = if cancel_at_natural_cycle_end
                                else
                                end

  updated_subscription = Stripe::Subscription.update(
    subscription.id,
      cancel_at: cancel_atsubscription.start_date
  )

  puts '-' * 100
  puts "SUBSCRIPTION UPDATED"
  puts '-' * 100
  puts "cancel_at_days_from_start_date: #{cancel_at_days_from_start_date}"
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

# Result Example
#
# ====================================================================================================
# SUBSCRIPTION CREATED
# ----------------------------------------------------------------------------------------------------
# SUBSCRIPTION UPDATED
# ----------------------------------------------------------------------------------------------------
# cancel_at_days_from_start_date: 1.0
# prorate: true
# cancel_at: 1578015503 ( 2020-01-03 10:38:23 +0900 )
# ----------------------------------------------------------------------------------------------------
# UPCOMING INVOICE
# ----------------------------------------------------------------------------------------------------
# No upcoming invoices for customer: cus_GTF8W1OmEXfBA0
# ----------------------------------------------------------------------------------------------------
# https://dashboard.stripe.com/test/subscriptions/sub_GTF8U3YhsJCrQS
# ====================================================================================================
# SUBSCRIPTION CREATED
# ----------------------------------------------------------------------------------------------------
# SUBSCRIPTION UPDATED
# ----------------------------------------------------------------------------------------------------
# cancel_at_days_from_start_date: 1.5
# prorate: true
# cancel_at: 1578058710 ( 2020-01-03 22:38:30 +0900 )
# ----------------------------------------------------------------------------------------------------
# UPCOMING INVOICE
# ----------------------------------------------------------------------------------------------------
# subotal: 2500
# tax: 250
# total: 2750
# ----------------------------------------------------------------------------------------------------
# https://dashboard.stripe.com/test/subscriptions/sub_GTF8H7bIsaj8Pk
# ====================================================================================================
# SUBSCRIPTION CREATED
# ----------------------------------------------------------------------------------------------------
# SUBSCRIPTION UPDATED
# ----------------------------------------------------------------------------------------------------
# cancel_at_days_from_start_date: 1.0
# prorate: false
# cancel_at: 1578015516 ( 2020-01-03 10:38:36 +0900 )
# ----------------------------------------------------------------------------------------------------
# UPCOMING INVOICE
# ----------------------------------------------------------------------------------------------------
# No upcoming invoices for customer: cus_GTF8CXrtvAVwF3
# ----------------------------------------------------------------------------------------------------
# https://dashboard.stripe.com/test/subscriptions/sub_GTF87Md8TDO0kp
# ====================================================================================================
# SUBSCRIPTION CREATED
# ----------------------------------------------------------------------------------------------------
# SUBSCRIPTION UPDATED
# ----------------------------------------------------------------------------------------------------
# cancel_at_days_from_start_date: 1.5
# prorate: false
# cancel_at: 1578058721 ( 2020-01-03 22:38:41 +0900 )
# ----------------------------------------------------------------------------------------------------
# UPCOMING INVOICE
# ----------------------------------------------------------------------------------------------------
# subotal: 2500
# tax: 250
# total: 2750
# ----------------------------------------------------------------------------------------------------
# https://dashboard.stripe.com/test/subscriptions/sub_GTF8anHJQxbjuZ

# Upcoming Invoice example
#
# #<Stripe::Invoice:0x3fc4a2661790> JSON: {
#   "object": "invoice",
#   "account_country": "JP",
#   "account_name": "yumainaura",
#   "amount_due": 2750,
#   "amount_paid": 0,
#   "amount_remaining": 2750,
#   "application_fee_amount": null,
#   "attempt_count": 0,
#   "attempted": false,
#   "billing_reason": "upcoming",
#   "charge": null,
#   "collection_method": "charge_automatically",
#   "created": 1578014805,
#   "currency": "jpy",
#   "custom_fields": null,
#   "customer": "cus_GTEw1afyfIrI1y",
#   "customer_address": null,
#   "customer_email": null,
#   "customer_name": null,
#   "customer_phone": null,
#   "customer_shipping": null,
#   "customer_tax_exempt": "none",
#   "customer_tax_ids": [
#
#   ],
#   "default_payment_method": null,
#   "default_source": null,
#   "default_tax_rates": [
#     {"id":"txr_1FwISWCmti5jpytUAW5cQLZD","object":"tax_rate","active":true,"created":1577928404,"description":null,"display_name":"Tax Rate","inclusive":false,"jurisdiction":null,"livemode":false,"metadata":{},"percentage":10.0}
#   ],
#   "description": null,
#   "discount": null,
#   "due_date": null,
#   "ending_balance": 0,
#   "footer": null,
#   "lines": {"object":"list","data":[{"id":"ii_1FwIVXCmti5jpytU8CG244xU","object":"line_item","amount":2500,"currency":"jpy","description":"Time on Gold plan 4089335818 after 03 Jan 2020","discountable":false,"invoice_item":"ii_1FwIVXCmti5jpytU8CG244xU","livemode":false,"metadata":{},"period":{"end":1578058005,"start":1578014805},"plan":{"id":"plan_GTEwRnsNWzQe0z","object":"plan","active":true,"aggregate_usage":null,"amount":5000,"amount_decimal":"5000","billing_scheme":"per_unit","created":1577928403,"currency":"jpy","interval":"day","interval_count":1,"livemode":false,"metadata":{},"nickname":null,"product":"prod_GTEwFNftibuHvh","tiers":null,"tiers_mode":null,"transform_usage":null,"trial_period_days":null,"usage_type":"licensed"},"proration":true,"quantity":1,"subscription":"sub_GTEwOBkoJxfJns","subscription_item":"si_GTEwb4o0RNQrDl","tax_amounts":[{"amount":250,"inclusive":false,"tax_rate":"txr_1FwISWCmti5jpytUAW5cQLZD"}],"tax_rates":[],"type":"invoiceitem","unique_id":"il_tmp1FwIVXCmti5jpytU8CG244xU"}],"has_more":false,"total_count":1,"url":"/v1/invoices/upcoming/lines?customer=cus_GTEw1afyfIrI1y"},
#   "livemode": false,
#   "metadata": {},
#   "next_payment_attempt": 1578018405,
#   "number": "3FF07B02-0002",
#   "paid": false,
#   "payment_intent": null,
#   "period_end": 1578014805,
#   "period_start": 1577928405,
#   "post_payment_credit_notes_amount": 0,
#   "pre_payment_credit_notes_amount": 0,
#   "receipt_number": null,
#   "starting_balance": 0,
#   "statement_descriptor": null,
#   "status": "draft",
#   "status_transitions": {"finalized_at":null,"marked_uncollectible_at":null,"paid_at":null,"voided_at":null},
#   "subscription": "sub_GTEwOBkoJxfJns",
#   "subtotal": 2500,
#   "tax": 250,
#   "tax_percent": 10.0,
#   "total": 2750,
#   "total_tax_amounts": [
#     {"amount":250,"inclusive":false,"tax_rate":"txr_1FwISWCmti5jpytUAW5cQLZD"}
#   ],
#   "webhooks_delivered_at": null
# }

