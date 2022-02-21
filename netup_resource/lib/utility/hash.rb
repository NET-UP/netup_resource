class Hash
  def flatten_keys(newhash={}, keys=nil)
    self.each do |k, v|
      k = k.to_s
      keys2 = keys ? keys+"[#{k}]" : k
      if v.is_a?(Hash)
        v.flatten_keys(newhash, keys2)
      else
        newhash[keys2] = v
      end
    end
    newhash
  end

  def format_form_data
    result = {}
    self.each do |k,v|
      if v.is_a? Hash
         v = v.flatten_keys
         result[k.to_s] = format_form_data(v)
      elsif v.is_a? Array
         v.length.times do |n|
           v[n] = v[n].flatten_keys if v[n].is_a?(Hash)
           result.merge! "#{k.to_s}[]" => format_form_data(v[n])
       end
      else
         result[k.to_s] = v.to_s
      end
    end
    result
  end 
  alias_method :to_html, :format_form_data
end