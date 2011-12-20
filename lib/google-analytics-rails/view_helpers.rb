require 'google_analytics_tools'

module GoogleAnalytics::Rails
  # @example Ecommerce example
  #
  #     # create a new transaction
  #     analytics_add_transaction(
  #       '1234',           # order ID - required
  #       'Acme Clothing',  # affiliation or store name
  #       '11.99',          # total - required
  #       '1.29',           # tax
  #       '5',              # shipping
  #       'San Jose',       # city
  #       'California',     # state or province
  #       'USA'             # country
  #     )
  #
  #     # add an item to the transaction
  #     analytics_add_item(
  #       '1234',           # order ID - required
  #       'DD44',           # SKU/code - required
  #       'T-Shirt',        # product name
  #       'Green Medium',   # category or variation
  #       '11.99',          # unit price - required
  #       '1'               # quantity - required
  #     )
  #
  #     # submit the transaction
  #     analytics_track_transaction
  #
  module ViewHelpers
    # Initializes the Analytics javascript. Put it in the `<head>` tag.
    #
    # @param events [Array]
    #   The page load times and page views are tracked by default, additional events can be added here.
    # @param options [Hash]
    # @option options [Boolean] :local (false) Sets the local development mode.
    #   See http://www.google.com/support/forum/p/Google%20Analytics/thread?tid=741739888e14c07a&hl=en
    #
    # @example Set the local bit in development mode
    #   analytics_init :local => Rails.env.development?
    #
    # @example Allow links across domains
    #   analytics_init [GAQ::Events::SetAllowLinker.new(true)]
    #
    # @return [String] a `<script>` tag, containing the analytics initialization sequence.
    #
    def analytics_init(events = [], options = {})
      raise ArgumentError, "Tracker must be set! Did you set GAR.tracker ?" unless GAR.valid_tracker?

      local = options.delete(:local) || false

      queue = GAQ.new

      # unshift => reverse order
      events.unshift GAQ::Events::TrackPageLoadTime.new
      events.unshift GAQ::Events::TrackPageview.new
      events.unshift GAQ::Events::SetAccount.new(GAR.tracker)

      if local
        events.push GAQ::Events::SetDomainName.new('none')
        events.push GAQ::Events::SetAllowLinker.new(true)
      end

      events.each do |event|
        queue << event
      end

      queue.to_s.html_safe
    end

    # Track a custom event
    # @see http://code.google.com/apis/analytics/docs/tracking/eventTrackerGuide.html
    #
    # @example
    #
    #     analytics_track_event "Videos", "Play", "Gone With the Wind"
    #
    def analytics_track_event(category, action, label, value)
      analytics_render_event(GAQ::Events::TrackEvent.new(category, action, label, value))
    end

    # Track an ecommerce transaction
    # @see http://code.google.com/apis/analytics/docs/tracking/gaTrackingEcommerce.html
    def analytics_add_transaction(order_id, store_name, total, tax, shipping, city, state_or_province, country)
      analytics_render_event(GAQ::Events::ECommerce::AddTransaction.new(order_id, store_name, total, tax, shipping, city, state_or_province, country))
    end

    # Add an item to the current transaction
    # @see http://code.google.com/apis/analytics/docs/tracking/gaTrackingEcommerce.html
    def analytics_add_item(order_id, product_id, product_name, product_variation, unit_price, quantity)
      analytics_render_event(GAQ::Events::ECommerce::AddItem.new(order_id, product_id, product_name, product_variation, unit_price, quantity))
    end

    # Flush the current transaction
    # @see http://code.google.com/apis/analytics/docs/tracking/gaTrackingEcommerce.html
    def analytics_track_transaction
      analytics_render_event(GAQ::Events::ECommerce::TrackTransaction.new)
    end

    private

    def analytics_render_event(event)
      raise ArgumentError, "Tracker must be set! Did you set GAR.tracker ?" unless GAR.valid_tracker?
      result = <<-JAVASCRIPT
<script type="text/javascript">
  #{GAQ::EventRenderer.new(event, nil).to_s}
</script>
      JAVASCRIPT
      result.html_safe
    end
  end
end
