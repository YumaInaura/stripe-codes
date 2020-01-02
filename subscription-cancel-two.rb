# Docs

# https://stripe.com/docs/billing/subscriptions/subscription-schedules
# https://stripe.com/docs/billing/subscriptions/subscription-schedules/use-cases
#
# https://stripe.com/docs/api/subscription_schedules/release
# https://support.stripe.com/questions/create-update-and-schedule-subscriptions


require 'stripe'

Stripe::api_key = ENV['STRIPE_SECRET_KEY']

product1 = Stripe::Product.create(name: "Gold plan #{rand(9999999999)}")
plan1 = Stripe::Plan.create(interval: 'month', currency: 'jpy', amount: 5000, product: product1.id, usage_type: 'licensed')

tax_rate = Stripe::TaxRate.create(display_name: 'Tax Rate', percentage: 10.0, inclusive: false)
customer = Stripe::Customer.create
payment_method = Stripe::PaymentMethod.create(type: 'card', card: { number: '4242424242424242', exp_year: 2030, exp_month: 01})
customer_payment_method = Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id)

def put_subscription_schedule(subscription_schedule, message)
  puts '-' * 100
  puts "Subscription Schedule"
  puts message
  puts '-' * 100
  puts subscription_schedule
  puts '-' * 100
  puts "https://dashboard.stripe.com/test/subscription_schedules/#{subscription_schedule.id}"
end

# https://stripe.com/docs/api/subscription_schedules/create
soon_start_subscription_schedule = Stripe::SubscriptionSchedule.create(
  {
    customer: customer.id,
    start_date: Time.now.to_i + 5,
    default_settings: {
      default_payment_method: customer_payment_method.id,
    },
    phases: [
      {
        plans:
          [
            { plan: plan1.id, quantity: 1 },
          ],
        prorate: false,
        default_tax_rates: [tax_rate],
      },
    ],
  }
)
put_subscription_schedule(soon_start_subscription_schedule, 'CREATED')

puts '-' * 100
puts "Wait until subscription schedule starts"
puts '-' * 100
until soon_start_subscription_schedule.status == 'active' do
  soon_start_subscription_schedule = Stripe::SubscriptionSchedule.retrieve(soon_start_subscription_schedule.id)
  puts soon_start_subscription_schedule.status
  sleep 2
end

started_subscription_schedule = Stripe::SubscriptionSchedule.retrieve(id: soon_start_subscription_schedule.id, expand: ['subscription'])

future_subscription_schedule = Stripe::SubscriptionSchedule.create(
  {
    customer: customer.id,
    start_date: Time.now.to_i + 100*24*60*60,
    default_settings: {
      default_payment_method: customer_payment_method.id,
    },
    phases: [
      {
        plans:
          [
            { plan: plan1.id, quantity: 1 },
          ],
        prorate: false,
        default_tax_rates: [tax_rate],
      },
    ],
  }
)
put_subscription_schedule(future_subscription_schedule, 'CREATED')

binding.pry

def update_subscription_schedule(base_subscription_schedule)
  Stripe::SubscriptionSchedule.update(
    base_subscription_schedule.id,
    {
      end_behavior: 'cancel',
      phases: [
        {
          plans:
            [
              {
                plan:     base_subscription_schedule.phases[0].plans[0].plan,
                quantity: base_subscription_schedule.phases[0].plans[0].quantity
              },
            ],
          prorate: base_subscription_schedule.phases[0].prorate,
          default_tax_rates: base_subscription_schedule.phases[0].default_tax_rates.map(&:id),
          start_date: base_subscription_schedule.phases[0].start_date,
          end_date: base_subscription_schedule.phases[0].start_date + end_from_start_date
        },
      ]
    }
  )
end


update_subscription_schedule(started_subscription_schedule)
update_subscription_schedule(future_subscription_schedule)
