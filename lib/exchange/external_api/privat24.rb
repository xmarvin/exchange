# -*- encoding : utf-8 -*-
module Exchange
  module ExternalAPI
    class Privat24 < XML
      API_URL              = 'api.privatbank.ua/p24api'
      CURRENCIES           = [:uah, :usd, :eur, :rub]

      def update opts={}
        time = helper.assure_time(opts[:at])
        
        Call.new(api_url(time), :at => time, :format => :xml, :api => self.class) do |result|
          @base                 = :uah
          @buy_rates            = extract_rates(result, 'buy')
          @sale_rates           = extract_rates(result, 'sale')
          @timestamp            = Time.now.to_i
        end
      end

      def get_rate(cur, method)
        _rates = if method == :buy
                   @buy_rates
                 else
                   @sale_rates
                 end
        _rates[cur]
      end

      def rate from, to, opts={}
        rate = cache.cached(self.class, opts.merge(:key_for => [from, to])) do
          return  BigDecimal.new("1.0") if from == to
          update(opts)
          rate_from   = get_rate(from, from != base ? :buy : :sale)
          rate_to     = get_rate(to, to == base ?  :buy : :sale)
          test_for_rates_and_raise_if_nil rate_from, rate_to, opts[:at]

          rate_to / rate_from
        end

        rate.is_a?(BigDecimal) ? rate : BigDecimal.new(rate.to_s)
      end

      private

      def extract_rates doc, method
        res = doc.css('row exchangerate').inject({uah: 1}) do |h, a|
          h[check_currency(a.attributes['ccy'].to_s.downcase.to_sym)] = 1 / BigDecimal.new(a.attributes[method].to_s)
          h
        end
        res
      end

        def check_currency(cur)
          cur == :rur ? :rub : cur
        end

        def api_url time=nil
          [ 
            "#{config.protocol}:/", 
            API_URL, 
            'pubinfo?exchange&coursid=5'
          ].join('/')
        end
        
    end
  end
end
