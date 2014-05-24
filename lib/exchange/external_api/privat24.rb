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
          @rates                = extract_rates(result)
          @timestamp            = Time.now.to_i
        end
      end
            
      private

        def extract_rates doc
          res = doc.css('row exchangerate').inject({uah: 1}) do |h, a|
            h[check_currency(a.attributes['ccy'].to_s.downcase.to_sym)] = 1 / BigDecimal.new(a.attributes['buy'].to_s)
            h
          end
          p res
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
