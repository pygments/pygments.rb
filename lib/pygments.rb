# frozen_string_literal: true

require 'forwardable'

require_relative 'pygments/lexer'
require_relative 'pygments/popen'

module Pygments
  class << self
    extend Forwardable

    def lexers
      LexerCache.instance.raw_lexers
    end

    def engine
      Thread.current.thread_variable_get(:pygments_engine) ||
        Thread.current.thread_variable_set(:pygments_engine, Pygments::Popen.new)
    end

    def_delegators :engine,
                   :formatters,
                   :lexers!,
                   :filters,
                   :styles,
                   :css,
                   :lexer_name_for,
                   :highlight,
                   :start
  end
end
