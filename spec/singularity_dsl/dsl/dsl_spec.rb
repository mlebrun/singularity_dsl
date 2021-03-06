# encoding: utf-8

require 'singularity_dsl/dsl/dsl'
require 'singularity_dsl/dsl/registry'
require 'singularity_dsl/task'

class TestTask < SingularityDsl::Task
end

describe 'Dsl' do
  let(:dsl) { SingularityDsl::Dsl::Dsl.new }

  context '#initialize' do
    it 'creates registry' do
      expect(dsl.registry).to be_a_kind_of SingularityDsl::Dsl::Registry
    end
  end

  context '#define_task' do
    it 'creates task function for given task' do
      dsl.define_task TestTask
      expect(dsl.singleton_methods).to include :testtask
    end

    it 'throws when tasks have the same name' do
      dsl.define_task TestTask
      expect { dsl.define_task TestTask }
        .to raise_error RuntimeError, /task name clash/
    end
  end

  context '#load_ex_proc' do
    let(:test_proc) { ::Proc.new { flag 'load_ex_proc_flag' } }
    let(:registry_double) { double 'SingularityDsl::Dsl::Registry_DOUBLE' }

    it 'instance_evals block' do
      expect(dsl).to receive(:flag).with('load_ex_proc_flag')
      dsl.load_ex_proc(&test_proc)
    end

    it 'wipes the existing task registry' do
      expect(dsl.registry).to_not eql registry_double

      allow(SingularityDsl::Dsl::Registry).to receive(:new)
        .and_return(registry_double)

      dsl.load_ex_proc(&test_proc)

      expect(dsl.registry).to eql registry_double
    end
  end

  context '#load_ex_script' do
    let(:test_proc) { ::Proc.new {} }
    let(:registry_double) { double 'SingularityDsl::Dsl::Registry_DOUBLE' }

    it 'instance_evals contents of a file' do
      allow(::File).to receive(:read).and_return('0')
      expect(dsl).to receive(:instance_eval).with('0')
      dsl.load_ex_script 'foo'
    end

    it 'wipes the existing task registry' do
      expect(dsl.registry).to_not eql registry_double

      allow(::File).to receive(:read).and_return('0')
      allow(SingularityDsl::Dsl::Registry).to receive(:new)
        .and_return(registry_double)

      expect(dsl).to receive(:instance_eval).with('0')

      dsl.load_ex_script 'foo'

      expect(dsl.registry).to eql registry_double
    end
  end

  context '#load_tasks_in_path' do
    it 'does not load tasks that have already been required' do
      path = ::File.dirname(__FILE__) + '/../../lib/singularity_dsl/tasks'
      expect(dsl).to receive(:load_tasks).with []
      dsl.load_tasks_in_path path
    end

    it 'actually loads new tasks from dir' do
      path = ::File.dirname(__FILE__) + '/stubs/tasks'
      dsl.load_tasks_in_path path
      expect(dsl.singleton_methods).to include :dummytask
      # IMPORTANT: do this to prevent the singleton
      # from having this task in the map
      SingularityDsl.reset_map
    end
  end

  context '#flag' do
    it 'sets true by default' do
      dsl.flag 'default'
      expect(dsl.flags).to eql default: true
    end

    it 'sets vals' do
      dsl.flag 'foo', 'bar'
      expect(dsl.flags).to eql foo: 'bar'
    end
  end

  context '#flag?' do
    it 'returns false by default' do
      expect(dsl.flag?('blah')).to eql false
    end

    it 'returns true by default' do
      dsl.flag 'default'
      expect(dsl.flag?('default')).to eql true
    end

    it 'returns vals' do
      dsl.flag 'foo', 'bar'
      expect(dsl.flag?('foo')).to eql 'bar'
    end
  end
end
