module Store::OrdersHelper
  def order_title
    if @order.aasm_state == "cart"
      content_tag(:h2, "購物車明細")
    else
      content_tag(:h2, "訂單明細")
    end
  end

  def status_print(state)
    case state
    when "cart"
      "購物車"
    when "placed"
      "待結帳"
    when "paid"
      "已付款"
    when "shipped"
      "已出貨"
    when "arrived"
      "已到貨"
    when "cancelled"
      "已取消"
    when "returned"
      "已退回"
    when "outdated"
      "已過期"
    end
  end

  def progress_bar
    return if @order.aasm_state == "cart"
    value = case @order.aasm_state
    when "placed"
      "10"
    when "paid"
      "50"
    when "delivered"
      "100"
    else
      "0"
    end
    content_tag(:progress, "", :max => "100", :value => value)
  end

  def progress_bar_status
    return if @order.aasm_state == "cart"
    content_tag(:div,
               content_tag(:span, "下單", id: "place") + 
               content_tag(:span, "付款", id: "pay") + 
               content_tag(:span, "出貨", id: "deliver"),
               :class => "status-bar")
  end

  def check_stock(item)
    quantity = item.quantity
    stock = item.product.stock
    if quantity > stock 
      content_tag(:span, "不足", style: "color: red")
    else
      content_tag(:span, "有")
    end
  end

  def action_button
    _class = "btn btn-primary action"
    case @order.aasm_state
    when "cart"
      link_to("確認下單", place_store_order_path(@order), class: _class)
    when "placed"
      link_to("前往付款頁面", "", class: _class)
    else
      ""
    end
  end
end
