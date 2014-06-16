# encoding: utf-8

require 'singularity_dsl/dsl/changeset'
require 'singularity_dsl/dsl/event_store'
require 'singularity_dsl/dsl/registry'

module SingularityDsl
  # DSL classes & fxs
  module Dsl
    # wrapper for DSL
    class Dsl
      include Changeset
      include EventStore

      attr_reader :registry

      def initialize
        super
        @registry = Registry.new
        load_tasks_in_path default_task_dir
      end

      def define_task(klass)
        raise_task_def_error klass if task_defined klass
        # because define_method is private
        define_singleton_method(task klass) do |&block|
          @registry.add_task klass.new(&block)
        end
      end

      def task_name(klass)
        klass.to_s.split(':').last
      end

      def task(klass)
        task_name(klass).downcase.to_sym
      end

      def task_list
        klasses = []
        SingularityDsl.constants.each do |klass|
          klass = SingularityDsl.const_get(klass)
          next unless klass.is_a? Class
          next unless klass < Task
          klasses.push klass
        end
        klasses
      end

      def load_tasks_in_path(path)
        base_tasks = task_list
        files_in_path(path).each do |file|
          SingularityDsl.module_eval(::File.read file)
        end
        load_tasks(task_list - base_tasks)
      end

      private

      def files_in_path(path)
        paths = [path] if ::File.file? path
        paths = dir_glob path if ::File.directory? path
        paths ||= []
        paths
      end

      def dir_glob(dir)
        dir = ::File.join dir, '**'
        ::Dir.glob dir
      end

      def raise_task_def_error(klass)
        fail "task name clash for #{klass}"
      end

      def task_defined(klass)
        singleton_methods(false).include?(task klass)
      end

      def load_tasks(list)
        list.each { |klass| define_task klass }
      end

      def default_task_dir
        dir = ::File.dirname __FILE__
        ::File.join dir, '..', 'tasks'
      end
    end
  end
end