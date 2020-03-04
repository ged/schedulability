# -*- ruby -*-
# frozen_string_literal: true

require 'schedulability' unless defined?( Schedulability )

# Schedulability namespace
module Schedulability

	class Error < StandardError; end

	class ParseError < Error; end

	class RangeError < ParseError; end

end # module Arborist

