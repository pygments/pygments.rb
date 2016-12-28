# coding: utf-8
# frozen_string_literal: true
require File.join(File.dirname(__FILE__), 'pygments/popen')
require 'forwardable'

module Pygments

  autoload :Lexer, 'pygments/lexer'

  class << self
    extend Forwardable

    def engine
      Thread.current.thread_variable_get(:pygments_engine) ||
        Thread.current.thread_variable_set(:pygments_engine, Pygments::Popen.new)
    end

    def_delegators :engine,
      :formatters,
      :lexers,
      :lexers!,
      :filters,
      :styles,
      :css,
      :lexer_name_for,
      :highlight,
      :start
  end
end
