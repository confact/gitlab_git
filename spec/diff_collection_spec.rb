require 'spec_helper'

describe Gitlab::Git::DiffCollection do
  subject do
    Gitlab::Git::DiffCollection.new(
      iterator,
      max_files: max_files,
      max_lines: max_lines,
      all_diffs: all_diffs,
    )
  end
  let(:iterator) { Array.new(file_count, fake_diff(line_count)) }
  let(:file_count) { 0 }
  let(:line_count) { 1 }
  let(:max_files) { 10 }
  let(:max_lines) { 100 }
  let(:all_diffs) { false }

  its(:to_a) { should be_kind_of ::Array }

  describe :decorate! do
    let(:file_count) { 3}

    it 'modifies the array in place' do
      count = 0
      subject.decorate! { |d| !d.nil? && count += 1 }
      subject.to_a.should eq([1, 2, 3])
    end
  end

  context 'overflow handling' do
    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        its(:overflow?) { should be_false }
        its(:empty?) { should be_false }
        its(:real_size) { should eq('3') }
        it { subject.size.should eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:overflow?) { should be_false }
          its(:empty?) { should be_false }
          its(:real_size) { should eq('3') }
          it { subject.size.should eq(3) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }

        its(:overflow?) { should be_true }
        its(:empty?) { should be_false }
        its(:real_size) { should eq('0+') }
        it { subject.size.should eq(0) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:overflow?) { should be_false }
          its(:empty?) { should be_false }
          its(:real_size) { should eq('3') }
          it { subject.size.should eq(3) }
        end
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:overflow?) { should be_true }
        its(:empty?) { should be_false }
        its(:real_size) { should eq('10+') }
        it { subject.size.should eq(10) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:overflow?) { should be_false }
          its(:empty?) { should be_false }
          its(:real_size) { should eq('11') }
          it { subject.size.should eq(11) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 30 }

        its(:overflow?) { should be_true }
        its(:empty?) { should be_false }
        its(:real_size) { should eq('3+') }
        it { subject.size.should eq(3) }

        context 'when limiting is disabled' do
          let(:all_diffs) { true }

          its(:overflow?) { should be_false }
          its(:empty?) { should be_false }
          its(:real_size) { should eq('11') }
          it { subject.size.should eq(11) }
        end
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        its(:overflow?) { should be_false }
        its(:empty?) { should be_false }
        its(:real_size) { should eq('10') }
        it { subject.size.should eq(10) }
      end
    end
  end

  describe 'empty collection' do
    subject { Gitlab::Git::DiffCollection.new([]) }

    its(:overflow?) { should be_false }
    its(:empty?) { should be_true }
    its(:size) { should eq(0) }
    its(:real_size) { should eq('0')}
  end

  def fake_diff(line_count)
    {'diff' => "DIFF\n" * line_count}
  end
end