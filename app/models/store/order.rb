class Store::Order < ActiveRecord::Base
  belongs_to :user
  has_many :items, :class_name => "Store::OrderItem", :foreign_key => "order_id", :dependent => :destroy
  has_one :info, :class_name => "Store::OrderInfo", :foreign_key => "order_id"
  include AASM
  extend FriendlyId
  friendly_id :token
  before_save :generate_token, :set_paid_false

  def generate_token
    self.token = SecureRandom.hex if not self.token
    true
  end

  def set_paid_false
    self.paid = false if self.paid.nil?
    true
  end

  def paypal_url(return_url)
    url = Rails.application.routes.url_helpers.store_payment_notifiers_url(:host => ENV["paypal_returning_host"])
    values = {
      :business => ENV["paypal_seller_email"],
      :cmd => "_cart",
      :upload => "1",
      :return => return_url,
      :invoice => id,
      :notify_url => url,
      :cert_id => ENV["paypal_cert_id"]
    } 
    items.each_with_index do |item, index|
      values.merge!({
        "amount_#{index+1}" => item.price,
        "item_name_#{index+1}" => item.product.title,
        "item_number_#{index+1}" => item.id,
        "quantity_#{index+1}" => item.quantity
      })
    end
    # "https://www.sandbox.paypal.com/cgi-bin/webscr?" + values.to_query
    encrypt_for_paypal(values)
  end

  def encrypt_for_paypal(values)
    paypal_cert_pem = File.read("#{Rails.root}/certs/paypal_cert.pem")
    app_cert_pem = File.read("#{Rails.root}/certs/app_cert.pem")
    app_key_pem = File.read("#{Rails.root}/certs/app_key.pem")
    signed = OpenSSL::PKCS7::sign(OpenSSL::X509::Certificate.new(app_cert_pem), OpenSSL::PKey::RSA.new(app_key_pem, ''), values.map { |k, v| "#{k}=#{v}"  }.join("\n"), [], OpenSSL::PKCS7::BINARY)
    OpenSSL::PKCS7::encrypt([OpenSSL::X509::Certificate.new(paypal_cert_pem)], signed.to_der, OpenSSL::Cipher::Cipher::new("DES3"), OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")
  end

  def add_item(product_id)
    item = self.items.find_by_product_id(product_id)
    if item
      quan = item.quantity + 1
      item.update_column(:quantity, quan)
      # item.update_column(:price, quan*item.price)
    else
      product = Store::Product.find(product_id)
      item = self.items.create(:product_id => product.id, 
                        :quantity => 1,
                        :price => product.price
                       )
    end
    self.update_total_price
    {title: item.product.title, quantity: item.quantity, price: item.price}
  end

  def update_order_time
    self.update_column(:order_time, Time.now)
  end

  def update_pay_time
    self.update_column(:pay_time, Time.now)
  end

  def update_total_price
    total_price = self.items.inject(0){|r,item|
      r += (item.quantity * item.price)
    }
    self.update_column(:price, total_price)
  end

  aasm do
    state :outdated
    state :cart, :initial => true
    state :placed
    state :paid
    state :shipped
    state :arrived
    state :cancelled
    state :returned

    event :outdate do
      transitions from: [:cart, :placed], to: :outdated
    end
    event :place do
      transitions from: :cart, to: :placed
    end
    event :pay do
      transitions from: :placed, to: :paid
    end
    event :ship do
      transitions from: :paid, to: :shipped
    end
    event :arrive do
      transitions from: :shipped, to: :arrived
    end
    event :cancel do
      transitions from: [:cart, :placed, :paid], to: :cancelled
    end
    event :return do
      transitions from: :arrived, to: :returned
    end
  end
end